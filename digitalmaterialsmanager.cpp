#include "digitalmaterialsmanager.h"
#include "databasemanager.h"
#include <QSqlTableModel>
#include <QSqlQueryModel>

DigitalMaterialsManager::DigitalMaterialsManager(QObject *parent)
    : QObject{parent}
    ,m_itemsModel(new DigitalMaterialsModel(this))
    ,m_historyModel(new DigitalMaterialsHistoryModel(this))
    ,m_connectionName("DigitalMaterialsConnection")
{
    if(!initializeDatabase()){
        emit errorOccured("Database initialization failed, database operations will not occur.");
    }
}

DigitalMaterialsManager::~DigitalMaterialsManager()
{
    //do something here when the class destructs ( would close db but will bring conflict in other parts of the app)
}

QAbstractListModel *DigitalMaterialsManager::itemsModel() const
{
    return  m_itemsModel;
}

QAbstractListModel *DigitalMaterialsManager::historyModel() const
{
    return m_historyModel;
}

bool DigitalMaterialsManager::initializeDatabase()
{
    m_database = DatabaseManager::getConnection();

    if(!m_database.open()){
        qDebug() << "(DigitalMaterials) Failed to open the database: " << m_database.lastError().text();
        emit errorOccured("(DigitalMaterials) Failed to open the database: " + m_database.lastError().text());
        return false;
    }

    createTables();
    refreshItems();
    refreshHistory();
    return true;
}

//this function is unnecessary and only kept for backward compatibility
void DigitalMaterialsManager::setDatabaseConnection(const QString &connectionName)
{
    m_connectionName = connectionName;
    m_database = QSqlDatabase::database(connectionName);

    if (m_database.isValid() && m_database.isOpen()) {
        createTables();
        refreshItems();
        refreshHistory();
    }
}

void DigitalMaterialsManager::getUserBorrowedQuantity(int itemID, const QString &userNumber)
{
    if (!m_database.open()){
        emit userBorrowedQuantityChecked(userNumber, 0, "Database connection failed");
        return;
    }

    QSqlQuery query(m_database);
    query.prepare(R"(
        SELECT SUM(quantity_borrowed) as user_borrowed_quantity
        FROM digital_materials_loans
        WHERE item_id = ? AND user_number = ? AND status = 'Borrowed'
    )");
    query.addBindValue(itemID);
    query.addBindValue(userNumber);

    if (!query.exec() || !query.next()) {
        emit userBorrowedQuantityChecked(userNumber, 0, "Query failed");
        return;
    }

    int userBorrowedQuantity = query.value("user_borrowed_quantity").toInt();
    QString message;

    if (userBorrowedQuantity > 0) {
        message = QString("User %1 has borrowed %2 items").arg(userNumber).arg(userBorrowedQuantity);
    } else {
        message = QString("User %1 has not borrowed this item").arg(userNumber);
    }

    emit userBorrowedQuantityChecked(userNumber, userBorrowedQuantity, message);
}

void DigitalMaterialsManager::refreshItems()
{
    if (!m_database.open()){
        qDebug() << "Failed to open the database for refreshing items: " << m_database.lastError().text();
        emit errorOccured("Failed to open the database for refreshing items: " + m_database.lastError().text());
        return;
    }

    QSqlQuery query(m_database);
    QString queryString = R"(
        SELECT ItemID, ItemName, ItemType, quantity, quantityBorrowed,
               holder, dateAdded, dateBorrowed, location, condition,
               value, status, details
        FROM digital_materials
        ORDER BY dateAdded DESC
    )";

    query.prepare(queryString);
    if (!query.exec()){
        emit errorOccured("Failed to refresh items.");
        return;
    }


    QList<QVariantMap> items;

    while(query.next()){
        QVariantMap item;
        item["itemID"] = query.value("itemID").toString();
        item["itemName"] = query.value("itemName").toString();
        item["itemType"] = query.value("itemType").toString();
        item["quantity"] = query.value("quantity").toInt();
        item["quantityBorrowed"] = query.value("quantityBorrowed").toInt();
        item["holder"]  = query.value("holder").toString();
        item["dateAdded"] = query.value("dateAdded").toDateTime().toString("yyyy-MM-dd hh-mm");
        item["dateBorrowed"] = query.value("dateBorrowed").toDateTime().toString("yyyy-MM-dd hh-mm");
        item["location"] = query.value("location").toString();
        item["condition"] = query.value("condition").toString();
        item["value"] = query.value("value").toDouble();
        item["status"] = query.value("status").toString();
        item["details"] = query.value("details").toString();

        items.append(item);
    }

    m_itemsModel->setItems(items);
    emit itemsModelChanged();
}

