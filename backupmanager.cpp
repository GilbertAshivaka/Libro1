#include "backupmanager.h"
#include "databasemanager.h"
#include <QDebug>
#include <QCoreApplication>
#include <QJsonObject>
#include <QStorageInfo>
#include <QDesktopServices>
#include <QRandomGenerator>
#include <QSqlError>


BackupManager::BackupManager(QObject *parent)
    : QObject{parent}
    ,currentStatus(Idle)
    ,progressPercentage(0)
    ,cancelRequested(false)
    ,backupFrequencyHours(24)
    ,scheduledBackupEnabled(false)
    ,scheduledBackupTimer(new QTimer(this))
    ,backupWatcher(new QFutureWatcher<QString>(this))
    ,restoreWatcher(new QFutureWatcher<bool>(this))
{
    //initialize paths
    applicationDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    defaultBackupPath = applicationDataPath + "/Backups";
    databasePath = QApplication::applicationDirPath() + "/library.db";

    QDir().mkpath(defaultBackupPath);

    //Inititialize backup database
    initializeBackupDatabase();

    //connect QFutureWatchers
    connect(backupWatcher, &QFutureWatcher<QString>::finished, this, &BackupManager::onBackupFinished);
    connect(restoreWatcher, &QFutureWatcher<bool>::finished, this, &BackupManager::onRestoreFinished);

    //connect timer for scheduled backups
    connect(scheduledBackupTimer, &QTimer::timeout, this, &BackupManager::performScheduledBackup);

    //connect to the close database connection signall to close all the connections before trying to remove the database
    connect(this, &BackupManager::aboutToRestoreDatabase, this, [this]() {
        // Close all database connections in the main thread
        const auto connectionNames = QSqlDatabase::connectionNames();
        for (const QString &connectionName : connectionNames) {
            QSqlDatabase::database(connectionName).close();
            QSqlDatabase::removeDatabase(connectionName);
        }
        qDebug() << "Database connections closed.";
    });

    //connection to refresh the database connection when the restore is finished
    connect (this, &BackupManager::databaseRestored, this, [this] (){
        DatabaseManager dbManager;
        dbManager.createDatabase();
        if(dbManager.isdbInitialized()){
            qDebug() << "Database has been initialized successfully.";
        }else{
            qDebug() <<"Database re-initialization failed.";
        }
    });

    //restart the application
    connect(this, &BackupManager::databaseRestored, this, [this](){
        restart();
    });

    qDebug() << "BackupManager initialized succesfully with default path: " << defaultBackupPath;
}

BackupManager::~BackupManager()
{
    if (backupDb.isOpen()){
        backupDb.close();
    }

    // delete backupWatcher;
    // delete restoreWatcher;
}

bool BackupManager::createBackup(const BackupConfig &config)
{
    QMutexLocker locker(&backupMutex);

    if (currentStatus == InProgress){
        emit backupFailed("Another backup operation is already in progress.");
        return false;
    }

    //generate backupId for tracking
    currentBackupId = generateBackupId();

    //create initial backup record
    BackupRecord record;
    record.backupID = currentBackupId;
    record.timeStamp = QDateTime::currentDateTime();
    record.type = config.type;
    record.filePath = databasePath; //QString(); //will be set after backup creation
    record.compressed = config.compressBackup;
    record.encrypted = config.encryptBackup;
    record.status = InProgress;

    qDebug() << "Record created, sending to save function";

    if (!saveBackupRecords(record)){
        emit backupFailed("Failed to save the database backup.");
        return false;
    }

    qDebug() << "Record saved successfully.";

    setStatus(InProgress);
    cancelRequested = false;
    emit backupStarted();

    QFuture<QString> future = createBackupAsync(config);
    backupWatcher->setFuture(future);

    return true;
}

bool BackupManager::restoreBackup(const QString &backupFilePath, const QString &password)
{
    QMutexLocker locker(&backupMutex);

    if (currentStatus == InProgress){
        emit restoreFailed("Another operation is already in progress");
        return false;
    }

    if (!QFile::exists(backupFilePath)){
        emit restoreFailed("Backup file does not exist.");
        return false;
    }

    setStatus(InProgress);
    cancelRequested = false;
    emit restoreStarted();

    QFuture<bool> future = restoreDatabaseAsync(backupFilePath, password);
    restoreWatcher->setFuture(future);

    return true;
}

