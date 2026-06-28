#include "issuedbookslist.h"
#include "databasemanager.h"
#include "settingsmanager.h"

IssuedBooksList::IssuedBooksList(QObject *parent)
    : QObject{parent}, m_currentAdminId(1)
{
    db =DatabaseManager::getConnection();

    if(!db.open()){
        qDebug() << "Failed to open the database: " + db.lastError().text();
    }
}

IssuedBooksList::~IssuedBooksList()
{
    //do something here
}

QVector<IssuedBookInfo> IssuedBooksList::getIssuedBooks() const
{
    return issuedBooks;
}

bool IssuedBooksList::loadIssuedBooks()
{
    if (!db.open()){
        emit errorOccured("Database not open: " + db.lastError().text());
        qDebug() << "Database not open: " + db.lastError().text();
        return false;
    }

    emit preModelReset();
    issuedBooks.clear();


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
        "WHERE ib.status = 'Borrowed' "
        "ORDER BY ib.issue_date DESC";

    if (!query.exec(querySQL)){
        emit errorOccured("Error loading issued books: " + query.lastError().text());
        qDebug() << "Error loading issued books: " + query.lastError().text();
        emit postModelReset();
        return false;
    }

    QDateTime currentDate = QDateTime::currentDateTime();

    while(query.next()){
        IssuedBookInfo book;
        book.issueId = query.value("issue_id").toInt();
        book.bookId = query.value("book_id").toInt();
        book.userId = query.value("user_id").toInt();
        book.userName = query.value("user_name").toString();
        book.callnumber = query.value("callNumber").toString();
        book.bookTitle = query.value("book_title").toString();
        book.issueDate = query.value("issue_date").toDateTime();
        book.dueDate = query.value("due_date").toDateTime();
        book.bookValue = query.value("book_value").toDouble();
        book.isSelected = false;

        book.status = calculateStatus(book.dueDate, currentDate);
        book.fineAmount = calculateLateFees(book.dueDate, currentDate);

        if(book.status == "Probably lost"){
            addToLostBooks(book);
        }

        emit preBookAppended();
        issuedBooks.append(book);
        emit postBookAppended();
    }

    emit postModelReset();
    emit booksUpdated();
    return true;
}

void IssuedBooksList::selectAllBooks()
{
    for(int i = 0; i< issuedBooks.count(); ++i){
        issuedBooks[i].isSelected = true;
    }

    emit booksUpdated();
}

void IssuedBooksList::deselectAllBooks()
{
    for (int i = 0; i< issuedBooks.count(); ++i){
        issuedBooks[i].isSelected = false;
    }
    emit booksUpdated();
}

void IssuedBooksList::toggleBookSelection(int index)
{
    if (index >= 0 && index < issuedBooks.size()){
        issuedBooks[index].isSelected = !issuedBooks[index].isSelected;
        emit booksUpdated();
    }
}

int IssuedBooksList::getSelectedBooksCount() const
{
    int count = 0;
    for (const auto &book: issuedBooks){
        if (book.isSelected)
            count ++;
    }

    return count;
}

void IssuedBooksList::returnSelectedBooks()
{
    QList<IssuedBookInfo> selectedBooks;

    //Get all selected books
    for (const auto &book : issuedBooks){
        if (book.isSelected){
            selectedBooks.append(book);
        }
    }

    if (selectedBooks.isEmpty()){
        emit errorOccured("No books selected for return.");
        return;
    }

    if (!db.open()){
        emit errorOccured("Database not open.");
        return;
    }

    db.transaction();

    int successCount = 0;
    QStringList errorMessages;

    for (const auto &book : selectedBooks){
        if (processBookReturn(book)){
            successCount++;
        }else {
            errorMessages.append(QString("Failed to return book: %1").arg(book.callnumber));
        }
    }

    if (errorMessages.isEmpty()){

            db.commit();

        //Remove returned books from the list
        for (int i = issuedBooks.size() -1; i >= 0; --i){
            if (issuedBooks[i].isSelected){
                emit preBookRemoved(i);
                issuedBooks.removeAt(i);
                emit postBookRemoved();
            }
        }

        emit booksUpdated();
        emit operationSuccessful(QString("Succesfully returned %1 books").arg(successCount));
    }else {
        db.rollback();
        emit errorOccured("Some books failed to return: " + errorMessages.join(","));
    }
}

