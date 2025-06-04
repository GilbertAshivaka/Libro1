#include "issuebookslist.h"
#include "databasemanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

IssueBooksList::IssueBooksList(QObject *parent)
    : QObject{parent}, m_db{DatabaseManager::getConnection()}
{
    if (!m_db.open()){
        qWarning() << "IssueBooksList is unable to open the datebase: " << m_db.lastError().text();
    }
}

IssueBooksList::~IssueBooksList(){
    if (m_db.isOpen()) m_db.close(); //close the database if it is open
}

void IssueBooksList::clear(){
    m_books.clear();
}

bool IssueBooksList::canBorrowMoreBooks(const QString &userId, const UserPrivileges &privileges)
{
    QSqlQuery query(m_db);

    if (!m_db.open()){
        emit errorOcurred("CanBorrowMoreBooks. Failed to open database: " + query.lastError().text());
        qDebug() << "Failed to open database: " + query.lastError().text();
    }

    query.prepare("SELECT COUNT(*) FROM issued_books WHERE user_id = ? AND status = 'Borrowed' ");
    query.addBindValue(userId);

    if (!query.exec() || !query.next()){
        qDebug() << "Failed to check user's current loans: " +query.lastError().text();
        return false;
    }

    int currentLoans = query.value(0).toInt();
    return currentLoans < privileges.maxBooksAllowed;
}

bool IssueBooksList::fetchBooks(int page, int pageSize){
    if(!m_db.isOpen()){
        emit errorOcurred("IssueBooks: Database not open.");
        return false;
    }

    emit preModelReset();
    clear();

    const int offset = (page- 1) * pageSize;

    QSqlQuery query(m_db);

    query.prepare(R"sql(
            SELECT bookID, title, author, callNumber, barcode, shelfNumber
            FROM books
            WHERE availability == 'Available'
            ORDER BY title ASC
            LIMIT :limit OFFSET :off
    )sql");

    query.bindValue(":limit", pageSize);
    query.bindValue(":off", offset);

    if (!query.exec()){
        emit errorOcurred("Failed to fetch books to issue" + query.lastError().text());
        qDebug() << "Failed to fetch books to issue" << query.lastError().text();
        emit postModelReset();
        return false;
    }

    while (query.next()){
        IssueBook b;

        b.bookID = query.value(0).toInt();
        b.title = query.value(1).toString();
        b.author = query.value(2).toString();
        b.callNumber = query.value(3).toString();
        b.barcode = query.value(4).toString();
        b.shelfNumber = query.value(5).toString();

        emit preBookAppended();
        m_books.append(b);
        emit postBookAppended();
    }

    emit postModelReset();
    emit booksUpdated();
    return true;
}



bool IssueBooksList::searchBooks(const QString &filter, int page, int pageSize){

    if (!m_db.isOpen()){
        emit errorOcurred("IssueBook: Database not open.");
        return false;
    }

    emit preModelReset();
    clear();

    const int offset = (page- 1) * pageSize;

    QSqlQuery query(m_db);
    query.prepare(R"sql(
            SELECT bookID, title, author, callNumber, barcode, shelfNumber
            FROM books
            WHERE availability == 'Available'
            AND (
                title LIKE :f
                OR author LIKE :f
                OR callNumber LIKE :f
            )

            ORDER BY title ASC
            LIMIT :limit OFFSET :offset
        )sql");

    QString pat = "%" + filter + "%";
    query.bindValue(":f", pat);
    query.bindValue(":limit", pageSize);
    query.bindValue(":offset", offset);

    if (!query.exec()){
        emit errorOcurred("IssueBoook: Search books failed" + query.lastError().text());
        qDebug() << "IssueBook: Search books failed" << query.lastError().text();
        emit postModelReset();
        return false;
    }

    while(query.next()){
        IssueBook b;
        b.bookID = query.value(0).toInt();
        b.title = query.value(1).toString();
        b.author = query.value(2).toString();
        b.callNumber = query.value(3).toString();
        b.barcode = query.value(4).toString();
        b.shelfNumber = query.value(5).toString();

        emit preBookAppended();
        m_books.append(b);
        emit postBookAppended();
    }

    emit postModelReset();
    emit booksUpdated();
    return true;
}

