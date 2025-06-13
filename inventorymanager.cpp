#include "inventorymanager.h"

InventoryManager::InventoryManager(QObject *parent)
    : QObject{parent}
{
    db = DatabaseManager::getConnection();
    if (!db.open()){
        qDebug() << "Failed to open database - Inventory Manager : " +db.lastError().text();
    }
}

InventoryManager::~InventoryManager()
{
    //do something here for destructing
}

int InventoryManager::getTotalBooksCount()
{
    if (!db.open()){
        emit errorOccured("Failed to open database: " + db.lastError().text());
        return 0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT COUNT(*) FROM books WHERE availability != 'Deleted'")){
        emit errorOccured("Failed to get the total number of books: " + query.lastError().text());
        return 0;
    }

    while (query.next()){
        return query.value(0).toInt();
    }

    return 0;
}

int InventoryManager::getAvailableBooksCount()
{
    if (!db.open()){
        emit errorOccured("Failed to open database to get available books: " + db.lastError().text());
        return 0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT COUNT(*) FROM books WHERE availability = 'Available'")){
        emit errorOccured("Failed to get available books: " + query.lastError().text());
        return 0;
    }

    while (query.next()){
        return query.value(0).toInt();
    }

    return 0;
}

int InventoryManager::getCheckedOutBooksCount()
{
    if (!db.open()){
        emit errorOccured("Failed to open database for getting checked out books: " + db.lastError().text());
        return 0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT COUNT(*) FROM issued_books")){
        emit errorOccured("Failed to get checked out books: " + query.lastError().text());
        return 0;
    }

    while (query.next()){
        return query.value(0).toInt();
    }

    return 0;
}

int InventoryManager::getOverdueBooksCount()
{
    if (!db.open()){
        emit errorOccured("Failed to open the database for getting overdue books: " + db.lastError().text());
        return 0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT COUNT(*) FROM issued_books WHERE due_date < datetime('now')")){
        emit errorOccured("Failed to get overdue books: " + query.lastError().text());
        return 0;
    }

    while (query.next()){
        return query.value(0).toInt();
    }

    return 0;
}

int InventoryManager::getMissingBooksCount()
{
    if (!db.open()){
        emit errorOccured("Failed to open database to get lost books: " + db.lastError().text());
        return 0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT COUNT(*) FROM lost_books")){
        emit errorOccured("Failed to get missing books count: " + query.lastError().text());
        return 0;
    }

    while (query.next()){
        return query.value(0).toInt();
    }

    return 0;
}

double InventoryManager::getTotalOverdueFees()
{
    if (!db.open()){
        emit errorOccured("Failed to open database to get total fees: " + db.lastError().text());
        return 0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT SUM(fine_amount - fine_paid) FROM issued_books WHERE due_date < datetime('now')")){
        emit errorOccured("Failed to get total fees: " + query.lastError().text());
        return 0.0;
    }

    while (query.next()){
        return query.value(0).toDouble();
    }

    return 0.0;
}

double InventoryManager::getTotalReplacementCost()
{
    if (db.open()){
        emit errorOccured("Failed to open the database for getting the total replacement cost:" + db.lastError().text());
        return 0.0;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT SUM(replacement_cost) FROM lost_books")){
        emit errorOccured("Failed to get total replacement cost: " + query.lastError().text());
        return 0.0;
    }

    while (query.next()){
        return query.value(0).toDouble();
    }

    return 0.0;
}

bool InventoryManager::deleteBook(const QString &bookNumber)
{
    if (bookNumber.isEmpty()){
        emit errorOccured("Book number cannot be empty.");
        return false;
    }

    int bookId = getBookIdFromNumber(bookNumber);
    if (bookId == -1){
        emit errorOccured("Book could not be found: " + bookNumber);
        return false;
    }

    if (isBookCurrentlyIssued(bookNumber)){
        emit errorOccured("Cannot delete book that is currently issued.");
        return false;
    }

    //open the database
    if (!db.open()){
        emit errorOccured("Failed to open the database to delete book: " + db.lastError().text());
        return false;
    }

    QSqlQuery query(db);

    query.prepare("DELETE FROM books WHERE bookID = ?");
    query.addBindValue(bookId);

    if (!query.exec()){
        emit errorOccured("Failed to delete book: " + query.lastError().text());
        return false;
    }

    emit operationCompleted("Book deleted successfully: " + bookNumber);
    return true;
}

