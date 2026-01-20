#include "suggestionsmanager.h"
#include <QRandomGenerator>

// ============== SuggestionsModel Implementation ==============

SuggestionsModel::SuggestionsModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SuggestionsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_suggestions.count();
}

QVariant SuggestionsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_suggestions.count())
        return QVariant();

    const QVariantMap &suggestion = m_suggestions.at(index.row());

    switch (role) {
    case IdRole:
        return suggestion.value("id");
    case UserIdRole:
        return suggestion.value("user_id");
    case UserNameRole:
        return suggestion.value("is_anonymous").toBool() ? "Anonymous" : suggestion.value("user_name");
    case UserNumberRole:
        return suggestion.value("is_anonymous").toBool() ? "" : suggestion.value("user_number");
    case UserRoleRole:
        return suggestion.value("is_anonymous").toBool() ? "" : suggestion.value("user_role");
    case ContentRole:
        return suggestion.value("content");
    case TypeRole:
        return suggestion.value("type");
    case IsAnonymousRole:
        return suggestion.value("is_anonymous");
    case StatusRole:
        return suggestion.value("status");
    case CreatedAtRole:
        return suggestion.value("created_at");
    case PreviewRole:
        return truncateContent(suggestion.value("content").toString());
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> SuggestionsModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "suggestionId";
    roles[UserIdRole] = "userId";
    roles[UserNameRole] = "userName";
    roles[UserNumberRole] = "userNumber";
    roles[UserRoleRole] = "userRole";
    roles[ContentRole] = "content";
    roles[TypeRole] = "type";
    roles[IsAnonymousRole] = "isAnonymous";
    roles[StatusRole] = "status";
    roles[CreatedAtRole] = "createdAt";
    roles[PreviewRole] = "preview";
    return roles;
}

void SuggestionsModel::setSuggestions(const QList<QVariantMap> &suggestions)
{
    beginResetModel();
    m_suggestions = suggestions;
    endResetModel();
}

void SuggestionsModel::clear()
{
    beginResetModel();
    m_suggestions.clear();
    endResetModel();
}

QVariantMap SuggestionsModel::get(int index) const
{
    if (index < 0 || index >= m_suggestions.count())
        return QVariantMap();

    QVariantMap result = m_suggestions.at(index);
    // Handle anonymous display
    if (result.value("is_anonymous").toBool()) {
        result["user_name"] = "Anonymous";
        result["user_number"] = "";
        result["user_role"] = "";
    }
    return result;
}

QString SuggestionsModel::truncateContent(const QString &content, int maxLength) const
{
    if (content.length() <= maxLength)
        return content;
    return content.left(maxLength).trimmed() + "...";
}


// ============== SuggestionsManager Implementation ==============

SuggestionsManager::SuggestionsManager(QObject *parent)
    : QObject(parent)
{
    db = DatabaseManager::getConnection();
    m_model = new SuggestionsModel(this);
}

SuggestionsManager::~SuggestionsManager()
{
}

SuggestionsModel* SuggestionsManager::model() const
{
    return m_model;
}

bool SuggestionsManager::submitSuggestion(int userId, const QString &userName,
                                          const QString &userNumber, const QString &userRole,
                                          const QString &content, const QString &type,
                                          bool isAnonymous)
{
    if (content.trimmed().isEmpty()) {
        emit submitError("Please enter your " + type + " before submitting.");
        return false;
    }

    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO suggestions_feedback "
        "(user_id, user_name, user_number, user_role, content, type, is_anonymous, status, created_at, updated_at) "
        "VALUES (:user_id, :user_name, :user_number, :user_role, :content, :type, :is_anonymous, 'pending', :created_at, :updated_at)"
        );

    QString currentTime = QDateTime::currentDateTime().toString(Qt::ISODate);

    query.bindValue(":user_id", userId > 0 ? userId : QVariant(QVariant::Int));
    query.bindValue(":user_name", userName);
    query.bindValue(":user_number", userNumber);
    query.bindValue(":user_role", userRole);
    query.bindValue(":content", content.trimmed());
    query.bindValue(":type", type);
    query.bindValue(":is_anonymous", isAnonymous ? 1 : 0);
    query.bindValue(":created_at", currentTime);
    query.bindValue(":updated_at", currentTime);

    if (!query.exec()) {
        qWarning() << "Failed to submit" << type << ":" << query.lastError().text();
        emit submitError("Failed to submit your " + type + ". Please try again.");
        return false;
    }

    QString successMsg = type.at(0).toUpper() + type.mid(1) + " submitted successfully. Thank you for your input!";
    emit submitSuccess(successMsg);

    qDebug() << type << "submitted successfully";
    return true;
}

