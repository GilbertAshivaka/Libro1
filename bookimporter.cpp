#include "bookimporter.h"
#include <QtConcurrent>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QUuid>
#include <QUrl>

#include "barcodewriter.h"

BookImporter::BookImporter(QObject *parent)
    : QObject(parent),
    watcher(new QFutureWatcher<BookImportResult>(this))
{
    connect(watcher, &QFutureWatcher<BookImportResult>::finished, this, [this]() {
        BookImportResult result = watcher->result();
        emit importCompleted(result.successCount, result.failCount);
        if (!result.errors.isEmpty()) {
            emit importError(result.errors.join("\n"));
        }
    });
}

BookImporter::~BookImporter()
{
    if (watcher->isRunning()) {
        watcher->cancel();
        watcher->waitForFinished();
    }
}

void BookImporter::startImport(const QString &filePath)
{
    auto future = QtConcurrent::run([this, filePath]() {
        return processImport(filePath, [this](int progress) {
            emit importProgress(progress);
        });
    });
    watcher->setFuture(future);
}

QString BookImporter::urlToLocalFile(const QString &url)
{
    return QUrl(url).toLocalFile();
}

void BookImporter::parseHeaders(const QString &headerLine, QStringList &headers)
{
    headers = headerLine.split(",");
    for (QString &header : headers) {
        header = header.trimmed();
    }
}

QStringList BookImporter::parseCsvLine(const QString &line) {
    QStringList result;
    QString currentField;
    bool inQuotes = false;

    for (int i = 0; i < line.size(); ++i) {
        QChar c = line.at(i);
        if (c == '\"') {
            // If we're already in quotes and the next character is a quote, it's an escaped quote.
            if (inQuotes && i + 1 < line.size() && line.at(i + 1) == '\"') {
                currentField.append('\"');
                ++i;  // Skip the next quote.
            } else {
                inQuotes = !inQuotes;  // Toggle the state.
            }
        } else if (c == ',' && !inQuotes) {
            result.append(currentField.trimmed());
            currentField.clear();
        } else {
            currentField.append(c);
        }
    }
    // Add the last field.
    result.append(currentField.trimmed());
    return result;
}


QString BookImporter::generateBarcode(const QString &category = "", const QString &title = "", const QString &author = "")
{
    QString prefix = category.isEmpty() ? "BC" : category.left(2).toUpper();

    QDateTime now = QDateTime::currentDateTime();
    QString timeStamp = now.toString("yyMMdd");

    QString random = QString::number(QRandomGenerator::global()->bounded(10000, 10)).rightJustified(4, '0');

    QString barcode = prefix +timeStamp + random;

    //generate and save barcode image for printing
    BarcodeWriter barcodeWriter;
    barcodeWriter.writeAndSaveBarcode("Code128", barcode, title, author);

    return barcode;
}

BookImportResult BookImporter::processImport(const QString &filePath, const std::function<void (int)> &progressCallback)
{
    BookImportResult result;
    const QString connectionName = "book_import_thread_connection";
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
    db.setDatabaseName("library.db");

    if (!db.open()) {
        result.errors.append("Failed to open database: " + db.lastError().text());
        return result;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        result.errors.append("Could not open file for reading: " + filePath);
        db.close();
        QSqlDatabase::removeDatabase(connectionName);
        return result;
    }

    QTextStream in(&file);

    // Ensure file is not empty.
    if (in.atEnd()) {
        result.errors.append("File is empty");
        file.close();
        db.close();
        QSqlDatabase::removeDatabase(connectionName);
        return result;
    }

    // Read and parse header.
    QString headerLine = in.readLine();
    QStringList headers;
    parseHeaders(headerLine, headers);
    // (Optional: Validate header names if necessary)

    // Count total lines for progress calculation.
    int totalLines = 0;
    while (!in.atEnd()) {
        in.readLine();
        totalLines++;
    }

    // Reset the file pointer and skip the header.
    file.seek(0);
    in.readLine();
    int currentLine = 0;
    while (!in.atEnd()) {
        QString line = in.readLine();
        QStringList bookData = parseCsvLine(line);
        if (processBookRecord(db, bookData)) {
            result.successCount++;
        } else {
            result.failCount++;
            result.errors.append("Failed to process book: " + line);
        }
        currentLine++;
        int progress = (currentLine * 100) / (totalLines > 0 ? totalLines : 1);
        progressCallback(progress);
    }

    file.close();
    db.close();
    QSqlDatabase::removeDatabase(connectionName);
    return result;
}

bool BookImporter::processBookRecord(QSqlDatabase &db, const QStringList &bookData)
{
    // Expected CSV columns:
    // 0: title, 1: author, 2: callNumber, 3: publisher, 4: isbn,
    // 5: shelfNo, 6: description, 7: language, 8: subject, 9: genre,
    // 10: value, 11: method
    if (bookData.size() < 12) {
        qWarning() << "Insufficient book data.";
        return false;
    }

    QString title       = bookData[0].trimmed();
    QString author      = bookData[1].trimmed();
    QString callNumber  = bookData[2].trimmed();
    QString publisher   = bookData[3].trimmed();
    QString isbn        = bookData[4].trimmed();
    QString shelfNo     = bookData[5].trimmed();     // can be blank
    QString description = bookData[6].trimmed();       // can be blank
    QString language    = bookData[7].trimmed();
    QString subject     = bookData[8].trimmed();
    QString genre       = bookData[9].trimmed();
    QString valueStr    = bookData[10].trimmed();
    QString method      = bookData[11].trimmed();


    // Validate that required fields are provided.
    if (title.isEmpty() || author.isEmpty() || callNumber.isEmpty() ||
        publisher.isEmpty() || isbn.isEmpty() ||
        language.isEmpty() || subject.isEmpty() || genre.isEmpty() ||
        valueStr.isEmpty() || method.isEmpty())
    {
        qWarning() << "Missing required book fields.";
        return false;
    }

    bool valueOk = false;
    int value = valueStr.toInt(&valueOk);
    if (!valueOk) {
        qWarning() << "Invalid value for book:" << valueStr;
        return false;
    }

    // Auto-generate a unique barcode.
    QString barcode = generateBarcode(subject, title, author);

    QSqlQuery query(db);
    if (!query.exec("BEGIN TRANSACTION")) {
        qWarning() << "Failed to begin transaction:" << query.lastError().text();
        return false;
    }

    query.prepare("INSERT OR IGNORE INTO books "
                  "(title, author, callNumber, publisher, isbn, barcode, shelfNumber, "
                  "description, language, subject, genre, value, method) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(title);
    query.addBindValue(author);
    query.addBindValue(callNumber);
    query.addBindValue(publisher);
    query.addBindValue(isbn);
    query.addBindValue(barcode);
    query.addBindValue(shelfNo);
    query.addBindValue(description);
    query.addBindValue(language);
    query.addBindValue(subject);
    query.addBindValue(genre);
    query.addBindValue(value);
    query.addBindValue(method);

    bool success = query.exec();
    if (!success) {
        query.exec("ROLLBACK");
        qWarning() << "Failed to insert into books table:" << query.lastError().text();
        return false;
    }

    if (!query.exec("COMMIT")) {
        qWarning() << "Failed to commit transaction:" << query.lastError().text();
        return false;
    }

    return true;
}
