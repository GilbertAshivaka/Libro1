import QtQuick
import QtQuick.Controls

Item {
    id: reportsActivityContainer
    ScrollView{
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        id: activitySV
        anchors.fill: parent
        contentHeight: reportsActivity.activityFlowHeight + 50

        ReportsActivity{
            id: reportsActivity
            width: activitySV.width
            height: activityFlowHeight + 50
        }
    }
}
