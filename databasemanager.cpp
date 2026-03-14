#include "databasemanager.h"
#include <QDebug>
#include <QMutexLocker>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QCoreApplication>

QMutex DatabaseManager::dbMutex;  // initialize the static mutex

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
    // Resolve the ApplicationData path once at construction
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath); // ensure the directory exists
    dbPath = appDataPath + "/library.db";

    // One-time migration from old location (next to .exe) to AppData
    migrateExistingDatabase(appDataPath);

    // ensure that the database connection is only created once and set it to dbInitialised variable
    // so that the isdbInitialised function can be called from different parts of the application
    dbInitalized = createDatabase();
}

DatabaseManager::~DatabaseManager()
{
    // Close the database connection when the object is destroyed
    if (db.isOpen()) {
        db.close();
    }
}

void DatabaseManager::migrateExistingDatabase(const QString &appDataPath)
{
    QString newPath = appDataPath + "/library.db";
    QString oldPath = QCoreApplication::applicationDirPath() + "/library.db";

    // Only migrate if new location doesn't exist yet but old one does
    if (!QFile::exists(newPath) && QFile::exists(oldPath)) {
        if (QFile::copy(oldPath, newPath)) {
            qDebug() << "Database migrated from" << oldPath << "to" << newPath;
            // Rename old file as a backup rather than deleting it
            QFile::rename(oldPath, oldPath + ".bak");
        } else {
            qWarning() << "Failed to migrate database from" << oldPath << "to" << newPath;
            emit errorOccured("Failed to migrate database to new location.");
        }
    }
}

bool DatabaseManager::isdbInitialized() const
{
    return dbInitalized;
}

