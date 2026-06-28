#include "emailnotificationcontroller.h"
#include <QCoreApplication>
#include <QTime>
#include <QDate>


EmailNotificationController::EmailNotificationController(QObject *parent)
    : QObject{parent}
    , m_socket(new QSslSocket(this)) //changed here from QTcpSocket
    , m_retryTimer(new QTimer(this))
    , m_scheduleTimer(new QTimer(this))
    , m_emailLogsModel(new EmailLogsModel(this))
    , m_totalEmailsSent(0)
    , m_totalEmailsFailed(0)
    , m_currentState(Init)
    , m_isProcessing(false)
    , m_isPaused(false)
    , m_retryCount(0)
{
    //set up retry timer
    m_retryTimer->setSingleShot(true);
    connect(m_retryTimer, &QTimer::timeout, this, &EmailNotificationController::onRetryTimer);

    //set up socket connections
    connect(m_socket, &QSslSocket::connected, this, &EmailNotificationController::onSocketConnected);

    connect(m_socket, &QSslSocket::readyRead, this, &EmailNotificationController::onSocketReadyRead);

    connect(m_socket, QOverload<QAbstractSocket::SocketError>::of(&QSslSocket::errorOccurred),
            this, &EmailNotificationController::onSocketError);

    connect(m_socket, &QSslSocket::disconnected, this, &EmailNotificationController::onSocketDisconnected);

    //change made to handle SSL errors
    connect(m_socket, QOverload<const QList<QSslError>&>::of(&QSslSocket::sslErrors),
            this, [this](const QList<QSslError> &errors) {
                // For development, you might ignore some errors
                // In production, handle these properly
                logEmailActivity("SSL errors occurred (ignoring for Gmail)", "WARNING");
                m_socket->ignoreSslErrors();
            });

    //encrypted signal handler after encryption is done
    connect(m_socket, &QSslSocket::encrypted, this, [this]() {
        logEmailActivity("TLS encryption established successfully!");

        // Now send EHLO again after TLS
        m_currentState = EhloAfterTlsSent; // or set your m_tlsUpgraded flag
        m_socket->write("EHLO localhost\r\n");
        m_socket->flush(); // Make sure it's sent
    });

    //SSL error handling
    connect(m_socket, &QSslSocket::sslErrors, this, [this](const QList<QSslError> &errors) {
        for (const QSslError &error : errors) {
            logEmailActivity("SSL Error (ignoring): " + error.errorString(), "WARNING");
        }
        // Ignore errors and continue
        m_socket->ignoreSslErrors();
    });


    loadConfiguration();

    // Ensure the (additive, non-destructive) de-duplication table exists.
    ensureNotificationLogSchema();

    // Daily scheduler: tick periodically and let onScheduleTimerTick() decide
    // whether it's time to run (gated by the configured time-of-day and a
    // persisted "last run" date so it fires at most once per day).
    connect(m_scheduleTimer, &QTimer::timeout, this, &EmailNotificationController::onScheduleTimerTick);
    m_scheduleTimer->start(15 * 60 * 1000); // every 15 minutes

    // Startup catch-up: if the app launches after the scheduled time and today's
    // run hasn't happened yet, send shortly after startup.
    QTimer::singleShot(8000, this, &EmailNotificationController::onScheduleTimerTick);

    updateLastActivity("Email notification system initialised.");
}

EmailNotificationController::~EmailNotificationController()
{
    if (m_socket && m_socket->state() == QSslSocket::ConnectedState){
        m_socket->write("QUIT\\r\\n");
        m_socket->waitForBytesWritten();
        m_socket->disconnectFromHost();
    }
}

bool EmailNotificationController::isConfigured() const
{
    return !smtpServer().isEmpty() && !smtpUsername().isEmpty();
}

bool EmailNotificationController::isProcessing() const
{
    return m_isProcessing && !m_isPaused;
}

int EmailNotificationController::queueSize() const
{
    return m_emailQueue.size();
}

QString EmailNotificationController::smtpServer() const
{
    QSettings settings("LIbroILMS","EmailSettings");
    return settings.value("smtp/server", "smtp.gmail.com").toString();
}

int EmailNotificationController::smtpPort() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("smtp/port", 587).toInt();
}

QString EmailNotificationController::smtpUsername() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("smtp/username", "").toString();
}

QString EmailNotificationController::smtpPassword() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("smtp/password", "").toString();
}

bool EmailNotificationController::useSSL() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("smtp/useSSL",false).toBool();
}

bool EmailNotificationController::useTLS() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("smtp/useTLS", true).toBool();
}

//SMTP Configuration setters
void EmailNotificationController::setSmtpServer(const QString &server)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("smtp/server").toString() != server){
        settings.setValue("smtp/server", server);
        emit smtpConfigChanged();
        emit configurationChanged();
    }
}

void EmailNotificationController::setSmtpPort(int port)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("smtp/port").toInt() != port){
        settings.setValue("smtp/port", port);
        emit smtpConfigChanged();
        emit configurationChanged();
    }
}

void EmailNotificationController::setSmtpUsername(const QString &username)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("smtp/username").toString() != username) {
        settings.setValue("smtp/username", username);
        emit smtpConfigChanged();
        emit configurationChanged();
    }
}

