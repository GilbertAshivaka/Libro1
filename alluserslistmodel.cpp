#include "alluserslistmodel.h"
#include "alluserslist.h"

AllUsersListModel::AllUsersListModel(QObject *parent)
    : QAbstractListModel(parent)
    , mList(nullptr)
{
}

int AllUsersListModel::rowCount(const QModelIndex &parent) const
{
    // For list models only the root node (an invalid parent) should return the list's size. For all
    // other (valid) parents, rowCount() should return 0 so that it does not become a tree model.
    if (parent.isValid() || !mList)
        return 0;

    return mList->getUsers().size();
}

QVariant AllUsersListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || !mList)
        return QVariant();

    const User user = mList->getUsers().at(index.row());
    switch(role){
    case UserIdRole:
        return QVariant(user.userId);
    case FirstNameRole:
        return QVariant(user.firstName);
    case LastNameRole:
        return QVariant(user.lastName);
    case EmailRole:
        return QVariant(user.email);
    case PhoneRole:
        return QVariant(user.phone);
    case UserTypeRole:
        return QVariant(user.userRole);
    case StatusRole:
        return QVariant(user.status);
    case CreatedAtRole:
        return QVariant(user.createdAt);
    case UpdatedAtRole:
        return QVariant(user.updatedAt);
    case AdmRole:
        return QVariant(user.admNo);
    case BranchRole:
        return QVariant(user.branch);
    case EnrollmentYearRole:
        return QVariant(user.enrollmentYear);
    case LevelRole:
        return QVariant(user.level);
    case StaffNoRole:
        return QVariant(user.staffNo);
    case DepartmentRole:
        return QVariant(user.department);
    case StartYearRole:
        return QVariant(user.startYear);
    case CategoryRole:
        return QVariant(user.category);
    case UserNoRole:
        return QVariant(user.userNo);
    case ResidenceRole:
        return QVariant(user.residence);
    case AgeRole:
        return QVariant(user.age);
    case GenderRole:
        return QVariant(user.gender);
    default:
        return QVariant(QString("No info specified."));
    }

    return QVariant();
}

bool AllUsersListModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(!mList)
        return false;

    User user = mList->getUsers().at(index.row());

    switch(role){
    case FirstNameRole:
        user.firstName = value.toString();
        break;
    case LastNameRole:
        user.lastName = value.toString();
        break;
    case EmailRole:
        user.email = value.toString();
        break;
    case PhoneRole:
        user.phone = value.toString();
        break;
    case UserTypeRole:
        user.userRole = value.toString();
        break;
    case StatusRole:
        user.status = value.toString();
        break;
    case CreatedAtRole:
        user.createdAt = value.toDateTime();
        break;
    case UpdatedAtRole:
        user.updatedAt = value.toDateTime();
        break;
    case AdmRole:
        user.admNo = value.toString();
        break;
    case BranchRole:
        user.branch = value.toString();
        break;
    case EnrollmentYearRole:
        user.enrollmentYear = value.toInt();
        break;
    case LevelRole:
        user.level = value.toString();
        break;
    case StaffNoRole:
        user.staffNo = value.toString();
        break;
    case DepartmentRole:
        user.department = value.toString();
        break;
    case StartYearRole:
        user.startYear = value.toInt();
        break;
    case CategoryRole:
        user.category = value.toString();
        break;
    case UserNoRole:
        user.userNo = value.toString();
        break;
    case ResidenceRole:
        user.residence = value.toString();
        break;
    case AgeRole:
        user.age = value.toInt();
        break;
    case GenderRole:
        user.gender = value.toString();
    }

    if (data(index, role) != value) {
        emit dataChanged(index, index, {role});
        return true;
    }
    return false;
}

Qt::ItemFlags AllUsersListModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;

    return QAbstractItemModel::flags(index) | Qt::ItemIsEditable; // FIXME: Implement me!
}

QHash<int, QByteArray> AllUsersListModel::roleNames() const
{
    QHash<int, QByteArray> names;
    names[UserIdRole] = "userId";
    names[FirstNameRole] = "firstName";
    names[LastNameRole] = "lastName";
    names[EmailRole] = "email";
    names[PhoneRole] = "phoneNo";
    names[UserTypeRole] = "userRole";
    names[StatusRole] = "status";
    names[CreatedAtRole] = "createdAt";
    names[UpdatedAtRole] = "updatedAt";
    names[AdmRole] = "admNo";
    names[BranchRole] = "branch";
    names[EnrollmentYearRole] = "enrollmentYear";
    names[LevelRole] = "level";
    names[StaffNoRole] = "staffNo";
    names[DepartmentRole] = "department";
    names[StartYearRole] = "startYear";
    names[CategoryRole] = "category";
    names[UserNoRole] = "userNO";
    names[ResidenceRole] = "residence";
    names[AgeRole] = "age";
    names[GenderRole] = "gender";

    return names;
}



AllUsersList *AllUsersListModel::list() const
{
    return mList;
}

void AllUsersListModel::setList(AllUsersList *newList)
{
    beginResetModel();

    if (mList)
        mList->disconnect(this);

    mList = newList;

    if(mList){
        connect(mList, &AllUsersList::preModelReset, this, &AllUsersListModel::beginResetModel);
        connect(mList, &AllUsersList::postModelReset, this, &AllUsersListModel::endResetModel);

        connect(mList, &AllUsersList::preUserAppended, this, [=](){
            int index = mList->getUsers().size();
            beginInsertRows(QModelIndex(), index, index);
        });

        connect(mList, &AllUsersList::postUserAppended, this, [=](){
            endInsertRows();
        });

        connect(mList, &AllUsersList::preUserRemoved, this, [=](int index){
            beginRemoveRows(QModelIndex(), index, index);
        });

        connect(mList, &AllUsersList::postUserRemoved, this, [=](){
            endRemoveRows();
        });

        connect(mList, &AllUsersList::usersUpdated, this, [=]() {
            emit dataChanged(index(0), index(rowCount() - 1));
        });
    }

    endResetModel(); // to match beginResetModel();
}












