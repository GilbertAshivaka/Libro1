#ifndef BOOKSHOPMANAGER_H
#define BOOKSHOPMANAGER_H

#include <QObject>
#include <QAbstractListModel>
#include <QQmlListProperty>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QUrl>
#include <QDesktopServices>
#include <QRegularExpression>
#include <QDebug>

struct Bookshop {
    int id;
    QString name;
    QString url;
};

class BookshopModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum BookshopRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        UrlRole
    };

    explicit BookshopModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addBookshop(const Bookshop &bookshop);
    void removeBookshop(int id);
    void clear();
    void setBookshops(const QList<Bookshop> &bookshops);

private:
    QList<Bookshop> m_bookshops;
};

class BookshopManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(BookshopModel* bookshopsModel READ bookshopsModel CONSTANT)

public:
    explicit BookshopManager(QObject *parent = nullptr);
    ~BookshopManager();

    BookshopModel* bookshopsModel() const { return m_bookshopsModel; }

    Q_INVOKABLE bool addBookshop(const QString &name, const QString &url);
    Q_INVOKABLE bool deleteBookshop(int id);
    Q_INVOKABLE void openBookshop(const QString &url);
    Q_INVOKABLE bool isValidUrl(const QString &url);
    Q_INVOKABLE void loadBookshops();

signals:
    void bookshopAdded(const QString &name, const QString &url);
    void bookshopDeleted(int id);
    void errorOccurred(const QString &error);

private:
    bool initializeDatabase();
    void populateDefaultBookshops();
    bool bookshopExists(const QString &name, const QString &url);

    BookshopModel* m_bookshopsModel;
    QSqlDatabase m_database;
};

#endif // BOOKSHOPMANAGER_H