void EmailNotificationController::setSmtpPassword(const QString &password)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("smtp/password").toString() != password) {
        settings.setValue("smtp/password", password);
        emit smtpConfigChanged();
        emit configurationChanged();
    }
}

void EmailNotificationController::setUseSSL(bool use)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("smtp/useSSL").toBool() != use) {
        settings.setValue("smtp/useSSL", use);
        emit smtpConfigChanged();
        emit configurationChanged();
    }
}

void EmailNotificationController::setUseTLS(bool use)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("smtp/useTLS").toBool() != use) {
        settings.setValue("smtp/useTLS", use);
        emit smtpConfigChanged();
        emit configurationChanged();
    }
}

//Automation (daily scheduler) configuration

bool EmailNotificationController::autoNotificationsEnabled() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("automation/enabled", false).toBool();
}

QString EmailNotificationController::notificationTime() const
{
    QSettings settings("LibroILMS", "EmailSettings");
    return settings.value("automation/time", "08:00").toString();
}

void EmailNotificationController::setAutoNotificationsEnabled(bool enabled)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("automation/enabled", false).toBool() != enabled) {
        settings.setValue("automation/enabled", enabled);
        updateLastActivity(enabled ? "Automatic daily notifications enabled"
                                   : "Automatic daily notifications disabled");
        emit automationConfigChanged();
        // Re-evaluate immediately so enabling late in the day can still fire today.
        if (enabled)
            QTimer::singleShot(0, this, &EmailNotificationController::onScheduleTimerTick);
    }
}

void EmailNotificationController::setNotificationTime(const QString &time)
{
    QSettings settings("LibroILMS", "EmailSettings");
    if (settings.value("automation/time", "08:00").toString() != time) {
        settings.setValue("automation/time", time);
        emit automationConfigChanged();
    }
}

//Main Email sending functions

void EmailNotificationController::checkAndSendOverdueNotifications()
{
    if (!isConfigured()){
        emit errorOccured("SMTP Configuration required");
        return;
    }

    QList<EmailData> overdueEmails = getOverdueBooks();

    if (overdueEmails.isEmpty()){
        updateLastActivity("No overudue books found.");
        return;
    }

    updateLastActivity(QString("Found %1 overdue book notifications to send")
                           .arg(overdueEmails.size()));

    for (const auto email :overdueEmails){
        m_emailQueue.enqueue(email);
        m_emailLogsModel->addLog(email.to, email.subject, "Pending", email.type);
    }

    emit queueSizeChanged();
    processEmailQueue();
}

void EmailNotificationController::checkAndSendReservedBookNotifications()
{
    if (!isConfigured()) {
        emit errorOccured("SMTP configuration required");
        return;
    }

    QList<EmailData> reservedEmails = getReservedBooks();

    if (reservedEmails.isEmpty()) {
        updateLastActivity("No reserved book notifications to send");
        return;
    }

    updateLastActivity(QString("Found %1 reserved book notifications to send").arg(reservedEmails.size()));

    for (const auto &email : reservedEmails) {
        m_emailQueue.enqueue(email);
        m_emailLogsModel->addLog(email.to, email.subject, "Pending", email.type);
    }

    emit queueSizeChanged();
    processEmailQueue();
}

void EmailNotificationController::runNotificationsNow()
{
    // Send both reminder types in one pass. The per-item de-dup guard prevents
    // re-sending anything already notified within the cooldown window.
    checkAndSendOverdueNotifications();
    checkAndSendReservedBookNotifications();
}

void EmailNotificationController::onScheduleTimerTick()
{
    if (!autoNotificationsEnabled())
        return;

    if (!isConfigured())
        return; // silently wait until SMTP is configured

    const QDateTime now = QDateTime::currentDateTime();

    QTime scheduled = QTime::fromString(notificationTime(), "HH:mm");
    if (!scheduled.isValid())
        scheduled = QTime(8, 0);

    // Only after the configured time-of-day.
    if (now.time() < scheduled)
        return;

    // At most once per calendar day (persisted across restarts).
    QSettings settings("LibroILMS", "EmailSettings");
    const QString today = now.date().toString("yyyy-MM-dd");
    if (settings.value("automation/lastRun", "").toString() == today)
        return;

    settings.setValue("automation/lastRun", today);
    updateLastActivity("Automated daily notifications triggered");
    logEmailActivity("Scheduler: running daily overdue + reserved notifications");

    runNotificationsNow();
}

void EmailNotificationController::sendTestEmail(const QString &recipientEmail)
{
    if (!isConfigured()){
        emit errorOccured("SMTP Configuration required.");
        return;
    }

    if (recipientEmail.isEmpty()){
        emit errorOccured("Recipient email required.");
        return;
    }

    EmailData testEmail;
    testEmail.to = recipientEmail;
    testEmail.subject = "Library Management System - Test Email";
    testEmail.body = generateTestEmailBody();
    testEmail.userName = "Test User";
    testEmail.bookTitle = "Test Book";
    testEmail.type = "test";

    m_emailQueue.enqueue(testEmail);
    m_emailLogsModel->addLog(recipientEmail, testEmail.subject, "Pending", "test");
    updateLastActivity("Sending test email to " + recipientEmail);

    emit queueSizeChanged();
    processEmailQueue();
}

