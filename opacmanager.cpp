#include "opacmanager.h"
#include "databasemanager.h"
#include <QNetworkRequest>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSqlQuery>
#include <QSqlError>
#include <QUrlQuery>
#include <QDebug>
#include <QMutexLocker>
#include <QVariant>
#include <QThread>

OpacManager::OpacManager(QObject *parent)
    : QObject{parent}
    , m_networkManager(new QNetworkAccessManager(this))
    , m_autoSyncTimer(new QTimer(this))
    , m_expirationTimer(new QTimer(this))
    , m_isConfigured(false)
    , m_isSyncing(false)
    , m_syncStatus("Not configured")
    , m_autoSyncEnabled(false)
    , m_syncIntervalMinutes(60)
    , m_notificationPickupDays(3)
    , m_reservationExpiryDays(7)
    , m_pendingReservationsCount(0)
{
    //Get database connection
    m_db = DatabaseManager::getConnection();

    //Create tables if they don't exist
    createTables();

    //load configuration from the database
    if (loadConfiguration()){
        m_isConfigured = true;

        updatePendingCount();
        emit configurationChanged();
    }

    //set up autoSync timer
    connect(m_autoSyncTimer, &QTimer::timeout, this, &OpacManager::onAutoSyncTimerTimeout);

    //set up expiration checker, runs daily
    m_expirationTimer->setInterval(24*60*60*1000); //24 hours
    connect(m_expirationTimer, &QTimer::timeout, this, &OpacManager::onExpirationTimeTimeout);
    m_expirationTimer->start();

    //check for expired reservations on startup
    checkExpiredReservations();

    //start autoSync if enabled
    if (m_autoSyncEnabled && m_isConfigured){
        startAutoSync();
    }
}

OpacManager::~OpacManager()
{
    stopAutoSync();
    m_expirationTimer->stop();
}

void OpacManager::setAutoSyncEnabled(bool enabled)
{
    if (m_autoSyncEnabled == enabled) return;

    m_autoSyncEnabled = enabled;

    // Update database
    QMutexLocker locker(&m_mutex);
    QSqlQuery query(m_db);
    query.prepare("UPDATE opac_configuration SET auto_sync_enabled = :enabled, "
                  "updated_at = CURRENT_TIMESTAMP WHERE is_active = 1");
    query.bindValue(":enabled", enabled ? 1 : 0);
    query.exec();

    emit autoSyncEnabledChanged();

    if (enabled && m_isConfigured) {
        startAutoSync();
    } else {
        stopAutoSync();
    }
}

void OpacManager::setSyncIntervalMinutes(int minutes)
{
    if (m_syncIntervalMinutes == minutes) return;

    m_syncIntervalMinutes = minutes;

    // Update database
    QMutexLocker locker(&m_mutex);
    QSqlQuery query(m_db);
    query.prepare("UPDATE opac_configuration SET sync_interval_minutes = :minutes, "
                  "updated_at = CURRENT_TIMESTAMP WHERE is_active = 1");
    query.bindValue(":minutes", minutes);
    query.exec();

    emit syncIntervalChanged();

    if (m_autoSyncEnabled && m_isConfigured) {
        startAutoSync();
    }
}

bool OpacManager::initializeConfiguration(const QString &opacUrl, const QString &apiKey, int syncInterval, int pickupDays, int expiryDays)
{
    m_opacUrl = opacUrl.trimmed();
    m_apiKey = apiKey.trimmed();
    m_syncIntervalMinutes = syncIntervalMinutes();
    m_notificationPickupDays = pickupDays;
    m_reservationExpiryDays = expiryDays;
    m_autoSyncEnabled = true;

    if (!validateConfiguration()){
        emit errorOccurred("Invalid configuration parameters");
        return false;
    }

    if (saveConfiguration()){
        m_isConfigured = true;
        emit configurationChanged();

        startAutoSync();

        performFullSync();

        return true;
    }

    return false;
}

bool OpacManager::updateConfiguration(const QString &opacUrl, const QString &apiKey, int &syncInterval, int pickupDays, int expiryDays)
{
    bool urlChanged = (m_opacUrl != opacUrl.trimmed());

    m_opacUrl = opacUrl.trimmed();
    m_apiKey = apiKey.trimmed();
    m_syncIntervalMinutes = syncInterval;
    m_notificationPickupDays = pickupDays;
    m_reservationExpiryDays = expiryDays;

    if (!validateConfiguration()) {
        emit errorOccurred("Invalid configuration parameters");
        return false;
    }

    if (saveConfiguration()) {
        emit configurationChanged();
        emit syncIntervalChanged();

        // Restart auto-sync timer with new interval
        if (m_autoSyncEnabled) {
            startAutoSync();
        }

        // If URL changed, trigger full sync
        if (urlChanged) {
            performFullSync();
        }

        return true;
    }

    return false;
}

QVariantMap OpacManager::getConfiguration()
{
    QVariantMap config;
    config["opacUrl"] = m_opacUrl;
    config["apiKey"] = m_apiKey;
    config["syncIntervalMinutes"] = m_syncIntervalMinutes;
    config["autoSyncEnabled"] = m_autoSyncEnabled;
    config["notificationPickupDays"] = m_notificationPickupDays;
    config["reservationExpiryDays"] = m_reservationExpiryDays;
    config["lastSyncTime"] = m_lastSyncTime;
    config["isConfigured"] = m_isConfigured;

    return config;
}

