#include "SettingsManager.h"
#include <QDebug>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>

#include "databasemanager.h"

// STATIC MEMBERS
SettingsManager *SettingsManager::m_instance = nullptr;
QMutex SettingsManager::m_mutex;

// DEFAULT VALUES - Centralized for easy maintenance
namespace Defaults {
// General
const QString APPLICATION_TITLE = "Libro Integrated Library Management System";
const QString DATABASE_FILE_NAME = "library.db";
const QString ORGANIZATION_NAME = "Libro";
const QString LIBRARY_NAME = "";
const QString LIBRARY_ADDRESS = "";
const QString LIBRARY_PHONE = "";
const QString LIBRARY_EMAIL = "";

// Circulation - Student
const int STUDENT_MAX_LOAN_DAYS = 14;
const int STUDENT_MAX_BOOKS = 3;
const int STUDENT_MAX_RENEWALS = 2;

// Circulation - Staff
const int STAFF_MAX_LOAN_DAYS = 30;
const int STAFF_MAX_BOOKS = 10;
const int STAFF_MAX_RENEWALS = 3;

// Circulation - Other
const int OTHER_MAX_LOAN_DAYS = 7;
const int OTHER_MAX_BOOKS = 2;
const int OTHER_MAX_RENEWALS = 1;

// Fines
const double FINE_RATE_PER_DAY = 10.0;
const double MAX_FINE_AMOUNT = 500.0;
const QString CURRENCY_SYMBOL = "KES"; // Kenya Shillings, change as needed

// Reservation
const int RESERVATION_PICKUP_DAYS = 3;
const int RESERVATION_EXPIRY_DAYS = 7;
const int MAX_RESERVATIONS_PER_USER = 3;

// Email/SMTP
const QString SMTP_SERVER = "smtp.gmail.com";
const int SMTP_PORT = 587;
const QString SMTP_USERNAME = "";
const QString SMTP_PASSWORD = "";
const bool SMTP_USE_TLS = true;
const QString SENDER_EMAIL = "";
const QString SENDER_NAME = "Libro Library System";
const bool EMAIL_NOTIFICATIONS_ENABLED = false;

// Email Templates
const QString OVERDUE_EMAIL_TEMPLATE =
    "Dear {USER_NAME},\n\n"
    "This is a reminder that the following book is overdue:\n\n"
    "Title: {BOOK_TITLE}\n"
    "Due Date: {DUE_DATE}\n"
    "Days Overdue: {DAYS_OVERDUE}\n"
    "Fine Accrued: {CURRENCY_SYMBOL} {FINE_AMOUNT}\n\n"
    "Please return the book as soon as possible to avoid additional fines.\n\n"
    "Best regards,\n"
    "{LIBRARY_NAME}";

const QString PICKUP_EMAIL_TEMPLATE =
    "Dear {USER_NAME},\n\n"
    "Great news! The book you reserved is now available for pickup:\n\n"
    "Title: {BOOK_TITLE}\n"
    "Author: {BOOK_AUTHOR}\n\n"
    "Please collect it within {PICKUP_DAYS} days. After this period, "
    "the reservation will be cancelled and the book will be made available to other patrons.\n\n"
    "Best regards,\n"
    "{LIBRARY_NAME}";

const QString WELCOME_EMAIL_TEMPLATE =
    "Dear {USER_NAME},\n\n"
    "Welcome to {LIBRARY_NAME}!\n\n"
    "Your library account has been created successfully.\n"
    "You can now borrow books, make reservations, and access our digital resources.\n\n"
    "Your borrowing privileges:\n"
    "- Maximum books: {MAX_BOOKS}\n"
    "- Loan period: {LOAN_DAYS} days\n"
    "- Renewals allowed: {MAX_RENEWALS}\n\n"
    "If you have any questions, please contact us at {LIBRARY_EMAIL}.\n\n"
    "Best regards,\n"
    "{LIBRARY_NAME}";

// System
const int LOG_RETENTION_DAYS = 90;
const bool AUTO_BACKUP_ENABLED = false;
const int BACKUP_INTERVAL_DAYS = 7;
const QString BACKUP_LOCATION = "";
}


SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent),
    m_iniSettings(QSettings::IniFormat, QSettings::UserScope,
                  QCoreApplication::organizationName().isEmpty() ? "Libro" : QCoreApplication::organizationName(),
                  QCoreApplication::applicationName().isEmpty() ? "LibroLMS" : QCoreApplication::applicationName()),
    m_dbInitialized(false)
{
    qDebug() << "SettingsManager: Initializing...";
    qDebug() << "SettingsManager: INI file location:" << m_iniSettings.fileName();

    // Initialize bootstrap settings in INI file
    initializeIniDefaults();

    //Initialize database using connection from databasemanager
    QSqlDatabase db = DatabaseManager::getConnection();
    qDebug() << "Database connection fetched...";
    initializeDatabase(db);

    qDebug() << "Database initialised...";
}