bool InventoryManager::archiveBook(const QString &bookNumber)
{
    if(bookNumber.isEmpty()){
        emit errorOccured("Book number cannot be empty.");
        return false;
    }

    int bookId = getBookIdFromNumber(bookNumber);
    if (bookId == -1){
        emit errorOccured("Could not find book: " + bookNumber);
        return false;
    }

    if (isBookCurrentlyIssued(bookNumber)){
        emit errorOccured("Cannot archive book that is currently issued.");
        return false;
    }


    if (!db.open()){
        emit errorOccured("Failed to open the database for archiving book: " + db.lastError().text());
        return false;
    }

    QSqlQuery query(db);
    query.prepare("UPDATE books SET availabilty = 'Archived' WHERE bookID = ?");
    query.addBindValue(bookId);

    if (!query.exec()){
        emit errorOccured("Failed to archive book: " + query.lastError().text());
        return false;
    }

    emit operationCompleted("Successfully archived book: " + bookNumber);
    return true;
}

QVariantList InventoryManager::getRecentAcquisitions(const QDate &fromDate)
{
    QVariantList results;

    if (!fromDate.isValid()){
        emit errorOccured("Invalid date provided.");
        return results;
    }

    if (!db.open()){
        emit errorOccured("Failed to open the database to get recent acquisitions: " + db.lastError().text());
        return results;
    }

    QSqlQuery query(db);

    query.prepare("SELECT bookID, title, author, callNumber, dateAdded, availability "
                  "FROM books "
                  "WHERE date(dateAdded) >= date(?) AND availability != 'Deleted' "
                  "ORDER BY dateAdded DESC");

    query.addBindValue(fromDate.toString("yyyy-MM-dd"));

    if (!query.exec()){
        emit errorOccured("Failed to get recently acquired books: " + query.lastError().text());
        return results;
    }

    while (query.next()){
        QVariantMap book;

        book["bookId"] = query.value("bookID").toString();
        book["title"] = query.value("title").toString();
        book["author"] = query.value("author").toString();
        book["callNumber"] = query.value("callNumber").toString();
        book["dateAdded"] = query.value("dateAdded").toString();
        book["availability"] = query.value("availability").toString();

        results.append(book);

        // qDebug() << book["title"] << book["dateAdded"];
    }

    return results;
}

void InventoryManager::getCountByCategory(const QString &category, const QString &searchTerm)
{
    QVariantList results;

    if (!isValidCategory(category)){
        emit errorOccured("Invalid category: " + category);
        return;
    }

    if(!db.open()){
        emit errorOccured("Failed to open the database for getting count by category: " + db.lastError().text());
        return;
    }

    QSqlQuery query(db);

    QString queryString = QString("SELECT %1, COUNT(*) AS count FROM books WHERE availability != 'Deleted'").arg(category);

    if (!searchTerm.isEmpty()){
        queryString += QString(" AND %1 LIKE ?").arg(category);
    }

    queryString += QString(" GROUP BY %1 ORDER BY count DESC").arg(category);

    query.prepare(queryString);

    if (!searchTerm.isEmpty()){
        query.addBindValue("%" +searchTerm+ "%");
    }

    if (!query.exec()){
        emit errorOccured("Failed to get count by category: " + query.lastError().text());
        return;
    }

    while (query.next()){
        QVariantMap item;

        item["category"] = query.value(0).toString();
        item["count"] = query.value("count").toInt();

        results.append(item);

        qDebug() << item["category"] << item["count"];
    }

    m_categoryCount = results;
    emit categoryCountChanged();
}

void InventoryManager::getItemsNeedingAttention()
{
    QVariantList results;

    if (!db.open()){
        emit errorOccured("Failed to open the database for getting items needing attention:" + db.lastError().text());
        return;
    }

    QSqlQuery query(db);

    if (!query.exec("SELECT bookID, title, author, callNumber, condition, shelfNumber "
                    "FROM books "
                    "WHERE condition = 'Damaged' AND availability != 'Deleted' "
                    "ORDER BY title")) {
        emit errorOccured("Failed to get items needing attention: " + query.lastError().text());

        return;
    }

    while (query.next()){
        QVariantMap book;

        book["booId"] = query.value("bookID").toString();
        book["title"] = query.value("title").toString();
        book["author"] = query.value("author").toString();
        book["callNumber"] = query.value("callNumber").toString();
        book["condition"] = query.value("condition").toString();
        book["shelfNumber"] = query.value("shelfNumber").toString();

        results.append(book);
    }

    m_attentionItems = results;
    emit attentionItemsChanged();
}