void OpacManager::testConnection()
{
    if (m_opacUrl.isEmpty() || m_apiKey.isEmpty()){
        emit connectionTestResult(false, "Please configure OPAC URL and API key first");
        return;
    }

    setSyncStatus("Testing connection...");

    //test with simple sync logs endpoint (requires API Key)
    QNetworkRequest request(QUrl(buildApiUrl("/api/sync/logs?limit=1")));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("X-API-Key", m_apiKey.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Library Management System Desktop v1.0");

    QNetworkReply *reply = m_networkManager->get(request);
    m_activeRequests[reply] = "connection_test";
    QTimer::singleShot(NETWORK_TIMEOUT, reply, [reply](){
        if (reply->isRunning()){
            reply->abort();
        }
    });

    connect(reply, &QNetworkReply::finished, this, &OpacManager::onNetworkReplyFinished);
}

void OpacManager::syncNow()
{
    if (m_isSyncing) {
        emit errorOccurred("Sync already in progress");
        return;
    }

    if (!m_isConfigured) {
        emit errorOccurred("OPAC not configured. Please configure first.");
        return;
    }

    // Check if this is first sync
    QDateTime lastBooksSync = getLastSyncTimestamp("books");

    if (!lastBooksSync.isValid()) {
        performFullSync();
    } else {
        performIncrementalSync();
    }
}

void OpacManager::syncBooks()
{
    if (m_isSyncing) {
        emit errorOccurred("Sync already in progress");
        return;
    }

    if (!m_isConfigured) {
        emit errorOccurred("OPAC not configured");
        return;
    }

    setIsSyncing(true);
    setSyncStatus("Syncing books...");

    QDateTime lastSync = getLastSyncTimestamp("books");
    QJsonArray books = getAllBooks(); //lastSync.isValid() ? getChangedBooks(lastSync) : getAllBooks();

    if (books.isEmpty()) {
        setSyncStatus("No books to sync");
        setIsSyncing(false);
        return;
    }

    QJsonObject payload;
    payload["books"] = books;

    sendHttpRequest("/api/sync/books", "POST", payload, "books_sync");
}

void OpacManager::syncUsers()
{
    if (m_isSyncing) {
        emit errorOccurred("Sync already in progress");
        return;
    }

    if (!m_isConfigured) {
        emit errorOccurred("OPAC not configured");
        return;
    }

    setIsSyncing(true);
    setSyncStatus("Syncing users...");

    QDateTime lastSync = getLastSyncTimestamp("users");
    QJsonObject users = getAllUsers(); //lastSync.isValid() ? getChangedUsers(lastSync) : getAllUsers();

    if (users.isEmpty()) {
        setSyncStatus("No users to sync");
        setIsSyncing(false);
        return;
    }

    // QJsonObject payload;
    // payload["users"] = users;

    sendHttpRequest("/api/sync/users", "POST", users, "users_sync");
}

void OpacManager::syncReservations()
{
    if (!m_isConfigured) {
        emit errorOccurred("OPAC not configured");
        return;
    }

    setSyncStatus("Checking for new reservations...");

    QDateTime lastSync = getLastSyncTimestamp("reservations");
    QUrl url(buildApiUrl("/api/sync/reservations"));
    QUrlQuery query;

    // Add query parameters
    // if (lastSync.isValid()) {
    //     query.addQueryItem("since", lastSync.toString(Qt::ISODate));
    // }
    query.addQueryItem("limit", "1000");

    url.setQuery(query);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("X-API-Key", m_apiKey.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Library Management System Desktop v1.0");

    QNetworkReply *reply = m_networkManager->get(request);
    m_activeRequests[reply] = "reservations_sync";

    connect(reply, &QNetworkReply::finished, this, &OpacManager::onNetworkReplyFinished);
}

QVariantList OpacManager::getReservationsList(const QString &filter)
{
    QMutexLocker locker(&m_mutex);
    QVariantList reservations;

    QString sql = "SELECT r.*, b.title, b.author, b.callNumber, b.availability "
                  "FROM reserved_books r "
                  "JOIN books b ON r.book_id = b.bookID ";

    if (filter != "all") {
        sql += "WHERE r.status = :status ";
    }

    sql += "ORDER BY r.reservation_date ASC";

    QSqlQuery query(m_db);
    query.prepare(sql);

    if (filter != "all") {
        query.bindValue(":status", filter);
    }

    if (!query.exec()) {
        qWarning() << "Error fetching reservations:" << query.lastError().text();
        return reservations;
    }

    while (query.next()) {
        QVariantMap res;
        res["reservationId"] = query.value("reservation_id").toInt();
        res["bookId"] = query.value("book_id").toInt();
        res["bookTitle"] = query.value("title").toString();
        res["bookAuthor"] = query.value("author").toString();
        res["callNumber"] = query.value("callNumber").toString();
        res["userId"] = query.value("user_id").toInt();
        res["userEmail"] = query.value("user_email").toString();
        res["userName"] = query.value("user_name").toString();
        res["reservationDate"] = query.value("reservation_date").toString();
        res["expiryDate"] = query.value("expiry_date").toString();
        res["status"] = query.value("status").toString();
        res["notificationSentDate"] = query.value("notification_sent_date").toString();
        res["pickupDeadline"] = query.value("pickup_deadline").toString();
        res["bookAvailability"] = query.value("availability").toString();
        res["notes"] = query.value("notes").toString();

        reservations.append(res);
    }

    return reservations;
}

bool OpacManager::cancelReservation(int reservationId)
{
    bool success = updateReservationStatus(reservationId, "cancelled");

    if (success) {
        // Update OPAC
        QString endpoint = QString("/api/sync/reservations/%1").arg(reservationId);
        QJsonObject data;
        data["status"] = "cancelled";

        sendHttpRequest(endpoint, "PUT", data, "reservation_update");

        emit reservationsUpdated();
    }

    return success;
}

bool OpacManager::fulfillReservation(int reservationId, int issueId)
{
    QMutexLocker locker(&m_mutex);

    // Update reservation status
    QSqlQuery query(m_db);
    query.prepare("UPDATE reserved_books SET status = 'fulfilled', updated_at = CURRENT_TIMESTAMP "
                  "WHERE reservation_id = :id");
    query.bindValue(":id", reservationId);

    if (!query.exec()) {
        qWarning() << "Error fulfilling reservation:" << query.lastError().text();
        return false;
    }

    // Link reservation to issued book
    query.prepare("UPDATE issued_books SET reservation_id = :res_id WHERE issue_id = :issue_id");
    query.bindValue(":res_id", reservationId);
    query.bindValue(":issue_id", issueId);

    if (!query.exec()) {
        qWarning() << "Error linking reservation to issue:" << query.lastError().text();
    }

    // Update OPAC
    QString endpoint = QString("/api/sync/reservations/%1").arg(reservationId);
    QJsonObject data;
    data["status"] = "fulfilled";

    sendHttpRequest(endpoint, "PUT", data, "reservation_update");

    updatePendingCount();
    emit reservationsUpdated();

    return true;
}

QVariantList OpacManager::getSyncHistory(int limit)
{
    QMutexLocker locker(&m_mutex);
    QVariantList history;

    QSqlQuery query(m_db);
    query.prepare("SELECT * FROM opac_sync_log ORDER BY started_at DESC LIMIT :limit");
    query.bindValue(":limit", limit);

    if (!query.exec()) {
        qWarning() << "Error fetching sync history:" << query.lastError().text();
        return history;
    }

    while (query.next()) {
        QVariantMap log;
        log["syncId"] = query.value("sync_id").toInt();
        log["syncType"] = query.value("sync_type").toString();
        log["direction"] = query.value("sync_direction").toString();
        log["recordsAffected"] = query.value("records_affected").toInt();
        log["status"] = query.value("status").toString();
        log["errorMessage"] = query.value("error_message").toString();
        log["startedAt"] = query.value("started_at").toString();
        log["completedAt"] = query.value("completed_at").toString();
        log["triggeredBy"] = query.value("triggered_by").toString();

        history.append(log);
    }

    return history;
}

bool OpacManager::clearSyncHistory()
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    if (!query.exec("DELETE FROM opac_sync_log")) {
        qWarning() << "Error clearing sync history:" << query.lastError().text();
        return false;
    }

    return true;
}

void OpacManager::onAutoSyncTimerTimeout()
{
    if (!m_isSyncing && m_isConfigured) {
        qDebug() << "Auto-sync triggered";
        performIncrementalSync();
    }
}

void OpacManager::onExpirationTimeTimeout()
{
    qDebug() << "Running expiration check";
    checkExpiredReservations();
}

void OpacManager::onNetworkReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    QString requestType = m_activeRequests.take(reply);
    QByteArray response = reply->readAll();
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    if (reply->error() == QNetworkReply::NoError){
        //success
        if (requestType == "connection_test"){
            handleConnectionTest(response);
        }else if(requestType == "books_sync"){
            handleBooksSync(response);
        }else if(requestType == "users_sync"){
            handleUsersSync(response);
        }else if (requestType == "reservations_sync"){
            handleReservationsSync(response);
        }else if (requestType == "reservation_update"){
            qDebug() << "Reservation updated successfully";
        }
    }else{
        //Error handling based on status code
        QString errorMsg = reply->errorString();

        //provide more specific error messages based on http status codes
        if (statusCode == 401){
            errorMsg = "Invalid or inactive API key. Please check your configuration.";
        }else if(statusCode == 404){
            errorMsg = "API endpoint not found. Check server url and version compatibility.";
        }else if(statusCode == 500){
            errorMsg = "Server error. Please try again later or contact support.";
        }else if (reply->error() == QNetworkReply::TimeoutError){
            errorMsg = "Request timed out. Check your internet connection.";
        }else if(reply->error() == QNetworkReply::ConnectionRefusedError){
            errorMsg = "Request refused. Is the server running?";
        }

        qWarning() << "Network error[" << statusCode << "]: " << errorMsg;
        qWarning() << "Response: " << response;

        if (requestType == "connection_test"){
            emit connectionTestResult(false, errorMsg);
            setSyncStatus("Connection failed");
        }else {
            emit syncFailed(errorMsg);
            logSyncOperation(requestType, "push", 0, "failed", errorMsg);
            setSyncStatus("Sync failed: " + errorMsg);
        }

        setIsSyncing(false);
    }

    reply->deleteLater();
}

