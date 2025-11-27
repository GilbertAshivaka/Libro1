#ifndef REPORTSMANAGER_H
#define REPORTSMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QDateTime>
#include <QVariantMap>
#include <QVariantList>
#include <QMutex>
#include <QTimer>
#include <QAbstractListModel>

//model for complex chart data that requires AstractListModel
class ChartDataModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ChartDataRoles{
        LabelRole = Qt::UserRole + 1,
        ValueRole,
        PercentageRole,
        CategoryRole,
        SubLabelRole,
        XValueRole,
        YValueRole,
        SeriesNameRole,
        ColorRole,
        ExtraDataRole
    };

    explicit ChartDataModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setData(const QVariantList &data);
    void clearData();

private:
    QVariantList m_data;
};

//======================================================================================//

class ReportsManager : public QObject
{
    Q_OBJECT

    //properties for caching and state management
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QDateTime lastCacheUpdate READ lastCacheUpdate NOTIFY lastCacheUpdateChanged)
    Q_PROPERTY(bool cacheEnabled READ cacheEnabled WRITE setCacheEnabled NOTIFY cacheEnabledChanged)


public:
    explicit ReportsManager(QObject *parent = nullptr);
    ~ReportsManager();

    //Property getters
    bool isLoading(){return m_isLoading;}
    QString lastError(){return m_lastError;}
    QDateTime lastCacheUpdate(){return m_lastCacheUpdate;}
    bool cacheEnabled(){return m_cacheEnabled;}

    //property setters
    void setCacheEnabled(bool enabled);


    // ============================================================================
    // 1. COLLECTION OVERVIEW & STATISTICS
    // ============================================================================
    Q_INVOKABLE QVariantMap getCollectionStats();
    Q_INVOKABLE QVariantList getBooksByGenreDistribution(const QString &dateRange = "all");
    Q_INVOKABLE QVariantList getBooksByPublicationYear(int topN = 10);
    Q_INVOKABLE QVariantList getBookAvailabilityStatus();
    Q_INVOKABLE QVariantList getTopBorrowedBooks(int topN = 10, const QString &genre = "all",
                                                 const QString &language = "all");
    Q_INVOKABLE QVariantMap getCollectionMetrics(const QString &dateRange = "all",
                                                 const QString &genre = "all", const QString &language = "all");


    // ============================================================================
    // 2. CIRCULATION ANALYTICS
    // ============================================================================
    Q_INVOKABLE QVariantMap getCirculationStats(const QString &dateRange = "last30days");
    Q_INVOKABLE QVariantList getBorrowingTrends(const QString &dateRange = "last30days",
                                                const QString &groupBy = "day");
    Q_INVOKABLE QVariantList getBorrowingTrendsByUserType(const QString &dateRange = "last30days");
    Q_INVOKABLE QVariantList getBorrowingByDayOfWeek(const QString &dateRange = "last30days");
    Q_INVOKABLE QVariantList getMonthlyCirculation(const QString &dateRange = "last12months");
    Q_INVOKABLE QVariantMap getCirculationMetrics(const QString &dateRange = "last30days",
                                                  const QString &userType = "all", const QString &genre = "all");


    // ============================================================================
    // 3. USER ENGAGEMENT & DEMOGRAPHICS
    // ============================================================================
    Q_INVOKABLE QVariantMap getUserEngagementStats();
    Q_INVOKABLE QVariantList getUserDistributionByType();
    Q_INVOKABLE QVariantList getTopActiveBorrowers(int topN = 20, const QString &userType = "all");
    Q_INVOKABLE QVariantList getNewUserRegistrations(const QString &dateRange = "last12months");
    Q_INVOKABLE QVariantList getBorrowingActivityByUserCategory();
    Q_INVOKABLE QVariantMap getUserEngagementMetrics(const QString &dateRange = "all",
                                                     const QString &userType = "all", const QString &status = "all");


    // ============================================================================
    // 4. FINANCIAL REPORTS
    // ============================================================================
    Q_INVOKABLE QVariantMap getFinancialStats(const QString &dateRange = "currentMonth");
    Q_INVOKABLE QVariantList getFineCollectionOverTime(const QString &dateRange = "last6months");
    Q_INVOKABLE QVariantList getFineAmountVsPaid(const QString &dateRange = "last6months");
    Q_INVOKABLE QVariantList getFinePaymentStatus();
    Q_INVOKABLE QVariantList getLostBookCostsByMonth(const QString &dateRange = "last12months");
    Q_INVOKABLE QVariantMap getFinancialMetrics(const QString &dateRange = "currentMonth",
                                                const QString &userType = "all", const QString &paymentStatus = "all");


    // ============================================================================
    // 5. OVERDUE & COMPLIANCE
    // ============================================================================
    Q_INVOKABLE QVariantMap getOverdueStats();
    Q_INVOKABLE QVariantList getOverdueBooksByDaysRange();
    Q_INVOKABLE QVariantList getOverdueTrendOverMonths(const QString &dateRange = "last12months");
    Q_INVOKABLE QVariantList getUsersWithMostOverdue(int topN = 15, const QString &userType = "all");
    Q_INVOKABLE QVariantList getOverdueBooksByUserType();
    Q_INVOKABLE QVariantMap getOverdueMetrics(const QString &daysRange = "all",
                                              const QString &userType = "all", const QString &genre = "all");


    // ============================================================================
    // 6. LOST & DAMAGED BOOKS
    // ============================================================================
    Q_INVOKABLE QVariantMap getLostDamagedStats();
    Q_INVOKABLE QVariantList getLostBooksOverTime(const QString &dateRange = "last12months");
    Q_INVOKABLE QVariantList getLostBooksByGenre();
    Q_INVOKABLE QVariantList getLostBookResolutionStatus();
    Q_INVOKABLE QVariantList getUsersWithLostBooks(int topN = 15);
    Q_INVOKABLE QVariantMap getLostDamagedMetrics(const QString &dateRange = "all",
                                                  const QString &resolutionStatus = "all",
                                                  const QString &userType = "all",
                                                  const QString &genre = "all");



    // ============================================================================
    // 7. RESERVATION ANALYTICS
    // ============================================================================
    Q_INVOKABLE QVariantMap getReservationStats();
    Q_INVOKABLE QVariantList getReservationsOverTime(const QString &dateRange = "last6months");
    Q_INVOKABLE QVariantList getMostReservedBooks(int topN = 20);
    Q_INVOKABLE QVariantList getReservationStatusDistribution();
    Q_INVOKABLE QVariantList getReservationSource();
    Q_INVOKABLE QVariantMap getReservationMetrics(const QString &dateRange = "all",
                                                  const QString &status = "all",
                                                  const QString &source = "all");



    // ============================================================================
    // 8. DIGITAL MATERIALS & EQUIPMENT
    // ============================================================================
    Q_INVOKABLE QVariantMap getDigitalMaterialsStats();
    Q_INVOKABLE QVariantList getDigitalMaterialsByType();
    Q_INVOKABLE QVariantList getMostBorrowedDigitalItems(int topN = 15);
    Q_INVOKABLE QVariantList getDigitalMaterialLoansOverTime(const QString &dateRange = "last6months");
    Q_INVOKABLE QVariantList getDigitalMaterialsAvailableVsBorrowed();
    Q_INVOKABLE QVariantMap getDigitalMaterialsMetrics(const QString &itemType = "all",
                                                       const QString &status = "all",
                                                       const QString &dateRange = "all");


    // ============================================================================
    // 9. POPULAR TRENDS & INSIGHTS
    // ============================================================================
    Q_INVOKABLE QVariantMap getTrendsInsightsStats();
    Q_INVOKABLE QVariantList getPopularSubjectsGenres(int topN = 20);
    Q_INVOKABLE QVariantList getBooksPerformanceMatrix();
    Q_INVOKABLE QVariantList getTopAuthors(int topN = 20);
    Q_INVOKABLE QVariantList getGenrePopularityTrends(const QString &dateRange = "last12months");
    Q_INVOKABLE QVariantMap getTrendsMetrics(const QString &dateRange = "all",
                                             const QString &genre = "all",
                                             int minBorrowThreshold = 0);



    // ============================================================================
    // 10. SYSTEM ACTIVITY & PERFORMANCE
    // ============================================================================
    Q_INVOKABLE QVariantMap getSystemPerformanceStats();
    Q_INVOKABLE QVariantList getSystemLogsBySeverity(const QString &dateRange = "last7days");
    Q_INVOKABLE QVariantList getLogCategoriesDistribution(const QString &dateRange = "all");
    Q_INVOKABLE QVariantList getOpacSyncOperations(const QString &dateRange = "all");
    Q_INVOKABLE QVariantList getDailySystemActivity(const QString &dateRange = "last30days");
    Q_INVOKABLE QVariantMap getSystemMetrics(const QString &dateRange = "today",
                                             const QString &logLevel = "all",
                                             const QString &category = "all");



    // ============================================================================
    // UTILITY & HELPER METHODS
    // ============================================================================
    Q_INVOKABLE void clearCache();
    Q_INVOKABLE void refreshAllData();
    Q_INVOKABLE QString getDatabaseSize();
    Q_INVOKABLE QVariantList getAvailableGenres();
    Q_INVOKABLE QVariantList getAvailableLanguages();
    Q_INVOKABLE QVariantList getAvailableUserTypes();


