#ifndef ALLUSERSLIST_H
#define ALLUSERSLIST_H

#include <QObject>
#include <QVector>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QThread>
#include <QtConcurrent>

#include "databasemanager.h"

class User {
public:
    // Base user properties
    int userId = -1;
    QString firstName;
    QString lastName;
    QString email;
    QString phone; //added
    QString userRole;
    QString status; //added
    QDateTime createdAt;
    QDateTime updatedAt;

    //properties for different user types
    // Student specific
    QString admNo;
    QString branch;
    int enrollmentYear = 0;
    QString level;

    // Staff specific
    QString staffNo;
    QString department;
    int startYear = 0;
    QString category;

    // Other user specific
    QString userNo;
    QString residence;
    int age = 0;
    QString gender;
    QString phone2;

    User() {}

    // Basic constructor for simple cases
    User(const QString &first, const QString &last, const QString &mail, const QString &role)
        : firstName(first), lastName(last), email(mail), userRole(role) {}

    //helper method to create user from query
    static User fromQuery(const QSqlQuery &query, const QString &userRole);
};

class AllUsersList : public QObject
{
    Q_OBJECT
public:
    explicit AllUsersList(QObject *parent = nullptr);
    ~AllUsersList();

    QVector<User> getUsers() const;
    Q_INVOKABLE int getTotalUsersCount(const QString& userType);

public slots:
    bool fetchUsers(QString userRole, int page, int pageSize);
    void removeUser(int index);
    Q_INVOKABLE bool searchUsers(const QString &searchTerm);


signals:
    void preUserAppended();
    void postUserAppended();
    void preUserRemoved(int index);
    void postUserRemoved();
    void usersUpdated();
    void errorOccured(QString error);
    void preModelReset();
    void postModelReset();

private:
    QSqlDatabase db;
    QVector<User> users;

    bool validateUsers(QString name, QString userID);
};

#endif // ALLUSERSLIST_H

















