#include "databasemanager.h"
#include <QDebug>
#include <QMutexLocker>

QMutex DatabaseManager::dbMutex;  // initialize the static mutex

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
    // ensure that the database connection is only created once and set it to dbInitialised variable so that the isdbInitialised fucntion can be called from different parts of the application
    dbInitalized = createDatabase();
}

DatabaseManager::~DatabaseManager()
{
    // Close the database connection when the object is destroyed
    if (db.isOpen()) {
        db.close();
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
        db.setDatabaseName("library.db");
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

    // // Drop and recreate issued_books with correct foreign key
    // if (!query.exec("DROP TABLE IF EXISTS issued_books")) {
    //     emit errorOccured("Error dropping issued_books table: " + query.lastError().text());
    //     return false;
    // }

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

    qDebug() << "Tables created successfully";
    return true;
}



// Static method to return a database connection (optionally for multiple classes)
QSqlDatabase DatabaseManager::getConnection()
{
    QMutexLocker locker(&dbMutex);  // lock to ensure thread safety
    if (!QSqlDatabase::contains("libraryConnection")) {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "libraryConnection");
        db.setDatabaseName("library.db");
        if (!db.open()) {
            qWarning() << "Failed to open database: " + db.lastError().text();
        }
    }
    return QSqlDatabase::database("libraryConnection");
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
        db.setDatabaseName("library.db");
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