bool OpacManager::createTables()
{
    //Because we already created tables in DatabaseManager class we only check if they exist

    QMutexLocker locker(&m_mutex);
    QStringList requiredTables = {
        "reserved_books",
        "opac_sync_log",
        "opac_configuration"
    };

    QStringList existingTables = m_db.tables();

    for (const QString &tableName : requiredTables){
        if (!existingTables.contains(tableName)){
            QString errorMsg = QString("Required table % does not exist. Please ensure DatabaseManager has created all tables")
            .arg(tableName);

            qWarning() << errorMsg;
            emit errorOccurred(errorMsg);
            return false;
        }
    }

    qDebug() << "All required OPAC tables verified successfully.";
    return true;
}

bool OpacManager::loadConfiguration()
{
    QMutexLocker locker(&m_mutex);
    QSqlQuery query(m_db);

    query.prepare("SELECT * FROM opac_configuration WHERE is_active = 1 ORDER BY config_id DESC LIMIT 1");

    if (!query.exec()){
        qWarning() << "Unable to load configuration: " << query.lastError().text();
        return false;
    }

    if (query.next()){
        m_opacUrl = query.value("opac_url").toString();
        m_apiKey = query.value("api_key").toString();
        m_syncIntervalMinutes = query.value("sync_interval_minutes").toInt();
        m_autoSyncEnabled = query.value("auto_sync_enabled").toBool();
        m_notificationPickupDays = query.value("notification_pickup_days").toInt();
        m_reservationExpiryDays = query.value("reservation_expiry_days").toInt();

        //get last sync time
        QDateTime lastSync = query.value("last_sync_time").toDateTime();
        if (lastSync.isValid()){
            m_lastSyncTime = lastSync.toString("yyyy-MM-dd hh:mm:ss");
        }else{
            m_lastSyncTime = "Never";
        }
        return true;
    }

    return false;
}

bool OpacManager::saveConfiguration()
{
    QMutexLocker locker(&m_mutex);
    QSqlQuery query(m_db);

    // Check if configuration exists
    query.prepare("SELECT config_id FROM opac_configuration WHERE is_active = 1 LIMIT 1");
    if (!query.exec()) {
        qWarning() << "Error checking configuration:" << query.lastError().text();
        return false;
    }

    bool configExists = query.next();
    int configId = configExists ? query.value(0).toInt() : 0;

    if (configExists) {
        // Update existing configuration
        query.prepare("UPDATE opac_configuration SET "
                      "opac_url = :url, api_key = :key, sync_interval_minutes = :interval, "
                      "auto_sync_enabled = :auto_sync, notification_pickup_days = :pickup_days, "
                      "reservation_expiry_days = :expiry_days, updated_at = CURRENT_TIMESTAMP "
                      "WHERE config_id = :id");
        query.bindValue(":id", configId);
    } else {
        // Insert new configuration
        query.prepare("INSERT INTO opac_configuration "
                      "(opac_url, api_key, sync_interval_minutes, auto_sync_enabled, "
                      "notification_pickup_days, reservation_expiry_days) "
                      "VALUES (:url, :key, :interval, :auto_sync, :pickup_days, :expiry_days)");
    }

    query.bindValue(":url", m_opacUrl);
    query.bindValue(":key", m_apiKey);
    query.bindValue(":interval", m_syncIntervalMinutes);
    query.bindValue(":auto_sync", m_autoSyncEnabled ? 1 : 0);
    query.bindValue(":pickup_days", m_notificationPickupDays);
    query.bindValue(":expiry_days", m_reservationExpiryDays);

    if (!query.exec()) {
        qWarning() << "Error saving configuration:" << query.lastError().text();
        emit errorOccurred("Failed to save configuration: " + query.lastError().text());
        return false;
    }

    return true;
}

bool OpacManager::validateConfiguration()
{
    if (m_opacUrl.isEmpty() || !m_opacUrl.startsWith("http")) {
        return false;
    }

    if (m_apiKey.isEmpty()) {
        return false;
    }

    if (m_syncIntervalMinutes < 15 || m_syncIntervalMinutes > (1440) ) {
        return false;
    }

    if (m_notificationPickupDays < 1 || m_notificationPickupDays > (7) ) {
        return false;
    }

    if (m_reservationExpiryDays < 3 || m_reservationExpiryDays > (30) ) {
        return false;
    }

    return true;
}

QDateTime OpacManager::getLastSyncTimestamp(const QString &syncType)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    QString column;

    if (syncType == "books") {
        column = "last_books_sync";
    } else if (syncType == "users") {
        column = "last_users_sync";
    } else if (syncType == "reservations") {
        column = "last_reservations_sync";
    } else {
        return QDateTime();
    }

    query.prepare(QString("SELECT %1 FROM opac_configuration WHERE is_active = 1 LIMIT 1").arg(column));

    if (!query.exec() || !query.next()) {
        return QDateTime();
    }

    return query.value(0).toDateTime();
}

