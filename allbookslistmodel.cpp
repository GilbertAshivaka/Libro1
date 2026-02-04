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
    case CallNumberRole:
        return QVariant(book.callNumber);
    case PublisherRole:
        return QVariant(book.publisher);
    case IsbnRole:
        return QVariant(book.isbn);
    case BarcodeRole:
        return QVariant(book.barcode);
    case YearPublishedRole:
        return QVariant(book.yearPublished);
    case ShelfNumberRole:
        return QVariant(book.shelfNumber);
    case DescriptionRole:
        return QVariant(book.description);
    case LanguageRole:
        return QVariant(book.language);
    case SubjectRole:
        return QVariant(book.subject);
    case GenreRole:
        return QVariant(book.genre);
    case ValueRole:
        return QVariant(book.value);
    case MethodRole:
        return QVariant(book.method);
    case DateAddedRole:
        return QVariant(book.dateAdded);
    case AvailabilityRole:
        return QVariant(book.availability);
    case TimesBorrowedRole:
        return QVariant(book.timesBorrowed);
    case ConditionRole:
        return QVariant(book.condition);
    default:
        return QVariant();
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
    case CallNumberRole:
        book.callNumber = value.toString();
        break;
    case PublisherRole:
        book.publisher = value.toString();
        break;
    case IsbnRole:
        book.isbn = value.toString();
        break;
    case BarcodeRole:
        book.barcode = value.toString();
        break;
    case YearPublishedRole:
        book.yearPublished = value.toString();
        break;
    case ShelfNumberRole:
        book.shelfNumber = value.toString();
        break;
    case DescriptionRole:
        book.description = value.toString();
        break;
    case LanguageRole:
        book.language = value.toString();
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
    case DateAddedRole:
        book.dateAdded = value.toString();
        break;
    case AvailabilityRole:
        book.availability = value.toString();
        break;
    case TimesBorrowedRole:
        book.timesBorrowed = value.toInt();
        break;
    case ConditionRole:
        book.condition = value.toString();
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
    names[CallNumberRole] = "callNumber";
    names[PublisherRole] = "publisher";
    names[IsbnRole] = "isbn";
    names[BarcodeRole] = "barcode";
    names[YearPublishedRole] = "yearPublished";
    names[ShelfNumberRole] = "shelfNumber";
    names[DescriptionRole] = "description";
    names[LanguageRole] = "language";
    names[SubjectRole] = "subject";
    names[GenreRole] = "genre";
    names[ValueRole] = "value";
    names[MethodRole] = "method";
    names[DateAddedRole] = "dateAdded";
    names[AvailabilityRole] = "availability";
    names[TimesBorrowedRole] = "timesBorrowed";
    names[ConditionRole] = "condition";

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














