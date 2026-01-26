#include "loginmanager.h"
#include <QSqlRecord>

LoginManager::LoginManager(QObject *parent)
    : QObject(parent),
    m_currentUserId(0),
    m_isLoggedIn(false),
    m_enrollmentYear(0),
    m_startYear(0)
{
    db = DatabaseManager::getConnection();
    if (!db.isOpen()) {
        qWarning() << "LoginManager: Database connection not available";
    }
}

LoginManager::~LoginManager()
{
    // Database connection is managed by DatabaseManager
}

bool LoginManager::login(const QString &username, const QString &password, const QString &userType)
{
    if (username.trimmed().isEmpty() || password.trimmed().isEmpty()) {
        emit loginFailed("Username and password are required");
        return false;
    }

    bool success = false;

    if (userType == "Student") {
        success = authenticateStudent(username.trimmed(), password.trimmed());
    } else if (userType == "Staff") {
        success = authenticateStaff(username.trimmed(), password.trimmed());
    } else if (userType == "Other") {
        success = authenticateOtherUser(username.trimmed(), password.trimmed());
    } else {
        emit loginFailed("Invalid user type specified");
        return false;
    }

    if (success) {
        m_isLoggedIn = true;
        emit loginStateChanged();
        emit currentUserChanged();
        emit loginSuccessful(m_currentUserName, m_currentUserRole);
        qDebug() << "Login successful for:" << m_currentUserName << "Role:" << m_currentUserRole;
    }

    return success;
}

void LoginManager::logout()
{
    clearSession();
    emit loginStateChanged();
    emit currentUserChanged();
    emit logoutSuccessful();
    qDebug() << "User logged out successfully";
}

void LoginManager::clearSession()
{
    m_currentUserId = 0;
    m_currentUserName.clear();
    m_currentUserNumber.clear();
    m_currentUserRole.clear();
    m_currentUserEmail.clear();
    m_currentUserPhone.clear();
    m_department.clear();
    m_category.clear();
    m_branch.clear();
    m_level.clear();
    m_residence.clear();
    m_enrollmentYear = 0;
    m_startYear = 0;
    m_isLoggedIn = false;
}

bool LoginManager::findUserByNameOrEmail(const QString &username, const QString &userRole,
                                         int &userId, QString &firstName, QString &secondName, QString &email)
{
    QSqlQuery query(db);

    // Search by full name (first_name + second_name) or by email
    query.prepare(
        "SELECT user_id, first_name, second_name, email, phone "
        "FROM users "
        "WHERE user_role = :role AND status = 'Active' AND "
        "((first_name || ' ' || second_name) = :username COLLATE NOCASE OR "
        "email = :email COLLATE NOCASE)"
        );
    query.bindValue(":role", userRole);
    query.bindValue(":username", username);
    query.bindValue(":email", username);

    if (!query.exec()) {
        qWarning() << "Error finding user:" << query.lastError().text();
        return false;
    }

    if (query.next()) {
        userId = query.value("user_id").toInt();
        firstName = query.value("first_name").toString();
        secondName = query.value("second_name").toString();
        email = query.value("email").toString();
        m_currentUserPhone = query.value("phone").toString();
        return true;
    }

    return false;
}

bool LoginManager::authenticateStudent(const QString &username, const QString &password)
{
    int userId = 0;
    QString firstName, secondName, email;

    if (!findUserByNameOrEmail(username, "Student", userId, firstName, secondName, email)) {
        emit loginFailed("Student not found. Please check your name or email.");
        return false;
    }

    // Verify password (adm_no) from students table
    QSqlQuery query(db);
    query.prepare(
        "SELECT adm_no, branch, enrollment_year, level "
        "FROM students "
        "WHERE student_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (!query.exec()) {
        qWarning() << "Error verifying student credentials:" << query.lastError().text();
        emit loginFailed("Database error. Please try again.");
        return false;
    }

    if (!query.next()) {
        emit loginFailed("Student record not found.");
        return false;
    }

    QString storedAdmNo = query.value("adm_no").toString();

    // Compare password (case-insensitive for convenience)
    if (storedAdmNo.compare(password, Qt::CaseInsensitive) != 0) {
        emit loginFailed("Invalid admission number. Please try again.");
        return false;
    }

    // Authentication successful - populate session data
    m_currentUserId = userId;
    m_currentUserName = firstName + " " + secondName;
    m_currentUserNumber = storedAdmNo;
    m_currentUserRole = "Student";
    m_currentUserEmail = email;
    m_branch = query.value("branch").toString();
    m_enrollmentYear = query.value("enrollment_year").toInt();
    m_level = query.value("level").toString();

    return true;
}

