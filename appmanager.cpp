#include "appmanager.h"
#include <QDebug>
#include <QCoreApplication>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QUrlQuery>

// Initialize static members
AppManager* AppManager::m_instance = nullptr;
QMutex AppManager::m_mutex;

AppManager::AppManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_validationTimer(new QTimer(this))
    , m_licenseStatus("not_activated")
    , m_licenseTier("")
    , m_isValidating(false)
    , m_currentAdminId(0)
    , m_currentAdminIsSuperAdmin(false)
{
    // Get database connection
    m_db = DatabaseManager::getConnection();

    // Create tables if needed
    createTables();

    // Load license from database
    loadLicenseFromDatabase();

    // Set up periodic validation timer (24 hours)
    connect(m_validationTimer, &QTimer::timeout, this, &AppManager::onValidationTimerTimeout);
    m_validationTimer->setInterval(VALIDATION_INTERVAL_MS);

    // Connect network manager
    connect(m_networkManager, &QNetworkAccessManager::finished, this, &AppManager::onNetworkReplyFinished);

    // API base URL - configure this to your Libro portal
    m_apiBaseUrl = "http://localhost:8000/api/v1"; //"https://libro.yourdomain.com/api/v1";

    // Start validation timer if activated
    if (isActivated()) {
        m_validationTimer->start();
    }
}

AppManager::~AppManager()
{
    m_validationTimer->stop();
}

AppManager* AppManager::instance()
{
    QMutexLocker locker(&m_mutex);
    if (!m_instance) {
        m_instance = new AppManager(QCoreApplication::instance());
    }
    return m_instance;
}

// ==================== LICENSE GETTERS ====================

QString AppManager::licenseStatus() const
{
    return m_licenseStatus;
}

bool AppManager::isActivated() const
{
    return !m_organizationId.isEmpty() && !m_licenseKey.isEmpty();
}

bool AppManager::isLicenseValid() const
{
    // Valid if trial, active, or grace_period
    return m_licenseStatus == "trial" ||
           m_licenseStatus == "active" ||
           m_licenseStatus == "grace_period";
}

bool AppManager::isBlocked() const
{
    return m_licenseStatus == "blocked";
}

bool AppManager::isGracePeriod() const
{
    return m_licenseStatus == "grace_period";
}

int AppManager::graceDaysRemaining() const
{
    if (!isGracePeriod()) return 0;

    int daysSinceExpiry = m_expiryDate.daysTo(QDate::currentDate());
    int remaining = GRACE_PERIOD_DAYS - daysSinceExpiry;
    return qMax(0, remaining);
}

QString AppManager::licenseTier() const
{
    return m_licenseTier;
}

QDate AppManager::expiryDate() const
{
    return m_expiryDate;
}

int AppManager::daysRemaining() const
{
    if (!m_expiryDate.isValid()) return 0;
    int days = QDate::currentDate().daysTo(m_expiryDate);
    return qMax(0, days);
}

QString AppManager::lastValidationTime() const
{
    if (!m_lastValidation.isValid()) return "Never";
    return m_lastValidation.toString("MMM dd, yyyy 'at' hh:mm AP");
}

bool AppManager::isValidating() const
{
    return m_isValidating;
}

// ==================== ORGANIZATION GETTERS ====================

QString AppManager::organizationId() const
{
    return m_organizationId;
}

QString AppManager::organizationName() const
{
    return m_organizationName;
}

QString AppManager::organizationLocation() const
{
    return m_organizationLocation;
}

QString AppManager::organizationAddress() const
{
    return m_organizationAddress;
}

QString AppManager::organizationPhone() const
{
    return m_organizationPhone;
}

QString AppManager::organizationEmail() const
{
    return m_organizationEmail;
}

// ==================== ADMIN GETTERS ====================

bool AppManager::hasAdminSetup() const
{
    QSqlQuery query(m_db);
    query.prepare("SELECT COUNT(*) FROM admins WHERE is_active = 1");
    if (query.exec() && query.next()) {
        return query.value(0).toInt() > 0;
    }
    return false;
}

bool AppManager::isAdminLoggedIn() const
{
    return m_currentAdminId > 0;
}

int AppManager::currentAdminId() const
{
    return m_currentAdminId;
}

