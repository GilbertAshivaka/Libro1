#include "usermanager.h"
#include <QSqlRecord>
#include <QDateTime>

UserManager::UserManager(QObject *parent)
    : QObject(parent)
{
    db = DatabaseManager::getConnection();
    if (!db.isOpen()) {
        qWarning() << "UserManager: Database connection not available";
    }
}

UserManager::~UserManager()
{
    // Database connection is managed by DatabaseManager
}

bool UserManager::addUser(const QString &firstName, const QString &lastName, const QString &email, const QString &phone, const QString &userRole, const QVariantMap &additionalInfo)
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

    QSqlDatabase db = QSqlDatabase::database("user_db");  //Get the current database connection

    //check if the database is open
    if (!db.isOpen()) {
        emit errorOccurred("Database is not open.");
        return false;
    }

    QSqlQuery query(db);  //pass the database connection to the query

    if (!query.exec("BEGIN TRANSACTION")){
        emit errorOccurred("Failed to begin transaction: " + query.lastError().text());
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
        emit errorOccurred("Error inserting into users Table: "+ query.lastError().text());
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
        query.prepare("INSERT INTO other_users (other_users_id, user_no, residence, age, gender, phone) VALUES (?,?,?,?,?,?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["user_no"].toString());
        query.addBindValue(additionalInfo["residence"].toString());
        query.addBindValue(additionalInfo["age"].toInt());
        query.addBindValue(additionalInfo["gender"].toString());
        query.addBindValue(additionalInfo["phone"].toString());
    }

    if (!query.exec()){
        emit errorOccurred("Error inserting into specific role table: " +query.lastError().text());
        query.exec("ROLLBACK");
        return false;
    }

    emit errorOccurred("Successfully added user");

    if (!query.exec("COMMIT")){
        emit errorOccurred("Failed to commit transaction: " + query.lastError().text());
    }

    return true;
}

QVariantMap UserManager::getUserById(int userId) const
{
    QVariantMap result;

    if (userId <= 0) {
        return result;
    }

    QSqlQuery query(db);
    query.prepare(
        "SELECT user_id, first_name, second_name, email, phone, user_role, status, created_at "
        "FROM users WHERE user_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (!query.exec()) {
        qWarning() << "Error fetching user by ID:" << query.lastError().text();
        return result;
    }

    if (query.next()) {
        result["userId"] = query.value("user_id").toInt();
        result["firstName"] = query.value("first_name").toString();
        result["secondName"] = query.value("second_name").toString();
        result["fullName"] = query.value("first_name").toString() + " " + query.value("second_name").toString();
        result["email"] = query.value("email").toString();
        result["phone"] = query.value("phone").toString();
        result["userRole"] = query.value("user_role").toString();
        result["status"] = query.value("status").toString();
        result["createdAt"] = query.value("created_at").toString();

        // Get role-specific details
        QString userRole = result["userRole"].toString();
        QVariantMap roleDetails = getRoleSpecificDetails(userId, userRole);

        // Merge role-specific details
        for (auto it = roleDetails.begin(); it != roleDetails.end(); ++it) {
            result[it.key()] = it.value();
        }

        // Add statistics
        result["totalBooksIssued"] = getTotalBooksIssued(userId);
        result["currentlyBorrowed"] = getCurrentlyBorrowedCount(userId);
        result["overdueCount"] = getOverdueCount(userId);

        qDebug() << "Total books issued: " << result["totalBooksIssued"];
    }

    return result;
}

