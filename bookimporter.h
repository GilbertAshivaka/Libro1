#ifndef BOOKIMPORTER_H
#define BOOKIMPORTER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QFutureWatcher>
#include <functional>
#include <QSqlDatabase>

//Structure to store the result of the import process
struct BookImportResult{
    int successCount;
    int failCount;
    QStringList errors;

    BookImportResult(int s = 0, int f = 0, const QStringList& e = QStringList()):
        successCount(s), failCount(f), errors(e){}
};

class BookImporter : public QObject
{
    Q_OBJECT
public:
    explicit BookImporter(QObject *parent = nullptr);
    ~BookImporter();

    //starts the import process given the filepath
    Q_INVOKABLE void startImport(const QString& filePath);
    Q_INVOKABLE QString urlToLocalFile(const QString& url); //converts the url from drag and drop to filepath


signals:
    void importProgress(int importProgress);
    void importCompleted(int successCount, int failCount);
    void importError(const QString& error);
    void errorOccured(const QString& error);

private:
    BookImportResult processImport(const QString& filePath, const std::function<void (int)> & progressCallBack);
    bool processBookRecord(QSqlDatabase& db, const QStringList& bookData);
    void parseHeaders(const QString& headerLine, QStringList& headers);
    QStringList parseCsvLine(const QString& line);
    QString generateBarcode(const QString &category, const QString &title, const QString &author);

    QFutureWatcher<BookImportResult> *watcher;

};

#endif // BOOKIMPORTER_H