void EmailNotificationController::sendCustomEmail(const QString &to, const QString &subject, const QString &body)
{
    if (!isConfigured()){
        emit errorOccured("SMTP Configuration is required.");
        return;
    }

    if (to.isEmpty() || subject.isEmpty()){
        emit errorOccured("Recipient and subject required");
        return;
    }

    EmailData customEmail;
    customEmail.to = to;
    customEmail.subject = subject;
    customEmail.body = body;
    customEmail.type = "custom";

    m_emailQueue.enqueue(customEmail);
    m_emailLogsModel->addLog(to, subject, "Pending", "custom");

    updateLastActivity("Sending custom email to " + to);

    emit queueSizeChanged();
    processEmailQueue();
}

void EmailNotificationController::saveConfiguration()
{
    // Validate configuration before "saving"
    QSettings settings("LibroILMS", "EmailSettings");

    if (settings.value("smtp/server").toString().isEmpty()) {
        emit notificationSent("Error: SMTP server cannot be empty");
        return;
    }

    if (settings.value("smtp/username").toString().isEmpty()) {
        emit notificationSent("Error: Username cannot be empty");
        return;
    }

    if (settings.value("smtp/password").toString().isEmpty()) {
        emit notificationSent("Error: Password cannot be empty");
        return;
    }

    // Configuration is already saved by setters, just confirm
    updateLastActivity("Configuration saved.");
    emit notificationSent("SMTP Configuration saved successfully.");
}

void EmailNotificationController::loadConfiguration()
{
    // configuration is automatically loaded by the getters
    emit configurationChanged();
    emit smtpConfigChanged();
    updateLastActivity("Configuration loaded.");
}

bool EmailNotificationController::testConfiguration()
{
    return isConfigured();
}

void EmailNotificationController::clearQueue()
{
    m_emailQueue.clear();
    updateLastActivity("Email queue cleared");
    emit queueSizeChanged();
    emit processingChanged();
}

void EmailNotificationController::pauseProcessing()
{
    m_isPaused = true;
}

void EmailNotificationController::resumeProcessing()
{
    m_isPaused = true;
    updateLastActivity("Email processing resumed");
    processEmailQueue();
    emit processingChanged();
}

void EmailNotificationController::resetStatistics()
{
    m_totalEmailsSent = 0;
    m_totalEmailsFailed = 0;
    m_emailLogsModel->clearLogs();
    updateLastActivity("Statistics reset");
    emit totalEmailsSentChanged();
    emit totalEmailsFailedChanged();
}

int EmailNotificationController::getPendingOverdueCount()
{
    // Query database for overdue books count
    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open()) {
        return 0;
    }

    QSqlQuery query(db);
    QString queryString = QString(R"(
        SELECT COUNT(*)
        FROM issued_books ib
        JOIN users u ON ib.user_id = u.user_id
        WHERE ib.status = 'Borrowed'
        AND ib.due_date < datetime('now')
        AND u.email IS NOT NULL
        AND u.email != ''
        AND NOT EXISTS (
            SELECT 1 FROM notification_log nl
            WHERE nl.notification_type = 'overdue'
            AND nl.target_id = ib.issue_id
            AND (julianday('now') - julianday(nl.sent_at)) * 24 < %1
        )
    )").arg(NOTIFICATION_COOLDOWN_HOURS);

    if (query.exec(queryString) && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

int EmailNotificationController::getPendingReservedCount()
{
    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open()) {
        return 0;
    }

    int count = 0;
    QSqlQuery query(db);

    // Count reservations that are ready for pickup notification
    // (notified status OR pending with book available)
    QString pickupCountQuery = QString(R"(
        SELECT COUNT(*)
        FROM reserved_books rb
        JOIN books b ON rb.book_id = b.bookID
        WHERE (
            (rb.status = 'notified')
            OR
            (rb.status = 'pending' AND b.availability = 'Available')
        )
        AND rb.user_email IS NOT NULL
        AND rb.user_email != ''
        AND NOT EXISTS (
            SELECT 1 FROM notification_log nl
            WHERE nl.notification_type = 'reservation_pickup'
            AND nl.target_id = rb.reservation_id
            AND (julianday('now') - julianday(nl.sent_at)) * 24 < %1
        )
    )").arg(NOTIFICATION_COOLDOWN_HOURS);

    if (query.exec(pickupCountQuery) && query.next()) {
        count += query.value(0).toInt();
    }

    // Count reservations nearing expiry (within 2 days)
    QString expiryCountQuery = QString(R"(
        SELECT COUNT(*)
        FROM reserved_books rb
        JOIN books b ON rb.book_id = b.bookID
        WHERE rb.status = 'pending'
        AND b.availability != 'Available'
        AND julianday(rb.expiry_date) - julianday('now') <= 2
        AND julianday(rb.expiry_date) - julianday('now') >= 0
        AND rb.user_email IS NOT NULL
        AND rb.user_email != ''
        AND NOT EXISTS (
            SELECT 1 FROM notification_log nl
            WHERE nl.notification_type = 'reservation_expiry'
            AND nl.target_id = rb.reservation_id
            AND (julianday('now') - julianday(nl.sent_at)) * 24 < %1
        )
    )").arg(NOTIFICATION_COOLDOWN_HOURS);

    if (query.exec(expiryCountQuery) && query.next()) {
        count += query.value(0).toInt();
    }

    return count;
}