QString AppManager::currentAdminName() const
{
    return m_currentAdminName;
}

QString AppManager::currentAdminUsername() const
{
    return m_currentAdminUsername;
}

bool AppManager::currentAdminIsSuperAdmin() const
{
    return m_currentAdminIsSuperAdmin;
}

// ==================== LICENSE METHODS ====================

void AppManager::activateLicense(const QString &orgId, const QString &licenseKey)
{
    if (orgId.trimmed().isEmpty() || licenseKey.trimmed().isEmpty()) {
        emit activationFailed("Organization ID and License Key are required");
        return;
    }

    m_isValidating = true;
    emit validatingChanged();

    // Build request  http://localhost:8000/api/v1/license/activate
    QNetworkRequest request(QUrl(buildApiUrl("/license/activate")));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Libro Desktop v1.0");

    QJsonObject body;
    body["organization_id"] = orgId.trimmed();
    body["license_key"] = licenseKey.trimmed();

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(body).toJson());
    m_pendingRequests[reply] = ActivationRequest;

    // Store temporarily for use in response handler
    m_organizationId = orgId.trimmed();
    m_licenseKey = licenseKey.trimmed();

    // Set timeout
    QTimer::singleShot(NETWORK_TIMEOUT_MS, reply, [reply]() {
        if (reply->isRunning()) {
            reply->abort();
        }
    });
}

void AppManager::validateLicense()
{
    if (!isActivated()) {
        m_licenseStatus = "not_activated";
        emit licenseStatusChanged();
        return;
    }

    m_isValidating = true;
    emit validatingChanged();

    // Build request
    QNetworkRequest request(QUrl(buildApiUrl("/license/validate")));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Libro Desktop v1.0");

    QJsonObject body;
    body["organization_id"] = m_organizationId;
    body["license_key"] = m_licenseKey;

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(body).toJson());
    m_pendingRequests[reply] = ValidationRequest;

    // Set timeout
    QTimer::singleShot(NETWORK_TIMEOUT_MS, reply, [this, reply]() {
        if (reply->isRunning()) {
            reply->abort();
            // Fall back to offline validation
            updateLicenseStatus();
            logValidation("startup", false, m_licenseStatus, QString(), "Network timeout - using cached data");
        }
    });
}

void AppManager::manualValidation()
{
    validateLicense();
}

QVariantMap AppManager::getLicenseDetails() const
{
    QVariantMap details;
    details["status"] = m_licenseStatus;
    details["organizationId"] = m_organizationId;
    details["organizationName"] = m_organizationName;
    details["organizationLocation"] = m_organizationLocation;
    details["organizationAddress"] = m_organizationAddress;
    details["organizationPhone"] = m_organizationPhone;
    details["organizationEmail"] = m_organizationEmail;
    details["tier"] = m_licenseTier;
    details["activationDate"] = m_activationDate.toString("MMM dd, yyyy");
    details["expiryDate"] = m_expiryDate.toString("MMM dd, yyyy");
    details["daysRemaining"] = daysRemaining();
    details["lastValidation"] = lastValidationTime();
    details["isGracePeriod"] = isGracePeriod();
    details["graceDaysRemaining"] = graceDaysRemaining();
    return details;
}

QVariantList AppManager::getValidationLogs(int limit) const
{
    QVariantList logs;
    QSqlQuery query(m_db);
    query.prepare(
        "SELECT validation_type, was_online, validation_result, error_message, "
        "days_until_expiry, timestamp FROM license_validation_log "
        "ORDER BY timestamp DESC LIMIT :limit"
        );
    query.bindValue(":limit", limit);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap log;
            log["type"] = query.value("validation_type").toString();
            log["wasOnline"] = query.value("was_online").toBool();
            log["result"] = query.value("validation_result").toString();
            log["error"] = query.value("error_message").toString();
            log["daysUntilExpiry"] = query.value("days_until_expiry").toInt();
            log["timestamp"] = query.value("timestamp").toDateTime().toString("MMM dd, yyyy hh:mm AP");
            logs.append(log);
        }
    }
    return logs;
}

// ==================== ADMIN METHODS ====================

