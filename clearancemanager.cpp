#include "clearancemanager.h"
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QVariant>
#include <QFile>
#include <QTextStream>
// #include <QTextCodec>

ClearanceManager::ClearanceManager(QObject *parent)
    : QObject(parent)
    , m_isProcessing(false)
    , m_clearanceStatus("idle")
{
    db = DatabaseManager::getConnection();
}

void ClearanceManager::processClearance(const QString &userName, const QString &userNumber,
                                        const QString &userType, int adminUserId)
{
    m_isProcessing = true;
    emit processingChanged();

    m_clearanceStatus = "processing";
    emit clearanceStatusChanged();

    m_clearanceResult.clear();

    // Get user information
    QVariantMap userInfo = getUserInfo(userNumber, userType);

    if (userInfo.isEmpty() || !userInfo.contains("user_id")) {
        m_clearanceStatus = "error";
        emit clearanceStatusChanged();
        emit errorOccurred("User not found with the provided information");

        m_isProcessing = false;
        emit processingChanged();
        return;
    }

    // Remember the user context (incl. the original lookup number/type used by
    // the receipt) so we can re-evaluate after a payment/waiver without the
    // operator re-entering the details.
    QVariantMap ctx = userInfo;
    ctx["user_number"] = userNumber;
    ctx["user_type"] = userType;
    m_currentUserInfo = ctx;
    m_currentAdminId = adminUserId;
    m_hasContext = true;

    buildClearanceResult(ctx, adminUserId);

    m_isProcessing = false;
    emit processingChanged();
}

void ClearanceManager::buildClearanceResult(const QVariantMap &userInfo, int adminUserId)
{
    int userId = userInfo["user_id"].toInt();
    QString fullName = userInfo["full_name"].toString();
    QString email = userInfo["email"].toString();
    QString phone = userInfo["phone"].toString();
    QString userNumber = userInfo.value("user_number").toString();
    QString userType = userInfo.value("user_type").toString();

    // Perform all clearance checks
    QVariantMap borrowedBooksCheck = checkBorrowedBooks(userId);
    QVariantMap digitalMaterialsCheck = checkDigitalMaterials(userId);
    QVariantMap lostBooksCheck = checkLostBooks(userId);
    QVariantMap unpaidFinesCheck = checkUnpaidFines(userId);

    // Determine if clearance is approved
    bool booksCleared = borrowedBooksCheck["cleared"].toBool();
    bool materialsCleared = digitalMaterialsCheck["cleared"].toBool();
    bool lostBooksCleared = lostBooksCheck["cleared"].toBool();
    bool finesCleared = unpaidFinesCheck["cleared"].toBool();

    bool approved = booksCleared && materialsCleared && lostBooksCleared && finesCleared;

    // Build clearance result
    m_clearanceResult.clear();
    m_clearanceResult["approved"] = approved;
    m_clearanceResult["status"] = approved ? "Approved" : "Rejected";
    m_clearanceResult["user_id"] = userId;
    m_clearanceResult["user_name"] = fullName;
    m_clearanceResult["user_number"] = userNumber;
    m_clearanceResult["user_type"] = userType;
    m_clearanceResult["email"] = email;
    m_clearanceResult["phone"] = phone;
    m_clearanceResult["clearance_date"] = getCurrentDateTime();
    m_clearanceResult["processed_by"] = adminUserId;

    // Add check results
    m_clearanceResult["borrowed_books"] = borrowedBooksCheck;
    m_clearanceResult["digital_materials"] = digitalMaterialsCheck;
    m_clearanceResult["lost_books"] = lostBooksCheck;
    m_clearanceResult["unpaid_fines"] = unpaidFinesCheck;

    // Build rejection reasons if not approved
    QStringList rejectionReasons;
    if (!booksCleared) {
        rejectionReasons.append("Unreturned Books");
    }
    if (!materialsCleared) {
        rejectionReasons.append("Unreturned Digital Materials");
    }
    if (!lostBooksCleared) {
        rejectionReasons.append("Unpaid Lost Book Charges");
    }
    if (!finesCleared) {
        rejectionReasons.append("Outstanding Fines");
    }
    m_clearanceResult["rejection_reasons"] = rejectionReasons;

    // Log the clearance
    QString logMessage = approved ?
                             QString("Clearance APPROVED for %1 (%2)").arg(fullName, userNumber) :
                             QString("Clearance REJECTED for %1 (%2)").arg(fullName, userNumber);

    QString logDetails = QString("User Type: %1\nStatus: %2\nReasons: %3")
                             .arg(userType)
                             .arg(approved ? "Approved" : "Rejected")
                             .arg(rejectionReasons.join(", "));

    logClearance(approved ? "INFO" : "WARNING", logMessage, logDetails, userId);

    // Update status
    m_clearanceStatus = approved ? "approved" : "rejected";
    emit clearanceStatusChanged();
    emit clearanceResultChanged();
    emit clearanceCompleted(approved, approved ? "Clearance Approved" : "Clearance Rejected");
}

void ClearanceManager::reevaluate()
{
    if (!m_hasContext)
        return;
    buildClearanceResult(m_currentUserInfo, m_currentAdminId);
}