bool OpacManager::updateLastSyncTimestamp(const QString &syncType, const QDateTime &timestamp)
{
    QMutexLocker locker(&m_mutex);

    QString column;

    if (syncType == "books") {
        column = "last_books_sync";
    } else if (syncType == "users") {
        column = "last_users_sync";
    } else if (syncType == "reservations") {
        column = "last_reservations_sync";
    } else {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QString("UPDATE opac_configuration SET %1 = :timestamp, updated_at = CURRENT_TIMESTAMP "
                          "WHERE is_active = 1").arg(column));
    query.bindValue(":timestamp", timestamp.toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "Error updating last sync timestamp:" << query.lastError().text();
        return false;
    }

    m_lastSyncTime = timestamp.toString("yyyy-MM-dd hh:mm:ss");
    emit lastSyncTimeChanged();

    return true;
}

bool OpacManager::logSyncOperation(const QString &syncType, const QString &direction, int recordsAffected,
                                   const QString &status, const QString &errorMessage)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare("INSERT INTO opac_sync_log "
                  "(sync_type, sync_direction, records_affected, status, error_message, "
                  "started_at, completed_at, triggered_by) "
                  "VALUES (:type, :direction, :records, :status, :error, "
                  ":started, CURRENT_TIMESTAMP, :triggered)");

    query.bindValue(":type", syncType);
    query.bindValue(":direction", direction);
    query.bindValue(":records", recordsAffected);
    query.bindValue(":status", status);
    query.bindValue(":error", errorMessage.isEmpty() ? QVariant() : errorMessage);
    query.bindValue(":started", QDateTime::currentDateTime().toString(Qt::ISODate));
    query.bindValue(":triggered", m_autoSyncTimer->isActive() ? "automatic" : "manual");

    if (!query.exec()) {
        qWarning() << "Error logging sync operation:" << query.lastError().text();
        return false;
    }

    return true;
}

QJsonArray OpacManager::getChangedBooks(const QDateTime &since)
{
    QMutexLocker locker(&m_mutex);
    QJsonArray books;

    QSqlQuery query(m_db);
    query.prepare("SELECT * FROM books WHERE dateAdded >= :since");
    query.bindValue(":since", since.toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "Error fetching changed books:" << query.lastError().text();
        return books;
    }

    while (query.next()) {
        QJsonObject book;
        book["book_id"] = query.value("bookID").toInt();
        book["title"] = query.value("title").toString();
        book["author"] = query.value("author").toString();
        book["call_number"] = query.value("callNumber").toString();
        book["publisher"] = query.value("publisher").toString();
        book["isbn"] = query.value("isbn").toString();
        book["barcode"] = query.value("barcode").toString();
        book["year_published"] = query.value("year_published").toString();
        book["shelf_number"] = query.value("shelfNumber").toString();
        book["description"] = query.value("description").toString();
        book["language"] = query.value("language").toString();
        book["subject"] = query.value("subject").toString();
        book["genre"] = query.value("genre").toString();
        book["value"] = query.value("value").toInt();
        book["acquisition_method"] = query.value("method").toString();
        book["date_added"] = query.value("dateAdded").toString();
        book["availability"] = query.value("availability").toString();
        book["times_borrowed"] = query.value("timesBorrowed").toInt();
        book["condition"] = query.value("condition").toString();

        books.append(book);
    }

    return books;
}

QJsonArray OpacManager::getChangedUsers(const QDateTime &since)
{
    QMutexLocker locker(&m_mutex);
    QJsonArray users;

    QSqlQuery query(m_db);
    query.prepare("SELECT u.*, "
                  "s.adm_no, s.branch, s.enrollment_year, s.level, "
                  "st.staff_no, st.department, st.start_year, st.category, "
                  "o.user_no, o.residence, o.age, o.gender "
                  "FROM users u "
                  "LEFT JOIN students s ON u.user_id = s.student_id "
                  "LEFT JOIN staff st ON u.user_id = st.staff_id "
                  "LEFT JOIN other_users o ON u.user_id = o.other_users_id "
                  "WHERE u.updated_at >= :since");
    query.bindValue(":since", since.toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "Error fetching changed users:" << query.lastError().text();
        return users;
    }

    while (query.next()) {
        QJsonObject user;
        user["user_id"] = query.value("user_id").toInt();
        user["first_name"] = query.value("first_name").toString();
        user["second_name"] = query.value("second_name").toString();
        user["email"] = query.value("email").toString();
        user["phone"] = query.value("phone").toString();
        user["user_role"] = query.value("user_role").toString();
        user["status"] = query.value("status").toString();
        user["created_at"] = query.value("created_at").toString();
        user["updated_at"] = query.value("updated_at").toString();

        QString role = query.value("user_role").toString();

        if (role == "student") {
            user["adm_no"] = query.value("adm_no").toString();
            user["branch"] = query.value("branch").toString();
            user["enrollment_year"] = query.value("enrollment_year").toInt();
            user["level"] = query.value("level").toString();
        } else if (role == "staff") {
            user["staff_no"] = query.value("staff_no").toString();
            user["department"] = query.value("department").toString();
            user["start_year"] = query.value("start_year").toInt();
            user["category"] = query.value("category").toString();
        } else if (role == "other_user") {
            user["user_no"] = query.value("user_no").toString();
            user["residence"] = query.value("residence").toString();
            user["age"] = query.value("age").toInt();
            user["gender"] = query.value("gender").toString();
        }

        users.append(user);
    }

    return users;
}

QJsonArray OpacManager::getAllBooks()
{
    QMutexLocker locker(&m_mutex);
    QJsonArray books;

    QSqlQuery query(m_db);
    query.prepare("SELECT * FROM books");

    if (!query.exec()) {
        qWarning() << "Error fetching books:" << query.lastError().text();
        return books;
    }

    qDebug() << "Books fetched";

    while (query.next()) {
        QJsonObject book;
        book["book_id"] = query.value("bookID").toInt();
        book["title"] = query.value("title").toString();
        book["author"] = query.value("author").toString();
        book["call_number"] = query.value("callNumber").toString();
        book["publisher"] = query.value("publisher").toString();
        book["isbn"] = query.value("isbn").toString();
        book["barcode"] = query.value("barcode").toString();
        book["year_published"] = query.value("year_published").toString();
        book["shelf_number"] = query.value("shelfNumber").toString();
        book["description"] = query.value("description").toString();
        book["language"] = query.value("language").toString();
        book["subject"] = query.value("subject").toString();
        book["genre"] = query.value("genre").toString();
        book["value"] = query.value("value").toInt();
        book["acquisition_method"] = query.value("method").toString();
        book["date_added"] = query.value("dateAdded").toString();
        book["availability"] = query.value("availability").toString();
        book["times_borrowed"] = query.value("timesBorrowed").toInt();
        book["condition"] = query.value("condition").toString();

        books.append(book);
    }

    qDebug() << "Books fetched";

    return books;
}