signals:
    //state change signals
    void isLoadingChanged();
    void lastErrorChanged();
    void lastCacheUpdateChanged();
    void cacheEnabledChanged();
    void dataRefreshed();
    void errorOccurred(const QString &error);

private:
    //database connection
    QSqlDatabase m_db;
    QMutex m_mutex;

    //state variables
    bool m_isLoading;
    QString m_lastError;
    QDateTime m_lastCacheUpdate;
    bool m_cacheEnabled;

    //cache management
    QTimer *m_cacheTimer;
    QMap<QString, QVariant> m_cache;
    int m_cacheExpiryMinutes;

    //helper methods for date range parsing
    QPair<QDateTime, QDateTime> parseDateRange(const QString &dateRange) const;
    QString getDateRangeSQL(const QString &dateRange, const QString &dateColumn) const;

    //cache management helpers
    bool isCacheValid(const QString &key) const;
    void setCacheValue(const QString &key, const QVariant &value);
    QVariant getCacheValue(const QString &key) const;
    void invalidateCache();


    // Error handling
    void setError(const QString &error);
    void clearError();
    void setLoading(bool loading);

    // Database query helpers
    QVariantList executeQueryToList(const QString &query, const QVariantList &bindValues = QVariantList());
    QVariantMap executeQueryToMap(const QString &query, const QVariantList &bindValues = QVariantList());
    int executeCountQuery(const QString &query, const QVariantList &bindValues = QVariantList());
    double executeAverageQuery(const QString &query, const QVariantList &bindValues = QVariantList());
    double executeSumQuery(const QString &query, const QVariantList &bindValues = QVariantList());

    // Data formatting helpers
    QString formatCurrency(double value) const;
    QString formatPercentage(double value) const;
    QString formatDate(const QDateTime &date) const;
    QVariantMap createStatCard(const QString &label,
                               const QVariant &value,
                               const QString &unit = "",
                               const QString &trend = "") const;

};

#endif // REPORTSMANAGER_H



















