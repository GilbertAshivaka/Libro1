import QtQuick
import QtQuick.Controls
import QtCharts

Item {
    id: reportsActivity
    anchors.fill: parent
    property double calCulatedHeight: 0
    property double activityFlowHeight: activityFlowItem.calculateFlowHeight()

    Flow{
        id: activityFlowItem
        anchors.fill: parent
        spacing: 20

        function calculateFlowHeight() {
            let currentWidth = 0;
            let rowHeight = 0;
            let totalHeight = 0;
            let spacing = activityFlowItem.spacing;

            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (!item.visible) continue;

                if (currentWidth + item.width > activityFlowItem.width) {
                    totalHeight += rowHeight + spacing;
                    currentWidth = 0;
                    rowHeight = 0;
                }

                currentWidth += item.width + spacing;
                rowHeight = Math.max(rowHeight, item.height);
            }

            totalHeight += rowHeight; // Add the last row's height
//            calculatedHeight = totalHeight;
//            console.log("Calculated Height: ", totalHeight);
            return totalHeight;
        }

        //Signal to calculate the height when items change
        onChildrenChanged: calculateFlowHeight()

        Component.onCompleted: calculateFlowHeight()

        // System Logs by Severity Over Time
        Rectangle{
            id: logsBySeverityContainer
            width: 600
            height: 400
            radius: 8
            // border.color: "lightgray"


            ChartView {
                id: logsBySeverityChart
                anchors.fill: parent
                title: "System Logs by Severity Over Time"
                antialiasing: true
                legend.alignment: Qt.AlignBottom
                backgroundColor: "transparent"

                DateTimeAxis {
                    id: logsDateAxis
                    format: "MMM dd"
                    titleText: "Date"
                    min: new Date(new Date().getFullYear(), 0, 1)
                    max: new Date()
                }
                ValuesAxis {
                    id: logsValueAxis
                    titleText: "Log Count"
                    min: 0
                    max: 500
                }
            }

            Component.onCompleted: {
                loadLogsBySeverity()
            }

            function loadLogsBySeverity() {
                // Clear existing series
                logsBySeverityChart.removeAllSeries()
                var data = reportsManager.getSystemLogsBySeverity("all")
                var seriesMap = {}
                var colors = {
                    "INFO": "#2196F3",
                    "WARNING": "#FF9800",
                    "ERROR": "#F44336",
                    "CRITICAL": "#9C27B0"
                }
                var minDate = null
                var maxDate = null
                var maxValue = 0

                // Group data by log level
                for (var i = 0; i < data.length; i++) {
                    var level = data[i].log_level
                    if (!seriesMap[level]) {
                        var series = logsBySeverityChart.createSeries(ChartView.SeriesTypeLine, level, logsDateAxis, logsValueAxis)
                        series.color = colors[level] || "#9E9E9E"
                        series.width = 2
                        seriesMap[level] = series
                    }
                    var date = new Date(data[i].date)
                    var timestamp = date.getTime()
                    seriesMap[level].append(timestamp, data[i].count)

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
                logsValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

                // Set X-axis to actual data range with 1 day padding on each side
                if (minDate !== null && maxDate !== null) {
                    var minDateObj = new Date(minDate)
                    var maxDateObj = new Date(maxDate)

                    // Add 1 day padding on each side
                    minDateObj.setDate(minDateObj.getDate() - 1)
                    maxDateObj.setDate(maxDateObj.getDate() + 1)

                    logsDateAxis.min = minDateObj
                    logsDateAxis.max = maxDateObj
                }
            }
        }

        // Log Categories Distribution
        Rectangle{
            id: logCategoriesContainer
            width: 600
            height: 400
            radius: 8
            // border.color: "lightgray"

            ChartView {
                id: logCategoriesChart
                anchors.fill: parent
                title: "Log Categories Distribution"
                antialiasing: true
                legend.alignment: Qt.AlignRight
                backgroundColor: "transparent"

                PieSeries {
                    id: logCategoriesSeries
                }
            }

            Component.onCompleted: {
                loadLogCategories()
            }

            function loadLogCategories() {
                logCategoriesSeries.clear()
                var data = reportsManager.getLogCategoriesDistribution("all")
                var colors = ["#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#F44336", "#00BCD4"]

                for (var i = 0; i < data.length; i++) {
                    var slice = logCategoriesSeries.append(data[i].label, data[i].value)
                    slice.color = colors[i % colors.length]
                    slice.labelVisible = data[i].percentage > 5
                }
            }
        }

        // Daily System Activity
        Rectangle{
            id: dailyActivityContainer
            width: 600
            height: 400
            radius: 8
            border.color: "lightgray"

            ChartView {
                id: dailyActivityChart
                anchors.fill: parent
                title: "Daily System Activity"
                antialiasing: true
                legend.visible: false
                backgroundColor: "transparent"

                AreaSeries {
                    id: dailyActivitySeries
                    name: "Activity"
                    color: "#2196F3"
                    borderColor: "#1976D2"
                    borderWidth: 2

                    axisX: DateTimeAxis {
                        id: activityDateAxis
                        format: "MMM dd"
                        titleText: "Date"
                        min: new Date(new Date().getFullYear(), 0, 1)
                        max: new Date()
                    }
                    axisY: ValuesAxis {
                        id: activityValueAxis
                        titleText: "Operations"
                        min: 0
                        max: 2000
                    }

                    upperSeries: LineSeries {
                        id: activityUpperSeries
                    }
                }
            }

            Component.onCompleted: {
                loadDailyActivity()
            }

            function loadDailyActivity() {
                activityUpperSeries.clear()
                var data = reportsManager.getDailySystemActivity("all")
                var minDate = null
                var maxDate = null
                var maxValue = 0

                for (var i = 0; i < data.length; i++) {
                    var date = new Date(data[i].xValue)
                    var timestamp = date.getTime()
                    activityUpperSeries.append(timestamp, data[i].yValue)

                    // Track min/max dates and values
                    if (minDate === null || timestamp < minDate) {
                        minDate = timestamp
                    }
                    if (maxDate === null || timestamp > maxDate) {
                        maxDate = timestamp
                    }
                    if (data[i].yValue > maxValue) {
                        maxValue = data[i].yValue
                    }
                }

                // Set Y-axis max with 10% padding
                activityValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

                // Set X-axis to actual data range with 1 day padding on each side
                if (minDate !== null && maxDate !== null) {
                    var minDateObj = new Date(minDate)
                    var maxDateObj = new Date(maxDate)

                    // Add 1 day padding on each side
                    minDateObj.setDate(minDateObj.getDate() - 1)
                    maxDateObj.setDate(maxDateObj.getDate() + 1)

                    activityDateAxis.min = minDateObj
                    activityDateAxis.max = maxDateObj
                }
            }
        }
    }
}






