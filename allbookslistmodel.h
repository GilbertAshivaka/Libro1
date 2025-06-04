#ifndef ALLBOOKSLISTMODEL_H
#define ALLBOOKSLISTMODEL_H

#include <QAbstractListModel>

class AllBooksList;

class AllBooksListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(AllBooksList *list READ list WRITE setList)

public:
    explicit AllBooksListModel(QObject *parent = nullptr);

    enum{
        TitleRole = Qt::UserRole,
        AuthorRole,
        BookNumberRole,
        PublisherRole,
        EditionRole,
        VolumeRole,
        ShelfNumberRole,
        DescriptionRole,
        SubjectRole,
        GenreRole,
        ValueRole,
        MethodRole
    };

    // Basic functionality:
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // Editable:
    bool setData(const QModelIndex &index, const QVariant &value,
                 int role = Qt::EditRole) override;

    Qt::ItemFlags flags(const QModelIndex& index) const override;

    QHash<int, QByteArray> roleNames() const override;

    AllBooksList *list() const;
    void setList(AllBooksList *newList);

private:
    AllBooksList *mList;
};

#endif // ALLBOOKSLISTMODEL_H
