#include "analyticsmanager.h"
#include <QDebug>

AnalyticsManager::AnalyticsManager(QObject *parent)
    : QObject{parent}
    , m_refreshTimer(new QTimer(this))
{
    // Get database connection
    db = DatabaseManager::getConnection();

    // Initial data load
    updateTodayActivity();

    // Setup auto-refresh timer (5 minutes = 300000 ms)
    m_refreshTimer->setInterval(300000);
    connect(m_refreshTimer, &QTimer::timeout, this, &AnalyticsManager::updateTodayActivity);
    m_refreshTimer->start();

    qDebug() << "AnalyticsManager initialized with 5-minute auto-refresh";
}

AnalyticsManager::~AnalyticsManager()
{
    if (m_refreshTimer) {
        m_refreshTimer->stop();
    }
}

QVariantList AnalyticsManager::todayActivityData() const
{
    return m_todayActivityData;
}

void AnalyticsManager::refreshData()
{
    qDebug() << "Manual refresh triggered";
    updateTodayActivity();
}

void AnalyticsManager::updateTodayActivity()
{
    QList<HourlyActivity> activities = fetchTodayActivityFromDB();

    // Convert to QVariantList for QML
    QVariantList newData;
    for (const HourlyActivity &activity : activities) {
        QVariantMap point;
        point["hour"] = activity.hour;
        point["count"] = activity.count;
        newData.append(point);
    }

    // Only emit signal if data actually changed
    if (newData != m_todayActivityData) {
        m_todayActivityData = newData;
        emit todayActivityDataChanged();
        qDebug() << "Today's activity data updated:" << m_todayActivityData.size() << "data points";
    }
}

QList<AnalyticsManager::HourlyActivity> AnalyticsManager::fetchTodayActivityFromDB()
{
    QList<HourlyActivity> result;

    if (!db.isOpen()) {
        qWarning() << "Database is not open";
        emit errorOccurred("Database connection is not open");
        return result;
    }

    // Get today's date in the format stored in database
    QString today = QDate::currentDate().toString("yyyy-MM-dd");

    QSqlQuery query(db);

    // Combined query to get both issued and returned books per hour
    QString queryString = R"(
        SELECT
            CAST(strftime('%H', datetime) AS INTEGER) as hour,
            COUNT(*) as count
        FROM (
            -- Books issued today
            SELECT issue_date as datetime
            FROM issued_books
            WHERE DATE(issue_date) = :today

            UNION ALL

            -- Books returned today (from issued_books)
            SELECT return_date as datetime
            FROM issued_books
            WHERE DATE(return_date) = :today

            UNION ALL

            -- Books returned today (from book_return_log)
            SELECT return_date as datetime
            FROM book_return_log
            WHERE DATE(return_date) = :today
        )
        GROUP BY hour
        ORDER BY hour
    )";

    query.prepare(queryString);
    query.bindValue(":today", today);

    if (!query.exec()) {
        qWarning() << "Failed to fetch today's activity:" << query.lastError().text();
        emit errorOccurred("Failed to fetch activity data: " + query.lastError().text());
        return result;
    }

    while (query.next()) {
        HourlyActivity activity;
        activity.hour = query.value(0).toInt();
        activity.count = query.value(1).toInt();
        result.append(activity);
    }

    qDebug() << "Fetched" << result.size() << "hours of activity for today";
    return result;
}