SettingsManager::~SettingsManager()
{
    qDebug() << "SettingsManager: Shutting down...";
    m_iniSettings.sync();
}

// SINGLETON INSTANCE
SettingsManager *SettingsManager::instance()
{
    QMutexLocker locker(&m_mutex);
    if (!m_instance) {
        m_instance = new SettingsManager(QCoreApplication::instance());
    }
    return m_instance;
}

// DATABASE INITIALIZATION
bool SettingsManager::initializeDatabase(const QSqlDatabase &db)
{
    // QMutexLocker locker(&m_mutex);

    if (!db.isOpen()) {
        qWarning() << "SettingsManager: Cannot initialize - database is not open";
        emit errorOccurred("Database is not open");
        return false;
    }

    qDebug() << "Database is open...";

    m_db = db;

    if (!createSettingsTable()) {
        return false;
    }

    populateDefaultSettings();
    m_dbInitialized = true;

    qDebug() << "SettingsManager: Database initialized successfully";
    emit settingsLoaded();
    return true;
}

bool SettingsManager::createSettingsTable()
{
    QSqlQuery query(m_db);

    // table created in the central DatabaseManager class. Try to query the table - if it works, table exists
    if (query.exec("SELECT COUNT(*) FROM app_settings")) {
        qDebug() << "SettingsManager: app_settings table verified and accessible";
        return true;
    } else {
        qWarning() << "SettingsManager: app_settings table NOT accessible or doesn't exist";
        qWarning() << "Error:" << query.lastError().text();
        emit errorOccurred("Settings table not accessible: " + query.lastError().text());
        return false;
    }
}

void SettingsManager::populateDefaultSettings()
{
    // Check if settings already exist
    QSqlQuery checkQuery(m_db);
    checkQuery.exec("SELECT COUNT(*) FROM app_settings");
    if (checkQuery.next() && checkQuery.value(0).toInt() > 0) {
        qDebug() << "SettingsManager: Settings already populated, skipping defaults";
        return;
    }

    qDebug() << "SettingsManager: Populating default settings...";

    // General Settings
    writeDbSetting("General", "library_name", Defaults::LIBRARY_NAME, "string", "Name of the library");
    writeDbSetting("General", "library_address", Defaults::LIBRARY_ADDRESS, "string", "Physical address of the library");
    writeDbSetting("General", "library_phone", Defaults::LIBRARY_PHONE, "string", "Library contact phone number");
    writeDbSetting("General", "library_email", Defaults::LIBRARY_EMAIL, "string", "Library contact email");

    // Circulation - Student
    writeDbSetting("Circulation", "student_max_loan_days", Defaults::STUDENT_MAX_LOAN_DAYS, "int", "Maximum loan period for students (days)");
    writeDbSetting("Circulation", "student_max_books", Defaults::STUDENT_MAX_BOOKS, "int", "Maximum books a student can borrow");
    writeDbSetting("Circulation", "student_max_renewals", Defaults::STUDENT_MAX_RENEWALS, "int", "Maximum renewals allowed for students");

    // Circulation - Staff
    writeDbSetting("Circulation", "staff_max_loan_days", Defaults::STAFF_MAX_LOAN_DAYS, "int", "Maximum loan period for staff (days)");
    writeDbSetting("Circulation", "staff_max_books", Defaults::STAFF_MAX_BOOKS, "int", "Maximum books staff can borrow");
    writeDbSetting("Circulation", "staff_max_renewals", Defaults::STAFF_MAX_RENEWALS, "int", "Maximum renewals allowed for staff");

    // Circulation - Other
    writeDbSetting("Circulation", "other_max_loan_days", Defaults::OTHER_MAX_LOAN_DAYS, "int", "Maximum loan period for other users (days)");
    writeDbSetting("Circulation", "other_max_books", Defaults::OTHER_MAX_BOOKS, "int", "Maximum books other users can borrow");
    writeDbSetting("Circulation", "other_max_renewals", Defaults::OTHER_MAX_RENEWALS, "int", "Maximum renewals for other users");

    // Fines
    writeDbSetting("Circulation", "fine_rate_per_day", Defaults::FINE_RATE_PER_DAY, "double", "Fine amount charged per overdue day");
    writeDbSetting("Circulation", "max_fine_amount", Defaults::MAX_FINE_AMOUNT, "double", "Maximum fine cap");
    writeDbSetting("Circulation", "currency_symbol", Defaults::CURRENCY_SYMBOL, "string", "Currency symbol for fines");

    // Reservation
    writeDbSetting("Reservation", "pickup_days", Defaults::RESERVATION_PICKUP_DAYS, "int", "Days to pickup reserved book");
    writeDbSetting("Reservation", "expiry_days", Defaults::RESERVATION_EXPIRY_DAYS, "int", "Days until reservation expires");
    writeDbSetting("Reservation", "max_per_user", Defaults::MAX_RESERVATIONS_PER_USER, "int", "Maximum reservations per user");

    // Email/SMTP
    writeDbSetting("Email", "smtp_server", Defaults::SMTP_SERVER, "string", "SMTP server hostname");
    writeDbSetting("Email", "smtp_port", Defaults::SMTP_PORT, "int", "SMTP server port");
    writeDbSetting("Email", "smtp_username", Defaults::SMTP_USERNAME, "string", "SMTP authentication username");
    writeDbSetting("Email", "smtp_password", Defaults::SMTP_PASSWORD, "string", "SMTP authentication password");
    writeDbSetting("Email", "smtp_use_tls", Defaults::SMTP_USE_TLS, "bool", "Use TLS/SSL for SMTP");
    writeDbSetting("Email", "sender_email", Defaults::SENDER_EMAIL, "string", "Email sender address");
    writeDbSetting("Email", "sender_name", Defaults::SENDER_NAME, "string", "Email sender display name");
    writeDbSetting("Email", "notifications_enabled", Defaults::EMAIL_NOTIFICATIONS_ENABLED, "bool", "Enable email notifications");

    // Email Templates
    writeDbSetting("Email", "overdue_template", Defaults::OVERDUE_EMAIL_TEMPLATE, "string", "Template for overdue notifications");
    writeDbSetting("Email", "pickup_template", Defaults::PICKUP_EMAIL_TEMPLATE, "string", "Template for pickup notifications");
    writeDbSetting("Email", "welcome_template", Defaults::WELCOME_EMAIL_TEMPLATE, "string", "Template for welcome emails");

    // System
    writeDbSetting("System", "log_retention_days", Defaults::LOG_RETENTION_DAYS, "int", "Days to retain system logs");
    writeDbSetting("System", "auto_backup_enabled", Defaults::AUTO_BACKUP_ENABLED, "bool", "Enable automatic backups");
    writeDbSetting("System", "backup_interval_days", Defaults::BACKUP_INTERVAL_DAYS, "int", "Days between automatic backups");
    writeDbSetting("System", "backup_location", Defaults::BACKUP_LOCATION, "string", "Directory for backup files");

    qDebug() << "SettingsManager: Default settings populated";
}

