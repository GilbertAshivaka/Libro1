#pragma once
#ifndef ISSUEBOOKSLIST_H
#define ISSUEBOOKSLIST_H

#include <QObject>
#include <QVector>
#include <QSqlDatabase>
#include <QDateTime>

//struct to represent the book being issued
struct IssueBook{
    int bookID;
    QString title;
    QString author;
    QString callNumber;
    QString barcode;
    QString shelfNumber;
};


//Struct to return the user details for use in the issuing process
struct UserInfo{
    QString fullNames;
    QString userType;
    QString internalUserID; //the actual user_id from the database
    QString userNumber; // user facing ID
    bool isValid;

    UserInfo() : internalUserID(""), isValid(false){}
};

//struct to return user Privileges
struct UserPrivileges{
    QString userType;
    int maxLoanDays;
    int maxBooksAllowed;
    int renewableLimit;
    bool canBorrowRestrictedBooks;
    QString privilegeDescription;

    UserPrivileges() : maxLoanDays(14), maxBooksAllowed(3), renewableLimit(1), canBorrowRestrictedBooks(false){}
};

Q_DECLARE_METATYPE(UserInfo)


class IssueBooksList : public QObject
{
    Q_OBJECT
public:
    explicit IssueBooksList(QObject *parent = nullptr);
    ~IssueBooksList();

    QVector<IssueBook> getBooks() const{return m_books; }

    Q_INVOKABLE QString lookUpUserNumber(int userId);


signals:
    void preModelReset();
    void postModelReset();
    void preBookAppended();
    void postBookAppended();
    void booksUpdated();
    void errorOcurred(const QString &msg);
    void operationSuccessful(const QString &msg);

public slots:
    bool fetchBooks(int page = 1, int pageSize =100);
    bool searchBooks(const QString &filter, int page, int pageSize = 100);
    bool searchByBarcode(const QString& barcode);
    bool issueBook(int bookId, const QString &userNumber);
    QString returnDueDate(); //we would like to display the duedate on the UI

    UserInfo lookUpUserInfo(const QString &userNumber);
    QString lookUpUserNumber(const QString &userNumber);

    QString getUserType(const QString &userNumber);
    QString getInternalUserID(const QString &userNumber);
    int getTotalBooksCount();

    UserPrivileges getUserPrivileges(const QString &userType);

    QString getDueDate();

private:
    QSqlDatabase m_db;
    QVector<IssueBook> m_books;
    QDateTime m_dueDate;

    int m_defaultLoanDays = 14;

    bool validateIssue(int bookId, const QString userId);
    void clear();
    bool canBorrowMoreBooks(const QString &userId, const UserPrivileges &privileges);
};

#endif // ISSUEBOOKSLIST_H












