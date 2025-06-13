#include "singlebookreturn.h"
#include "databasemanager.h"

SingleBookReturn::SingleBookReturn(QObject *parent)
    : QObject{parent}, m_hasBookData(false), m_currentAdminId(1)
{
    db = DatabaseManager::getConnection();

    if(!db.open()){
        qDebug() << "SingleBookReturn...Failed to open the database: " + db.lastError().text();
    }
}

SingleBookReturn::~SingleBookReturn(){
    //does nothing
}

QString SingleBookReturn::bookTitle() const
{
    return m_hasBookData ? m_currentBook.bookTitle : QString();
}

QString SingleBookReturn::callNumber() const
{
    return m_hasBookData ? m_currentBook.callNumber : QString();
}

QString SingleBookReturn::userName() const
{
    return m_hasBookData ? m_currentBook.userName : QString();
}

QString SingleBookReturn::userNumber() const
{
    return m_hasBookData ? m_currentBook.userNumber : QString();
}

QDateTime SingleBookReturn::issueDate() const
{
    return m_hasBookData ? m_currentBook.issueDate : QDateTime();
}

QDateTime SingleBookReturn::dueDate() const
{
    return m_hasBookData ? m_currentBook.dueDate : QDateTime();
}

QString SingleBookReturn::status() const
{
    return m_hasBookData ? m_currentBook.status : QString();
}

double SingleBookReturn::fineAmount() const
{
    return m_hasBookData ? m_currentBook.fineAmount : 0.0;
}

QString SingleBookReturn::condition() const
{
    return m_hasBookData ? m_currentBook.condition : QString();
}

bool SingleBookReturn::hasBookData() const
{
    return m_hasBookData;
}

bool SingleBookReturn::searchByCallNumber(const QString &callNumber)
{
    if (callNumber.trimmed().isEmpty()){
        emit errorOccured("CallNumber cannot be empty.");
        return false;
    }

    return loadBookFromDatabase("b.callNumber", callNumber.trimmed());
}

bool SingleBookReturn::searchByBarcode(const QString &barcode)
{
    if (barcode.trimmed().isEmpty()){
        emit errorOccured("Barcode cannot be empty.");
        return false;
    }

    return loadBookFromDatabase("b.barcode", barcode.trimmed());
}

bool SingleBookReturn::returnCurrentBook()
{
    if (!m_hasBookData){
        emit errorOccured("Book data empty, no book to return.");
        return false;
    }

    if (!db.open()){
        emit errorOccured("Database not open." + db.lastError().text());
        return false;
    }

    db.transaction();

    if (processBookReturn(m_currentBook)){
        db.commit();
        emit operationSuccessful(
            QString("Successfully returned book: %1").arg(m_currentBook.callNumber)
            );
        clearBookData();
        return true;
    }else {
        db.rollback();
        emit errorOccured("Failed to return book: " + m_currentBook.callNumber);
        return false;
    }
}

void SingleBookReturn::clearBookData()
{
    m_hasBookData = false;
    m_currentBook = BookInfo{};
    emit bookDataChanged();
}

