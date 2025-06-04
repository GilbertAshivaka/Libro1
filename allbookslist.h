#ifndef ALLBOOKSLIST_H
#define ALLBOOKSLIST_H

#include <QObject>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <QString>
#include <QVector>
#include <QDebug>
//#include <QVariant>

class Book {
public:
    Book(const QString& title,
         const QString& author,
         const QString& callNumber,
         const QString& publisher,
         const QString& isbn,
         const QString& barcode,
         const QString& yearPublished,
         const QString& shelfNumber,
         const QString& description,
         const QString& language,
         const QString& subject,
         const QString& genre,
         int value,
         const QString& method,
         const QString& dateAdded,
         const QString& availability,
         int timesBorrowed,
         const QString& condition)
        : title(title),
        author(author),
        callNumber(callNumber),
        publisher(publisher),
        isbn(isbn),
        barcode(barcode),
        yearPublished(yearPublished),
        shelfNumber(shelfNumber),
        language(language),
        description(description),
        subject(subject),
        genre(genre),
        value(value),
        method(method),
        dateAdded(dateAdded),
        availability(availability),
        timesBorrowed(timesBorrowed),
        condition(condition)
    {}

    QString title;
    QString author;
    QString callNumber;
    QString publisher;
    QString isbn;
    QString barcode;
    QString yearPublished;
    QString shelfNumber;
    QString description;
    QString language;
    QString subject;
    QString genre;
    int value;
    QString method;
    QString dateAdded;
    QString availability;
    int timesBorrowed;
    QString condition;
};
//registering book with the Qt Meta-object system
Q_DECLARE_METATYPE(Book)

class AllBooksList : public QObject
{
    Q_OBJECT
public:
    explicit AllBooksList(QObject *parent = nullptr);
    ~AllBooksList();


    bool connectToDatabase();
    QVector<Book> getBooks() const;

    Q_INVOKABLE int getTotalBooksCount(const QString& category);


public slots:
    bool fetchBooks(int page, int pageSize, const QString& category);
    bool addBook(const QString &title,
                 const QString &author,
                 const QString &callNumber,
                 const QString &publisher,
                 const QString &isbn,
                 const QString &barcode,
                 const QString &yearPublished,
                 const QString shelfNumber,
                 const QString &description,
                 const QString &language,
                 const QString &subject,
                 const QString &genre,
                 int value,
                 const QString &method
                 );

    void removeBook(const QString& callNumber);

signals:
    void booksUpdated();
    void preBookAppended();
    void postBookAppended();

    //notify model reset
    void preModelReset();
    void postModelReset();

    void preBookRemoved(int index);
    void postBookRemoved();
    void errorOccured(const QString& error);
private:
    QSqlDatabase db;
    QVector<Book> books;

    bool validateInputs(
        const QString &title,
        const QString &author,
        const QString shelfNumber,
        int value
        );


};

#endif // ALLBOOKSLIST_H