QVariantMap UserManager::getUserByNumber(const QString &userNumber, const QString &userRole) const
{
    QVariantMap result;

    if (userNumber.isEmpty()) {
        return result;
    }

    int userId = 0;
    QSqlQuery query(db);

    if (userRole == "Student") {
        query.prepare("SELECT student_id FROM students WHERE adm_no = :number");
    } else if (userRole == "Staff") {
        query.prepare("SELECT staff_id FROM staff WHERE staff_no = :number");
    } else if (userRole == "Other") {
        query.prepare("SELECT other_users_id FROM other_users WHERE user_no = :number");
    } else {
        return result;
    }

    query.bindValue(":number", userNumber);

    if (!query.exec()) {
        qWarning() << "Error finding user by number:" << query.lastError().text();
        return result;
    }

    if (query.next()) {
        userId = query.value(0).toInt();
        return getUserById(userId);
    }

    return result;
}

int UserManager::getTotalBooksIssued(int userId) const
{
    // Count from both issued_books (current) and book_return_log (returned)
    // This gives total of all books ever issued to the user
    int totalCount = 0;

    QSqlQuery query(db);

    // Count from issued_books table
    query.prepare(
        "SELECT COUNT(*) FROM issued_books WHERE user_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        totalCount += query.value(0).toInt();
    }

    // Count from book_return_log table (returned books no longer in issued_books)
    query.prepare(
        "SELECT COUNT(*) FROM book_return_log WHERE user_id = :userId "
        "AND original_issue_id NOT IN (SELECT issue_id FROM issued_books WHERE user_id = :userId2)"
        );
    query.bindValue(":userId", userId);
    query.bindValue(":userId2", userId);

    if (query.exec() && query.next()) {
        totalCount += query.value(0).toInt();
    }

    return totalCount;
}