bool IssuedBooksList::searchBooksInDatabase(const QString &searchTerm)
{
    if (!db.open()){
        emit errorOccured("Database not open: " + db.lastError().text());
        qDebug() << "Database not open" + db.lastError().text();
        return false;
    }

    QString trimmedTerm = searchTerm.trimmed();

    //if the searchTerm is empty return the original list of books
    if (trimmedTerm.isEmpty()){
        return loadIssuedBooks();
    }

    emit preModelReset();
    issuedBooks.clear();

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
        "WHERE ib.status = 'Borrowed' "
        "AND (LOWER(b.title) LIKE ? OR "
        "     LOWER(u.first_name || ' ' || u.second_name) LIKE ? OR "
        "     LOWER(b.callNumber) LIKE ? OR "
        "     LOWER(b.author) LIKE ?) "
        "ORDER BY ib.issue_date DESC";

    if (!query.prepare(querySQL)){
        emit errorOccured("Error preparing query: " + query.lastError().text());
        emit postModelReset();
        return false;
    }

    QString searchPattern = "%" + trimmedTerm.toLower() + "%";

    query.addBindValue(searchPattern);
    query.addBindValue(searchPattern);
    query.addBindValue(searchPattern);
    query.addBindValue(searchPattern);

    if (!query.exec()){
        emit errorOccured("Error searching issued books: " + query.lastError().text());
        emit postModelReset();
        return false;
    }

    QDateTime currentDate = QDateTime::currentDateTime();

    while (query.next()){
        IssuedBookInfo book;
        book.issueId = query.value("issue_id").toInt();
        book.bookId = query.value("book_id").toInt();
        book.userId = query.value("user_id").toInt();
        book.userName = query.value("user_name").toString();
        book.callnumber = query.value("callNumber").toString();
        book.bookTitle = query.value("book_title").toString();
        book.issueDate = query.value("issue_date").toDateTime();
        book.dueDate = query.value("due_date").toDateTime();
        book.bookValue = query.value("book_value").toDouble();
        book.isSelected = false;

        book.status = calculateStatus(book.dueDate, currentDate);
        book.fineAmount = calculateLateFees(book.dueDate, currentDate);

        if (book.status == "Probably lost"){
            addToLostBooks(book);
        }

        emit preBookAppended();
        issuedBooks.append(book);
        emit postBookAppended();
    }

    emit postModelReset();
    emit searchResultsChanged();
    emit booksUpdated();
    return true;
}

QString IssuedBooksList::calculateStatus(const QDateTime &dueDate, const QDateTime &currentDate)
{
    qint64 daysOverdue = dueDate.daysTo(currentDate);

    if (daysOverdue <= 0){
        return "Pending";
    }else if(daysOverdue <= 90){
        return "Overdue";
    }else {
        return "Probably lost";
    }
}

double IssuedBooksList::calculateLateFees(const QDateTime &dueDate, const QDateTime &currentDate)
{
    qint64 daysOverdue = dueDate.daysTo(currentDate);

    if (daysOverdue <= 0)
        return 0.0;

    // Use the configured fine rate and cap (consistent with the single-book
    // return path) instead of a hard-coded, uncapped rate.
    int dailyFine = SettingsManager::instance()->fineRatePerDay();
    int maxFineAmount = SettingsManager::instance()->maxFineAmount();
    qint64 fineAmount = daysOverdue * dailyFine;

    return fineAmount > maxFineAmount ? maxFineAmount : static_cast<double>(fineAmount);
}

bool IssuedBooksList::processBookReturn(const IssuedBookInfo &bookInfo)
{
    QDateTime currentDate = QDateTime::currentDateTime();

    double finalFee = calculateLateFees(bookInfo.dueDate, currentDate);

    if(!updateBookAvailability(bookInfo.bookId)){
        return false;
    }

    if (!logReturnTransaction(bookInfo, finalFee)){
        return false;
    }

    // The book is returned regardless of any outstanding fine (unchanged
    // behaviour). But if a late fee is owed, preserve it in the outstanding_fines
    // ledger BEFORE the issued_books row is deleted, otherwise the fine is lost.
    if (finalFee > 0.0) {
        double alreadyPaid = 0.0;
        QSqlQuery paidQuery(db);
        paidQuery.prepare("SELECT fine_paid FROM issued_books WHERE issue_id = ?");
        paidQuery.addBindValue(bookInfo.issueId);
        if (paidQuery.exec() && paidQuery.next())
            alreadyPaid = paidQuery.value(0).toDouble();

        if ((finalFee - alreadyPaid) > 0.0) {
            if (!recordOutstandingFine(bookInfo, finalFee, alreadyPaid)) {
                return false;   // abort so the transaction rolls back; fine not lost
            }
        }
    }

    if (!removeFromIssuedBooks(bookInfo.issueId)){
        return false;
    }

    // If this book had been auto-flagged as lost (>90 days overdue), mark that
    // lost_books record resolved so a returned book stops counting as a lost
    // charge (e.g. it no longer inflates the user's clearance balance).
    {
        QSqlQuery lostQuery(db);
        lostQuery.prepare("UPDATE lost_books SET status = 'Returned', resolution_type = 'Returned', "
                          "resolution_date = CURRENT_TIMESTAMP, resolved_by = ?, "
                          "updated_at = CURRENT_TIMESTAMP "
                          "WHERE original_issue_id = ? AND status IN ('Lost', 'Unpaid')");
        lostQuery.addBindValue(m_currentAdminId);
        lostQuery.addBindValue(bookInfo.issueId);
        lostQuery.exec();   // non-fatal: book is already returned
    }

    return true;
}

