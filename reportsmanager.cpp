/*
 * ReportsManager - Comprehensive Reports & Analytics Engine
 *
 * This class provides data retrieval and processing for all 10 report categories
 * in the Library Management System. It implements caching for performance and
 * exposes all methods to QML via Q_INVOKABLE.
 *
 * Features:
 * - 10 comprehensive report categories
 * - Intelligent caching with configurable expiry
 * - Thread-safe database operations
 * - Flexible date range filtering
 * - Rich data formatting for charts
 */

#include "reportsmanager.h"
#include "databasemanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QMutexLocker>
#include <QFile>
#include <QDate>
#include <QSqlRecord>
#include "activitylogs.h"

// ============================================================================
// ChartDataModel Implementation
// ============================================================================

ChartDataModel::ChartDataModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ChartDataModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}

QVariant ChartDataModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_data.size())
        return QVariant();

    QVariantMap item = m_data[index.row()].toMap();

    switch (role) {
    case LabelRole: return item.value("label");
    case ValueRole: return item.value("value");
    case PercentageRole: return item.value("percentage");
    case CategoryRole: return item.value("category");
    case SubLabelRole: return item.value("subLabel");
    case XValueRole: return item.value("xValue");
    case YValueRole: return item.value("yValue");
    case SeriesNameRole: return item.value("seriesName");
    case ColorRole: return item.value("color");
    case ExtraDataRole: return item.value("extraData");
    default: return QVariant();
    }
}

QHash<int, QByteArray> ChartDataModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[LabelRole] = "label";
    roles[ValueRole] = "value";
    roles[PercentageRole] = "percentage";
    roles[CategoryRole] = "category";
    roles[SubLabelRole] = "subLabel";
    roles[XValueRole] = "xValue";
    roles[YValueRole] = "yValue";
    roles[SeriesNameRole] = "seriesName";
    roles[ColorRole] = "color";
    roles[ExtraDataRole] = "extraData";
    return roles;
}

void ChartDataModel::setData(const QVariantList &data)
{
    beginResetModel();
    m_data = data;
    endResetModel();
}

void ChartDataModel::clearData()
{
    beginResetModel();
    m_data.clear();
    endResetModel();
}

// ============================================================================
// ReportsManager Implementation
// ============================================================================

ReportsManager::ReportsManager(QObject *parent)
    : QObject(parent)
    , m_isLoading(false)
    , m_cacheEnabled(true)
    , m_cacheExpiryMinutes(5)
{
    // Get database connection
    m_db = DatabaseManager::getConnection();

    if (!m_db.isOpen()) {
        qWarning() << "ReportsManager: Database connection is not open";
        setError("Database connection failed");
    }

    // Set up cache timer for automatic cleanup
    m_cacheTimer = new QTimer(this);
    m_cacheTimer->setInterval(m_cacheExpiryMinutes * 60 * 1000);
    connect(m_cacheTimer, &QTimer::timeout, this, &ReportsManager::invalidateCache);

    if (m_cacheEnabled) {
        m_cacheTimer->start();
    }

    qDebug() << "ReportsManager initialized successfully";
}

ReportsManager::~ReportsManager()
{
    if (m_cacheTimer) {
        m_cacheTimer->stop();
    }
}

void ReportsManager::setCacheEnabled(bool enabled)
{
    if (m_cacheEnabled != enabled) {
        m_cacheEnabled = enabled;

        if (m_cacheEnabled) {
            m_cacheTimer->start();
        } else {
            m_cacheTimer->stop();
            clearCache();
        }

        emit cacheEnabledChanged();
    }
}

// ============================================================================
// HELPER METHODS - Date Range Parsing
// ============================================================================

QPair<QDateTime, QDateTime> ReportsManager::parseDateRange(const QString &dateRange) const
{
    QDateTime endDate = QDateTime::currentDateTime();
    QDateTime startDate;

    if (dateRange == "today") {
        startDate = QDateTime(QDate::currentDate(), QTime(0, 0, 0));
    } else if (dateRange == "yesterday") {
        startDate = QDateTime(QDate::currentDate().addDays(-1), QTime(0, 0, 0));
        endDate = QDateTime(QDate::currentDate(), QTime(0, 0, 0));
    } else if (dateRange == "last7days") {
        startDate = endDate.addDays(-7);
    } else if (dateRange == "last30days") {
        startDate = endDate.addDays(-30);
    } else if (dateRange == "last3months") {
        startDate = endDate.addMonths(-3);
    } else if (dateRange == "last6months") {
        startDate = endDate.addMonths(-6);
    } else if (dateRange == "last12months") {
        startDate = endDate.addMonths(-12);
    } else if (dateRange == "currentMonth") {
        startDate = QDateTime(QDate(endDate.date().year(), endDate.date().month(), 1), QTime(0, 0, 0));
    } else if (dateRange == "currentYear") {
        startDate = QDateTime(QDate(endDate.date().year(), 1, 1), QTime(0, 0, 0));
    } else if (dateRange == "all") {
        startDate = QDateTime(QDate(2000, 1, 1), QTime(0, 0, 0)); // Far past date
    } else {
        // Default to last 30 days
        startDate = endDate.addDays(-30);
    }

    return qMakePair(startDate, endDate);
}

QString ReportsManager::getDateRangeSQL(const QString &dateRange, const QString &dateColumn) const
{
    QPair<QDateTime, QDateTime> range = parseDateRange(dateRange);

    if (dateRange == "all") {
        return ""; // No filter
    }

    return QString("%1 BETWEEN '%2' AND '%3'")
        .arg(dateColumn)
        .arg(range.first.toString("yyyy-MM-dd HH:mm:ss"))
        .arg(range.second.toString("yyyy-MM-dd HH:mm:ss"));
}

// ============================================================================
// HELPER METHODS - Cache Management
// ============================================================================

bool ReportsManager::isCacheValid(const QString &key) const
{
    if (!m_cacheEnabled || !m_cache.contains(key)) {
        return false;
    }

    QVariantMap cached = m_cache.value(key).toMap();
    QDateTime cacheTime = cached.value("timestamp").toDateTime();

    return cacheTime.secsTo(QDateTime::currentDateTime()) < (m_cacheExpiryMinutes * 60);
}

void ReportsManager::setCacheValue(const QString &key, const QVariant &value)
{
    if (!m_cacheEnabled) return;

    QVariantMap cacheEntry;
    cacheEntry["data"] = value;
    cacheEntry["timestamp"] = QDateTime::currentDateTime();

    m_cache[key] = cacheEntry;
    m_lastCacheUpdate = QDateTime::currentDateTime();
    emit lastCacheUpdateChanged();
}

QVariant ReportsManager::getCacheValue(const QString &key) const
{
    if (isCacheValid(key)) {
        return m_cache.value(key).toMap().value("data");
    }
    return QVariant();
}

void ReportsManager::invalidateCache()
{
    m_cache.clear();
    m_lastCacheUpdate = QDateTime();
    emit lastCacheUpdateChanged();
    qDebug() << "ReportsManager: Cache invalidated";
}

void ReportsManager::clearCache()
{
    invalidateCache();
}