void EmailNotificationController::onSocketConnected()
{
    logEmailActivity("Connected to SMTP server");
    m_currentState  = Connected;
}

void EmailNotificationController::onSocketReadyRead()
{
    QByteArray data = m_socket->readAll();
    QString response = QString::fromUtf8(data).trimmed();

    logEmailActivity("Server response" + response);
    processServerResponse(response);
}

void EmailNotificationController::onSocketError(QAbstractSocket::SocketError error)
{
    QString errorString = m_socket->errorString();
    logEmailActivity("Socket error: " + errorString, "ERROR");

    if(m_retryCount < MAX_RETRIES){
        m_retryCount++;
        logEmailActivity(QString("Retrying due to socket error (%1/%2)")
                             .arg(m_retryCount).arg(MAX_RETRIES));

        m_retryTimer->start(5000);
    }else{
        //Failed after retries
        m_emailLogsModel->addLog(m_currentEmail.to, m_currentEmail.subject, "Failed",
                                 m_currentEmail.type, errorString);

        m_totalEmailsFailed++;
        emit totalEmailsFailedChanged();
        emit errorOccured("Email failed to " + m_currentEmail.to + ": " + errorString);

        m_isProcessing = false;
        processEmailQueue();
    }
}

void EmailNotificationController::onSocketDisconnected()
{
    logEmailActivity("Disconnected from SMTP server");

    if (m_currentState != Finished) {
        logEmailActivity("Unexpected disconnection", "WARNING");
    }
}

void EmailNotificationController::onRetryTimer()
{
    connectToServer();
}


void EmailNotificationController::processEmailQueue()
{
    if (m_isProcessing || m_emailQueue.isEmpty() || m_isPaused){
        if (m_emailQueue.isEmpty()){
            m_isProcessing = false;
            emit processingChanged();
        }

        return;
    }

    if(!isConfigured()){
        logEmailActivity("SMTP settings not configured", "ERROR");
        emit errorOccured("SMTP settings not confifgured");
        return;
    }

    m_isProcessing = true;
    emit processingChanged();

    m_currentEmail = m_emailQueue.dequeue();
    emit queueSizeChanged();

    logEmailActivity(QString("Processing email to %1, Subject: %2").arg(m_currentEmail.to).arg(m_currentEmail.subject));

    sendEmail(m_currentEmail);
}

void EmailNotificationController::sendEmail(const EmailData &emailData)
{
    m_currentState = Init;
    m_retryCount = 0;
    connectToServer();
}

void EmailNotificationController::connectToServer()
{
    m_socket->setProtocol(QSsl::TlsV1_2OrLater);
    // Disconnect if already connected
    if (m_socket->state() == QSslSocket::ConnectedState) {
        m_socket->disconnectFromHost();
        m_socket->waitForDisconnected(3000);
    }

    logEmailActivity(QString("Connecting to TCP server: %1:%2")
                         .arg(smtpServer())
                         .arg(smtpPort()));

    m_socket->connectToHost(smtpServer(), smtpPort());

    if (!m_socket->waitForConnected(10000)) {
        logEmailActivity("Failed to connect to SMTP server: " + m_socket->errorString(), "ERROR");

        if (m_retryCount < MAX_RETRIES) {
            m_retryCount++;
            logEmailActivity(QString("Retrying connection %1/%2")
                                 .arg(m_retryCount)
                                 .arg(MAX_RETRIES));

            m_retryTimer->start(5000);
            return;
        }

        // Failed after all retries
        m_emailLogsModel->addLog(m_currentEmail.to,
                                 m_currentEmail.subject,
                                 "Failed",
                                 m_currentEmail.type,
                                 m_socket->errorString());

        m_totalEmailsFailed++;
        emit totalEmailsFailedChanged();
        emit errorOccured("Failed to connect to: " + m_socket->errorString());

        m_isProcessing = false;
        processEmailQueue();
        return;
    }

    // If we reach here, connection was successful
    logEmailActivity("Successfully connected to SMTP server");
    // Continue with SMTP communication...
}

