#ifndef SUGGESTIONSMANAGER_H
#define SUGGESTIONSMANAGER_H

#include <QObject>
#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>
#include <QTimer>
#include "databasemanager.h"

// Model for suggestions list
class SuggestionsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum SuggestionRoles {
        IdRole = Qt::UserRole + 1,
        UserIdRole,
        UserNameRole,
        UserNumberRole,
        UserRoleRole,
        ContentRole,
        TypeRole,
        IsAnonymousRole,
        StatusRole,
        CreatedAtRole,
        PreviewRole  // First few words of content
    };

    explicit SuggestionsModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setSuggestions(const QList<QVariantMap> &suggestions);
    void clear();

    Q_INVOKABLE QVariantMap get(int index) const;

private:
    QList<QVariantMap> m_suggestions;
    QString truncateContent(const QString &content, int maxLength = 80) const;
};


// Main manager class
class SuggestionsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(SuggestionsModel* model READ model CONSTANT)

public:
    explicit SuggestionsManager(QObject *parent = nullptr);
    ~SuggestionsManager();

    SuggestionsModel* model() const;

    // Submit suggestion/feedback (for users)
    Q_INVOKABLE bool submitSuggestion(int userId, const QString &userName,
                                      const QString &userNumber, const QString &userRole,
                                      const QString &content, const QString &type,
                                      bool isAnonymous);

    // Fetch all suggestions with optional filters (for admin)
    Q_INVOKABLE void fetchAllSuggestions(const QString &filterType = "all",
                                         const QString &filterStatus = "all");

    // Get single suggestion by ID (for detail popup)
    Q_INVOKABLE QVariantMap getSuggestionById(int id);

    // Update suggestion status (for admin)
    Q_INVOKABLE bool updateStatus(int id, const QString &newStatus);

    // Delete suggestion (for admin)
    Q_INVOKABLE bool deleteSuggestion(int id);

    // Get random active suggestion for corner widget (not addressed, not deleted)
    Q_INVOKABLE QVariantMap getRandomActiveSuggestion();

    // Get count of active suggestions
    Q_INVOKABLE int getActiveSuggestionsCount();

    // Get total suggestions count (for admin stats)
    Q_INVOKABLE int getTotalCount(const QString &filterType = "all",
                                  const QString &filterStatus = "all");

signals:
    void submitSuccess(const QString &message);
    void submitError(const QString &errorMessage);
    void operationSuccess(const QString &message);
    void operationError(const QString &errorMessage);
    void suggestionsLoaded();

private:
    QSqlDatabase db;
    SuggestionsModel *m_model;

    QString formatDateTime(const QString &isoDateTime) const;
};

#endif // SUGGESTIONSMANAGER_H
