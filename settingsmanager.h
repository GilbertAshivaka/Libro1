#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>
#include <QVariant>
#include <QMutex>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>

/**
 * @brief The SettingsManager class provides a centralized, thread-safe singleton
 * for managing application settings using a hybrid storage approach:
 * - Bootstrap/System settings: Stored in QSettings (INI file)
 * - Operational settings: Stored in SQLite database (app_settings table)
 *
 * All properties are exposed to QML via Q_PROPERTY for easy binding.
 */
class SettingsManager : public QObject
{
    Q_OBJECT

    // GENERAL SETTINGS
    Q_PROPERTY(QString applicationTitle READ applicationTitle WRITE setApplicationTitle NOTIFY applicationTitleChanged)
    Q_PROPERTY(QString databaseFileName READ databaseFileName CONSTANT) // Read-only, bootstrap setting
    Q_PROPERTY(QString organizationName READ organizationName WRITE setOrganizationName NOTIFY organizationNameChanged)
    Q_PROPERTY(QString libraryName READ libraryName WRITE setLibraryName NOTIFY libraryNameChanged)
    Q_PROPERTY(QString libraryAddress READ libraryAddress WRITE setLibraryAddress NOTIFY libraryAddressChanged)
    Q_PROPERTY(QString libraryPhone READ libraryPhone WRITE setLibraryPhone NOTIFY libraryPhoneChanged)
    Q_PROPERTY(QString libraryEmail READ libraryEmail WRITE setLibraryEmail NOTIFY libraryEmailChanged)

    // CIRCULATION SETTINGS
    // Student Rules
    Q_PROPERTY(int studentMaxLoanDays READ studentMaxLoanDays WRITE setStudentMaxLoanDays NOTIFY studentMaxLoanDaysChanged)
    Q_PROPERTY(int studentMaxBooksAllowed READ studentMaxBooksAllowed WRITE setStudentMaxBooksAllowed NOTIFY studentMaxBooksAllowedChanged)
    Q_PROPERTY(int studentMaxRenewals READ studentMaxRenewals WRITE setStudentMaxRenewals NOTIFY studentMaxRenewalsChanged)

    // Staff Rules
    Q_PROPERTY(int staffMaxLoanDays READ staffMaxLoanDays WRITE setStaffMaxLoanDays NOTIFY staffMaxLoanDaysChanged)
    Q_PROPERTY(int staffMaxBooksAllowed READ staffMaxBooksAllowed WRITE setStaffMaxBooksAllowed NOTIFY staffMaxBooksAllowedChanged)
    Q_PROPERTY(int staffMaxRenewals READ staffMaxRenewals WRITE setStaffMaxRenewals NOTIFY staffMaxRenewalsChanged)

    // Other Users Rules
    Q_PROPERTY(int otherMaxLoanDays READ otherMaxLoanDays WRITE setOtherMaxLoanDays NOTIFY otherMaxLoanDaysChanged)
    Q_PROPERTY(int otherMaxBooksAllowed READ otherMaxBooksAllowed WRITE setOtherMaxBooksAllowed NOTIFY otherMaxBooksAllowedChanged)
    Q_PROPERTY(int otherMaxRenewals READ otherMaxRenewals WRITE setOtherMaxRenewals NOTIFY otherMaxRenewalsChanged)

    // Fine Settings
    Q_PROPERTY(double fineRatePerDay READ fineRatePerDay WRITE setFineRatePerDay NOTIFY fineRatePerDayChanged)
    Q_PROPERTY(double maxFineAmount READ maxFineAmount WRITE setMaxFineAmount NOTIFY maxFineAmountChanged)
    Q_PROPERTY(QString currencySymbol READ currencySymbol WRITE setCurrencySymbol NOTIFY currencySymbolChanged)

    // RESERVATION SETTINGS
    Q_PROPERTY(int reservationPickupDays READ reservationPickupDays WRITE setReservationPickupDays NOTIFY reservationPickupDaysChanged)
    Q_PROPERTY(int reservationExpiryDays READ reservationExpiryDays WRITE setReservationExpiryDays NOTIFY reservationExpiryDaysChanged)
    Q_PROPERTY(int maxReservationsPerUser READ maxReservationsPerUser WRITE setMaxReservationsPerUser NOTIFY maxReservationsPerUserChanged)

