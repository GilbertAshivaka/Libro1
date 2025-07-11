#ifndef ACTIVITYLOGS_H
#define ACTIVITYLOGS_H

#include <QObject>
#include "databasemanager.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QMutex>
#include <QMutexLocker>

class ActivityLogs : public QObject
{
    Q_OBJECT
public:
    explicit ActivityLogs(QObject *parent = nullptr);

    ~ActivityLogs();

    bool logActivity(const QString &level, const QString &category, const QString &message, const QString &details = QString(), int userId = -1);
    Q_INVOKABLE QList<QVariantMap> getLogs(const QString &level = QString(), const QString &category = QString(), int limit = 100, int offset = 0);
    Q_INVOKABLE int getTotalLogsCount(const QString &level = QString(), const QString &category = QString());

    Q_INVOKABLE bool deleteLogs(int daysToKeep); //delete old logs

    bool executeSystemLogsInsert();

signals:
    void errorOccured(const QString &error);
    void ooperationSuccessful(const QString & message);

private:
    QMutex logsMutex;
    QSqlDatabase db;
};

#endif // ACTIVITYLOGS_H