bool AppManager::setupFirstAdmin(
    const QString &firstName,
    const QString &lastName,
    const QString &email,
    const QString &phone,
    const QString &staffNo,
    const QString &department,
    const QString &username,
    const QString &password)
{
    // Validate inputs
    if (firstName.trimmed().isEmpty() || lastName.trimmed().isEmpty() ||
        email.trimmed().isEmpty() || staffNo.trimmed().isEmpty() ||
        department.trimmed().isEmpty() || username.trimmed().isEmpty() ||
        password.isEmpty()) {
        emit errorOccurred("All required fields must be filled");
        return false;
    }

    // Check if admin already exists
    if (hasAdminSetup()) {
        emit errorOccurred("Admin account already exists");
        return false;
    }

    // Check username availability
    if (!isUsernameAvailable(username)) {
        emit errorOccurred("Username already taken");
        return false;
    }

    QSqlQuery query(m_db);

    // Start transaction
    if (!query.exec("BEGIN TRANSACTION")) {
        emit errorOccurred("Failed to start transaction");
        return false;
    }

    // 1. Insert into users table
    query.prepare(
        "INSERT INTO users (first_name, second_name, email, phone, user_role) "
        "VALUES (:firstName, :lastName, :email, :phone, 'Staff')"
        );
    query.bindValue(":firstName", firstName.trimmed());
    query.bindValue(":lastName", lastName.trimmed());
    query.bindValue(":email", email.trimmed());
    query.bindValue(":phone", phone.trimmed());

    if (!query.exec()) {
        qWarning() << "Failed to insert user:" << query.lastError().text();
        query.exec("ROLLBACK");
        emit errorOccurred("Failed to create user account: " + query.lastError().text());
        return false;
    }

    int userId = query.lastInsertId().toInt();

    // 2. Insert into staff table
    query.prepare(
        "INSERT INTO staff (staff_id, staff_no, department, start_year, category) "
        "VALUES (:staffId, :staffNo, :department, :startYear, 'Administrator')"
        );
    query.bindValue(":staffId", userId);
    query.bindValue(":staffNo", staffNo.trimmed());
    query.bindValue(":department", department.trimmed());
    query.bindValue(":startYear", QDate::currentDate().year());

    if (!query.exec()) {
        qWarning() << "Failed to insert staff:" << query.lastError().text();
        query.exec("ROLLBACK");
        emit errorOccurred("Failed to create staff record: " + query.lastError().text());
        return false;
    }

    // 3. Insert into admins table (first admin is super_admin)
    QString passwordHash = hashPassword(password);
    QString adminName = firstName.trimmed() + " " + lastName.trimmed();

    query.prepare(
        "INSERT INTO admins (user_id, staff_id, username, password, admin_name, email, phone, is_super_admin, is_active) "
        "VALUES (:userId, :staffId, :username, :password, :adminName, :email, :phone, 1, 1)"
        );
    query.bindValue(":userId", userId);
    query.bindValue(":staffId", userId);
    query.bindValue(":username", username.trimmed());
    query.bindValue(":password", passwordHash);
    query.bindValue(":adminName", adminName);
    query.bindValue(":email", email.trimmed());
    query.bindValue(":phone", phone.trimmed());

    if (!query.exec()) {
        qWarning() << "Failed to insert admin:" << query.lastError().text();
        query.exec("ROLLBACK");
        emit errorOccurred("Failed to create admin account: " + query.lastError().text());
        return false;
    }

    // Commit transaction
    if (!query.exec("COMMIT")) {
        emit errorOccurred("Failed to commit transaction");
        return false;
    }

    qDebug() << "First admin created successfully:" << username;
    emit adminStateChanged();

    // Auto-login the newly created admin
    return adminLogin(username, password);
}

