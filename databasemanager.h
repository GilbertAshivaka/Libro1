#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QMutex>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QCoreApplication>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    bool isdbInitialized() const;

    Q_INVOKABLE int getTotalUsersCount(const QString& userType);

    // static method to obtain a thread-safe database connection
    static QSqlDatabase getConnection();

    //get databasePath since it now lives in the AppData directory
    static QString getDatabasePath();

    bool createDatabase();


public slots:
    void deleteTables();

signals:
    void errorOccured(const QString &error);

private:
    bool dbInitalized = false;

    QSqlDatabase db;
    static QMutex dbMutex;   // mutex for thread safety

    QString dbPath;
    //utility to handle migration, database was initially created in the Application directory instead of ApplicationData directory
    void migrateExistingDatabase(const QString &appDataPath);

};

#endif // DATABASEMANAGER_H
