#include "storagemanager.h"
#include "databasemanager.h"

StorageManager::StorageManager(QObject *parent)
    : QObject{parent}
    ,m_appSize(0)
    ,m_databaseSize(0)
    ,m_deviceSize(0)
    ,m_recommendedSize(0)
{}

//define the getters
qint64 StorageManager::appSize() const {
    return m_appSize;
}

double StorageManager::storagePercentage() const
{
    if (m_deviceSize == 0)
        return 0.0;

    return (static_cast<double>(m_appSize) / static_cast<double>(m_deviceSize)) * 100.0;
}

qint64 StorageManager::databaseSize() const {
    return m_databaseSize;
}

qint64 StorageManager::deviceSize() const {
    return m_deviceSize;
}

qint64 StorageManager::recommendedSize() const {
    return m_recommendedSize;
}

//continue defining the getters
QString StorageManager::appSizeFormatted() const {
    return formatSize(m_appSize);
}

QString StorageManager::databaseSizeFormatted() const {
    return formatSize(m_databaseSize);
}
QString StorageManager::deviceSizeFormatted() const {
    return formatSize(m_deviceSize);
}

QString StorageManager::recommendedSizeFormatted() const {
    return formatSize(m_recommendedSize);
}

void StorageManager::fetchStorageInfo()
{
    qDebug() << "Fetching storage info....";

    try{
        m_appSize = calculateAppSize();
        m_databaseSize = calculateDatabaseSize();
        m_deviceSize = calculateDeviceSize();
        m_recommendedSize = m_appSize * 3;

        qDebug() << "Storage info fetched successfully.";
        qDebug() << "App Size: " << appSizeFormatted();
        qDebug() << "Database Size: " << databaseSizeFormatted();
        qDebug() << "Device size: " << deviceSizeFormatted();
        qDebug() << "Reccomended Size:" << recommendedSizeFormatted();
        qDebug() << "Storage Percentage: " << storagePercentage();

        emit storageDataChanged();
    }catch(const std::exception &e){
        qDebug() << "Failed to fetch storage info: " << e.what();
        emit errorOccured(QString("Failed to fetch storage data: %1").arg(e.what()));
    }
}

qint64 StorageManager::calculateDirectorySize(const QString &path)
{
    qint64 totalSize = 0;

    QDir dir(path);

    if (!dir.exists()){
        return 0;
    }

    QFileInfoList files = dir.entryInfoList(QDir::Files | QDir::Hidden | QDir::System);
    for (const QFileInfo &fileInfo: files){
        totalSize += fileInfo.size();
    }

    QFileInfoList subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
    for (const QFileInfo &subdir: subdirs){
        totalSize += calculateDirectorySize(subdir.absoluteFilePath());
    }

    return totalSize;
}

qint64 StorageManager::calculateAppSize()
{
    QString appPath = QApplication::applicationDirPath();
    qint64 appSize = calculateDirectorySize(appPath);

    //also include the executable if it's not in the calculated appPath
    QFileInfo execInfo(QApplication::applicationDirPath());

    if (!execInfo.absolutePath().startsWith(appPath))
        appSize += execInfo.size();

    return appSize;
}

qint64 StorageManager::calculateDatabaseSize()
{
    //get all the possible places where the libary.db is located
    QStringList possiblePaths = {
        DatabaseManager::getDatabasePath(),
        QApplication::applicationDirPath() + "/library.db",
        QDir::currentPath() + "library.db",
        QDir::homePath() + "library.db",
        QDir::tempPath() + "library.db"
    };

    qDebug() << "Application path: " << QApplication::applicationDirPath();

    for (const QString &path: possiblePaths){
        QFileInfo dbInfo(path);

        if (dbInfo.exists() && dbInfo.isFile()){
            qDebug() << "Found file at: " <<path;

            return dbInfo.size();
        }
    }

    qDebug() << "Database file library.db could not be found in common places";
    emit errorOccured("Database file library.db could not be found in common places. \nThe database size will be 0 B ");
    return 0;
}

qint64 StorageManager::calculateDeviceSize()
{
    QString appPath = QApplication::applicationDirPath();
    QStorageInfo storage(appPath);

    if (storage.isValid()){
        return storage.bytesTotal();
    }

    qDebug() << "Could not determine devide storage size";
    return 0;
}

QString StorageManager::formatSize(qint64 bytes) const
{
    if (bytes == 0)
        return "0 B";

    qint64 KB = 1024;
    qint64 MB = KB * 1024;
    qint64 GB = MB * 1024;
    qint64 TB = GB * 1024;

    if (bytes >= TB){
        return QString::number(static_cast<double>(bytes) / TB ,'f', 2) + " TB";
    }else if (bytes >= GB){
        return QString::number(static_cast<double>(bytes) / GB, 'f', 2) + " GB";
    }else if(bytes >= MB){
        return QString::number(static_cast<double>(bytes) / MB, 'f', 2) + " MB";
    }else if(bytes >= KB){
        return QString::number(static_cast<double>(bytes) / KB, 'f', 2) + " KB";
    }else{
        return QString::number(bytes)  + " B";
    }
}