QJsonObject OpacManager::getAllUsers() {
    QJsonObject result;
    QJsonArray usersArray, studentsArray, staffArray, otherUsersArray;

    //check if the database is open first
    if(!m_db.open()){
        qDebug() << "Database is not open";
        return result;
    }

    // Query all users with their role data
    QSqlQuery query(m_db);
    query.prepare("SELECT u.*, s.adm_no, s.branch, s.enrollment_year, s.level, "
                  "st.staff_no, st.department, st.start_year, st.category, "
                  "o.user_no, o.residence, o.age, o.gender "
                  "FROM users u "
                  "LEFT JOIN students s ON u.user_id = s.student_id "
                  "LEFT JOIN staff st ON u.user_id = st.staff_id "
                  "LEFT JOIN other_users o ON u.user_id = o.other_users_id");

    if (!query.exec()) {
        qWarning() << "Failed to fetch users:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QString userRole = query.value("user_role").toString();

        // normalize user_role format
        // Convert "Student" -> "student", "Staff" -> "staff", "Other user" -> "other_user"
        QString normalizedRole = userRole.toLower().trimmed();
        if (normalizedRole == "other user" || normalizedRole == "other") {
            normalizedRole = "other_user";
        }

        // Base user object
        QJsonObject userObj;
        userObj["first_name"] = query.value("first_name").toString();
        userObj["second_name"] = query.value("second_name").toString();
        userObj["email"] = query.value("email").toString();

        // truncate phone to max 20 characters
        QString phone = query.value("phone").toString();
        if (phone.length() > 20) {
            phone = phone.left(20);  // Truncate to 20 chars
        }
        userObj["phone"] = phone;

        userObj["user_role"] = normalizedRole;  // Use normalized role
        userObj["status"] = query.value("status").toString();

        // FIX 3: Set password based on role
        QString password;
        if (normalizedRole == "student") {
            password = query.value("adm_no").toString();
        } else if (normalizedRole == "staff") {
            password = query.value("staff_no").toString();
        } else if (normalizedRole == "other_user") {
            password = query.value("user_no").toString();
        }

        // Ensure password is not empty
        if (password.isEmpty()) {
            qWarning() << "Skipping user with empty password:"
                       << query.value("email").toString();
            continue;  // Skip this user
        }

        userObj["password"] = password;

        if (query.value("user_id").toInt() > 0) {
            userObj["user_id"] = query.value("user_id").toInt();
        }

        usersArray.append(userObj);

        // Role-specific data
        if (normalizedRole == "student") {
            QJsonObject studentObj;
            studentObj["adm_no"] = query.value("adm_no").toString();

            QVariant branchVar = query.value("branch");
            if (!branchVar.isNull()) {
                studentObj["branch"] = branchVar.toString();
            }

            QVariant enrollmentVar = query.value("enrollment_year");
            if (!enrollmentVar.isNull()) {
                studentObj["enrollment_year"] = enrollmentVar.toInt();
            }

            QVariant levelVar = query.value("level");
            if (!levelVar.isNull()) {
                studentObj["level"] = levelVar.toString();
            }

            studentsArray.append(studentObj);
        }
        else if (normalizedRole == "staff") {
            QJsonObject staffObj;
            staffObj["staff_no"] = query.value("staff_no").toString();
            staffObj["department"] = query.value("department").toString();

            QVariant startYearVar = query.value("start_year");
            if (!startYearVar.isNull()) {
                staffObj["start_year"] = startYearVar.toInt();
            }

            QVariant categoryVar = query.value("category");
            if (!categoryVar.isNull()) {
                staffObj["category"] = categoryVar.toString();
            }

            staffArray.append(staffObj);
        }
        else if (normalizedRole == "other_user") {
            QJsonObject otherObj;
            otherObj["user_no"] = query.value("user_no").toString();

            QVariant residenceVar = query.value("residence");
            if (!residenceVar.isNull()) {
                otherObj["residence"] = residenceVar.toString();
            }

            QVariant ageVar = query.value("age");
            if (!ageVar.isNull()) {
                otherObj["age"] = ageVar.toInt();
            }

            QVariant genderVar = query.value("gender");
            if (!genderVar.isNull()) {
                otherObj["gender"] = genderVar.toString();
            }

            otherUsersArray.append(otherObj);
        }
    }

    result["users"] = usersArray;
    result["students"] = studentsArray;
    result["staff"] = staffArray;
    result["other_users"] = otherUsersArray;

    qDebug() << "Prepared user sync data:"
             << usersArray.size() << "users,"
             << studentsArray.size() << "students,"
             << staffArray.size() << "staff,"
             << otherUsersArray.size() << "other_users";

    return result;
}

bool OpacManager::saveReservations(const QJsonArray &reservations)
{
    QMutexLocker locker(&m_mutex);

    m_db.transaction();

    for (const QJsonValue &val : reservations) {
        QJsonObject res = val.toObject();

        QSqlQuery query(m_db);

        // Check if reservation already exists
        query.prepare("SELECT reservation_id FROM reserved_books WHERE reservation_id = :id");
        query.bindValue(":id", res["reservation_id"].toInt());

        if (!query.exec()) {
            qWarning() << "Error checking reservation:" << query.lastError().text();
            continue;
        }

        bool exists = query.next();

        if (exists) {
            // Update existing reservation
            query.prepare("UPDATE reserved_books SET status = :status, updated_at = CURRENT_TIMESTAMP "
                          "WHERE reservation_id = :id");
            query.bindValue(":status", res["status"].toString());
            query.bindValue(":id", res["reservation_id"].toInt());
        } else {
            // Insert new reservation
            query.prepare("INSERT INTO reserved_books "
                          "(reservation_id, book_id, user_id, user_email, user_name, "
                          "reservation_date, expiry_date, status, notes) "
                          "VALUES (:id, :book_id, :user_id, :email, :name, :res_date, :exp_date, :status, :notes)");

            query.bindValue(":id", res["reservation_id"].toInt());
            query.bindValue(":book_id", res["book_id"].toInt());
            query.bindValue(":user_id", res["user_id"].toInt());
            query.bindValue(":email", res["user_email"].toString());
            query.bindValue(":name", res["user_name"].toString());
            query.bindValue(":res_date", res["reservation_date"].toString());
            query.bindValue(":exp_date", res["expiry_date"].toString());
            query.bindValue(":status", res["status"].toString());
            query.bindValue(":notes", res["notes"].toString());
        }

        if (!query.exec()) {
            qWarning() << "Error saving reservation:" << query.lastError().text();
            m_db.rollback();
            return false;
        }
    }

    if (!m_db.commit()) {
        qWarning() << "Error committing reservations:" << m_db.lastError().text();
        return false;
    }

    // Check book availability and notify if needed
    checkBookAvailability();
    updatePendingCount();
    emit reservationsUpdated();

    return true;
}

bool OpacManager::updateReservationStatus(int reservationId, const QString &status, const QDateTime &notificationDate, const QDateTime &pickupDeadline)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare("UPDATE reserved_books SET status = :status, "
                  "notification_sent_date = :notif_date, pickup_deadline = :deadline, "
                  "updated_at = CURRENT_TIMESTAMP WHERE reservation_id = :id");

    query.bindValue(":status", status);
    query.bindValue(":notif_date", notificationDate.isValid() ?
                                       notificationDate.toString(Qt::ISODate) : QVariant());
    query.bindValue(":deadline", pickupDeadline.isValid() ?
                                     pickupDeadline.toString(Qt::ISODate) : QVariant());
    query.bindValue(":id", reservationId);

    if (!query.exec()) {
        qWarning() << "Error updating reservation status:" << query.lastError().text();
        return false;
    }

    updatePendingCount();
    return true;
}