void SuggestionsManager::fetchAllSuggestions(const QString &filterType, const QString &filterStatus)
{
    QSqlQuery query(db);

    QString sql = "SELECT * FROM suggestions_feedback WHERE 1=1";

    if (filterType != "all") {
        sql += " AND type = :type";
    }
    if (filterStatus != "all") {
        sql += " AND status = :status";
    }

    sql += " ORDER BY created_at DESC";

    query.prepare(sql);

    if (filterType != "all") {
        query.bindValue(":type", filterType);
    }
    if (filterStatus != "all") {
        query.bindValue(":status", filterStatus);
    }

    QList<QVariantMap> suggestions;

    if (query.exec()) {
        while (query.next()) {
            QVariantMap suggestion;
            suggestion["id"] = query.value("id");
            suggestion["user_id"] = query.value("user_id");
            suggestion["user_name"] = query.value("user_name");
            suggestion["user_number"] = query.value("user_number");
            suggestion["user_role"] = query.value("user_role");
            suggestion["content"] = query.value("content");
            suggestion["type"] = query.value("type");
            suggestion["is_anonymous"] = query.value("is_anonymous").toBool();
            suggestion["status"] = query.value("status");
            suggestion["created_at"] = formatDateTime(query.value("created_at").toString());
            suggestions.append(suggestion);
        }
    } else {
        qWarning() << "Failed to fetch suggestions:" << query.lastError().text();
        emit operationError("Failed to load suggestions.");
    }

    m_model->setSuggestions(suggestions);
    emit suggestionsLoaded();
}

QVariantMap SuggestionsManager::getSuggestionById(int id)
{
    QVariantMap suggestion;

    QSqlQuery query(db);
    query.prepare("SELECT * FROM suggestions_feedback WHERE id = :id");
    query.bindValue(":id", id);

    if (query.exec() && query.next()) {
        suggestion["id"] = query.value("id");
        suggestion["user_id"] = query.value("user_id");
        suggestion["user_name"] = query.value("is_anonymous").toBool() ? "Anonymous" : query.value("user_name");
        suggestion["user_number"] = query.value("is_anonymous").toBool() ? "" : query.value("user_number");
        suggestion["user_role"] = query.value("is_anonymous").toBool() ? "" : query.value("user_role");
        suggestion["content"] = query.value("content");
        suggestion["type"] = query.value("type");
        suggestion["is_anonymous"] = query.value("is_anonymous").toBool();
        suggestion["status"] = query.value("status");
        suggestion["created_at"] = formatDateTime(query.value("created_at").toString());
    } else {
        qWarning() << "Failed to get suggestion by ID:" << query.lastError().text();
    }

    return suggestion;
}

bool SuggestionsManager::updateStatus(int id, const QString &newStatus)
{
    QSqlQuery query(db);
    query.prepare(
        "UPDATE suggestions_feedback SET status = :status, updated_at = :updated_at WHERE id = :id"
        );
    query.bindValue(":status", newStatus);
    query.bindValue(":updated_at", QDateTime::currentDateTime().toString(Qt::ISODate));
    query.bindValue(":id", id);

    if (!query.exec()) {
        qWarning() << "Failed to update status:" << query.lastError().text();
        emit operationError("Failed to update status.");
        return false;
    }

    emit operationSuccess("Status updated to '" + newStatus + "'.");
    return true;
}

bool SuggestionsManager::deleteSuggestion(int id)
{
    QSqlQuery query(db);
    query.prepare("DELETE FROM suggestions_feedback WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        qWarning() << "Failed to delete suggestion:" << query.lastError().text();
        emit operationError("Failed to delete item.");
        return false;
    }

    emit operationSuccess("Item deleted successfully.");
    return true;
}

QVariantMap SuggestionsManager::getRandomActiveSuggestion()
{
    QVariantMap suggestion;

    // Get all active suggestions (pending or reviewed, not addressed)
    QSqlQuery query(db);
    query.prepare(
        "SELECT * FROM suggestions_feedback "
        "WHERE status != 'addressed' "
        "ORDER BY RANDOM() LIMIT 1"
        );

    if (query.exec() && query.next()) {
        suggestion["id"] = query.value("id");
        suggestion["user_name"] = query.value("is_anonymous").toBool() ? "Anonymous" : query.value("user_name");
        suggestion["content"] = query.value("content");
        suggestion["type"] = query.value("type");
        suggestion["created_at"] = formatDateTime(query.value("created_at").toString());
    }

    return suggestion;
}

int SuggestionsManager::getActiveSuggestionsCount()
{
    QSqlQuery query(db);
    query.prepare("SELECT COUNT(*) FROM suggestions_feedback WHERE status != 'addressed'");

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

int SuggestionsManager::getTotalCount(const QString &filterType, const QString &filterStatus)
{
    QSqlQuery query(db);

    QString sql = "SELECT COUNT(*) FROM suggestions_feedback WHERE 1=1";

    if (filterType != "all") {
        sql += " AND type = :type";
    }
    if (filterStatus != "all") {
        sql += " AND status = :status";
    }

    query.prepare(sql);

    if (filterType != "all") {
        query.bindValue(":type", filterType);
    }
    if (filterStatus != "all") {
        query.bindValue(":status", filterStatus);
    }

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

QString SuggestionsManager::formatDateTime(const QString &isoDateTime) const
{
    QDateTime dt = QDateTime::fromString(isoDateTime, Qt::ISODate);
    if (dt.isValid()) {
        return dt.toString("dd MMM yyyy, hh:mm");
    }
    return isoDateTime;
}