void InventoryManager::getBooksUnderMaintenance()
{
    QVariantList results;

    QSqlQuery query(db);
    if (!query.exec("SELECT bookID, title, author, callNumber, condition, shelfNumber "
                    "FROM books "
                    "WHERE availability = 'Under Maintenance' "
                    "ORDER BY title")) {
        emit errorOccured("Failed to get books under maintenance: " + query.lastError().text());
        return;
    }

    while (query.next()) {
        QVariantMap book;
        book["bookId"] = query.value("bookID").toInt();
        book["title"] = query.value("title").toString();
        book["author"] = query.value("author").toString();
        book["callNumber"] = query.value("callNumber").toString();
        book["condition"] = query.value("condition").toString();
        book["shelfNumber"] = query.value("shelfNumber").toString();
        results.append(book);
    }

    m_underMaintenance = results;
    emit underMaintenanceChanged();
}

void InventoryManager::getNumberOfCopies()
{
    QVariantList results;

    qDebug() << "Control reaches this: 1";

    if (!db.open()){
        emit errorOccured("Failed to open database for getting the number of copies:" + db.lastError().text());
        return;
    }

    QSqlQuery query(db);
    if (!query.exec("SELECT title, isbn, COUNT(*) as copies "
                    "FROM books "
                    "WHERE availability != 'Deleted' "
                    "GROUP BY COALESCE(isbn, title) "
                    "HAVING COUNT(*) > 1 "
                    "ORDER BY copies DESC, title")) {
        emit errorOccured("Failed to get number of copies: " + query.lastError().text());
        return;
    }

    qDebug() << "Control reaches this: 2";

    while (query.next()) {
        QVariantMap book;
        book["title"] = query.value("title").toString();
        book["isbn"] = query.value("isbn").toString();
        book["copies"] = query.value("copies").toInt();
        results.append(book);
    }

    qDebug() << "Control reaches this: 3";

    m_copies = results;
    emit copiesChanged();
}

bool InventoryManager::bookExists(const QString &bookNumber)
{
    return getBookIdFromNumber(bookNumber) != -1;
}

bool InventoryManager::isBookCurrentlyIssued(const QString &bookNumber)
{
    int bookId = getBookIdFromNumber(bookNumber);

    if(bookId == -1){
        return false;
    }

    if (!db.open()){
        emit errorOccured("Failed to open the database: " + db.lastError().text());
        return false;
    }

    QSqlQuery query(db);

    query.prepare("SELECT COUNT(*) FROM issued_books WHERE book_id = ?");

    if (!query.exec()){
        emit errorOccured("Failed to determine if the book is issued: " + query.lastError().text());
        return false;
    }

    while (query.next()){
        return query.value(0).toInt() > 0;
    }

    return false;
}

void InventoryManager::updateRecentAcquisitions(const QDate &fromDate)
{
    if (!fromDate.isValid()){
        emit errorOccured("Invalid date provided.");
        return;
    }

    m_recentAcquisitions = getRecentAcquisitions(fromDate);

    emit recentAcquisitionsChanged();
}

int InventoryManager::getBookIdFromNumber(const QString &bookNumber)
{
    if (!db.open()){
        emit errorOccured("Failed to open the database to get: " + db.lastError().text());
        return -1;
    }

    QSqlQuery query(db);

    query.prepare("SELECT bookID FROM books WHERE "
                  "(callNumber = ? OR barcode = ? OR bookID = ?) "
                  "AND availability != 'Deleted'");
    query.addBindValue(bookNumber);
    query.addBindValue(bookNumber);
    query.addBindValue(bookNumber);

    if (!query.exec()){
        emit errorOccured("Failed to find book: " + query.lastError().text());
        return -1;
    }

    if (query.next()){
        return query.value("bookID").toInt();
    }

    return -1;
}

bool InventoryManager::isValidCategory(const QString &category)
{
    QStringList validCategories = {"title", "author", "subject", "genre", "publisher"};
    return validCategories.contains(category.toLower());
}


void InventoryManager::getBooksByShelf()
{
    QVariantList results;

    if (!db.open()){
        emit errorOccured("Failed to open the database for getting books by shelf: " + db.lastError().text());
        return;
    }

    QSqlQuery query(db);
    if (!query.exec("SELECT shelfNumber, COUNT(*) as count "
                    "FROM books "
                    "WHERE shelfNumber IS NOT NULL AND shelfNumber != '' AND availability != 'Deleted' "
                    "GROUP BY shelfNumber "
                    "ORDER BY shelfNumber")) {
        emit errorOccured("Failed to get books by shelf: " + query.lastError().text());
        return;
    }

    while (query.next()) {
        QVariantMap shelf;
        shelf["shelfNumber"] = query.value("shelfNumber").toString();
        shelf["count"] = query.value("count").toInt();
        results.append(shelf);
    }

    m_shelfList = results;
    emit shelfListChanged();
}


