void EmailNotificationController::processServerResponse(const QString &response)
{
    QString code = response.left(3);

    switch (m_currentState) {
    case Connected:
        if (code == "220") {
            m_currentState = EhloSent;
            m_socket->write("EHLO localhost\r\n");
        } else {
            logEmailActivity("Unexpected server greeting: " + response, "ERROR");
            resetConnection("Connected");
        }
        break;

    case EhloSent:
        if (code == "250") {
            // if (useTLS()) {
            //     m_currentState = StartTlsSent;
            //     m_socket->write("STARTTLS\r\n");
            // } else {
            //     m_currentState = AuthLoginSent;
            //     m_socket->write("AUTH LOGIN\r\n");
            // }
            if (true) {  // ← force STARTTLS
                m_currentState = StartTlsSent;
                m_socket->write("STARTTLS\r\n");
                logEmailActivity("Forcing STARTTLS (debug)");
            } else {
                m_currentState = AuthLoginSent;
                m_socket->write("AUTH LOGIN\r\n");
            }
        } else {
            logEmailActivity("EHLO failed: " + response, "ERROR");
            resetConnection("EhloSent");
        }
        break;

    case StartTlsSent:
        if (code == "220") {
            logEmailActivity("Starting TLS encryption...");

            // Start encrypted connection
            m_socket->startClientEncryption();
        } else {
            logEmailActivity("STARTTLS failed: " + response, "ERROR");
            resetConnection("StartTlsSent");
        }
        break;

    case EhloAfterTlsSent:
        if (code == "250") {
            // We're already past TLS, just proceed to authentication
            logEmailActivity("EHLO after TLS successful, proceeding to authentication");
            m_currentState = AuthLoginSent;
            m_socket->write("AUTH LOGIN\r\n");
        } else {
            logEmailActivity("EHLO after TLS failed: " + response, "ERROR");
            resetConnection("EhloAfterTlsSent");
        }
        break;

    case AuthLoginSent:
        if (code == "334") {
            m_currentState = AuthUserSent;
            QString username = base64Encode(smtpUsername());
            m_socket->write(username.toUtf8() + "\r\n");
        } else {
            logEmailActivity("AUTH LOGIN failed: " + response, "ERROR");
            resetConnection("AuthLoginSent");
        }
        break;

    case AuthUserSent:
        if (code == "334") {
            m_currentState = AuthPassSent;
            QString password = base64Encode(smtpPassword());
            m_socket->write(password.toUtf8() + "\r\n");
        } else {
            logEmailActivity("Username authentication failed: " + response, "ERROR");
            resetConnection("AuthUserSent");
        }
        break;

    case AuthPassSent:
        if (code == "235") {
            m_currentState = MailFromSent;
            QString mailFrom = QString("MAIL FROM:<%1>\r\n").arg(smtpUsername());
            m_socket->write(mailFrom.toUtf8());
        } else {
            logEmailActivity("Password authentication failed: " + response, "ERROR");
            resetConnection("AuthPassSent");
        }
        break;

    case MailFromSent:
        if (code == "250") {
            m_currentState = RcptToSent;
            QString rcptTo = QString("RCPT TO:<%1>\r\n").arg(m_currentEmail.to);
            m_socket->write(rcptTo.toUtf8());
        } else {
            logEmailActivity("MAIL FROM failed: " + response, "ERROR");
            resetConnection("MailFromSent");
        }
        break;

    case RcptToSent:
        if (code == "250") {
            m_currentState = DataSent;
            m_socket->write("DATA\r\n");
        } else {
            logEmailActivity("RCPT TO failed: " + response, "ERROR");
            resetConnection("RcptToSent");
        }
        break;

    case DataSent:
        if (code == "354") {
            m_currentState = MessageSent;

            QString message = QString("From: %1\r\n"
                                      "To: %2\r\n"
                                      "Subject: %3\r\n"
                                      "Content-Type: text/plain; charset=utf-8\r\n"
                                      "\r\n"
                                      "%4\r\n"
                                      ".\r\n")  // Fixed all \r\n
                                  .arg(smtpUsername())
                                  .arg(m_currentEmail.to)
                                  .arg(m_currentEmail.subject)
                                  .arg(m_currentEmail.body);

            m_socket->write(message.toUtf8());
        } else {
            logEmailActivity("DATA command failed: " + response, "ERROR");
            resetConnection("DataSent");
        }
        break;

    case MessageSent:
        if (code == "250") {
            m_currentState = Finished;
            logEmailActivity("Email sent successfully to: " + m_currentEmail.to);

            m_emailLogsModel->addLog(m_currentEmail.to, m_currentEmail.subject, "Sent",
                                     m_currentEmail.type);

            // Record for de-duplication ONLY on confirmed delivery, so a failed
            // send is retried on the next run instead of being suppressed.
            if (m_currentEmail.targetId >= 0 &&
                (m_currentEmail.type == "overdue" ||
                 m_currentEmail.type == "reservation_pickup" ||
                 m_currentEmail.type == "reservation_expiry")) {
                recordNotificationSent(m_currentEmail.type, m_currentEmail.targetId);
            }

            m_totalEmailsSent++;
            emit totalEmailsSentChanged();
            emit notificationSent("Email sent to " + m_currentEmail.to);

            m_socket->write("QUIT\r\n");  // Fixed
            m_socket->waitForBytesWritten();
            m_socket->disconnectFromHost();

            m_isProcessing = false;
            processEmailQueue();
        } else {
            logEmailActivity("Message sending failed: " + response, "ERROR");
            resetConnection("MessageSent");
        }
        break;

    default:
        logEmailActivity("Unexpected state in email processing", "ERROR");
        resetConnection("Default");
        break;
    }
}

void EmailNotificationController::resetConnection(const QString &from)
{
    m_currentState = Init;
    m_socket->disconnectFromHost();

    // Mark current email as failed
    m_emailLogsModel->addLog(m_currentEmail.to, m_currentEmail.subject, "Failed", m_currentEmail.type, "Connection reset");
    m_totalEmailsFailed++;
    emit totalEmailsFailedChanged();
    emit errorOccured("Email failed to " + m_currentEmail.to + ": Connection reset(" +  from +")");

    m_isProcessing = false;
    processEmailQueue();
}