    // EMAIL/SMTP SETTINGS
    Q_PROPERTY(QString smtpServer READ smtpServer WRITE setSmtpServer NOTIFY smtpServerChanged)
    Q_PROPERTY(int smtpPort READ smtpPort WRITE setSmtpPort NOTIFY smtpPortChanged)
    Q_PROPERTY(QString smtpUsername READ smtpUsername WRITE setSmtpUsername NOTIFY smtpUsernameChanged)
    Q_PROPERTY(QString smtpPassword READ smtpPassword WRITE setSmtpPassword NOTIFY smtpPasswordChanged)
    Q_PROPERTY(bool smtpUseTLS READ smtpUseTLS WRITE setSmtpUseTLS NOTIFY smtpUseTLSChanged)
    Q_PROPERTY(QString senderEmail READ senderEmail WRITE setSenderEmail NOTIFY senderEmailChanged)
    Q_PROPERTY(QString senderName READ senderName WRITE setSenderName NOTIFY senderNameChanged)
    Q_PROPERTY(bool emailNotificationsEnabled READ emailNotificationsEnabled WRITE setEmailNotificationsEnabled NOTIFY emailNotificationsEnabledChanged)

    // Email Templates
    Q_PROPERTY(QString overdueEmailTemplate READ overdueEmailTemplate WRITE setOverdueEmailTemplate NOTIFY overdueEmailTemplateChanged)
    Q_PROPERTY(QString pickupEmailTemplate READ pickupEmailTemplate WRITE setPickupEmailTemplate NOTIFY pickupEmailTemplateChanged)
    Q_PROPERTY(QString welcomeEmailTemplate READ welcomeEmailTemplate WRITE setWelcomeEmailTemplate NOTIFY welcomeEmailTemplateChanged)

    // SYSTEM & MAINTENANCE SETTINGS
    Q_PROPERTY(int logRetentionDays READ logRetentionDays WRITE setLogRetentionDays NOTIFY logRetentionDaysChanged)
    Q_PROPERTY(bool autoBackupEnabled READ autoBackupEnabled WRITE setAutoBackupEnabled NOTIFY autoBackupEnabledChanged)
    Q_PROPERTY(int backupIntervalDays READ backupIntervalDays WRITE setBackupIntervalDays NOTIFY backupIntervalDaysChanged)
    Q_PROPERTY(QString backupLocation READ backupLocation WRITE setBackupLocation NOTIFY backupLocationChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);
    ~SettingsManager();

    /**
     * @brief Returns the singleton instance of SettingsManager
     * @return Pointer to the SettingsManager instance
     */
    static SettingsManager *instance();

    /**
     * @brief Initializes the database table for storing operational settings
     * @param db The database connection to use
     * @return true if successful, false otherwise
     */
    bool initializeDatabase(const QSqlDatabase &db);

    /**
     * @brief Checks if the settings database table is initialized
     * @return true if initialized, false otherwise
     */
    Q_INVOKABLE bool isInitialized() const;

    /**
     * @brief Reloads all settings from storage (both INI and database)
     */
    Q_INVOKABLE void reloadSettings();

    /**
     * @brief Resets all settings to their default values
     */
    Q_INVOKABLE void resetToDefaults();

    /**
     * @brief Exports settings to a JSON file for backup
     * @param filePath Path to the export file
     * @return true if successful, false otherwise
     */
    Q_INVOKABLE bool exportSettings(const QString &filePath);

    /**
     * @brief Imports settings from a JSON file
     * @param filePath Path to the import file
     * @return true if successful, false otherwise
     */
    Q_INVOKABLE bool importSettings(const QString &filePath);

    // GENERAL SETTINGS - Accessors
    QString applicationTitle() const;
    void setApplicationTitle(const QString &title);
    QString databaseFileName() const;
    QString organizationName() const;
    void setOrganizationName(const QString &name);
    QString libraryName() const;
    void setLibraryName(const QString &name);
    QString libraryAddress() const;
    void setLibraryAddress(const QString &address);
    QString libraryPhone() const;
    void setLibraryPhone(const QString &phone);
    QString libraryEmail() const;
    void setLibraryEmail(const QString &email);

    // CIRCULATION SETTINGS - Accessors
    // Student
    int studentMaxLoanDays() const;
    void setStudentMaxLoanDays(int days);
    int studentMaxBooksAllowed() const;
    void setStudentMaxBooksAllowed(int count);
    int studentMaxRenewals() const;
    void setStudentMaxRenewals(int count);

    // Staff
    int staffMaxLoanDays() const;
    void setStaffMaxLoanDays(int days);
    int staffMaxBooksAllowed() const;
    void setStaffMaxBooksAllowed(int count);
    int staffMaxRenewals() const;
    void setStaffMaxRenewals(int count);

    // Other Users
    int otherMaxLoanDays() const;
    void setOtherMaxLoanDays(int days);
    int otherMaxBooksAllowed() const;
    void setOtherMaxBooksAllowed(int count);
    int otherMaxRenewals() const;
    void setOtherMaxRenewals(int count);

    // Fines
    double fineRatePerDay() const;
    void setFineRatePerDay(double rate);
    double maxFineAmount() const;
    void setMaxFineAmount(double amount);
    QString currencySymbol() const;
    void setCurrencySymbol(const QString &symbol);

