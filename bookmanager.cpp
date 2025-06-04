#include "bookmanager.h"
#include "databasemanager.h"

//#include "barcodewriter.h" could be useful when adding a book using thid function to generate the barcode here

BookManager::BookManager(QObject *parent)
    : QObject{parent}
{

}

bool BookManager::addBook(const QString &title,
                          const QString &author,
                          const QString &callNumber,
                          const QString &publisher,
                          const QString &isbn,
                          const QString &barcode,
                          const QString &yearPublished,
                          int shelfNumber,
                          const QString &description,
                          const QString &language,
                          const QString &subject,
                          const QString &genre,
                          int value,
                          const QString &method)
{
    if (!validateInputs(title, author, shelfNumber, value)){
        return false;
    }

    QSqlDatabase db = DatabaseManager::getConnection();
    if (!db.isOpen()){
        emit errorOccured("Failed to open the database: " + db.lastError().text());
        qWarning() << "Failed to open the database: " + db.lastError().text();
        return false;
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO books (title, author, callNumber, publisher, isbn, "
                  "barcode, year_published, shelfNumber, description, language, subject, genre, value, method) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

    query.addBindValue(title);
    query.addBindValue(author);
    query.addBindValue(callNumber);
    query.addBindValue(publisher);
    query.addBindValue(isbn);
    query.addBindValue(barcode);
    query.addBindValue(yearPublished);
    query.addBindValue(shelfNumber);
    query.addBindValue(description);
    query.addBindValue(language);
    query.addBindValue(subject);
    query.addBindValue(genre);
    query.addBindValue(value);
    query.addBindValue(method);

    if (!query.exec()){
        emit errorOccured("Error adding book to database: " + query.lastError().text());
    }

    emit bookAdded();
    return true;
}

bool BookManager::validateInputs(const QString &title, const QString &author, int shelfNumber, int value)
{
    if (title.isEmpty() || author.isEmpty()){
        emit errorOccured("Title and author are required fields.");
        return false;
    }

    if(shelfNumber < 0){
        emit errorOccured("Shelf number cannot be negative.");
        return false;
    }

    if (value < 0){
        emit  errorOccured("The value cannot be negative.");
        return false;
    }

    return true;
}