void EmailNotificationController::ensureNotificationLogSchema()
{
    // Additive only: creates a NEW table if missing. Never alters or drops any
    // existing table, so existing data is completely untouched.
    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open()) {
        logEmailActivity("Could not open database to ensure notification_log table", "WARNING");
        return;
    }

    QSqlQuery query(db);
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS notification_log ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "notification_type TEXT NOT NULL,"   // 'overdue' | 'reservation_pickup' | 'reservation_expiry'
            "target_id INTEGER,"                 // issue_id or reservation_id
            "sent_at DATETIME DEFAULT CURRENT_TIMESTAMP)")) {
        logEmailActivity("Failed to create notification_log table: " + query.lastError().text(), "ERROR");
        return;
    }
    query.exec("CREATE INDEX IF NOT EXISTS idx_notiflog_lookup "
               "ON notification_log(notification_type, target_id, sent_at)");
}

void EmailNotificationController::recordNotificationSent(const QString &type, int targetId)
{
    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open())
        return;

    QSqlQuery query(db);
    query.prepare("INSERT INTO notification_log (notification_type, target_id, sent_at) "
                  "VALUES (:type, :id, datetime('now'))");
    query.bindValue(":type", type);
    query.bindValue(":id", targetId);
    if (!query.exec()) {
        logEmailActivity(QString("Failed to record notification (%1, %2): %3")
                             .arg(type).arg(targetId).arg(query.lastError().text()), "WARNING");
    }
}

QList<EmailData> EmailNotificationController::getOverdueBooks()
{
    QList<EmailData> overdueEmails;

    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open()) {
        logEmailActivity("Database connection failed", "ERROR");
        return overdueEmails;
    }

    QSqlQuery query(db);
    // De-dup guard: skip rows already notified within the cooldown window
    // (tracked in the additive notification_log table).
    QString queryString = QString(R"(
        SELECT
            ib.issue_id,
            u.email,
            u.first_name || ' ' || u.second_name AS full_name,
            b.title,
            ib.due_date,
            julianday('now') - julianday(ib.due_date) AS days_overdue
        FROM issued_books ib
        JOIN users u ON ib.user_id = u.user_id
        JOIN books b ON ib.book_id = b.bookID
        WHERE ib.status = 'Borrowed'
        AND ib.due_date < datetime('now')
        AND u.email IS NOT NULL
        AND u.email != ''
        AND NOT EXISTS (
            SELECT 1 FROM notification_log nl
            WHERE nl.notification_type = 'overdue'
            AND nl.target_id = ib.issue_id
            AND (julianday('now') - julianday(nl.sent_at)) * 24 < %1
        )
        ORDER BY days_overdue DESC
    )").arg(NOTIFICATION_COOLDOWN_HOURS);

    if (!query.exec(queryString)) {
        logEmailActivity("Failed to query overdue books: " + query.lastError().text(), "ERROR");
        return overdueEmails;
    }

    while (query.next()){
        EmailData email;
        email.to = query.value("email").toString();
        email.userName = query.value("full_name").toString();
        email.bookTitle = query.value("title").toString();
        email.type = "overdue";
        email.targetId = query.value("issue_id").toInt();

        QDateTime dueDate = query.value("due_date").toDateTime();
        int daysOverdue = query.value("days_overdue").toInt();

        email.subject = QString("Library notice: Overdue Book - %1").arg(email.bookTitle);
        email.body = generateOverdueEmailBody(email.userName, email.bookTitle, dueDate, daysOverdue);

        overdueEmails.append(email);
    }

    return overdueEmails;
}