void ReportsManager::refreshAllData()
{
    clearCache();
    emit dataRefreshed();
    qDebug() << "ReportsManager: All data refreshed";
}

// ============================================================================
// HELPER METHODS - Error Handling
// ============================================================================

void ReportsManager::setError(const QString &error)
{
    m_lastError = error;
    emit lastErrorChanged();
    emit errorOccurred(error);
    qWarning() << "ReportsManager Error:" << error;
}

void ReportsManager::clearError()
{
    m_lastError.clear();
    emit lastErrorChanged();
}

void ReportsManager::setLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

// ============================================================================
// HELPER METHODS - Database Query Execution
// ============================================================================

QVariantList ReportsManager::executeQueryToList(const QString &queryStr, const QVariantList &bindValues)
{
    QMutexLocker locker(&m_mutex);
    QVariantList result;

    QSqlQuery query(m_db);
    query.prepare(queryStr);

    for (const QVariant &value : bindValues) {
        query.addBindValue(value);
    }

    if (!query.exec()) {
        setError("Query execution failed: " + query.lastError().text());
        qWarning() << "Query failed:" << queryStr;
        qWarning() << "Error:" << query.lastError().text();
        return result;
    }

    // Get column names
    QSqlRecord record = query.record();
    QStringList columnNames;
    for (int i = 0; i < record.count(); ++i) {
        columnNames << record.fieldName(i);
    }

    // Build result list
    while (query.next()) {
        QVariantMap row;
        for (int i = 0; i < columnNames.size(); ++i) {
            row[columnNames[i]] = query.value(i);
        }
        result.append(row);
    }

    return result;
}

int ReportsManager::executeCountQuery(const QString &queryStr, const QVariantList &bindValues)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare(queryStr);

    for (const QVariant &value : bindValues) {
        query.addBindValue(value);
    }

    if (!query.exec()) {
        setError("Count query failed: " + query.lastError().text());
        return 0;
    }

    if (query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

double ReportsManager::executeAverageQuery(const QString &queryStr, const QVariantList &bindValues)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare(queryStr);

    for (const QVariant &value : bindValues) {
        query.addBindValue(value);
    }

    if (!query.exec()) {
        setError("Average query failed: " + query.lastError().text());
        return 0.0;
    }

    if (query.next()) {
        return query.value(0).toDouble();
    }

    return 0.0;
}

double ReportsManager::executeSumQuery(const QString &queryStr, const QVariantList &bindValues)
{
    QMutexLocker locker(&m_mutex);

    QSqlQuery query(m_db);
    query.prepare(queryStr);

    for (const QVariant &value : bindValues) {
        query.addBindValue(value);
    }

    if (!query.exec()) {
        setError("Sum query failed: " + query.lastError().text());
        return 0.0;
    }

    if (query.next()) {
        return query.value(0).toDouble();
    }

    return 0.0;
}

// ============================================================================
// HELPER METHODS - Data Formatting
// ============================================================================

QString ReportsManager::formatCurrency(double value) const
{
    return QString("$%1").arg(value, 0, 'f', 2);
}

QString ReportsManager::formatPercentage(double value) const
{
    return QString("%1%").arg(value, 0, 'f', 1);
}

QString ReportsManager::formatDate(const QDateTime &date) const
{
    return date.toString("yyyy-MM-dd");
}

QVariantMap ReportsManager::createStatCard(const QString &label, const QVariant &value, const QString &unit, const QString &trend) const
{
    QVariantMap card;
    card["label"] = label;
    card["value"] = value;
    card["unit"] = unit;
    card["trend"] = trend;
    return card;
}

// ============================================================================
// UTILITY METHODS
// ============================================================================

QString ReportsManager::getDatabaseSize()
{
    QFile dbFile(DatabaseManager::getDatabasePath());
    if (dbFile.exists()) {
        qint64 sizeBytes = dbFile.size();
        double sizeMB = sizeBytes / (1024.0 * 1024.0);
        return QString("%1 MB").arg(sizeMB, 0, 'f', 2);
    }
    return "0 MB";
}

QVariantList ReportsManager::getAvailableGenres()
{
    QString cacheKey = "available_genres";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT DISTINCT genre FROM books WHERE genre IS NOT NULL AND genre != '' ORDER BY genre";
    QVariantList result = executeQueryToList(query);

    QVariantList genres;
    genres.append(QVariantMap{{"value", "all"}, {"label", "All Genres"}});

    for (const QVariant &item : result) {
        QVariantMap row = item.toMap();
        QString genre = row["genre"].toString();
        genres.append(QVariantMap{{"value", genre}, {"label", genre}});
    }

    setCacheValue(cacheKey, genres);
    return genres;
}

QVariantList ReportsManager::getAvailableLanguages()
{
    QString cacheKey = "available_languages";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT DISTINCT language FROM books WHERE language IS NOT NULL AND language != '' ORDER BY language";
    QVariantList result = executeQueryToList(query);

    QVariantList languages;
    languages.append(QVariantMap{{"value", "all"}, {"label", "All Languages"}});

    for (const QVariant &item : result) {
        QVariantMap row = item.toMap();
        QString language = row["language"].toString();
        languages.append(QVariantMap{{"value", language}, {"label", language}});
    }

    setCacheValue(cacheKey, languages);
    return languages;
}

QVariantList ReportsManager::getAvailableUserTypes()
{
    QVariantList userTypes;
    userTypes.append(QVariantMap{{"value", "all"}, {"label", "All Users"}});
    userTypes.append(QVariantMap{{"value", "Student"}, {"label", "Students"}});
    userTypes.append(QVariantMap{{"value", "Staff"}, {"label", "Staff"}});
    userTypes.append(QVariantMap{{"value", "Other"}, {"label", "Other Users"}});
    return userTypes;
}

// ============================================================================
// CATEGORY 1: COLLECTION OVERVIEW & STATISTICS
// ============================================================================

