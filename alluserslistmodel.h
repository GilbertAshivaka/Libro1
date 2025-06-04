#ifndef ALLUSERSLISTMODEL_H
#define ALLUSERSLISTMODEL_H

#include <QAbstractListModel>
class AllUsersList;

class AllUsersListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(AllUsersList *userList READ list WRITE setList)

public:
    explicit AllUsersListModel(QObject *parent = nullptr);

    enum{
        FirstNameRole = Qt::UserRole,
        LastNameRole,
        EmailRole,PhoneRole,
        UserTypeRole, StatusRole,
        CreatedAtRole, UpdatedAtRole,
        AdmRole, BranchRole, EnrollmentYearRole,
        LevelRole, StaffNoRole, DepartmentRole,
        StartYearRole, CategoryRole, UserNoRole,
        ResidenceRole, AgeRole, GenderRole
    };

    // Basic functionality:
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // Editable:
    bool setData(const QModelIndex &index, const QVariant &value,
                 int role = Qt::EditRole) override;

    Qt::ItemFlags flags(const QModelIndex& index) const override;

    QHash<int, QByteArray> roleNames() const override;

    AllUsersList *list() const;
    void setList(AllUsersList *newList);

private:
    AllUsersList *mList;
};

#endif // ALLUSERSLISTMODEL_H