QList<EmailData> EmailNotificationController::getReservedBooks()
{
    QList<EmailData> reservedEmails;

    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open()) {
        logEmailActivity("Database connection failed", "ERROR");
        return reservedEmails;
    }

    int pickupDays = SettingsManager::instance()->reservationPickupDays();

    // ── Scenario 1: Books ready for pickup ──────────────────────────────
    // Reservations where status is 'notified' (book is available and waiting)
    // OR status is 'pending' but the book is actually Available now
    QSqlQuery pickupQuery(db);
    QString pickupQueryString = QString(R"(
        SELECT
            rb.reservation_id,
            rb.user_email,
            rb.user_name,
            b.title,
            b.callNumber,
            rb.pickup_deadline,
            rb.notification_sent_date,
            rb.status
        FROM reserved_books rb
        JOIN books b ON rb.book_id = b.bookID
        WHERE (
            (rb.status = 'notified')
            OR
            (rb.status = 'pending' AND b.availability = 'Available')
        )
        AND rb.user_email IS NOT NULL
        AND rb.user_email != ''
        AND NOT EXISTS (
            SELECT 1 FROM notification_log nl
            WHERE nl.notification_type = 'reservation_pickup'
            AND nl.target_id = rb.reservation_id
            AND (julianday('now') - julianday(nl.sent_at)) * 24 < %1
        )
        ORDER BY rb.reservation_date ASC
    )").arg(NOTIFICATION_COOLDOWN_HOURS);

    if (!pickupQuery.exec(pickupQueryString)) {
        logEmailActivity("Failed to query reserved books for pickup: " + pickupQuery.lastError().text(), "ERROR");
        return reservedEmails;
    }

    while (pickupQuery.next()) {
        int reservationId = pickupQuery.value("reservation_id").toInt();
        QString status = pickupQuery.value("status").toString();

        // If the reservation is still 'pending' and the book is available,
        // update it to 'notified' and set the pickup deadline
        if (status == "pending") {
            QDateTime now = QDateTime::currentDateTime();
            QDateTime deadline = now.addDays(pickupDays);

            QSqlQuery updateQuery(db);
            updateQuery.prepare(
                "UPDATE reserved_books SET status = 'notified', "
                "notification_sent_date = :notif_date, "
                "pickup_deadline = :deadline, "
                "updated_at = CURRENT_TIMESTAMP "
                "WHERE reservation_id = :id"
                );
            updateQuery.bindValue(":notif_date", now.toString(Qt::ISODate));
            updateQuery.bindValue(":deadline", deadline.toString(Qt::ISODate));
            updateQuery.bindValue(":id", reservationId);

            if (!updateQuery.exec()) {
                logEmailActivity(QString("Failed to update reservation %1 to notified: %2")
                                     .arg(reservationId).arg(updateQuery.lastError().text()), "ERROR");
                continue;
            }

            // Also mark the book as Reserved
            QSqlQuery bookUpdate(db);
            bookUpdate.prepare("UPDATE books SET availability = 'Reserved' "
                               "WHERE bookID = (SELECT book_id FROM reserved_books WHERE reservation_id = :id)");
            bookUpdate.bindValue(":id", reservationId);
            bookUpdate.exec();
        }

        EmailData email;
        email.to = pickupQuery.value("user_email").toString();
        email.userName = pickupQuery.value("user_name").toString();
        email.bookTitle = pickupQuery.value("title").toString();
        email.type = "reservation_pickup";
        email.targetId = reservationId;

        // Use the existing or newly-set pickup deadline
        QDateTime pickupDeadline;
        if (status == "pending") {
            pickupDeadline = QDateTime::currentDateTime().addDays(pickupDays);
        } else {
            pickupDeadline = pickupQuery.value("pickup_deadline").toDateTime();
            if (!pickupDeadline.isValid())
                pickupDeadline = QDateTime::currentDateTime().addDays(pickupDays);
        }

        email.subject = QString("Library Notice: Your Reserved Book is Ready - %1").arg(email.bookTitle);
        email.body = generateReservedEmailBody(email.userName, email.bookTitle, pickupDeadline, pickupDays);

        reservedEmails.append(email);
    }

    // ── Scenario 2: Reservations nearing expiry ─────────────────────────
    // Pending reservations where the book is NOT yet available and
    // the expiry date is within 2 days from now
    QSqlQuery expiryQuery(db);
    QString expiryQueryString = QString(R"(
        SELECT
            rb.reservation_id,
            rb.user_email,
            rb.user_name,
            b.title,
            b.callNumber,
            rb.expiry_date,
            CAST(julianday(rb.expiry_date) - julianday('now') AS INTEGER) AS days_remaining
        FROM reserved_books rb
        JOIN books b ON rb.book_id = b.bookID
        WHERE rb.status = 'pending'
        AND b.availability != 'Available'
        AND julianday(rb.expiry_date) - julianday('now') <= 2
        AND julianday(rb.expiry_date) - julianday('now') >= 0
        AND rb.user_email IS NOT NULL
        AND rb.user_email != ''
        AND NOT EXISTS (
            SELECT 1 FROM notification_log nl
            WHERE nl.notification_type = 'reservation_expiry'
            AND nl.target_id = rb.reservation_id
            AND (julianday('now') - julianday(nl.sent_at)) * 24 < %1
        )
        ORDER BY rb.expiry_date ASC
    )").arg(NOTIFICATION_COOLDOWN_HOURS);

    if (!expiryQuery.exec(expiryQueryString)) {
        logEmailActivity("Failed to query expiring reservations: " + expiryQuery.lastError().text(), "ERROR");
        return reservedEmails;
    }

    while (expiryQuery.next()) {
        EmailData email;
        email.to = expiryQuery.value("user_email").toString();
        email.userName = expiryQuery.value("user_name").toString();
        email.bookTitle = expiryQuery.value("title").toString();
        email.type = "reservation_expiry";
        email.targetId = expiryQuery.value("reservation_id").toInt();

        QDateTime expiryDate = expiryQuery.value("expiry_date").toDateTime();
        int daysRemaining = expiryQuery.value("days_remaining").toInt();

        email.subject = QString("Library Notice: Reservation Expiring Soon - %1").arg(email.bookTitle);
        email.body = generateExpiryReminderEmailBody(email.userName, email.bookTitle, expiryDate, daysRemaining);

        reservedEmails.append(email);
    }

    logEmailActivity(QString("Found %1 reserved book notifications to process").arg(reservedEmails.size()));

    return reservedEmails;
}

QString EmailNotificationController::generateOverdueEmailBody(const QString &userName, const QString &bookTitle, const QDateTime &dueDate, int daysOverdue)
{
    QString body = QString(R"(
Dear %1,

This is a friendly reminder that you have an overdue book from our library.

Book Details:
- Title: %2
- Due Date: %3
- Days Overdue: %4

Please return this book as soon as possible to avoid additional late fees. If you need to renew the book, please contact the library or use our online system.

If you have already returned this book, please disregard this message.

Thank you for your cooperation.

Best regards,
Library Management System

---
This is an automated message. Please do not reply to this email.
For assistance, please contact the library directly.
)").arg(userName)
                       .arg(bookTitle)
                       .arg(dueDate.toString("yyyy-MM-dd"))
                       .arg(daysOverdue);

    return body;
}