bool DatabaseManager::createDatabase()
{
    // use a mutex lock to ensure thread safety
    QMutexLocker locker(&dbMutex);

    // Check if the connection already exists before creating
    if (QSqlDatabase::contains("libraryConnection")) {
        db = QSqlDatabase::database("libraryConnection");
    } else {
        db = QSqlDatabase::addDatabase("QSQLITE", "libraryConnection");
        db.setDatabaseName(dbPath); // use resolved AppData path
    }

    if (!db.open()) {
        qWarning() << "Failed to open database: " + db.lastError().text();
        emit errorOccured("Failed to open database: " + db.lastError().text());
        return false;
    }

    QSqlQuery(db).exec("PRAGMA foreign_keys = ON;"); //ensure that the foreign keys are enforced

    QSqlQuery query(db);


    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS users ("
            "user_id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "first_name TEXT NOT NULL,"
            "second_name TEXT NOT NULL, "
            "email TEXT UNIQUE,"
            "phone TEXT UNIQUE,"
            "user_role TEXT NOT NULL,"
            "status TEXT DEFAULT 'Active',"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)")) {
        emit errorOccured("Error creating users table: " + query.lastError().text());
        return false;
    }

    if (!query.exec("CREATE TABLE IF NOT EXISTS students ("
                    "student_id INTEGER PRIMARY KEY,"
                    "adm_no TEXT NOT NULL,"
                    "branch TEXT,"
                    "enrollment_year INTEGER,"
                    "level TEXT,"
                    "FOREIGN KEY (student_id) REFERENCES users(user_id) ON DELETE CASCADE)")) {
        emit errorOccured("Error creating students table: " + query.lastError().text());
        return false;
    }

    if (!query.exec("CREATE TABLE IF NOT EXISTS staff ("
                    "staff_id INTEGER PRIMARY KEY,"
                    "staff_no TEXT NOT NULL,"
                    "department TEXT NOT NULL,"
                    "start_year INT,"
                    "category TEXT,"
                    "FOREIGN KEY (staff_id) REFERENCES users(user_id) ON DELETE CASCADE)")) {
        emit errorOccured("Error creating staff table: " + query.lastError().text());
        return false;
    }

    if (!query.exec("CREATE TABLE IF NOT EXISTS other_users ("
                    "other_users_id INTEGER PRIMARY KEY,"
                    "user_no VARCHAR NOT NULL,"
                    "residence TEXT,"
                    "age int,"
                    "gender TEXT,"
                    "phone VARCHAR,"
                    "FOREIGN KEY (other_users_id) REFERENCES users(user_id) ON DELETE CASCADE)")) {
        emit errorOccured("Error creating other_users table: " + query.lastError().text());
        return false;
    }

    if (!query.exec("CREATE TABLE IF NOT EXISTS books("
                    "bookID INTEGER PRIMARY KEY AUTOINCREMENT, "
                    "title TEXT NOT NULL, "
                    "author TEXT NOT NULL, "
                    "callNumber TEXT UNIQUE, "
                    "publisher TEXT, "
                    "isbn TEXT, "
                    "barcode TEXT, "
                    "year_published TEXT, "
                    "shelfNumber TEXT, "
                    "description TEXT, "
                    "language TEXT, "
                    "subject TEXT, "
                    "genre TEXT, "
                    "value INTEGER, "
                    "method TEXT,"
                    "dateAdded DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "availability TEXT DEFAULT 'Available',"
                    "timesBorrowed INT DEFAULT 0,"
                    "condition TEXT DEFAULT 'Good')")) {
        emit errorOccured("Error creating the books table: " + query.lastError().text());
        return false;
    }

    //Creating the issued_books table
    if(!query.exec("CREATE TABLE IF NOT EXISTS issued_books ("
                    "issue_id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "book_id INTEGER NOT NULL,"
                    "user_id INTEGER NOT NULL,"
                    "issue_date DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "due_date DATETIME NOT NULL,"
                    "return_date DATETIME,"
                    "fine_amount DECIMAL(10,2) DEFAULT 0.00,"
                    "fine_paid DECIMAL(10,2) DEFAULT 0.00,"
                    "fine_paid_date DATETIME,"
                    "renewal_count INTEGER DEFAULT 0,"
                    "last_renewal_date DATETIME,"
                    "status TEXT DEFAULT 'Borrowed',"
                    "condition_before TEXT,"
                    "condition_after TEXT,"
                    "notes TEXT,"
                    "issued_by INTEGER,"
                    "received_by INTEGER,"
                    "reservation_id INTEGER,"
                    "FOREIGN KEY (book_id) REFERENCES books(bookID) ON DELETE CASCADE,"
                    "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,"
                    "FOREIGN KEY (issued_by) REFERENCES users(user_id),"
                    "FOREIGN KEY (received_by) REFERENCES users(user_id)"
                    // Add FOREIGN KEY for reservation_id later
                    ")")){
        emit errorOccured("Error creating issued_books table: " + query.lastError().text());
        qDebug() << "Error creating issued_books table: " + query.lastError().text();
        return false;
    }

    if (!query.exec("CREATE TABLE IF NOT EXISTS lost_books ("
                    "lost_id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "original_issue_id INTEGER,"
                    "book_id INTEGER NOT NULL,"
                    "user_id INTEGER NOT NULL,"
                    "book_title TEXT NOT NULL,"
                    "book_call_number TEXT NOT NULL,"
                    "book_author TEXT,"
                    "book_isbn TEXT,"
                    "book_value DECIMAL(10,2) DEFAULT 0.00,"
                    "user_name TEXT NOT NULL,"
                    "user_email TEXT,"
                    "user_phone TEXT,"
                    "user_role TEXT,"
                    "student_adm_no TEXT,"
                    "staff_no TEXT,"
                    "issue_date DATETIME NOT NULL,"
                    "due_date DATETIME NOT NULL,"
                    "reported_lost_date DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "days_overdue INTEGER,"
                    "fine_amount DECIMAL(10,2) DEFAULT 0.00,"
                    "replacement_cost DECIMAL(10,2),"
                    "total_amount_due DECIMAL(10,2),"
                    "amount_paid DECIMAL(10,2) DEFAULT 0.00,"
                    "payment_date DATETIME,"
                    "status TEXT DEFAULT 'Lost',"
                    "condition_when_issued TEXT,"
                    "notes TEXT,"
                    "reported_by INTEGER,"
                    "resolved_by INTEGER,"
                    "resolution_date DATETIME,"
                    "resolution_type TEXT,"
                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "FOREIGN KEY (book_id) REFERENCES books(bookID) ON DELETE CASCADE,"
                    "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,"
                    "FOREIGN KEY (reported_by) REFERENCES users(user_id),"
                    "FOREIGN KEY (resolved_by) REFERENCES users(user_id)"
                    ")")){
        emit errorOccured("Error creating lost_books table: " + query.lastError().text());
        qDebug() << "Error creating lost_books table: " + query.lastError().text();
        return false;
    }

    if (!query.exec("CREATE TABLE IF NOT EXISTS book_return_log ("
                    "log_id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "original_issue_id INTEGER,"
                    "book_id INTEGER,"
                    "user_id INTEGER,"
                    "book_title TEXT,"
                    "book_call_number TEXT,"
                    "user_name TEXT,"
                    "issue_date DATETIME,"
                    "due_date DATETIME,"
                    "return_date DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "fine_amount DECIMAL(10,2) DEFAULT 0.00,"
                    "days_overdue INTEGER,"
                    "status_at_return TEXT,"
                    "returned_by INTEGER,"
                    "notes TEXT,"
                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                    ")")){
        emit errorOccured("Error creating book_return_log table: " + query.lastError().text());
        qDebug() << "Error creating book_return_log table: " + query.lastError().text();
        return false;
    }

    //Create the logs table
    if (!query.exec("CREATE TABLE IF NOT EXISTS system_logs ("
                    "log_id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "log_level TEXT NOT NULL CHECK (log_level IN ('INFO', 'WARNING', 'ERROR', 'DEBUG', 'CRITICAL')),"
                    "log_category TEXT NOT NULL,"
                    "log_message TEXT NOT NULL,"
                    "details TEXT,"
                    "user_id INTEGER,"
                    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "FOREIGN KEY (user_id) REFERENCES users(user_id)"
                    ")")){
        emit errorOccured("Failed to create the logs table: " + query.lastError().text());
        qDebug() << "Failed to create the logs table: " << query.lastError().text();
        return false;
    }

    //create index on the logs table for better performance
    query.exec("CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON system_logs(timestamp)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_logs_level ON system_logs(log_level)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_logs_category ON system_logs(log_category)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_logs_user_id ON system_logs(user_id)");

    // Create the bookshops table
    if (!query.exec("CREATE TABLE IF NOT EXISTS bookshops ("
                    "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "name TEXT NOT NULL,"
                    "url TEXT NOT NULL,"
                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"
                    ")")){
        emit errorOccured("Error creating bookshops table: " + query.lastError().text());
        qDebug() << "Error creating bookshops table: " + query.lastError().text();
        return false;
    }

    // Create digital_materials table
    if (!query.exec("CREATE TABLE IF NOT EXISTS digital_materials ("
                    "ItemID INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "ItemName TEXT NOT NULL,"
                    "ItemType TEXT NOT NULL,"
                    "quantity INTEGER NOT NULL DEFAULT 0,"
                    "quantityBorrowed INTEGER NOT NULL DEFAULT 0,"
                    "holder TEXT,"
                    "dateAdded DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "dateBorrowed DATETIME,"
                    "location TEXT,"
                    "condition TEXT,"
                    "value REAL DEFAULT 0.0,"
                    "status TEXT DEFAULT 'Available',"
                    "details TEXT"
                    ")")) {
        emit errorOccured("Error creating digital_materials table: " + query.lastError().text());
        qDebug() << "Error creating digital_materials table: " + query.lastError().text();
        return false;
    }

    // Create digital_materials_loans table for history
    if (!query.exec("CREATE TABLE IF NOT EXISTS digital_materials_loans ("
                    "loan_id INTEGER PRIMARY KEY AUTOINCREMENT,"
                    "item_id INTEGER NOT NULL,"
                    "item_name TEXT NOT NULL,"
                    "user_id INTEGER,"
                    "user_number TEXT NOT NULL,"
                    "quantity_borrowed INTEGER NOT NULL,"
                    "issue_date DATETIME DEFAULT CURRENT_TIMESTAMP,"
                    "return_date DATETIME,"
                    "status TEXT DEFAULT 'Borrowed',"
                    "FOREIGN KEY (item_id) REFERENCES digital_materials(ItemID) ON DELETE CASCADE"
                    ")")) {
        emit errorOccured("Error creating digital_materials_loans table: " + query.lastError().text());
        qDebug() << "Error creating digital_materials_loans table: " + query.lastError().text();
        return false;
    }

    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS reserved_books ("
            "reservation_id INTEGER PRIMARY KEY,"
            "book_id INTEGER NOT NULL,"
            "user_id INTEGER NOT NULL,"
            "user_email TEXT NOT NULL,"
            "user_name TEXT NOT NULL,"
            "reservation_date DATETIME NOT NULL,"
            "notification_sent_date DATETIME,"
            "pickup_deadline DATETIME,"
            "status TEXT DEFAULT 'pending',"
            "expiry_date DATETIME NOT NULL,"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "source TEXT DEFAULT 'online',"
            "notes TEXT,"
            "FOREIGN KEY (book_id) REFERENCES books(bookID) ON DELETE CASCADE,"
            "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE)")) {
        qWarning() << "Error creating reserved_books table:" << query.lastError().text();
        emit errorOccured("Failed to create reserved_books table: " + query.lastError().text());
        return false;
    }

    // Create indexes for reserved_books
    query.exec("CREATE INDEX IF NOT EXISTS idx_reserved_status ON reserved_books(status)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_reserved_book_id ON reserved_books(book_id)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_reserved_user_id ON reserved_books(user_id)");

    // Create opac_sync_log table
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS opac_sync_log ("
            "sync_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "sync_type TEXT NOT NULL,"
            "sync_direction TEXT NOT NULL,"
            "records_affected INTEGER DEFAULT 0,"
            "status TEXT NOT NULL,"
            "error_message TEXT,"
            "started_at DATETIME NOT NULL,"
            "completed_at DATETIME,"
            "last_sync_timestamp DATETIME,"
            "triggered_by TEXT NOT NULL)")) {
        qWarning() << "Error creating opac_sync_log table:" << query.lastError().text();
        emit errorOccured("Failed to create opac_sync_log table: " + query.lastError().text());
        return false;
    }

    // Create indexes for opac_sync_log
    query.exec("CREATE INDEX IF NOT EXISTS idx_sync_type ON opac_sync_log(sync_type)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_sync_started ON opac_sync_log(started_at)");

    // Create opac_configuration table
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS opac_configuration ("
            "config_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "opac_url TEXT NOT NULL,"
            "api_key TEXT NOT NULL,"
            "sync_interval_minutes INTEGER DEFAULT 60,"
            "last_books_sync DATETIME,"
            "last_users_sync DATETIME,"
            "last_reservations_sync DATETIME,"
            "auto_sync_enabled INTEGER DEFAULT 0,"
            "notification_pickup_days INTEGER DEFAULT 3,"
            "reservation_expiry_days INTEGER DEFAULT 7,"
            "is_active INTEGER DEFAULT 1,"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)")) {
        qWarning() << "Error creating opac_configuration table:" << query.lastError().text();
        emit errorOccured("Failed to create opac_configuration table: " + query.lastError().text());
        return false;
    }

    // Create app_settings table
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS app_settings ("
            "setting_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "category TEXT NOT NULL,"
            "setting_key TEXT NOT NULL UNIQUE,"
            "setting_value TEXT,"
            "setting_type TEXT DEFAULT 'string',"
            "description TEXT,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)")) {
        qWarning() << "Error creating app_settings table:" << query.lastError().text();
        emit errorOccured("Failed to create app_settings table: " + query.lastError().text());
        return false;
    }

    // Create indexes for app_settings
    query.exec("CREATE INDEX IF NOT EXISTS idx_settings_key ON app_settings(setting_key)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_settings_category ON app_settings(category)");

    // Create suggestions_feedback table
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS suggestions_feedback ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "user_id INTEGER,"
            "user_name TEXT,"
            "user_number TEXT,"
            "user_role TEXT,"
            "content TEXT NOT NULL,"
            "type TEXT NOT NULL CHECK (type IN ('suggestion', 'feedback')),"
            "is_anonymous INTEGER DEFAULT 0,"
            "status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'addressed')),"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL)")) {
        qWarning() << "Error creating suggestions_feedback table:" << query.lastError().text();
        emit errorOccured("Failed to create suggestions_feedback table: " + query.lastError().text());
        return false;
    }

    // Create indexes for suggestions_feedback
    query.exec("CREATE INDEX IF NOT EXISTS idx_suggestions_type ON suggestions_feedback(type)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_suggestions_status ON suggestions_feedback(status)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_suggestions_created ON suggestions_feedback(created_at)");

    // Create admins table for system administrators
    // First admin is set up during initial app configuration
    // Subsequent admins must be staff members first, then promoted by existing admin
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS admins ("
            "admin_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "user_id INTEGER,"
            "staff_id INTEGER,"
            "username TEXT NOT NULL UNIQUE,"
            "password TEXT NOT NULL,"
            "admin_name TEXT NOT NULL,"
            "email TEXT,"
            "phone TEXT,"
            "is_super_admin INTEGER DEFAULT 0,"
            "is_active INTEGER DEFAULT 1,"
            "last_login DATETIME,"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "created_by INTEGER,"
            "FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,"
            "FOREIGN KEY (created_by) REFERENCES admins(admin_id)"
            ")")) {
        qWarning() << "Error creating admins table:" << query.lastError().text();
        emit errorOccured("Failed to create admins table: " + query.lastError().text());
        return false;
    }

    // Create indexes for admins table
    query.exec("CREATE INDEX IF NOT EXISTS idx_admins_username ON admins(username)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_admins_staff_id ON admins(staff_id)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_admins_active ON admins(is_active)");

    qDebug() << "Tables created successfully";
    return true;
}