bool DigitalMaterialsManager::addItem(const QString &itemName, const QString &itemType, int quantity, const QString &location, const QString &condition, double value, const QString &status, const QString &details)
{
    if (!m_database.open()){
        emit errorOccured("Failed to open the database for adding an item");
        return false;
    }

    QSqlQuery query(m_database);

    QString queryString = R"(
        INSERT INTO digital_materials
        (ItemName, ItemType, quantity, location, condition, value, status, details)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    )";

    query.prepare(queryString);

    query.addBindValue(itemName);
    query.addBindValue(itemType);
    query.addBindValue(quantity);
    query.addBindValue(location.isEmpty() ? QVariant(QVariant::String) : location);
    query.addBindValue(condition.isEmpty() ? QVariant(QVariant::String) : condition);
    query.addBindValue(value);
    query.addBindValue(status);
    query.addBindValue(details.isEmpty() ? QVariant(QVariant::String) : details);

    if(!query.exec()){
        emit errorOccured("Failed to add item: " + query.lastError().text());
        return false;
    }

    refreshItems();
    emit itemAdded(itemName);
    return true;
}

bool DigitalMaterialsManager::updateItem(int itemID, const QString &itemName, const QString &itemType, int quantity, const QString &location, const QString &condition, double value, const QString &status, const QString &details)
{
    if(!m_database.open()){
        emit errorOccured("Failed to open the database for updating item: " + m_database.lastError().text());
        return false;
    }

    QSqlQuery query(m_database);

    QString queryString = R"(
        UPDATE digital_materials
        SET ItemName = ?, quantity = ?, location = ?,
            condition = ?, value = ?, status = ?, details = ?
        WHERE ItemID = ?
    )";

    query.prepare(queryString);
    query.addBindValue(itemName);
    query.addBindValue(quantity);
    query.addBindValue(location.isEmpty() ? QVariant(QVariant::String) : location);
    query.addBindValue(condition.isEmpty() ? QVariant(QVariant::String) : condition);
    query.addBindValue(value);
    query.addBindValue(status);
    query.addBindValue(details.isEmpty() ? QVariant(QVariant::String) : details);
    query.addBindValue(itemID);

    if (!query.exec()){
        emit errorOccured("Failed to update item: " + query.lastError().text());
        return false;
    }

    refreshItems();
    emit itemUpdated(itemName);
    return true;
}

bool DigitalMaterialsManager::deleteItem(int itemID)
{
    if (!m_database.open()){
        emit errorOccured("Failed to open the database for deleting item: " + m_database.lastError().text());
        return false;
    }

    QSqlQuery selectQuery(m_database);
    selectQuery.prepare("SELECT ItemName from digital_materials WHERE ItemID = ?");
    selectQuery.addBindValue(itemID);

    QString itemName;
    if(selectQuery.exec() && selectQuery.next()){
        itemName = selectQuery.value(0).toString();
    }

    //check if the item has any borrowed quantity
    QSqlQuery checkQuery(m_database);
    checkQuery.prepare("SELECT quantityBorrowed from digital_materials WHERE itemID = ?");
    checkQuery.addBindValue(itemID);

    if (checkQuery.exec() && checkQuery.next()){
        int borrowedQty = checkQuery.value(0).toInt();
        if (borrowedQty > 0) {
            emit errorOccured("Cannot delete an item with borrowed quantities.");
            return false;
        }
    }

    QSqlQuery deleteQuery(m_database);
    deleteQuery.prepare("DELETE FROM digital_materials WHERE itemID = ?");
    deleteQuery.addBindValue(itemID);

    if(!deleteQuery.exec()){
        emit errorOccured("Failed to delete item: " + deleteQuery.lastError().text());
        return false;
    }

    refreshItems();
    emit itemDeleted(itemName);
    return true;
}

