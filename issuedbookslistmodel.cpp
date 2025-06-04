#include "issuedbookslistmodel.h"
#include "issuedbookslist.h"

IssuedBooksListModel::IssuedBooksListModel(QObject *parent)
    : QAbstractListModel(parent), mList(nullptr)
{}

QVariant IssuedBooksListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    // FIXME: Implement me!
    return QVariant();
}


int IssuedBooksListModel::rowCount(const QModelIndex &parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (parent.isValid() || !mList)
        return 0;

    return mList->getIssuedBooks().size();

}


QVariant IssuedBooksListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || !mList)
        return QVariant();

    const IssuedBookInfo book = mList->getIssuedBooks().at(index.row());

    switch(role){
    case IssueIdRole:
        return QVariant(book.issueId);
    case BookIdRole:
        return QVariant(book.bookId);
    case UserIdRole:
        return QVariant(book.userId);
    case UserNameRole:
        return QVariant(book.userName);
    case CallNumberRole:
        return QVariant(book.callnumber);
    case BookTitleRole:
        return QVariant(book.bookTitle);
    case IssueDateRole:
        return QVariant(book.issueDate.toString("dd/MM/yyyy"));
    case DueDateRole:
        return QVariant(book.dueDate.toString("dd/MM/yyyy"));
    case StatusRole:
        return QVariant(book.status);
    case FineAmountRole:
        return QVariant(book.fineAmount);
    case BookValueRole:
        return QVariant(book.bookValue);
    case IsSelectedRole:
        return QVariant(book.isSelected);
    default:
        return QStringLiteral("Not specified");
    }

    return QVariant();
}

bool IssuedBooksListModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(!mList)
        return false;

    if (role == IsSelectedRole) {
        mList->toggleBookSelection(index.row());
        emit dataChanged(index, index, {role});
        return true;
    }
    return false;
}

Qt::ItemFlags IssuedBooksListModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return QAbstractItemModel::flags(index) | Qt::ItemIsEditable; // FIXME: Implement me!
}


QHash<int, QByteArray> IssuedBooksListModel::roleNames() const
{
    QHash<int, QByteArray> names;

    names[IssueIdRole] = "issueId";
    names[BookIdRole] = "bookId";
    names[UserIdRole] = "userId";
    names[UserNameRole] = "name";
    names[CallNumberRole] = "bookNumber";
    names[BookTitleRole] = "bookTitle";
    names[IssueDateRole] = "issueDate";
    names[DueDateRole] = "dueDate";
    names[StatusRole] = "status";
    names[FineAmountRole] = "fineAmount";
    names[BookValueRole] = "bookValue";
    names[IsSelectedRole] = "isSelected";

    return names;
}

IssuedBooksList *IssuedBooksListModel::list() const
{
    return mList;
}

void IssuedBooksListModel::setList(IssuedBooksList *newList)
{
    beginResetModel();

    if (mList)
        mList->disconnect(this);

    mList = newList;

    if (mList){
        connect(mList, &IssuedBooksList::preModelReset, this, &IssuedBooksListModel::beginResetModel);
        connect(mList, &IssuedBooksList::postModelReset, this, &IssuedBooksListModel::endResetModel);

        connect(mList, &IssuedBooksList::preBookAppended, this, [=](){
            const int index = mList->getIssuedBooks().size();
            beginInsertRows(QModelIndex(), index, index);
        });

        connect(mList, &IssuedBooksList::postBookAppended, this, [=](){
            endInsertRows();
        });

        connect(mList, &IssuedBooksList::preBookRemoved, this, [=](int index){
            beginRemoveRows(QModelIndex(), index, index);
        });

        connect(mList, &IssuedBooksList::postBookRemoved, this, [=](){
            endRemoveRows();
        });

        connect(mList, &IssuedBooksList::booksUpdated, this, [=](){
            emit dataChanged(index(0), index(rowCount()-1));
        });
    }

    endResetModel();
}

