bool IssuedBooksList::recordOutstandingFine(const IssuedBookInfo &bookInfo, double fineAmount, double alreadyPaid)
{
    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO outstanding_fines "
        "(user_id, book_id, original_issue_id, book_title, book_call_number, "
        " fine_type, fine_amount, amount_paid, status) "
        "VALUES (?, ?, ?, ?, ?, 'overdue', ?, ?, 'outstanding')"
    );
    query.addBindValue(bookInfo.userId);
    query.addBindValue(bookInfo.bookId);
    query.addBindValue(bookInfo.issueId);
    query.addBindValue(bookInfo.bookTitle);
    query.addBindValue(bookInfo.callnumber);
    query.addBindValue(fineAmount);
    query.addBindValue(alreadyPaid);

    if (!query.exec()) {
        emit errorOccured("Error recording outstanding fine: " + query.lastError().text());
        return false;
    }
    return true;
}

bool IssuedBooksList::updateBookAvailability(int bookId)
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

bool IssuedBooksList::removeFromIssuedBooks(int issueId)
{
    QSqlQuery query(db);

    query.prepare("DELETE FROM issued_books WHERE issue_id = ?");
    query.addBindValue(issueId);

    if (!query.exec()){
        emit errorOccured("Error removing from issued books: " + query.lastError().text());
        return false;
    }
    return true;
}

bool IssuedBooksList::logReturnTransaction(const IssuedBookInfo &bookInfo, double finalFine)
{
    QSqlQuery query(db);

    if (!db.open()){
        emit errorOccured("Database not open; " + query.lastError().text());
        return false;
    }

    // Insert return log entry
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
    query.addBindValue(bookInfo.callnumber);
    query.addBindValue(bookInfo.userName);
    query.addBindValue(bookInfo.issueDate);
    query.addBindValue(bookInfo.dueDate);
    query.addBindValue(finalFine);
    query.addBindValue(daysOverdue);
    query.addBindValue(bookInfo.status);
    query.addBindValue(m_currentAdminId);

    if(!query.exec()){
        emit errorOccured("Error logging return transaction: " + query.lastError().text());
        return false;
    }

    return true;
}