bool AppManager::adminLogin(const QString &username, const QString &password)
{
    if (username.trimmed().isEmpty() || password.isEmpty()) {
        emit errorOccurred("Username and password are required");
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(
        "SELECT admin_id, admin_name, username, password, is_super_admin "
        "FROM admins WHERE username = :username AND is_active = 1"
        );
    query.bindValue(":username", username.trimmed());

    if (!query.exec()) {
        emit errorOccurred("Database error during login");
        return false;
    }

    if (!query.next()) {
        emit errorOccurred("Invalid username or password");
        return false;
    }

    QString storedHash = query.value("password").toString();
    if (!verifyPassword(password, storedHash)) {
        emit errorOccurred("Invalid username or password");
        return false;
    }

    // Login successful
    m_currentAdminId = query.value("admin_id").toInt();
    m_currentAdminName = query.value("admin_name").toString();
    m_currentAdminUsername = query.value("username").toString();
    m_currentAdminIsSuperAdmin = query.value("is_super_admin").toBool();

    // Update last login timestamp
    QSqlQuery updateQuery(m_db);
    updateQuery.prepare("UPDATE admins SET last_login = datetime('now') WHERE admin_id = :adminId");
    updateQuery.bindValue(":adminId", m_currentAdminId);
    updateQuery.exec();

    qDebug() << "Admin logged in:" << m_currentAdminUsername;
    emit adminStateChanged();
    return true;
}

void AppManager::adminLogout()
{
    m_currentAdminId = 0;
    m_currentAdminName = "";
    m_currentAdminUsername = "";
    m_currentAdminIsSuperAdmin = false;
    emit adminStateChanged();
    qDebug() << "Admin logged out";
}

bool AppManager::addAdmin(int staffId, const QString &username, const QString &password)
{
    if (staffId <= 0 || username.trimmed().isEmpty() || password.isEmpty()) {
        emit errorOccurred("Invalid parameters for adding admin");
        return false;
    }

    // Check if currently logged in as admin
    if (!isAdminLoggedIn()) {
        emit errorOccurred("You must be logged in as admin to add new admins");
        return false;
    }

    // Check username availability
    if (!isUsernameAvailable(username)) {
        emit errorOccurred("Username already taken");
        return false;
    }

    // Get staff details
    QSqlQuery staffQuery(m_db);
    staffQuery.prepare(
        "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone "
        "FROM users u INNER JOIN staff s ON u.user_id = s.staff_id "
        "WHERE s.staff_id = :staffId"
        );
    staffQuery.bindValue(":staffId", staffId);

    if (!staffQuery.exec() || !staffQuery.next()) {
        emit errorOccurred("Staff member not found");
        return false;
    }

    int userId = staffQuery.value("user_id").toInt();
    QString adminName = staffQuery.value("first_name").toString() + " " + staffQuery.value("second_name").toString();
    QString email = staffQuery.value("email").toString();
    QString phone = staffQuery.value("phone").toString();

    // Check if staff is already an admin
    QSqlQuery checkQuery(m_db);
    checkQuery.prepare("SELECT admin_id FROM admins WHERE staff_id = :staffId");
    checkQuery.bindValue(":staffId", staffId);
    if (checkQuery.exec() && checkQuery.next()) {
        emit errorOccurred("This staff member is already an admin");
        return false;
    }

    // Insert new admin
    QString passwordHash = hashPassword(password);
    QSqlQuery insertQuery(m_db);
    insertQuery.prepare(
        "INSERT INTO admins (user_id, staff_id, username, password, admin_name, email, phone, is_super_admin, is_active, created_by) "
        "VALUES (:userId, :staffId, :username, :password, :adminName, :email, :phone, 0, 1, :createdBy)"
        );
    insertQuery.bindValue(":userId", userId);
    insertQuery.bindValue(":staffId", staffId);
    insertQuery.bindValue(":username", username.trimmed());
    insertQuery.bindValue(":password", passwordHash);
    insertQuery.bindValue(":adminName", adminName);
    insertQuery.bindValue(":email", email);
    insertQuery.bindValue(":phone", phone);
    insertQuery.bindValue(":createdBy", m_currentAdminId);

    if (!insertQuery.exec()) {
        emit errorOccurred("Failed to create admin: " + insertQuery.lastError().text());
        return false;
    }

    qDebug() << "New admin added:" << username;
    emit adminStateChanged();
    return true;
}

bool AppManager::changeAdminPassword(int adminId, const QString &oldPassword, const QString &newPassword)
{
    if (adminId <= 0 || oldPassword.isEmpty() || newPassword.isEmpty()) {
        emit errorOccurred("Invalid parameters");
        return false;
    }

    if (newPassword.length() < 6) {
        emit errorOccurred("Password must be at least 6 characters");
        return false;
    }

    // Get current password hash
    QSqlQuery query(m_db);
    query.prepare("SELECT password FROM admins WHERE admin_id = :adminId");
    query.bindValue(":adminId", adminId);

    if (!query.exec() || !query.next()) {
        emit errorOccurred("Admin not found");
        return false;
    }

    QString storedHash = query.value("password").toString();
    if (!verifyPassword(oldPassword, storedHash)) {
        emit errorOccurred("Current password is incorrect");
        return false;
    }

    // Update password
    QString newHash = hashPassword(newPassword);
    QSqlQuery updateQuery(m_db);
    updateQuery.prepare("UPDATE admins SET password = :password, updated_at = datetime('now') WHERE admin_id = :adminId");
    updateQuery.bindValue(":password", newHash);
    updateQuery.bindValue(":adminId", adminId);

    if (!updateQuery.exec()) {
        emit errorOccurred("Failed to update password");
        return false;
    }

    qDebug() << "Password changed for admin ID:" << adminId;
    return true;
}

bool AppManager::deactivateAdmin(int adminId)
{
    if (adminId <= 0) {
        emit errorOccurred("Invalid admin ID");
        return false;
    }

    // Cannot deactivate yourself
    if (adminId == m_currentAdminId) {
        emit errorOccurred("You cannot deactivate your own account");
        return false;
    }

    // Check if this is the last active super_admin
    QSqlQuery countQuery(m_db);
    countQuery.prepare("SELECT COUNT(*) FROM admins WHERE is_super_admin = 1 AND is_active = 1");
    countQuery.exec();
    countQuery.next();
    int superAdminCount = countQuery.value(0).toInt();

    QSqlQuery checkQuery(m_db);
    checkQuery.prepare("SELECT is_super_admin FROM admins WHERE admin_id = :adminId");
    checkQuery.bindValue(":adminId", adminId);
    checkQuery.exec();
    checkQuery.next();
    bool isSuperAdmin = checkQuery.value(0).toBool();

    if (isSuperAdmin && superAdminCount <= 1) {
        emit errorOccurred("Cannot deactivate the last super admin");
        return false;
    }

    QSqlQuery updateQuery(m_db);
    updateQuery.prepare("UPDATE admins SET is_active = 0, updated_at = datetime('now') WHERE admin_id = :adminId");
    updateQuery.bindValue(":adminId", adminId);

    if (!updateQuery.exec()) {
        emit errorOccurred("Failed to deactivate admin");
        return false;
    }

    emit adminStateChanged();
    return true;
}

bool AppManager::reactivateAdmin(int adminId)
{
    if (adminId <= 0) {
        emit errorOccurred("Invalid admin ID");
        return false;
    }

    QSqlQuery updateQuery(m_db);
    updateQuery.prepare("UPDATE admins SET is_active = 1, updated_at = datetime('now') WHERE admin_id = :adminId");
    updateQuery.bindValue(":adminId", adminId);

    if (!updateQuery.exec()) {
        emit errorOccurred("Failed to reactivate admin");
        return false;
    }

    emit adminStateChanged();
    return true;
}

QVariantList AppManager::getAllAdmins() const
{
    QVariantList admins;
    QSqlQuery query(m_db);
    query.prepare(
        "SELECT a.admin_id, a.username, a.admin_name, a.email, a.is_super_admin, a.is_active, "
        "a.last_login, a.created_at, s.staff_no, s.department "
        "FROM admins a "
        "LEFT JOIN staff s ON a.staff_id = s.staff_id "
        "ORDER BY a.is_super_admin DESC, a.admin_name ASC"
        );

    if (query.exec()) {
        while (query.next()) {
            QVariantMap admin;
            admin["adminId"] = query.value("admin_id").toInt();
            admin["username"] = query.value("username").toString();
            admin["adminName"] = query.value("admin_name").toString();
            admin["email"] = query.value("email").toString();
            admin["isSuperAdmin"] = query.value("is_super_admin").toBool();
            admin["isActive"] = query.value("is_active").toBool();
            admin["lastLogin"] = query.value("last_login").toDateTime().toString("MMM dd, yyyy hh:mm AP");
            admin["createdAt"] = query.value("created_at").toDateTime().toString("MMM dd, yyyy");
            admin["staffNo"] = query.value("staff_no").toString();
            admin["department"] = query.value("department").toString();
            admins.append(admin);
        }
    }
    return admins;
}

QVariantList AppManager::getStaffNotAdmins() const
{
    QVariantList staffList;
    QSqlQuery query(m_db);
    query.prepare(
        "SELECT u.user_id, u.first_name, u.second_name, u.email, s.staff_id, s.staff_no, s.department "
        "FROM users u "
        "INNER JOIN staff s ON u.user_id = s.staff_id "
        "WHERE u.status = 'Active' AND s.staff_id NOT IN (SELECT staff_id FROM admins WHERE staff_id IS NOT NULL) "
        "ORDER BY u.first_name, u.second_name"
        );

    if (query.exec()) {
        while (query.next()) {
            QVariantMap staff;
            staff["staffId"] = query.value("staff_id").toInt();
            staff["fullName"] = query.value("first_name").toString() + " " + query.value("second_name").toString();
            staff["email"] = query.value("email").toString();
            staff["staffNo"] = query.value("staff_no").toString();
            staff["department"] = query.value("department").toString();
            staffList.append(staff);
        }
    }
    return staffList;
}

bool AppManager::isUsernameAvailable(const QString &username) const
{
    QSqlQuery query(m_db);
    query.prepare("SELECT COUNT(*) FROM admins WHERE LOWER(username) = LOWER(:username)");
    query.bindValue(":username", username.trimmed());
    if (query.exec() && query.next()) {
        return query.value(0).toInt() == 0;
    }
    return false;
}

// ==================== PASSWORD UTILITIES ====================

QString AppManager::hashPassword(const QString &password)
{
    // Generate 16-byte random salt
    QByteArray salt;
    salt.resize(16);
    QRandomGenerator::global()->fillRange(reinterpret_cast<quint32*>(salt.data()), 4);

    // Combine salt + password and hash with SHA-256
    QByteArray saltedPassword = salt + password.toUtf8();
    QByteArray hash = QCryptographicHash::hash(saltedPassword, QCryptographicHash::Sha256);

    // Store as: salt$hash (both hex encoded)
    return salt.toHex() + "$" + hash.toHex();
}

bool AppManager::verifyPassword(const QString &password, const QString &storedHash)
{
    QStringList parts = storedHash.split("$");
    if (parts.size() != 2) return false;

    QByteArray salt = QByteArray::fromHex(parts[0].toUtf8());
    QByteArray expectedHash = QByteArray::fromHex(parts[1].toUtf8());

    QByteArray saltedPassword = salt + password.toUtf8();
    QByteArray actualHash = QCryptographicHash::hash(saltedPassword, QCryptographicHash::Sha256);

    return actualHash == expectedHash;
}

// ==================== PRIVATE SLOTS ====================

void AppManager::onValidationTimerTimeout()
{
    qDebug() << "Periodic license validation triggered";
    validateLicense();
}

void AppManager::onNetworkReplyFinished(QNetworkReply *reply)
{
    m_isValidating = false;
    emit validatingChanged();

    if (!m_pendingRequests.contains(reply)) {
        reply->deleteLater();
        return;
    }

    RequestType requestType = m_pendingRequests.take(reply);

    if (reply->error() != QNetworkReply::NoError) {
        handleNetworkError(reply, requestType == ActivationRequest ? "Activation" : "Validation");
        reply->deleteLater();
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
    QJsonObject response = jsonDoc.object();

    if (requestType == ActivationRequest) {
        handleActivationResponse(response);
    } else {
        handleValidationResponse(response);
    }

    reply->deleteLater();
}

// ==================== PRIVATE METHODS ====================

bool AppManager::createTables()
{
    QSqlQuery query(m_db);

    // Create license_info table (single row enforced)
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS license_info ("
            "id INTEGER PRIMARY KEY CHECK (id = 1),"
            "organization_id TEXT NOT NULL,"
            "license_key TEXT NOT NULL,"
            "organization_name TEXT NOT NULL,"
            "organization_location TEXT,"
            "organization_address TEXT,"
            "organization_phone TEXT,"
            "organization_email TEXT,"
            "license_tier TEXT NOT NULL,"
            "activation_date DATETIME NOT NULL,"
            "expiry_date DATETIME NOT NULL,"
            "last_online_validation DATETIME,"
            "last_validation_status TEXT,"
            "is_active INTEGER DEFAULT 1,"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP,"
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP"
            ")")) {
        qWarning() << "Error creating license_info table:" << query.lastError().text();
        return false;
    }

    // Create license_validation_log table
    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS license_validation_log ("
            "log_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "validation_type TEXT NOT NULL,"
            "was_online INTEGER NOT NULL,"
            "validation_result TEXT NOT NULL,"
            "server_response TEXT,"
            "error_message TEXT,"
            "days_until_expiry INTEGER,"
            "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP"
            ")")) {
        qWarning() << "Error creating license_validation_log table:" << query.lastError().text();
        return false;
    }

    return true;
}