void OpacManager::checkExpiredReservations()
{
    QMutexLocker locker(&m_mutex);

    QDateTime now = QDateTime::currentDateTime();
    QSqlQuery query(m_db);

    // Expire reservations that passed expiry_date
    query.prepare("UPDATE reserved_books SET status = 'expired', updated_at = CURRENT_TIMESTAMP "
                  "WHERE (status = 'pending' OR status = 'notified') AND expiry_date < :now");
    query.bindValue(":now", now.toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "Error expiring reservations:" << query.lastError().text();
        return;
    }

    int expiredCount = query.numRowsAffected();

    // Expire notified reservations that passed pickup_deadline
    query.prepare("UPDATE reserved_books SET status = 'expired', updated_at = CURRENT_TIMESTAMP "
                  "WHERE status = 'notified' AND pickup_deadline < :now");
    query.bindValue(":now", now.toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "Error expiring notified reservations:" << query.lastError().text();
        return;
    }

    expiredCount += query.numRowsAffected();

    if (expiredCount > 0) {
        qDebug() << "Expired" << expiredCount << "reservations";
        updatePendingCount();
        emit reservationsUpdated();

        // Check if we can notify next person in queue
        checkBookAvailability();
    }
}

void OpacManager::checkBookAvailability()
{
    QMutexLocker locker(&m_mutex);

    // Get all books with pending reservations
    QSqlQuery query(m_db);
    query.prepare("SELECT DISTINCT book_id FROM reserved_books WHERE status = 'pending'");

    if (!query.exec()) {
        qWarning() << "Error checking book availability:" << query.lastError().text();
        return;
    }

    while (query.next()) {
        int bookId = query.value(0).toInt();

        // Check if book is available
        QSqlQuery bookQuery(m_db);
        bookQuery.prepare("SELECT availability FROM books WHERE bookID = :id");
        bookQuery.bindValue(":id", bookId);

        if (!bookQuery.exec() || !bookQuery.next()) {
            continue;
        }

        QString availability = bookQuery.value(0).toString();

        if (availability == "Available") {
            // Get next reservation in queue
            int nextReservation = getNextInQueue(bookId);

            if (nextReservation > 0) {
                notifyUserBookReady(nextReservation);
            }
        }
    }
}

int OpacManager::getNextInQueue(int bookId)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare("SELECT reservation_id FROM reserved_books "
                  "WHERE book_id = :book_id AND status = 'pending' "
                  "ORDER BY reservation_date ASC LIMIT 1");
    query.bindValue(":book_id", bookId);

    if (!query.exec()) {
        qWarning() << "Error getting next in queue:" << query.lastError().text();
        return -1;
    }

    if (query.next()) {
        return query.value(0).toInt();
    }

    return -1;
}

bool OpacManager::notifyUserBookReady(int reservationId)
{
    QDateTime notificationDate = QDateTime::currentDateTime();
    QDateTime pickupDeadline = notificationDate.addDays(m_notificationPickupDays);

    bool success = updateReservationStatus(reservationId, "notified", notificationDate, pickupDeadline);

    if (success) {
        // Update book availability to Reserved
        QMutexLocker locker(&m_mutex);

        QSqlQuery query(m_db);
        query.prepare("UPDATE books SET availability = 'Reserved' "
                      "WHERE bookID = (SELECT book_id FROM reserved_books WHERE reservation_id = :id)");
        query.bindValue(":id", reservationId);
        query.exec();

        // Update OPAC
        QString endpoint = QString("/api/sync/reservations/%1").arg(reservationId);
        QJsonObject data;
        data["status"] = "notified";
        data["notification_sent_date"] = notificationDate.toString(Qt::ISODate);
        data["pickup_deadline"] = pickupDeadline.toString(Qt::ISODate);

        sendHttpRequest(endpoint, "PUT", data, "reservation_update");

        qDebug() << "Notified user for reservation" << reservationId;
    }

    return success;
}

void OpacManager::updatePendingCount()
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare("SELECT COUNT(*) FROM reserved_books WHERE status IN ('pending', 'notified')");

    if (query.exec() && query.next()) {
        int count = query.value(0).toInt();
        if (count != m_pendingReservationsCount) {
            m_pendingReservationsCount = count;
            emit pendingReservationsCountChanged();
        }
    }
}

void OpacManager::sendHttpRequest(const QString &endpoint, const QString &method, const QJsonObject &data, const QString &requestType)
{
    QUrl url(buildApiUrl(endpoint));

    QNetworkRequest request(url);

    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("X-API-Key", m_apiKey.toUtf8());
    request.setRawHeader("User-Agent", "Library Management System Desktop v1.0");

    QNetworkReply *reply = nullptr;

    if (method == "GET"){
        reply = m_networkManager->get(request);
    }else if (method == "POST"){
        QJsonDocument doc(data);
        reply = m_networkManager->post(request, doc.toJson());
    }else if (method == "PUT"){
        QJsonDocument doc(data);
        reply = m_networkManager->put(request, doc.toJson());
    }

    if (reply){
        m_activeRequests[reply] = requestType;

        //Set timeout
        QTimer::singleShot(NETWORK_TIMEOUT, reply, [reply](){
            if (reply->isRunning()){
                reply->abort();
            }
        });

        connect(reply, &QNetworkReply::finished, this, &OpacManager::onNetworkReplyFinished);
    }
}

void OpacManager::handleBooksSync(const QByteArray &response)
{
    QJsonDocument doc = QJsonDocument::fromJson(response);
    QJsonObject obj = doc.object();

    QString status = obj["status"].toString();
    int created = obj["records_created"].toInt();
    int updated = obj["records_updated"].toInt();
    int recordsReceived = obj["records_received"].toInt();
    QJsonArray errors = obj["errors"].toArray();

    if (status == "error") {
        QString errorMsg = obj["message"].toString();
        qWarning() << "Books sync failed:" << errorMsg;
        emit syncFailed("Books sync failed: " + errorMsg);
        logSyncOperation("books", "push", 0, "failed", errorMsg);
        setIsSyncing(false);
        return;
    }

    qDebug() << "Books sync completed:" << created << "created," << updated << "updated";

    if (!errors.isEmpty()) {
        qWarning() << "Books sync completed with" << errors.size() << "errors";
    }

    updateLastSyncTimestamp("books", QDateTime::currentDateTime());
    logSyncOperation("books", "push", created + updated,
                     errors.isEmpty() ? "success" : "partial_success");

    setSyncStatus(QString("Books synced: %1 created, %2 updated").arg(created).arg(updated));

    // Complete the sync operation
    setIsSyncing(false);
    emit syncCompleted(QString("Books synced: %1 created, %2 updated").arg(created).arg(updated));
}