bool DigitalMaterialsManager::issueItem(int itemID, const QString &userNumber, int quantity)
{
    if (!isValidUser(userNumber)){
        emit errorOccured("User not found in the system");
        return false;
    }

    if (!m_database.open()){
        emit errorOccured("Failed to open the database to issue item: " + m_database.lastError().text());
        return false;
    }

    QSqlQuery checkQuery(m_database);
    checkQuery.prepare(R"(
        SELECT ItemName, quantity, quantityBorrowed
        FROM digital_materials
        WHERE ItemID = ?
    )");
    checkQuery.addBindValue(itemID);

    if (!checkQuery.exec() || !checkQuery.next()){
        emit errorOccured("No items found!");
        return false;
    }

    QString itemName = checkQuery.value("ItemName").toString();
    int totalQuantity = checkQuery.value("quantity").toInt();
    int borrowedQuantity = checkQuery.value("quantityBorrowed").toInt();
    int availableQuantity = totalQuantity - borrowedQuantity;

    if (quantity > availableQuantity){
        emit errorOccured(QString("Insufficient items available.\nAvailable items: %1").arg(availableQuantity));
        return false;
    }

    //START A TRANSACTION
    m_database.transaction();

    //update items borrowed quantity and holder
    QSqlQuery updateQuery(m_database);
    updateQuery.prepare(R"(
        UPDATE digital_materials
        SET quantityBorrowed = quantityBorrowed + ?,
            holder = CASE
                WHEN holder IS NULL OR holder = '' THEN ?
                ELSE holder || ', ' || ?
            END,
            dateBorrowed = CURRENT_TIMESTAMP,
            status = CASE
                WHEN (quantity - quantityBorrowed - ?) = 0 THEN 'Borrowed'
                ELSE 'Available'
            END
        WHERE ItemID = ?
    )");

    updateQuery.addBindValue(quantity);
    updateQuery.addBindValue(userNumber);
    updateQuery.addBindValue(userNumber);
    updateQuery.addBindValue(quantity);
    updateQuery.addBindValue(itemID);

    if (!updateQuery.exec()){
        m_database.rollback();
        emit errorOccured("Failed to update items: " + updateQuery.lastError().text());
        return false;
    }

    QSqlQuery historyQuery(m_database);
    historyQuery.prepare(R"(
        INSERT INTO digital_materials_loans
        (item_id, item_name, user_number, quantity_borrowed)
        VALUES (?, ?, ?, ?)
    )");
    historyQuery.addBindValue(itemID);
    historyQuery.addBindValue(itemName);
    historyQuery.addBindValue(userNumber);
    historyQuery.addBindValue(quantity);

    if (!historyQuery.exec()){
        m_database.rollback();
        emit errorOccured("Failed to record loan: " + historyQuery.lastError().text());
        return false;
    }

    m_database.commit();
    refreshItems();
    refreshHistory();
    emit itemIssued(itemName, userNumber, quantity);
    return true;
}