QVariantMap ClearanceManager::getUserInfo(const QString &userNumber, const QString &userType)
{
    QVariantMap userInfo;
    QSqlQuery query(db);

    QString queryStr;
    if (userType == "student") {
        queryStr = "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, "
                   "s.adm_no, s.branch, s.level "
                   "FROM students s "
                   "LEFT JOIN users u ON u.user_id = s.student_id "
                   "WHERE s.adm_no = :userNumber";
    } else if (userType == "staff") {
        queryStr = "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, "
                   "st.staff_no, st.department, st.category "
                   "FROM staff st "
                   "LEFT JOIN users u ON u.user_id = st.staff_id "
                   "WHERE st.staff_no = :userNumber";
    } else if (userType == "other_user") {
        queryStr = "SELECT u.user_id, u.first_name, u.second_name, u.email, u.phone, "
                   "o.user_no, o.residence "
                   "FROM other_users o "
                   "LEFT JOIN users u ON u.user_id = o.other_users_id "
                   "WHERE o.user_no = :userNumber";
    } else {
        return userInfo;
    }

    query.prepare(queryStr);
    query.bindValue(":userNumber", userNumber);

    if (query.exec() && query.next()) {
        userInfo["user_id"] = query.value(0).toInt();
        userInfo["first_name"] = query.value(1).toString();
        userInfo["second_name"] = query.value(2).toString();
        userInfo["full_name"] = query.value(1).toString() + " " + query.value(2).toString();
        userInfo["email"] = query.value(3).toString();
        userInfo["phone"] = query.value(4).toString();

        if (userType == "student") {
            userInfo["adm_no"] = query.value(5).toString();
            userInfo["branch"] = query.value(6).toString();
            userInfo["level"] = query.value(7).toString();
        } else if (userType == "staff") {
            userInfo["staff_no"] = query.value(5).toString();
            userInfo["department"] = query.value(6).toString();
            userInfo["category"] = query.value(7).toString();
        } else if (userType == "other_user") {
            userInfo["user_no"] = query.value(5).toString();
            userInfo["residence"] = query.value(6).toString();
        }
    } else {
        qWarning() << "Failed to get user info:" << query.lastError().text();
    }

    return userInfo;
}

QVariantMap ClearanceManager::checkBorrowedBooks(int userId)
{
    QVariantMap result;
    QVariantList issues;

    QSqlQuery query(db);
    query.prepare("SELECT ib.issue_id, b.title, b.callNumber, b.bookID, "
                  "ib.issue_date, ib.due_date "
                  "FROM issued_books ib "
                  "JOIN books b ON ib.book_id = b.bookID "
                  "WHERE ib.user_id = :userId AND ib.status = 'Borrowed'");
    query.bindValue(":userId", userId);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap issue;
            issue["issue_id"] = query.value(0).toInt();
            issue["title"] = query.value(1).toString();
            issue["call_number"] = query.value(2).toString();
            issue["book_id"] = query.value(3).toInt();
            issue["issue_date"] = query.value(4).toString();
            issue["due_date"] = query.value(5).toString();
            issues.append(issue);
        }
    } else {
        qWarning() << "Failed to check borrowed books:" << query.lastError().text();
    }

    result["cleared"] = issues.isEmpty();
    result["count"] = issues.size();
    result["issues"] = issues;
    result["category"] = "Borrowed Books";

    return result;
}

QVariantMap ClearanceManager::checkDigitalMaterials(int userId)
{
    QVariantMap result;
    QVariantList issues;

    // First get user number to match with holder field
    QSqlQuery userQuery(db);
    userQuery.prepare("SELECT u.first_name, u.second_name, "
                      "COALESCE(s.adm_no, st.staff_no, o.user_no) as user_number "
                      "FROM users u "
                      "LEFT JOIN students s ON u.user_id = s.student_id "
                      "LEFT JOIN staff st ON u.user_id = st.staff_id "
                      "LEFT JOIN other_users o ON u.user_id = o.other_users_id "
                      "WHERE u.user_id = :userId");
    userQuery.bindValue(":userId", userId);

    QString userNumber;
    if (userQuery.exec() && userQuery.next()) {
        userNumber = userQuery.value(2).toString();
    }

    // Check for unreturned digital materials in loans table
    QSqlQuery query(db);
    query.prepare("SELECT dml.loan_id, dml.item_name, dm.ItemType, dml.quantity_borrowed, "
                  "dml.issue_date, dm.ItemID "
                  "FROM digital_materials_loans dml "
                  "JOIN digital_materials dm ON dml.item_id = dm.ItemID "
                  "WHERE dml.user_number = :userNumber AND dml.status = 'Borrowed'");
    query.bindValue(":userNumber", userNumber);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap issue;
            issue["loan_id"] = query.value(0).toInt();
            issue["item_name"] = query.value(1).toString();
            issue["item_type"] = query.value(2).toString();
            issue["quantity"] = query.value(3).toInt();
            issue["issue_date"] = query.value(4).toString();
            issue["item_id"] = query.value(5).toInt();
            issues.append(issue);
        }
    } else {
        qWarning() << "Failed to check digital materials:" << query.lastError().text();
    }

    result["cleared"] = issues.isEmpty();
    result["count"] = issues.size();
    result["issues"] = issues;
    result["category"] = "Digital Materials";

    return result;
}

