#ifndef ISSUEDBOOKSLIST_H
#define ISSUEDBOOKSLIST_H

#include <QObject>
#include <QVector>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>

struct IssuedBookInfo{
    int issueId;
    int bookId;
    int userId;
    QString userName;
    QString callnumber;
    QString bookTitle;
    QDateTime issueDate;
    QDateTime dueDate;
    QString status;
    double fineAmount;
    double bookValue;
    bool isSelected;

    IssuedBookInfo() : issueId(0), bookId(0), userId(0), fineAmount(0.0), bookValue(0.0), isSelected(false){}
};

class IssuedBooksList : public QObject
{
    Q_OBJECT
public:
    explicit IssuedBooksList(QObject *parent = nullptr);
    ~IssuedBooksList();

    QVector<IssuedBookInfo> getIssuedBooks() const;


public slots:
    bool loadIssuedBooks();
    void selectAllBooks();
    void deselectAllBooks();
    void toggleBookSelection(int index);
    int getSelectedBooksCount() const;
    void returnSelectedBooks();
    bool searchBooksInDatabase(const QString &searchTerm);

    bool loadSortedIssuedBooks(const QString sortBy);
    int getRowCount();

signals:
    void preModelReset();
    void postModelReset();
    void preBookAppended();
    void postBookAppended();
    void preBookRemoved(int index);
    void postBookRemoved();
    void booksUpdated();
    void errorOccured(const QString &error);
    void operationSuccessful(const QString &msg);

    void searchResultsChanged();

private:
    QSqlDatabase db;
    QVector<IssuedBookInfo> issuedBooks;
    int m_currentAdminId;

    void createLostBooKSTable();
    QString calculateStatus(const QDateTime &dueDate, const QDateTime &currentDate);
    double calculateLateFees(const QDateTime &dueDate, const QDateTime &currentDate);

    bool processBookReturn(const IssuedBookInfo &bookInfo);
    bool updateBookAvailability(int bookId);
    bool removeFromIssuedBooks(int issueId);
    bool logReturnTransaction(const IssuedBookInfo &bookInfo, double finalFine);
    bool addToLostBooks(const IssuedBookInfo &bookInfo);

    // Preserve an unpaid late fee as a persistent outstanding fine before the
    // issued_books row is deleted, so it can be settled later during clearance.
    bool recordOutstandingFine(const IssuedBookInfo &bookInfo, double fineAmount, double alreadyPaid);
};

#endif // ISSUEDBOOKSLIST_H