//new returnItem function
bool DigitalMaterialsManager::returnItem(int itemID, int quantity, const QString& userNumber)
{
    qDebug() << "Item ID: " << itemID << "Quantity: " << quantity << "User Number: " << userNumber;

    if (!m_database.open()){
        emit errorOccured("Failed to open the database for returning an item: " + m_database.lastError().text());
        return false;
    }

    // Check if item exists
    QSqlQuery checkQuery(m_database);
    checkQuery.prepare(R"(
        SELECT ItemName, quantityBorrowed
        FROM digital_materials
        WHERE ItemID = ?
    )");
    checkQuery.addBindValue(itemID);
    if (!checkQuery.exec() || !checkQuery.next()){
        emit errorOccured("Item not found!");
        return false;
    }

    QString itemName = checkQuery.value("ItemName").toString();
    int totalBorrowedQuantity = checkQuery.value("quantityBorrowed").toInt();

    // Check if user has borrowed this item and get their borrowed quantity
    QSqlQuery userBorrowQuery(m_database);
    userBorrowQuery.prepare(R"(
        SELECT SUM(quantity_borrowed) as user_borrowed_quantity
        FROM digital_materials_loans
        WHERE item_id = ? AND user_number = ? AND status = 'Borrowed'
    )");
    userBorrowQuery.addBindValue(itemID);
    userBorrowQuery.addBindValue(userNumber);

    if (!userBorrowQuery.exec() || !userBorrowQuery.next()){
        emit errorOccured("Failed to check user's borrowed quantity!");
        return false;
    }

    int userBorrowedQuantity = userBorrowQuery.value("user_borrowed_quantity").toInt();

    if (userBorrowedQuantity == 0) {
        emit errorOccured("User " + userNumber + " has not borrowed this item!");
        return false;
    }

    if (quantity > userBorrowedQuantity){
        emit errorOccured("User " + userNumber + " has only borrowed " + QString::number(userBorrowedQuantity) + " items. Cannot return " + QString::number(quantity));
        return false;
    }

    //START TRANSACTION
    m_database.transaction();

    // Update the main digital_materials table
    QSqlQuery updateQuery(m_database);
    updateQuery.prepare(R"(
        UPDATE digital_materials
        SET quantityBorrowed = quantityBorrowed - ?,
            status = CASE
                WHEN (quantityBorrowed - ?) = 0 THEN 'Available'
                ELSE status
            END
        WHERE ItemID = ?
    )");
    updateQuery.addBindValue(quantity);
    updateQuery.addBindValue(quantity);
    updateQuery.addBindValue(itemID);

    if(!updateQuery.exec()){
        m_database.rollback();
        emit errorOccured("Failed to update item: " + updateQuery.lastError().text());
        return false;
    }

    // Get loan records ordered by date (oldest first) for processing partial returns
    QSqlQuery loanQuery(m_database);
    loanQuery.prepare(R"(
        SELECT loan_id, quantity_borrowed FROM digital_materials_loans
        WHERE item_id = ? AND user_number = ? AND status = 'Borrowed'
        ORDER BY issue_date ASC
    )");
    loanQuery.addBindValue(itemID);
    loanQuery.addBindValue(userNumber);

    if (!loanQuery.exec()) {
        m_database.rollback();
        emit errorOccured("Failed to select loan records: " + loanQuery.lastError().text());
        return false;
    }

    // Process returns: handle partial returns of individual loan records
    int remainingToReturn = quantity;
    QList<int> loansToMarkReturned;
    QList<QPair<int, int>> loansToSplit; // loan_id, new_quantity pairs

    while (loanQuery.next() && remainingToReturn > 0) {
        int loanId = loanQuery.value("loan_id").toInt();
        int loanQuantity = loanQuery.value("quantity_borrowed").toInt();

        if (remainingToReturn >= loanQuantity) {
            // Return entire loan record
            loansToMarkReturned << loanId;
            remainingToReturn -= loanQuantity;
        } else {
            // Partial return: need to split this loan record
            loansToSplit << qMakePair(loanId, loanQuantity - remainingToReturn);
            remainingToReturn = 0;
        }
    }

    // Mark complete loan records as returned
    if (!loansToMarkReturned.isEmpty()) {
        QStringList placeholders;
        for (int i = 0; i < loansToMarkReturned.size(); ++i) {
            placeholders << "?";
        }

        QSqlQuery markReturnedQuery(m_database);
        QString markReturnedSql = QString(R"(
            UPDATE digital_materials_loans
            SET return_date = CURRENT_TIMESTAMP, status = 'Returned'
            WHERE loan_id IN (%1)
        )").arg(placeholders.join(","));
        markReturnedQuery.prepare(markReturnedSql);

        for (int loanId : loansToMarkReturned) {
            markReturnedQuery.addBindValue(loanId);
        }

        if (!markReturnedQuery.exec()) {
            m_database.rollback();
            emit errorOccured("Failed to mark loan records as returned: " + markReturnedQuery.lastError().text());
            return false;
        }
    }

    // Handle partial returns by splitting loan records
    for (auto& splitPair : loansToSplit) {
        int originalLoanId = splitPair.first;
        int newQuantity = splitPair.second;

        // Get original loan data
        QSqlQuery originalLoanQuery(m_database);
        originalLoanQuery.prepare(R"(
            SELECT item_name, user_id, user_number, issue_date
            FROM digital_materials_loans
            WHERE loan_id = ?
        )");
        originalLoanQuery.addBindValue(originalLoanId);

        if (!originalLoanQuery.exec() || !originalLoanQuery.next()) {
            m_database.rollback();
            emit errorOccured("Failed to get original loan data for splitting");
            return false;
        }

        QString itemNameFromLoan = originalLoanQuery.value("item_name").toString();
        QVariant userId = originalLoanQuery.value("user_id");
        QString userNumberFromLoan = originalLoanQuery.value("user_number").toString();
        QString issueDate = originalLoanQuery.value("issue_date").toString();

        // Mark original loan as returned
        QSqlQuery markOriginalReturned(m_database);
        markOriginalReturned.prepare(R"(
            UPDATE digital_materials_loans
            SET return_date = CURRENT_TIMESTAMP, status = 'Returned'
            WHERE loan_id = ?
        )");
        markOriginalReturned.addBindValue(originalLoanId);

        if (!markOriginalReturned.exec()) {
            m_database.rollback();
            emit errorOccured("Failed to mark original loan as returned during split");
            return false;
        }

        // Create new loan record for remaining quantity
        QSqlQuery createNewLoan(m_database);
        createNewLoan.prepare(R"(
            INSERT INTO digital_materials_loans
            (item_id, item_name, user_id, user_number, quantity_borrowed, issue_date, status)
            VALUES (?, ?, ?, ?, ?, ?, 'Borrowed')
        )");
        createNewLoan.addBindValue(itemID);
        createNewLoan.addBindValue(itemNameFromLoan);
        if (userId.isNull()) {
            createNewLoan.addBindValue(QVariant());
        } else {
            createNewLoan.addBindValue(userId);
        }
        createNewLoan.addBindValue(userNumberFromLoan);
        createNewLoan.addBindValue(newQuantity);
        createNewLoan.addBindValue(issueDate);

        if (!createNewLoan.exec()) {
            m_database.rollback();
            emit errorOccured("Failed to create new loan record for remaining quantity: " + createNewLoan.lastError().text());
            return false;
        }
    }

    m_database.commit();
    refreshItems();
    refreshHistory();
    emit itemReturned(itemName, quantity);
    return true;
}