QVariantMap ClearanceManager::checkLostBooks(int userId)
{
    QVariantMap result;
    QVariantList issues;
    double totalOwed = 0.0;

    QSqlQuery query(db);
    query.prepare("SELECT lost_id, book_title, book_call_number, "
                  "total_amount_due, amount_paid, status "
                  "FROM lost_books "
                  "WHERE user_id = :userId AND status IN ('Lost', 'Unpaid')");
    query.bindValue(":userId", userId);

    if (query.exec()) {
        while (query.next()) {
            double amountDue = query.value(3).toDouble();
            double amountPaid = query.value(4).toDouble();
            double balance = amountDue - amountPaid;

            if (balance > 0) {
                QVariantMap issue;
                issue["lost_id"] = query.value(0).toInt();
                issue["book_title"] = query.value(1).toString();
                issue["call_number"] = query.value(2).toString();
                issue["amount_due"] = amountDue;
                issue["amount_paid"] = amountPaid;
                issue["balance"] = balance;
                issue["status"] = query.value(5).toString();
                issues.append(issue);
                totalOwed += balance;
            }
        }
    } else {
        qWarning() << "Failed to check lost books:" << query.lastError().text();
    }

    result["cleared"] = issues.isEmpty();
    result["count"] = issues.size();
    result["issues"] = issues;
    result["total_owed"] = totalOwed;
    result["category"] = "Lost Books";

    return result;
}

QVariantMap ClearanceManager::checkUnpaidFines(int userId)
{
    QVariantMap result;
    QVariantList issues;
    double totalOwed = 0.0;

    // Read from the persistent outstanding_fines ledger (a returned book's late
    // fee is preserved there). Balance = fine_amount - amount_paid - amount_waived.
    QSqlQuery query(db);
    query.prepare("SELECT fine_id, book_title, book_call_number, fine_amount, "
                  "amount_paid, amount_waived, fine_type, created_at "
                  "FROM outstanding_fines "
                  "WHERE user_id = :userId "
                  "AND (fine_amount - amount_paid - amount_waived) > 0.009");
    query.bindValue(":userId", userId);

    if (query.exec()) {
        while (query.next()) {
            double fineAmount = query.value("fine_amount").toDouble();
            double paid = query.value("amount_paid").toDouble();
            double waived = query.value("amount_waived").toDouble();
            double balance = fineAmount - paid - waived;

            if (balance > 0) {
                QVariantMap issue;
                issue["fine_id"] = query.value("fine_id").toInt();
                issue["book_title"] = query.value("book_title").toString();
                issue["call_number"] = query.value("book_call_number").toString();
                issue["fine_amount"] = fineAmount;
                issue["amount_paid"] = paid;
                issue["amount_waived"] = waived;
                issue["balance"] = balance;
                issue["fine_type"] = query.value("fine_type").toString();
                issues.append(issue);
                totalOwed += balance;
            }
        }
    } else {
        qWarning() << "Failed to check unpaid fines:" << query.lastError().text();
    }

    result["cleared"] = issues.isEmpty();
    result["count"] = issues.size();
    result["issues"] = issues;
    result["total_owed"] = totalOwed;
    result["category"] = "Unpaid Fines";

    return result;
}

// ============================================================================
// Settlement: payments (partial allowed) and waivers (reason required)
// ============================================================================