bool IssuedBooksList::addToLostBooks(const IssuedBookInfo &bookInfo)
{
    QSqlQuery checkQuery;
    checkQuery.prepare("SELECT COUNT(*) FROM lost_books WHERE original_issue_id = ?");
    checkQuery.addBindValue(bookInfo.issueId);

    if (!checkQuery.exec() || !checkQuery.next()){
        return false;
    }

    //if already in lost books don't add again
    if (checkQuery.value(0).toInt() > 0){
        return true;
    }

    QSqlQuery userQuery;
    userQuery.prepare(
        "SELECT u.email, u.phone, u.user_role, "
        "COALESCE(s.adm_no, st.staff_no, ou.user_no) as user_number "
        "FROM users u "
        "LEFT JOIN students s ON u.user_id = s.student_id "
        "LEFT JOIN staff st ON u.user_id = st.staff_id "
        "LEFT JOIN other_users ou ON u.user_id = ou.other_users_id "
        "WHERE u.user_id = ?"
    );

    userQuery.addBindValue(bookInfo.userId);

    if (!userQuery.exec() || userQuery.next()){
        return false;
    }

    QSqlQuery bookQuery;
    bookQuery.prepare("SELECT author, isbn FROM books WHERE bookID = ?");
    bookQuery.addBindValue(bookInfo.bookId);

    if (!bookQuery.exec() || bookQuery.next()){
        return false;
    }

    QSqlQuery insertQuery(db);
    insertQuery.prepare(
        "INSERT INTO lost_books "
        "(original_issue_id, book_id, user_id, book_title, book_call_number, book_author, "
        " book_isbn, book_value, user_name, user_email, user_phone, user_role, "
        " student_adm_no, staff_no, issue_date, due_date, days_overdue, fine_amount, "
        " replacement_cost, total_amount_due, reported_by) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );

    QDateTime currentDate = QDateTime::currentDateTime();
    qint64 overdueDays = bookInfo.dueDate.daysTo(currentDate);
    double replacemenCost = bookInfo.bookValue;
    double totalDue = bookInfo.fineAmount + replacemenCost;

    insertQuery.addBindValue(bookInfo.issueId);
    insertQuery.addBindValue(bookInfo.bookId);
    insertQuery.addBindValue(bookInfo.userId);
    insertQuery.addBindValue(bookInfo.bookTitle);
    insertQuery.addBindValue(bookInfo.callnumber);
    insertQuery.addBindValue(bookQuery.value("author").toString());
    insertQuery.addBindValue(bookQuery.value("isbn").toString());
    insertQuery.addBindValue(bookInfo.bookValue);
    insertQuery.addBindValue(bookInfo.userName);
    insertQuery.addBindValue(bookQuery.value("email").toString());
    insertQuery.addBindValue(bookQuery.value("phone").toString());
    insertQuery.addBindValue(bookQuery.value("user_role").toString());

    QString userRole = bookQuery.value("user_role").toString();
    if (userRole == "Student"){
        insertQuery.addBindValue(userQuery.value("user_number").toString());
        insertQuery.addBindValue(QVariant());
    }else if(userRole == "Staff"){
        insertQuery.addBindValue(QVariant());
        insertQuery.addBindValue(userQuery.value("user_number").toString());
    }else {
        insertQuery.addBindValue(QVariant());
        insertQuery.addBindValue(QVariant());
    }

    insertQuery.addBindValue(bookInfo.issueDate);
    insertQuery.addBindValue(bookInfo.dueDate);
    insertQuery.addBindValue(overdueDays);
    insertQuery.addBindValue(bookInfo.fineAmount);
    insertQuery.addBindValue(replacemenCost);
    insertQuery.addBindValue(totalDue);
    insertQuery.addBindValue(m_currentAdminId);

    if (!insertQuery.exec()){
        emit errorOccured("Failed to add into lost books: " + insertQuery.lastError().text());
        return false;
    }

    return true;
}

//lazy implementation of sort toggling
bool IssuedBooksList::loadSortedIssuedBooks(const QString sortBy)
{
    if (!db.open()){
        emit errorOccured("Database not open: " + db.lastError().text());
        qDebug() << "Database not open: " + db.lastError().text();
        return false;
    }

    emit preModelReset();
    issuedBooks.clear();


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
        "WHERE ib.status = 'Borrowed' "
        "ORDER BY ib.issue_date " + sortBy;


    if (!query.exec(querySQL)){
        emit errorOccured("Error loading issued books: " + query.lastError().text());
        qDebug() << "Error loading issued books: " + query.lastError().text();
        emit postModelReset();
        return false;
    }

    QDateTime currentDate = QDateTime::currentDateTime();

    while(query.next()){
        IssuedBookInfo book;
        book.issueId = query.value("issue_id").toInt();
        book.bookId = query.value("book_id").toInt();
        book.userId = query.value("user_id").toInt();
        book.userName = query.value("user_name").toString();
        book.callnumber = query.value("callNumber").toString();
        book.bookTitle = query.value("book_title").toString();
        book.issueDate = query.value("issue_date").toDateTime();
        book.dueDate = query.value("due_date").toDateTime();
        book.bookValue = query.value("book_value").toDouble();
        book.isSelected = false;

        book.status = calculateStatus(book.dueDate, currentDate);
        book.fineAmount = calculateLateFees(book.dueDate, currentDate);

        if(book.status == "Probably lost"){
            addToLostBooks(book);
        }

        emit preBookAppended();
        issuedBooks.append(book);
        emit postBookAppended();
    }

    emit postModelReset();
    emit booksUpdated();
    return true;
}

int IssuedBooksList::getRowCount()
{
    return issuedBooks.size();
}



























