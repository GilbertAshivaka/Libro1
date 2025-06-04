#include "userimporter.h"
#include <QtConcurrent>
#include <QUrl>
#include <QDebug>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>

UserImporter::UserImporter(QObject *parent)
    : QObject{parent}
    , watcher(new QFutureWatcher<ImportResult>(this))
{
    connect(watcher, &QFutureWatcher<ImportResult>::finished, this, &UserImporter::handleImportCompleted);
}

UserImporter::~UserImporter()
{
    if (watcher->isRunning()) {
        watcher->cancel();
        watcher->waitForFinished();
    }
}

QString UserImporter::userRole()
{
    return m_userRole;
}

void UserImporter::setUserRole(QString &newUserRole)
{
    m_userRole = newUserRole;
    emit userRoleChanged();
    qDebug() << "UserRole changed: " + m_userRole;
}

void UserImporter::startImport(const QString &filePath)
{
    auto future = QtConcurrent::run([this, filePath]() {
        return processImport(filePath,
                             [this](int progress) {
                                 emit importProgress(progress);
                             });
    });

    watcher->setFuture(future);
}

QString UserImporter::urlToLocalFile(const QString &url)
{
    return QUrl(url).toLocalFile();
}

void UserImporter::setRole(QString role)
{
    setUserRole(role);
}

void UserImporter::handleImportCompleted()
{
    ImportResult result = watcher->result();
    emit importCompleted(result.successCount, result.failCount);

    if (!result.errors.isEmpty()) {
        emit importError(result.errors.join("\n"));
    }
}

void UserImporter::parseHeaders(const QString& headerLine, QStringList& headers)
{
    headers = headerLine.split(",");
    for (QString& header : headers) {
        header = header.trimmed();
    }
}

QString UserImporter::detectUserType(const QStringList& headers)
{
    bool hasAdmissionNo = headers.contains("Admission No", Qt::CaseInsensitive);
    bool hasStaffNo = headers.contains("Staff No", Qt::CaseInsensitive);
    bool hasUserNo = headers.contains("User No", Qt::CaseInsensitive);

    bool hasLevel = headers.contains("Level", Qt::CaseInsensitive);
    bool hasCategory = headers.contains("Category", Qt::CaseInsensitive);
    bool hasGender = headers.contains("Gender", Qt::CaseInsensitive);

    if (hasAdmissionNo && hasLevel) {
        return "Student";
    } else if (hasStaffNo && hasCategory) {
        return "Staff";
    } else if (hasUserNo && hasGender) {
        return "Other user";
    }

    return QString();
}

bool UserImporter::validateUserTypeMatch(const QString& detectedType, const QString& selectedRole)
{
    return detectedType == selectedRole;
}

ImportResult UserImporter::processImport(const QString &filePath, const std::function<void (int)> &progressCallback)
{
    ImportResult result(0, 0, QStringList());

    const QString connectionName = "import_thread_connection";
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
    db.setDatabaseName("library.db");

    if (!db.open()) {
        result.errors.append("Failed to open database: " + db.lastError().text());
        return result;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        result.errors.append("Could not open file for reading: " + filePath);
        return result;
    }

    QTextStream in(&file);

    // Read and validate header
    if (in.atEnd()) {
        result.errors.append("File is empty");
        return result;
    }

    QStringList headers;
    parseHeaders(in.readLine(), headers);
    QString detectedType = detectUserType(headers);

    if (detectedType.isEmpty()) {
        result.errors.append("Could not determine user type from CSV headers");
        return result;
    }

    if (!validateUserTypeMatch(detectedType, m_userRole)) {
        result.errors.append(QString("Selected user type (%1) does not match CSV content type (%2)")
                                 .arg(m_userRole).arg(detectedType));
        return result;
    }

    // Count total lines for progress
    int totalLines = 0;
    while (!in.atEnd()) {
        in.readLine();
        totalLines++;
    }

    file.seek(0);
    in.readLine(); // Skip header
    int currentLine = 0;

    // Process data rows
    while (!in.atEnd()) {
        QString line = in.readLine();
        QStringList userData = line.split(",");

        if (validateUserData(userData)) {
            if (processUserRecord(db, userData)) {
                result.successCount++;
            } else {
                result.failCount++;
                result.errors.append("Failed to process user: " + userData.join(","));
            }
        } else {
            result.failCount++;
            result.errors.append("Invalid data format: " + userData.join(","));
        }

        currentLine++;
        int progress = (currentLine * 100) / totalLines;
        progressCallback(progress);
    }

    file.close();
    db.close();
    QSqlDatabase::removeDatabase(connectionName);

    return result;
}

bool UserImporter::validateUserData(const QStringList &userData)
{
    // Basic validation for minimum fields
    if (userData.size() < 5) {
        return false;
    }

    // Validate role-specific fields
    if (m_userRole == "Student") {
        if (userData.size() != 8) return false;
        // Validate enrollment year
        bool yearValid;
        int year = userData[6].toInt(&yearValid);
        return yearValid && year > 1900;
    }
    else if (m_userRole == "Staff") {
        if (userData.size() != 8) return false;
        // Validate start year
        bool yearValid;
        int year = userData[6].toInt(&yearValid);
        return yearValid && year > 1900;
    }
    else if (m_userRole == "Other user") {
        if (userData.size() != 8) return false;  // Note: changed to 8 since phone is at index 3
        // Validate age
        bool ageValid;
        int age = userData[6].toInt(&ageValid);
        return ageValid && age > 0 && age <= 120;
    }

    return false;
}