void SettingsManager::initializeIniDefaults()
{
    // Bootstrap settings that must be available before database connection
    if (!m_iniSettings.contains("Bootstrap/ApplicationTitle")) {
        m_iniSettings.setValue("Bootstrap/ApplicationTitle", Defaults::APPLICATION_TITLE);
    }
    if (!m_iniSettings.contains("Bootstrap/OrganizationName")) {
        m_iniSettings.setValue("Bootstrap/OrganizationName", Defaults::ORGANIZATION_NAME);
    }
    if (!m_iniSettings.contains("Bootstrap/DatabaseFileName")) {
        m_iniSettings.setValue("Bootstrap/DatabaseFileName", Defaults::DATABASE_FILE_NAME);
    }

    m_iniSettings.sync();
}

// HELPER METHODS - INI Settings
QVariant SettingsManager::readIniSetting(const QString &key, const QVariant &defaultValue) const
{
    return m_iniSettings.value(key, defaultValue);
}

void SettingsManager::writeIniSetting(const QString &key, const QVariant &value)
{
    if (m_iniSettings.value(key) != value) {
        m_iniSettings.setValue(key, value);
        m_iniSettings.sync();
    }
}

// HELPER METHODS - Database Settings
QVariant SettingsManager::readDbSetting(const QString &key, const QVariant &defaultValue) const
{
    if (!m_dbInitialized) {
        qDebug() << "SettingsManager: DB not initialized, returning default for" << key;
        return defaultValue;
    }

    QSqlQuery query(m_db);
    query.prepare("SELECT setting_value, setting_type FROM app_settings WHERE setting_key = :key");
    query.bindValue(":key", key);

    if (query.exec() && query.next()) {
        QString value = query.value(0).toString();
        QString type = query.value(1).toString();

        // Convert based on type
        if (type == "int") {
            return value.toInt();
        } else if (type == "double") {
            return value.toDouble();
        } else if (type == "bool") {
            return (value.toLower() == "true" || value == "1");
        }
        return value;
    }

    return defaultValue;
}

bool SettingsManager::writeDbSetting(const QString &category, const QString &key, const QVariant &value, const QString &type, const QString &description)
{
    if (!m_dbInitialized && !m_db.isOpen()) {
        qWarning() << "SettingsManager: Cannot write setting - database not available";
        return false;
    }

    QSqlQuery query(m_db);

    // Use UPSERT pattern (INSERT OR REPLACE)
    query.prepare(
        "INSERT INTO app_settings (category, setting_key, setting_value, setting_type, description, updated_at) "
        "VALUES (:category, :key, :value, :type, :description, CURRENT_TIMESTAMP) "
        "ON CONFLICT(setting_key) DO UPDATE SET "
        "setting_value = :value, updated_at = CURRENT_TIMESTAMP"
        );

    query.bindValue(":category", category);
    query.bindValue(":key", key);
    query.bindValue(":value", value.toString());
    query.bindValue(":type", type);
    query.bindValue(":description", description);

    if (!query.exec()) {
        qWarning() << "SettingsManager: Failed to write setting" << key << ":" << query.lastError().text();
        return false;
    }

    emit settingsSaved();
    return true;
}