int UserManager::getCurrentlyBorrowedCount(int userId) const
{
    QSqlQuery query(db);
    query.prepare(
        "SELECT COUNT(*) FROM issued_books "
        "WHERE user_id = :userId AND status = 'Borrowed'"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

int UserManager::getOverdueCount(int userId) const
{
    QSqlQuery query(db);
    query.prepare(
        "SELECT COUNT(*) FROM issued_books "
        "WHERE user_id = :userId AND status = 'Borrowed' "
        "AND due_date < datetime('now')"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

QVariantMap UserManager::getUserFines(int userId) const
{
    QVariantMap result;
    result["total"] = 0.0;
    result["paid"] = 0.0;
    result["unpaid"] = 0.0;

    QSqlQuery query(db);
    query.prepare(
        "SELECT COALESCE(SUM(fine_amount), 0) as total, "
        "COALESCE(SUM(fine_paid), 0) as paid "
        "FROM issued_books WHERE user_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        double total = query.value("total").toDouble();
        double paid = query.value("paid").toDouble();
        result["total"] = total;
        result["paid"] = paid;
        result["unpaid"] = total - paid;
    }

    return result;
}

QVariantList UserManager::getBorrowingHistory(int userId, int limit) const
{
    QVariantList history;

    QSqlQuery query(db);
    QString sql =
        "SELECT ib.issue_id, ib.book_id, b.title, b.author, b.callNumber, "
        "ib.issue_date, ib.due_date, ib.return_date, ib.status, "
        "ib.fine_amount, ib.fine_paid, ib.renewal_count "
        "FROM issued_books ib "
        "LEFT JOIN books b ON ib.book_id = b.bookID "
        "WHERE ib.user_id = :userId "
        "ORDER BY ib.issue_date DESC";

    if (limit > 0) {
        sql += " LIMIT :limit";
    }

    query.prepare(sql);
    query.bindValue(":userId", userId);
    if (limit > 0) {
        query.bindValue(":limit", limit);
    }

    if (!query.exec()) {
        qWarning() << "Error fetching borrowing history:" << query.lastError().text();
        return history;
    }

    while (query.next()) {
        QVariantMap record;
        record["issueId"] = query.value("issue_id").toInt();
        record["bookId"] = query.value("book_id").toInt();
        record["title"] = query.value("title").toString();
        record["author"] = query.value("author").toString();
        record["callNumber"] = query.value("callNumber").toString();
        record["issueDate"] = query.value("issue_date").toString();
        record["dueDate"] = query.value("due_date").toString();
        record["returnDate"] = query.value("return_date").toString();
        record["status"] = query.value("status").toString();
        record["fineAmount"] = query.value("fine_amount").toDouble();
        record["finePaid"] = query.value("fine_paid").toDouble();
        record["renewalCount"] = query.value("renewal_count").toInt();
        history.append(record);
    }

    return history;
}

bool UserManager::updateUserDetails(int userId, const QVariantMap &updates, const QString &adminPassword)
{
    // First verify admin password
    if (!verifyAdminPassword(adminPassword)) {
        emit updateFailed("Invalid admin password");
        return false;
    }

    if (userId <= 0 || updates.isEmpty()) {
        emit updateFailed("Invalid user ID or no updates provided");
        return false;
    }

    // Get current user role
    QSqlQuery roleQuery(db);
    roleQuery.prepare("SELECT user_role FROM users WHERE user_id = :userId");
    roleQuery.bindValue(":userId", userId);

    if (!roleQuery.exec() || !roleQuery.next()) {
        emit updateFailed("User not found");
        return false;
    }

    QString userRole = roleQuery.value("user_role").toString();

    // Build update query for users table
    QStringList setClauses;
    QStringList allowedUserFields = {"first_name", "second_name", "email", "phone"};

    for (auto it = updates.begin(); it != updates.end(); ++it) {
        if (allowedUserFields.contains(it.key())) {
            setClauses.append(it.key() + " = :" + it.key());
        }
    }

    if (!setClauses.isEmpty()) {
        setClauses.append("updated_at = datetime('now')");

        QSqlQuery updateQuery(db);
        QString sql = "UPDATE users SET " + setClauses.join(", ") + " WHERE user_id = :userId";
        updateQuery.prepare(sql);

        for (auto it = updates.begin(); it != updates.end(); ++it) {
            if (allowedUserFields.contains(it.key())) {
                updateQuery.bindValue(":" + it.key(), it.value());
            }
        }
        updateQuery.bindValue(":userId", userId);

        if (!updateQuery.exec()) {
            qWarning() << "Error updating user:" << updateQuery.lastError().text();
            emit updateFailed("Failed to update user details: " + updateQuery.lastError().text());
            return false;
        }
    }

    // Update role-specific table
    if (userRole == "Student") {
        QStringList studentFields = {"adm_no", "branch", "enrollment_year", "level"};
        QStringList studentSetClauses;

        for (auto it = updates.begin(); it != updates.end(); ++it) {
            if (studentFields.contains(it.key())) {
                studentSetClauses.append(it.key() + " = :" + it.key());
            }
        }

        if (!studentSetClauses.isEmpty()) {
            QSqlQuery studentQuery(db);
            QString sql = "UPDATE students SET " + studentSetClauses.join(", ") + " WHERE student_id = :userId";
            studentQuery.prepare(sql);

            for (auto it = updates.begin(); it != updates.end(); ++it) {
                if (studentFields.contains(it.key())) {
                    studentQuery.bindValue(":" + it.key(), it.value());
                }
            }
            studentQuery.bindValue(":userId", userId);

            if (!studentQuery.exec()) {
                qWarning() << "Error updating student details:" << studentQuery.lastError().text();
            }
        }
    } else if (userRole == "Staff") {
        QStringList staffFields = {"staff_no", "department", "start_year", "category"};
        QStringList staffSetClauses;

        for (auto it = updates.begin(); it != updates.end(); ++it) {
            if (staffFields.contains(it.key())) {
                staffSetClauses.append(it.key() + " = :" + it.key());
            }
        }

        if (!staffSetClauses.isEmpty()) {
            QSqlQuery staffQuery(db);
            QString sql = "UPDATE staff SET " + staffSetClauses.join(", ") + " WHERE staff_id = :userId";
            staffQuery.prepare(sql);

            for (auto it = updates.begin(); it != updates.end(); ++it) {
                if (staffFields.contains(it.key())) {
                    staffQuery.bindValue(":" + it.key(), it.value());
                }
            }
            staffQuery.bindValue(":userId", userId);

            if (!staffQuery.exec()) {
                qWarning() << "Error updating staff details:" << staffQuery.lastError().text();
            }
        }
    } else if (userRole == "Other") {
        QStringList otherFields = {"user_no", "residence", "age", "gender", "phone"};
        QStringList otherSetClauses;

        for (auto it = updates.begin(); it != updates.end(); ++it) {
            if (otherFields.contains(it.key())) {
                otherSetClauses.append(it.key() + " = :" + it.key());
            }
        }

        if (!otherSetClauses.isEmpty()) {
            QSqlQuery otherQuery(db);
            QString sql = "UPDATE other_users SET " + otherSetClauses.join(", ") + " WHERE other_users_id = :userId";
            otherQuery.prepare(sql);

            for (auto it = updates.begin(); it != updates.end(); ++it) {
                if (otherFields.contains(it.key())) {
                    otherQuery.bindValue(":" + it.key(), it.value());
                }
            }
            otherQuery.bindValue(":userId", userId);

            if (!otherQuery.exec()) {
                qWarning() << "Error updating other user details:" << otherQuery.lastError().text();
            }
        }
    }

    emit userDetailsUpdated(userId);
    return true;
}

bool UserManager::verifyAdminPassword(const QString &password) const
{
    // PLACEHOLDER: This will be replaced with AppManager verification
    // For now, use a simple placeholder password
    const QString PLACEHOLDER_ADMIN_PASSWORD = "admin123";

    return password == PLACEHOLDER_ADMIN_PASSWORD;

    // TODO: Replace with:
    // return AppManager::instance()->verifyAdminPassword(password);
}

QVariantMap UserManager::getRoleSpecificDetails(int userId, const QString &userRole) const
{
    if (userRole == "Student") {
        return getStudentDetails(userId);
    } else if (userRole == "Staff") {
        return getStaffDetails(userId);
    } else if (userRole == "Other") {
        return getOtherUserDetails(userId);
    }
    return QVariantMap();
}

QVariantMap UserManager::getStudentDetails(int userId) const
{
    QVariantMap details;

    QSqlQuery query(db);
    query.prepare(
        "SELECT adm_no, branch, enrollment_year, level "
        "FROM students WHERE student_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        details["userNumber"] = query.value("adm_no").toString();
        details["admNo"] = query.value("adm_no").toString();
        details["branch"] = query.value("branch").toString();
        details["enrollmentYear"] = query.value("enrollment_year").toInt();
        details["level"] = query.value("level").toString();
    }

    return details;
}

QVariantMap UserManager::getStaffDetails(int userId) const
{
    QVariantMap details;

    QSqlQuery query(db);
    query.prepare(
        "SELECT staff_no, department, start_year, category "
        "FROM staff WHERE staff_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        details["userNumber"] = query.value("staff_no").toString();
        details["staffNo"] = query.value("staff_no").toString();
        details["department"] = query.value("department").toString();
        details["startYear"] = query.value("start_year").toInt();
        details["category"] = query.value("category").toString();
    }

    return details;
}

QVariantMap UserManager::getOtherUserDetails(int userId) const
{
    QVariantMap details;

    QSqlQuery query(db);
    query.prepare(
        "SELECT user_no, residence, age, gender, phone "
        "FROM other_users WHERE other_users_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (query.exec() && query.next()) {
        details["userNumber"] = query.value("user_no").toString();
        details["userNo"] = query.value("user_no").toString();
        details["residence"] = query.value("residence").toString();
        details["age"] = query.value("age").toInt();
        details["gender"] = query.value("gender").toString();
        // Phone from other_users table
        QString phone = query.value("phone").toString();
        if (!phone.isEmpty()) {
            details["phone"] = phone;
        }
    }

    return details;
}