bool DigitalMaterialsManager::isValidUser(const QString &userNumber)
{
    //check if the user exists in the student, staff and other_users table
    if(!m_database.open()){
        emit errorOccured("Failed to open the database for user validation:" + m_database.lastError().text());
        return false;
    }

    QSqlQuery query(m_database);

    //check the students table
    query.prepare("SELECT COUNT(*) FROM students   WHERE adm_no = ?");
    query.addBindValue(userNumber);

    if (query.exec() && query.next() && query.value(0).toInt() > 0){
        return true;
    }

    //check the staff table
    query.prepare("SELECT COUNT(*) FROM staff WHERE staff_no = ?");
    query.addBindValue(userNumber);

    if(query.exec() && query.next() && query.value(0).toInt() > 0){
        return true;
    }

    //check the other users table
    query.prepare("SELECT COUNT(*) FROM other_users WHERE user_no = ?");
    query.addBindValue(userNumber);

    if(query.exec() && query.next() && query.value(0).toInt() > 0){
        return true;
    }

    return false;
}

void DigitalMaterialsManager::refreshHistory()
{
    if (!m_database.open()){
        emit errorOccured("Failed to open the database for refreshing history: " + m_database.lastError().text());
        return;
    }

    QSqlQuery query(m_database);
    QString queryString = R"(
        SELECT loan_id, item_id, item_name, user_id, user_number,
               quantity_borrowed, issue_date, return_date, status
        FROM digital_materials_loans
        ORDER BY issue_date DESC
    )";

    if (!query.exec(queryString)){
        emit errorOccured("Failed to refresh history: " + query.lastError().text());
        return;
    }

    QList<QVariantMap> history;
    while (query.next()) {
        QVariantMap record;
        record["loanID"] = query.value("loan_id").toInt();
        record["itemID"] = query.value("item_id").toInt();
        record["itemName"] = query.value("item_name").toString();
        record["userID"] = query.value("user_id").toInt();
        record["userNumber"] = query.value("user_number").toString();
        record["quantityBorrowed"] = query.value("quantity_borrowed").toInt();
        record["issueDate"] = query.value("issue_date").toDateTime().toString("yyyy-MM-dd");
        record["returnDate"] = query.value("return_date").isNull() ?
                                   QString() : query.value("return_date").toDateTime().toString("yyyy-MM-dd");
        record["status"] = query.value("status").toString();
        history.append(record);
    }

    m_historyModel->setHistory(history);
    emit historyModelChanged();
}