void ClearanceManager::recordSettlement(const QString &sourceType, int sourceId, int userId,
                                        const QString &action, double amount,
                                        const QString &reason, int adminUserId)
{
    QSqlQuery query(db);
    query.prepare("INSERT INTO fine_settlements "
                  "(source_type, source_id, user_id, action, amount, reason, admin_user_id) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(sourceType);
    query.addBindValue(sourceId);
    query.addBindValue(userId);
    query.addBindValue(action);
    query.addBindValue(amount);
    query.addBindValue(reason);
    query.addBindValue(adminUserId);
    if (!query.exec())
        qWarning() << "Failed to record settlement:" << query.lastError().text();
}

bool ClearanceManager::payFine(int fineId, double amount, int adminUserId)
{
    QSqlQuery q(db);
    q.prepare("SELECT user_id, fine_amount, amount_paid, amount_waived "
              "FROM outstanding_fines WHERE fine_id = ?");
    q.addBindValue(fineId);
    if (!q.exec() || !q.next()) {
        emit settlementCompleted(false, "Fine record not found.");
        return false;
    }
    int userId = q.value(0).toInt();
    double fineAmount = q.value(1).toDouble();
    double paid = q.value(2).toDouble();
    double waived = q.value(3).toDouble();
    double balance = fineAmount - paid - waived;

    if (amount <= 0.0) {
        emit settlementCompleted(false, "Payment amount must be greater than zero.");
        return false;
    }
    if (amount - balance > 0.009) {
        emit settlementCompleted(false, QString("Payment exceeds the outstanding balance of %1.")
                                            .arg(formatCurrency(balance)));
        return false;
    }

    double newPaid = paid + amount;
    bool settled = (fineAmount - newPaid - waived) <= 0.009;

    QSqlQuery up(db);
    if (settled) {
        up.prepare("UPDATE outstanding_fines SET amount_paid = ?, status = 'paid', "
                   "settled_by = ?, settled_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP "
                   "WHERE fine_id = ?");
        up.addBindValue(newPaid);
        up.addBindValue(adminUserId);
        up.addBindValue(fineId);
    } else {
        up.prepare("UPDATE outstanding_fines SET amount_paid = ?, updated_at = CURRENT_TIMESTAMP "
                   "WHERE fine_id = ?");
        up.addBindValue(newPaid);
        up.addBindValue(fineId);
    }
    if (!up.exec()) {
        emit settlementCompleted(false, "Failed to record payment: " + up.lastError().text());
        return false;
    }

    recordSettlement("fine", fineId, userId, "payment", amount, QString(), adminUserId);
    logClearance("INFO", QString("Fine payment of %1 recorded").arg(formatCurrency(amount)),
                 QString("fine_id=%1, settled=%2").arg(fineId).arg(settled ? "yes" : "no"), userId);
    emit settlementCompleted(true, QString("Payment of %1 recorded.").arg(formatCurrency(amount)));
    reevaluate();
    return true;
}

bool ClearanceManager::waiveFine(int fineId, const QString &reason, int adminUserId)
{
    if (reason.trimmed().isEmpty()) {
        emit settlementCompleted(false, "A reason is required to waive a fine.");
        return false;
    }

    QSqlQuery q(db);
    q.prepare("SELECT user_id, fine_amount, amount_paid, amount_waived "
              "FROM outstanding_fines WHERE fine_id = ?");
    q.addBindValue(fineId);
    if (!q.exec() || !q.next()) {
        emit settlementCompleted(false, "Fine record not found.");
        return false;
    }
    int userId = q.value(0).toInt();
    double fineAmount = q.value(1).toDouble();
    double paid = q.value(2).toDouble();
    double waived = q.value(3).toDouble();
    double balance = fineAmount - paid - waived;

    if (balance <= 0.009) {
        emit settlementCompleted(false, "This fine has no outstanding balance.");
        return false;
    }

    double newWaived = waived + balance;   // waive the remaining balance

    QSqlQuery up(db);
    up.prepare("UPDATE outstanding_fines SET amount_waived = ?, status = 'waived', "
               "waiver_reason = ?, settled_by = ?, settled_at = CURRENT_TIMESTAMP, "
               "updated_at = CURRENT_TIMESTAMP WHERE fine_id = ?");
    up.addBindValue(newWaived);
    up.addBindValue(reason.trimmed());
    up.addBindValue(adminUserId);
    up.addBindValue(fineId);
    if (!up.exec()) {
        emit settlementCompleted(false, "Failed to waive fine: " + up.lastError().text());
        return false;
    }

    recordSettlement("fine", fineId, userId, "waiver", balance, reason.trimmed(), adminUserId);
    logClearance("WARNING", QString("Fine of %1 waived").arg(formatCurrency(balance)),
                 QString("fine_id=%1, reason=%2").arg(fineId).arg(reason.trimmed()), userId);
    emit settlementCompleted(true, QString("Fine of %1 waived.").arg(formatCurrency(balance)));
    reevaluate();
    return true;
}

bool ClearanceManager::payLostBook(int lostId, double amount, int adminUserId)
{
    QSqlQuery q(db);
    q.prepare("SELECT user_id, total_amount_due, amount_paid FROM lost_books WHERE lost_id = ?");
    q.addBindValue(lostId);
    if (!q.exec() || !q.next()) {
        emit settlementCompleted(false, "Lost book record not found.");
        return false;
    }
    int userId = q.value(0).toInt();
    double totalDue = q.value(1).toDouble();
    double paid = q.value(2).toDouble();
    double balance = totalDue - paid;

    if (amount <= 0.0) {
        emit settlementCompleted(false, "Payment amount must be greater than zero.");
        return false;
    }
    if (amount - balance > 0.009) {
        emit settlementCompleted(false, QString("Payment exceeds the outstanding balance of %1.")
                                            .arg(formatCurrency(balance)));
        return false;
    }

    double newPaid = paid + amount;
    bool settled = (totalDue - newPaid) <= 0.009;

    QSqlQuery up(db);
    if (settled) {
        up.prepare("UPDATE lost_books SET amount_paid = ?, status = 'Paid', "
                   "payment_date = CURRENT_TIMESTAMP, resolved_by = ?, "
                   "resolution_date = CURRENT_TIMESTAMP, resolution_type = 'Paid', "
                   "updated_at = CURRENT_TIMESTAMP WHERE lost_id = ?");
        up.addBindValue(newPaid);
        up.addBindValue(adminUserId);
        up.addBindValue(lostId);
    } else {
        up.prepare("UPDATE lost_books SET amount_paid = ?, payment_date = CURRENT_TIMESTAMP, "
                   "updated_at = CURRENT_TIMESTAMP WHERE lost_id = ?");
        up.addBindValue(newPaid);
        up.addBindValue(lostId);
    }
    if (!up.exec()) {
        emit settlementCompleted(false, "Failed to record payment: " + up.lastError().text());
        return false;
    }

    recordSettlement("lost_book", lostId, userId, "payment", amount, QString(), adminUserId);
    logClearance("INFO", QString("Lost book payment of %1 recorded").arg(formatCurrency(amount)),
                 QString("lost_id=%1, settled=%2").arg(lostId).arg(settled ? "yes" : "no"), userId);
    emit settlementCompleted(true, QString("Payment of %1 recorded.").arg(formatCurrency(amount)));
    reevaluate();
    return true;
}

bool ClearanceManager::waiveLostBook(int lostId, const QString &reason, int adminUserId)
{
    if (reason.trimmed().isEmpty()) {
        emit settlementCompleted(false, "A reason is required to waive a lost book charge.");
        return false;
    }

    QSqlQuery q(db);
    q.prepare("SELECT user_id, total_amount_due, amount_paid FROM lost_books WHERE lost_id = ?");
    q.addBindValue(lostId);
    if (!q.exec() || !q.next()) {
        emit settlementCompleted(false, "Lost book record not found.");
        return false;
    }
    int userId = q.value(0).toInt();
    double totalDue = q.value(1).toDouble();
    double paid = q.value(2).toDouble();
    double balance = totalDue - paid;

    if (balance <= 0.009) {
        emit settlementCompleted(false, "This lost book charge has no outstanding balance.");
        return false;
    }

    // Mark as waived. checkLostBooks() only counts status IN ('Lost','Unpaid'),
    // so a 'Waived' record is excluded without misreporting it as paid.
    QSqlQuery up(db);
    up.prepare("UPDATE lost_books SET status = 'Waived', resolution_type = 'Waiver', "
               "resolved_by = ?, resolution_date = CURRENT_TIMESTAMP, "
               "notes = COALESCE(notes, '') || ' [Waiver: ' || ? || ']', "
               "updated_at = CURRENT_TIMESTAMP WHERE lost_id = ?");
    up.addBindValue(adminUserId);
    up.addBindValue(reason.trimmed());
    up.addBindValue(lostId);
    if (!up.exec()) {
        emit settlementCompleted(false, "Failed to waive lost book charge: " + up.lastError().text());
        return false;
    }

    recordSettlement("lost_book", lostId, userId, "waiver", balance, reason.trimmed(), adminUserId);
    logClearance("WARNING", QString("Lost book charge of %1 waived").arg(formatCurrency(balance)),
                 QString("lost_id=%1, reason=%2").arg(lostId).arg(reason.trimmed()), userId);
    emit settlementCompleted(true, QString("Lost book charge of %1 waived.").arg(formatCurrency(balance)));
    reevaluate();
    return true;
}

bool ClearanceManager::finalizeClearance()
{
    if (m_clearanceResult.isEmpty() || !m_clearanceResult.contains("user_id")) {
        emit clearanceFinalized(false, "No clearance to finalize.");
        return false;
    }
    if (!m_clearanceResult["approved"].toBool()) {
        emit clearanceFinalized(false, "Clearance is not approved; resolve all outstanding items first.");
        return false;
    }

    int userId = m_clearanceResult["user_id"].toInt();
    QString userName = m_clearanceResult["user_name"].toString();
    QString userNumber = m_clearanceResult["user_number"].toString();
    QString userType = m_clearanceResult["user_type"].toString();
    QString status = m_clearanceResult["status"].toString();
    QString summary = QString("All checks cleared. Finalized %1 by admin %2.")
                          .arg(m_clearanceResult["clearance_date"].toString())
                          .arg(m_currentAdminId);

    db.transaction();

    // 1) Persist the certificate FIRST so it survives the user's deletion.
    QSqlQuery ins(db);
    ins.prepare("INSERT INTO clearances "
                "(user_id, user_name, user_number, user_type, status, summary, cleared_by) "
                "VALUES (?, ?, ?, ?, ?, ?, ?)");
    ins.addBindValue(userId);
    ins.addBindValue(userName);
    ins.addBindValue(userNumber);
    ins.addBindValue(userType);
    ins.addBindValue(status);
    ins.addBindValue(summary);
    ins.addBindValue(m_currentAdminId);
    if (!ins.exec()) {
        db.rollback();
        emit clearanceFinalized(false, "Failed to save clearance record: " + ins.lastError().text());
        return false;
    }

    // 2) Remove the role-specific row (avoids orphans if cascade is off), then the user.
    QString roleTable, roleIdCol;
    if (userType == "student")          { roleTable = "students";     roleIdCol = "student_id"; }
    else if (userType == "staff")       { roleTable = "staff";        roleIdCol = "staff_id"; }
    else if (userType == "other_user")  { roleTable = "other_users";  roleIdCol = "other_users_id"; }

    if (!roleTable.isEmpty()) {
        QSqlQuery delRole(db);
        delRole.prepare(QString("DELETE FROM %1 WHERE %2 = ?").arg(roleTable, roleIdCol));
        delRole.addBindValue(userId);
        delRole.exec();   // non-fatal
    }

    QSqlQuery delUser(db);
    delUser.prepare("DELETE FROM users WHERE user_id = ?");
    delUser.addBindValue(userId);
    if (!delUser.exec()) {
        db.rollback();
        emit clearanceFinalized(false, "Failed to remove user: " + delUser.lastError().text());
        return false;
    }

    if (!db.commit()) {
        db.rollback();
        emit clearanceFinalized(false, "Failed to commit finalization: " + db.lastError().text());
        return false;
    }

    logClearance("INFO",
                 QString("Clearance finalized and user removed: %1 (%2)").arg(userName, userNumber),
                 QString("Cleared by admin %1").arg(m_currentAdminId), userId);

    m_hasContext = false;
    emit clearanceFinalized(true, QString("%1 cleared and removed successfully.").arg(userName));
    clearResult();
    return true;
}

void ClearanceManager::logClearance(const QString &level, const QString &message,
                                    const QString &details, int userId)
{
    QSqlQuery query(db);
    query.prepare("INSERT INTO system_logs (log_level, log_category, log_message, details, user_id) "
                  "VALUES (:level, 'CLEARANCE', :message, :details, :userId)");
    query.bindValue(":level", level);
    query.bindValue(":message", message);
    query.bindValue(":details", details);
    query.bindValue(":userId", userId);

    if (!query.exec()) {
        qWarning() << "Failed to log clearance:" << query.lastError().text();
    }
}

QString ClearanceManager::generateHTMLReceipt(const QVariantMap &clearanceData)
{
    bool approved = clearanceData["approved"].toBool();
    QString userName = clearanceData["user_name"].toString();
    QString userNumber = clearanceData["user_number"].toString();
    QString userType = clearanceData["user_type"].toString();
    QString email = clearanceData["email"].toString();
    QString phone = clearanceData["phone"].toString();
    QString clearanceDate = clearanceData["clearance_date"].toString();
    QString status = clearanceData["status"].toString();

    QString html = R"(<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Library Clearance Receipt</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Courier New', Courier, monospace;
            background: #f0f0f0;
            padding: 30px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }

        .receipt {
            background: white;
            max-width: 420px;
            width: 100%;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            position: relative;
        }

        .receipt::before,
        .receipt::after {
            content: '';
            position: absolute;
            left: 0;
            right: 0;
            height: 15px;
            background: repeating-linear-gradient(
                90deg,
                white 0px,
                white 10px,
                transparent 10px,
                transparent 20px
            );
        }

        .receipt::before {
            top: 0;
            background: repeating-linear-gradient(
                90deg,
                transparent 0px,
                transparent 10px,
                #f0f0f0 10px,
                #f0f0f0 20px
            );
        }

        .receipt::after {
            bottom: 0;
            background: repeating-linear-gradient(
                90deg,
                transparent 0px,
                transparent 10px,
                #f0f0f0 10px,
                #f0f0f0 20px
            );
        }

        .receipt-content {
            padding: 35px 30px 35px 30px;
        }

        .header {
            text-align: center;
            padding-bottom: 20px;
            margin-bottom: 20px;
            border-bottom: 2px dashed #ddd;
        }

        .header h1 {
            font-size: 18px;
            font-weight: 700;
            color: #1a1a1a;
            margin-bottom: 5px;
            letter-spacing: 1px;
        }

        .header h2 {
            font-size: 13px;
            font-weight: 400;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 2px;
        }

        .status-section {
            text-align: center;
            margin: 20px 0;
            padding: 15px;
            background: #f9f9f9;
            border-left: 4px solid #28a745;
        }

        .status-approved {
            background: #f0f9f4;
            border-left-color: #28a745;
        }

        .status-rejected {
            background: #fef5f5;
            border-left-color: #dc3545;
        }

        .status-text {
            font-size: 16px;
            font-weight: 700;
            color: #28a745;
            letter-spacing: 2px;
        }

        .status-rejected .status-text {
            color: #dc3545;
        }

        .divider {
            border: 0;
            border-top: 1px dashed #ddd;
            margin: 20px 0;
        }

        .info-section {
            margin-bottom: 20px;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            font-size: 12px;
            line-height: 1.6;
        }

        .info-label {
            color: #666;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 10px;
            letter-spacing: 0.5px;
        }

        .info-value {
            color: #1a1a1a;
            font-weight: 500;
            text-align: right;
            max-width: 60%;
        }

        .section-header {
            font-size: 11px;
            font-weight: 700;
            color: #1a1a1a;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin: 20px 0 12px 0;
            padding-bottom: 6px;
            border-bottom: 1px solid #28a745;
        }

        .check-item {
            padding: 10px 0;
            border-bottom: 1px dotted #e0e0e0;
            display: flex;
            align-items: flex-start;
            gap: 10px;
        }

        .check-item:last-child {
            border-bottom: none;
        }

        .check-icon {
            font-size: 16px;
            line-height: 1;
            margin-top: 2px;
            flex-shrink: 0;
        }

        .icon-pass {
            color: #28a745;
        }

        .icon-fail {
            color: #dc3545;
        }

        .check-details {
            flex: 1;
        }

        .check-name {
            font-size: 11px;
            font-weight: 600;
            color: #1a1a1a;
            margin-bottom: 3px;
        }

        .check-result {
            font-size: 10px;
            color: #666;
        }

        .check-result.fail {
            color: #dc3545;
            font-weight: 600;
        }

        .issue-list {
            margin-top: 6px;
            padding-left: 12px;
        }

        .issue-item {
            font-size: 9px;
            color: #dc3545;
            padding: 2px 0;
            line-height: 1.4;
        }

        .footer {
            text-align: center;
            margin-top: 25px;
            padding-top: 20px;
            border-top: 2px dashed #ddd;
        }

        .footer-text {
            font-size: 9px;
            color: #999;
            line-height: 1.8;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .footer-date {
            font-size: 10px;
            color: #666;
            margin: 8px 0;
            font-weight: 600;
        }

        @media print {
            body {
                background: white;
                padding: 0;
            }

            .receipt {
                box-shadow: none;
                max-width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="receipt">
        <div class="receipt-content">
            <div class="header">
                <h1>LIBRARY SYSTEM</h1>
                <h2>Clearance Receipt</h2>
            </div>

            <div class="status-section )" + QString(approved ? "status-approved" : "status-rejected") + R"(">
                <div class="status-text">)" + (approved ? "✓ APPROVED" : "✗ REJECTED") + R"(</div>
            </div>

            <hr class="divider">

            <div class="info-section">
                <div class="info-row">
                    <span class="info-label">Name</span>
                    <span class="info-value">)" + userName + R"(</span>
                </div>
                <div class="info-row">
                    <span class="info-label">)" + (userType == "student" ? "Adm. No" : userType == "staff" ? "Staff No" : "User No") + R"(</span>
                    <span class="info-value">)" + userNumber + R"(</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Type</span>
                    <span class="info-value">)" + userType.left(1).toUpper() + userType.mid(1) + R"(</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Email</span>
                    <span class="info-value">)" + email + R"(</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Phone</span>
                    <span class="info-value">)" + phone + R"(</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Date</span>
                    <span class="info-value">)" + clearanceDate + R"(</span>
                </div>
            </div>

            <div class="section-header">Verification Results</div>
)";

    // Add check results
    QVariantMap borrowedBooks = clearanceData["borrowed_books"].toMap();
    QVariantMap digitalMaterials = clearanceData["digital_materials"].toMap();
    QVariantMap lostBooks = clearanceData["lost_books"].toMap();
    QVariantMap unpaidFines = clearanceData["unpaid_fines"].toMap();

    // Borrowed Books Check
    bool booksCleared = borrowedBooks["cleared"].toBool();
    int booksCount = borrowedBooks["count"].toInt();
    html += R"(
            <div class="check-item">
                <span class="check-icon )" + QString(booksCleared ? "icon-pass" : "icon-fail") + R"(">)" + (booksCleared ? "✓" : "✗") + R"(</span>
                <div class="check-details">
                    <div class="check-name">BORROWED BOOKS</div>
                    <div class="check-result )" + QString(booksCleared ? "" : "fail") + R"(">)" + (booksCleared ? "No unreturned books" : QString("Found %1 unreturned book(s)").arg(booksCount)) + R"(</div>)";

    if (!booksCleared) {
        QVariantList issues = borrowedBooks["issues"].toList();
        html += R"(
                    <div class="issue-list">)";
        for (const QVariant &issueVar : issues) {
            QVariantMap issue = issueVar.toMap();
            html += QString(R"(
                        <div class="issue-item">• %1 (Call No: %2)</div>)").arg(issue["title"].toString(), issue["call_number"].toString());
        }
        html += R"(
                    </div>)";
    }
    html += R"(
                </div>
            </div>
)";

    // Digital Materials Check
    bool materialsCleared = digitalMaterials["cleared"].toBool();
    int materialsCount = digitalMaterials["count"].toInt();
    html += R"(
            <div class="check-item">
                <span class="check-icon )" + QString(materialsCleared ? "icon-pass" : "icon-fail") + R"(">)" + (materialsCleared ? "✓" : "✗") + R"(</span>
                <div class="check-details">
                    <div class="check-name">DIGITAL MATERIALS</div>
                    <div class="check-result )" + QString(materialsCleared ? "" : "fail") + R"(">)" + (materialsCleared ? "No unreturned materials" : QString("Found %1 unreturned item(s)").arg(materialsCount)) + R"(</div>)";

    if (!materialsCleared) {
        QVariantList issues = digitalMaterials["issues"].toList();
        html += R"(
                    <div class="issue-list">)";
        for (const QVariant &issueVar : issues) {
            QVariantMap issue = issueVar.toMap();
            html += QString(R"(
                        <div class="issue-item">• %1 - Type: %2 (Qty: %3)</div>)").arg(issue["item_name"].toString(), issue["item_type"].toString()).arg(issue["quantity"].toInt());
        }
        html += R"(
                    </div>)";
    }
    html += R"(
                </div>
            </div>
)";

    // Lost Books Check
    bool lostBooksCleared = lostBooks["cleared"].toBool();
    int lostBooksCount = lostBooks["count"].toInt();
    double lostBooksTotal = lostBooks["total_owed"].toDouble();
    html += R"(
            <div class="check-item">
                <span class="check-icon )" + QString(lostBooksCleared ? "icon-pass" : "icon-fail") + R"(">)" + (lostBooksCleared ? "✓" : "✗") + R"(</span>
                <div class="check-details">
                    <div class="check-name">LOST BOOKS</div>
                    <div class="check-result )" + QString(lostBooksCleared ? "" : "fail") + R"(">)" + (lostBooksCleared ? "No unpaid charges" : QString("Found %1 unpaid charge(s) - Total: %2").arg(lostBooksCount).arg(formatCurrency(lostBooksTotal))) + R"(</div>)";

    if (!lostBooksCleared) {
        QVariantList issues = lostBooks["issues"].toList();
        html += R"(
                    <div class="issue-list">)";
        for (const QVariant &issueVar : issues) {
            QVariantMap issue = issueVar.toMap();
            html += QString(R"(
                        <div class="issue-item">• %1 - Balance: %2</div>)").arg(issue["book_title"].toString(), formatCurrency(issue["balance"].toDouble()));
        }
        html += R"(
                    </div>)";
    }
    html += R"(
                </div>
            </div>
)";

    // Unpaid Fines Check
    bool finesCleared = unpaidFines["cleared"].toBool();
    int finesCount = unpaidFines["count"].toInt();
    double finesTotal = unpaidFines["total_owed"].toDouble();
    html += R"(
            <div class="check-item">
                <span class="check-icon )" + QString(finesCleared ? "icon-pass" : "icon-fail") + R"(">)" + (finesCleared ? "✓" : "✗") + R"(</span>
                <div class="check-details">
                    <div class="check-name">OUTSTANDING FINES</div>
                    <div class="check-result )" + QString(finesCleared ? "" : "fail") + R"(">)" + (finesCleared ? "No outstanding fines" : QString("Found %1 unpaid fine(s) - Total: %2").arg(finesCount).arg(formatCurrency(finesTotal))) + R"(</div>)";

    if (!finesCleared) {
        QVariantList issues = unpaidFines["issues"].toList();
        html += R"(
                    <div class="issue-list">)";
        for (const QVariant &issueVar : issues) {
            QVariantMap issue = issueVar.toMap();
            html += QString(R"(
                        <div class="issue-item">• %1 - Balance: %2</div>)").arg(issue["book_title"].toString(), formatCurrency(issue["balance"].toDouble()));
        }
        html += R"(
                    </div>)";
    }
    html += R"(
                </div>
            </div>
)";

    html += R"(
            <div class="footer">
                <p class="footer-text">Official Clearance Document</p>
                <p class="footer-date">Generated: )" + clearanceDate + R"(</p>
                <p class="footer-text">Library Management System © 2026</p>
            </div>
        </div>
    </div>
</body>
</html>
)";

    return html;
}

