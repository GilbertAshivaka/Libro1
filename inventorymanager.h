#ifndef INVENTORYMANAGER_H
#define INVENTORYMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QDate>
#include <QDebug>
#include "databasemanager.h"

class InventoryManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList recentAcquisitions READ recentAcquisitions  NOTIFY recentAcquisitionsChanged)
    Q_PROPERTY(QVariantList categoryCount READ categoryCount NOTIFY categoryCountChanged)
    Q_PROPERTY(QVariantList attentionItems READ attentionItems NOTIFY attentionItemsChanged)
    Q_PROPERTY(QVariantList underMaintenance READ underMaintenance NOTIFY underMaintenanceChanged)
    Q_PROPERTY(QVariantList shelfList READ shelfList NOTIFY shelfListChanged)
    Q_PROPERTY(QVariantList copies READ copies NOTIFY copiesChanged)

public:
    explicit InventoryManager(QObject *parent = nullptr);
    ~InventoryManager();

    Q_INVOKABLE int getTotalBooksCount();
    Q_INVOKABLE int getAvailableBooksCount();
    Q_INVOKABLE int getCheckedOutBooksCount();
    Q_INVOKABLE int getOverdueBooksCount();
    Q_INVOKABLE int getMissingBooksCount();
    Q_INVOKABLE double getTotalOverdueFees();
    Q_INVOKABLE double getTotalReplacementCost();

    //book manager functions
    Q_INVOKABLE bool deleteBook(const QString &bookNumber);
    Q_INVOKABLE bool archiveBook(const QString &bookNumber);

    //inventory reports functions
    Q_INVOKABLE QVariantList getRecentAcquisitions(const QDate &fromDate);
    Q_INVOKABLE void getCountByCategory(const QString &category, const QString &searchTerm = "");
    Q_INVOKABLE void getItemsNeedingAttention();
    Q_INVOKABLE void getBooksUnderMaintenance();

    //physical tracking functions
    Q_INVOKABLE void getBooksByShelf();
    Q_INVOKABLE void getNumberOfCopies();

    Q_INVOKABLE bool bookExists(const QString &bookNumber);
    Q_INVOKABLE bool isBookCurrentlyIssued(const QString &bookNumber);

    //getters for the QVariantLists
    QVariantList recentAcquisitions() const {return m_recentAcquisitions;}
    QVariantList categoryCount() const { return m_categoryCount; }
    QVariantList attentionItems() const { return m_attentionItems; }
    QVariantList underMaintenance() const { return m_underMaintenance; }
    QVariantList shelfList() const { return m_shelfList; }
    QVariantList copies() const { return m_copies; }

public slots:
    void updateRecentAcquisitions(const QDate &fromDate);

signals:
    void errorOccured(const QString &error);
    void operationCompleted(const QString &message);

    void recentAcquisitionsChanged();
    void categoryCountChanged();
    void attentionItemsChanged();
    void underMaintenanceChanged();
    void shelfListChanged();
    void copiesChanged();

    void noRecentAquisitions(const QString &message);
    void categoryNotFound(const QString &messase);
    void attentionItemsNotFound(const QString &message);
    void underMaintenanceNotFound(const QString &message);
    void shelfListEmpty(const QString &message);
    void noCopiesFound(const QString &message);

private:
    QSqlDatabase db;

    QVariantList m_recentAcquisitions;
    QVariantList m_categoryCount;
    QVariantList m_attentionItems;
    QVariantList m_underMaintenance;
    QVariantList m_shelfList;
    QVariantList m_copies;

    //helper function to get the bookID from bookNumber(callNumber, barcode or bookID)
    int getBookIdFromNumber(const QString &bookNumber);

    //helper to validate category names
    bool isValidCategory(const QString &category);
};

#endif // INVENTORYMANAGER_H









