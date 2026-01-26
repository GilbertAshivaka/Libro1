#ifndef APPMANAGER_H
#define APPMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QDateTime>
#include <QDate>
#include <QJsonObject>
#include <QJsonDocument>
#include <QCryptographicHash>
#include <QRandomGenerator>
#include <QMutex>
#include <QVariantMap>
#include <QVariantList>
#include "databasemanager.h"

/**
 * @brief AppManager - Singleton class managing license validation and admin authentication
 *
 * This class handles:
 * - License activation and periodic validation (online + offline)
 * - Organization information storage
 * - Admin account management (CRUD operations)
 * - Password hashing using Qt's SHA-256 with salt
 *
 * License States:
 * - not_activated: No license entered yet
 * - trial: 7-day trial period active
 * - active: Valid paid subscription (basic/premium)
 * - expired: License expiry date has passed
 * - grace_period: 1-7 days after expiry (full function with warning)
 * - blocked: More than 7 days after expiry (app unusable)
 */
class AppManager : public QObject
{
    Q_OBJECT

    // ==================== LICENSE PROPERTIES ====================
    Q_PROPERTY(QString licenseStatus READ licenseStatus NOTIFY licenseStatusChanged)
    Q_PROPERTY(bool isActivated READ isActivated NOTIFY licenseStatusChanged)
    Q_PROPERTY(bool isLicenseValid READ isLicenseValid NOTIFY licenseStatusChanged)
    Q_PROPERTY(bool isBlocked READ isBlocked NOTIFY licenseStatusChanged)
    Q_PROPERTY(bool isGracePeriod READ isGracePeriod NOTIFY licenseStatusChanged)
    Q_PROPERTY(int graceDaysRemaining READ graceDaysRemaining NOTIFY licenseStatusChanged)
    Q_PROPERTY(QString licenseTier READ licenseTier NOTIFY licenseStatusChanged)
    Q_PROPERTY(QDate expiryDate READ expiryDate NOTIFY licenseStatusChanged)
    Q_PROPERTY(int daysRemaining READ daysRemaining NOTIFY licenseStatusChanged)
    Q_PROPERTY(QString lastValidationTime READ lastValidationTime NOTIFY licenseStatusChanged)
    Q_PROPERTY(bool isValidating READ isValidating NOTIFY validatingChanged)

    // ==================== ORGANIZATION PROPERTIES ====================
    Q_PROPERTY(QString organizationId READ organizationId NOTIFY organizationChanged)
    Q_PROPERTY(QString organizationName READ organizationName NOTIFY organizationChanged)
    Q_PROPERTY(QString organizationLocation READ organizationLocation NOTIFY organizationChanged)
    Q_PROPERTY(QString organizationAddress READ organizationAddress NOTIFY organizationChanged)
    Q_PROPERTY(QString organizationPhone READ organizationPhone NOTIFY organizationChanged)
    Q_PROPERTY(QString organizationEmail READ organizationEmail NOTIFY organizationChanged)

    // ==================== ADMIN PROPERTIES ====================
    Q_PROPERTY(bool hasAdminSetup READ hasAdminSetup NOTIFY adminStateChanged)
    Q_PROPERTY(bool isAdminLoggedIn READ isAdminLoggedIn NOTIFY adminStateChanged)
    Q_PROPERTY(int currentAdminId READ currentAdminId NOTIFY adminStateChanged)
    Q_PROPERTY(QString currentAdminName READ currentAdminName NOTIFY adminStateChanged)
    Q_PROPERTY(QString currentAdminUsername READ currentAdminUsername NOTIFY adminStateChanged)
    Q_PROPERTY(bool currentAdminIsSuperAdmin READ currentAdminIsSuperAdmin NOTIFY adminStateChanged)

public:
    explicit AppManager(QObject *parent = nullptr);
    ~AppManager();

    // Singleton instance
    static AppManager* instance();

    // ==================== LICENSE GETTERS ====================
    QString licenseStatus() const;
    bool isActivated() const;
    bool isLicenseValid() const;
    bool isBlocked() const;
    bool isGracePeriod() const;
    int graceDaysRemaining() const;
    QString licenseTier() const;
    QDate expiryDate() const;
    int daysRemaining() const;
    QString lastValidationTime() const;
    bool isValidating() const;

    // ==================== ORGANIZATION GETTERS ====================
    QString organizationId() const;
    QString organizationName() const;
    QString organizationLocation() const;
    QString organizationAddress() const;
    QString organizationPhone() const;
    QString organizationEmail() const;

    // ==================== ADMIN GETTERS ====================
    bool hasAdminSetup() const;
    bool isAdminLoggedIn() const;
    int currentAdminId() const;
    QString currentAdminName() const;
    QString currentAdminUsername() const;
    bool currentAdminIsSuperAdmin() const;

    // ==================== LICENSE METHODS ====================
    /**
     * @brief Activate license with organization ID and license key
     * @param orgId Organization ID from Libro portal
     * @param licenseKey License key from Libro portal
     * Emits activationSucceeded() or activationFailed(error)
     */
    Q_INVOKABLE void activateLicense(const QString &orgId, const QString &licenseKey);

    /**
     * @brief Validate license online (called on startup and periodically)
     * Falls back to cached data if offline
     */
    Q_INVOKABLE void validateLicense();

