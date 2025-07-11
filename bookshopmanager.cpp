#include "bookshopmanager.h"
#include "databasemanager.h"

// BookshopModel Implementation
BookshopModel::BookshopModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int BookshopModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_bookshops.count();
}

QVariant BookshopModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_bookshops.count())
        return QVariant();

    const Bookshop &bookshop = m_bookshops.at(index.row());

    switch (role) {
    case IdRole:
        return bookshop.id;
    case NameRole:
        return bookshop.name;
    case UrlRole:
        return bookshop.url;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> BookshopModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[UrlRole] = "url";
    return roles;
}

void BookshopModel::addBookshop(const Bookshop &bookshop)
{
    beginInsertRows(QModelIndex(), m_bookshops.count(), m_bookshops.count());
    m_bookshops.append(bookshop);
    endInsertRows();
}

void BookshopModel::removeBookshop(int id)
{
    for (int i = 0; i < m_bookshops.count(); ++i) {
        if (m_bookshops.at(i).id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_bookshops.removeAt(i);
            endRemoveRows();
            break;
        }
    }
}

void BookshopModel::clear()
{
    beginResetModel();
    m_bookshops.clear();
    endResetModel();
}

void BookshopModel::setBookshops(const QList<Bookshop> &bookshops)
{
    beginResetModel();
    m_bookshops = bookshops;
    endResetModel();
}

// BookshopManager Implementation
BookshopManager::BookshopManager(QObject *parent)
    : QObject(parent)
    , m_bookshopsModel(new BookshopModel(this))
{
    initializeDatabase();
}

BookshopManager::~BookshopManager()
{
    if (m_database.isOpen()) {
        m_database.close();
    }
}

bool BookshopManager::initializeDatabase()
{
    m_database = DatabaseManager::getConnection();

    if (!m_database.open()) {
        qWarning() << "Database connection not available";
        emit errorOccurred("Database connection not available");
        return false;
    }

    // Create bookshops table if it doesn't exist
    QSqlQuery query(m_database);

    if (!query.exec("CREATE TABLE IF NOT EXISTS bookshops ("
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                    "name TEXT NOT NULL, "
                    "url TEXT NOT NULL, "
                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                    "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP)")) {
        qWarning() << "Failed to create bookshops table:" << query.lastError().text();
        emit errorOccurred("Failed to create bookshops table: " + query.lastError().text());
        return false;
    }

    // Check if table is empty and populate with default bookshops
    if (query.exec("SELECT COUNT(*) FROM bookshops")) {
        if (query.next() && query.value(0).toInt() == 0) {
            populateDefaultBookshops();
        }
    }

    return true;
}

void BookshopManager::populateDefaultBookshops()
{
    QList<QPair<QString, QString>> defaultBookshops = {
        {"Amazon", "https://www.amazon.com/books"},
        {"Barnes & Noble", "https://www.barnesandnoble.com"},
        {"Book Depository", "https://www.bookdepository.com"},
        {"Waterstones", "https://www.waterstones.com"},
        {"Goodreads", "https://www.goodreads.com"},
        {"Kindle Store", "https://www.amazon.com/kindle-store"},
        {"Google Play Books", "https://play.google.com/store/books"},
        {"Apple Books", "https://books.apple.com"}
    };

    QSqlQuery query(m_database);
    query.prepare("INSERT INTO bookshops (name, url) VALUES (?, ?)");

    for (const auto &bookshop : defaultBookshops) {
        query.addBindValue(bookshop.first);
        query.addBindValue(bookshop.second);

        if (!query.exec()) {
            qWarning() << "Failed to insert default bookshop:" << query.lastError().text();
        }
    }
}

bool BookshopManager::addBookshop(const QString &name, const QString &url)
{
    if (name.trimmed().isEmpty() || url.trimmed().isEmpty()) {
        emit errorOccurred("Name and URL cannot be empty");
        return false;
    }

    if (!isValidUrl(url)) {
        emit errorOccurred("Invalid URL format");
        return false;
    }

    if (bookshopExists(name.trimmed(), url.trimmed())) {
        emit errorOccurred("Bookshop with this name or URL already exists");
        return false;
    }

    QSqlQuery query(m_database);
    query.prepare("INSERT INTO bookshops (name, url, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)");
    query.addBindValue(name.trimmed());
    query.addBindValue(url.trimmed());

    if (!query.exec()) {
        qWarning() << "Failed to add bookshop:" << query.lastError().text();
        emit errorOccurred("Failed to add bookshop: " + query.lastError().text());
        return false;
    }

    // Get the ID of the newly inserted bookshop
    int newId = query.lastInsertId().toInt();

    // Add to model
    Bookshop bookshop;
    bookshop.id = newId;
    bookshop.name = name.trimmed();
    bookshop.url = url.trimmed();

    m_bookshopsModel->addBookshop(bookshop);

    emit bookshopAdded(name.trimmed(), url.trimmed());
    return true;
}

bool BookshopManager::deleteBookshop(int id)
{
    QSqlQuery query(m_database);
    query.prepare("DELETE FROM bookshops WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        qWarning() << "Failed to delete bookshop:" << query.lastError().text();
        emit errorOccurred("Failed to delete bookshop: " + query.lastError().text());
        return false;
    }

    if (query.numRowsAffected() == 0) {
        emit errorOccurred("Bookshop not found");
        return false;
    }

    // Remove from model
    m_bookshopsModel->removeBookshop(id);

    emit bookshopDeleted(id);
    return true;
}

void BookshopManager::openBookshop(const QString &url)
{
    if (isValidUrl(url)) {
        QDesktopServices::openUrl(QUrl(url));
    } else {
        emit errorOccurred("Invalid URL: " + url);
    }
}

bool BookshopManager::isValidUrl(const QString &url)
{
    QRegularExpression urlRegex("^https?://[\\w\\-]+(\\.[\\w\\-]+)+([\\w\\-\\.,@?^=%&:/~\\+#]*[\\w\\-\\@?^=%&/~\\+#])?$");
    return urlRegex.match(url.trimmed()).hasMatch();
}

void BookshopManager::loadBookshops()
{
    QSqlQuery query(m_database);

    if (!query.exec("SELECT id, name, url FROM bookshops ORDER BY name")) {
        qWarning() << "Failed to load bookshops:" << query.lastError().text();
        emit errorOccurred("Failed to load bookshops: " + query.lastError().text());
        return;
    }

    QList<Bookshop> bookshops;
    while (query.next()) {
        Bookshop bookshop;
        bookshop.id = query.value(0).toInt();
        bookshop.name = query.value(1).toString();
        bookshop.url = query.value(2).toString();
        bookshops.append(bookshop);
    }

    m_bookshopsModel->setBookshops(bookshops);
}

bool BookshopManager::bookshopExists(const QString &name, const QString &url)
{
    QSqlQuery query(m_database);
    query.prepare("SELECT COUNT(*) FROM bookshops WHERE LOWER(name) = LOWER(?) OR LOWER(url) = LOWER(?)");
    query.addBindValue(name.trimmed());
    query.addBindValue(url.trimmed());

    if (query.exec() && query.next()) {
        return query.value(0).toInt() > 0;
    }

    return false;
}
