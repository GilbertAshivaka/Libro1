#include "reservationmanager.h"
#include <QMutexLocker>

ReservationManager::ReservationManager(QObject *parent)
    : QObject(parent)
{
    db = DatabaseManager::getConnection();
}

ReservationManager::~ReservationManager()
{
}

bool ReservationManager::reserveBook(int bookId, const QString &userNumber)
{
    // Get user ID from user number
    int userId = getInternalUserID(userNumber);

    if (userId <= 0) {
        emit reservationError("User not found. Please enter a valid user ID.");
        return false;
    }

    // Validate the reservation (checks duplicates and max limit)
    if (!validateReservation(bookId, userId, userNumber)) {
        return false; // Error already emitted in validateReservation
    }

    // Get user details for the reservation
    QString userEmail = getUserEmail(userId);
    QString userName = getUserName(userId);

    // Calculate dates
    QDateTime reservationDate = QDateTime::currentDateTime();
    QDateTime expiryDate = reservationDate.addDays(RESERVATION_EXPIRY_DAYS);

    // Generate reservation ID
    int reservationId = generateReservationId();

    // Insert the reservation
    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO reserved_books "
        "(reservation_id, book_id, user_id, user_email, user_name, reservation_date, "
        "expiry_date, status, source, created_at, updated_at) "
        "VALUES (:reservation_id, :book_id, :user_id, :user_email, :user_name, :reservation_date, "
        ":expiry_date, :status, :source, :created_at, :updated_at)"
        );

    query.bindValue(":reservation_id", reservationId);
    query.bindValue(":book_id", bookId);
    query.bindValue(":user_id", userId);
    query.bindValue(":user_email", userEmail);
    query.bindValue(":user_name", userName);
    query.bindValue(":reservation_date", reservationDate.toString(Qt::ISODate));
    query.bindValue(":expiry_date", expiryDate.toString(Qt::ISODate));
    query.bindValue(":status", "pending");
    query.bindValue(":source", "desktop");
    query.bindValue(":created_at", reservationDate.toString(Qt::ISODate));
    query.bindValue(":updated_at", reservationDate.toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "Failed to create reservation:" << query.lastError().text();
        emit reservationError("Failed to create reservation. Please try again.");
        return false;
    }

    // Get remaining reservations count
    int remaining = MAX_RESERVATIONS_PER_USER - getUserReservationCount(userNumber);

    QString successMsg = QString("Reservation successful! You have %1 reservation(s) remaining.")
                             .arg(remaining);
    emit reservationSuccessful(successMsg);

    qDebug() << "Reservation created successfully. ID:" << reservationId;
    return true;
}

bool ReservationManager::validateReservation(int bookId, int userId, const QString &userNumber)
{
    // Check if user has already reserved this book
    QSqlQuery duplicateCheck(db);
    duplicateCheck.prepare(
        "SELECT COUNT(*) FROM reserved_books "
        "WHERE book_id = :book_id AND user_id = :user_id "
        "AND status IN ('pending', 'ready')"
        );
    duplicateCheck.bindValue(":book_id", bookId);
    duplicateCheck.bindValue(":user_id", userId);

    if (duplicateCheck.exec() && duplicateCheck.next()) {
        if (duplicateCheck.value(0).toInt() > 0) {
            emit reservationError("You have already reserved this book.");
            return false;
        }
    }

    // Check if user has reached maximum reservations
    int currentReservations = getUserReservationCount(userNumber);
    if (currentReservations >= MAX_RESERVATIONS_PER_USER) {
        emit reservationError(
            QString("You have reached the maximum limit of %1 reservations. "
                    "Please cancel an existing reservation or wait for a book to become available.")
                .arg(MAX_RESERVATIONS_PER_USER)
            );
        return false;
    }

    return true;
}

QString ReservationManager::getReservationExpiryDate() const
{
    QDateTime expiryDate = QDateTime::currentDateTime().addDays(RESERVATION_EXPIRY_DAYS);
    return expiryDate.toString("dd/MM/yyyy");
}

QString ReservationManager::getBookStatus(int bookId) const
{
    QSqlQuery query(db);
    query.prepare("SELECT availability FROM books WHERE bookID = :book_id");
    query.bindValue(":book_id", bookId);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    return "Unknown";
}