// Static method to return a database connection (optionally for multiple classes)
QSqlDatabase DatabaseManager::getConnection()
{
    QMutexLocker locker(&dbMutex);  // lock to ensure thread safety
    if (!QSqlDatabase::contains("libraryConnection")) {
        QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir().mkpath(appDataPath);

        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "libraryConnection");
        db.setDatabaseName(appDataPath + "/library.db"); // use resolved AppData path
        if (!db.open()) {
            qWarning() << "Failed to open database: " + db.lastError().text();
        }
    }
    return QSqlDatabase::database("libraryConnection");
}

QString DatabaseManager::getDatabasePath()
{
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath);
    return appDataPath + "/library.db";
}


int DatabaseManager::getTotalUsersCount(const QString &userType)
{
    //get connection to the database via the function
    db = getConnection();
    QSqlQuery query(db);
    QString queryString;

    if (userType == "students") {
        queryString = "SELECT COUNT(*) FROM students;";
    } else if (userType == "staff") {
        queryString = "SELECT COUNT(*) FROM staff;";
    } else if (userType == "other_users") {
        queryString = "SELECT COUNT(*) FROM other_users;";
    } else {
        queryString = "SELECT COUNT(*) FROM users;";
    }

    if (!query.exec(queryString)) {
        qWarning() << "Failed to get total users count:" << query.lastError().text();
        return -1;
    }

    if (query.next()) {
        return query.value(0).toInt(); // Extract the count from the result
    }

    return 0;
}


//this was a temporary function to delete a corrupted database
void DatabaseManager::deleteTables()
{
    // Check if the connection already exists before creating
    if (QSqlDatabase::contains("libraryConnection")) {
        db = QSqlDatabase::database("libraryConnection");
    } else {
        db = QSqlDatabase::addDatabase("QSQLITE", "libraryConnection");
        db.setDatabaseName(dbPath); // use resolved AppData path
    }

    if (!db.open()) {
        qWarning() << "Failed to open database: " + db.lastError().text();
        emit errorOccured("Failed to open database: " + db.lastError().text());
        return;
    }
    QSqlQuery query(db);
    // Drop each table if it exists
    query.exec("DROP TABLE IF EXISTS other_users");
    query.exec("DROP TABLE IF EXISTS staff");
    query.exec("DROP TABLE IF EXISTS students");
    query.exec("DROP TABLE IF EXISTS users");
    query.exec("DROP TABLE IF EXISTS books");
    qDebug() << "Tables dropped successfully.";
}