// UTILITY METHODS
bool SettingsManager::isInitialized() const
{
    return m_dbInitialized;
}

void SettingsManager::reloadSettings()
{
    m_iniSettings.sync();
    emit settingsLoaded();
    qDebug() << "SettingsManager: Settings reloaded";
}

void SettingsManager::resetToDefaults()
{
    if (!m_dbInitialized) {
        qWarning() << "SettingsManager: Cannot reset - database not initialized";
        return;
    }

    QSqlQuery query(m_db);
    query.exec("DELETE FROM app_settings");
    populateDefaultSettings();

    // Also reset INI bootstrap settings
    initializeIniDefaults();

    emit settingsLoaded();
    qDebug() << "SettingsManager: All settings reset to defaults";
}

bool SettingsManager::exportSettings(const QString &filePath)
{
    QJsonObject root;
    QJsonObject bootstrap, general, circulation, reservation, email, system;

    // Bootstrap (from INI)
    bootstrap["applicationTitle"] = applicationTitle();
    bootstrap["organizationName"] = organizationName();
    root["bootstrap"] = bootstrap;

    // General
    general["libraryName"] = libraryName();
    general["libraryAddress"] = libraryAddress();
    general["libraryPhone"] = libraryPhone();
    general["libraryEmail"] = libraryEmail();
    root["general"] = general;

    // Circulation
    circulation["studentMaxLoanDays"] = studentMaxLoanDays();
    circulation["studentMaxBooksAllowed"] = studentMaxBooksAllowed();
    circulation["studentMaxRenewals"] = studentMaxRenewals();
    circulation["staffMaxLoanDays"] = staffMaxLoanDays();
    circulation["staffMaxBooksAllowed"] = staffMaxBooksAllowed();
    circulation["staffMaxRenewals"] = staffMaxRenewals();
    circulation["otherMaxLoanDays"] = otherMaxLoanDays();
    circulation["otherMaxBooksAllowed"] = otherMaxBooksAllowed();
    circulation["otherMaxRenewals"] = otherMaxRenewals();
    circulation["fineRatePerDay"] = fineRatePerDay();
    circulation["maxFineAmount"] = maxFineAmount();
    circulation["currencySymbol"] = currencySymbol();
    root["circulation"] = circulation;

    // Reservation
    reservation["pickupDays"] = reservationPickupDays();
    reservation["expiryDays"] = reservationExpiryDays();
    reservation["maxPerUser"] = maxReservationsPerUser();
    root["reservation"] = reservation;

    // Email (excluding password for security)
    email["smtpServer"] = smtpServer();
    email["smtpPort"] = smtpPort();
    email["smtpUsername"] = smtpUsername();
    email["smtpUseTLS"] = smtpUseTLS();
    email["senderEmail"] = senderEmail();
    email["senderName"] = senderName();
    email["notificationsEnabled"] = emailNotificationsEnabled();
    email["overdueTemplate"] = overdueEmailTemplate();
    email["pickupTemplate"] = pickupEmailTemplate();
    email["welcomeTemplate"] = welcomeEmailTemplate();
    root["email"] = email;

    // System
    system["logRetentionDays"] = logRetentionDays();
    system["autoBackupEnabled"] = autoBackupEnabled();
    system["backupIntervalDays"] = backupIntervalDays();
    system["backupLocation"] = backupLocation();
    root["system"] = system;

    // Metadata
    QJsonObject meta;
    meta["exportDate"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    meta["version"] = "1.0";
    root["_meta"] = meta;

    // Write to file
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "SettingsManager: Cannot open file for export:" << filePath;
        emit errorOccurred("Cannot open file for export");
        return false;
    }

    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();

    qDebug() << "SettingsManager: Settings exported to" << filePath;
    return true;
}

