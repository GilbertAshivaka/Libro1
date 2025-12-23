import QtQuick
import QtCharts
import "../DynamicComponentLoader.js" as CustomComponentLoader

// Most Reserved Books Chart (copied from ReservationReports)
Item {
    id: mostReservedContainer
    width: 600
    height: 500

    property var reportsPage: null

    MouseArea{
        id: mostReserverdChartMA
        anchors.fill: parent
        z: 3
        cursorShape: "PointingHandCursor"
        onClicked: function() {
            CustomComponentLoader.customCreateComponent(reportsPage,"ReportsPage", mainContainer)
        }
    }

    ChartView {
        id: mostReservedChart
        anchors.fill: parent
        title: "Most Reserved Books"
        antialiasing: true
        legend.visible: false
        backgroundColor: "transparent"

        HorizontalBarSeries {
            id: mostReservedSeries
            axisY: BarCategoryAxis { id: bookAxis }
            axisX: ValuesAxis {
                id: mostReservedAxis
                titleText: "Reservation Count"
                min: 0
                max: 100
            }

            BarSet {
                id: reservedBarSet
                label: "Reservations"
                color: "#00BCD4"
            }
        }
    }

    Component.onCompleted: {
        loadMostReservedBooks()
    }

    function loadMostReservedBooks() {
        reservedBarSet.remove(0, reservedBarSet.count)

        var data = reportsManager.getMostReservedBooks(4)
        var categories = []
        var maxValue = 0

        for (var i = data.length - 1; i >= 0; i--) {
            var title = data[i].label
            if (title.length > 30) {
                title = title.substring(0, 27) + "..."
            }
            categories.push(title)
            reservedBarSet.append(data[i].value)

            if(data[i].value > maxValue){
                maxValue = data[i].value
            }
        }

        bookAxis.categories = categories

        // Set the Y-axis max to slightly above the max value (e.g., 10% padding)
        mostReservedAxis.max = Math.ceil(maxValue * 1.1)
    }
}