bool LoginManager::authenticateStaff(const QString &username, const QString &password)
{
    int userId = 0;
    QString firstName, secondName, email;

    if (!findUserByNameOrEmail(username, "Staff", userId, firstName, secondName, email)) {
        emit loginFailed("Staff member not found. Please check your name or email.");
        return false;
    }

    // Verify password (staff_no) from staff table
    QSqlQuery query(db);
    query.prepare(
        "SELECT staff_no, department, start_year, category "
        "FROM staff "
        "WHERE staff_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (!query.exec()) {
        qWarning() << "Error verifying staff credentials:" << query.lastError().text();
        emit loginFailed("Database error. Please try again.");
        return false;
    }

    if (!query.next()) {
        emit loginFailed("Staff record not found.");
        return false;
    }

    QString storedStaffNo = query.value("staff_no").toString();

    // Compare password (case-insensitive for convenience)
    if (storedStaffNo.compare(password, Qt::CaseInsensitive) != 0) {
        emit loginFailed("Invalid staff number. Please try again.");
        return false;
    }

    // Authentication successful - populate session data
    m_currentUserId = userId;
    m_currentUserName = firstName + " " + secondName;
    m_currentUserNumber = storedStaffNo;
    m_currentUserRole = "Staff";
    m_currentUserEmail = email;
    m_department = query.value("department").toString();
    m_startYear = query.value("start_year").toInt();
    m_category = query.value("category").toString();

    return true;
}

bool LoginManager::authenticateOtherUser(const QString &username, const QString &password)
{
    int userId = 0;
    QString firstName, secondName, email;

    if (!findUserByNameOrEmail(username, "Other", userId, firstName, secondName, email)) {
        emit loginFailed("User not found. Please check your name or email.");
        return false;
    }

    // Verify password (user_no) from other_users table
    QSqlQuery query(db);
    query.prepare(
        "SELECT user_no, residence, age, gender, phone "
        "FROM other_users "
        "WHERE other_users_id = :userId"
        );
    query.bindValue(":userId", userId);

    if (!query.exec()) {
        qWarning() << "Error verifying user credentials:" << query.lastError().text();
        emit loginFailed("Database error. Please try again.");
        return false;
    }

    if (!query.next()) {
        emit loginFailed("User record not found.");
        return false;
    }

    QString storedUserNo = query.value("user_no").toString();

    // Compare password (case-insensitive for convenience)
    if (storedUserNo.compare(password, Qt::CaseInsensitive) != 0) {
        emit loginFailed("Invalid user number. Please try again.");
        return false;
    }

    // Authentication successful - populate session data
    m_currentUserId = userId;
    m_currentUserName = firstName + " " + secondName;
    m_currentUserNumber = storedUserNo;
    m_currentUserRole = "Other";
    m_currentUserEmail = email;
    m_residence = query.value("residence").toString();

    // Phone from other_users table might override the one from users table
    QString otherPhone = query.value("phone").toString();
    if (!otherPhone.isEmpty()) {
        m_currentUserPhone = otherPhone;
    }

    return true;
}

QVariantMap LoginManager::getCurrentUserDetails() const
{
    QVariantMap details;

    if (!m_isLoggedIn) {
        return details;
    }

    details["userId"] = m_currentUserId;
    details["userName"] = m_currentUserName;
    details["userNumber"] = m_currentUserNumber;
    details["userRole"] = m_currentUserRole;
    details["email"] = m_currentUserEmail;
    details["phone"] = m_currentUserPhone;

    // Add role-specific details
    if (m_currentUserRole == "Student") {
        details["branch"] = m_branch;
        details["enrollmentYear"] = m_enrollmentYear;
        details["level"] = m_level;
    } else if (m_currentUserRole == "Staff") {
        details["department"] = m_department;
        details["startYear"] = m_startYear;
        details["category"] = m_category;
    } else if (m_currentUserRole == "Other") {
        details["residence"] = m_residence;
    }

    return details;
}

bool LoginManager::userExists(const QString &username, const QString &userType) const
{
    QString userRole;
    if (userType == "Student") {
        userRole = "Student";
    } else if (userType == "Staff") {
        userRole = "Staff";
    } else if (userType == "Other") {
        userRole = "Other";
    } else {
        return false;
    }

    QSqlQuery query(db);
    query.prepare(
        "SELECT COUNT(*) FROM users "
        "WHERE user_role = :role AND status = 'Active' AND "
        "((first_name || ' ' || second_name) = :username COLLATE NOCASE OR "
        "email = :email COLLATE NOCASE)"
        );
    query.bindValue(":role", userRole);
    query.bindValue(":username", username);
    query.bindValue(":email", username);

    if (query.exec() && query.next()) {
        return query.value(0).toInt() > 0;
    }

    return false;
}

QString LoginManager::getTargetPage() const
{
    if (!m_isLoggedIn) {
        return QString();
    }

    if (m_currentUserRole == "Student") {
        return "StudentPage.qml";
    } else if (m_currentUserRole == "Staff") {
        return "StaffPage.qml";
    } else if (m_currentUserRole == "Other") {
        return "OtherUserPage.qml"; // You may want to create this or use StudentPage
    }

    return QString();
}
