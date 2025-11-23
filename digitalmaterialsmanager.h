#ifndef DIGITALMATERIALSMANAGER_H
#define DIGITALMATERIALSMANAGER_H

#include <QObject>
#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>

class DigitalMaterialsModel;
class DigitalMaterialsHistoryModel;

class DigitalMaterialsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QAbstractListModel* itemsModel READ itemsModel NOTIFY itemsModelChanged)
    Q_PROPERTY(QAbstractListModel* historyModel READ historyModel NOTIFY historyModelChanged)


public:
    explicit DigitalMaterialsManager(QObject *parent = nullptr);
    ~DigitalMaterialsManager();

    //property getters
    QAbstractListModel* itemsModel() const;
    QAbstractListModel* historyModel() const;

    //Database initialization
    Q_INVOKABLE bool initializeDatabase();
    Q_INVOKABLE void setDatabaseConnection(const QString &connectionName);

    //get the number of items borrowed by a user
    Q_INVOKABLE void getUserBorrowedQuantity(int itemID, const QString& userNumber);

public slots:
    //Item management
    void refreshItems();

    bool addItem(const QString &itemName, const QString &itemType, int quantity,
                 const QString &location = QString(), const QString &condition = QString(),
                 double value = 0.0, const QString &status = "Available", const QString &details = QString()
                 );

    bool updateItem(int itemID, const QString &itemName, const QString &itemType, int quantity, const QString &location = QString(),
                    const QString &condition = QString(), double value = 0.0, const QString &status = "Available",
                    const QString &details = QString()
                    );

    bool deleteItem(int itemID);

    //borrowing management
    bool issueItem(int itemID, const QString &userNumber, int quantity);
    bool returnItem(int itemID, int quantity, const QString &userNumber);
    bool isValidUser(const QString &userNumber);

    //history management
    void refreshHistory();

signals:
    void itemsModelChanged();
    void historyModelChanged();
    void itemAdded(const QString &itemName);
    void itemUpdated(const QString &itemName);
    void itemIssued(const QString &itemName, const QString &userNumber, int quantity);
    void itemReturned(const QString &itemName, int quantity);
    void itemDeleted(const QString &itemName);
    void errorOccured(const QString &error);

    void userBorrowedQuantityChecked(const QString& userNumber, int quantity, const QString& message);

private:
    void createTables();
    bool executeQuery(QSqlQuery query, const QString &operation);

    DigitalMaterialsModel   *m_itemsModel;
    DigitalMaterialsHistoryModel *m_historyModel;

    QSqlDatabase m_database;
    QString m_connectionName;
};

//DIGITALMATERIALSMODEL

class DigitalMaterialsModel : public QAbstractListModel{
    Q_OBJECT

public:
    enum Roles{
        ItemIDRole = Qt::UserRole + 1,
        ItemNameRole,
        ItemTypeRole,
        QuantityRole,
        QuantityBorrowedRole,
        HolderRole,
        DateAddedRole,
        DateBorrowedRole,
        LocationRole,
        ConditionRole,
        ValueRole,
        StatusRole,
        DetailRole
    };

   explicit DigitalMaterialsModel(QObject *parent = nullptr);


    //AbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setItems(const QList<QVariantMap> &items);
    void clear();

private:
    QList<QVariantMap> m_items;

};

class DigitalMaterialsHistoryModel : public QAbstractListModel{
    Q_OBJECT

public:
    enum Roles {
        LoanIDRole = Qt::UserRole + 1,
        ItemIDRole,
        ItemNameRole,
        UserIDRole,
        UserNumberRole,
        QuantityBorrowedRole,
        IssueDateRole,
        ReturnDateRole,
        StatusRole
    };
    explicit DigitalMaterialsHistoryModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setHistory(const QList<QVariantMap> &history);
    void clear();

private:
    QList<QVariantMap> m_history;

};

#endif // DIGITALMATERIALSMANAGER_H