bool IssueBooksList::searchByBarcode(const QString &barcode){
    if (!m_db.isOpen()){
        emit errorOcurred("IssueBook: Database is not open." + m_db.lastError().text());
        qDebug() << "IssueBook: Database is not open." + m_db.lastError().text();
        return false;
    }

    emit preModelReset();
    clear();

    QSqlQuery query(m_db);

    query.prepare(R"sql(
            SELECT bookID, title, author, callNumber, barcode, shelfNumber
            FROM books
            WHERE barcode = :bc
            AND availability = 'Available'
        )sql");

    query.bindValue(":bc", barcode);

    if (!query.exec() || !query.next()){
        emit errorOcurred("Couldn't find book with barcode: " + barcode);
        qDebug() << "Couldn't find book with barcode: " + barcode;
        emit postModelReset();
        return false;
    }

    do {
        IssueBook b;
        b.bookID = query.value(0).toInt();
        b.title = query.value(1).toString();
        b.author = query.value(2).toString();
        b.callNumber = query.value(3).toString();
        b.barcode = query.value(4).toString();
        b.shelfNumber =query.value(5).toString();

        emit preBookAppended();
        m_books.append(b);
        emit postBookAppended();
        qDebug() << "Found Book: " << b.title << "\n";
    } while (query.next());

    emit postModelReset();
    emit booksUpdated();
    return true;
}

bool IssueBooksList::validateIssue(int bookId, const QString userId){
    if (bookId <0){
        emit errorOcurred("Invalid book ID");
        return false;
    }

    if (userId.isEmpty()){
        emit errorOcurred("Invalid user ID");
        return false;
    }

    return true;
}

bool IssueBooksList::issueBook(int bookId, const QString &userNumber){
    if (!m_db.isOpen()){
        emit errorOcurred("Database not open");
        qDebug() << "Database not open";
        return false;
    }

    UserInfo userInfo = lookUpUserInfo(userNumber);

    //validate user info
    if (!userInfo.isValid){
        emit errorOcurred("Invalid user ID");
        return false;
    }

    //get user privilges based on the user type
    UserPrivileges privileges = getUserPrivileges(userInfo.userType);
    QString userId = userInfo.internalUserID;

    if(!canBorrowMoreBooks(userId, privileges)){
        // emit errorOcurred(QString("User has reached a maximum limit of %1 books for %2")
        //                     .arg(privileges.maxBooksAllowed)
        //                     .arg(privileges.privilegeDescription)
        //                   );
        QString errorMsg = QString("User has reached a maximum limit of %1 books for %2")
                               .arg(privileges.maxBooksAllowed)
                               .arg(privileges.privilegeDescription);
        emit errorOcurred(errorMsg);
        qDebug() << errorMsg;
        return false;
    }

    if (!validateIssue(bookId, userId)){
        return false;
    }

    QSqlQuery chk(m_db);
    chk.prepare("SELECT availability FROM books WHERE bookID = ?");
    chk.addBindValue(bookId);

    if (!chk.exec() || !chk.next() || chk.value(0).toString() != "Available"){
        emit errorOcurred("Book is not available");
        qDebug() << "Book is not available" + chk.lastError().text();
        return false;
    }

    QDateTime due = QDateTime::currentDateTime().addDays(privileges.maxLoanDays);
    m_dueDate = due;

    m_db.transaction();

    //insert into the issued books table
    QSqlQuery ins(m_db);

    ins.prepare(R"sql(
            INSERT INTO issued_books
            (book_id, user_id, due_date, condition_before, issued_by, status, notes) VALUES (?, ?, ?, ?, ?, 'Borrowed', ?)
        )sql");

    ins.addBindValue(bookId);
    ins.addBindValue(userId);
    ins.addBindValue(due);
    ins.addBindValue(QStringLiteral("Good"));
    ins.addBindValue(userId); //this should be changed to read the admin details from the settings/database
    ins.addBindValue(QString("UserType: %1, MaxRenewals: %2, Loan Days: %3")
                     .arg(privileges.userType)
                     .arg(privileges.renewableLimit)
                     .arg(privileges.maxLoanDays)
                     );

    if (!ins.exec()){
        m_db.rollback();
        emit errorOcurred("Issuing book failed: " + ins.lastError().text());
        return false;
    }

    QSqlQuery upd(m_db);
    upd.prepare("UPDATE books SET availability = 'Borrowed', timesBorrowed = timesBorrowed + 1 WHERE bookID = ?");
    upd.addBindValue(bookId);
    if (!upd.exec()){
        m_db.rollback();
        emit errorOcurred("Failed to update book status: " + upd.lastError().text());
        emit errorOcurred("Failed to update book status: " + upd.lastError().text());
        return false;
    }


    if (!m_db.commit()){
        m_db.rollback();
        emit errorOcurred("Failed to commit issue transaction: " + m_db.lastError().text());
        return false;
    }


    // Success message with user-specific information
    QString successMsg = QString("Book issued successfully to %1 (%2). \nReturn expected on: %3 \nLoan period: %4 days")
                             .arg(userInfo.fullNames)
                             .arg(privileges.privilegeDescription)
                             .arg(due.date().toString())
                             .arg(privileges.maxLoanDays);

    emit operationSuccessful(successMsg);
    qDebug() << successMsg;
    return true;
}

