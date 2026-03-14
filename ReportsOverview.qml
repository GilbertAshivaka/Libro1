import QtQuick
import QtQuick.Controls
import QtCharts
import "Reports"


Item {
    id: reportsOverview
    anchors.fill: parent
    property double calCulatedHeight: 0
    property double overviewFlowHeight: overviewFlowItem.calculateFlowHeight()

    Flow{
        id: overviewFlowItem
        anchors.fill: parent
        spacing: 20

        function calculateFlowHeight() {
            let currentWidth = 0;
            let rowHeight = 0;
            let totalHeight = 0;
            let spacing = overviewFlowItem.spacing;

            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (!item.visible) continue;

                if (currentWidth + item.width > overviewFlowItem.width) {
                    totalHeight += rowHeight + spacing;
                    currentWidth = 0;
                    rowHeight = 0;
                }

                currentWidth += item.width + spacing;
                rowHeight = Math.max(rowHeight, item.height);
            }

            totalHeight += rowHeight; // Add the last row's height
            return totalHeight;
        }

        //Signal to calculate the height when items change
        onChildrenChanged: calculateFlowHeight()

        Component.onCompleted: calculateFlowHeight()

        // Genre Distribution Chart (copied from CollectionReports)
        Item {
            id: genreChartContainer
            width: 600
            height: 400

            ChartView {
                id: genreChart
                anchors.fill: parent
                title: "Books by Genre Distribution"
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

                for (var i = 0; i < data.length; i++) {
                    var slice = genreSeries.append(data[i].label, data[i].value)
                    slice.labelVisible = data[i].percentage > 5 // Show label if > 5%
                }
            }
        }

        // Most Reserved Books Chart (copied from ReservationReports)
        Item {
            id: mostReservedContainer
            width: 600
            height: 500

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

                var data = reportsManager.getMostReservedBooks(20)
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


        // Genre Popularity Trends Over Time
        Rectangle{
            id: genreTrendsContainer
            width: 600
            height: 400
            radius: 8
            anchors.leftMargin: 20
            border.color: "lightgray"


            ChartView {
                id: genreTrendsChart
                anchors.fill: parent
                title: "Genre Popularity Trends Over Time"
                antialiasing: true
                legend.alignment: Qt.AlignBottom
                backgroundColor: "transparent"

                DateTimeAxis {
                    id: genreTrendsDateAxis
                    format: "MMM yyyy"
                    titleText: "Month"
                    min: new Date(new Date().getFullYear(), 0, 1)  // Start of this year
                    max: new Date()  // Today
                }
                ValuesAxis {
                    id: genreTrendsValueAxis
                    titleText: "Borrows"
                    min: 0
                    max: 10
                }
            }

            Component.onCompleted: {
                loadGenreTrends()
            }

            function loadGenreTrends() {
                genreTrendsChart.removeAllSeries()
                var data = reportsManager.getGenrePopularityTrends("last12months")
                console.log("Total data points received:", data.length)

                if (data.length === 0) {
                    console.log("No data returned from getGenrePopularityTrends")
                    return
                }

                var seriesMap = {}
                var colors = ["#F44336", "#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#00BCD4", "#FF5722"]
                var colorIndex = 0
                var minDate = null
                var maxDate = null
                var maxValue = 0

                // Group data by genre
                for (var i = 0; i < data.length; i++) {
                    console.log("Data point:", i, "Genre:", data[i].genre, "Month:", data[i].month, "Count:", data[i].count)

                    var genre = data[i].genre
                    if (!seriesMap[genre]) {
                        var series = genreTrendsChart.createSeries(ChartView.SeriesTypeLine, genre, genreTrendsDateAxis, genreTrendsValueAxis)
                        series.color = colors[colorIndex % colors.length]
                        series.width = 2
                        seriesMap[genre] = series
                        console.log("Created series for genre:", genre)
                        colorIndex++
                    }

                    var date = new Date(data[i].month + "-01")
                    var timestamp = date.getTime()
                    console.log("Parsed date:", date, "Timestamp:", timestamp)

                    seriesMap[genre].append(timestamp, data[i].count)

                    // Track min/max dates and values
                    if (minDate === null || timestamp < minDate) {
                        minDate = timestamp
                    }
                    if (maxDate === null || timestamp > maxDate) {
                        maxDate = timestamp
                    }
                    if (data[i].count > maxValue) {
                        maxValue = data[i].count
                    }
                }

                // Set Y-axis max with 10% padding
                genreTrendsValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

                // Set X-axis to actual data range with 1 month padding on each side
                if (minDate !== null && maxDate !== null) {
                    var minDateObj = new Date(minDate)
                    var maxDateObj = new Date(maxDate)

                    // Add 1 month padding on each side
                    minDateObj.setMonth(minDateObj.getMonth() - 1)
                    maxDateObj.setMonth(maxDateObj.getMonth() + 1)

                    genreTrendsDateAxis.min = minDateObj
                    genreTrendsDateAxis.max = maxDateObj
                }
            }
        }
    }
}
