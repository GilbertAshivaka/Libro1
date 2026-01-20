#ifndef RESERVATIONMANAGER_H
#define RESERVATIONMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>
#include "databasemanager.h"

class ReservationManager : public QObject
{
    Q_OBJECT

public:
    explicit ReservationManager(QObject *parent = nullptr);
    ~ReservationManager();

    // Main reservation function
    Q_INVOKABLE bool reserveBook(int bookId, const QString &userNumber);

    // Helper functions for UI
    Q_INVOKABLE QString getReservationExpiryDate() const;
    Q_INVOKABLE QString getBookStatus(int bookId) const;
    Q_INVOKABLE QString getExpectedReturnDate(int bookId) const;
    Q_INVOKABLE int getUserReservationCount(const QString &userNumber) const;
    Q_INVOKABLE bool hasUserReservedBook(int bookId, const QString &userNumber) const;
    Q_INVOKABLE QString lookUpUserNumber(const QString &userNumber) const;
    Q_INVOKABLE int getInternalUserID(const QString &userNumber) const;
    Q_INVOKABLE int getMaxReservations() const;

signals:
    void reservationSuccessful(const QString &message);
    void reservationError(const QString &errorMessage);

private:
    QSqlDatabase db;

    // Constants
    static const int RESERVATION_EXPIRY_DAYS = 7;
    static const int MAX_RESERVATIONS_PER_USER = 3;

    // Helper methods
    bool validateReservation(int bookId, int userId, const QString &userNumber);
    QString getUserEmail(int userId) const;
    QString getUserName(int userId) const;
    int generateReservationId() const;
};

#endif // RESERVATIONMANAGER_H