    /**
     * @brief Manual validation triggered by user
     */
    Q_INVOKABLE void manualValidation();

    /**
     * @brief Get all license details as a map for UI display
     */
    Q_INVOKABLE QVariantMap getLicenseDetails() const;

    /**
     * @brief Get validation history logs
     * @param limit Maximum number of logs to return
     */
    Q_INVOKABLE QVariantList getValidationLogs(int limit = 20) const;

    // ==================== ADMIN METHODS ====================
    /**
     * @brief Create the first admin account during initial setup
     * Creates entries in users, staff, and admins tables
     * First admin is automatically a super_admin
     */
    Q_INVOKABLE bool setupFirstAdmin(
        const QString &firstName,
        const QString &lastName,
        const QString &email,
        const QString &phone,
        const QString &staffNo,
        const QString &department,
        const QString &username,
        const QString &password
        );

    /**
     * @brief Admin login with username and password
     */
    Q_INVOKABLE bool adminLogin(const QString &username, const QString &password);

    /**
     * @brief Logout current admin
     */
    Q_INVOKABLE void adminLogout();

    /**
     * @brief Add a new admin from existing staff member
     * @param staffId The staff_id of the staff member to promote
     * @param username Admin username
     * @param password Admin password
     */
    Q_INVOKABLE bool addAdmin(int staffId, const QString &username, const QString &password);

    /**
     * @brief Change admin password
     * @param adminId The admin_id to change password for
     * @param oldPassword Current password for verification
     * @param newPassword New password
     */
    Q_INVOKABLE bool changeAdminPassword(int adminId, const QString &oldPassword, const QString &newPassword);

    /**
     * @brief Deactivate an admin account
     * @param adminId The admin_id to deactivate
     */
    Q_INVOKABLE bool deactivateAdmin(int adminId);

    /**
     * @brief Reactivate a deactivated admin account
     * @param adminId The admin_id to reactivate
     */
    Q_INVOKABLE bool reactivateAdmin(int adminId);

    /**
     * @brief Get list of all admins
     */
    Q_INVOKABLE QVariantList getAllAdmins() const;

    /**
     * @brief Get list of active staff members who are not yet admins
     * Used for the "Add Admin" dialog
     */
    Q_INVOKABLE QVariantList getStaffNotAdmins() const;

    /**
     * @brief Check if username is available
     */
    Q_INVOKABLE bool isUsernameAvailable(const QString &username) const;

    // ==================== PASSWORD UTILITIES ====================
    /**
     * @brief Hash a password using SHA-256 with random salt
     * @param password Plain text password
     * @return Salted hash in format: "salt$hash" (hex encoded)
     */
    static QString hashPassword(const QString &password);

    /**
     * @brief Verify a password against stored hash
     * @param password Plain text password to verify
     * @param storedHash Stored hash from database
     * @return true if password matches
     */
    static bool verifyPassword(const QString &password, const QString &storedHash);

signals:
    // License signals
    void licenseStatusChanged();
    void organizationChanged();
    void validatingChanged();

    // Admin signals
    void adminStateChanged();

    // Async operation signals
    void activationSucceeded();
    void activationFailed(const QString &error);
    void validationCompleted(bool success, const QString &message);
    void networkError(const QString &error);

    // Error signals
    void errorOccurred(const QString &error);

private slots:
    void onValidationTimerTimeout();
    void onNetworkReplyFinished(QNetworkReply *reply);

private:
    // Singleton instance
    static AppManager* m_instance;
    static QMutex m_mutex;

    // Database
    QSqlDatabase m_db;

    // Network
    QNetworkAccessManager *m_networkManager;
    QTimer *m_validationTimer;
    static const int VALIDATION_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 hours
    static const int NETWORK_TIMEOUT_MS = 30000; // 30 seconds
    static const int GRACE_PERIOD_DAYS = 7;

    // API Configuration
    QString m_apiBaseUrl;

    // License state
    QString m_licenseStatus;        // not_activated, trial, active, expired, grace_period, blocked
    QString m_organizationId;
    QString m_licenseKey;
    QString m_organizationName;
    QString m_organizationLocation;
    QString m_organizationAddress;
    QString m_organizationPhone;
    QString m_organizationEmail;
    QString m_licenseTier;          // trial, basic, premium
    QDate m_activationDate;
    QDate m_expiryDate;
    QDateTime m_lastValidation;
    QString m_lastValidationStatus;
    bool m_isValidating;

    // Admin state
    int m_currentAdminId;
    QString m_currentAdminName;
    QString m_currentAdminUsername;
    bool m_currentAdminIsSuperAdmin;

    // Private methods
    bool createTables();
    bool loadLicenseFromDatabase();
    bool saveLicenseToDatabase();
    void updateLicenseStatus();
    void logValidation(const QString &type, bool wasOnline, const QString &result,
                       const QString &serverResponse = QString(), const QString &errorMessage = QString());
    QString buildApiUrl(const QString &endpoint) const;

    // Network request types
    enum RequestType {
        ActivationRequest,
        ValidationRequest
    };
    QMap<QNetworkReply*, RequestType> m_pendingRequests;

    void handleActivationResponse(const QJsonObject &response);
    void handleValidationResponse(const QJsonObject &response);
    void handleNetworkError(QNetworkReply *reply, const QString &context);
};

#endif // APPMANAGER_H
