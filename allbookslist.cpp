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

    // BarcodeWriter barcodeWriter;
    // barcodeWriter.writeAndSaveBarcode("Code128", barcode, title, author);

    BarcodeWriter::instance()->writeAndSaveBarcode("Code128", barcode, title, author);

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


// Basic search - searches title, author, callNumber, ISBN, publisher
// Real-time, partial matching, case-insensitive, OR matching
bool AllBooksList::searchBooks(const QString &searchTerm)
{
    if (searchTerm.trimmed().isEmpty()) {
        return false;
    }

    if (!db.isOpen() && !db.open()) {
        emit errorOccured("Database connection failed");
        return false;
    }

    QSqlQuery query(db);
    QString searchPattern = "%" + searchTerm.trimmed() + "%";

    QString queryStr =
        "SELECT title, author, callNumber, publisher, isbn, barcode, year_published, "
        "shelfNumber, description, language, subject, genre, value, method, dateAdded, "
        "availability, timesBorrowed, condition "
        "FROM books WHERE "
        "title LIKE :search1 OR "
        "author LIKE :search2 OR "
        "callNumber LIKE :search3 OR "
        "isbn LIKE :search4 OR "
        "publisher LIKE :search5 "
        "ORDER BY title ASC "
        "LIMIT 200";

    query.prepare(queryStr);
    query.bindValue(":search1", searchPattern);
    query.bindValue(":search2", searchPattern);
    query.bindValue(":search3", searchPattern);
    query.bindValue(":search4", searchPattern);
    query.bindValue(":search5", searchPattern);

    if (!query.exec()) {
        emit errorOccured("Search failed: " + query.lastError().text());
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
        books.append(book);
    }

    emit postModelReset();
    emit booksUpdated();
    emit searchCompleted(books.size());

    return true;
}


// Advanced search with multiple criteria - OR matching
bool AllBooksList::advancedSearchBooks(const QString &title,
                                       const QString &author,
                                       const QString &callNumber,
                                       const QString &isbn,
                                       const QString &publisher,
                                       const QString &yearFrom,
                                       const QString &yearTo,
                                       const QString &subject,
                                       const QString &genre,
                                       const QString &language,
                                       const QString &shelfNumber,
                                       const QString &availability,
                                       const QString &condition,
                                       const QString &method)
{
    if (!db.isOpen() && !db.open()) {
        emit errorOccured("Database connection failed");
        return false;
    }

    QSqlQuery query(db);
    QStringList conditions;

    // Build conditions for non-empty fields
    if (!title.trimmed().isEmpty()) {
        conditions << "title LIKE :title";
    }
    if (!author.trimmed().isEmpty()) {
        conditions << "author LIKE :author";
    }
    if (!callNumber.trimmed().isEmpty()) {
        conditions << "callNumber LIKE :callNumber";
    }
    if (!isbn.trimmed().isEmpty()) {
        conditions << "isbn LIKE :isbn";
    }
    if (!publisher.trimmed().isEmpty()) {
        conditions << "publisher LIKE :publisher";
    }
    if (!yearFrom.trimmed().isEmpty()) {
        conditions << "CAST(year_published AS INTEGER) >= :yearFrom";
    }
    if (!yearTo.trimmed().isEmpty()) {
        conditions << "CAST(year_published AS INTEGER) <= :yearTo";
    }
    if (!subject.trimmed().isEmpty() && subject != "All") {
        conditions << "subject = :subject";
    }
    if (!genre.trimmed().isEmpty() && genre != "All") {
        conditions << "genre = :genre";
    }
    if (!language.trimmed().isEmpty() && language != "All") {
        conditions << "language = :language";
    }
    if (!shelfNumber.trimmed().isEmpty()) {
        conditions << "shelfNumber LIKE :shelfNumber";
    }
    if (!availability.trimmed().isEmpty() && availability != "All") {
        conditions << "availability = :availability";
    }
    if (!condition.trimmed().isEmpty() && condition != "All") {
        conditions << "condition = :condition";
    }
    if (!method.trimmed().isEmpty() && method != "All") {
        conditions << "method = :method";
    }

    // If no conditions, return all books
    QString whereClause = conditions.isEmpty() ? "" : " WHERE " + conditions.join(" OR ");

    QString queryStr =
        "SELECT title, author, callNumber, publisher, isbn, barcode, year_published, "
        "shelfNumber, description, language, subject, genre, value, method, dateAdded, "
        "availability, timesBorrowed, condition "
        "FROM books" + whereClause +
        " ORDER BY title ASC LIMIT 500";

    query.prepare(queryStr);

    // Bind values for non-empty fields
    if (!title.trimmed().isEmpty()) {
        query.bindValue(":title", "%" + title.trimmed() + "%");
    }
    if (!author.trimmed().isEmpty()) {
        query.bindValue(":author", "%" + author.trimmed() + "%");
    }
    if (!callNumber.trimmed().isEmpty()) {
        query.bindValue(":callNumber", "%" + callNumber.trimmed() + "%");
    }
    if (!isbn.trimmed().isEmpty()) {
        query.bindValue(":isbn", "%" + isbn.trimmed() + "%");
    }
    if (!publisher.trimmed().isEmpty()) {
        query.bindValue(":publisher", "%" + publisher.trimmed() + "%");
    }
    if (!yearFrom.trimmed().isEmpty()) {
        query.bindValue(":yearFrom", yearFrom.trimmed().toInt());
    }
    if (!yearTo.trimmed().isEmpty()) {
        query.bindValue(":yearTo", yearTo.trimmed().toInt());
    }
    if (!subject.trimmed().isEmpty() && subject != "All") {
        query.bindValue(":subject", subject.trimmed());
    }
    if (!genre.trimmed().isEmpty() && genre != "All") {
        query.bindValue(":genre", genre.trimmed());
    }
    if (!language.trimmed().isEmpty() && language != "All") {
        query.bindValue(":language", language.trimmed());
    }
    if (!shelfNumber.trimmed().isEmpty()) {
        query.bindValue(":shelfNumber", "%" + shelfNumber.trimmed() + "%");
    }
    if (!availability.trimmed().isEmpty() && availability != "All") {
        query.bindValue(":availability", availability.trimmed());
    }
    if (!condition.trimmed().isEmpty() && condition != "All") {
        query.bindValue(":condition", condition.trimmed());
    }
    if (!method.trimmed().isEmpty() && method != "All") {
        query.bindValue(":method", method.trimmed());
    }

    if (!query.exec()) {
        emit errorOccured("Advanced search failed: " + query.lastError().text());
        qDebug() << "Advanced search failed:" << query.lastError().text();
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
        books.append(book);
    }

    emit postModelReset();
    emit booksUpdated();
    emit searchCompleted(books.size());

    return true;
}


