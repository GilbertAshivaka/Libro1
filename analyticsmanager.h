#ifndef ANALYTICSMANAGER_H
#define ANALYTICSMANAGER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include "databasemanager.h"

class AnalyticsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList todayActivityData READ todayActivityData NOTIFY todayActivityDataChanged)

public:
    explicit AnalyticsManager(QObject *parent = nullptr);
    ~AnalyticsManager();

    QVariantList todayActivityData() const;

    Q_INVOKABLE void refreshData();

signals:
    void todayActivityDataChanged();
    void errorOccurred(const QString &error);

private slots:
    void updateTodayActivity();

private:
    QVariantList m_todayActivityData;
    QTimer *m_refreshTimer;
    QSqlDatabase db;

    struct HourlyActivity {
        int hour;
        int count;
    };

    QList<HourlyActivity> fetchTodayActivityFromDB();
};

#endif // ANALYTICSMANAGER_H