bool AppManager::loadLicenseFromDatabase()
{
    QSqlQuery query(m_db);
    query.prepare("SELECT * FROM license_info WHERE id = 1");

    if (!query.exec() || !query.next()) {
        m_licenseStatus = "not_activated";
        return false;
    }

    m_organizationId = query.value("organization_id").toString();
    m_licenseKey = query.value("license_key").toString();
    m_organizationName = query.value("organization_name").toString();
    m_organizationLocation = query.value("organization_location").toString();
    m_organizationAddress = query.value("organization_address").toString();
    m_organizationPhone = query.value("organization_phone").toString();
    m_organizationEmail = query.value("organization_email").toString();
    m_licenseTier = query.value("license_tier").toString();
    m_activationDate = query.value("activation_date").toDate();
    m_expiryDate = query.value("expiry_date").toDate();
    m_lastValidation = query.value("last_online_validation").toDateTime();
    m_lastValidationStatus = query.value("last_validation_status").toString();

    updateLicenseStatus();
    emit licenseStatusChanged();
    emit organizationChanged();

    return true;
}

bool AppManager::saveLicenseToDatabase()
{
    QSqlQuery query(m_db);

    // Use INSERT OR REPLACE to handle single-row constraint
    query.prepare(
        "INSERT OR REPLACE INTO license_info "
        "(id, organization_id, license_key, organization_name, organization_location, "
        "organization_address, organization_phone, organization_email, license_tier, "
        "activation_date, expiry_date, last_online_validation, last_validation_status, "
        "is_active, updated_at) "
        "VALUES (1, :orgId, :licenseKey, :orgName, :orgLocation, :orgAddress, :orgPhone, "
        ":orgEmail, :tier, :activationDate, :expiryDate, :lastValidation, :lastStatus, 1, datetime('now'))"
        );

    query.bindValue(":orgId", m_organizationId);
    query.bindValue(":licenseKey", m_licenseKey);
    query.bindValue(":orgName", m_organizationName);
    query.bindValue(":orgLocation", m_organizationLocation);
    query.bindValue(":orgAddress", m_organizationAddress);
    query.bindValue(":orgPhone", m_organizationPhone);
    query.bindValue(":orgEmail", m_organizationEmail);
    query.bindValue(":tier", m_licenseTier);
    query.bindValue(":activationDate", m_activationDate);
    query.bindValue(":expiryDate", m_expiryDate);
    query.bindValue(":lastValidation", m_lastValidation);
    query.bindValue(":lastStatus", m_lastValidationStatus);

    if (!query.exec()) {
        qWarning() << "Failed to save license info:" << query.lastError().text();
        return false;
    }

    return true;
}