bool SingleBookReturn::loadBookFromDatabase(const QString &searchColumn, const QString &searchValue)
{
    if (!db.open()){
        emit errorOccured("Database not open" + db.lastError().text());
        return false;
    }

    QSqlQuery query(db);

    QString querySQL =
        "SELECT "
        "ib.issue_id, ib.book_id, ib.user_id, ib.issue_date, ib.due_date, "
        "ib.fine_amount, ib.condition_before, "
        "(u.first_name || ' ' || u.second_name) as user_name, "
        "u.email, u.phone, u.user_role, "
        "b.title as book_title, b.callNumber, b.author, b.value as book_value, "
        "COALESCE(s.adm_no, st.staff_no, ou.user_no) as user_number "
        "FROM issued_books ib "
        "LEFT JOIN users u ON ib.user_id = u.user_id "
        "LEFT JOIN books b ON ib.book_id = b.bookID "
        "LEFT JOIN students s ON u.user_id = s.student_id "
        "LEFT JOIN staff st ON u.user_id = st.staff_id "
        "LEFT JOIN other_users ou ON u.user_id = ou.other_users_id "
        "WHERE ib.status = 'Borrowed' AND " + searchColumn + " = ? "
        "ORDER BY ib.issue_date DESC LIMIT 1";

    if(!query.prepare(querySQL)){
        emit errorOccured("Failed to prepare query" + query.lastError().text());
        return false;
    }

    query.addBindValue(searchValue);

    if (!query.exec()){
        emit errorOccured("Error searching for book: " + query.lastError().text());
        return false;
    }

    if (!query.next()){
        emit bookNotFound(searchValue);
        clearBookData();
        return false;
    }

    // Populate book data
    m_currentBook.issueId = query.value("issue_id").toInt();
    m_currentBook.bookId = query.value("book_id").toInt();
    m_currentBook.userId = query.value("user_id").toInt();
    m_currentBook.userName = query.value("user_name").toString();
    m_currentBook.callNumber = query.value("callNumber").toString();
    m_currentBook.bookTitle = query.value("book_title").toString();
    m_currentBook.bookAuthor = query.value("author").toString();
    m_currentBook.issueDate = query.value("issue_date").toDateTime();
    m_currentBook.dueDate = query.value("due_date").toDateTime();
    m_currentBook.bookValue = query.value("book_value").toDouble();
    m_currentBook.condition = query.value("condition_before").toString();
    m_currentBook.userEmail = query.value("email").toString();
    m_currentBook.userPhone = query.value("phone").toString();
    m_currentBook.userRole = query.value("user_role").toString();
    m_currentBook.userNumber = query.value("user_number").toString();

    QDateTime currentDate = QDateTime::currentDateTime();
    m_currentBook.status = calculateStatus(m_currentBook.dueDate, currentDate);
    m_currentBook.fineAmount = calculateLateFees(m_currentBook.dueDate, currentDate);

    if (m_currentBook.status == "Probably lost"){
        addToLostBooks(m_currentBook);
    }

    m_hasBookData = true;
    emit bookFound();
    emit bookDataChanged();
    return true;
}

QString SingleBookReturn::calculateStatus(const QDateTime &dueDate, const QDateTime &currentDate)
{
    qint64 overdueDays = dueDate.daysTo(currentDate);

    if (overdueDays <= 0){
        return "Pending";
    }else if (overdueDays <= 90){
        return "Overdue";
    }else {
        return "Probably lost";
    }
}

double SingleBookReturn::calculateLateFees(const QDateTime &dueDate, const QDateTime &currentDate)
{
    qint64 overdueDays = dueDate.daysTo(currentDate);

    if(overdueDays <= 0)
        return 0.0;

    return overdueDays*10;
}

bool SingleBookReturn::processBookReturn(const BookInfo &bookInfo)
{
    QDateTime currentDate = QDateTime::currentDateTime();
    double finalFee = calculateLateFees(bookInfo.dueDate, currentDate);

    if (!updateBookAvailability(bookInfo.bookId)){
        return false;
    }

    if (!logReturnTransaction(bookInfo,finalFee)){
        return false;
    }

    if (!removeFromIssuedBooks(bookInfo.issueId)){
        return false;
    }

    return true;
}

bool SingleBookReturn::updateBookAvailability(int bookId)
{
    if (!db.open()){
        emit errorOccured("Failed to open database to update book availability.");
        return false;
    }

    QSqlQuery query(db);

    query.prepare("UPDATE books SET availability = 'Available', timesBorrowed = timesBorrowed + 1 WHERE bookID = ?");
    query.addBindValue(bookId);

    qDebug() << "Book Id: " << bookId;

    if (!query.exec()){
        emit errorOccured("Error updating book availability: " + query.lastError().text());
        return false;
    }

    if (query.numRowsAffected() == 0) {
        emit errorOccured("No book found with bookID: " + QString::number(bookId));
        return false;
    }

    return true;
}

