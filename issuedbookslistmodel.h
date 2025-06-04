#ifndef ISSUEDBOOKSLISTMODEL_H
#define ISSUEDBOOKSLISTMODEL_H

#include <QAbstractListModel>

class IssuedBooksList;

class IssuedBooksListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(IssuedBooksList* list READ list WRITE setList NOTIFY listChanged)

public:
    explicit IssuedBooksListModel(QObject *parent = nullptr);

    enum {
        IssueIdRole = Qt::UserRole +1,
        BookIdRole,
        UserIdRole,
        UserNameRole,
        CallNumberRole,
        BookTitleRole,
        IssueDateRole,
        DueDateRole,
        StatusRole,
        FineAmountRole,
        BookValueRole,
        IsSelectedRole
    };

    // Header:
    QVariant headerData(int section,
                        Qt::Orientation orientation,
                        int role = Qt::DisplayRole) const override;

    // Basic functionality:
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Q_INVOKABLE QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // Editable:
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

    Qt::ItemFlags flags(const QModelIndex &index) const override;


    virtual QHash<int, QByteArray> roleNames() const override;

    IssuedBooksList* list() const;
    void setList(IssuedBooksList *newList);

signals:
    void listChanged();
private:
    IssuedBooksList* mList;

};

#endif // ISSUEDBOOKSLISTMODEL_H