void AppManager::updateLicenseStatus()
{
    if (!isActivated()) {
        m_licenseStatus = "not_activated";
        return;
    }

    QDate today = QDate::currentDate();
    int daysSinceExpiry = m_expiryDate.daysTo(today);

    if (daysSinceExpiry < 0) {
        // Not expired yet
        if (m_licenseTier == "trial") {
            m_licenseStatus = "trial";
        } else {
            m_licenseStatus = "active";
        }
    } else if (daysSinceExpiry <= GRACE_PERIOD_DAYS) {
        // In grace period
        m_licenseStatus = "grace_period";
    } else {
        // Grace period exceeded
        m_licenseStatus = "blocked";
    }
}

void AppManager::logValidation(const QString &type, bool wasOnline, const QString &result,
                               const QString &serverResponse, const QString &errorMessage)
{
    QSqlQuery query(m_db);
    query.prepare(
        "INSERT INTO license_validation_log "
        "(validation_type, was_online, validation_result, server_response, error_message, days_until_expiry) "
        "VALUES (:type, :wasOnline, :result, :response, :error, :days)"
        );
    query.bindValue(":type", type);
    query.bindValue(":wasOnline", wasOnline ? 1 : 0);
    query.bindValue(":result", result);
    query.bindValue(":response", serverResponse);
    query.bindValue(":error", errorMessage);
    query.bindValue(":days", daysRemaining());
    query.exec();
}

