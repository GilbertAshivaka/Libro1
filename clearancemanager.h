#ifndef CLEARANCEMANAGER_H
#define CLEARANCEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantMap>
#include <QVariantList>
#include "databasemanager.h"

class ClearanceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY processingChanged)
    Q_PROPERTY(QString clearanceStatus READ clearanceStatus NOTIFY clearanceStatusChanged)
    Q_PROPERTY(QVariantMap clearanceResult READ clearanceResult NOTIFY clearanceResultChanged)

public:
    explicit ClearanceManager(QObject *parent = nullptr);

    // Property getters
    bool isProcessing() const { return m_isProcessing; }
    QString clearanceStatus() const { return m_clearanceStatus; }
    QVariantMap clearanceResult() const { return m_clearanceResult; }

public slots:
    // Main clearance function
    Q_INVOKABLE void processClearance(const QString &userName, const QString &userNumber,
                                      const QString &userType, int adminUserId);

    // Get user information
    Q_INVOKABLE QVariantMap getUserInfo(const QString &userNumber, const QString &userType);

    // Generate HTML receipt
    Q_INVOKABLE QString generateHTMLReceipt(const QVariantMap &clearanceData);

    // Save HTML receipt to file
    Q_INVOKABLE bool saveHTMLReceipt(const QString &filePath, const QString &htmlContent);

    // Clear current result
    Q_INVOKABLE void clearResult();

signals:
    void processingChanged();
    void clearanceStatusChanged();
    void clearanceResultChanged();
    void errorOccurred(const QString &error);
    void clearanceCompleted(bool approved, const QString &message);

private:
    // Helper functions
    QVariantMap checkBorrowedBooks(int userId);
    QVariantMap checkDigitalMaterials(int userId);
    QVariantMap checkLostBooks(int userId);
    QVariantMap checkUnpaidFines(int userId);

    void logClearance(const QString &level, const QString &message,
                      const QString &details, int userId);

    QString formatCurrency(double amount) const;
    QString getCurrentDateTime() const;

    // Member variables
    QSqlDatabase db;
    bool m_isProcessing;
    QString m_clearanceStatus;
    QVariantMap m_clearanceResult;
};

#endif // CLEARANCEMANAGER_H