bool SettingsManager::importSettings(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "SettingsManager: Cannot open file for import:" << filePath;
        emit errorOccurred("Cannot open file for import");
        return false;
    }

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();

    if (doc.isNull() || !doc.isObject()) {
        emit errorOccurred("Invalid settings file format");
        return false;
    }

    QJsonObject root = doc.object();

    // Import each section
    if (root.contains("general")) {
        QJsonObject gen = root["general"].toObject();
        if (gen.contains("libraryName")) setLibraryName(gen["libraryName"].toString());
        if (gen.contains("libraryAddress")) setLibraryAddress(gen["libraryAddress"].toString());
        if (gen.contains("libraryPhone")) setLibraryPhone(gen["libraryPhone"].toString());
        if (gen.contains("libraryEmail")) setLibraryEmail(gen["libraryEmail"].toString());
    }

    if (root.contains("circulation")) {
        QJsonObject circ = root["circulation"].toObject();
        if (circ.contains("studentMaxLoanDays")) setStudentMaxLoanDays(circ["studentMaxLoanDays"].toInt());
        if (circ.contains("studentMaxBooksAllowed")) setStudentMaxBooksAllowed(circ["studentMaxBooksAllowed"].toInt());
        if (circ.contains("studentMaxRenewals")) setStudentMaxRenewals(circ["studentMaxRenewals"].toInt());
        if (circ.contains("staffMaxLoanDays")) setStaffMaxLoanDays(circ["staffMaxLoanDays"].toInt());
        if (circ.contains("staffMaxBooksAllowed")) setStaffMaxBooksAllowed(circ["staffMaxBooksAllowed"].toInt());
        if (circ.contains("staffMaxRenewals")) setStaffMaxRenewals(circ["staffMaxRenewals"].toInt());
        if (circ.contains("otherMaxLoanDays")) setOtherMaxLoanDays(circ["otherMaxLoanDays"].toInt());
        if (circ.contains("otherMaxBooksAllowed")) setOtherMaxBooksAllowed(circ["otherMaxBooksAllowed"].toInt());
        if (circ.contains("otherMaxRenewals")) setOtherMaxRenewals(circ["otherMaxRenewals"].toInt());
        if (circ.contains("fineRatePerDay")) setFineRatePerDay(circ["fineRatePerDay"].toDouble());
        if (circ.contains("maxFineAmount")) setMaxFineAmount(circ["maxFineAmount"].toDouble());
        if (circ.contains("currencySymbol")) setCurrencySymbol(circ["currencySymbol"].toString());
    }

    if (root.contains("reservation")) {
        QJsonObject res = root["reservation"].toObject();
        if (res.contains("pickupDays")) setReservationPickupDays(res["pickupDays"].toInt());
        if (res.contains("expiryDays")) setReservationExpiryDays(res["expiryDays"].toInt());
        if (res.contains("maxPerUser")) setMaxReservationsPerUser(res["maxPerUser"].toInt());
    }

    if (root.contains("email")) {
        QJsonObject em = root["email"].toObject();
        if (em.contains("smtpServer")) setSmtpServer(em["smtpServer"].toString());
        if (em.contains("smtpPort")) setSmtpPort(em["smtpPort"].toInt());
        if (em.contains("smtpUsername")) setSmtpUsername(em["smtpUsername"].toString());
        if (em.contains("smtpUseTLS")) setSmtpUseTLS(em["smtpUseTLS"].toBool());
        if (em.contains("senderEmail")) setSenderEmail(em["senderEmail"].toString());
        if (em.contains("senderName")) setSenderName(em["senderName"].toString());
        if (em.contains("notificationsEnabled")) setEmailNotificationsEnabled(em["notificationsEnabled"].toBool());
        if (em.contains("overdueTemplate")) setOverdueEmailTemplate(em["overdueTemplate"].toString());
        if (em.contains("pickupTemplate")) setPickupEmailTemplate(em["pickupTemplate"].toString());
        if (em.contains("welcomeTemplate")) setWelcomeEmailTemplate(em["welcomeTemplate"].toString());
    }

    if (root.contains("system")) {
        QJsonObject sys = root["system"].toObject();
        if (sys.contains("logRetentionDays")) setLogRetentionDays(sys["logRetentionDays"].toInt());
        if (sys.contains("autoBackupEnabled")) setAutoBackupEnabled(sys["autoBackupEnabled"].toBool());
        if (sys.contains("backupIntervalDays")) setBackupIntervalDays(sys["backupIntervalDays"].toInt());
        if (sys.contains("backupLocation")) setBackupLocation(sys["backupLocation"].toString());
    }

    qDebug() << "SettingsManager: Settings imported from" << filePath;
    emit settingsLoaded();
    return true;
}

QVariantMap SettingsManager::getCirculationRulesForRole(const QString &userRole) const
{
    QVariantMap rules;
    QString role = userRole.toLower();

    if (role == "student" || role == "students") {
        rules["maxLoanDays"] = studentMaxLoanDays();
        rules["maxBooks"] = studentMaxBooksAllowed();
        rules["maxRenewals"] = studentMaxRenewals();
    } else if (role == "staff") {
        rules["maxLoanDays"] = staffMaxLoanDays();
        rules["maxBooks"] = staffMaxBooksAllowed();
        rules["maxRenewals"] = staffMaxRenewals();
    } else {
        // Default to "other" for any unrecognized role
        rules["maxLoanDays"] = otherMaxLoanDays();
        rules["maxBooks"] = otherMaxBooksAllowed();
        rules["maxRenewals"] = otherMaxRenewals();
    }

    rules["fineRatePerDay"] = fineRatePerDay();
    rules["maxFineAmount"] = maxFineAmount();
    rules["currencySymbol"] = currencySymbol();

    return rules;
}

