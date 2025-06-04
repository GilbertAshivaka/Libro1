#include "issuebookslistmodel.h"
#include <QDebug>

IssueBooksListModel::IssueBooksListModel(QObject *parent)
    : QAbstractListModel(parent),
    m_list{nullptr}
{}

QVariant IssueBooksListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    // FIXME: Implement me!
    return QVariant();
}

int IssueBooksListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid() || !m_list) return 0;
    return m_list->getBooks().size();

    // FIXME: Implement me!
}

QVariant IssueBooksListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || !m_list) return {};

    const auto &b = m_list->getBooks().at(index.row());

    //wrap all the attributes in QVariant
    switch(role){
    case BookIDRole:
        return QVariant(b.bookID);
    case TitleRole:
        return QVariant(b.title);
    case AuthorRole:
        return QVariant(b.author);
    case CallNumberRole:
        return QVariant(b.callNumber);
    case BarcodeRole:
        return QVariant(b.barcode);
    case ShelfNumberRole:
        return QVariant(b.shelfNumber);
    default:
        return {};
    }

    // FIXME: Implement me!
    return QVariant();
}

/*for returning a book when the barcode reads a barcode
Called with the argument 0 because barcode only matches one item*/
QVariant IssueBooksListModel::get(int row) const
{
    QVariantMap map;

    if(!m_list || row < 0 || row >= m_list->getBooks().size()) return map;

    const auto &b = m_list->getBooks().at(row);
    map["bookID"] = b.bookID;
    map["title"] = b.title;
    map["author"] = b.author;
    map["callNumber"] = b.callNumber;
    map["barcode"] = b.barcode;
    map["shelfNumber"] = b.shelfNumber;
    return map;
}

QHash<int, QByteArray> IssueBooksListModel::roleNames() const
{
    QHash<int, QByteArray> names;
    names[BookIDRole] = "bookID";
    names[TitleRole] = "title";
    names[AuthorRole] = "author";
    names[CallNumberRole] = "callNumber";
    names[BarcodeRole] = "barcode";
    names[ShelfNumberRole] = "shelfNumber";

    return names;

}

void IssueBooksListModel::setList(IssueBooksList *lst)
{
    beginResetModel();
    if (m_list) m_list->disconnect(this);
    m_list = lst;

    if (m_list){
        connect(m_list, &IssueBooksList::preModelReset, this, &IssueBooksListModel::beginResetModel);
        connect(m_list, &IssueBooksList::postModelReset, this, &IssueBooksListModel::endResetModel);

        connect(m_list, &IssueBooksList::preBookAppended, this, [=](){
            const int index = m_list->getBooks().size();
            beginInsertRows(QModelIndex(), index, index);
        });

        connect(m_list, &IssueBooksList::postBookAppended, this, [=](){
            endInsertRows();
        });

        connect(m_list, &IssueBooksList::booksUpdated, this, [=](){
            emit dataChanged(index(0), index(rowCount() - 1));
        });

        endResetModel();
        emit listChanged();
    }
}







