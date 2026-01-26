#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QVariantMap>
#include <QVariantList>
#include <QDebug>
#include "databasemanager.h"

/**
 * @brief UserManager handles fetching and updating user details for display on user pages.
 *
 * This class provides methods to:
 * - Fetch user details from the database
 * - Get user statistics (total books issued, current borrows)
 * - Update user details (with admin approval)
 */
class UserManager : public QObject
{
    Q_OBJECT

public:
    explicit UserManager(QObject *parent = nullptr);
    ~UserManager();

    Q_INVOKABLE bool addUser(const QString &firstName, const QString &lastName, const QString &email, const QString &phone,  const QString &userRole, const QVariantMap &additionalInfo);

    /**
     * @brief Get complete user details by user ID
     * @param userId The internal user ID
     * @return QVariantMap with all user details
     */
    Q_INVOKABLE QVariantMap getUserById(int userId) const;

    /**
     * @brief Get complete user details by user number
     * @param userNumber The user-specific number (adm_no/staff_no/user_no)
     * @param userRole The user role: "Student", "Staff", or "Other"
     * @return QVariantMap with all user details
     */
    Q_INVOKABLE QVariantMap getUserByNumber(const QString &userNumber, const QString &userRole) const;

    /**
     * @brief Get the total number of books ever issued to a user
     * @param userId The internal user ID
     * @return Total count of books issued (including returned ones)
     */
    Q_INVOKABLE int getTotalBooksIssued(int userId) const;

    /**
     * @brief Get the count of currently borrowed books
     * @param userId The internal user ID
     * @return Count of books currently borrowed
     */
    Q_INVOKABLE int getCurrentlyBorrowedCount(int userId) const;

    /**
     * @brief Get the count of overdue books for a user
     * @param userId The internal user ID
     * @return Count of overdue books
     */
    Q_INVOKABLE int getOverdueCount(int userId) const;

    /**
     * @brief Get total fines for a user (paid and unpaid)
     * @param userId The internal user ID
     * @return QVariantMap with "total", "paid", "unpaid" amounts
     */
    Q_INVOKABLE QVariantMap getUserFines(int userId) const;

    /**
     * @brief Get the user's borrowing history
     * @param userId The internal user ID
     * @param limit Maximum number of records to return (0 = all)
     * @return QVariantList of borrowing records
     */
    Q_INVOKABLE QVariantList getBorrowingHistory(int userId, int limit = 10) const;

    /**
     * @brief Update user details (requires admin password verification)
     * @param userId The internal user ID
     * @param updates QVariantMap with field-value pairs to update
     * @param adminPassword The admin password for verification
     * @return true if update successful
     */
    Q_INVOKABLE bool updateUserDetails(int userId, const QVariantMap &updates, const QString &adminPassword);

    /**
     * @brief Verify admin password (placeholder - will use AppManager later)
     * @param password The password to verify
     * @return true if password is correct
     */
    Q_INVOKABLE bool verifyAdminPassword(const QString &password) const;

    /**
     * @brief Get user's role-specific details
     * @param userId The internal user ID
     * @param userRole The user role
     * @return QVariantMap with role-specific details
     */
    Q_INVOKABLE QVariantMap getRoleSpecificDetails(int userId, const QString &userRole) const;

signals:
    void userDetailsUpdated(int userId);
    void updateFailed(const QString &errorMessage);
    void errorOccurred(const QString &error);

private:
    QSqlDatabase db;

    // Helper methods
    QVariantMap getStudentDetails(int userId) const;
    QVariantMap getStaffDetails(int userId) const;
    QVariantMap getOtherUserDetails(int userId) const;
};

#endif // USERMANAGER_H
