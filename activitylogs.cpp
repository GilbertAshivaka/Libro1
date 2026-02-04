#include "activitylogs.h"

// Define the static mutex
QMutex ActivityLogs::logsMutex;

ActivityLogs::ActivityLogs(QObject *parent)
    : QObject{parent}
{
    db = DatabaseManager::getConnection();
    // executeSystemLogsInsert();
}

ActivityLogs::~ActivityLogs()
{
    //Qt  will take care of automatic destruction
}

bool ActivityLogs::logActivity(const QString &level, const QString &category, const QString &message, const QString &details, int userId)
{
    QMutexLocker locker(&logsMutex);

    // Get database connection directly (static method, no instance)
    QSqlDatabase db = DatabaseManager::getConnection();

    if (!db.isOpen() && !db.open()){
        qDebug() << "Failed to open the database for logging activity: " << db.lastError().text();
        return false;
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO system_logs (log_level, log_category, log_message, details, user_id) "
                  "VALUES (?, ?, ?, ?, ?)");

    query.addBindValue(level);
    query.addBindValue(category);
    query.addBindValue(message);
    query.addBindValue(details.isEmpty() ? QVariant() : details);
    query.addBindValue(userId == -1 ? QVariant() : userId);

    if (!query.exec()){
        qDebug() << "Failed to log activity: " << query.lastError().text();
        return false;
    }

    return true;
}

QList<QVariantMap> ActivityLogs::getLogs(const QString &level, const QString &category, int limit, int offset)
{
    QList<QVariantMap> logs;

    if (!db.open()){
        emit errorOccured("Failed to open the database to get the logs: " + db.lastError().text());
        qDebug() << "Failed to open the database to get the logs: " << db.lastError().text();
        return logs;
    }

    QString queryStr = "SELECT l.log_id, l.log_level, l.log_category, l.log_message, "
                       "l.details, l.user_id, u.first_name, u.second_name, l.timestamp "
                       "FROM system_logs l "
                       "LEFT JOIN users u ON l.user_id = u.user_id WHERE 1=1";


    QSqlQuery query(db);

    if (!level.isEmpty()) {
        queryStr += " AND l.log_level = ?";
    }
    if (!category.isEmpty()) {
        queryStr += " AND l.log_category = ?";
    }

    queryStr += " ORDER BY l.timestamp DESC LIMIT ? OFFSET ?";

    query.prepare(queryStr);

    if (!level.isEmpty()) {
        query.addBindValue(level);
    }
    if (!category.isEmpty()) {
        query.addBindValue(category);
    }

    query.addBindValue(limit);
    query.addBindValue(offset);

    if (!query.exec()){
        emit errorOccured("Failed to get logs: " + query.lastError().text());
        qDebug() << "Failed to get logs: " << query.lastError().text();
        return logs;
    }

    while (query.next()){
        QVariantMap log;
        log["logId"] = query.value("log_id");
        log["logLevel"] = query.value("log_level");
        log["logCategory"] = query.value("log_category");
        log["logMessage"] = query.value("log_message");
        log["details"] = query.value("details");
        log["userId"] = query.value("user_id");
        log["userName"] = query.value("first_name").toString() + " " + query.value("second_name").toString();
        log["timestamp"] = query.value("timestamp");

        logs.append(log);
    }


    return logs;
}

int ActivityLogs::getTotalLogsCount(const QString &level, const QString &category)
{
    if (!db.open()){
        emit errorOccured("Failed to open the database to get the total number of logs: " + db.lastError().text());
        qDebug() << "Failed to open the database to get the total number of logs: " << db.lastError().text();
        return 0;
    }


    QString queryStr = "SELECT COUNT(*) FROM system_logs WHERE 1=1";

    QSqlQuery query(db);

    if (!level.isEmpty()) {
        queryStr += " AND log_level = ?";
    }
    if (!category.isEmpty()) {
        queryStr += " AND log_category = ?";
    }

    query.prepare(queryStr);

    if (!level.isEmpty()) {
        query.addBindValue(level);
    }
    if (!category.isEmpty()) {
        query.addBindValue(category);
    }

    if (!query.exec()) {
        qDebug() << "Failed to get logs count:" << query.lastError().text();
        return -1;
    }

    if (query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

bool ActivityLogs::deleteLogs(int daysToKeep)
{
    QMutexLocker locker(&logsMutex);

    if(!db.open()){
        emit errorOccured("Failed to open the database for deleting old logs: " + db.lastError().text());
        qDebug() << "Failed to open the database for deleting old logs: " << db.lastError().text();
        return false;
    }

    QSqlQuery query(db);
    query.prepare("DELETE FROM system_logs WHERE timestamp < datetime('now', '-' || ? || ' days')");
    query.addBindValue(daysToKeep);

    if(!query.exec()){
        emit errorOccured("Failed to delete old logs: " + query.lastError().text());
        qDebug() << "Failed to delete old logs: " << query.lastError().text();
        return false;
    }

    logActivity("INFO", "SYSTEM", QString("Cleared logs older than %1 days old").arg(daysToKeep));

    return true;
}

bool ActivityLogs::executeSystemLogsInsert()
{
    if(!db.open()){
        emit errorOccured("Failed to open the database for inserting the test logs: " + db.lastError().text());
        qDebug() << "Failed to open the database for inserting the test logs.";
        return false;
    }

    db.transaction();

    QSqlQuery query(db);

    // Your INSERT statement
    QString insertStatement = R"(
        INSERT INTO system_logs (log_level, log_category, log_message, details, user_id)
        VALUES
        ('INFO', 'USER_MANAGEMENT', 'New student registered successfully', '{"adm_no": "STU001", "branch": "Computer Science", "level": "Undergraduate"}', 1),
        ('INFO', 'BOOK_OPERATIONS', 'Book issued to student', '{"book_title": "Database Systems", "call_number": "CS001", "due_date": "2024-11-15"}', 2),
        ('WARNING', 'BOOK_OPERATIONS', 'Book return overdue', '{"days_overdue": 5, "fine_amount": 50.00, "book_title": "Programming in C++"}', 3),
        ('ERROR', 'AUTHENTICATION', 'Failed login attempt', '{"email": "invalid@example.com", "attempts": 3}', NULL),
        ('INFO', 'BOOK_OPERATIONS', 'Book returned successfully', '{"condition": "Good", "fine_paid": 25.00}', 2),
        ('CRITICAL', 'SYSTEM', 'Database connection failed', '{"error": "Connection timeout after 30 seconds"}', NULL),
        ('INFO', 'USER_MANAGEMENT', 'Staff member added', '{"staff_no": "STF001", "department": "Library Services"}', 1),
        ('WARNING', 'BOOK_OPERATIONS', 'Book reported as lost', '{"replacement_cost": 150.00, "book_isbn": "978-0123456789"}', 4),
        ('ERROR', 'SYSTEM', 'Failed to create backup', '{"backup_path": "/backups/library_20241017.db", "error": "Insufficient disk space"}', NULL),
        ('INFO', 'AUTHENTICATION', 'User logged out', '{"session_duration": "2 hours 15 minutes"}', 2)
    )";

    // Execute the INSERT statement
    if (!query.exec(insertStatement)) {
        qDebug() << "Insert failed:" << query.lastError().text();
        return false;
    }

    db.commit();

    qDebug() << "Insert successful! Rows affected:" << query.numRowsAffected();
    return true;
}





