#include "categorylist.h"
#include "databasemanager.h"


CategoryList::CategoryList(QObject *parent)
    : QObject{parent}
{
    db = DatabaseManager::getConnection();
    fetchCategories();

}

QStringList CategoryList::getCategories() const
{
    return categories;
}

void CategoryList::fetchCategories()
{
    if (!db.open()){
        emit errorOccured("Database connection is not open.");

        return;
    }

    QSqlQuery query(db);
    categories.clear();

    query.exec("SELECT DISTINCT subject FROM books WHERE subject IS NOT NULL AND subject != ''");

    while (query.next()){
        QString category = query.value(0).toString();
        if (!categories.contains(category)){
            categories.append(category);
        }
    }


    query.exec("SELECT DISTINCT genre FROM books WHERE genre IS NOT NULL AND genre != ''");
    while (query.next()){
        QString category = query.value(0).toString();
        if (!categories.contains(category)){
            categories.append(category);
        }
    }

    qDebug() << "Categories fetched.";

    categories.sort();
    emit categoriesChanged();
}

