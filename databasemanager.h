#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QMutex>

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


public slots:
    void deleteTables();

signals:
    void errorOccured(const QString &error);

private:
    bool createDatabase();
    bool dbInitalized = false;

    QSqlDatabase db;
    static QMutex dbMutex;   // mutex for thread safety

};

#endif // DATABASEMANAGER_H
