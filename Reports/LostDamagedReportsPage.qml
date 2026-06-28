import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: lostDamagedPage
    title: "Lost & Damaged Books"
    anchors.fill: parent
    
    signal closeClicked()
    
    MouseArea {
        anchors.fill: parent
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
                title: "📕 Lost & Damaged Books"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Monitor collection losses and damage"
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
                            model: ["All Time", "Last 3 Months", "Last 6 Months", "Last 12 Months", "Current Year"]
                            currentIndex: 0
                            onActivated: loadLostDamagedData()
                        }
                        
                        Label {
                            text: "Resolution:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: resolutionCombo
                            Layout.preferredWidth: 150
                            model: ["All", "Replaced", "Paid", "Pending", "Waived"]
                            currentIndex: 0
                            onActivated: loadLostDamagedData()
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
                            onActivated: loadLostDamagedData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadLostDamagedData()
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
                        id: totalLostCard
                        Layout.fillWidth: true
                        title: "Total Lost Books"
                        value: "0"
                        accentColor: "#F44336"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: lostThisYearCard
                        Layout.fillWidth: true
                        title: "Lost This Year"
                        value: "0"
                        accentColor: "#E91E63"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: replacementCostCard
                        Layout.fillWidth: true
                        title: "Replacement Cost"
                        value: "$0"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: damagedBooksCard
                        Layout.fillWidth: true
                        title: "Damaged Books"
                        value: "0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: lossRateCard
                        Layout.fillWidth: true
                        title: "Loss Rate"
                        value: "0"
                        unit: "%"
                        accentColor: "#FF5722"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // Lost Books Over Time
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Lost Books Over Time"
                subtitle: "Trend of book losses"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadLostBooksOverTime()
                onExportClicked: exportChart(lostBooksOverTimeSection())
                
                contentItem: ChartView {
                    id: lostBooksTimeChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    LineSeries {
                        id: lostBooksTimeSeries
                        name: "Lost Books"
                        color: "#F44336"
                        width: 3
                        
                        axisX: DateTimeAxis {
                            id: lostBooksDateAxis
                            format: "MMM yyyy"
                            titleText: "Month"
                            min: new Date(new Date().getFullYear() , 0, 1) // start of this year
                            max:  new Date()
                        }
                        axisY: ValuesAxis {
                            id: lostBooksValueAxis
                            titleText: "Lost Books"
                            min: 0
                            max: 10
                        }
                    }
                }
            }
            
            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20
                
                // Lost Books by Genre
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Lost Books by Genre"
                    subtitle: "Which types are most commonly lost"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadLostBooksByGenre()
                    onExportClicked: exportChart(lostByGenreSection())
                    
                    contentItem: ChartView {
                        id: lostByGenreChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"
                        
                        BarSeries {
                            id: lostByGenreSeries
                            axisX: BarCategoryAxis { id: genreAxis }
                            axisY: ValuesAxis {
                                id: genreValuesAxis
                                titleText: "Lost Books"
                                min: 0
                                max: 10
                            }
                            
                            BarSet {
                                id: genreBarSet
                                label: "Lost"
                                color: "#E91E63"
                            }
                        }
                    }
                }
                
                // Resolution Status
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Lost Book Resolution Status"
                    subtitle: "Status of lost book cases"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadResolutionStatus()
                    onExportClicked: exportChart(resolutionStatusSection())
                    
                    contentItem: ChartView {
                        id: resolutionStatusChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"
                        
                        PieSeries {
                            id: resolutionStatusSeries
                            holeSize: 0.4
                        }
                    }
                }
            }
            
            // Users with Lost Books
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 500
                title: "Users with Lost Books"
                subtitle: "Top 15 users who frequently lose books"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadUsersWithLostBooks()
                onExportClicked: exportChart(usersWithLostBooksSection())
                
                contentItem: ChartView {
                    id: usersLostBooksChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    HorizontalBarSeries {
                        id: usersLostBooksSeries
                        axisY: BarCategoryAxis { id: userAxis }
                        axisX: ValuesAxis {
                            id: lostBooksPerUserAxis
                            titleText: "Lost Books"
                            min: 0
                            max: 10
                        }
                        
                        BarSet {
                            id: userLostBarSet
                            label: "Lost"
                            color: "#9C27B0"
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
    
    Component.onCompleted: {
        loadUserTypes()
        loadLostDamagedData()
    }
    
    function loadUserTypes() {
        var types = reportsManager.getAvailableUserTypes();

        for (var i = 0; i < types.length; i++) {
            var map = types[i];
            userTypeModel.append({ text: map.userType || map.type || map.name || map.label || map.value || "" });
        }
    }
    
    function getDateRangeValue() {
        var ranges = ["all", "last3months", "last6months", "last12months", "currentYear"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getResolutionFilter() {
        return resolutionCombo.currentIndex === 0 ? "all" : resolutionCombo.currentText
    }
    
    function getUserTypeFilter() {
        return userTypeCombo.currentIndex === 0 ? "all" : userTypeCombo.currentText
    }
    
    function loadLostDamagedData() {
        loadLostDamagedStats()
        loadLostBooksOverTime()
        loadLostBooksByGenre()
        loadResolutionStatus()
        loadUsersWithLostBooks()
    }
    
    function loadLostDamagedStats() {
        var stats = reportsManager.getLostDamagedStats()
        
        totalLostCard.value = stats.totalLostBooks || "0"
        lostThisYearCard.value = stats.lostBooksThisYear || "0"
        replacementCostCard.value = "$" + (stats.replacementCostOutstanding || 0).toFixed(2)
        damagedBooksCard.value = stats.damagedBooks || "0"
        lossRateCard.value = (stats.lossRate || 0).toFixed(2)
    }
    
    function loadLostBooksOverTime() {
        lostBooksTimeSeries.clear()

        var data = reportsManager.getLostBooksOverTime(getDateRangeValue())
        var minDate = null
        var maxDate = null
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            var timestamp = date.getTime()
            lostBooksTimeSeries.append(timestamp, data[i].yValue)

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
        lostBooksValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis to actual data range with 1 month padding on each side
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            // Add 1 month padding on each side
            minDateObj.setMonth(minDateObj.getMonth() - 1)
            maxDateObj.setMonth(maxDateObj.getMonth() + 1)

            lostBooksDateAxis.min = minDateObj
            lostBooksDateAxis.max = maxDateObj
        }
    }

    function loadLostBooksByGenre() {
        genreBarSet.remove(0, genreBarSet.count)

        var data = reportsManager.getLostBooksByGenre()
        var categories = []
        var maxValue = 0

        for (var i = 0; i < Math.min(data.length, 10); i++) {
            var genre = data[i].category
            if (genre.length > 15) {
                genre = genre.substring(0, 12) + "..."
            }
            categories.push(genre)
            genreBarSet.append(data[i].value)

            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        genreAxis.categories = categories

        // Set Y-axis max dynamically with 10% padding
        genreValuesAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    function loadResolutionStatus() {
        resolutionStatusSeries.clear()

        var data = reportsManager.getLostBookResolutionStatus()
        var colors = {
            "Replaced": "#4CAF50",
            "Paid": "#2196F3",
            "Pending": "#FF9800",
            "Waived": "#9E9E9E"
        }

        for (var i = 0; i < data.length; i++) {
            var slice = resolutionStatusSeries.append(data[i].label, data[i].value)
            if (colors[data[i].label]) {
                slice.color = colors[data[i].label]
            }
            slice.labelVisible = true
        }
    }

    function loadUsersWithLostBooks() {
        userLostBarSet.remove(0, userLostBarSet.count)

        var data = reportsManager.getUsersWithLostBooks(15)
        var categories = []
        var maxValue = 0

        for (var i = data.length - 1; i >= 0; i--) {
            var name = data[i].label
            if (name.length > 25) {
                name = name.substring(0, 22) + "..."
            }
            categories.push(name)
            userLostBarSet.append(data[i].value)

            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        userAxis.categories = categories

        // Set X-axis max dynamically with 10% padding
        lostBooksPerUserAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    // ========================================================================
    // Report export / print
    // ========================================================================

    function filtersList() {
        return [
            { label: "Date Range", value: dateRangeCombo.currentText },
            { label: "Resolution", value: resolutionCombo.currentText },
            { label: "User Type",  value: userTypeCombo.currentText }
        ]
    }

    function metricsSection() {
        var s = reportsManager.getLostDamagedStats()
        return {
            title: "Key Metrics", kind: "metrics",
            data: [
                { label: "Total Lost Books",  value: String(s.totalLostBooks || 0) },
                { label: "Lost This Year",    value: String(s.lostBooksThisYear || 0) },
                { label: "Replacement Cost",  value: "$" + (s.replacementCostOutstanding || 0).toFixed(2) },
                { label: "Damaged Books",     value: String(s.damagedBooks || 0) },
                { label: "Loss Rate",         value: (s.lossRate || 0).toFixed(2), unit: "%" }
            ]
        }
    }

    function lostBooksOverTimeSection() {
        var data = reportsManager.getLostBooksOverTime(getDateRangeValue())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].xValue)
            values.push(data[i].yValue)
        }
        return {
            title: "Lost Books Over Time",
            subtitle: "Trend of book losses",
            kind: "chart", chartType: "line",
            labels: labels,
            datasets: [ { label: "Lost Books", color: "#F44336", data: values } ]
        }
    }

    function lostByGenreSection() {
        var data = reportsManager.getLostBooksByGenre()
        var labels = [], values = []
        for (var i = 0; i < Math.min(data.length, 10); i++) {
            labels.push(data[i].category)
            values.push(data[i].value)
        }
        return {
            title: "Lost Books by Genre",
            subtitle: "Which types are most commonly lost",
            kind: "chart", chartType: "bar",
            labels: labels,
            datasets: [ { label: "Lost", color: "#E91E63", data: values } ]
        }
    }

    function resolutionStatusSection() {
        var data = reportsManager.getLostBookResolutionStatus()
        var colorMap = {
            "Replaced": "#4CAF50", "Paid": "#2196F3", "Pending": "#FF9800", "Waived": "#9E9E9E"
        }
        var labels = [], values = [], colors = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
            colors.push(colorMap[data[i].label] || "#607D8B")
        }
        return {
            title: "Lost Book Resolution Status",
            subtitle: "Status of lost book cases",
            kind: "chart", chartType: "doughnut",
            labels: labels,
            datasets: [ { label: "Cases", data: values, colors: colors } ]
        }
    }

    function usersWithLostBooksSection() {
        var data = reportsManager.getUsersWithLostBooks(15)
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            var name = data[i].label
            if (name.length > 30)
                name = name.substring(0, 27) + "..."
            labels.push(name)
            values.push(data[i].value)
        }
        return {
            title: "Users with Lost Books",
            subtitle: "Top 15 users who frequently lose books",
            kind: "chart", chartType: "horizontalBar",
            labels: labels,
            datasets: [ { label: "Lost", color: "#9C27B0", data: values } ]
        }
    }

    function buildReportPayload() {
        return {
            title: "Lost & Damaged Books",
            subtitle: "Monitor collection losses and damage",
            filters: filtersList(),
            sections: [
                metricsSection(),
                lostBooksOverTimeSection(),
                lostByGenreSection(),
                resolutionStatusSection(),
                usersWithLostBooksSection()
            ]
        }
    }

    function exportChart(section) {
        reportExporter.exportToPdf({
            title: "Lost & Damaged Books — " + section.title,
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
