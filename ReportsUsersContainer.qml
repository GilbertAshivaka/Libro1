import QtQuick
import QtQuick.Controls

Item {
    id: reportsUsersContainer
    ScrollView{
        id: usersSV
        anchors.fill: parent
        contentHeight: reportsUsers.usersFlowHeight + 50

        ReportsUsers{
            id: reportsUsers
            width: usersSV.width
            height: usersFlowHeight + 50
        }
    }
}