QVariantMap ReportsManager::getCollectionStats()
{
    QString cacheKey = "collection_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Total books
    stats["totalBooks"] = executeCountQuery("SELECT COUNT(*) FROM books");

    // Available books
    stats["availableBooks"] = executeCountQuery("SELECT COUNT(*) FROM books WHERE availability = 'Available'");

    // Books added this month
    QString thisMonth = QDate::currentDate().toString("yyyy-MM");
    stats["booksAddedThisMonth"] = executeCountQuery(
        "SELECT COUNT(*) FROM books WHERE strftime('%Y-%m', dateAdded) = ?",
        {thisMonth}
        );

    // Average book value
    stats["averageBookValue"] = executeAverageQuery("SELECT AVG(value) FROM books WHERE value > 0");

    // Books in good condition
    stats["booksInGoodCondition"] = executeCountQuery("SELECT COUNT(*) FROM books WHERE condition = 'Good'");

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getBooksByGenreDistribution(const QString &dateRange)
{
    QString cacheKey = QString("books_by_genre_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT genre, COUNT(*) as count FROM books WHERE genre IS NOT NULL AND genre != ''";

    if (dateRange != "all") {
        QString dateFilter = getDateRangeSQL(dateRange, "dateAdded");
        if (!dateFilter.isEmpty()) {
            query += " AND " + dateFilter;
        }
    }

    query += " GROUP BY genre ORDER BY count DESC";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["genre"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getBooksByPublicationYear(int topN)
{
    QString cacheKey = QString("books_by_year_top%1").arg(topN);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString(
                        "SELECT year_published, COUNT(*) as count FROM books "
                        "WHERE year_published IS NOT NULL AND year_published != '' "
                        "GROUP BY year_published ORDER BY year_published DESC LIMIT %1"
                        ).arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["category"] = row["year_published"];
        chartData["value"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getBookAvailabilityStatus()
{
    QString cacheKey = "book_availability_status";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT availability, COUNT(*) as count FROM books GROUP BY availability";
    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["availability"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getTopBorrowedBooks(int topN, const QString &genre, const QString &language)
{
    QString cacheKey = QString("top_borrowed_books_%1_%2_%3").arg(topN).arg(genre).arg(language);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString("SELECT title, author, timesBorrowed FROM books WHERE timesBorrowed > 0");

    if (genre != "all") {
        query += QString(" AND genre = '%1'").arg(genre);
    }
    if (language != "all") {
        query += QString(" AND language = '%1'").arg(language);
    }

    query += QString(" ORDER BY timesBorrowed DESC LIMIT %1").arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["title"].toString();
        chartData["subLabel"] = row["author"].toString();
        chartData["value"] = row["timesBorrowed"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getCollectionMetrics(const QString &dateRange, const QString &genre, const QString &language)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total, AVG(value) as avgValue, SUM(timesBorrowed) as totalBorrows FROM books WHERE 1=1";

    if (dateRange != "all") {
        QString dateFilter = getDateRangeSQL(dateRange, "dateAdded");
        if (!dateFilter.isEmpty()) {
            query += " AND " + dateFilter;
        }
    }
    if (genre != "all") {
        query += QString(" AND genre = '%1'").arg(genre);
    }
    if (language != "all") {
        query += QString(" AND language = '%1'").arg(language);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        QVariantMap data = result.first().toMap();
        metrics["totalBooks"] = data["total"];
        metrics["averageValue"] = data["avgValue"];
        metrics["totalBorrows"] = data["totalBorrows"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 2: CIRCULATION ANALYTICS
// ============================================================================

QVariantMap ReportsManager::getCirculationStats(const QString &dateRange)
{
    QString cacheKey = QString("circulation_stats_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;
    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");

    // Books currently on loan
    stats["currentlyOnLoan"] = executeCountQuery("SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed'");

    // Books due today
    QString today = QDate::currentDate().toString("yyyy-MM-dd");
    stats["dueToday"] = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND DATE(due_date) = ?",
        {today}
        );

    // Books due this week
    QString weekLater = QDate::currentDate().addDays(7).toString("yyyy-MM-dd");
    stats["dueThisWeek"] = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND DATE(due_date) BETWEEN ? AND ?",
        {today, weekLater}
        );

    // Total circulations in date range
    QString circulationQuery = "SELECT COUNT(*) FROM issued_books WHERE 1=1";
    if (!dateFilter.isEmpty()) {
        circulationQuery += " AND " + dateFilter;
    }
    stats["totalCirculations"] = executeCountQuery(circulationQuery);

    // Average loan duration
    stats["averageLoanDuration"] = executeAverageQuery(
        "SELECT AVG(JULIANDAY(return_date) - JULIANDAY(issue_date)) FROM issued_books WHERE return_date IS NOT NULL"
        );

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getBorrowingTrends(const QString &dateRange, const QString &groupBy)
{
    QString cacheKey = QString("borrowing_trends_%1_%2").arg(dateRange).arg(groupBy);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString dateFormat;
    if (groupBy == "day") {
        dateFormat = "%Y-%m-%d";
    } else if (groupBy == "week") {
        dateFormat = "%Y-W%W";
    } else if (groupBy == "month") {
        dateFormat = "%Y-%m";
    } else {
        dateFormat = "%Y-%m-%d";
    }

    QString query = QString(
                        "SELECT strftime('%1', issue_date) as period, COUNT(*) as count "
                        "FROM issued_books WHERE 1=1"
                        ).arg(dateFormat);

    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY period ORDER BY period";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["period"];
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getBorrowingTrendsByUserType(const QString &dateRange)
{
    QString cacheKey = QString("borrowing_by_usertype_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m-%d', ib.issue_date) as date, u.user_role, COUNT(*) as count "
        "FROM issued_books ib "
        "JOIN users u ON ib.user_id = u.user_id WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "ib.issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY date, u.user_role ORDER BY date, u.user_role";

    QVariantList result = executeQueryToList(query);
    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getBorrowingByDayOfWeek(const QString &dateRange)
{
    QString cacheKey = QString("borrowing_by_dayofweek_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT "
        "CASE CAST(strftime('%w', issue_date) AS INTEGER) "
        "WHEN 0 THEN 'Sunday' WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' "
        "WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday' "
        "WHEN 6 THEN 'Saturday' END as day_name, "
        "COUNT(*) as count FROM issued_books WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY strftime('%w', issue_date) ORDER BY strftime('%w', issue_date)";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["category"] = row["day_name"];
        chartData["value"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);

    qDebug() << "Result: " << result;
    return result;
}

QVariantList ReportsManager::getMonthlyCirculation(const QString &dateRange)
{
    QString cacheKey = QString("monthly_circulation_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }
    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");
    // Get issues per month
    QString issuesQuery =
        "SELECT strftime('%Y-%m', issue_date) as month, COUNT(*) as issues "
        "FROM issued_books WHERE 1=1";
    if (!dateFilter.isEmpty()) {
        issuesQuery += " AND " + dateFilter;
    }
    issuesQuery += " GROUP BY month";
    // Get returns per month
    QString returnsQuery =
        "SELECT strftime('%Y-%m', return_date) as month, COUNT(*) as returns "
        "FROM issued_books WHERE return_date IS NOT NULL";
    QString returnDateFilter = getDateRangeSQL(dateRange, "return_date");
    if (!returnDateFilter.isEmpty()) {
        returnsQuery += " AND " + returnDateFilter;
    }
    returnsQuery += " GROUP BY month";
    QVariantList issuesData = executeQueryToList(issuesQuery);
    QVariantList returnsData = executeQueryToList(returnsQuery);
    // Combine data
    QMap<QString, QVariantMap> combined;
    for (const QVariant &item : issuesData) {
        QVariantMap row = item.toMap();
        QString month = row["month"].toString();
        combined[month]["month"] = month;
        combined[month]["issues"] = row["issues"];
        combined[month]["returns"] = 0;
    }
    for (const QVariant &item : returnsData) {
        QVariantMap row = item.toMap();
        QString month = row["month"].toString();
        if (!combined.contains(month)) {
            combined[month]["month"] = month;
            combined[month]["issues"] = 0;
        }
        combined[month]["returns"] = row["returns"];
    }

    // Convert QList<QVariantMap> to QVariantList
    QVariantList result;
    for (const QVariantMap &map : combined.values()) {
        result.append(map);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getCirculationMetrics(const QString &dateRange, const QString &userType, const QString &genre)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total FROM issued_books ib";

    bool needsJoin = (userType != "all" || genre != "all");
    if (needsJoin) {
        if (userType != "all") query += " JOIN users u ON ib.user_id = u.user_id";
        if (genre != "all") query += " JOIN books b ON ib.book_id = b.bookID";
    }

    query += " WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "ib.issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }
    if (userType != "all") {
        query += QString(" AND u.user_role = '%1'").arg(userType);
    }
    if (genre != "all") {
        query += QString(" AND b.genre = '%1'").arg(genre);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        metrics["totalCirculations"] = result.first().toMap()["total"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 3: USER ENGAGEMENT & DEMOGRAPHICS
// ============================================================================

QVariantMap ReportsManager::getUserEngagementStats()
{
    QString cacheKey = "user_engagement_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Total registered users
    stats["totalUsers"] = executeCountQuery("SELECT COUNT(*) FROM users");

    // Active users (borrowed in last 30 days)
    QString last30Days = QDateTime::currentDateTime().addDays(-30).toString("yyyy-MM-dd HH:mm:ss");
    stats["activeUsers"] = executeCountQuery(
        "SELECT COUNT(DISTINCT user_id) FROM issued_books WHERE issue_date >= ?",
        {last30Days}
        );

    // Inactive users (no borrows in last 90 days)
    QString last90Days = QDateTime::currentDateTime().addDays(-90).toString("yyyy-MM-dd HH:mm:ss");
    QString inactiveQuery =
        "SELECT COUNT(*) FROM users WHERE user_id NOT IN "
        "(SELECT DISTINCT user_id FROM issued_books WHERE issue_date >= ?)";
    stats["inactiveUsers"] = executeCountQuery(inactiveQuery, {last90Days});

    // New users this month
    QString thisMonth = QDate::currentDate().toString("yyyy-MM");
    stats["newUsersThisMonth"] = executeCountQuery(
        "SELECT COUNT(*) FROM users WHERE strftime('%Y-%m', created_at) = ?",
        {thisMonth}
        );

    // Average books per user
    stats["averageBooksPerUser"] = executeAverageQuery(
        "SELECT COUNT(*) FROM issued_books GROUP BY user_id"
        );

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getUserDistributionByType()
{
    QString cacheKey = "user_distribution_by_type";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT user_role, COUNT(*) as count FROM users GROUP BY user_role";
    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["user_role"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getTopActiveBorrowers(int topN, const QString &userType)
{
    QString cacheKey = QString("top_borrowers_%1_%2").arg(topN).arg(userType);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT u.first_name || ' ' || u.second_name as name, u.user_role, COUNT(*) as borrow_count "
        "FROM issued_books ib "
        "JOIN users u ON ib.user_id = u.user_id WHERE 1=1";

    if (userType != "all") {
        query += QString(" AND u.user_role = '%1'").arg(userType);
    }

    query += QString(" GROUP BY ib.user_id ORDER BY borrow_count DESC LIMIT %1").arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["name"];
        chartData["subLabel"] = row["user_role"];
        chartData["value"] = row["borrow_count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getNewUserRegistrations(const QString &dateRange)
{
    QString cacheKey = QString("new_registrations_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', created_at) as month, COUNT(*) as count "
        "FROM users WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "created_at");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["month"];
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getBorrowingActivityByUserCategory()
{
    QString cacheKey = "borrowing_activity_by_category";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString last30Days = QDateTime::currentDateTime().addDays(-30).toString("yyyy-MM-dd HH:mm:ss");

    QString query =
        "SELECT u.user_role, "
        "COUNT(DISTINCT u.user_id) as total_users, "
        "COUNT(DISTINCT CASE WHEN ib.issue_date >= ? THEN ib.user_id END) as active_users "
        "FROM users u "
        "LEFT JOIN issued_books ib ON u.user_id = ib.user_id "
        "GROUP BY u.user_role";

    QVariantList result = executeQueryToList(query, {last30Days});
    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getUserEngagementMetrics(const QString &dateRange, const QString &userType, const QString &status)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total FROM users WHERE 1=1";

    if (userType != "all") {
        query += QString(" AND user_role = '%1'").arg(userType);
    }
    if (status != "all") {
        query += QString(" AND status = '%1'").arg(status);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        metrics["totalUsers"] = result.first().toMap()["total"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 4: FINANCIAL REPORTS
// ============================================================================

QVariantMap ReportsManager::getFinancialStats(const QString &dateRange)
{
    QString cacheKey = QString("financial_stats_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;
    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");

    // Total fines generated
    QString fineQuery = "SELECT SUM(fine_amount) FROM issued_books WHERE fine_amount > 0";
    if (!dateFilter.isEmpty()) {
        fineQuery += " AND " + dateFilter;
    }
    stats["totalFinesGenerated"] = executeSumQuery(fineQuery);

    // Total fines collected
    QString paidQuery = "SELECT SUM(fine_paid) FROM issued_books WHERE fine_paid > 0";
    if (!dateFilter.isEmpty()) {
        QString paidFilter = getDateRangeSQL(dateRange, "fine_paid_date");
        if (!paidFilter.isEmpty()) {
            paidQuery += " AND " + paidFilter;
        }
    }
    stats["totalFinesCollected"] = executeSumQuery(paidQuery);

    // Outstanding fines
    stats["outstandingFines"] = executeSumQuery(
        "SELECT SUM(fine_amount - fine_paid) FROM issued_books WHERE fine_amount > fine_paid"
        );

    // Lost books replacement cost
    stats["lostBooksReplacementCost"] = executeSumQuery(
        "SELECT SUM(replacement_cost) FROM lost_books WHERE status = 'Lost'"
        );

    // Average fine per overdue
    stats["averageFinePerOverdue"] = executeAverageQuery(
        "SELECT fine_amount FROM issued_books WHERE fine_amount > 0"
        );

    // Fine collection rate
    double generated = stats["totalFinesGenerated"].toDouble();
    double collected = stats["totalFinesCollected"].toDouble();
    stats["fineCollectionRate"] = generated > 0 ? (collected / generated * 100.0) : 0.0;

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getFineCollectionOverTime(const QString &dateRange)
{
    QString cacheKey = QString("fine_collection_time_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', fine_paid_date) as month, SUM(fine_paid) as total "
        "FROM issued_books WHERE fine_paid > 0 AND fine_paid_date IS NOT NULL";

    QString dateFilter = getDateRangeSQL(dateRange, "fine_paid_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["month"];
        chartData["yValue"] = row["total"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getFineAmountVsPaid(const QString &dateRange)
{
    QString cacheKey = QString("fine_amount_vs_paid_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', issue_date) as month, "
        "SUM(fine_amount) as generated, SUM(fine_paid) as paid "
        "FROM issued_books WHERE fine_amount > 0";

    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList result = executeQueryToList(query);
    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getFinePaymentStatus()
{
    QString cacheKey = "fine_payment_status";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QVariantList result;

    // No fine
    int noFine = executeCountQuery("SELECT COUNT(*) FROM issued_books WHERE fine_amount = 0");

    // Fully paid
    int fullyPaid = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE fine_amount > 0 AND fine_amount = fine_paid"
        );

    // Partially paid
    int partiallyPaid = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE fine_amount > 0 AND fine_paid > 0 AND fine_paid < fine_amount"
        );

    // Unpaid
    int unpaid = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE fine_amount > 0 AND fine_paid = 0"
        );

    int total = noFine + fullyPaid + partiallyPaid + unpaid;

    result.append(QVariantMap{{"label", "No Fine"}, {"value", noFine},
                              {"percentage", total > 0 ? (noFine * 100.0 / total) : 0.0}});
    result.append(QVariantMap{{"label", "Fully Paid"}, {"value", fullyPaid},
                              {"percentage", total > 0 ? (fullyPaid * 100.0 / total) : 0.0}});
    result.append(QVariantMap{{"label", "Partially Paid"}, {"value", partiallyPaid},
                              {"percentage", total > 0 ? (partiallyPaid * 100.0 / total) : 0.0}});
    result.append(QVariantMap{{"label", "Unpaid"}, {"value", unpaid},
                              {"percentage", total > 0 ? (unpaid * 100.0 / total) : 0.0}});

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getLostBookCostsByMonth(const QString &dateRange)
{
    QString cacheKey = QString("lost_book_costs_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', reported_lost_date) as month, SUM(replacement_cost) as total "
        "FROM lost_books WHERE replacement_cost > 0";

    QString dateFilter = getDateRangeSQL(dateRange, "reported_lost_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["category"] = row["month"];
        chartData["value"] = row["total"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getFinancialMetrics(const QString &dateRange, const QString &userType, const QString &paymentStatus)
{
    QVariantMap metrics;

    QString query = "SELECT SUM(fine_amount) as generated, SUM(fine_paid) as paid FROM issued_books ib";

    if (userType != "all") {
        query += " JOIN users u ON ib.user_id = u.user_id";
    }

    query += " WHERE fine_amount > 0";

    QString dateFilter = getDateRangeSQL(dateRange, "ib.issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }
    if (userType != "all") {
        query += QString(" AND u.user_role = '%1'").arg(userType);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        QVariantMap data = result.first().toMap();
        metrics["totalGenerated"] = data["generated"];
        metrics["totalPaid"] = data["paid"];
        metrics["outstanding"] = data["generated"].toDouble() - data["paid"].toDouble();
    }

    return metrics;
}

// ============================================================================
// CATEGORY 5: OVERDUE & COMPLIANCE
// ============================================================================

QVariantMap ReportsManager::getOverdueStats()
{
    QString cacheKey = "overdue_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;
    QString today = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    // Total overdue books
    stats["totalOverdue"] = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND due_date < ?",
        {today}
        );

    // Longest overdue (in days)
    QString longestQuery =
        "SELECT MAX(JULIANDAY(?) - JULIANDAY(due_date)) FROM issued_books "
        "WHERE status = 'Borrowed' AND due_date < ?";
    stats["longestOverdueDays"] = executeAverageQuery(longestQuery, {today, today});

    // Average days overdue
    QString avgQuery =
        "SELECT AVG(JULIANDAY(?) - JULIANDAY(due_date)) FROM issued_books "
        "WHERE status = 'Borrowed' AND due_date < ?";
    stats["averageDaysOverdue"] = executeAverageQuery(avgQuery, {today, today});

    // Books 30+ days overdue
    QString days30Ago = QDateTime::currentDateTime().addDays(-30).toString("yyyy-MM-dd HH:mm:ss");
    stats["overdue30Plus"] = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND due_date < ?",
        {days30Ago}
        );

    // Overdue rate
    int totalBorrowed = executeCountQuery("SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed'");
    int overdue = stats["totalOverdue"].toInt();
    stats["overdueRate"] = totalBorrowed > 0 ? (overdue * 100.0 / totalBorrowed) : 0.0;

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getOverdueBooksByDaysRange()
{
    QString cacheKey = "overdue_by_days_range";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString today = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    QVariantList result;

    // 0-7 days
    QString range1 = QDateTime::currentDateTime().addDays(-7).toString("yyyy-MM-dd HH:mm:ss");
    int count1 = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND due_date < ? AND due_date >= ?",
        {today, range1}
        );

    // 8-14 days
    QString range2 = QDateTime::currentDateTime().addDays(-14).toString("yyyy-MM-dd HH:mm:ss");
    int count2 = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND due_date < ? AND due_date >= ?",
        {range1, range2}
        );

    // 15-30 days
    QString range3 = QDateTime::currentDateTime().addDays(-30).toString("yyyy-MM-dd HH:mm:ss");
    int count3 = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND due_date < ? AND due_date >= ?",
        {range2, range3}
        );

    // 30+ days
    int count4 = executeCountQuery(
        "SELECT COUNT(*) FROM issued_books WHERE status = 'Borrowed' AND due_date < ?",
        {range3}
        );

    result.append(QVariantMap{{"category", "0-7 days"}, {"value", count1}});
    result.append(QVariantMap{{"category", "8-14 days"}, {"value", count2}});
    result.append(QVariantMap{{"category", "15-30 days"}, {"value", count3}});
    result.append(QVariantMap{{"category", "30+ days"}, {"value", count4}});

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getOverdueTrendOverMonths(const QString &dateRange)
{
    QString cacheKey = QString("overdue_trend_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    // This shows count of overdue books at the end of each month
    QString query =
        "SELECT strftime('%Y-%m', due_date) as month, COUNT(*) as count "
        "FROM issued_books WHERE status = 'Borrowed' AND due_date < datetime('now')";

    QString dateFilter = getDateRangeSQL(dateRange, "due_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["month"];
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getUsersWithMostOverdue(int topN, const QString &userType)
{
    QString cacheKey = QString("users_most_overdue_%1_%2").arg(topN).arg(userType);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString today = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    QString query =
        "SELECT u.first_name || ' ' || u.second_name as name, u.user_role, COUNT(*) as overdue_count "
        "FROM issued_books ib "
        "JOIN users u ON ib.user_id = u.user_id "
        "WHERE ib.status = 'Borrowed' AND ib.due_date < ?";

    if (userType != "all") {
        query += QString(" AND u.user_role = '%1'").arg(userType);
    }

    query += QString(" GROUP BY ib.user_id ORDER BY overdue_count DESC LIMIT %1").arg(topN);

    QVariantList rawData = executeQueryToList(query, {today});
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["name"];
        chartData["subLabel"] = row["user_role"];
        chartData["value"] = row["overdue_count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getOverdueBooksByUserType()
{
    QString cacheKey = "overdue_by_user_type";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString today = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    QString query =
        "SELECT u.user_role, COUNT(*) as count "
        "FROM issued_books ib "
        "JOIN users u ON ib.user_id = u.user_id "
        "WHERE ib.status = 'Borrowed' AND ib.due_date < ? "
        "GROUP BY u.user_role";

    QVariantList rawData = executeQueryToList(query, {today});
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["user_role"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getOverdueMetrics(const QString &daysRange, const QString &userType, const QString &genre)
{
    QVariantMap metrics;

    QString today = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    QString query = "SELECT COUNT(*) as total FROM issued_books ib";

    bool needsUserJoin = (userType != "all");
    bool needsBookJoin = (genre != "all");

    if (needsUserJoin) query += " JOIN users u ON ib.user_id = u.user_id";
    if (needsBookJoin) query += " JOIN books b ON ib.book_id = b.bookID";

    query += " WHERE ib.status = 'Borrowed' AND ib.due_date < ?";

    QVariantList bindValues = {today};

    if (userType != "all") {
        query += QString(" AND u.user_role = '%1'").arg(userType);
    }
    if (genre != "all") {
        query += QString(" AND b.genre = '%1'").arg(genre);
    }

    QVariantList result = executeQueryToList(query, bindValues);
    if (!result.isEmpty()) {
        metrics["totalOverdue"] = result.first().toMap()["total"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 6: LOST & DAMAGED BOOKS
// ============================================================================

QVariantMap ReportsManager::getLostDamagedStats()
{
    QString cacheKey = "lost_damaged_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Total lost books (all time)
    stats["totalLostBooks"] = executeCountQuery("SELECT COUNT(*) FROM lost_books");

    // Lost books this year
    QString thisYear = QString::number(QDate::currentDate().year());
    stats["lostBooksThisYear"] = executeCountQuery(
        "SELECT COUNT(*) FROM lost_books WHERE strftime('%Y', reported_lost_date) = ?",
        {thisYear}
        );

    // Total replacement cost outstanding
    stats["replacementCostOutstanding"] = executeSumQuery(
        "SELECT SUM(replacement_cost) FROM lost_books WHERE status = 'Lost'"
        );

    // Books marked as damaged
    stats["damagedBooks"] = executeCountQuery(
        "SELECT COUNT(*) FROM books WHERE condition != 'Good' AND condition IS NOT NULL"
        );

    // Loss rate (percentage of collection)
    int totalBooks = executeCountQuery("SELECT COUNT(*) FROM books");
    int lostBooks = stats["totalLostBooks"].toInt();
    stats["lossRate"] = totalBooks > 0 ? (lostBooks * 100.0 / totalBooks) : 0.0;

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getLostBooksOverTime(const QString &dateRange)
{
    QString cacheKey = QString("lost_books_time_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', reported_lost_date) as month, COUNT(*) as count "
        "FROM lost_books WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "reported_lost_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["month"];
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getLostBooksByGenre()
{
    QString cacheKey = "lost_books_by_genre";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT b.genre, COUNT(*) as count "
        "FROM lost_books lb "
        "JOIN books b ON lb.book_id = b.bookID "
        "WHERE b.genre IS NOT NULL AND b.genre != '' "
        "GROUP BY b.genre ORDER BY count DESC";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["category"] = row["genre"];
        chartData["value"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getLostBookResolutionStatus()
{
    QString cacheKey = "lost_book_resolution_status";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT COALESCE(resolution_type, 'Pending') as resolution, COUNT(*) as count "
        "FROM lost_books GROUP BY resolution";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["resolution"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getUsersWithLostBooks(int topN)
{
    QString cacheKey = QString("users_lost_books_%1").arg(topN);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString(
                        "SELECT user_name, user_role, COUNT(*) as lost_count "
                        "FROM lost_books "
                        "GROUP BY user_id ORDER BY lost_count DESC LIMIT %1"
                        ).arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["user_name"];
        chartData["subLabel"] = row["user_role"];
        chartData["value"] = row["lost_count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getLostDamagedMetrics(const QString &dateRange, const QString &resolutionStatus,
                                                  const QString &userType, const QString &genre)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total, SUM(replacement_cost) as totalCost FROM lost_books WHERE 1=1";

    if (dateRange != "all") {
        QString dateFilter = getDateRangeSQL(dateRange, "reported_lost_date");
        if (!dateFilter.isEmpty()) {
            query += " AND " + dateFilter;
        }
    }
    if (resolutionStatus != "all") {
        query += QString(" AND resolution_type = '%1'").arg(resolutionStatus);
    }
    if (userType != "all") {
        query += QString(" AND user_role = '%1'").arg(userType);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        QVariantMap data = result.first().toMap();
        metrics["totalLost"] = data["total"];
        metrics["totalCost"] = data["totalCost"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 7: RESERVATION ANALYTICS
// ============================================================================

QVariantMap ReportsManager::getReservationStats()
{
    QString cacheKey = "reservation_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Active reservations
    stats["activeReservations"] = executeCountQuery(
        "SELECT COUNT(*) FROM reserved_books WHERE status = 'pending'"
        );

    // Average wait time (days between reservation and pickup)
    stats["averageWaitTime"] = executeAverageQuery(
        "SELECT JULIANDAY(notification_sent_date) - JULIANDAY(reservation_date) "
        "FROM reserved_books WHERE notification_sent_date IS NOT NULL"
        );

    // Reservation fulfillment rate
    int total = executeCountQuery("SELECT COUNT(*) FROM reserved_books");
    int fulfilled = executeCountQuery("SELECT COUNT(*) FROM reserved_books WHERE status = 'fulfilled'");
    stats["fulfillmentRate"] = total > 0 ? (fulfilled * 100.0 / total) : 0.0;

    // Expired reservations
    stats["expiredReservations"] = executeCountQuery(
        "SELECT COUNT(*) FROM reserved_books WHERE status = 'expired'"
        );

    // Books with pending reservations
    stats["booksWithPendingReservations"] = executeCountQuery(
        "SELECT COUNT(DISTINCT book_id) FROM reserved_books WHERE status = 'pending'"
        );

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

// QVariantList ReportsManager::getReservationsOverTime(const QString &dateRange)
// {
//     QString cacheKey = QString("reservations_time_%1").arg(dateRange);
//     if (isCacheValid(cacheKey)) {
//         return getCacheValue(cacheKey).toList();
//     }

//     QString query =
//         "SELECT strftime('%Y-%m', reservation_date) as month, COUNT(*) as count "
//         "FROM reserved_books WHERE 1=1";

//     QString dateFilter = getDateRangeSQL(dateRange, "reservation_date");
//     if (!dateFilter.isEmpty()) {
//         query += " AND " + dateFilter;
//     }

//     query += " GROUP BY month ORDER BY month";

//     QVariantList rawData = executeQueryToList(query);
//     QVariantList result;

//     for (const QVariant &item : rawData) {
//         QVariantMap row = item.toMap();

//         QVariantMap chartData;
//         chartData["xValue"] = row["month"];
//         chartData["yValue"] = row["count"];
//         result.append(chartData);
//     }

//     setCacheValue(cacheKey, result);
//     return result;
// }

QVariantList ReportsManager::getReservationsOverTime(const QString &dateRange)
{
    QString cacheKey = QString("reservations_time_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m-%d', reservation_date) as date, COUNT(*) as count "
        "FROM reserved_books WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "reservation_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    // Group by first day of month
    query =
        "SELECT date(reservation_date, 'start of month') as date, COUNT(*) as count "
        "FROM reserved_books WHERE 1=1";

    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY date ORDER BY date";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["date"];  // Now returns "2025-11-01" format
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}


QVariantList ReportsManager::getMostReservedBooks(int topN)
{
    QString cacheKey = QString("most_reserved_books_%1").arg(topN);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString(
                        "SELECT b.title, b.author, COUNT(*) as reservation_count "
                        "FROM reserved_books rb "
                        "JOIN books b ON rb.book_id = b.bookID "
                        "GROUP BY rb.book_id ORDER BY reservation_count DESC LIMIT %1"
                        ).arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["title"];
        chartData["subLabel"] = row["author"];
        chartData["value"] = row["reservation_count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getReservationStatusDistribution()
{
    QString cacheKey = "reservation_status_dist";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT status, COUNT(*) as count FROM reserved_books GROUP BY status";
    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["status"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getReservationSource()
{
    QString cacheKey = "reservation_source";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT source, COUNT(*) as count FROM reserved_books GROUP BY source";
    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["source"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getReservationMetrics(const QString &dateRange, const QString &status, const QString &source)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total FROM reserved_books WHERE 1=1";

    if (dateRange != "all") {
        QString dateFilter = getDateRangeSQL(dateRange, "reservation_date");
        if (!dateFilter.isEmpty()) {
            query += " AND " + dateFilter;
        }
    }
    if (status != "all") {
        query += QString(" AND status = '%1'").arg(status);
    }
    if (source != "all") {
        query += QString(" AND source = '%1'").arg(source);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        metrics["totalReservations"] = result.first().toMap()["total"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 8: DIGITAL MATERIALS & EQUIPMENT
// ============================================================================

QVariantMap ReportsManager::getDigitalMaterialsStats()
{
    QString cacheKey = "digital_materials_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Total digital items
    stats["totalItems"] = executeSumQuery("SELECT SUM(quantity) FROM digital_materials");

    // Items currently on loan
    stats["currentlyOnLoan"] = executeSumQuery("SELECT SUM(quantityBorrowed) FROM digital_materials");

    // Most popular resource type
    QString query =
        "SELECT ItemType FROM digital_materials_loans "
        "GROUP BY item_id ORDER BY COUNT(*) DESC LIMIT 1";
    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        stats["mostPopularType"] = result.first().toMap().value("ItemType", "N/A");
    } else {
        stats["mostPopularType"] = "N/A";
    }

    // Average loan duration
    stats["averageLoanDuration"] = executeAverageQuery(
        "SELECT JULIANDAY(return_date) - JULIANDAY(issue_date) "
        "FROM digital_materials_loans WHERE return_date IS NOT NULL"
        );

    // Utilization rate
    double total = stats["totalItems"].toDouble();
    double onLoan = stats["currentlyOnLoan"].toDouble();
    stats["utilizationRate"] = total > 0 ? (onLoan / total * 100.0) : 0.0;

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getDigitalMaterialsByType()
{
    QString cacheKey = "digital_materials_by_type";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT ItemType, SUM(quantity) as total FROM digital_materials GROUP BY ItemType";
    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["total"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["ItemType"];
        chartData["value"] = row["total"];
        chartData["percentage"] = total > 0 ? (row["total"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getMostBorrowedDigitalItems(int topN)
{
    QString cacheKey = QString("most_borrowed_digital_%1").arg(topN);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString(
                        "SELECT item_name, COUNT(*) as loan_count "
                        "FROM digital_materials_loans "
                        "GROUP BY item_id ORDER BY loan_count DESC LIMIT %1"
                        ).arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["item_name"];
        chartData["value"] = row["loan_count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getDigitalMaterialLoansOverTime(const QString &dateRange)
{
    QString cacheKey = QString("digital_loans_time_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', issue_date) as month, COUNT(*) as count "
        "FROM digital_materials_loans WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month ORDER BY month";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["month"];
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getDigitalMaterialsAvailableVsBorrowed()
{
    QString cacheKey = "digital_available_vs_borrowed";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT ItemType, SUM(quantity) as total, SUM(quantityBorrowed) as borrowed "
        "FROM digital_materials GROUP BY ItemType";

    QVariantList result = executeQueryToList(query);
    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getDigitalMaterialsMetrics(const QString &itemType, const QString &status, const QString &dateRange)
{
    QVariantMap metrics;

    QString query = "SELECT SUM(quantity) as total, SUM(quantityBorrowed) as borrowed FROM digital_materials WHERE 1=1";

    if (itemType != "all") {
        query += QString(" AND ItemType = '%1'").arg(itemType);
    }
    if (status == "Available") {
        query += " AND (quantity - quantityBorrowed) > 0";
    } else if (status == "Borrowed") {
        query += " AND quantityBorrowed > 0";
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        QVariantMap data = result.first().toMap();
        metrics["totalQuantity"] = data["total"];
        metrics["borrowedQuantity"] = data["borrowed"];
        metrics["availableQuantity"] = data["total"].toInt() - data["borrowed"].toInt();
    }

    return metrics;
}

// ============================================================================
// CATEGORY 9: POPULAR TRENDS & INSIGHTS
// ============================================================================

QVariantMap ReportsManager::getTrendsInsightsStats()
{
    QString cacheKey = "trends_insights_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Trending genre this month
    QString thisMonth = QDate::currentDate().toString("yyyy-MM");
    QString trendingQuery =
        "SELECT b.genre FROM issued_books ib "
        "JOIN books b ON ib.book_id = b.bookID "
        "WHERE strftime('%Y-%m', ib.issue_date) = ? "
        "GROUP BY b.genre ORDER BY COUNT(*) DESC LIMIT 1";
    QVariantList trendResult = executeQueryToList(trendingQuery, {thisMonth});
    if (!trendResult.isEmpty()) {
        stats["trendingGenre"] = trendResult.first().toMap().value("genre", "N/A");
    } else {
        stats["trendingGenre"] = "N/A";
    }

    // Most borrowed author
    QString authorQuery =
        "SELECT author FROM books WHERE timesBorrowed > 0 "
        "ORDER BY timesBorrowed DESC LIMIT 1";
    QVariantList authorResult = executeQueryToList(authorQuery);
    if (!authorResult.isEmpty()) {
        stats["mostBorrowedAuthor"] = authorResult.first().toMap().value("author", "N/A");
    } else {
        stats["mostBorrowedAuthor"] = "N/A";
    }

    // Average borrowing frequency
    stats["averageBorrowingFrequency"] = executeAverageQuery(
        "SELECT timesBorrowed FROM books WHERE timesBorrowed > 0"
        );

    // Collection turnover rate
    int totalBooks = executeCountQuery("SELECT COUNT(*) FROM books");
    int totalBorrows = executeSumQuery("SELECT SUM(timesBorrowed) FROM books");
    stats["collectionTurnoverRate"] = totalBooks > 0 ? (static_cast<double>(totalBorrows) / totalBooks) : 0.0;

    // Books never borrowed
    stats["booksNeverBorrowed"] = executeCountQuery(
        "SELECT COUNT(*) FROM books WHERE timesBorrowed = 0"
        );

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getPopularSubjectsGenres(int topN)
{
    QString cacheKey = QString("popular_subjects_%1").arg(topN);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString(
                        "SELECT genre, SUM(timesBorrowed) as total_borrows, COUNT(*) as book_count "
                        "FROM books WHERE genre IS NOT NULL AND genre != '' "
                        "GROUP BY genre ORDER BY total_borrows DESC LIMIT %1"
                        ).arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["genre"];
        chartData["value"] = row["total_borrows"];
        chartData["extraData"] = row["book_count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getBooksPerformanceMatrix()
{
    QString cacheKey = "books_performance_matrix";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT title, author, genre, timesBorrowed, value "
        "FROM books WHERE timesBorrowed > 0 "
        "ORDER BY timesBorrowed DESC LIMIT 50";

    QVariantList result = executeQueryToList(query);
    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getTopAuthors(int topN)
{
    QString cacheKey = QString("top_authors_%1").arg(topN);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = QString(
                        "SELECT author, SUM(timesBorrowed) as total_borrows, COUNT(*) as book_count "
                        "FROM books WHERE author IS NOT NULL AND author != '' "
                        "GROUP BY author ORDER BY total_borrows DESC LIMIT %1"
                        ).arg(topN);

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["author"];
        chartData["value"] = row["total_borrows"];
        chartData["subLabel"] = QString("%1 books").arg(row["book_count"].toInt());
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getGenrePopularityTrends(const QString &dateRange)
{
    QString cacheKey = QString("genre_popularity_trends_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m', ib.issue_date) as month, b.genre, COUNT(*) as count "
        "FROM issued_books ib "
        "JOIN books b ON ib.book_id = b.bookID "
        "WHERE b.genre IS NOT NULL AND b.genre != ''";

    QString dateFilter = getDateRangeSQL(dateRange, "ib.issue_date");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY month, b.genre ORDER BY month, count DESC";

    QVariantList result = executeQueryToList(query);
    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getTrendsMetrics(const QString &dateRange, const QString &genre, int minBorrowThreshold)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total, AVG(timesBorrowed) as avg_borrows FROM books WHERE timesBorrowed >= ?";

    QVariantList bindValues = {minBorrowThreshold};

    if (genre != "all") {
        query += QString(" AND genre = '%1'").arg(genre);
    }

    QVariantList result = executeQueryToList(query, bindValues);
    if (!result.isEmpty()) {
        QVariantMap data = result.first().toMap();
        metrics["totalBooks"] = data["total"];
        metrics["averageBorrows"] = data["avg_borrows"];
    }

    return metrics;
}

// ============================================================================
// CATEGORY 10: SYSTEM ACTIVITY & PERFORMANCE
// ============================================================================

QVariantMap ReportsManager::getSystemPerformanceStats()
{
    QString cacheKey = "system_performance_stats";
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toMap();
    }

    setLoading(true);
    clearError();

    QVariantMap stats;

    // Total system operations today
    QString today = QDate::currentDate().toString("yyyy-MM-dd");
    stats["operationsToday"] = executeCountQuery(
        "SELECT COUNT(*) FROM system_logs WHERE DATE(timestamp) = ?",
        {today}
        );

    // Error count (last 24 hours)
    QString last24h = QDateTime::currentDateTime().addDays(-1).toString("yyyy-MM-dd HH:mm:ss");
    stats["errorCount24h"] = executeCountQuery(
        "SELECT COUNT(*) FROM system_logs WHERE log_level IN ('ERROR', 'CRITICAL') AND timestamp >= ?",
        {last24h}
        );

    // Last successful OPAC sync
    QString syncQuery =
        "SELECT MAX(completed_at) as last_sync FROM opac_sync_log WHERE status = 'success'";
    QVariantList syncResult = executeQueryToList(syncQuery);
    if (!syncResult.isEmpty() && !syncResult.first().toMap()["last_sync"].isNull()) {
        stats["lastOpacSync"] = syncResult.first().toMap()["last_sync"].toString();
    } else {
        stats["lastOpacSync"] = "Never";
    }

    // Database size
    stats["databaseSize"] = getDatabaseSize();

    // Peak usage hour
    QString peakQuery =
        "SELECT strftime('%H', timestamp) as hour, COUNT(*) as count "
        "FROM system_logs GROUP BY hour ORDER BY count DESC LIMIT 1";
    QVariantList peakResult = executeQueryToList(peakQuery);
    if (!peakResult.isEmpty()) {
        stats["peakUsageHour"] = peakResult.first().toMap().value("hour", "N/A").toString() + ":00";
    } else {
        stats["peakUsageHour"] = "N/A";
    }

    setLoading(false);
    setCacheValue(cacheKey, stats);
    return stats;
}

QVariantList ReportsManager::getSystemLogsBySeverity(const QString &dateRange)
{
    QString cacheKey = QString("system_logs_severity_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query =
        "SELECT strftime('%Y-%m-%d', timestamp) as date, log_level, COUNT(*) as count "
        "FROM system_logs WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "timestamp");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY date, log_level ORDER BY date, log_level";

    QVariantList result = executeQueryToList(query);
    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getLogCategoriesDistribution(const QString &dateRange)
{
    QString cacheKey = QString("log_categories_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT log_category, COUNT(*) as count FROM system_logs WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "timestamp");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY log_category ORDER BY count DESC";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    int total = 0;
    for (const QVariant &item : rawData) {
        total += item.toMap()["count"].toInt();
    }

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["label"] = row["log_category"];
        chartData["value"] = row["count"];
        chartData["percentage"] = total > 0 ? (row["count"].toDouble() / total * 100.0) : 0.0;
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getOpacSyncOperations(const QString &dateRange)
{
    QString cacheKey = QString("opac_sync_ops_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    QString query = "SELECT status, COUNT(*) as count FROM opac_sync_log WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "started_at");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY status";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["category"] = row["status"];
        chartData["value"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantList ReportsManager::getDailySystemActivity(const QString &dateRange)
{
    QString cacheKey = QString("daily_system_activity_%1").arg(dateRange);
    if (isCacheValid(cacheKey)) {
        return getCacheValue(cacheKey).toList();
    }

    // Combine multiple operations into daily activity count
    QString query =
        "SELECT strftime('%Y-%m-%d', timestamp) as date, COUNT(*) as count "
        "FROM system_logs WHERE 1=1";

    QString dateFilter = getDateRangeSQL(dateRange, "timestamp");
    if (!dateFilter.isEmpty()) {
        query += " AND " + dateFilter;
    }

    query += " GROUP BY date ORDER BY date";

    QVariantList rawData = executeQueryToList(query);
    QVariantList result;

    for (const QVariant &item : rawData) {
        QVariantMap row = item.toMap();
        QVariantMap chartData;
        chartData["xValue"] = row["date"];
        chartData["yValue"] = row["count"];
        result.append(chartData);
    }

    setCacheValue(cacheKey, result);
    return result;
}

QVariantMap ReportsManager::getSystemMetrics(const QString &dateRange, const QString &logLevel, const QString &category)
{
    QVariantMap metrics;

    QString query = "SELECT COUNT(*) as total FROM system_logs WHERE 1=1";

    if (dateRange != "all") {
        QString dateFilter = getDateRangeSQL(dateRange, "timestamp");
        if (!dateFilter.isEmpty()) {
            query += " AND " + dateFilter;
        }
    }
    if (logLevel != "all") {
        query += QString(" AND log_level = '%1'").arg(logLevel);
    }
    if (category != "all") {
        query += QString(" AND log_category = '%1'").arg(category);
    }

    QVariantList result = executeQueryToList(query);
    if (!result.isEmpty()) {
        metrics["totalLogs"] = result.first().toMap()["total"];
    }

    return metrics;
}