bool SingleBookReturn::removeFromIssuedBooks(int issueId)
{
    QSqlQuery query(db);

    query.prepare("DELETE FROM issued_books WHERE issue_id = ? ");
    query.addBindValue(issueId);

    if (!query.exec()){
        emit errorOccured("Failed to remove from issued books: " + query.lastError().text());
        return false;
    }

    return true;
}

bool SingleBookReturn::logReturnTransaction(const BookInfo &bookInfo, double finalFee)
{
    QSqlQuery query(db);

    if (!db.open()){
        emit errorOccured("Database not open: " + db.lastError().text());
        return false;
    }

    query.prepare(
        "INSERT INTO book_return_log "
        "(original_issue_id, book_id, user_id, book_title, book_call_number, user_name, "
        " issue_date, due_date, fine_amount, days_overdue, status_at_return, returned_by) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );

    QDateTime currentDate = QDateTime::currentDateTime();
    qint64 daysOverdue = bookInfo.dueDate.daysTo(currentDate);

    query.addBindValue(bookInfo.issueId);
    query.addBindValue(bookInfo.bookId);
    query.addBindValue(bookInfo.userId);
    query.addBindValue(bookInfo.bookTitle);
    query.addBindValue(bookInfo.callNumber);
    query.addBindValue(bookInfo.userName);
    query.addBindValue(bookInfo.issueDate);
    query.addBindValue(bookInfo.dueDate);
    query.addBindValue(finalFee);
    query.addBindValue(daysOverdue);
    query.addBindValue(bookInfo.status);
    query.addBindValue(m_currentAdminId);

    if (!query.exec()){
        emit errorOccured("Failed to log book return transaction: " + query.lastError().text());
        return false;
    }

    return true;
}

bool SingleBookReturn::addToLostBooks(const BookInfo &bookInfo)
{
    QSqlQuery checkQuery(db);

    checkQuery.prepare("SELECT COUNT(*) FROM lost_books WHERE original_issue_id = ?");
    checkQuery.addBindValue(bookInfo.issueId);

    if(!checkQuery.exec()){
        return false;
    }

    if(checkQuery.value(0).toInt() > 0){
        return true;
    }

    QSqlQuery insertQuery(db);

    insertQuery.prepare(
        "INSERT INTO lost_books "
        "(original_issue_id, book_id, user_id, book_title, book_call_number, book_author, "
        " book_value, user_name, user_email, user_phone, user_role, "
        " issue_date, due_date, days_overdue, fine_amount, "
        " replacement_cost, total_amount_due, reported_by) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );

    QDateTime currentDate = QDateTime::currentDateTime();
    qint64 overdueDays = bookInfo.issueDate.daysTo(currentDate);
    double replacementCost = bookInfo.bookValue;
    double totalDue = bookInfo.fineAmount + replacementCost;

    insertQuery.addBindValue(bookInfo.issueDate);
    insertQuery.addBindValue(bookInfo.bookId);
    insertQuery.addBindValue(bookInfo.userId);
    insertQuery.addBindValue(bookInfo.bookTitle);
    insertQuery.addBindValue(bookInfo.callNumber);
    insertQuery.addBindValue(bookInfo.bookAuthor);
    insertQuery.addBindValue(bookInfo.bookValue);
    insertQuery.addBindValue(bookInfo.userName);
    insertQuery.addBindValue(bookInfo.userEmail);
    insertQuery.addBindValue(bookInfo.userPhone);
    insertQuery.addBindValue(bookInfo.userRole);
    insertQuery.addBindValue(bookInfo.issueDate);
    insertQuery.addBindValue(bookInfo.dueDate);
    insertQuery.addBindValue(overdueDays);
    insertQuery.addBindValue(fineAmount());
    insertQuery.addBindValue(replacementCost);
    insertQuery.addBindValue(totalDue);
    insertQuery.addBindValue(m_currentAdminId);

    if (!insertQuery.exec()){
        emit errorOccured("Failed to add to lost books: " + insertQuery.lastError().text());
        return false;
    }
    return true;
}































