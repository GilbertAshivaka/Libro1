#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariantMap>
#include <QDebug>
#include "databasemanager.h"

/**
 * @brief LoginManager handles authentication for students, staff, and other_users.
 *
 * Authentication uses:
 * - Username: user's full name (first_name + second_name) OR email
 * - Password: adm_no (students), staff_no (staff), user_no (other_users)
 *
 * Admin login is handled separately by AppManager (to be implemented later).
 */
class LoginManager : public QObject
{
    Q_OBJECT

    // Current logged-in user properties
    Q_PROPERTY(int currentUserId READ currentUserId NOTIFY currentUserChanged)
    Q_PROPERTY(QString currentUserName READ currentUserName NOTIFY currentUserChanged)
    Q_PROPERTY(QString currentUserNumber READ currentUserNumber NOTIFY currentUserChanged)
    Q_PROPERTY(QString currentUserRole READ currentUserRole NOTIFY currentUserChanged)
    Q_PROPERTY(QString currentUserEmail READ currentUserEmail NOTIFY currentUserChanged)
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStateChanged)

public:
    explicit LoginManager(QObject *parent = nullptr);
    ~LoginManager();

    // Property getters
    int currentUserId() const { return m_currentUserId; }
    QString currentUserName() const { return m_currentUserName; }
    QString currentUserNumber() const { return m_currentUserNumber; }
    QString currentUserRole() const { return m_currentUserRole; }
    QString currentUserEmail() const { return m_currentUserEmail; }
    bool isLoggedIn() const { return m_isLoggedIn; }

    /**
     * @brief Authenticate a user (student, staff, or other_user)
     * @param username The user's full name or email
     * @param password The user-specific number (adm_no/staff_no/user_no)
     * @param userType Expected user type: "Student", "Staff", or "Other"
     * @return true if authentication successful
     */
    Q_INVOKABLE bool login(const QString &username, const QString &password, const QString &userType);

    /**
     * @brief Logout the current user and clear session data
     */
    Q_INVOKABLE void logout();

    /**
     * @brief Get the current user's detailed information
     * @return QVariantMap with user details
     */
    Q_INVOKABLE QVariantMap getCurrentUserDetails() const;

    /**
     * @brief Check if a user exists with given credentials without logging in
     * @param username The user's full name or email
     * @param userType The user type to check
     * @return true if user exists
     */
    Q_INVOKABLE bool userExists(const QString &username, const QString &userType) const;

    /**
     * @brief Get the page to load after successful login
     * @return QString path to the QML page
     */
    Q_INVOKABLE QString getTargetPage() const;

signals:
    void currentUserChanged();
    void loginStateChanged();
    void loginSuccessful(const QString &userName, const QString &userRole);
    void loginFailed(const QString &errorMessage);
    void logoutSuccessful();

private:
    QSqlDatabase db;

    // Current user session data
    int m_currentUserId;
    QString m_currentUserName;
    QString m_currentUserNumber;
    QString m_currentUserRole;
    QString m_currentUserEmail;
    QString m_currentUserPhone;
    bool m_isLoggedIn;

    // Additional user-specific data
    QString m_department;    // For staff
    QString m_category;      // For staff
    QString m_branch;        // For students
    QString m_level;         // For students
    QString m_residence;     // For other_users
    int m_enrollmentYear;    // For students
    int m_startYear;         // For staff

    // Helper methods
    bool authenticateStudent(const QString &username, const QString &password);
    bool authenticateStaff(const QString &username, const QString &password);
    bool authenticateOtherUser(const QString &username, const QString &password);

    void clearSession();
    bool findUserByNameOrEmail(const QString &username, const QString &userRole, int &userId, QString &firstName, QString &secondName, QString &email);
};

#endif // LOGINMANAGER_H