//redundant code, tables already created in the database manager class
void DigitalMaterialsManager::createTables()
{
    if (!m_database.open()){
        emit errorOccured("Failed to open the database for creating tables: " + m_database.lastError().text());
        return;
    }

    QSqlQuery query(m_database);

    // Create digital_materials table
    QString createItemsTable = R"(
        CREATE TABLE IF NOT EXISTS digital_materials (
            ItemID INTEGER PRIMARY KEY AUTOINCREMENT,
            ItemName TEXT NOT NULL,
            ItemType TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 0,
            quantityBorrowed INTEGER NOT NULL DEFAULT 0,
            holder TEXT,
            dateAdded DATETIME DEFAULT CURRENT_TIMESTAMP,
            dateBorrowed DATETIME,
            location TEXT,
            condition TEXT,
            value REAL DEFAULT 0.0,
            status TEXT DEFAULT 'Available',
            details TEXT
        )
    )";

    if (!executeQuery(query, createItemsTable)) {
        emit errorOccured("Failed to create digital_materials table");
        return;
    }

    // Create digital_materials_loans table for history
    QString createLoansTable = R"(
        CREATE TABLE IF NOT EXISTS digital_materials_loans (
            loan_id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            user_id INTEGER,
            user_number TEXT NOT NULL,
            quantity_borrowed INTEGER NOT NULL,
            issue_date DATETIME DEFAULT CURRENT_TIMESTAMP,
            return_date DATETIME,
            status TEXT DEFAULT 'Borrowed',
            FOREIGN KEY (item_id) REFERENCES digital_materials(ItemID)
        )
    )";

    if (!executeQuery(query, createLoansTable)) {
        emit errorOccured("Failed to create digital_materials_loans table");
        return;
    }
}

