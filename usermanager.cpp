#include "usermanager.h"

UserManager::UserManager(QObject *parent)
    : QObject{parent}
{
    if (!QSqlDatabase::contains("user_db")) {
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", "user_db");
        db.setDatabaseName("library.db");

        if (!db.open()) {
            qDebug() <<"Failed to open database: " + db.lastError().text();
        } else {
            qDebug() << "Database successfully opened.";
        }
    }
}

UserManager::~UserManager(){
    if (QSqlDatabase::database("user_db").isOpen()){
        QSqlDatabase::database("user_db").close();
    }
}

bool UserManager::addUser(const QString &firstName, const QString &lastName, const QString &email, const QString &phone, const QString &userRole, const QVariantMap &additionalInfo){
    QSqlDatabase db = QSqlDatabase::database("user_db");  //Get the current database connection

    //check if the database is open
    if (!db.isOpen()) {
        emit errorOccured("Database is not open.");
        return false;
    }

    QSqlQuery query(db);  //pass the database connection to the query

    if (!query.exec("BEGIN TRANSACTION")){
        emit errorOccured("Failed to begin transaction: " + query.lastError().text());
        return false;
    }

    qDebug() << "Inserting parameters: " <<firstName <<lastName <<email <<userRole <<phone;
    qDebug() << "Inserting Students:" << additionalInfo["adm_no"].toString()
             << additionalInfo["branch"].toString()
             << additionalInfo["enrollment_year"].toInt()
             << additionalInfo["level"].toString();


    query.prepare("INSERT INTO users (first_name, second_name, email, phone, user_role) VALUES (?,?,?,?,?)");
    query.addBindValue(firstName);
    query.addBindValue(lastName);
    query.addBindValue(email);
    query.addBindValue(phone);
    query.addBindValue(userRole);

    if (!query.exec()){
        emit errorOccured("Error inserting into users Table: "+ query.lastError().text());
        query.exec("ROLLBACK"); // if insertion fails
        return false;
    }

    qDebug() << "Inserted into the users table succesfully";

    int userId = query.lastInsertId().toInt();

    if (userRole == "Student"){
        query.clear(); //get rid of any other prepared queries

        query.prepare("INSERT INTO students (student_id, adm_no, branch, enrollment_year, level) VALUES(?,?,?,?,?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["adm_no"].toString());
        query.addBindValue(additionalInfo["branch"].toString());
        query.addBindValue(additionalInfo["enrollment_year"].toInt());
        query.addBindValue(additionalInfo["level"].toString());

    }else if (userRole == "Staff"){
        query.prepare("INSERT INTO staff (staff_id, staff_no,  department, start_year, category) VALUES (?,?,?,?,?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["staff_no"].toString());
        query.addBindValue(additionalInfo["department"].toString());
        query.addBindValue(additionalInfo["start_year"].toInt());
        query.addBindValue(additionalInfo["category"].toString());

    }else if (userRole == "Other user"){
        query.prepare("INSERT INTO other_users (other_user_id, user_no, residence, age, gender, phone) VALUES (?,?,?,?,?,?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["user_no"].toString());
        query.addBindValue(additionalInfo["residence"].toString());
        query.addBindValue(additionalInfo["age"].toInt());
        query.addBindValue(additionalInfo["gender"].toString());
        query.addBindValue(additionalInfo["phone"].toString());
    }

    if (!query.exec()){
        emit errorOccured("Error inserting into specific role table: " +query.lastError().text());
        query.exec("ROLLBACK");
        return false;
    }

    emit errorOccured("Successfully added user");

    if (!query.exec("COMMIT")){
        emit errorOccured("Failed to commit transaction: " + query.lastError().text());
    }

    return true;
}