void OpacManager::handleUsersSync(const QByteArray &response)
{
    QJsonDocument doc = QJsonDocument::fromJson(response);
    QJsonObject obj = doc.object();

    QString status = obj["status"].toString();
    int created = obj["records_created"].toInt();
    int updated = obj["records_updated"].toInt();
    int recordsReceived = obj["records_received"].toInt();
    QJsonArray errors = obj["errors"].toArray();

    if (status == "error") {
        QString errorMsg = obj["message"].toString();
        qWarning() << "Users sync failed:" << errorMsg;
        emit syncFailed("Users sync failed: " + errorMsg);
        logSyncOperation("users", "push", 0, "failed", errorMsg);
        setIsSyncing(false);
        return;
    }

    qDebug() << "Users sync completed:" << created << "created," << updated << "updated";

    if (!errors.isEmpty()) {
        qWarning() << "Users sync completed with" << errors.size() << "errors";
    }

    updateLastSyncTimestamp("users", QDateTime::currentDateTime());
    logSyncOperation("users", "push", created + updated,
                     errors.isEmpty() ? "success" : "partial_success");

    setSyncStatus(QString("Users synced: %1 created, %2 updated").arg(created).arg(updated));

    // Complete the sync operation
    setIsSyncing(false);
    emit syncCompleted(QString("Users synced: %1 created, %2 updated").arg(created).arg(updated));
}

void OpacManager::handleReservationsSync(const QByteArray &response)
{
    //launch async reservation handling
    // Parse JSON response
    QJsonDocument doc = QJsonDocument::fromJson(response);
    QJsonObject obj = doc.object();
    QJsonArray reservations = obj["reservations"].toArray();
    int count = obj["count"].toInt(reservations.size());

    qDebug() << "Number  of reservations: " << count;

    handleReservationsSyncAsync(response);
}

void OpacManager::handleConnectionTest(const QByteArray &response)
{
    QJsonDocument doc = QJsonDocument::fromJson(response);

    // The /api/sync/logs endpoint returns a list of sync logs
    // If we can parse it successfully, the connection is valid
    if (doc.isObject() || doc.isArray()){
        emit connectionTestResult(true, "Connection successful- API Key is valid.");
        setSyncStatus("Connected to OPAC");
        qDebug() << "Connection successful";
    }else {
        emit connectionTestResult(false, "Ivalid response from server");
        qWarning() << "Connection test: Invalid response format";
    }
}

void OpacManager::setSyncStatus(const QString &status)
{
    if (m_syncStatus == status) return;

    m_syncStatus = status;
    emit syncStatusChanged();
}

void OpacManager::setIsSyncing(bool syncing)
{
    if (m_isSyncing == syncing) return;

    m_isSyncing = syncing;
    emit syncingChanged();
}

void OpacManager::startAutoSync()
{
    m_autoSyncTimer->stop();
    m_autoSyncTimer->setInterval(m_syncIntervalMinutes * 60 * 1000);
    m_autoSyncTimer->start();

    qDebug() << "Auto-sync started with interval:" << m_syncIntervalMinutes << "minutes";
}

void OpacManager::stopAutoSync()
{
    m_autoSyncTimer->stop();
    qDebug() << "Auto-sync stopped";
}

QString OpacManager::buildApiUrl(const QString &endpoint)
{
    QString url = m_opacUrl;
    if (!url.endsWith("/")) {
        url += "/";
    }
    if (endpoint.startsWith("/")) {
        url += endpoint.mid(1);
    } else {
        url += endpoint;
    }
    return url;
}

QFuture<bool> OpacManager::handleReservationsSyncAsync(const QByteArray &response)
{
    return QtConcurrent::run([this, response]() -> bool {
        // Create a separate database connection for this thread
        QString connectionName = QString("opac_reservations_thread_%1").arg(reinterpret_cast<quintptr>(QThread::currentThread()));


        QSqlDatabase threadDb = QSqlDatabase::addDatabase("QSQLITE", connectionName);
        threadDb.setDatabaseName(m_db.databaseName()); // Use same database file

        if (!threadDb.open()) {
            qWarning() << "Failed to open database in thread:" << threadDb.lastError().text();

            // Clean up and notify on main thread
            QMetaObject::invokeMethod(this, [this]() {
                emit syncFailed("Failed to save reservations: Database connection error");
                logSyncOperation("reservations", "pull", 0, "failed", "Database connection error");
                setIsSyncing(false);
            }, Qt::QueuedConnection);

            QSqlDatabase::removeDatabase(connectionName);
            return false;
        }

        // Parse JSON response
        QJsonDocument doc = QJsonDocument::fromJson(response);
        QJsonObject obj = doc.object();
        QJsonArray reservations = obj["reservations"].toArray();
        int count = obj["count"].toInt(reservations.size());

        qDebug() << "Number  of reservations: " << count;

        if (reservations.isEmpty()) {
            // Update on main thread
            QMetaObject::invokeMethod(this, [this]() {
                setSyncStatus("No new reservations");
                updateLastSyncTimestamp("reservations", QDateTime::currentDateTime());
                logSyncOperation("reservations", "pull", 0, "success");
                setIsSyncing(false);
                emit syncCompleted("No new reservations");
            }, Qt::QueuedConnection);

            threadDb.close();
            QSqlDatabase::removeDatabase(connectionName);
            return true;
        }

        // Save reservations using the thread-specific connection
        bool success = saveReservationsInThread(reservations, threadDb);

        if (success) {
            qDebug() << "Saved" << count << "reservations";

            // Schedule checkBookAvailability and UI updates on main thread
            QMetaObject::invokeMethod(this, [this, count]() {
                updateLastSyncTimestamp("reservations", QDateTime::currentDateTime());
                logSyncOperation("reservations", "pull", count, "success");
                setSyncStatus(QString("Received %1 new reservations").arg(count));

                // Defer heavy operations
                QTimer::singleShot(500, this, [this]() {
                    checkBookAvailability();
                    updatePendingCount();
                    emit reservationsUpdated();
                });

                setIsSyncing(false);
                emit syncCompleted(QString("Received %1 new reservations").arg(count));
            }, Qt::QueuedConnection);
        } else {
            // Notify failure on main thread
            QMetaObject::invokeMethod(this, [this]() {
                emit syncFailed("Failed to save reservations");
                logSyncOperation("reservations", "pull", 0, "failed", "Database error");
                setIsSyncing(false);
            }, Qt::QueuedConnection);
        }

        // Close and remove thread-specific connection
        threadDb.close();
        QSqlDatabase::removeDatabase(connectionName);

        return success;
    });
}