// GENERAL SETTINGS - Implementation
QString SettingsManager::applicationTitle() const
{
    return readIniSetting("Bootstrap/ApplicationTitle", Defaults::APPLICATION_TITLE).toString();
}

void SettingsManager::setApplicationTitle(const QString &title)
{
    if (applicationTitle() != title) {
        writeIniSetting("Bootstrap/ApplicationTitle", title);
        emit applicationTitleChanged();
    }
}

QString SettingsManager::databaseFileName() const
{
    return readIniSetting("Bootstrap/DatabaseFileName", Defaults::DATABASE_FILE_NAME).toString();
}

QString SettingsManager::organizationName() const
{
    return readIniSetting("Bootstrap/OrganizationName", Defaults::ORGANIZATION_NAME).toString();
}

void SettingsManager::setOrganizationName(const QString &name)
{
    if (organizationName() != name) {
        writeIniSetting("Bootstrap/OrganizationName", name);
        emit organizationNameChanged();
    }
}

QString SettingsManager::libraryName() const
{
    return readDbSetting("library_name", Defaults::LIBRARY_NAME).toString();
}

void SettingsManager::setLibraryName(const QString &name)
{
    if (libraryName() != name) {
        writeDbSetting("General", "library_name", name, "string");
        emit libraryNameChanged();
    }
}

QString SettingsManager::libraryAddress() const
{
    return readDbSetting("library_address", Defaults::LIBRARY_ADDRESS).toString();
}

void SettingsManager::setLibraryAddress(const QString &address)
{
    if (libraryAddress() != address) {
        writeDbSetting("General", "library_address", address, "string");
        emit libraryAddressChanged();
    }
}

QString SettingsManager::libraryPhone() const
{
    return readDbSetting("library_phone", Defaults::LIBRARY_PHONE).toString();
}

void SettingsManager::setLibraryPhone(const QString &phone)
{
    if (libraryPhone() != phone) {
        writeDbSetting("General", "library_phone", phone, "string");
        emit libraryPhoneChanged();
    }
}

QString SettingsManager::libraryEmail() const
{
    return readDbSetting("library_email", Defaults::LIBRARY_EMAIL).toString();
}

void SettingsManager::setLibraryEmail(const QString &email)
{
    if (libraryEmail() != email) {
        writeDbSetting("General", "library_email", email, "string");
        emit libraryEmailChanged();
    }
}

// CIRCULATION SETTINGS - Student
int SettingsManager::studentMaxLoanDays() const
{
    return readDbSetting("student_max_loan_days", Defaults::STUDENT_MAX_LOAN_DAYS).toInt();
}

void SettingsManager::setStudentMaxLoanDays(int days)
{
    if (studentMaxLoanDays() != days) {
        writeDbSetting("Circulation", "student_max_loan_days", days, "int");
        emit studentMaxLoanDaysChanged();
    }
}

int SettingsManager::studentMaxBooksAllowed() const
{
    return readDbSetting("student_max_books", Defaults::STUDENT_MAX_BOOKS).toInt();
}

void SettingsManager::setStudentMaxBooksAllowed(int count)
{
    if (studentMaxBooksAllowed() != count) {
        writeDbSetting("Circulation", "student_max_books", count, "int");
        emit studentMaxBooksAllowedChanged();
    }
}

int SettingsManager::studentMaxRenewals() const
{
    return readDbSetting("student_max_renewals", Defaults::STUDENT_MAX_RENEWALS).toInt();
}

void SettingsManager::setStudentMaxRenewals(int count)
{
    if (studentMaxRenewals() != count) {
        writeDbSetting("Circulation", "student_max_renewals", count, "int");
        emit studentMaxRenewalsChanged();
    }
}

// CIRCULATION SETTINGS - Staff
int SettingsManager::staffMaxLoanDays() const
{
    return readDbSetting("staff_max_loan_days", Defaults::STAFF_MAX_LOAN_DAYS).toInt();
}

void SettingsManager::setStaffMaxLoanDays(int days)
{
    if (staffMaxLoanDays() != days) {
        writeDbSetting("Circulation", "staff_max_loan_days", days, "int");
        emit staffMaxLoanDaysChanged();
    }
}

int SettingsManager::staffMaxBooksAllowed() const
{
    return readDbSetting("staff_max_books", Defaults::STAFF_MAX_BOOKS).toInt();
}

void SettingsManager::setStaffMaxBooksAllowed(int count)
{
    if (staffMaxBooksAllowed() != count) {
        writeDbSetting("Circulation", "staff_max_books", count, "int");
        emit staffMaxBooksAllowedChanged();
    }
}

int SettingsManager::staffMaxRenewals() const
{
    return readDbSetting("staff_max_renewals", Defaults::STAFF_MAX_RENEWALS).toInt();
}

void SettingsManager::setStaffMaxRenewals(int count)
{
    if (staffMaxRenewals() != count) {
        writeDbSetting("Circulation", "staff_max_renewals", count, "int");
        emit staffMaxRenewalsChanged();
    }
}

