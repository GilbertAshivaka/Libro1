import QtQuick
import QtQuick.Controls

Item {
    id: reportsOverviewContainer
    ScrollView{
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
