#ifndef STORAGEMANAGER_H
#define STORAGEMANAGER_H

#include <QObject>
#include <QQmlEngine>
#include <QStorageInfo>
#include <QDir>
#include <QFileInfo>
#include <QtWidgets/QApplication>
#include <QDebug>

class StorageManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qint64 appSize READ appSize NOTIFY storageDataChanged)
    Q_PROPERTY(qint64 databaseSize READ databaseSize NOTIFY storageDataChanged)
    Q_PROPERTY(qint64 deviceSize READ deviceSize NOTIFY storageDataChanged)
    Q_PROPERTY(qint64 recommendedSize READ recommendedSize NOTIFY storageDataChanged)
    Q_PROPERTY(double storagePercentage READ storagePercentage NOTIFY storageDataChanged)
    Q_PROPERTY(QString appSizeFormatted READ appSizeFormatted NOTIFY storageDataChanged)
    Q_PROPERTY(QString databaseSizeFormatted READ databaseSizeFormatted NOTIFY storageDataChanged)
    Q_PROPERTY(QString deviceSizeFormatted READ deviceSizeFormatted NOTIFY storageDataChanged)
    Q_PROPERTY(QString recommendedSizeFormatted READ recommendedSizeFormatted NOTIFY storageDataChanged)
public:
    explicit StorageManager(QObject *parent = nullptr);

    //Getters
    qint64 appSize() const;
    qint64 databaseSize() const;
    qint64 deviceSize() const;
    qint64 recommendedSize() const;

    double storagePercentage() const;

    QString appSizeFormatted() const;
    QString databaseSizeFormatted() const;
    QString deviceSizeFormatted() const;
    QString recommendedSizeFormatted() const;

public slots:
    void fetchStorageInfo();

signals:
    void storageDataChanged();
    void errorOccured(const QString& error);

private:
    qint64 m_appSize;
    qint64 m_databaseSize;
    qint64 m_deviceSize;
    qint64 m_recommendedSize;

    qint64 calculateDirectorySize(const QString &path);
    qint64 calculateAppSize();
    qint64 calculateDatabaseSize();
    qint64 calculateDeviceSize();

    QString formatSize(qint64 bytes) const;
};

#endif // STORAGEMANAGER_H

