// CIRCULATION SETTINGS - Other Users
int SettingsManager::otherMaxLoanDays() const
{
    return readDbSetting("other_max_loan_days", Defaults::OTHER_MAX_LOAN_DAYS).toInt();
}

void SettingsManager::setOtherMaxLoanDays(int days)
{
    if (otherMaxLoanDays() != days) {
        writeDbSetting("Circulation", "other_max_loan_days", days, "int");
        emit otherMaxLoanDaysChanged();
    }
}

int SettingsManager::otherMaxBooksAllowed() const
{
    return readDbSetting("other_max_books", Defaults::OTHER_MAX_BOOKS).toInt();
}

void SettingsManager::setOtherMaxBooksAllowed(int count)
{
    if (otherMaxBooksAllowed() != count) {
        writeDbSetting("Circulation", "other_max_books", count, "int");
        emit otherMaxBooksAllowedChanged();
    }
}

int SettingsManager::otherMaxRenewals() const
{
    return readDbSetting("other_max_renewals", Defaults::OTHER_MAX_RENEWALS).toInt();
}

void SettingsManager::setOtherMaxRenewals(int count)
{
    if (otherMaxRenewals() != count) {
        writeDbSetting("Circulation", "other_max_renewals", count, "int");
        emit otherMaxRenewalsChanged();
    }
}

// CIRCULATION SETTINGS - Fines
double SettingsManager::fineRatePerDay() const
{
    return readDbSetting("fine_rate_per_day", Defaults::FINE_RATE_PER_DAY).toDouble();
}

void SettingsManager::setFineRatePerDay(double rate)
{
    if (qFuzzyCompare(fineRatePerDay(), rate) == false) {
        writeDbSetting("Circulation", "fine_rate_per_day", rate, "double");
        emit fineRatePerDayChanged();
    }
}

double SettingsManager::maxFineAmount() const
{
    return readDbSetting("max_fine_amount", Defaults::MAX_FINE_AMOUNT).toDouble();
}

void SettingsManager::setMaxFineAmount(double amount)
{
    if (qFuzzyCompare(maxFineAmount(), amount) == false) {
        writeDbSetting("Circulation", "max_fine_amount", amount, "double");
        emit maxFineAmountChanged();
    }
}

QString SettingsManager::currencySymbol() const
{
    return readDbSetting("currency_symbol", Defaults::CURRENCY_SYMBOL).toString();
}

void SettingsManager::setCurrencySymbol(const QString &symbol)
{
    if (currencySymbol() != symbol) {
        writeDbSetting("Circulation", "currency_symbol", symbol, "string");
        emit currencySymbolChanged();
    }
}

// RESERVATION SETTINGS
int SettingsManager::reservationPickupDays() const
{
    return readDbSetting("pickup_days", Defaults::RESERVATION_PICKUP_DAYS).toInt();
}

void SettingsManager::setReservationPickupDays(int days)
{
    if (reservationPickupDays() != days) {
        writeDbSetting("Reservation", "pickup_days", days, "int");
        emit reservationPickupDaysChanged();
    }
}

int SettingsManager::reservationExpiryDays() const
{
    return readDbSetting("expiry_days", Defaults::RESERVATION_EXPIRY_DAYS).toInt();
}

void SettingsManager::setReservationExpiryDays(int days)
{
    if (reservationExpiryDays() != days) {
        writeDbSetting("Reservation", "expiry_days", days, "int");
        emit reservationExpiryDaysChanged();
    }
}

int SettingsManager::maxReservationsPerUser() const
{
    return readDbSetting("max_per_user", Defaults::MAX_RESERVATIONS_PER_USER).toInt();
}

void SettingsManager::setMaxReservationsPerUser(int count)
{
    if (maxReservationsPerUser() != count) {
        writeDbSetting("Reservation", "max_per_user", count, "int");
        emit maxReservationsPerUserChanged();
    }
}

// EMAIL SETTINGS
QString SettingsManager::smtpServer() const
{
    return readDbSetting("smtp_server", Defaults::SMTP_SERVER).toString();
}

void SettingsManager::setSmtpServer(const QString &server)
{
    if (smtpServer() != server) {
        writeDbSetting("Email", "smtp_server", server, "string");
        emit smtpServerChanged();
    }
}

int SettingsManager::smtpPort() const
{
    return readDbSetting("smtp_port", Defaults::SMTP_PORT).toInt();
}

void SettingsManager::setSmtpPort(int port)
{
    if (smtpPort() != port) {
        writeDbSetting("Email", "smtp_port", port, "int");
        emit smtpPortChanged();
    }
}

QString SettingsManager::smtpUsername() const
{
    return readDbSetting("smtp_username", Defaults::SMTP_USERNAME).toString();
}

