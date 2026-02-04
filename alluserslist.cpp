#include "alluserslist.h"
#include <QFuture>

AllUsersList::AllUsersList(QObject *parent)
    : QObject{parent}
{
    db = DatabaseManager::getConnection();

    if(!db.open()){
        qWarning() <<  "Failed to open database: " + db.lastError().text();
    }
}

AllUsersList::~AllUsersList()
{
    // if (db.isOpen()) //closing the database affects other modules
    //     db.close();
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

    // For "all" query, determine actual role from the user_role field
    QString actualRole = userRole;
    if (userRole == "all") {
        if (user.userRole == "Student") {
            actualRole = "student";
        } else if (user.userRole == "Staff") {
            actualRole = "staff";
        } else if (user.userRole == "Other user") {
            actualRole = "other_users";
        }
    }

    // Get role-specific properties
    // For "all" query, columns are: student fields (4), staff fields (4), other_user fields (5)
    if (userRole == "all") {
        // Student fields at positions 9-12
        if (actualRole == "student") {
            user.admNo = query.value(9).toString();
            user.branch = query.value(10).toString();
            user.enrollmentYear = query.value(11).toInt();
            user.level = query.value(12).toString();
        }
        // Staff fields at positions 13-16
        else if (actualRole == "staff") {
            user.staffNo = query.value(13).toString();
            user.department = query.value(14).toString();
            user.startYear = query.value(15).toInt();
            user.category = query.value(16).toString();
        }
        // Other user fields at positions 17-21
        else if (actualRole == "other_users") {
            user.userNo = query.value(17).toString();
            user.residence = query.value(18).toString();
            user.age = query.value(19).toInt();
            user.gender = query.value(20).toString();
            user.phone2 = query.value(21).toString();
        }
    }
    else if (userRole == "student") {
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
    else if (userRole == "other_users") {
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

        // db.close(); //close the database connection first before removing
        return true;
    });

    //remove the database connection
    // QSqlDatabase::removeDatabase("fetchUsersConnection");
    return true;
}


// Search users across all user types
// Matches on: first_name, second_name, adm_no, staff_no, user_no
// Partial matching, case-insensitive
bool AllUsersList::searchUsers(const QString &searchTerm)
{
    // If search term is empty, this should be handled by caller to reload all users
    if (searchTerm.trimmed().isEmpty()) {
        return false;
    }

    QFuture<bool> future = QtConcurrent::run([=]() {
        const QString connectionName = "searchUsersConnection";

        // Remove existing connection if it exists
        if (QSqlDatabase::contains(connectionName)) {
            QSqlDatabase::removeDatabase(connectionName);
        }

        QSqlDatabase searchDb = QSqlDatabase::addDatabase("QSQLITE", connectionName);
        searchDb.setDatabaseName("library.db");

        if (!searchDb.open()) {
            emit errorOccured("Database connection failed: " + searchDb.lastError().text());
            return false;
        }

        QSqlQuery query(searchDb);

        // Search pattern for LIKE - partial, case-insensitive (SQLite LIKE is case-insensitive by default for ASCII)
        QString searchPattern = "%" + searchTerm.trimmed() + "%";

        // Query all user types with UNION, filtering by search term
        QString queryStr =
            // Students
            "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, u.user_role, u.status, u.created_at, u.updated_at, "
            "s.adm_no, s.branch, s.enrollment_year, s.level, "
            "NULL as staff_no, NULL as department, NULL as start_year, NULL as category, "
            "NULL as user_no, NULL as residence, NULL as age, NULL as gender, NULL as phone2 "
            "FROM users u "
            "LEFT JOIN students s ON u.user_id = s.student_id "
            "WHERE u.user_role = 'Student' AND ("
            "   u.first_name LIKE :search1 OR "
            "   u.second_name LIKE :search2 OR "
            "   (u.first_name || ' ' || u.second_name) LIKE :search3 OR "
            "   s.adm_no LIKE :search4"
            ") "

            "UNION ALL "

            // Staff
            "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, u.user_role, u.status, u.created_at, u.updated_at, "
            "NULL, NULL, NULL, NULL, "
            "s.staff_no, s.department, s.start_year, s.category, "
            "NULL, NULL, NULL, NULL, NULL "
            "FROM users u "
            "LEFT JOIN staff s ON u.user_id = s.staff_id "
            "WHERE u.user_role = 'Staff' AND ("
            "   u.first_name LIKE :search5 OR "
            "   u.second_name LIKE :search6 OR "
            "   (u.first_name || ' ' || u.second_name) LIKE :search7 OR "
            "   s.staff_no LIKE :search8"
            ") "

            "UNION ALL "

            // Other users
            "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, u.user_role, u.status, u.created_at, u.updated_at, "
            "NULL, NULL, NULL, NULL, "
            "NULL, NULL, NULL, NULL, "
            "o.user_no, o.residence, o.age, o.gender, o.phone "
            "FROM users u "
            "LEFT JOIN other_users o ON u.user_id = o.other_users_id "
            "WHERE u.user_role = 'Other user' AND ("
            "   u.first_name LIKE :search9 OR "
            "   u.second_name LIKE :search10 OR "
            "   (u.first_name || ' ' || u.second_name) LIKE :search11 OR "
            "   o.user_no LIKE :search12"
            ") "

            "ORDER BY first_name ASC "
            "LIMIT 100";  // Limit results for performance

        query.prepare(queryStr);

        // Bind search pattern to all placeholders
        for (int i = 1; i <= 12; i++) {
            query.bindValue(QString(":search%1").arg(i), searchPattern);
        }

        if (!query.exec()) {
            emit errorOccured("Search failed: " + query.lastError().text());
            qDebug() << "Search query failed: " + query.lastError().text();
            searchDb.close();
            return false;
        }

        QVector<User> tempUsers;
        while (query.next()) {
            tempUsers.append(User::fromQuery(query, "all"));
        }

        searchDb.close();

        // Update the model on the main thread
        QMetaObject::invokeMethod(this, [=]() {
            emit preModelReset();
            users = tempUsers;
            emit postModelReset();
            emit usersUpdated();
        }, Qt::QueuedConnection);

        return true;
    });

    return true;
}