// Get distinct values for dropdown population
QStringList AllBooksList::getDistinctSubjects()
{
    QStringList subjects;
    subjects << "All";

    if (!db.isOpen() && !db.open()) return subjects;

    QSqlQuery query(db);
    query.exec("SELECT DISTINCT subject FROM books WHERE subject IS NOT NULL AND subject != '' ORDER BY subject");

    while (query.next()) {
        subjects << query.value(0).toString();
    }
    return subjects;
}

QStringList AllBooksList::getDistinctGenres()
{
    QStringList genres;
    genres << "All";

    if (!db.isOpen() && !db.open()) return genres;

    QSqlQuery query(db);
    query.exec("SELECT DISTINCT genre FROM books WHERE genre IS NOT NULL AND genre != '' ORDER BY genre");

    while (query.next()) {
        genres << query.value(0).toString();
    }
    return genres;
}

QStringList AllBooksList::getDistinctLanguages()
{
    QStringList languages;
    languages << "All";

    if (!db.isOpen() && !db.open()) return languages;

    QSqlQuery query(db);
    query.exec("SELECT DISTINCT language FROM books WHERE language IS NOT NULL AND language != '' ORDER BY language");

    while (query.next()) {
        languages << query.value(0).toString();
    }
    return languages;
}

QStringList AllBooksList::getDistinctAvailability()
{
    QStringList availability;
    availability << "All";

    if (!db.isOpen() && !db.open()) return availability;

    QSqlQuery query(db);
    query.exec("SELECT DISTINCT availability FROM books WHERE availability IS NOT NULL AND availability != '' ORDER BY availability");

    while (query.next()) {
        availability << query.value(0).toString();
    }
    return availability;
}

QStringList AllBooksList::getDistinctConditions()
{
    QStringList conditions;
    conditions << "All";

    if (!db.isOpen() && !db.open()) return conditions;

    QSqlQuery query(db);
    query.exec("SELECT DISTINCT condition FROM books WHERE condition IS NOT NULL AND condition != '' ORDER BY condition");

    while (query.next()) {
        conditions << query.value(0).toString();
    }
    return conditions;
}

QStringList AllBooksList::getDistinctMethods()
{
    QStringList methods;
    methods << "All";

    if (!db.isOpen() && !db.open()) return methods;

    QSqlQuery query(db);
    query.exec("SELECT DISTINCT method FROM books WHERE method IS NOT NULL AND method != '' ORDER BY method");

    while (query.next()) {
        methods << query.value(0).toString();
    }
    return methods;
}