QString AppManager::buildApiUrl(const QString &endpoint) const
{
    return m_apiBaseUrl + endpoint;
}

void AppManager::handleActivationResponse(const QJsonObject &response)
{
    if (!response["success"].toBool()) {
        QString error = response["error"].toString("Activation failed");
        m_organizationId.clear();
        m_licenseKey.clear();
        emit activationFailed(error);
        logValidation("activation", true, "failed", QJsonDocument(response).toJson(), error);
        return;
    }

    // Extract organization info
    QJsonObject org = response["organization"].toObject();
    m_organizationName = org["name"].toString();
    m_organizationLocation = org["location"].toString();
    m_organizationAddress = org["address"].toString();
    m_organizationPhone = org["phone"].toString();
    m_organizationEmail = org["email"].toString();

    // Extract license info
    QJsonObject license = response["license"].toObject();
    m_licenseTier = license["tier"].toString();
    m_activationDate = QDate::fromString(license["activation_date"].toString(), "yyyy-MM-dd");
    m_expiryDate = QDate::fromString(license["expiry_date"].toString(), "yyyy-MM-dd");

    m_lastValidation = QDateTime::currentDateTime();
    m_lastValidationStatus = "valid";

    // Save to database
    saveLicenseToDatabase();
    updateLicenseStatus();

    // Start validation timer
    m_validationTimer->start();

    emit licenseStatusChanged();
    emit organizationChanged();
    emit activationSucceeded();

    logValidation("activation", true, "success", QJsonDocument(response).toJson());
    qDebug() << "License activated successfully for:" << m_organizationName;
}