//helper function to save the reservations to the database using a specific database connection
bool OpacManager::saveReservationsInThread(const QJsonArray &reservations, QSqlDatabase &db)
{
    // No mutex needed as this runs on background thread with its own connection

    db.transaction();

    for (const QJsonValue &val : reservations) {
        QJsonObject res = val.toObject();

        QSqlQuery query(db); // Use the thread-specific database

        // Check if reservation already exists
        query.prepare("SELECT reservation_id FROM reserved_books WHERE reservation_id = :id");
        query.bindValue(":id", res["reservation_id"].toInt());

        if (!query.exec()) {
            qWarning() << "Error checking reservation:" << query.lastError().text();
            continue;
        }

        bool exists = query.next();

        if (exists) {
            // Update existing reservation
            query.prepare("UPDATE reserved_books SET status = :status, updated_at = CURRENT_TIMESTAMP "
                          "WHERE reservation_id = :id");
            query.bindValue(":status", res["status"].toString());
            query.bindValue(":id", res["reservation_id"].toInt());
        } else {
            // Insert new reservation
            query.prepare("INSERT INTO reserved_books "
                          "(reservation_id, book_id, user_id, user_email, user_name, "
                          "reservation_date, expiry_date, status, notes) "
                          "VALUES (:id, :book_id, :user_id, :email, :name, :res_date, :exp_date, :status, :notes)");

            query.bindValue(":id", res["reservation_id"].toInt());
            query.bindValue(":book_id", res["book_id"].toInt());
            query.bindValue(":user_id", res["user_id"].toInt());
            query.bindValue(":email", res["user_email"].toString());
            query.bindValue(":name", res["user_name"].toString());
            query.bindValue(":res_date", res["reservation_date"].toString());
            query.bindValue(":exp_date", res["expiry_date"].toString());
            query.bindValue(":status", res["status"].toString());
            query.bindValue(":notes", res["notes"].toString());
        }

        if (!query.exec()) {
            qWarning() << "Error saving reservation:" << query.lastError().text();
            db.rollback();
            return false;
        }
    }

    if (!db.commit()) {
        qWarning() << "Error committing reservations:" << db.lastError().text();
        return false;
    }

    return true;
}

void OpacManager::performFullSync()
{
    setIsSyncing(true);
    setSyncStatus("Starting full synchronization...");

    QDateTime startTime = QDateTime::currentDateTime();

    //Get all books
    QJsonArray books = getAllBooks();

    setSyncStatus(QString("Syncing %1 books....").arg(books.size()));

    //send books in batches
    int totalBooks = books.size();
    int batchCount = (totalBooks + BATCH_SIZE -1)/BATCH_SIZE;

    for (int i = 0; i < batchCount; i++){
        int start = i * BATCH_SIZE;
        int end = qMin(start + BATCH_SIZE, totalBooks);

        QJsonArray batch;
        for (int j = start; j < end; j++){
            batch.append(books[j]);
        }

        //Payload matches the BookSync request from the API
        QJsonObject payload;
        payload["books"] = batch;

        sendHttpRequest("/api/sync/books", "POST", payload, "books_sync");

        QThread::msleep(500);
    }

    // // Sync users
    // setSyncStatus("Syncing users...");
    // QJsonArray users = getAllUsers();

    // int totalUsers = users.size();
    // int userBatchCount = (totalUsers + BATCH_SIZE - 1) / BATCH_SIZE;

    // for (int i = 0; i < userBatchCount; i++) {
    //     int start = i * BATCH_SIZE;
    //     int end = qMin(start + BATCH_SIZE, totalUsers);

    //     QJsonArray batch;
    //     for (int j = start; j < end; j++) {
    //         batch.append(users[j]);
    //     }

    //     // Payload matches the UserSyncRequest schema from the API
    //     // Note: The API expects embedded role-specific data within each user object
    //     QJsonObject payload;
    //     payload["users"] = batch;

    //     sendHttpRequest("/api/sync/users", "POST", payload, "users_sync");

    //     QThread::msleep(500);
    // }

    // Sync users
    setSyncStatus("Syncing users...");
    QJsonObject allUserData = getAllUsers();  // returns properly structured object

    // Extract the separate arrays
    QJsonArray users = allUserData["users"].toArray();
    QJsonArray students = allUserData["students"].toArray();
    QJsonArray staff = allUserData["staff"].toArray();
    QJsonArray otherUsers = allUserData["other_users"].toArray();

    int totalUsers = users.size();
    int userBatchCount = (totalUsers + BATCH_SIZE - 1) / BATCH_SIZE;

    for (int i = 0; i < userBatchCount; i++) {
        int start = i * BATCH_SIZE;
        int end = qMin(start + BATCH_SIZE, totalUsers);

        // Build batches for all arrays proportionally
        QJsonArray userBatch;
        QJsonArray studentBatch;
        QJsonArray staffBatch;
        QJsonArray otherUserBatch;

        for (int j = start; j < end; j++) {
            userBatch.append(users[j]);

            // Add corresponding role-specific data
            QString role = users[j].toObject()["user_role"].toString();

            // Find and add the matching role-specific record
            if (role == "student" && j < students.size()) {
                studentBatch.append(students[j]);
            } else if (role == "staff" && j < staff.size()) {
                staffBatch.append(staff[j]);
            } else if (role == "other_user" && j < otherUsers.size()) {
                otherUserBatch.append(otherUsers[j]);
            }
        }

        // Payload with separate arrays (matches backend UserSyncRequest schema)
        QJsonObject payload;
        payload["users"] = userBatch;
        payload["students"] = studentBatch;
        payload["staff"] = staffBatch;
        payload["other_users"] = otherUserBatch;

        sendHttpRequest("/api/sync/users", "POST", payload, "users_sync");

        QThread::msleep(500);
    }

    // Update timestamps
    updateLastSyncTimestamp("books", QDateTime::currentDateTime());
    updateLastSyncTimestamp("users", QDateTime::currentDateTime());

    // Check for reservations (this will complete the sync when it finishes)
    syncReservations();

    logSyncOperation("full", "push", totalBooks + totalUsers, "success");

    // Note: setIsSyncing(false) will be called by the handler functions when network requests complete
}

void OpacManager::performIncrementalSync()
{
    setIsSyncing(true);
    setSyncStatus("Starting incremental syncing....");

    //get last sync timestamps
    QDateTime lastBooksSyncTime = getLastSyncTimestamp("books");
    QDateTime lastUsersSyncTime = getLastSyncTimestamp("users");

    //get changed books
    QJsonArray changedBooks = getChangedBooks(lastBooksSyncTime);
    if(!changedBooks.empty()){
        setSyncStatus(QString("Syncing %1 books...").arg(changedBooks.size()));

        QJsonObject payload;
        payload["books"] = changedBooks;

        sendHttpRequest("/api/sync/books", "POST", payload, "books_sync");
        updateLastSyncTimestamp("books", QDateTime::currentDateTime());
    }

    // Get changed users
    QJsonArray changedUsers = getChangedUsers(lastUsersSyncTime);
    if (!changedUsers.isEmpty()) {
        setSyncStatus(QString("Syncing %1 changed users...").arg(changedUsers.size()));

        QJsonObject payload;
        payload["users"] = changedUsers;

        sendHttpRequest("/api/sync/users", "POST", payload, "users_sync");
        updateLastSyncTimestamp("users", QDateTime::currentDateTime());
    }

    // Check for new reservations (this will complete the sync when it finishes)
    syncReservations();

    int totalChanged = changedBooks.size() + changedUsers.size();

    if (totalChanged > 0) {
        logSyncOperation("incremental", "push", totalChanged, "success");
    }

}

