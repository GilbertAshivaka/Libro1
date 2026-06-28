import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: overdueReportsPage
    title: "Overdue & Compliance"
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
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
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
                title: "⚠️ Overdue & Compliance"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Track late returns and compliance issues"
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
                            model: ["All Time", "Last 30 Days", "Last 3 Months", "Last 6 Months", "Last 12 Months"]
                            currentIndex: 0
                            onActivated: loadOverdueData()
                        }
                        
                        Label {
                            text: "User Type:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: userTypeCombo
                            Layout.preferredWidth: 150
                            model: userTypeModel
                            currentIndex: 0
                            onActivated: loadOverdueData()
                        }
                        
                        Label {
                            text: "Genre:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: genreCombo
                            Layout.preferredWidth: 150
                            model: genreModel
                            currentIndex: 0
                            onActivated: loadOverdueData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadOverdueData()
                        }

                        ExportButton {
                            enabled: !reportExporter.isBusy
                            onExportPDF: reportExporter.exportToPdf(buildReportPayload())
                            onExportCSV: reportExporter.exportToCsv(buildReportPayload())
                            onExportExcel: reportExporter.exportToCsv(buildReportPayload())
                            onPrintReport: reportExporter.printReport(buildReportPayload())
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
                        id: totalOverdueCard
                        Layout.fillWidth: true
                        title: "Total Overdue"
                        value: "0"
                        accentColor: "#F44336"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: longestOverdueCard
                        Layout.fillWidth: true
                        title: "Longest Overdue"
                        value: "0"
                        unit: "days"
                        accentColor: "#E91E63"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: avgDaysOverdueCard
                        Layout.fillWidth: true
                        title: "Avg Days Overdue"
                        value: "0"
                        unit: "days"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: critical30PlusCard
                        Layout.fillWidth: true
                        title: "30+ Days Overdue"
                        value: "0"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: overdueRateCard
                        Layout.fillWidth: true
                        title: "Overdue Rate"
                        value: "0"
                        unit: "%"
                        accentColor: "#FF5722"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20
                
                // Overdue by Days Range
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Overdue Books by Days Range"
                    subtitle: "Severity distribution of overdue items"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadOverdueByDaysRange()
                    onExportClicked: exportChart(daysRangeSection())
                    
                    contentItem: ChartView {
                        id: daysRangeChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"
                        
                        BarSeries {
                            id: daysRangeSeries
                            axisX: BarCategoryAxis {
                                id: daysRangeAxis
                                categories: ["0-7 days", "8-14 days", "15-30 days", "30+ days"]
                            }
                            axisY: ValuesAxis {
                                id: daysRangeValueAxis
                                titleText: "Number of Books"
                                min: 0
                                max: 10
                            }
                            
                            BarSet {
                                id: daysRangeSet
                                label: "Overdue"
                                color: "#FF5722"
                            }
                        }
                    }
                }
                
                // Overdue by User Type
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Overdue Books by User Type"
                    subtitle: "Compliance issues per user group"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadOverdueByUserType()
                    onExportClicked: exportChart(overdueByUserTypeSection())
                    
                    contentItem: ChartView {
                        id: overdueUserTypeChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"
                        
                        PieSeries {
                            id: overdueUserTypeSeries
                        }
                    }
                }
            }
            
            // Overdue Trend Over Months
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Overdue Trend Over Months"
                subtitle: "Track if overdue problem is improving or worsening"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadOverdueTrend()
                onExportClicked: exportChart(overdueTrendSection())
                
                contentItem: ChartView {
                    id: overdueTrendChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    LineSeries {
                        id: overdueTrendSeries
                        name: "Overdue Count"
                        color: "#F44336"
                        width: 3
                        
                        axisX: DateTimeAxis {
                            id: overdueTrendDateAxis
                            format: "MMM yyyy"
                            titleText: "Month"
                            min: new Date(new Date().getFullYear() , 0, 1)  // Start of this year
                            max: new Date()  // Today
                        }
                        axisY: ValuesAxis {
                            id: overdueTrendValueAxis
                            titleText: "Overdue Books"
                            min: 0
                            max: 10
                        }
                    }
                }
            }
            
            // Users with Most Overdue
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 500
                title: "Users with Most Overdue Books"
                subtitle: "Top 15 users for follow-up"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadUsersWithMostOverdue()
                onExportClicked: exportChart(usersWithMostOverdueSection())
                
                contentItem: ChartView {
                    id: topOverdueUsersChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    HorizontalBarSeries {
                        id: topOverdueUsersSeries
                        axisY: BarCategoryAxis { id: overdueUserAxis }
                        axisX: ValuesAxis {
                            id: overdueUserValueAxis
                            titleText: "Overdue Books"
                            min: 0
                            max: 10
                        }
                        
                        BarSet {
                            id: overdueUserBarSet
                            label: "Overdue"
                            color: "#E91E63"
                        }
                    }
                }
            }
            
            Item { height: 20 }
        }
    }
    
    // Data Models
    ListModel {
        id: userTypeModel
        ListElement { text: "All User Types" }
    }
    
    ListModel {
        id: genreModel
        ListElement { text: "All Genres" }
    }
    
    Component.onCompleted: {
        loadFilters()
        loadOverdueData()
    }
    
    function loadFilters() {
        var genres = reportsManager.getAvailableGenres()
        for (var i = 0; i < genres.length; i++) {
            var genre = genres[i]
            // genre is a map → pick the correct key (most likely "genre", "label", or "value")
            genreModel.append({ text: genre.genre || genre.label || genre.value || genre.toString() })
        }

        var types = reportsManager.getAvailableUserTypes();

        for (var j = 0; j < types.length; j++) {
            var map = types[j];
            // Adjust the key below to match what your C++ query actually returns
            userTypeModel.append({ text: map.userType || map.type || map.name || map.label || map.value || "" });
        }
    }
    
    function getDateRangeValue() {
        var ranges = ["all", "last30days", "last3months", "last6months", "last12months"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getUserTypeFilter() {
        return userTypeCombo.currentIndex === 0 ? "all" : userTypeCombo.currentText
    }
    
    function getGenreFilter() {
        return genreCombo.currentIndex === 0 ? "all" : genreCombo.currentText
    }
    
    function loadOverdueData() {
        loadOverdueStats()
        loadOverdueByDaysRange()
        loadOverdueTrend()
        loadUsersWithMostOverdue()
        loadOverdueByUserType()
    }
    
    function loadOverdueStats() {
        var stats = reportsManager.getOverdueStats()
        
        totalOverdueCard.value = stats.totalOverdue || "0"
        longestOverdueCard.value = Math.floor(stats.longestOverdueDays || 0)
        avgDaysOverdueCard.value = (stats.averageDaysOverdue || 0).toFixed(1)
        critical30PlusCard.value = stats.overdue30Plus || "0"
        overdueRateCard.value = (stats.overdueRate || 0).toFixed(1)
    }
    
    function loadOverdueByDaysRange() {
        daysRangeSet.remove(0, daysRangeSet.count)

        var data = reportsManager.getOverdueBooksByDaysRange()
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            var value = data[i].value || 0
            daysRangeSet.append(value)

            if (value > maxValue) {
                maxValue = value
            }
        }

        // Set Y-axis max dynamically with 10% padding
        daysRangeValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    function loadOverdueTrend() {
        overdueTrendSeries.clear()

        var data = reportsManager.getOverdueTrendOverMonths(getDateRangeValue())
        var minDate = null
        var maxDate = null
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            var timestamp = date.getTime()
            overdueTrendSeries.append(timestamp, data[i].yValue)

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
        overdueTrendValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis to actual data range with 1 month padding on each side
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            // Add 1 month padding on each side
            minDateObj.setMonth(minDateObj.getMonth() - 1)
            maxDateObj.setMonth(maxDateObj.getMonth() + 1)

            overdueTrendDateAxis.min = minDateObj
            overdueTrendDateAxis.max = maxDateObj
        }
    }

    function loadUsersWithMostOverdue() {
        overdueUserBarSet.remove(0, overdueUserBarSet.count)

        var data = reportsManager.getUsersWithMostOverdue(15, getUserTypeFilter())
        var categories = []
        var maxValue = 0

        for (var i = data.length - 1; i >= 0; i--) {
            var name = data[i].label
            if (name.length > 25) {
                name = name.substring(0, 22) + "..."
            }
            categories.push(name)
            overdueUserBarSet.append(data[i].value)

            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        overdueUserAxis.categories = categories

        // Set X-axis max dynamically with 10% padding
        overdueUserValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    function loadOverdueByUserType() {
        overdueUserTypeSeries.clear()

        var data = reportsManager.getOverdueBooksByUserType()
        var colors = ["#F44336", "#FF9800", "#9C27B0", "#E91E63", "#FF5722"]

        for (var i = 0; i < data.length; i++) {
            var slice = overdueUserTypeSeries.append(data[i].label, data[i].value)
            slice.color = colors[i % colors.length]
            slice.labelVisible = true
        }
    }

    // ========================================================================
    // Report export / print
    // ========================================================================

    function filtersList() {
        return [
            { label: "Date Range", value: dateRangeCombo.currentText },
            { label: "User Type",  value: userTypeCombo.currentText },
            { label: "Genre",      value: genreCombo.currentText }
        ]
    }

    function metricsSection() {
        var s = reportsManager.getOverdueStats()
        return {
            title: "Key Metrics", kind: "metrics",
            data: [
                { label: "Total Overdue",    value: String(s.totalOverdue || 0) },
                { label: "Longest Overdue",  value: String(Math.floor(s.longestOverdueDays || 0)), unit: "days" },
                { label: "Avg Days Overdue", value: (s.averageDaysOverdue || 0).toFixed(1), unit: "days" },
                { label: "30+ Days Overdue", value: String(s.overdue30Plus || 0) },
                { label: "Overdue Rate",     value: (s.overdueRate || 0).toFixed(1), unit: "%" }
            ]
        }
    }

    function daysRangeSection() {
        var data = reportsManager.getOverdueBooksByDaysRange()
        var fixed = ["0-7 days", "8-14 days", "15-30 days", "30+ days"]
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].category || data[i].label || fixed[i] || ("Range " + (i + 1)))
            values.push(data[i].value || 0)
        }
        return {
            title: "Overdue Books by Days Range",
            subtitle: "Severity distribution of overdue items",
            kind: "chart", chartType: "bar",
            labels: labels,
            datasets: [ { label: "Overdue", color: "#FF5722", data: values } ]
        }
    }

    function overdueByUserTypeSection() {
        var data = reportsManager.getOverdueBooksByUserType()
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
        }
        return {
            title: "Overdue Books by User Type",
            subtitle: "Compliance issues per user group",
            kind: "chart", chartType: "pie",
            labels: labels,
            datasets: [ { label: "Overdue", data: values } ]
        }
    }

    function overdueTrendSection() {
        var data = reportsManager.getOverdueTrendOverMonths(getDateRangeValue())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].xValue)
            values.push(data[i].yValue)
        }
        return {
            title: "Overdue Trend Over Months",
            subtitle: "Track if overdue problem is improving or worsening",
            kind: "chart", chartType: "line",
            labels: labels,
            datasets: [ { label: "Overdue Count", color: "#F44336", data: values } ]
        }
    }

    function usersWithMostOverdueSection() {
        var data = reportsManager.getUsersWithMostOverdue(15, getUserTypeFilter())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            var name = data[i].label
            if (name.length > 30)
                name = name.substring(0, 27) + "..."
            labels.push(name)
            values.push(data[i].value)
        }
        return {
            title: "Users with Most Overdue Books",
            subtitle: "Top 15 users for follow-up",
            kind: "chart", chartType: "horizontalBar",
            labels: labels,
            datasets: [ { label: "Overdue", color: "#E91E63", data: values } ]
        }
    }

    function buildReportPayload() {
        return {
            title: "Overdue & Compliance",
            subtitle: "Track late returns and compliance issues",
            filters: filtersList(),
            sections: [
                metricsSection(),
                daysRangeSection(),
                overdueByUserTypeSection(),
                overdueTrendSection(),
                usersWithMostOverdueSection()
            ]
        }
    }

    function exportChart(section) {
        reportExporter.exportToPdf({
            title: "Overdue & Compliance — " + section.title,
            filters: filtersList(),
            sections: [ section ]
        })
    }

    Connections {
        target: reportExporter
        function onExportFinished(success, outputPath, message) {
            if (success && outputPath)
                console.log("Report exported to:", outputPath)
            else if (!success && message)
                console.warn("Report export failed:", message)
        }
    }
}