bool UserImporter::processUserRecord(QSqlDatabase &db, const QStringList &userData)
{
    if (userData.size() < 3) {
        qWarning() << "Insufficient user data.";
        return false;
    }

    QString firstName = userData[0].trimmed();
    QString lastName = userData[1].trimmed();
    QString email = userData[2].trimmed();
    QString phone = userData[3].trimmed();
    QString userRole = m_userRole;

    // Validate data size based on role
    bool isValidSize = false;
    if (userRole == "Student" && userData.size() == 8) {
        isValidSize = true;
    } else if (userRole == "Staff" && userData.size() == 8) {
        isValidSize = true;
    } else if (userRole == "Other user" && userData.size() == 8) {  // Changed to 8 since phone is at index 3
        isValidSize = true;
    }

    if (!isValidSize) {
        qWarning() << "Invalid data size for role" << userRole;
        return false;
    }

    // Create and validate role-specific data
    QVariantMap additionalInfo;
    bool isValidData = false;

    if (userRole == "Student") {
        bool validYear;
        int enrollmentYear = userData[6].toInt(&validYear);
        if (!validYear || enrollmentYear <= 0) {
            qWarning() << "Invalid enrollment year for student";
            return false;
        }

        additionalInfo["adm_no"] = userData[4].trimmed();
        additionalInfo["branch"] = userData[5].trimmed();
        additionalInfo["enrollment_year"] = enrollmentYear;
        additionalInfo["level"] = userData[7].trimmed();

        isValidData = !additionalInfo["adm_no"].toString().isEmpty() &&
                      !additionalInfo["branch"].toString().isEmpty() &&
                      !additionalInfo["level"].toString().isEmpty();

    } else if (userRole == "Staff") {
        bool validYear;
        int startYear = userData[6].toInt(&validYear);
        if (!validYear || startYear <= 0) {
            qWarning() << "Invalid start year for staff";
            return false;
        }

        additionalInfo["staff_no"] = userData[4].trimmed();
        additionalInfo["department"] = userData[5].trimmed();
        additionalInfo["start_year"] = startYear;
        additionalInfo["category"] = userData[7].trimmed();

        isValidData = !additionalInfo["staff_no"].toString().isEmpty() &&
                      !additionalInfo["department"].toString().isEmpty() &&
                      !additionalInfo["category"].toString().isEmpty();

    } else if (userRole == "Other user") {
        bool validAge;
        int age = userData[6].toInt(&validAge);
        if (!validAge || age <= 0 || age > 120) {
            qWarning() << "Invalid age for other user";
            return false;
        }

        additionalInfo["user_no"] = userData[4].trimmed();
        additionalInfo["residence"] = userData[5].trimmed();
        additionalInfo["age"] = age;
        additionalInfo["gender"] = userData[7].trimmed();
        additionalInfo["phone"] = userData[3].trimmed(); //phone is three here, changing this at this point would lead to other drastic and time consuming changes to the database schema


        isValidData = !additionalInfo["user_no"].toString().isEmpty() &&
                      !additionalInfo["residence"].toString().isEmpty() &&
                      !additionalInfo["gender"].toString().isEmpty();
    }

    if (!isValidData) {
        qWarning() << "Invalid or missing data for role" << userRole;
        return false;
    }

    // Database operations
    QSqlQuery query(db);
    if (!query.exec("BEGIN TRANSACTION")) {
        qWarning() << "Failed to begin transaction:" << query.lastError().text();
        return false;
    }

    // Insert into users table
    query.prepare("INSERT OR IGNORE INTO users (first_name, second_name, email, phone, user_role) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(firstName);
    query.addBindValue(lastName);
    query.addBindValue(email);
    query.addBindValue(phone);
    query.addBindValue(userRole);

    if (!query.exec()) {
        query.exec("ROLLBACK");
        qWarning() << "Failed to insert into users table:" << query.lastError().text();
        return false;
    }

    int userId = query.lastInsertId().toInt();

    // Insert into role-specific table
    bool success = false;
    if (userRole == "Student") {
        query.prepare("INSERT OR IGNORE INTO students (student_id, adm_no, branch, enrollment_year, level) VALUES (?, ?, ?, ?, ?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["adm_no"].toString());
        query.addBindValue(additionalInfo["branch"].toString());
        query.addBindValue(additionalInfo["enrollment_year"].toInt());
        query.addBindValue(additionalInfo["level"].toString());
        success = query.exec();

    } else if (userRole == "Staff") {
        query.prepare("INSERT OR IGNORE INTO staff (staff_id, staff_no, department, start_year, category) VALUES (?, ?, ?, ?, ?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["staff_no"].toString());
        query.addBindValue(additionalInfo["department"].toString());
        query.addBindValue(additionalInfo["start_year"].toInt());
        query.addBindValue(additionalInfo["category"].toString());
        success = query.exec();

    } else if (userRole == "Other user") {
        query.prepare("INSERT OR IGNORE INTO other_users (other_users_id, user_no, residence, age, gender, phone) VALUES (?, ?, ?, ?, ?, ?)");
        query.addBindValue(userId);
        query.addBindValue(additionalInfo["user_no"].toString());
        query.addBindValue(additionalInfo["residence"].toString());
        query.addBindValue(additionalInfo["age"].toInt());
        query.addBindValue(additionalInfo["gender"].toString());
        query.addBindValue(additionalInfo["phone"].toString());
        success = query.exec();
    }

    if (!success) {
        query.exec("ROLLBACK");
        qWarning() << "Failed to insert into role-specific table:" << query.lastError().text();
        return false;
    }

    if (!query.exec("COMMIT")) {
        qWarning() << "Failed to commit transaction:" << query.lastError().text();
        return false;
    }

    return true;
}
