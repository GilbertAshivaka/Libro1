#include "emailnotificationcontroller.h"
#include <QCoreApplication>


EmailNotificationController::EmailNotificationController(QObject *parent)
    : QObject{parent}
    , m_socket(new QSslSocket(this)) //changed here from QTcpSocket
    , m_retryTimer(new QTimer(this))
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
    m_emailLogsModel->addLog(to, subject, "Pengding", "custom");
    
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
    QString queryString = R"(
        SELECT COUNT(*)
        FROM issued_books ib
        JOIN users u ON ib.user_id = u.user_id
        WHERE ib.status = 'Borrowed'
        AND ib.due_date < datetime('now')
        AND u.email IS NOT NULL
        AND u.email != ''
    )";
    
    if (query.exec(queryString) && query.next()) {
        return query.value(0).toInt();
    }
    
    return 0;
}

int EmailNotificationController::getPendingReservedCount()
{
    //Placeholder to be implemented when we have the reserved books table
    return 0;
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
            if (useTLS()) {
                m_currentState = StartTlsSent;
                m_socket->write("STARTTLS\r\n");
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

QList<EmailData> EmailNotificationController::getOverdueBooks()
{
    QList<EmailData> overdueEmails;
    
    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.open()) {
        logEmailActivity("Database connection failed", "ERROR");
        return overdueEmails;
    }
    
    QSqlQuery query(db);
    QString queryString = R"(
        SELECT
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
        ORDER BY days_overdue DESC
    )";
    
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
    
    // Placeholder - implement when you have reservations table
    logEmailActivity("Reserved book notifications not yet implemented - add reservations table", "INFO");
    
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

QString EmailNotificationController::generateReservedEmailBody(const QString &userName, const QString &bookTitle)
{
    QString body = QString(R"(
Dear %1,

Good news! The book you reserved is now available for pickup.

Book Details:
- Title: %2

Please collect your reserved book within the next 3 days. After this period, the reservation will be cancelled and the book will be made available to other users.

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
)").arg(userName).arg(bookTitle);
    
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

