    // RESERVATION SETTINGS - Accessors
    int reservationPickupDays() const;
    void setReservationPickupDays(int days);
    int reservationExpiryDays() const;
    void setReservationExpiryDays(int days);
    int maxReservationsPerUser() const;
    void setMaxReservationsPerUser(int count);

    // EMAIL SETTINGS - Accessors
    QString smtpServer() const;
    void setSmtpServer(const QString &server);
    int smtpPort() const;
    void setSmtpPort(int port);
    QString smtpUsername() const;
    void setSmtpUsername(const QString &username);
    QString smtpPassword() const;
    void setSmtpPassword(const QString &password);
    bool smtpUseTLS() const;
    void setSmtpUseTLS(bool use);
    QString senderEmail() const;
    void setSenderEmail(const QString &email);
    QString senderName() const;
    void setSenderName(const QString &name);
    bool emailNotificationsEnabled() const;
    void setEmailNotificationsEnabled(bool enabled);

    // Email Templates
    QString overdueEmailTemplate() const;
    void setOverdueEmailTemplate(const QString &templateText);
    QString pickupEmailTemplate() const;
    void setPickupEmailTemplate(const QString &templateText);
    QString welcomeEmailTemplate() const;
    void setWelcomeEmailTemplate(const QString &templateText);

    // SYSTEM SETTINGS - Accessors
    int logRetentionDays() const;
    void setLogRetentionDays(int days);
    bool autoBackupEnabled() const;
    void setAutoBackupEnabled(bool enabled);
    int backupIntervalDays() const;
    void setBackupIntervalDays(int days);
    QString backupLocation() const;
    void setBackupLocation(const QString &location);

    // UTILITY METHODS
    /**
     * @brief Gets circulation rules for a specific user role
     * @param userRole The role: "Student", "Staff", or "Other"
     * @return QVariantMap containing maxLoanDays, maxBooks, maxRenewals
     */
    Q_INVOKABLE QVariantMap getCirculationRulesForRole(const QString &userRole) const;

signals:
    // General
    void applicationTitleChanged();
    void organizationNameChanged();
    void libraryNameChanged();
    void libraryAddressChanged();
    void libraryPhoneChanged();
    void libraryEmailChanged();

    // Circulation - Student
    void studentMaxLoanDaysChanged();
    void studentMaxBooksAllowedChanged();
    void studentMaxRenewalsChanged();

    // Circulation - Staff
    void staffMaxLoanDaysChanged();
    void staffMaxBooksAllowedChanged();
    void staffMaxRenewalsChanged();

    // Circulation - Other
    void otherMaxLoanDaysChanged();
    void otherMaxBooksAllowedChanged();
    void otherMaxRenewalsChanged();

    // Fines
    void fineRatePerDayChanged();
    void maxFineAmountChanged();
    void currencySymbolChanged();

    // Reservation
    void reservationPickupDaysChanged();
    void reservationExpiryDaysChanged();
    void maxReservationsPerUserChanged();

    // Email
    void smtpServerChanged();
    void smtpPortChanged();
    void smtpUsernameChanged();
    void smtpPasswordChanged();
    void smtpUseTLSChanged();
    void senderEmailChanged();
    void senderNameChanged();
    void emailNotificationsEnabledChanged();
    void overdueEmailTemplateChanged();
    void pickupEmailTemplateChanged();
    void welcomeEmailTemplateChanged();

    // System
    void logRetentionDaysChanged();
    void autoBackupEnabledChanged();
    void backupIntervalDaysChanged();
    void backupLocationChanged();

    // Status signals
    void settingsLoaded();
    void settingsSaved();
    void errorOccurred(const QString &error);

private:
    // Singleton instance and mutex for thread safety
    static SettingsManager *m_instance;
    static QMutex m_mutex;

    // Storage backends
    QSettings m_iniSettings;       // For bootstrap settings (INI file)
    QSqlDatabase m_db;             // For operational settings (database)
    bool m_dbInitialized;

    // HELPER METHODS
    /**
     * @brief Reads a setting from INI file (for bootstrap settings)
     */
    QVariant readIniSetting(const QString &key, const QVariant &defaultValue) const;

    /**
     * @brief Writes a setting to INI file (for bootstrap settings)
     */
    void writeIniSetting(const QString &key, const QVariant &value);

    /**
     * @brief Reads a setting from the database (for operational settings)
     */
    QVariant readDbSetting(const QString &key, const QVariant &defaultValue) const;

    /**
     * @brief Writes a setting to the database (for operational settings)
     */
    bool writeDbSetting(const QString &category, const QString &key, const QVariant &value, const QString &type, const QString &description = QString());

    /**
     * @brief Creates the app_settings table if it doesn't exist
     */
    bool createSettingsTable();

    /**
     * @brief Populates default settings in the database
     */
    void populateDefaultSettings();

    /**
     * @brief Initializes default values in INI file for bootstrap settings
     */
    void initializeIniDefaults();
};

#endif // SETTINGSMANAGER_H
