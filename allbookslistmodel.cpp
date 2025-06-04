#include "allbookslistmodel.h"
#include "allbookslist.h"

AllBooksListModel::AllBooksListModel(QObject *parent)
    : QAbstractListModel(parent)
    , mList(nullptr)
{
}

int AllBooksListModel::rowCount(const QModelIndex &parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (parent.isValid() || !mList)
        return 0;


    return mList->getBooks().size();
}

QVariant AllBooksListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || !mList)
        return QVariant();

    const Book book = mList->getBooks().at(index.row());

    switch(role){
    case TitleRole:
        return QVariant(book.title);
    case AuthorRole:
        return QVariant(book.author);
    case BookNumberRole:
        return QVariant(book.callNumber);
    case PublisherRole:
        return QVariant(book.publisher);
    case EditionRole:
        return QVariant(book.isbn);
    case VolumeRole:
        return QVariant(book.barcode);
    case ShelfNumberRole:
        return QVariant(book.shelfNumber);
    case DescriptionRole:
        return QVariant(book.description);
    case SubjectRole:
        return QVariant(book.subject);
    case GenreRole:
        return QVariant(book.genre);
    case ValueRole:
        return QVariant(book.value);
    case MethodRole:
        return QVariant(book.method);
    default:
        return QStringLiteral("Not specified");
    }

    return QVariant();
}

bool AllBooksListModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(!mList)
        return false;

    Book book = mList->getBooks().at(index.row());

    switch(role){
    case TitleRole:
        book.title = value.toString();
        break;
    case AuthorRole:
        book.author = value.toString();
        break;
    case BookNumberRole:
        book.callNumber = value.toString();
        break;
    case PublisherRole:
        book.publisher = value.toString();
        break;
    case EditionRole:
        book.isbn = value.toString();
        break;
    case VolumeRole:
        book.barcode = value.toString();
        break;
    case ShelfNumberRole:
        book.shelfNumber = value.toString();
        break;
    case DescriptionRole:
        book.description = value.toString();
        break;
    case SubjectRole:
        book.subject = value.toString();
        break;
    case GenreRole:
        book.genre = value.toString();
        break;
    case ValueRole:
        book.value = value.toInt();
        break;
    case MethodRole:
        book.method = value.toString();
        break;
    }

    if (data(index, role) != value) {
        // some functionality should be added for enabling editing book data from the list if needed
        emit dataChanged(index, index, {role});
        return true;
    }
    return false;
}

Qt::ItemFlags AllBooksListModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return QAbstractItemModel::flags(index) | Qt::ItemIsEditable; //flag to be looked at later
}

QHash<int, QByteArray> AllBooksListModel::roleNames() const
{
    QHash<int, QByteArray> names;
    names[TitleRole] = "title";
    names[AuthorRole] = "author";
    names[BookNumberRole] = "bookNumber";
    names[PublisherRole] = "publisher";
    names[EditionRole] = "edition";
    names[VolumeRole] = "volume";
    names[ShelfNumberRole] = "shelfNumber";
    names[DescriptionRole]= "description";
    names[SubjectRole]= "subject";
    names[GenreRole] = "genre";
    names[ValueRole] = "value";
    names[MethodRole] = "method";

    return names;
}

AllBooksList *AllBooksListModel::list() const
{
    return mList;
}

void AllBooksListModel::setList(AllBooksList *newList)
{
    beginResetModel();

    if (mList)
        mList->disconnect(this);

    mList = newList;

    if (mList) {
        // model reset signals
        connect(mList, &AllBooksList::preModelReset, this, &AllBooksListModel::beginResetModel);
        connect(mList, &AllBooksList::postModelReset, this, &AllBooksListModel::endResetModel);

        connect(mList, &AllBooksList::preBookAppended, this, [=]() {
            const int index = mList->getBooks().size();
            beginInsertRows(QModelIndex(), index, index);
        });
        connect(mList, &AllBooksList::postBookAppended, this, [=]() {
            endInsertRows();
        });
        connect(mList, &AllBooksList::preBookRemoved, this, [=](int index) {
            beginRemoveRows(QModelIndex(), index, index);
        });
        connect(mList, &AllBooksList::postBookRemoved, this, [=]() {
            endRemoveRows();
        });

        // data update signal
        connect(mList, &AllBooksList::booksUpdated, this, [=]() {
            emit dataChanged(index(0), index(rowCount() - 1));
        });
    }

    endResetModel();
}














