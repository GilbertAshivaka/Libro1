import QtQuick
import QtQuick.Controls

Item {
    id: reportsOverviewContainer
    ScrollView{
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        id: overviewSV
        anchors.fill: parent
        contentHeight: reportsOverview.overviewFlowHeight + 50

        ReportsOverview{
            id: reportsOverview
            width: overviewSV.width
            height: overviewFlowHeight + 50
        }
    }
}
