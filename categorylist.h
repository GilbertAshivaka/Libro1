#ifndef CATEGORYLIST_H
#define CATEGORYLIST_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVector>
#include <QString>

class CategoryList : public QObject
{
    Q_OBJECT
public:
    explicit CategoryList(QObject *parent = nullptr);

    Q_INVOKABLE QStringList getCategories() const;
    Q_INVOKABLE void fetchCategories();



signals:
    void categoriesChanged();
    void errorOccured(const QString& error);

private:
    QSqlDatabase db;
    QStringList categories;
};

#endif // CATEGORYLIST_H