bool ClearanceManager::saveHTMLReceipt(const QString &filePath, const QString &htmlContent)
{
    // Remove the file:// prefix if present
    QString cleanPath = filePath;
    if (cleanPath.startsWith("file:///")) {
        cleanPath = cleanPath.mid(8); // Remove "file:///"
    } else if (cleanPath.startsWith("file://")) {
        cleanPath = cleanPath.mid(7); // Remove "file://"
    }

    QFile file(cleanPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning() << "Failed to open file for writing:" << cleanPath;
        qWarning() << "Error:" << file.errorString();
        emit errorOccurred("Failed to save HTML receipt: " + file.errorString());
        return false;
    }

    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8); // Ensure UTF-8 encoding for special characters
    out << htmlContent;
    file.close();

    if (file.error() != QFile::NoError) {
        qWarning() << "Error writing to file:" << file.errorString();
        emit errorOccurred("Error writing HTML receipt: " + file.errorString());
        return false;
    }

    qDebug() << "HTML receipt saved successfully to:" << cleanPath;

    // Log the save action
    if (m_clearanceResult.contains("user_id") && m_clearanceResult.contains("user_name")) {
        int userId = m_clearanceResult["user_id"].toInt();
        QString userName = m_clearanceResult["user_name"].toString();
        logClearance("INFO",
                     QString("HTML receipt saved for %1").arg(userName),
                     QString("File: %1").arg(cleanPath),
                     userId);
    }

    return true;
}

void ClearanceManager::clearResult()
{
    m_clearanceResult.clear();
    m_clearanceStatus = "idle";
    emit clearanceResultChanged();
    emit clearanceStatusChanged();
}

QString ClearanceManager::formatCurrency(double amount) const
{
    return QString("KSh %1").arg(amount, 0, 'f', 2);
}

QString ClearanceManager::getCurrentDateTime() const
{
    return QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
}