void AppManager::handleValidationResponse(const QJsonObject &response)
{
    if (response["valid"].toBool()) {
        // Update expiry date from server (in case of renewal)
        QString newExpiry = response["expiry_date"].toString();
        if (!newExpiry.isEmpty()) {
            m_expiryDate = QDate::fromString(newExpiry, "yyyy-MM-dd");
        }

        QString newTier = response["tier"].toString();
        if (!newTier.isEmpty()) {
            m_licenseTier = newTier;
        }

        m_lastValidation = QDateTime::currentDateTime();
        m_lastValidationStatus = "valid";

        saveLicenseToDatabase();
        updateLicenseStatus();

        emit licenseStatusChanged();
        emit validationCompleted(true, "License validated successfully");
        logValidation("periodic", true, m_licenseStatus, QJsonDocument(response).toJson());
    } else {
        // License invalid from server
        QString error = response["error"].toString("License validation failed");
        m_lastValidation = QDateTime::currentDateTime();
        m_lastValidationStatus = "invalid";

        saveLicenseToDatabase();
        updateLicenseStatus();

        emit licenseStatusChanged();
        emit validationCompleted(false, error);
        logValidation("periodic", true, "invalid", QJsonDocument(response).toJson(), error);
    }
}

void AppManager::handleNetworkError(QNetworkReply *reply, const QString &context)
{
    QString errorMsg = reply->errorString();
    qWarning() << context << "network error:" << errorMsg;

    if (context == "Activation") {
        m_organizationId.clear();
        m_licenseKey.clear();
        emit activationFailed("Network error: " + errorMsg);
        logValidation("activation", false, "network_error", QString(), errorMsg);
    } else {
        // Validation failed - fall back to offline check
        updateLicenseStatus();
        emit validationCompleted(false, "Offline mode - using cached license data");
        logValidation("periodic", false, m_licenseStatus, QString(), "Network error - offline validation");
    }

    emit networkError(errorMsg);
}