//returns the automatic dueDate for the default privileges configurations
QString IssueBooksList::returnDueDate()
{
    m_dueDate = QDateTime::currentDateTime().addDays(m_defaultLoanDays);
    qDebug() << "Due date set to:" << m_dueDate.toString("yyyy-MM-dd hh:mm:ss");

    if (m_dueDate.isValid()){
        return m_dueDate.toString("dd/MM/yyyy");
    }else{
        return "Invalid Date";
    }

    // return m_dueDate.toString();
}

UserInfo IssueBooksList::lookUpUserInfo(const QString &userNumber)
{
    UserInfo userInfo;

    if (!m_db.open()){
        return userInfo;
    }

    QSqlQuery query(m_db);

    struct QueryInfo{
        QString query;
        QString userType;
    };

    QList<QueryInfo> queries = {
        {
            R"sql(
                SELECT u.user_id, u.first_name, u.second_name, s.adm_no
                FROM users u
                INNER JOIN students s ON u.user_id = s.student_id
                WHERE s.adm_no = ?
            )sql",
            "Student"
        },
        {
            R"sql(
                SELECT u.user_id, u.first_name, u.second_name, st.staff_no
                FROM users u
                INNER JOIN staff st ON u.user_id = st.staff_id
                WHERE st.staff_no = ?
            )sql",
            "Staff"
        },
        {
            R"sql(
                SELECT u.user_id, u.first_name, u.second_name, ou.user_no
                FROM users u
                INNER JOIN other_users ou ON u.user_id = ou.other_users_id
                WHERE ou.user_no = ?
            )sql",
            "Other"
        }
    };

    //try each query intil we find the right user
    for (const auto queryInfo: queries){
        query.prepare(queryInfo.query);
        query.addBindValue(userNumber);

        if (query.exec() && query.next()){
            userInfo.internalUserID =  query.value(0).toString();
            userInfo.fullNames = query.value(1).toString() + " " + query.value(2).toString();
            userInfo.userType = queryInfo.userType;
            userInfo.userNumber = userNumber;
            userInfo.isValid = true;
            break;
        }
    }

    if (!userInfo.isValid){
        qWarning() << "User not found with number: " << userNumber;
    }

    return userInfo;
}


QString IssueBooksList::lookUpUserNumber(int userId){
    if (!m_db.isOpen())
        return{};

    QSqlQuery query(m_db);
    query.prepare("SELECT first_name, second_name FROM users WHERE user_id = ?");
    query.addBindValue(userId);

    if (query.exec() && query.next()){
        return query.value(0).toString() + " " + query.value(1).toString();
    }
    return {};
}


//take the userID regardless of the userRole and returns their name
//this simple version uses the lookUPUserInfo function
QString IssueBooksList::lookUpUserNumber(const QString &userNumber)
{
    UserInfo info = lookUpUserInfo(userNumber);
    return info.isValid ? info.fullNames : QString();
}

// some other getter functions that  we may need
QString IssueBooksList::getUserType(const QString &userNumber)
{
    UserInfo info = lookUpUserInfo(userNumber);
    return info.isValid ? info.userType : QString();
}

QString IssueBooksList::getInternalUserID(const QString &userNumber)
{
    UserInfo info = lookUpUserInfo(userNumber);
    return info.isValid ? info.internalUserID : QString();
}

int IssueBooksList::getTotalBooksCount()
{
    if (!m_db.open()){
        emit errorOcurred("Database not open");
        qDebug() << "Database not open";
        return -1;
    }

    QSqlQuery query(m_db);
    query.prepare("SELECT COUNT(*) FROM books WHERE availability = 'Available' ");

    while (!query.exec() || !query.next()){
        emit errorOcurred("Failed to get total number of books: " + query.lastError().text());
        qDebug() << "Failed to get the total number of books: " + query.lastError().text();
        return -1;
    }

    return query.value(0).toInt();
}

//Function to get user Privileges
UserPrivileges IssueBooksList::getUserPrivileges(const QString &userType)
{
    UserPrivileges privileges;
    privileges.userType = userType;

    //Define privilges for different users
    if (userType.compare("student", Qt::CaseInsensitive) ==0){
        privileges.maxLoanDays = 14;
        privileges.maxBooksAllowed = 3;
        privileges.renewableLimit =1;
        privileges.privilegeDescription = QString("Student privileges");
    }
    else if (userType.compare("staff", Qt::CaseInsensitive) ==0){
        privileges.maxLoanDays = 30;
        privileges.maxBooksAllowed = 10;
        privileges.renewableLimit = 3;
        privileges.privilegeDescription = QString("Staff Privileges");
    }
    else if (userType.compare("other user", Qt::CaseInsensitive) ==0){
        privileges.maxLoanDays = 7;
        privileges.maxBooksAllowed = 2;
        privileges.renewableLimit = 0;
        privileges.privilegeDescription = QString("Visitor/guest privileges");
    }

    return privileges;
}

//returns the dueDate afer the userType is known
QString IssueBooksList::getDueDate()
{
    return m_dueDate.toString("dd/MM/yyyy");
}