void BackupManager::openCloudDialog(CloudProvider provider, const QString &localBackupPath)
{
    if (!QFile::exists(localBackupPath)){
        emit backupFailed("Local backup file does not exist for backup.");
        return;
    }

    QString url = getCloudProviderUrl(provider);

    if (!url.isEmpty()){
        bool opened = QDesktopServices::openUrl(QUrl(url));
        if (!opened){
            emit backupFailed("Failed to open cloud provider in the browser.");
        }else {
            qDebug() << "Opened cloud provider: " << url;
            qDebug() << "Please backup this file on the cloud provider platform: " << localBackupPath;
            emit operationSuccessful("Please backup this file on the cloud provider platform: " + localBackupPath);
        }
    }else{
        emit errorOccured("Unsupported cloud provider.");
        qDebug() << "Unsupported cloud provider.";
    }
}

QString BackupManager::getCloudProviderUrl(CloudProvider provider) const
{
    switch(provider){
    case GoogleDrive:
        return "https://drive.google.com/drive/my-drive";
    case AmazonS3:
        return "https://console.aws.amazon.com/s3/";
    case DropBox:
        return "https://www.dropbox.com/home";
    case OneDrive:
        return "https://onedrive.live.com/";
    case Generic:
        return "https://google.com";// let the user handle generic providers.
    default :
        return "";
    }
}

void BackupManager::cancelCurrentBackup()
{
    cancelRequested = true;

    updateProgress(progressPercentage, "Cancelling operation...");

    //cancel the future if it is running
    // if (backupWatcher->isRunning()){
    //     backupWatcher->cancel();
    // }
    // if (restoreWatcher->isRunning()){
    //     restoreWatcher->cancel();
    // }
}

bool BackupManager::deleteBackupRecord(const QString &backupId)
{
    if (!backupDb.open()){
        emit errorOccured("Failed to open the database for deleting the record.");
        return false;
    }

    QSqlQuery query(backupDb);
    query.prepare("DELETE FROM backup_history WHERE backup_id = ?");
    query.addBindValue(backupId);

    return query.exec();
}

quint64 BackupManager::estimateBackupSize() const
{
    QFileInfo dbFile(databasePath);

    if (!dbFile.exists()){
        qDebug() << "Database file does not exist.";
        return 0;
    }

    quint64 size = dbFile.size();

    //if compression is used, estimate the comressed file size(about 30%-50% of the original)
    return static_cast<quint64>(size* 0.6);
}

quint64 BackupManager::getAvailableSpace(const QString &path) const
{
    QStorageInfo storage(path);

    return storage.bytesAvailable();
}

void BackupManager::configureBackup(const QVariantMap &configMap)
{
    BackupConfig config;
    config.type = static_cast<BackupType>(configMap.value("type").toInt());
    config.destinationPath = configMap.value(""
                                             "destinationPath").toString();
    config.provider = static_cast<CloudProvider>(configMap.value("provider").toInt());
    config.compressBackup = configMap.value("compressBackup").toBool();
    config.encryptBackup = configMap.value("encryptBackup").toBool();
    config.encryptionPassword = configMap.value("encryptionPassword").toString();

    // Now use the original function
    createBackup(config);
    // performLocalBackup(config);
}

void BackupManager::setDefaultBackupPath(const QString &path)
{
    if (defaultBackupPath != path){
        defaultBackupPath = path;
        QDir().mkpath(path);
        emit defaultPathChanged();
    }
}

void BackupManager::setBackupFrequencyHours(int hours)
{
    if (backupFrequencyHours != hours && hours >0){
        backupFrequencyHours = hours;
    }

    if (scheduledBackupEnabled){
        scheduledBackupTimer->setInterval(hours * 60 * 60 * 1000); //convert to milliseconds because the timer expects in milliseconds
    }

    emit frequencyChanged();
}

void BackupManager::setScheduledBackupEnabled(bool enabled)
{
    if (scheduledBackupEnabled != enabled){
        scheduledBackupEnabled = enabled;
    }

    if (enabled){
        scheduledBackupTimer->start(backupFrequencyHours * 60 * 60 * 1000);
        qDebug() << "Backup frequency timer started, interval: " << backupFrequencyHours << " hours";
    }else {
        scheduledBackupTimer->stop();
        qDebug() << "Backup frequency timer stopped.";
    }
    emit scheduledBackupEnabledChanged();
}

