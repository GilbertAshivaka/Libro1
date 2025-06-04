#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>
#include <QString>
#include <QSqlQuery>
#include <QVariant>
#include <QVariantMap>
#include <QSqlError>
#include <QDebug>

class UserManager : public QObject
{
    Q_OBJECT
public:
    explicit UserManager(QObject *parent = nullptr);

    //destructor
    ~UserManager();

    Q_INVOKABLE bool addUser(const QString &firstName, const QString &lastName, const QString &email, const QString &phone,  const QString &userRole, const QVariantMap &additionalInfo);

signals:
    void errorOccured(const QString &errorMessage);
private:

};

#endif // USERMANAGER_H
