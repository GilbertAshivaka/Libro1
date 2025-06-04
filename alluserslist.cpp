#include "alluserslist.h"
#include <QFuture>

AllUsersList::AllUsersList(QObject *parent)
    : QObject{parent}
{
    db = DatabaseManager::getConnection();

    if(!db.isOpen()){
        qWarning() <<  "Failed to open database: " + db.lastError().text();
    }
}

AllUsersList::~AllUsersList()
{
    if (db.isOpen())
        db.close();
}

QVector<User> AllUsersList::getUsers() const
{
    return users;
}

int AllUsersList::getTotalUsersCount(const QString &userType)
{
    QSqlQuery query(db);
    QString queryString;

    if (userType == "student") {
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

void AllUsersList::removeUser(QString UserID)
{
    QSqlQuery query(db);
    query.prepare("DELETE FROM users WHERE userID = ?");
    query.addBindValue(UserID);

    if (query.exec()){
        for(int i = 0; i < users.size(); ++i){
            if(users[i].email == UserID){
                emit preUserRemoved(i);
                users.removeAt(i);
                emit postUserRemoved();
                emit usersUpdated();

                break;
            }
        }
    }else {
        emit errorOccured("Error removing user: " + db.lastError().text());
    }
}

bool AllUsersList::validateUsers(QString name, QString userID)
{
    if (name.isEmpty() || userID.isEmpty()){
        emit errorOccured("Name and userID are required fields.");
        return false;
    }

    return true;
}


// Implementation of fromQuery
User User::fromQuery(const QSqlQuery &query, const QString &userRole) {
    User user;

    // Get base user properties
    int fieldOffset = 0;
    user.userId = query.value(fieldOffset++).toInt();
    user.firstName = query.value(fieldOffset++).toString();
    user.lastName = query.value(fieldOffset++).toString();
    user.email = query.value(fieldOffset++).toString();
    user.phone = query.value(fieldOffset++).toString();
    user.userRole = query.value(fieldOffset++).toString();
    user.status = query.value(fieldOffset++).toString();
    user.createdAt = query.value(fieldOffset++).toDateTime();
    user.updatedAt = query.value(fieldOffset++).toDateTime();

    // Get role-specific properties
    if (userRole == "student") {
        user.admNo = query.value(fieldOffset++).toString();
        user.branch = query.value(fieldOffset++).toString();
        user.enrollmentYear = query.value(fieldOffset++).toInt();
        user.level = query.value(fieldOffset++).toString();
    }
    else if (userRole == "staff") {
        user.staffNo = query.value(fieldOffset++).toString();
        user.department = query.value(fieldOffset++).toString();
        user.startYear = query.value(fieldOffset++).toInt();
        user.category = query.value(fieldOffset++).toString();
    }
    else if (userRole == "other_user") {
        user.userNo = query.value(fieldOffset++).toString();
        user.residence = query.value(fieldOffset++).toString();
        user.age = query.value(fieldOffset++).toInt();
        user.gender = query.value(fieldOffset++).toString();
        user.phone2 = query.value(fieldOffset++).toString();
    }

    return user;
}

//method for fetching all users and specific user type
bool AllUsersList::fetchUsers(QString userRole, int page, int pageSize) {
    QFuture<bool> future = QtConcurrent::run([=]() {
        int offset = (page - 1) * pageSize;
        const QString connectionName = "fetchUsersConnection";
        QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
        db.setDatabaseName("library.db");

        if (!db.open()) {
            emit errorOccured("Database connection failed: " + db.lastError().text());
            return false;
        }

        QSqlQuery query(db);
        QString queryStr;

        if (userRole == "all") {
            // Query for all users with UNION
            queryStr =
                //first select all columns from users table
                "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, u.user_role, u.status, u.created_at, u.updated_at, "
                //then student-specific columns
                "s.adm_no, s.branch, s.enrollment_year, s.level, "
                //staff columns (NULL)
                "NULL as staff_no, NULL as department, NULL as start_year, NULL as category, "
                //other user columns (NULL)
                "NULL as user_no, NULL as residence, NULL as age, NULL as gender, NULL as phone "
                "FROM users u "
                "LEFT JOIN students s ON u.user_id = s.student_id "
                "WHERE u.user_role = 'Student' "

                "UNION ALL "

                //staff records
                "SELECT u.user_id, u.first_name, u.second_name, u.email,u.phone, u.user_role, u.status, u.created_at, u.updated_at, "
                //student columns (NULL)
                "NULL, NULL, NULL, NULL, "
                //staff columns
                "s.staff_no, s.department, s.start_year, s.category, "
                //other user columns (NULL)
                "NULL, NULL, NULL, NULL, NULL "
                "FROM users u "
                "LEFT JOIN staff s ON u.user_id = s.staff_id "
                "WHERE u.user_role = 'Staff' "

                "UNION ALL "

                //other users records
                "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, u.user_role, u.status, u.created_at, u.updated_at, "
                //student columns (NULL)
                "NULL, NULL, NULL, NULL, "
                //staff columns (NULL)
                "NULL, NULL, NULL, NULL, "
                //other user columns
                "o.user_no, o.residence, o.age, o.gender, o.phone "
                "FROM users u "
                "LEFT JOIN other_users o ON u.user_id = o.other_users_id "
                "WHERE u.user_role = 'Other user' "

                "ORDER BY first_name ASC "
                "LIMIT :pageSize OFFSET :offset";

            query.prepare(queryStr);
            query.bindValue(":pageSize", pageSize);
            query.bindValue(":offset", offset);
        } else {
            // Query for specific user type
            QString joinTable, additionalFields;
            if (userRole == "student") {
                joinTable = "students";
                additionalFields = "s.adm_no, s.branch, s.enrollment_year, s.level";
            } else if (userRole == "staff") {
                joinTable = "staff";
                additionalFields = "s.staff_no, s.department, s.start_year, s.category";
            } else if (userRole == "other_users") {
                joinTable = "other_users";
                additionalFields = "o.user_no, o.residence, o.age, o.gender, o.phone";
            }

            qDebug() << "Reaches this: ";

            if (userRole == "student" || userRole == "staff"){
                queryStr = QString(
                               "SELECT u.*, %1 "
                               "FROM users u "
                               "LEFT JOIN %2 s ON u.user_id = s.%3_id "
                               "WHERE u.user_role = :userRole "
                               "ORDER BY u.created_at ASC "
                               "LIMIT :pageSize OFFSET :offset"
                               ).arg(additionalFields, joinTable, userRole);
            }else{
                queryStr = QString(
                               "SELECT u.*, %1 "
                               "FROM users u "
                               "LEFT JOIN %2 o ON u.user_id = o.%3_id "
                               "WHERE u.user_role = :userRole "
                               "ORDER BY u.created_at ASC "
                               "LIMIT :pageSize OFFSET :offset"
                               ).arg(additionalFields, joinTable, userRole);
            }

            qDebug() << "Query string assigned: ";

            QString queryUserRole;

            if(userRole == "student"){
                queryUserRole = "Student";

            }else if(userRole == "staff"){
                queryUserRole = "Staff";

            }else if(userRole == "other_users"){
                queryUserRole = "Other user";
            }

            qDebug() << "Everything is still fine: ";

            query.prepare(queryStr);
            query.bindValue(":userRole", queryUserRole);
            query.bindValue(":pageSize", pageSize);
            query.bindValue(":offset", offset);
        }

        qDebug() << "Let's see if that works: ";

        if (!query.exec()) {
            emit errorOccured("Failed to fetch users: " + query.lastError().text());
            qDebug() << "Did not go to plan: " + query.lastError().text();
            return false;
        }

        qDebug() << "Perfect!!!";

        QVector<User> tempUsers;
        while (query.next()) {
            emit preUserAppended();
            tempUsers.append(User::fromQuery(query, userRole));
            emit postUserAppended();
        }

        QMetaObject::invokeMethod(this, [=]() {
                emit preModelReset();
                users = tempUsers;
                emit postModelReset();
                emit usersUpdated();
            }, Qt::QueuedConnection);

        //get the total number of users every time this function is called to update the UI navigation button
        getTotalUsersCount(userRole);

        db.close(); //close the database connection first before removing
        return true;
    });

    //remove the database connection
    QSqlDatabase::removeDatabase("fetchUsersConnection");
    return true;
}

