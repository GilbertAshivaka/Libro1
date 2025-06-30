#include "allbookslist.h"
#include "databasemanager.h"
#include "barcodewriter.h"
#include "backupmanager.h"

AllBooksList::AllBooksList(QObject *parent)
    : QObject{parent}
{
    //accessing the database using the getConnection method of DatabaseManager
    db = DatabaseManager::getConnection();

    if (!db.open()) {
        qWarning() << "Failed to open database: " + db.lastError().text();
    }

    // //connect to the
    // connect(backupManager, &BackupManager::databaseRestored, this, [this]() {
    //     // Refresh database connection after restore
    //     db = DatabaseManager::getConnection();
    //     if (!db.open()) {
    //         qWarning() << "Failed to reopen database after restore: " + db.lastError().text();
    //     } else {
    //         // Optionally refresh your book list
    //         fetchBooks(0, 100);
    //     }
    // });

    //    fetchBooks(0, 100);
}

AllBooksList::~AllBooksList(){
    // db.close(); // Close the connection when the object is destroyed
}

QVector<Book> AllBooksList::getBooks() const
{
    return books;
}


int AllBooksList::getTotalBooksCount(const QString &category)
{
    if (!db.open()) {
        qWarning() << "Failed to open database: " + db.lastError().text();
    }

    QSqlQuery query(db);
    QString queryString;

    if (category == "all") {
        queryString = "SELECT COUNT(*) FROM books;";
    }else{
        queryString = "SELECT COUNT(*) FROM books;";
    }

    if (!query.exec(queryString)) {
        qWarning() << "Failed to get total books count:" << query.lastError().text();
        return -1;
    }

    if (query.next()) {
        return query.value(0).toInt(); // Extract the count from the result
    }

    return 0;
}


bool AllBooksList::fetchBooks(int page, int pageSize, const QString &category = "all")
{
    int offset = (page - 1) * pageSize;

    if (!db.open()) {
        qWarning() << "Failed to open database: " + db.lastError().text();
    }

    QSqlQuery query(db);
    QString queryString;

    if (category == "all") {
        queryString = "SELECT title, author, callNumber, publisher, isbn, barcode, year_published, "
                      "shelfNumber, description, language, subject, genre, value, method, dateAdded, "
                      "availability, timesBorrowed, condition "
                      "FROM books LIMIT :pageSize OFFSET :offset";
    } else {
        queryString = "SELECT title, author, callNumber, publisher, isbn, barcode, year_published, "
                      "shelfNumber, description, language, subject, genre, value, method, dateAdded, "
                      "availability, timesBorrowed, condition "
                      "FROM books WHERE subject = :category OR genre = :category "
                      "LIMIT :pageSize OFFSET :offset";
    }

    query.prepare(queryString);
    query.bindValue(":pageSize", pageSize);
    query.bindValue(":offset", offset);
    if (category != "all") {
        query.bindValue(":category", category);
    }


    if (!query.exec()) {
        emit errorOccured("Failed to fetch books: " + query.lastError().text());
        return false;
    }

    emit preModelReset();
    books.clear();

    while (query.next()) {
        Book book(
            query.value(0).toString(),
            query.value(1).toString(),
            query.value(2).toString(),
            query.value(3).toString(),
            query.value(4).toString(),
            query.value(5).toString(),
            query.value(6).toString(),
            query.value(7).toString(),
            query.value(8).toString(),
            query.value(9).toString(),
            query.value(10).toString(),
            query.value(11).toString(),
            query.value(12).toInt(),
            query.value(13).toString(),
            query.value(14).toString(),
            query.value(15).toString(),
            query.value(16).toInt(),
            query.value(17).toString()
            );
        emit preBookAppended();
        books.append(book);
        qDebug() << book.callNumber << " " << book.availability;
        emit postBookAppended();
    }

    emit postModelReset();
    emit booksUpdated();
    return true;
}

bool AllBooksList::addBook(const QString &title,
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
                           const QString &method)
{

    if (!db.open()) {
        emit errorOccured("Database connection is not open.");
        return false;
    }


    if (!validateInputs(title, author, shelfNumber, value)){
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

    if (query.exec()){
        emit preBookAppended();

        //select the added book and display it on the list
        QSqlQuery fetchQuery(db);
        fetchQuery.prepare("SELECT title, author, callNumber, publisher, isbn, barcode, year_published, "
                           "shelfNumber, description, language, subject, genre, value, method, dateAdded, availability, timesBorrowed, condition"
                           " FROM books WHERE callNumber = ?"); //the space between condition and FROM is important

        fetchQuery.addBindValue(callNumber);
        if (!fetchQuery.exec()) {
            qWarning() << "Error fetching book: " << fetchQuery.lastError().text();
            return false;
        }

        if(fetchQuery.next()){
            const QString dateAdded = fetchQuery.value(14).toString();
            const QString availabilty = fetchQuery.value(15).toString();
            int timesBorrowed = fetchQuery.value(16).toInt();
            const QString condition = fetchQuery.value(17).toString();

            books.append(Book(title, author, callNumber, publisher, isbn, barcode,yearPublished, shelfNumber, description, language, subject, genre, value, method, dateAdded, availabilty, timesBorrowed, condition));
        }else {
            qWarning() << "No book found with callNumber: " << callNumber;
        }

        emit postBookAppended();
        emit booksUpdated();
        qDebug() << "Book added succesfully!";
    } else {
        emit errorOccured("There was an error adding book to the database: " + query.lastError().text());
        qWarning() << "There was an error adding book to the database: " + query.lastError().text();
    }

    BarcodeWriter barcodeWriter;
    barcodeWriter.writeAndSaveBarcode("Code128", barcode, title, author);

    return true;
}

void AllBooksList::removeBook(const QString &callNumber)
{
    if (!db.open()) {
        qWarning() << "Failed to open database: " + db.lastError().text();
    }

    QSqlQuery query(db);
    query.prepare("DELETE FROM books WHERE callNumber = ?");
    query.addBindValue(callNumber);

    if(query.exec()){
        for(int i = 0; i < books.size(); ++i){
            if (books[i].callNumber == callNumber){
                emit preBookRemoved(i);

                books.removeAt(i);

                emit postBookRemoved();
                emit booksUpdated();

                break;
            }
        }
    } else {
        emit errorOccured("Error removing book from database: " + query.lastError().text());
        qWarning() << "Error removing book from database: " + query.lastError().text();
    }
}

bool AllBooksList::validateInputs(const QString &title, const QString &author, const QString shelfNumber, int value)
{
    if (title.isEmpty() || author.isEmpty()){
        emit errorOccured("Title and author are required fields.");
        return false;
    }

    if(shelfNumber.isEmpty()){
        emit errorOccured("Shelf number cannot be empty.");
        return false;
    }

    if (value < 0){
        emit  errorOccured("The value cannot be negative.");
        return false;
    }

    return true;
}