void BackupManager::restart()
{
    emit applicationRestarting("Database successfully restored, the application will restart.");

    // Give the UI time to display the message
    QTimer::singleShot(3000, this, [this]() {
        // Prepare the restart
        QString program = QApplication::applicationFilePath();
        QStringList arguments = QApplication::arguments();
        arguments.removeFirst(); // Remove program name

        // Schedule restart
        QMetaObject::invokeMethod(qApp, [program, arguments]() {
            QProcess::startDetached(program, arguments);
            QApplication::quit();
        }, Qt::QueuedConnection);

        qDebug() << "Restarting the application.";
    });
}

void BackupManager::onBackupFinished()
{
    QString result = backupWatcher->result();

    if (cancelRequested){
        cleanup();
        setStatus(Cancelled);
        updateBackupRecord(currentBackupId, Cancelled, "Backup cancelled by the user.");
        emit backupCancelled();
        return;
    }

    if (result.isEmpty()){
        setStatus(Failed);
        updateBackupRecord(currentBackupId, Failed, "Unkown error occured during backup.");
        emit backupFailed("Backup operation failed.");
    }else {
        updateProgress(100, "Backup completed successfully!");
        setStatus(Completed);
        updateBackupRecord(currentBackupId, Completed);
        emit backupCompleted(currentBackupId, result);
    }

    cleanup();
}

void BackupManager::onRestoreFinished()
{
    bool success = restoreWatcher->result();

    if (cancelRequested){
        setStatus(Cancelled);
        emit restoreCancelled();
        return;
    }

    if (success){
        updateProgress(100, "Database restored successfully");
        setStatus(Completed);
        emit restoreCompleted();
    }else {
        setStatus(Failed);
        emit restoreFailed("Backup restore failed.");
    }

    cleanup();
}

void BackupManager::performScheduledBackup()
{
    qDebug() << "Performing sheduled backup...";

    //create the default backup configuration
    emit gearingUp("Performing scheduled backup...");
    BackupConfig config;
    config.type = LocalBackup;
    config.destinationPath = defaultBackupPath;
    config.compressBackup = true;
    config.encryptBackup = false;

    createBackup(config);
}

QFuture<QString> BackupManager::createBackupAsync(const BackupConfig &config)
{
    return QtConcurrent::run([this, config]()->QString{
        return performLocalBackup(config);
    });
}

QFuture<bool> BackupManager::restoreDatabaseAsync(const QString &backupFilePath, const QString &password)
{
    return QtConcurrent::run([this, backupFilePath, password]()->bool{
        return performDatabaseRestore(backupFilePath, password);
    });
}

QFuture<QString> BackupManager::calculateChecksumAsync(const QString &filePath)
{
    return QtConcurrent::run([this, filePath]()->QString{
        return calculateFileChecksum(filePath);
    });
}

QFuture<bool> BackupManager::compressFilesAsync(const QString &sourcePath, const QString &targetPath)
{
    return QtConcurrent::run([this, sourcePath, targetPath]()->bool{
        return compressFile(sourcePath, targetPath);
    });
}

QFuture<bool> BackupManager::decompressFilesAsync(const QString &sourcePath, const QString &targetPath)
{
    return QtConcurrent::run([this, sourcePath, targetPath]()->bool{
        return decompressFile(sourcePath, targetPath);
    });
}

//Helper functions
bool BackupManager::initializeBackupDatabase()
{
    QString backupDbPath = applicationDataPath + "/backup_history.db";

    if (QSqlDatabase::contains("backupConnection")){
        backupDb = QSqlDatabase::database("backupConnection");
    }else {
        backupDb = QSqlDatabase::addDatabase("QSQLITE", "backupConnection");
        backupDb.setDatabaseName(backupDbPath);
    }

    if (!backupDb.open()){
        emit errorOccured("Failed to open the backup database: " + backupDb.lastError().text());
        return false;
    }

    QSqlQuery query(backupDb);

    if (!query.exec(
            "CREATE TABLE IF NOT EXISTS backup_history ("
            "backup_id TEXT PRIMARY KEY,"
            "timestamp DATETIME NOT NULL,"
            "type INTEGER NOT NULL,"
            "provider INTEGER,"
            "file_path TEXT NOT NULL,"
            "file_size INTEGER DEFAULT 0,"
            "compressed BOOLEAN DEFAULT 0,"
            "encrypted BOOLEAN DEFAULT 0,"
            "checksum TEXT,"
            "status INTEGER NOT NULL,"
            "error_message TEXT,"
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
            ")")) {
        qWarning() << "Failed to create backup_history table:" << query.lastError().text();
        emit errorOccured("Failed to create backup_history table: " + query.lastError().text());
        return false;
    }

    return true;
}

