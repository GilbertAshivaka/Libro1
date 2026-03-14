#ifndef SINGLEBOOKRETURN_H
#define SINGLEBOOKRETURN_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>
#include <QRegularExpression>

struct BookInfo{
    int issueId;
    int bookId;
    int userId;
    QString userName;
    QString callNumber;
    QString bookTitle;
    QString bookAuthor;
    QDateTime issueDate;
    QDateTime dueDate;
    double bookValue;
    QString status;
    double fineAmount;
    QString condition;
    QString userEmail;
    QString userPhone;
    QString userRole;
    QString userNumber;
};

class SingleBookReturn : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString bookTitle READ bookTitle  NOTIFY bookDataChanged)
    Q_PROPERTY(QString callNumber READ callNumber NOTIFY bookDataChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY bookDataChanged)
    Q_PROPERTY(QString userNumber READ userNumber NOTIFY bookDataChanged)
    Q_PROPERTY(QDateTime issueDate READ issueDate NOTIFY bookDataChanged)
    Q_PROPERTY(QDateTime dueDate READ dueDate NOTIFY bookDataChanged)
    Q_PROPERTY(QString status READ status NOTIFY bookDataChanged)
    Q_PROPERTY(double  fineAmount READ fineAmount NOTIFY bookDataChanged)
    Q_PROPERTY(QString condition READ condition NOTIFY bookDataChanged)
    Q_PROPERTY(bool hasBookData READ hasBookData NOTIFY bookDataChanged)

public:
    explicit SingleBookReturn(QObject *parent = nullptr);
    ~SingleBookReturn();

    //The Q_PROPERTY getters
    QString bookTitle() const;
    QString callNumber() const;
    QString userName() const;
    QString userNumber() const;
    QDateTime issueDate() const;
    QDateTime dueDate() const;
    QString status() const;
    double fineAmount() const;
    QString condition() const;
    bool hasBookData() const;

    Q_INVOKABLE bool recordFinePayment(double amountPaid);
    Q_INVOKABLE bool returnBookWithFine(bool finePaid);
    Q_INVOKABLE double getPendingFineAmount() const;
    Q_INVOKABLE bool hasPendingFine() const;


public slots:

    bool searchByCallNumber(const QString &callNumber);
    bool searchByBarcode(const QString &barcode);

    bool returnCurrentBook();
    void clearBookData();


signals:

    void bookDataChanged();
    void errorOccured(const QString &erroMsg);
    void operationSuccessful(const QString &successMsg);
    void bookFound();
    void bookNotFound(const QString &searchTerm);

    void finePaymentRecorded(double amount);
    void returnRequiresFinePayment(double fineAmt);

private:
    //Member variables
    QSqlDatabase db;
    BookInfo m_currentBook;
    bool m_hasBookData;
    int m_currentAdminId;

    bool loadBookFromDatabase(const QString &searchColumn, const QString &searchValue);
    QString calculateStatus(const QDateTime &dueDate, const QDateTime &currentDate);
    double calculateLateFees(const QDateTime &dueDate, const QDateTime &currentDate);
    bool processBookReturn(const BookInfo &bookInfo);
    bool updateBookAvailability(int bookId);
    bool removeFromIssuedBooks(int issueId);
    bool logReturnTransaction(const BookInfo &bookInfo, double finalFee);
    bool addToLostBooks(const BookInfo &bookInfo);

    bool updateIssuedBookFinePayment(int issueId, double amtPaid);
};

#endif // SINGLEBOOKRETURN_H






















