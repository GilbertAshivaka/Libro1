#ifndef ISSUEBOOKSLISTMODEL_H
#define ISSUEBOOKSLISTMODEL_H

#include <QAbstractListModel>
#include "issuebookslist.h"


class IssueBooksListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(IssueBooksList* list READ list WRITE setList NOTIFY listChanged)

public:

    enum BookRoles{
        BookIDRole = Qt::UserRole +1,
        TitleRole,
        AuthorRole,
        CallNumberRole,
        BarcodeRole,
        ShelfNumberRole
    };
    Q_ENUM(BookRoles)

    explicit IssueBooksListModel(QObject *parent = nullptr);

    // Header:
    QVariant headerData(int section,
                        Qt::Orientation orientation,
                        int role = Qt::DisplayRole) const override;

    // Basic functionality:
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    Q_INVOKABLE QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    Q_INVOKABLE QVariant get(int row) const;

    QHash<int, QByteArray> roleNames() const override;

    IssueBooksList* list() const {return m_list;}

    void setList(IssueBooksList* lst);

signals:
    void listChanged();
private:
    IssueBooksList* m_list;
};

#endif // ISSUEBOOKSLISTMODEL_H
















