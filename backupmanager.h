#ifndef BACKUPMANAGER_H
#define BACKUPMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QtConcurrent>
#include <QFuture>
#include <QFutureWatcher>
#include <Qurl>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QDateTime>
#include <QTimer>
#include <QFileInfo>
#include <QProgressDialog>
#include <QApplication>
#include <QMessageBox>
#include <QStandardPaths>
#include <QCryptographicHash>
#include <QMutex>
#include <QMutexLocker>
#include "databasemanager.h"

class BackupManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(BackupStatus currentStatus READ getCurrentStatus NOTIFY statusChanged )
    Q_PROPERTY(int  progressPercentage READ getProgressPercentage NOTIFY progressChanged)
    Q_PROPERTY(QString currentOperation READ getCurrentOperation NOTIFY operationChanged)
    Q_PROPERTY(QString defaultBackupPath READ getDefaultBackupPath WRITE setDefaultBackupPath NOTIFY defaultPathChanged)
    Q_PROPERTY(int backupFrequencyHours READ getBackupFrequencyHours WRITE setBackupFrequencyHours NOTIFY frequencyChanged)
    Q_PROPERTY(bool scheduledBackupEnabled READ isScheduledBackupEnabled WRITE setScheduledBackupEnabled NOTIFY scheduledBackupEnabledChanged)

public:
    enum BackupType{
        LocalBackup = 0,
        CloudBackup = 1,
    };
    Q_ENUM(BackupType)

    enum BackupStatus{
        Idle = 0,
        InProgress = 1,
        Completed = 2,
        Failed = 3,
        Cancelled = 4
    };
    Q_ENUM(BackupStatus)

    enum CloudProvider{
        GoogleDrive = 0,
        AmazonS3 = 1,
        DropBox = 2,
        OneDrive = 3,
        Generic = 4
    };
    Q_ENUM(CloudProvider)

    struct BackupConfig{
        BackupType type;
        QString destinationPath;
        CloudProvider provider;
        bool compressBackup;
        bool encryptBackup;
        QString encryptionPassword;

        BackupConfig() : type(LocalBackup), provider(GoogleDrive), compressBackup(true), encryptBackup(false){}
    };



    struct BackupRecord{
        QString backupID;
        QDateTime timeStamp;
        BackupType type;
        CloudProvider provider;
        QString filePath;
        quint64 fileSize;
        BackupStatus status;
        QString errorMessage;
        bool encrypted;
        bool compressed;
        QString checkSum;
    };

    explicit BackupManager(QObject *parent = nullptr);

    ~BackupManager();
    //Main backup functions
    Q_INVOKABLE bool createBackup(const BackupConfig &config);
    Q_INVOKABLE bool restoreBackup(const QString &backupFilePath, const QString &password = QString());

    //Cloud backup helpers
    Q_INVOKABLE void openCloudDialog(CloudProvider provider, const QString &localBackupPath);
    Q_INVOKABLE QString getCloudProviderUrl(CloudProvider provider) const;

    //Backup managers
    Q_INVOKABLE void cancelCurrentBackup();
    Q_INVOKABLE QVariantList getBackupHistory();
    Q_INVOKABLE bool deleteBackupRecord(const QString &backupId);
    Q_INVOKABLE quint64 estimateBackupSize() const;
    Q_INVOKABLE quint64 getAvailableSpace(const QString &path) const;

    Q_INVOKABLE void configureBackup(const QVariantMap &configMap);

    //getter for the properties
    BackupStatus getCurrentStatus(){return currentStatus;}
    int getProgressPercentage(){return progressPercentage;}
    QString getCurrentOperation(){return currentOperation;}
    QString getDefaultBackupPath(){return defaultBackupPath;}

    Q_INVOKABLE void setDefaultBackupPath(const QString &path);

    //scheduled backup properties
    int getBackupFrequencyHours() const{return backupFrequencyHours;}
    Q_INVOKABLE void setBackupFrequencyHours(int hours);
    bool isScheduledBackupEnabled() const{return scheduledBackupEnabled;}
    Q_INVOKABLE void setScheduledBackupEnabled(bool enabled);

    void restart();


public slots:


signals:
    void backupStarted();
    void backupProgress(int percentage, const QString &operation);
    void backupCompleted(const QString backupId, const QString &filePath);
    void backupFailed(const QString &error);
    void backupCancelled();

    void restoreStarted();
    void restoreProgress(int percentage, const QString &operation);
    void restoreCancelled();
    void restoreCompleted();
    void restoreFailed(const QString &error);


    void statusChanged();
    void operationChanged();
    void defaultPathChanged();
    void frequencyChanged();
    void progressChanged();
    void scheduledBackupEnabledChanged();

    //utility signals
    void errorOccured(const QString &errorMessage);
    void gearingUp(const QString &message);
    void operationSuccessful(const QString &message);

    void databaseRestored();
    void aboutToRestoreDatabase();

    void applicationRestarting(const QString &message);

private slots:
    void onBackupFinished();
    void onRestoreFinished();
    void performScheduledBackup();

private:
    //Async wrapper functions
    QFuture<QString> createBackupAsync(const BackupConfig &config);
    QFuture<bool> restoreDatabaseAsync(const QString &backupFilePath, const QString &password = QString());
    QFuture<QString> calculateChecksumAsync(const QString &filePath);
    QFuture<bool> compressFilesAsync(const QString &sourcePath, const QString &targetPath);
    QFuture<bool> decompressFilesAsync(const QString &sourcePath, const QString &targetPath);

    //helper functions
    bool initializeBackupDatabase();
    bool saveBackupRecords(const BackupRecord &record);
    bool updateBackupRecord(const QString &backupId, BackupStatus status, const QString &errorMessage = QString());
    QString generateBackupId() const;
    QString generateBackupFileName(BackupType type, CloudProvider provider = GoogleDrive) const;
    bool isDatabaseFile(const QString &file) const;
    void updateProgress(int percentage, const QString &operation);
    void setStatus(BackupStatus status);
    void cleanup();

    //core backup/restore logic called by the Async wrappers
    QString performLocalBackup(const BackupConfig &config);
    bool performDatabaseRestore(const QString &backupFilePath, const QString &password = QString());
    QString calculateFileChecksum(const QString &filePath);
    bool compressFile(const QString &sourcePath, const QString targetPath);
    bool decompressFile(const QString &sourcePath, const QString &targetPath);

    //Member variables
    QMutex backupMutex;
    QSqlDatabase backupDb;

    BackupStatus currentStatus;
    int progressPercentage;
    QString currentOperation;
    bool cancelRequested;

    QString applicationDataPath;
    QString defaultBackupPath;
    QString databasePath;

    //scheduled backup
    QTimer *scheduledBackupTimer;
    int backupFrequencyHours;
    bool scheduledBackupEnabled;

    QFutureWatcher<QString> *backupWatcher;
    QFutureWatcher<bool> *restoreWatcher;

    //current backup ID record for updates;
    QString currentBackupId;
};

#endif // BACKUPMANAGER_H


































