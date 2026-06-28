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

    // ---- Settlement of outstanding balances during clearance ----
    // Partial payments are allowed (amount must be > 0 and <= remaining balance).
    // Waivers require a non-empty reason. On success each re-runs the clearance
    // checks so the UI reflects the new state immediately.
    Q_INVOKABLE bool payFine(int fineId, double amount, int adminUserId);
    Q_INVOKABLE bool waiveFine(int fineId, const QString &reason, int adminUserId);
    Q_INVOKABLE bool payLostBook(int lostId, double amount, int adminUserId);
    Q_INVOKABLE bool waiveLostBook(int lostId, const QString &reason, int adminUserId);

    // Finalize an APPROVED clearance: persists a clearance certificate and then
    // removes the user, atomically (so the record can't be lost if deletion
    // fails, and the user isn't removed without a record).
    Q_INVOKABLE bool finalizeClearance();

signals:
    void processingChanged();
    void clearanceStatusChanged();
    void clearanceResultChanged();
    void errorOccurred(const QString &error);
    void clearanceCompleted(bool approved, const QString &message);
    void settlementCompleted(bool success, const QString &message);
    void clearanceFinalized(bool success, const QString &message);

private:
    // Helper functions
    QVariantMap checkBorrowedBooks(int userId);
    QVariantMap checkDigitalMaterials(int userId);
    QVariantMap checkLostBooks(int userId);
    QVariantMap checkUnpaidFines(int userId);

    void logClearance(const QString &level, const QString &message,
                      const QString &details, int userId);

    // Settlement helpers
    void buildClearanceResult(const QVariantMap &userInfo, int adminUserId);
    void reevaluate();   // re-run checks for the current user after a settlement
    void recordSettlement(const QString &sourceType, int sourceId, int userId,
                          const QString &action, double amount, const QString &reason,
                          int adminUserId);

    QString formatCurrency(double amount) const;
    QString getCurrentDateTime() const;

    // Member variables
    QSqlDatabase db;
    bool m_isProcessing;
    QString m_clearanceStatus;
    QVariantMap m_clearanceResult;

    // Context of the user currently being cleared (for re-evaluation after a
    // payment/waiver, so the page refreshes without re-entering details).
    bool m_hasContext = false;
    QVariantMap m_currentUserInfo;
    int m_currentAdminId = 0;
};

#endif // CLEARANCEMANAGER_H
