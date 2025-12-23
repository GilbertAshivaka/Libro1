import QtQuick
import QtCharts
import "../DynamicComponentLoader.js" as CustomComponentLoader

// Genre Distribution Chart (copied from CollectionReports)
Item {
    id: genreChartContainer
    width: 600
    height: 400
    property var reportsPage: null

    MouseArea{
        id: genreChartMA
        anchors.fill: parent
        z: 3
        cursorShape: "PointingHandCursor"
        onClicked: function() {
            CustomComponentLoader.customCreateComponent(reportsPage,"ReportsPage", mainContainer)
        }
    }

    ChartView {
        id: genreChart
        anchors.fill: parent
        title: "Top 5 Genre Distribution"
        antialiasing: true
        legend.alignment: Qt.AlignRight
        backgroundColor: "transparent"

        PieSeries {
            id: genreSeries
        }
    }

    Component.onCompleted: {
        loadGenreDistribution()
    }

    function loadGenreDistribution() {
        genreSeries.clear()

        var data = reportsManager.getBooksByGenreDistribution("all")

        for (var i = 0; i < 5; i++) { // show only the top 5 genres
            var slice = genreSeries.append(data[i].label, data[i].value)
            slice.labelVisible = data[i].percentage > 5 // Show label if > 5%
        }
    }
}




















