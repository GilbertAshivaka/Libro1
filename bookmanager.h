#ifndef BOOKMANAGER_H
#define BOOKMANAGER_H

#include <QObject>
#include <QString>
#include <QSqlQuery>
#include <QSqlError>

class BookManager : public QObject
{
    Q_OBJECT
public:
    explicit BookManager(QObject *parent = nullptr);

    Q_INVOKABLE bool addBook(const QString &title,
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
                             const QString &method
                             );

signals:
    void errorOccured(const QString &error);
    void bookAdded();

private:
    bool validateInputs(
        const QString &title,
        const QString &author,
        int shelfNumber,
        int value
        );

};


#endif // BOOKMANAGER_H