bool DigitalMaterialsManager::executeQuery(QSqlQuery query, const QString &operation)
{
    query.prepare(operation);
    if(!query.exec()){
        qDebug() << "Failed to execute query: " << query.lastError().text();
        qDebug() << "Operation: " << operation;

        return false;
    }

    return true;
}




DigitalMaterialsModel::DigitalMaterialsModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int DigitalMaterialsModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_items.count();
}

QVariant DigitalMaterialsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.count())
        return QVariant();

    const QVariantMap &item = m_items.at(index.row());

    switch (role){
    case ItemIDRole:
        return item.value("itemID");
    case ItemNameRole:
        return item.value("itemName");
    case ItemTypeRole:
        return item.value("itemType");
    case QuantityRole:
        return item.value("quantity");
    case QuantityBorrowedRole:
        return item.value("quantityBorrowed");
    case HolderRole:
        return item.value("holder");
    case DateAddedRole:
        return item.value("dateAdded");
    case DateBorrowedRole:
        return item.value("dateBorrowed");
    case LocationRole:
        return item.value("location");
    case ConditionRole:
        return item.value("condition");
    case ValueRole:
        return item.value("value");
    case StatusRole:
        return item.value("status");
    case DetailRole:
        return item.value("details");
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> DigitalMaterialsModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[ItemIDRole] = "itemID";
    roles[ItemNameRole] = "itemName";
    roles[ItemTypeRole] = "itemType";
    roles[QuantityRole] = "quantity";
    roles[QuantityBorrowedRole] = "quantityBorrowed";
    roles[HolderRole] = "holder";
    roles[DateAddedRole] = "dateAdded";
    roles[DateBorrowedRole] = "dateBorrowed";
    roles[LocationRole] = "location";
    roles[ConditionRole] = "condition";
    roles[ValueRole] = "value";
    roles[StatusRole] = "status";
    roles[DetailRole] = "details";
    return roles;
}

void DigitalMaterialsModel::setItems(const QList<QVariantMap> &items)
{
    beginResetModel();
    m_items = items;
    endResetModel();
}

void DigitalMaterialsModel::clear()
{
    beginResetModel();
    m_items.clear();
    endResetModel();
}


//DigitalMaterialHistoryModel
DigitalMaterialsHistoryModel::DigitalMaterialsHistoryModel(QObject *parent)
    :QAbstractListModel(parent)
{
}

int DigitalMaterialsHistoryModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_history.count();
}

QVariant DigitalMaterialsHistoryModel::data(const QModelIndex &index, int role) const
{
    if(!index.isValid() || index.row() >= m_history.count())
        return QVariant();

    const QVariantMap &record = m_history.at(index.row());

    switch (role){
    case LoanIDRole:
        return record.value("loanID");
    case ItemIDRole:
        return record.value("itemID");
    case ItemNameRole:
        return record.value("itemName");
    case UserIDRole:
        return record.value("userID");
    case UserNumberRole:
        return record.value("userNumber");
    case QuantityBorrowedRole:
        return record.value("quantityBorrowed");
    case IssueDateRole:
        return record.value("issueDate");
    case ReturnDateRole:
        return record.value("returnDate");
    case StatusRole:
        return record.value("status");
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> DigitalMaterialsHistoryModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[LoanIDRole] = "loanID";
    roles[ItemIDRole] = "itemID";
    roles[ItemNameRole] = "itemName";
    roles[UserIDRole] = "userID";
    roles[UserNumberRole] = "userNumber";
    roles[QuantityBorrowedRole] = "quantityBorrowed";
    roles[IssueDateRole] = "issueDate";
    roles[ReturnDateRole] = "returnDate";
    roles[StatusRole] = "status";
    return roles;
}

void DigitalMaterialsHistoryModel::setHistory(const QList<QVariantMap> &history)
{
    beginResetModel();
    m_history = history;
    endResetModel();
}

void DigitalMaterialsHistoryModel::clear()
{
    beginResetModel();
    m_history.clear();
    endResetModel();
}