QString EmailNotificationController::generateReservedEmailBody(const QString &userName, const QString &bookTitle, const QDateTime &pickupDeadline, int pickupDays)
{
    QString body = QString(R"(
Dear %1,

Good news! The book you reserved is now available for pickup.

Book Details:
- Title: %2
- Pickup Deadline: %3

Please collect your reserved book within the next %4 day(s). After this period, the reservation will be cancelled and the book will be made available to other users.

Library Hours:
Monday - Friday: 8:00 AM - 6:00 PM
Saturday: 9:00 AM - 4:00 PM
Sunday: Closed

Thank you for using our library services.

Best regards,
Library Management System

---
This is an automated message. Please do not reply to this email.
For assistance, please contact the library directly.
)").arg(userName)
                       .arg(bookTitle)
                       .arg(pickupDeadline.toString("yyyy-MM-dd"))
                       .arg(pickupDays);

    return body;
}

QString EmailNotificationController::generateExpiryReminderEmailBody(const QString &userName, const QString &bookTitle, const QDateTime &expiryDate, int daysRemaining)
{
    QString body = QString(R"(
Dear %1,

This is a reminder that your reservation for the following book is expiring soon.

Book Details:
- Title: %2
- Reservation Expires: %3
- Days Remaining: %4

The book is not yet available. If it becomes available before the expiry date, you will be notified to collect it. If the reservation expires, you are welcome to place a new reservation.

If you would like to cancel this reservation early, please visit the library or use the online system.

Thank you for using our library services.

Best regards,
Library Management System

---
This is an automated message. Please do not reply to this email.
For assistance, please contact the library directly.
)").arg(userName)
                       .arg(bookTitle)
                       .arg(expiryDate.toString("yyyy-MM-dd"))
                       .arg(daysRemaining);

    return body;
}

QString EmailNotificationController::generateTestEmailBody()
{
    return QString(R"(
Hello,

This is a test email from the Library Management System.

If you received this email, the email notification system is working correctly.

Current Time: %1

Best regards,
Library Management System

---
This is an automated test message.
)").arg(QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss"));
}

QString EmailNotificationController::base64Encode(const QString &text)
{
    return QString::fromUtf8(text.toUtf8().toBase64());
}

void EmailNotificationController::logEmailActivity(const QString &message, const QString &level)
{
    qDebug() << QString("[%1] %2: %3")
    .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss"))
        .arg(level)
        .arg(message);

    // Log to database system_logs table
    QSqlDatabase db = DatabaseManager::getConnection();
    if (db.open()) {
        QSqlQuery query(db);
        query.prepare("INSERT INTO system_logs (log_level, log_category, log_message, timestamp) "
                      "VALUES (?, 'EMAIL', ?, datetime('now'))");
        query.addBindValue(level);
        query.addBindValue(message);
        query.exec();
    }
}

void EmailNotificationController::updateLastActivity(const QString &activity)
{
    m_lastActivity = QString("[%1] %2")
    .arg(QDateTime::currentDateTime().toString("hh:mm:ss"))
        .arg(activity);
    emit lastActivityChanged();
}





EmailLogsModel::EmailLogsModel(QObject *parent)
    :QAbstractListModel(parent)
{

}

int EmailLogsModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_logs.size();
}

QVariant EmailLogsModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_logs.size())
        return QVariant();

    const EmailLogEntry &log = m_logs[index.row()];

    switch (role){
    case RecipientRole:
        return log.recipient;
    case SubjectRole:
        return log.subject;
    case StatusRole:
        return log.status;
    case TimestampRole:
        return log.timestamp;
    case ErrorRole:
        return log.error;
    case TypeRole:
        return log.type;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> EmailLogsModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[RecipientRole] = "recipient";
    roles[StatusRole] = "status";
    roles[SubjectRole] = "subject";
    roles[TimestampRole] = "timestamp";
    roles[ErrorRole] = "error";
    roles[TypeRole] = "type";
    return roles;
}

void EmailLogsModel::addLog(const QString &recipient, const QString &subject, const QString &status, const QString type, const QString error)
{
    beginInsertRows(QModelIndex(), 0, 0);

    EmailLogEntry log;
    log.recipient = recipient;
    log.subject = subject;
    log.status = status;
    log.timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
    log.error = error;
    log.type = type;


    m_logs.prepend(log);

    //keep only the last 100
    if (m_logs.size() > 100){
        beginRemoveRows(QModelIndex(), 100, m_logs.size()-1);
        m_logs.erase(m_logs.begin() +100, m_logs.end());
        endRemoveRows();
    }

    endInsertRows();
}

void EmailLogsModel::updateLogStatus(int index, const QString status, const QString error)
{
    if (index < 0 || index >= m_logs.size())
        return;

    m_logs[index].status = status;
    m_logs[index].error = error;
    m_logs[index].timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

    QModelIndex modelIndex = createIndex(index, 0);
    emit dataChanged(modelIndex, modelIndex);
}

void EmailLogsModel::clearLogs()
{
    beginResetModel();
    m_logs.clear();
    endResetModel();
}

int EmailLogsModel::getLogsCount()
{
    return m_logs.size();
}

