bool BackupManager::saveBackupRecords(const BackupRecord &record)
{
    qDebug() << "Getting ready to save the database record";
    if (!backupDb.open()){
        emit errorOccured("Failed to open the backup database to record database backup.");
        qDebug() << "Failed to open the backup database to record database backup.";
        return false;
    }

    qDebug() << "Database opened for saving the backup record.";

    QSqlQuery query(backupDb);
    query.prepare(
        "INSERT INTO backup_history (backup_id, timestamp, type, provider, file_path, "
        "file_size, compressed, encrypted, checksum, status, error_message) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

    query.addBindValue(record.backupID);
    query.addBindValue(record.timeStamp);
    query.addBindValue(static_cast<int>(record.type));
    query.addBindValue(static_cast<int>(record.provider));
    query.addBindValue(record.filePath);
    query.addBindValue(record.fileSize);
    query.addBindValue(record.compressed);
    query.addBindValue(record.encrypted);
    query.addBindValue(record.checkSum);
    query.addBindValue(static_cast<int>(record.status));
    query.addBindValue(record.errorMessage);

    qDebug() << "Database record query prepared.";

    if (!query.exec()){
        emit errorOccured("Failed to save backup record: " + query.lastError().text());
        qDebug() << "Failed to save backup record: " + query.lastError().text();
        return false;
    }

    qDebug() << "Database record query executed.";

    return true;
}

bool BackupManager::updateBackupRecord(const QString &backupId, BackupStatus status, const QString &errorMessage)
{
    if (!backupDb.open()){
        emit errorOccured("Failed to open the backup database to update backup record: " + backupDb.lastError().text());
        return false;
    }

    QSqlQuery query(backupDb);
    query.prepare("UPDATE backup_history SET status = ?, error_message = ? WHERE backup_id = ?");
    query.addBindValue(static_cast<int>(status));
    query.addBindValue(errorMessage);
    query.addBindValue(backupId);

    if (!query.exec()){
        emit errorOccured("Failed to update backup record: " + query.lastError().text());
        return false;
    }

    return true;
}

QString BackupManager::generateBackupId() const
{
    return QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss") + "_" +
           QString::number(QRandomGenerator::global()->bounded(1000), 16);
}

QString BackupManager::generateBackupFileName(BackupType type, CloudProvider provider) const
{
    QString prefix = "ILMS_DB_Backup";
    QString typeStr = (type == LocalBackup) ? "Local" : "Cloud";

    QString providerStr;
    if (type == CloudBackup){
        switch (provider){
        case GoogleDrive:
            providerStr  = "_GDrive";
            break;
        case AmazonS3:
            providerStr = "_AWS";
            break;
        case DropBox:
            providerStr = "_DropBox";
            break;
        case OneDrive:
            providerStr = "_OneDrive";
            break;
        case Generic:
            providerStr = "_Generic";
            break;
        }
    }

    QString timeStamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");

    return QString("%1_%2%3_%4.db").arg(prefix, typeStr, providerStr, timeStamp);
}

bool BackupManager::isDatabaseFile(const QString &file) const
{
    QSqlDatabase testDb;
    if (QSqlDatabase::contains("testConnection")) {
        testDb = QSqlDatabase::database("testConnection");
    } else {
        testDb = QSqlDatabase::addDatabase("QSQLITE", "testConnection");
    }
    testDb.setDatabaseName(file);

    bool isValid = testDb.open();
    if (isValid){
        //Additional check, try to query sqlite_master
        QSqlQuery query(testDb);
        isValid = query.exec("SELECT name FROM sqlite_master WHERE type='table' LIMIT 1");

        //check if it has the expected library tables
        if (isValid){
            //check if it has expected library tables
            QSqlQuery tableQuery(testDb);
            isValid = tableQuery.exec("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'books', 'students', 'staff')");

            //at least one of the core tables should exist
            isValid = isValid && tableQuery.next();
        }
    }

    // testDb.close();
    // QSqlDatabase::removeDatabase("testConnection");

    return isValid;
}

void BackupManager::updateProgress(int percentage, const QString &operation)
{
    if(percentage != progressPercentage || currentOperation != operation){
        progressPercentage = percentage;
        currentOperation = operation;
    }

    emit progressChanged();
    emit operationChanged();
    emit backupProgress(percentage, operation);

    //also emit restoreProgress if we're in restore mode
    if(currentStatus == InProgress && restoreWatcher->isRunning()){
        emit restoreProgress(percentage, operation);
        qDebug() << "Backup/Restore progress: " << percentage << "%" << operation;
    }
}

void BackupManager::setStatus(BackupStatus status)
{
    if (currentStatus != status){
        currentStatus = status;

        emit statusChanged();
        qDebug() << "Backup/Restore set to: " << status;
    }
}

void BackupManager::cleanup()
{
    progressPercentage = 0;
    currentOperation.clear();
    cancelRequested = false;
    currentBackupId.clear();

    emit progressChanged();
    emit operationChanged();
}

//Core backup logic
QString BackupManager::performLocalBackup(const BackupConfig &config)
{
    try {
        updateProgress(10, "Initializing backup....");

        if (!QFile::exists(databasePath)){
            emit backupFailed("Database file does not exist.");
            return QString();
        }

        QString backupPath = config.destinationPath.isEmpty() ? defaultBackupPath : config.destinationPath;
        QString backupFileName = generateBackupFileName(config.type, config.provider);
        QString fullBackupPath = backupPath + "/" + backupFileName;

        QDir().mkpath(backupPath);

        updateProgress(20, "Copying database file...");

        //Start copying the file
        if (QFile::exists(fullBackupPath)){
            QFile::remove(fullBackupPath);
        }

        if (!QFile::copy(databasePath, fullBackupPath)){
            //if direct copying fails, try copying to temp first

            QString tempPath = fullBackupPath + ".tmp";

            if (QFile::exists(tempPath)){
                QFile::remove(tempPath);
            }

            if (!QFile::copy(databasePath, tempPath)){
                emit errorOccured("Failed to copy the database file to temp location.");
                qWarning() << "Failed to copy the database file to temp location.";
                return QString();
            }

            qDebug() << "Temp path: " << tempPath;
            qDebug() << "Db path: " << databasePath;

            if (!QFile::rename(tempPath, fullBackupPath)){
                QFile::remove(tempPath);
                emit errorOccured("Failed to move temp file to final destination.");
                qWarning() << "Failed to move temp file to final destination.";
                return QString();
            }
        }

        if (cancelRequested){
            QFile::remove(fullBackupPath);
            cancelCurrentBackup();
            return QString();
        }

        updateProgress(50, "Backup file created.");

        //compress if requested
        if (config.compressBackup){
            updateProgress(50, "Compressing the backup....");

            QString compressedPath = fullBackupPath + ".zip";

            if (compressFile(fullBackupPath, compressedPath)){
                QFile::remove(fullBackupPath); //remove the uncompressed version
                fullBackupPath = compressedPath;
                updateProgress(75, "Compression completed");
            }else{
                qWarning() << "Compression failed, keeping the uncompressed backup.";
            }
        }

        if (cancelRequested){
            QFile::remove(fullBackupPath);
            cancelCurrentBackup();
            return QString();
        }

        updateProgress(80, "Calculating checksum....");

        //calculate checksum
        QString checksum = calculateFileChecksum(fullBackupPath);

        //update the database record with the final details
        QFileInfo fileInfo(fullBackupPath);

        if (backupDb.open()) {
            QSqlQuery query(backupDb);
            query.prepare("UPDATE backup_history SET file_path = ?, file_size = ?, checksum = ? WHERE backup_id = ?");
            query.addBindValue(fullBackupPath);
            query.addBindValue(fileInfo.size());
            query.addBindValue(checksum);
            query.addBindValue(currentBackupId);

            if (!query.exec()) {
                emit errorOccured("Failed to update backup record: " + query.lastError().text());
                qWarning() << "Failed to update backup record: " << query.lastError().text();
            }
        }

        updateProgress(90, "Finalizing backup...");

        //Open cloud backup dialog if it's a cloud backup
        if (config.type == CloudBackup) {
            QMetaObject::invokeMethod(this, [this, config, fullBackupPath]() {
                qDebug() << "Openning the cloud backup window....." << config.provider << " " << fullBackupPath;
                openCloudDialog(config.provider, fullBackupPath);
            }, Qt::QueuedConnection);
        }
        emit backupCompleted(currentBackupId, fullBackupPath);
        return fullBackupPath;

    }catch(std::exception &e){
        emit errorOccured("Exception in LocalBackup: " + QString(e.what()));
        qWarning() << "Exception in performLocalBackup: " << e.what();
        return QString();
    }catch(...){
        emit errorOccured("Unknown exception in performLocalBackup.");
        qWarning() << "Unknown exception in performLocalBackup.";
        return QString();
    }
}

bool BackupManager::performDatabaseRestore(const QString &backupFilePath, const QString &password)
{
    Q_UNUSED(password) // encryption not implemented

    try{
        updateProgress(10, "Validating backup file...");

        if (!QFile::exists(backupFilePath)){
            emit errorOccured("Backup file does not exist: " + backupFilePath);
            qWarning() << "Backup file does not exist" << backupFilePath;
            return false;
        }

        QString workingPath = backupFilePath;
        QString tempPath;

        //check if it's a compressed file
        if (backupFilePath.endsWith(".zip", Qt::CaseInsensitive)){
            updateProgress(20, "Decompressing backup....");
            tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/restore_temp.db";

            if (QFile::exists(tempPath)){
                QFile::remove(tempPath);
            }

            if(!decompressFile(backupFilePath, tempPath)){
                emit errorOccured("Failed to decompress backup.");
                qWarning() << "Failed to decompress backup.";
                return false;
            }
            workingPath = tempPath;
        }

        if (cancelRequested){
            if (!tempPath.isEmpty()){
                QFile::remove(tempPath);
            }
            cancelCurrentBackup();
            return false;
        }

        updateProgress(50, "Validating database integrity....");

        //validate that it's a proper SQLite database file
        if(!isDatabaseFile(workingPath)){
            emit errorOccured("Invalid database file: " + workingPath);
            if (!tempPath.isEmpty()){
                QFile::remove(tempPath);
            }
            return false;
        }

        updateProgress(70, "Backing up current database....");

        QString currentBackupPath = databasePath + ".backup." + QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");
        if (QFile::exists(databasePath)){
            if (!QFile::copy(databasePath, currentBackupPath)) {
                emit errorOccured("Failed to create backup of current database.");
                if (!tempPath.isEmpty()){
                    QFile::remove(tempPath);
                }
                return false;
            }
        }

        updateProgress(80, "Restoring backup....");

        // Signal main thread to close database connections before file operations
        QMetaObject::invokeMethod(this, [this]() {
            emit aboutToRestoreDatabase();
        }, Qt::BlockingQueuedConnection);

        // Give system time to release file handles after connections are closed
        QThread::msleep(1000);


        // Replace the current database
        if (QFile::exists(databasePath)){
            if (!QFile::remove(databasePath)) {
                emit errorOccured("Failed to remove existing database file. File may be in use.");
                qDebug() << "Failed to remove existing database file. File may be in use. " << databasePath;

                // Restore the current database backup
                if (QFile::exists(currentBackupPath)){
                    QFile::remove(currentBackupPath);
                }

                if (!tempPath.isEmpty()){
                    QFile::remove(tempPath);
                }

                qDebug() << "Failed to remove existing database file. File may be in use. " << databasePath;
                return false;
            }
        }

        qDebug() << "Successfully removed the database.";

        // Add detailed debugging for the copy operation
        QFileInfo sourceInfo(workingPath);
        QFileInfo targetDirInfo(QFileInfo(databasePath).absolutePath());

        qDebug() << "Source file size:" << sourceInfo.size() << "bytes";
        qDebug() << "Source readable:" << sourceInfo.isReadable();
        qDebug() << "Target directory writable:" << targetDirInfo.isWritable();
        qDebug() << "Attempting to copy from:" << workingPath << "to:" << databasePath;

        bool success = false;

        // Try standard Qt copy first
        success = QFile::copy(workingPath, databasePath);

        if (!success) {
            qDebug() << "Standard QFile::copy failed, attempting manual copy...";

            // Try manual copy as fallback
            QFile sourceFile(workingPath);
            QFile targetFile(databasePath);

            if (sourceFile.open(QIODevice::ReadOnly)) {
                if (targetFile.open(QIODevice::WriteOnly)) {
                    QByteArray data = sourceFile.readAll();
                    qint64 bytesWritten = targetFile.write(data);
                    success = (bytesWritten == data.size() && bytesWritten > 0);
                    targetFile.close();

                    if (success) {
                        qDebug() << "Manual copy succeeded, wrote" << bytesWritten << "bytes";
                    } else {
                        qDebug() << "Manual copy failed - bytes written:" << bytesWritten << "expected:" << data.size();
                        qDebug() << "Target file error:" << targetFile.errorString();
                    }
                } else {
                    qDebug() << "Failed to open target file for writing:" << targetFile.errorString();
                }
                sourceFile.close();
            } else {
                qDebug() << "Failed to open source file for reading:" << sourceFile.errorString();
            }
        } else {
            qDebug() << "Standard copy succeeded";
        }

        if (!success){
            emit errorOccured("Failed to copy the database to target location.");
            qDebug() << "Failed to copy the database to target location.";

            //restore the current database if the copying failed
            if (QFile::exists(currentBackupPath)){
                QFile::copy(currentBackupPath, databasePath);
                QFile::remove(currentBackupPath);
            }

            if (!tempPath.isEmpty()){
                QFile::remove(tempPath);
            }
            return false;
        }

        updateProgress(90, "Validating restored database....");

        // Create a new database connection specifically for this thread
        QString connectionName = QString("restore_test_%1").arg(reinterpret_cast<quintptr>(QThread::currentThread()));
        QSqlDatabase testDb;

        // Clean up any existing connection with this name first
        if (QSqlDatabase::contains(connectionName)) {
            QSqlDatabase::removeDatabase(connectionName);
        }

        testDb = QSqlDatabase::addDatabase("QSQLITE", connectionName);
        testDb.setDatabaseName(databasePath);

        if (!testDb.open()){
            emit errorOccured("Restored database is invalid: " + testDb.lastError().text());
            //restore the backup if the new database is invalid

            QFile::remove(databasePath);
            if(QFile::exists(currentBackupPath)){
                QFile::copy(currentBackupPath, databasePath);
                QFile::remove(currentBackupPath);
            }

            if (!tempPath.isEmpty()){
                QFile::remove(tempPath);
            }

            // Clean up the test connection
            QSqlDatabase::removeDatabase(connectionName);

            return false;
        }

        // Additional validation: check if essential tables exist
        QSqlQuery query(testDb);
        bool hasValidTables = query.exec("SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users', 'books', 'students', 'staff')");

        if (!hasValidTables || !query.next()) {
            emit errorOccured("Restored database does not contain expected tables.");

            // Clean up and restore backup
            testDb.close();
            QSqlDatabase::removeDatabase(connectionName);

            QFile::remove(databasePath);
            if(QFile::exists(currentBackupPath)){
                QFile::copy(currentBackupPath, databasePath);
                QFile::remove(currentBackupPath);
            }

            if (!tempPath.isEmpty()){
                QFile::remove(tempPath);
            }

            return false;
        }

        // Close and remove the test connection
        testDb.close();
        QSqlDatabase::removeDatabase(connectionName);

        //cleanup
        if (QFile::exists(currentBackupPath)){
            QFile::remove(currentBackupPath);
        }

        if (!tempPath.isEmpty()){
            QFile::remove(tempPath);
        }

        updateProgress(100, "Database restore completed successfully.");
        emit operationSuccessful("Database restored successfully from: " + backupFilePath);

        //notify for the database connections to be refreshed
        QMetaObject::invokeMethod(this, [this]() {
            emit databaseRestored();
        }, Qt::QueuedConnection);

        return true;

    }catch(const std::exception& e){
        emit errorOccured("Error in performDatabaseRestore: " + QString(e.what()));
        return false;
    }catch(...){
        emit errorOccured("Unknown error in performDatabaseRestore.");
        return false;
    }
}
QString BackupManager::calculateFileChecksum(const QString &filePath)
{
    QFile file(filePath);

    if (!file.open(QIODevice::ReadOnly)){
        emit errorOccured("Failed to open file for checksum calculation.");
        return QString();
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);

    const quint64 bufferSize = 8192;
    char buffer[bufferSize];

    while(!file.atEnd()){
        qint64 bytesRead = file.read(buffer, bufferSize);

        if (bytesRead >0 ){
            hash.addData(QByteArrayView(buffer, bytesRead));
        }

        if (cancelRequested){
            return QString();
        }
    }

    return hash.result().toHex();
}

bool BackupManager::compressFile(const QString &sourcePath, const QString targetPath)
{
    QProcess zipProcess;
    QStringList arguments;

#ifdef Q_OS_WIN
    //Use built-in windows compression
    QString command = "powershell";

    arguments << "-Command"
              << QString("Compress-Archive -Path '%1' -DestinationPath '%2' -Force")
                     .arg(sourcePath, targetPath);

#else
    // Use zip command on Unix-like systems
    QString command = "zip";
    arguments << "-j" // Don't store directory structure
              << targetPath
              << sourcePath;
#endif

    zipProcess.start(command, arguments);

    if (!zipProcess.waitForStarted(5000)){
        emit errorOccured("Failed to start compression process.");
        return false;
    }

    if (!zipProcess.waitForFinished(120000)){
        emit errorOccured("Compression process timed out.");
        zipProcess.kill();
        return false;
    }

    if (zipProcess.exitCode() != 0){
        emit errorOccured(
            QString("Compression failed with exit code: %1\nError output: %2")
                .arg(zipProcess.exitCode())
                .arg(QString::fromLocal8Bit(zipProcess.readAllStandardError()))
            );

        return false;
    }

    return QFile::exists(targetPath);
}

bool BackupManager::decompressFile(const QString &sourcePath, const QString &targetPath)
{
    QProcess unzipProcess;
    QStringList arguments;

    //get the target directory
    QFileInfo targetInfo(targetPath);

    QString targetDir = targetInfo.absolutePath();
    QString taretFileName = targetInfo.fileName();

    //ensure that the target directory exists
    QDir().mkpath(targetDir);

#ifdef Q_OS_WIN
    //use built-in Windows decompression
    QString command = "powershell";
    arguments << "-Command"
              << QString("Expand-Archive -Path '%1' -DestinationPath '%2' -Force")
                     .arg(sourcePath, targetDir);

#else
    // Use unzip command on Unix-like systems
    QString command = "unzip";
    arguments << "-o" // Overwrite existing files
              << sourcePath
              << "-d" << targetDir;
#endif

    unzipProcess.start(command, arguments);

    if(!unzipProcess.waitForStarted(5000)){
        emit errorOccured("Failed to start the decompression process");
        return false;
    }

    if(!unzipProcess.waitForFinished(120000)){
        emit errorOccured("Decompression process timed out.");
        unzipProcess.kill();
        return false;
    }

    if (unzipProcess.exitCode() != 0){
        emit errorOccured(
            QString("Decompression failed with exit code: %1\nError output: %2")
                .arg(unzipProcess.exitCode())
                .arg(QString::fromLocal8Bit(unzipProcess.readAllStandardError()))
            );

        return false;
    }

    //On Windows, Powershell extracts to a subfolder so we need to find the actual file
#ifdef Q_OS_WIN
    QDir extractedDir(targetDir);
    QStringList filters;

    filters << "*.db";

    QFileInfoList dbFiles;
    QDirIterator it(targetDir, filters, QDir::Files, QDirIterator::Subdirectories);

    while (it.hasNext()){
        it.next();
        dbFiles << it.fileInfo();
    }

    if (!dbFiles.isEmpty()){
        //move the first .db file found to the target location
        QString extractedFile = dbFiles.first().absoluteFilePath();

        if (QFile::exists(targetPath)){
            QFile::remove(targetPath);
        }

        bool moved = QFile::rename(extractedFile, targetPath);

        if (!moved){
            //if rename fails,  try copy then delete
            QFile::copy(extractedFile, targetPath);
            QFile::remove(extractedFile);
            moved = true;
        }

        //clean up any other extracted folders
        QDir extractedDirPath = dbFiles.first().absolutePath();
        if (extractedDirPath != targetDir){
            QDir(extractedDirPath).removeRecursively();
        }

        return moved && QFile::exists(targetPath);
    }
#endif
    return QFile::exists(targetPath);
}

QVariantList BackupManager::getBackupHistory()
{
    qDebug() << "Getting ready to fetch backup history.";
    QVariantList records;

    if (!backupDb.open()){
        return records;
    }

    qDebug() << "Database opened successfully to get backup history.";

    QSqlQuery query(backupDb);

    if (!query.exec("SELECT * FROM backup_history ORDER BY timestamp DESC LIMIT 50")) {
        qWarning() << "Failed to fetch backup history:" << query.lastError().text();
        return records;
    }

    qDebug() << "Query executes.";

    while (query.next()){
        QVariantMap record;
        record["backupId"] = query.value("backup_id").toString();
        record["timeStamp"] = query.value("timestamp").toDateTime();
        record["type"] = static_cast<BackupType>(query.value("type").toInt());
        record["provider"]  = static_cast<CloudProvider>(query.value("provider").toInt());
        record["filePath"] = query.value("file_path").toString();
        record["fileSize"] = query.value("file_size").toLongLong();
        record["compressed"] = query.value("compressed").toBool();
        record["encrypted"] = query.value("encrypted").toBool();
        record["checkSum"] = query.value("checksum").toString();
        record["status"] = static_cast<BackupStatus>(query.value("status").toInt());
        record["errorMessage"] = query.value("error_message").toString();

        records.append(record);
    }

    qDebug() << "Records fetched.";
    for (const auto &record: records){
        qDebug() << "Record: " << record.toMap()["backupId"].toString();
    }

    return records;
}

































