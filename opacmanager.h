#ifndef OPACMANAGER_H
#define OPACMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QDateTime>
#include <QJsonObject>
#include <QJsonArray>
#include <QSqlDatabase>
#include <QMutex>
#include <QFuture>
#include <QtConcurrent>

class OpacManager : public QObject
{
    Q_OBJECT
    
    //properties for QML binding
    Q_PROPERTY(bool isConfigured READ isConfigured NOTIFY configurationChanged)
    Q_PROPERTY(bool isSyncing READ isSyncing NOTIFY syncingChanged)
    Q_PROPERTY(QString syncStatus READ syncStatus NOTIFY syncStatusChanged)
    Q_PROPERTY(bool autoSyncEnabled READ autoSyncEnabled WRITE setAutoSyncEnabled NOTIFY autoSyncEnabledChanged)
    Q_PROPERTY(int syncIntervalMinutes READ syncIntervalMinutes WRITE setSyncIntervalMinutes NOTIFY syncIntervalChanged)
    Q_PROPERTY(QString lastSyncTime READ lastSyncTime NOTIFY lastSyncTimeChanged)
    Q_PROPERTY(int pendingReservationsCount READ pendingReservationsCount NOTIFY pendingReservationsCountChanged)
    
public:
    explicit OpacManager(QObject *parent = nullptr);
    ~OpacManager();
    
    //property getters
    bool isConfigured() const {return m_isConfigured;}
    bool isSyncing() const {return m_isSyncing;}
    QString syncStatus() const {return m_syncStatus;}
    bool autoSyncEnabled() const {return m_autoSyncEnabled;}
    int syncIntervalMinutes() const {return m_syncIntervalMinutes;}
    QString lastSyncTime() const {return m_lastSyncTime;}
    int pendingReservationsCount() const {return m_pendingReservationsCount;}
    
    //property setters
    void setAutoSyncEnabled(bool enabled);
    void setSyncIntervalMinutes(int minutes);
    
    //Methods to be called from Qml frontend
    Q_INVOKABLE bool initializeConfiguration(const QString &opacUrl, const QString &apiKey,
                                             int syncInterval = 60, int pickupDays = 3, int expiryDays = 7);
    Q_INVOKABLE bool updateConfiguration(const QString &opacUrl, const QString &apiKey,
                                         int &syncInterval, int pickupDays, int expiryDays);
    
    Q_INVOKABLE QVariantMap getConfiguration();
    Q_INVOKABLE void testConnection();
    Q_INVOKABLE void syncNow();
    Q_INVOKABLE void syncBooks();
    Q_INVOKABLE void syncUsers();
    Q_INVOKABLE void syncReservations();
    Q_INVOKABLE QVariantList getReservationsList(const QString &filter = "all");
    Q_INVOKABLE bool cancelReservation(int reservationId);
    Q_INVOKABLE bool fulfillReservation(int reservationId, int issueId);
    Q_INVOKABLE QVariantList getSyncHistory(int limit = 20);
    Q_INVOKABLE bool clearSyncHistory();
    
signals:
    //signals for UI updates
    void configurationChanged();
    void syncingChanged();
    void syncStatusChanged();
    void syncCompleted(const QString &message);
    void syncFailed(const QString &error);
    void reservationsUpdated();
    void autoSyncEnabledChanged();
    void syncIntervalChanged();
    void lastSyncTimeChanged();
    void pendingReservationsCountChanged();
    void connectionTestResult(bool success, const QString &message);
    void errorOccurred(const QString &error);
    
private slots:
    void onAutoSyncTimerTimeout();
    void onExpirationTimeTimeout();
    void onNetworkReplyFinished();
    
private:
    //Database management
    bool createTables();
    bool loadConfiguration();
    bool saveConfiguration();
    bool validateConfiguration();
    QDateTime getLastSyncTimestamp(const QString &syncType);
    bool updateLastSyncTimestamp(const QString &syncType, const QDateTime &timestamp);
    bool logSyncOperation(const QString &syncType, const QString &direction,
                           int recordsAffected,const QString &status, const QString &errorMessage = QString());

    //Data retrieval for sync
    QJsonArray getChangedBooks(const QDateTime &since);
    QJsonArray getChangedUsers(const QDateTime &since);
    QJsonArray getAllBooks();
    QJsonObject getAllUsers();

    //Reservation management
    bool saveReservations(const QJsonArray &reservations);
    bool updateReservationStatus(int reservationId, const QString &status,
                                 const QDateTime &notificationDate = QDateTime(), const QDateTime &pickupDeadline = QDateTime());
    QVariantList getActiveReservations(const QString &statusFilter = QString());
    void checkExpiredReservations();
    void checkBookAvailability();
    int getNextInQueue(int bookId);
    bool notifyUserBookReady(int reservationId);
    void updatePendingCount();

    //HTTP communication
    void sendHttpRequest(const QString &endpoint, const QString &method,
                         const QJsonObject &data = QJsonObject(), const QString &requestType = QString());
    void handleBooksSync(const QByteArray &response);
    void handleUsersSync(const QByteArray &response);
    void handleReservationsSync(const QByteArray &response);
    void handleConnectionTest(const QByteArray &response);

    //Helper methods
    void setSyncStatus(const QString &status);
    void setIsSyncing(bool syncing);
    void startAutoSync();
    void stopAutoSync();
    void performFullSync();
    void performIncrementalSync();
    QString buildApiUrl(const QString &endpoint);
    void retryRequest(const QString &endpoint, const QString &method,
                      const QJsonObject &data, int attemptNumber);

    //for some async operations on the reservations so it doesn't freeze UI
    QFuture<bool> handleReservationsSyncAsync(const QByteArray &response);
    bool saveReservationsInThread(const QJsonArray &reservations, QSqlDatabase &db);


    //Member variables
    QNetworkAccessManager *m_networkManager;
    QTimer *m_autoSyncTimer;
    QTimer *m_expirationTimer;
    QSqlDatabase m_db;
    QMutex m_mutex;

    //Configuration data
    QString m_opacUrl;
    QString m_apiKey;
    int m_syncIntervalMinutes;
    int m_notificationPickupDays;
    int m_reservationExpiryDays;

    //State variables
    bool m_isConfigured;
    bool m_isSyncing;
    QString m_syncStatus;
    bool m_autoSyncEnabled;
    QString m_lastSyncTime;
    int m_pendingReservationsCount;

    //Request tracking
    QString m_currentRequestType;
    QMap<QNetworkReply*, QString> m_activeRequests;

    //Constants
    static const int NETWORK_TIMEOUT = 30000; //30 seconds
    static const int MAX_RETRIES = 3;
    static const int BATCH_SIZE = 500;
};

#endif // OPACMANAGER_H

