QString ReservationManager::getExpectedReturnDate(int bookId) const
{
    QSqlQuery query(db);
    query.prepare(
        "SELECT due_date FROM issued_books "
        "WHERE book_id = :book_id AND status = 'Borrowed' "
        "ORDER BY issue_date DESC LIMIT 1"
        );
    query.bindValue(":book_id", bookId);

    if (query.exec() && query.next()) {
        QDateTime dueDate = QDateTime::fromString(query.value(0).toString(), Qt::ISODate);
        if (dueDate.isValid()) {
            return dueDate.toString("dd/MM/yyyy");
        }
    }

    return "";
}

int ReservationManager::getUserReservationCount(const QString &userNumber) const
{
    int userId = getInternalUserID(userNumber);
    if (userId <= 0) {
        return 0;
    }

    QSqlQuery query(db);
    query.prepare(
        "SELECT COUNT(*) FROM reserved_books "
        "WHERE user_id = :user_id AND status IN ('pending', 'ready')"
        );
    query.bindValue(":user_id", userId);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

bool ReservationManager::hasUserReservedBook(int bookId, const QString &userNumber) const
{
    int userId = getInternalUserID(userNumber);
    if (userId <= 0) {
        return false;
    }

    QSqlQuery query(db);
    query.prepare(
        "SELECT COUNT(*) FROM reserved_books "
        "WHERE book_id = :book_id AND user_id = :user_id "
        "AND status IN ('pending', 'ready')"
        );
    query.bindValue(":book_id", bookId);
    query.bindValue(":user_id", userId);

    if (query.exec() && query.next()) {
        return query.value(0).toInt() > 0;
    }

    return false;
}

QString ReservationManager::lookUpUserNumber(const QString &userNumber) const
{
    QSqlQuery query(db);

    // First check students table
    query.prepare(
        "SELECT u.first_name || ' ' || u.second_name AS full_name "
        "FROM users u "
        "INNER JOIN students s ON u.user_id = s.student_id "
        "WHERE s.adm_no = :user_number"
        );
    query.bindValue(":user_number", userNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    // Check staff table
    query.prepare(
        "SELECT u.first_name || ' ' || u.second_name AS full_name "
        "FROM users u "
        "INNER JOIN staff st ON u.user_id = st.staff_id "
        "WHERE st.staff_no = :user_number"
        );
    query.bindValue(":user_number", userNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    // Check other_users table
    query.prepare(
        "SELECT u.first_name || ' ' || u.second_name AS full_name "
        "FROM users u "
        "INNER JOIN other_users o ON u.user_id = o.other_users_id "
        "WHERE o.user_no = :user_number"
        );
    query.bindValue(":user_number", userNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    return "";
}

int ReservationManager::getInternalUserID(const QString &userNumber) const
{
    QSqlQuery query(db);

    // Check students table
    query.prepare("SELECT student_id FROM students WHERE adm_no = :user_number");
    query.bindValue(":user_number", userNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    // Check staff table
    query.prepare("SELECT staff_id FROM staff WHERE staff_no = :user_number");
    query.bindValue(":user_number", userNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    // Check other_users table
    query.prepare("SELECT other_users_id FROM other_users WHERE user_no = :user_number");
    query.bindValue(":user_number", userNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return -1;
}

int ReservationManager::getMaxReservations() const
{
    return MAX_RESERVATIONS_PER_USER;
}

QString ReservationManager::getUserEmail(int userId) const
{
    QSqlQuery query(db);
    query.prepare("SELECT email FROM users WHERE user_id = :user_id");
    query.bindValue(":user_id", userId);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    return "";
}

QString ReservationManager::getUserName(int userId) const
{
    QSqlQuery query(db);
    query.prepare("SELECT first_name || ' ' || second_name FROM users WHERE user_id = :user_id");
    query.bindValue(":user_id", userId);

    if (query.exec() && query.next()) {
        return query.value(0).toString();
    }

    return "";
}

int ReservationManager::generateReservationId() const
{
    QSqlQuery query(db);
    query.exec("SELECT COALESCE(MAX(reservation_id), 0) + 1 FROM reserved_books");

    if (query.next()) {
        return query.value(0).toInt();
    }

    return 1;
}
