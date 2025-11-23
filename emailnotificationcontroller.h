#ifndef EMAILNOTIFICATIONCONTROLLER_H
#define EMAILNOTIFICATIONCONTROLLER_H

#include <QObject>
#include <QAbstractListModel>
#include <QTcpSocket>
#include <QSslSocket>
#include <QTimer>
#include <QQueue>
#include <QDateTime>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSettings>
#include <QDebug>
#include "databasemanager.h"

//Email data structure
struct EmailData{
    QString to;
    QString subject;
    QString body;
    QString userName;
    QString bookTitle;
    QString type;    
};

//Email log entry for the model
struct EmailLogEntry{
    QString recipient;
    QString subject;
    QString status;
    QString timestamp;
    QString error;
    QString type;    
};

class EmailLogsModel : public QAbstractListModel{
    Q_OBJECT
    
public:
    enum LogRoles {
        RecipientRole = Qt::UserRole + 1,
        SubjectRole,
        StatusRole,
        TimestampRole,
        ErrorRole,
        TypeRole
    };
    
    explicit EmailLogsModel(QObject *parent = nullptr);
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    Q_INVOKABLE void addLog(const QString &recipient, const QString &subject, const QString & status, const QString type, const QString error = "");
    Q_INVOKABLE void updateLogStatus(int index, const QString status, const QString error = "");
    
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE int getLogsCount();
    
private:
    QList<EmailLogEntry> m_logs;
    
};


class EmailNotificationController : public QObject
{
    Q_OBJECT
    
    //QML Properties
    Q_PROPERTY(bool isConfigured READ isConfigured NOTIFY configurationChanged)
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY processingChanged)
    Q_PROPERTY(int queueSize READ queueSize NOTIFY queueSizeChanged)
    Q_PROPERTY(int totalEmailsSent READ totalEmailsSent NOTIFY totalEmailsSentChanged)
    Q_PROPERTY(int totalEmailsFailed READ totalEmailsFailed NOTIFY totalEmailsFailedChanged)
    Q_PROPERTY(QString lastActivity READ lastActivity NOTIFY lastActivityChanged)
    Q_PROPERTY(EmailLogsModel* emailLogs READ emailLogs CONSTANT)
    
    // SMTP Configuration Properties
    Q_PROPERTY(QString smtpServer READ smtpServer WRITE setSmtpServer NOTIFY smtpConfigChanged)
    Q_PROPERTY(int smtpPort READ smtpPort WRITE setSmtpPort NOTIFY smtpConfigChanged)
    Q_PROPERTY(QString smtpUsername READ smtpUsername WRITE setSmtpUsername NOTIFY smtpConfigChanged)
    Q_PROPERTY(QString smtpPassword READ smtpPassword WRITE setSmtpPassword NOTIFY smtpConfigChanged)
    Q_PROPERTY(bool useSSL READ useSSL WRITE setUseSSL NOTIFY smtpConfigChanged)
    Q_PROPERTY(bool useTLS READ useTLS WRITE setUseTLS NOTIFY smtpConfigChanged)

public:
    explicit EmailNotificationController(QObject *parent = nullptr);
    ~EmailNotificationController();
    
    //Property getters
    bool isConfigured() const;
    bool isProcessing() const;
    int queueSize() const;
    
    int totalEmailsSent() const{
        return m_totalEmailsSent;
    }
    
    int totalEmailsFailed() const{
        return m_totalEmailsFailed;
    }
    
    QString lastActivity() const {
        return m_lastActivity;
    }
    
    EmailLogsModel* emailLogs() const{
        return m_emailLogsModel;
    }
    
    //SMTP getters/setters
    QString smtpServer() const;
    int smtpPort() const;
    QString smtpUsername() const;
    QString smtpPassword() const;
    bool useSSL() const;
    bool useTLS() const;
    
    void setSmtpServer(const QString &server);
    void setSmtpPort(int port);
    void setSmtpUsername(const QString  &username);
    void setSmtpPassword(const QString &password);
    void setUseSSL(bool use);
    void setUseTLS(bool use);
    
public slots:
    //Main Email functions
    void checkAndSendOverdueNotifications();
    void checkAndSendReservedBookNotifications();
    void sendTestEmail(const QString &recipientEmail);
    void sendCustomEmail(const QString &to, const QString &subject, const QString &body);
    
    //Configuration Management
    void saveConfiguration();
    void loadConfiguration();
    bool testConfiguration();
    
    //Queue management
    void clearQueue();
    void pauseProcessing();
    void resumeProcessing();
    
    //Statistics
    void resetStatistics();
    int getPendingOverdueCount();
    int getPendingReservedCount();

signals:
    //Property signals
    void configurationChanged();
    void processingChanged();
    void queueSizeChanged();
    void totalEmailsSentChanged();
    void totalEmailsFailedChanged();
    void lastActivityChanged();
    void smtpConfigChanged();
    
    //Notification signals
    void notificationSent(const QString &message);
    void errorOccured(const QString &error);
    
private slots:
    void onSocketConnected();
    void onSocketReadyRead();
    void onSocketError(QAbstractSocket::SocketError error);
    void onSocketDisconnected();
    void onRetryTimer();
    
private:
    //Core email sending methods
    void processEmailQueue();
    void sendEmail(const EmailData &emailData);
    void connectToServer();
    void processServerResponse(const QString &response);
    void resetConnection(const QString &from);
    
    //Database Queries
    QList<EmailData> getOverdueBooks();
    QList<EmailData> getReservedBooks();
    
    //Email templates
    QString generateOverdueEmailBody(const QString &userName, const QString &bookTitle, const QDateTime &dueDate, int daysOverdue);
    QString generateReservedEmailBody(const QString &userName, const QString &bookTitle);
    QString generateTestEmailBody();
    
    //Utility methods
    QString base64Encode(const QString &text);
    void logEmailActivity(const QString &message, const QString &level = "INFO");
    void updateLastActivity(const QString &activity);
    
    //SMTP State machine
    enum SMTPState{
        Init,
        Connected,
        EhloSent,
        StartTlsSent,
        EhloAfterTlsSent,
        AuthLoginSent,
        AuthUserSent,
        AuthPassSent,
        MailFromSent,
        RcptToSent,
        DataSent,
        MessageSent,
        Finished
    };
    
    //Member Variables
    // QTcpSocket *m_socket;
    QSslSocket *m_socket;
    QTimer *m_retryTimer;
    EmailLogsModel *m_emailLogsModel;
    
    QQueue<EmailData> m_emailQueue;
    EmailData m_currentEmail;
    
    //Statistics
    int m_totalEmailsSent;
    int m_totalEmailsFailed;
    QString m_lastActivity;

    // State management
    SMTPState m_currentState;
    bool m_isProcessing;
    bool m_isPaused;
    int m_retryCount;

    static const int MAX_RETRIES = 3;
    
};

#endif // EMAILNOTIFICATIONCONTROLLER_H












