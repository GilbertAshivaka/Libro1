import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: systemPerformancePage
    title: "System Performance"
    anchors.fill: parent
    
    signal closeClicked()
    
    MouseArea {
        anchors.fill: parent
        z: -1
    }
    
    // Back button
    Rectangle {
        id: backBtn
        width: 80
        height: 32
        radius: 25
        border.color: "#878585"
        border.width: 2
        clip: true
        z: 3
        anchors {
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 30
        }
        
        Text {
            anchors.centerIn: parent
            text: "Close"
            font.pixelSize: 16
            font.bold: true
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            
            onEntered: {
                backBtn.color = "#878585"
                parent.children[0].color = "white"
            }
            onExited: {
                backBtn.color = "white"
                parent.children[0].color = "#878585"
            }
            onClicked: closeClicked()
        }
    }
    
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        
        ColumnLayout {
            width: parent.width
            spacing: 20
            
            Item { height: 10 }
            
            // Header Section
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "⚙️ System Activity & Performance"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Monitor system health, usage patterns, and operational metrics"
                        font.pixelSize: 13
                        color: "#757575"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    // Filter Controls
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15
                        
                        Label {
                            text: "Date Range:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: dateRangeCombo
                            Layout.preferredWidth: 200
                            model: ["Today", "Last 7 Days", "Last 30 Days", "Last 3 Months", "All Time"]
                            currentIndex: 1
                            onActivated: loadSystemData()
                        }
                        
                        Label {
                            text: "Log Level:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: logLevelCombo
                            Layout.preferredWidth: 150
                            model: ["All", "INFO", "WARNING", "ERROR", "CRITICAL"]
                            currentIndex: 0
                            onActivated: loadSystemData()
                        }
                        
                        Label {
                            text: "Category:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: categoryCombo
                            Layout.preferredWidth: 150
                            model: ["All", "Database", "Authentication", "Sync", "API", "System"]
                            currentIndex: 0
                            onActivated: loadSystemData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadSystemData()
                        }
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export system report")
                        }
                    }
                }
            }
            
            // Key Metrics Cards
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "Key Metrics"
                background: Rectangle {
                    color: "transparent"
                    border.color: "transparent"
                    radius: 5
                }
                
                GridLayout {
                    width: parent.width
                    columns: 5
                    rowSpacing: 15
                    columnSpacing: 15
                    
                    StatCard {
                        id: operationsTodayCard
                        Layout.fillWidth: true
                        title: "Operations Today"
                        value: "0"
                        accentColor: "#2196F3"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: errorCount24hCard
                        Layout.fillWidth: true
                        title: "Errors (24h)"
                        value: "0"
                        accentColor: "#F44336"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: lastOpacSyncCard
                        Layout.fillWidth: true
                        title: "Last OPAC Sync"
                        value: "Never"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: databaseSizeCard
                        Layout.fillWidth: true
                        title: "Database Size"
                        value: "0 MB"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: peakUsageCard
                        Layout.fillWidth: true
                        title: "Peak Usage Hour"
                        value: "N/A"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // System Logs by Severity
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "System Logs by Severity Over Time"
                subtitle: "Track system stability and error patterns"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadLogsBySeverity()
                onExportClicked: console.log("Export logs by severity")
                
                contentItem: ChartView {
                    id: logsBySeverityChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.alignment: Qt.AlignBottom
                    backgroundColor: "transparent"
                    
                    DateTimeAxis {
                        id: logsDateAxis
                        format: "MMM dd"
                        titleText: "Date"
                        min: new Date(new Date().getFullYear() , 0, 1)
                        max: new Date()
                    }
                    ValuesAxis {
                        id: logsValueAxis
                        titleText: "Log Count"
                        min: 0
                        max: 500
                    }
                }
            }
            
            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20
                
                // Log Categories Distribution
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Log Categories Distribution"
                    subtitle: "Which parts of system are most active"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadLogCategories()
                    onExportClicked: console.log("Export log categories")
                    
                    contentItem: ChartView {
                        id: logCategoriesChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"
                        
                        PieSeries {
                            id: logCategoriesSeries
                        }
                    }
                }
                
                // OPAC Sync Operations
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "OPAC Sync Operations"
                    subtitle: "Integration health with online catalog"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadOpacSyncOps()
                    onExportClicked: console.log("Export OPAC sync")
                    
                    contentItem: ChartView {
                        id: opacSyncChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"
                        
                        BarSeries {
                            id: opacSyncSeries
                            axisX: BarCategoryAxis {
                                id: syncStatusAxis
                                categories: ["Success", "Failure", "Pending"]
                            }
                            axisY: ValuesAxis {
                                id: syncOpsAxis
                                titleText: "Count"
                                min: 0
                                max: 500
                            }
                            
                            BarSet {
                                id: syncBarSet
                                label: "Operations"
                                color: "#4CAF50"
                            }
                        }
                    }
                }
            }
            
            // Daily System Activity
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Daily System Activity"
                subtitle: "Overall system usage patterns"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadDailyActivity()
                onExportClicked: console.log("Export daily activity")
                
                contentItem: ChartView {
                    id: dailyActivityChart
                    anchors.fill: parent
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
                            min: new Date(new Date().getFullYear() , 0, 1)
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
            }
            
            Item { height: 20 }
        }
    }
    
    Component.onCompleted: {
        loadSystemData()
    }
    
    function getDateRangeValue() {
        var ranges = ["today", "last7days", "last30days", "last3months", "all"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getLogLevelFilter() {
        return logLevelCombo.currentIndex === 0 ? "all" : logLevelCombo.currentText
    }
    
    function getCategoryFilter() {
        return categoryCombo.currentIndex === 0 ? "all" : categoryCombo.currentText
    }
    
    function loadSystemData() {
        loadSystemStats()
        loadLogsBySeverity()
        loadLogCategories()
        loadOpacSyncOps()
        loadDailyActivity()
    }
    
    function loadSystemStats() {
        var stats = reportsManager.getSystemPerformanceStats()
        
        operationsTodayCard.value = stats.operationsToday || "0"
        errorCount24hCard.value = stats.errorCount24h || "0"
        lastOpacSyncCard.value = formatDateTime(stats.lastOpacSync)
        databaseSizeCard.value = stats.databaseSize || "0 MB"
        peakUsageCard.value = stats.peakUsageHour || "N/A"
    }
    
    function formatDateTime(dateStr) {
        if (!dateStr || dateStr === "Never") return "Never"
        var date = new Date(dateStr)
        if (isNaN(date.getTime())) return "Never"
        return Qt.formatDateTime(date, "MMM dd HH:mm")
    }
    
    function loadLogsBySeverity() {
        // Clear existing series
        logsBySeverityChart.removeAllSeries()

        var data = reportsManager.getSystemLogsBySeverity(getDateRangeValue())
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

    function loadLogCategories() {
        logCategoriesSeries.clear()

        var data = reportsManager.getLogCategoriesDistribution(getDateRangeValue())
        var colors = ["#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#F44336", "#00BCD4"]

        for (var i = 0; i < data.length; i++) {
            var slice = logCategoriesSeries.append(data[i].label, data[i].value)
            slice.color = colors[i % colors.length]
            slice.labelVisible = data[i].percentage > 5
        }
    }

    function loadOpacSyncOps() {
        syncBarSet.remove(0, syncBarSet.count)

        var data = reportsManager.getOpacSyncOperations(getDateRangeValue())
        var statusMap = { "success": 0, "failure": 0, "pending": 0 }

        for (var i = 0; i < data.length; i++) {
            var status = data[i].category.toLowerCase()
            if (statusMap.hasOwnProperty(status)) {
                statusMap[status] = data[i].value
            }
        }

        syncBarSet.append(statusMap["success"])
        syncBarSet.append(statusMap["failure"])
        syncBarSet.append(statusMap["pending"])

        // Find max value from the three statuses
        var maxValue = Math.max(statusMap["success"], statusMap["failure"], statusMap["pending"])

        // Set Y-axis max dynamically with 10% padding
        syncOpsAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Color code the bars
        syncBarSet.color = statusMap["failure"] > statusMap["success"] ? "#F44336" : "#4CAF50"
    }

    function loadDailyActivity() {
        activityUpperSeries.clear()

        var data = reportsManager.getDailySystemActivity(getDateRangeValue())
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