void SettingsManager::setSmtpUsername(const QString &username)
{
    if (smtpUsername() != username) {
        writeDbSetting("Email", "smtp_username", username, "string");
        emit smtpUsernameChanged();
    }
}

QString SettingsManager::smtpPassword() const
{
    return readDbSetting("smtp_password", Defaults::SMTP_PASSWORD).toString();
}

void SettingsManager::setSmtpPassword(const QString &password)
{
    if (smtpPassword() != password) {
        writeDbSetting("Email", "smtp_password", password, "string");
        emit smtpPasswordChanged();
    }
}

bool SettingsManager::smtpUseTLS() const
{
    return readDbSetting("smtp_use_tls", Defaults::SMTP_USE_TLS).toBool();
}

void SettingsManager::setSmtpUseTLS(bool use)
{
    if (smtpUseTLS() != use) {
        writeDbSetting("Email", "smtp_use_tls", use, "bool");
        emit smtpUseTLSChanged();
    }
}

QString SettingsManager::senderEmail() const
{
    return readDbSetting("sender_email", Defaults::SENDER_EMAIL).toString();
}

void SettingsManager::setSenderEmail(const QString &email)
{
    if (senderEmail() != email) {
        writeDbSetting("Email", "sender_email", email, "string");
        emit senderEmailChanged();
    }
}

QString SettingsManager::senderName() const
{
    return readDbSetting("sender_name", Defaults::SENDER_NAME).toString();
}

void SettingsManager::setSenderName(const QString &name)
{
    if (senderName() != name) {
        writeDbSetting("Email", "sender_name", name, "string");
        emit senderNameChanged();
    }
}

bool SettingsManager::emailNotificationsEnabled() const
{
    return readDbSetting("notifications_enabled", Defaults::EMAIL_NOTIFICATIONS_ENABLED).toBool();
}

void SettingsManager::setEmailNotificationsEnabled(bool enabled)
{
    if (emailNotificationsEnabled() != enabled) {
        writeDbSetting("Email", "notifications_enabled", enabled, "bool");
        emit emailNotificationsEnabledChanged();
    }
}

// EMAIL TEMPLATES
QString SettingsManager::overdueEmailTemplate() const
{
    return readDbSetting("overdue_template", Defaults::OVERDUE_EMAIL_TEMPLATE).toString();
}

void SettingsManager::setOverdueEmailTemplate(const QString &templateText)
{
    if (overdueEmailTemplate() != templateText) {
        writeDbSetting("Email", "overdue_template", templateText, "string");
        emit overdueEmailTemplateChanged();
    }
}

QString SettingsManager::pickupEmailTemplate() const
{
    return readDbSetting("pickup_template", Defaults::PICKUP_EMAIL_TEMPLATE).toString();
}

void SettingsManager::setPickupEmailTemplate(const QString &templateText)
{
    if (pickupEmailTemplate() != templateText) {
        writeDbSetting("Email", "pickup_template", templateText, "string");
        emit pickupEmailTemplateChanged();
    }
}

QString SettingsManager::welcomeEmailTemplate() const
{
    return readDbSetting("welcome_template", Defaults::WELCOME_EMAIL_TEMPLATE).toString();
}

void SettingsManager::setWelcomeEmailTemplate(const QString &templateText)
{
    if (welcomeEmailTemplate() != templateText) {
        writeDbSetting("Email", "welcome_template", templateText, "string");
        emit welcomeEmailTemplateChanged();
    }
}

// SYSTEM SETTINGS
int SettingsManager::logRetentionDays() const
{
    return readDbSetting("log_retention_days", Defaults::LOG_RETENTION_DAYS).toInt();
}

void SettingsManager::setLogRetentionDays(int days)
{
    if (logRetentionDays() != days) {
        writeDbSetting("System", "log_retention_days", days, "int");
        emit logRetentionDaysChanged();
    }
}

bool SettingsManager::autoBackupEnabled() const
{
    return readDbSetting("auto_backup_enabled", Defaults::AUTO_BACKUP_ENABLED).toBool();
}

void SettingsManager::setAutoBackupEnabled(bool enabled)
{
    if (autoBackupEnabled() != enabled) {
        writeDbSetting("System", "auto_backup_enabled", enabled, "bool");
        emit autoBackupEnabledChanged();
    }
}

int SettingsManager::backupIntervalDays() const
{
    return readDbSetting("backup_interval_days", Defaults::BACKUP_INTERVAL_DAYS).toInt();
}

void SettingsManager::setBackupIntervalDays(int days)
{
    if (backupIntervalDays() != days) {
        writeDbSetting("System", "backup_interval_days", days, "int");
        emit backupIntervalDaysChanged();
    }
}

QString SettingsManager::backupLocation() const
{
    return readDbSetting("backup_location", Defaults::BACKUP_LOCATION).toString();
}

void SettingsManager::setBackupLocation(const QString &location)
{
    if (backupLocation() != location) {
        writeDbSetting("System", "backup_location", location, "string");
        emit backupLocationChanged();
    }
}
