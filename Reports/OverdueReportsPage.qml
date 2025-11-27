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
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export overdue report")
                        }
                    }
                }
            }
            
            // Key Metrics Cards
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "Key Metrics"
                
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
                    onExportClicked: console.log("Export days range chart")
                    
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
                                titleText: "Number of Books"
                                min: 0
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
                    onExportClicked: console.log("Export user type chart")
                    
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
                onExportClicked: console.log("Export overdue trend")
                
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
                        }
                        axisY: ValuesAxis {
                            id: overdueTrendValueAxis
                            titleText: "Overdue Books"
                            min: 0
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
                onExportClicked: console.log("Export top overdue users")
                
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
                            titleText: "Overdue Books"
                            min: 0
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
        
        for (var i = 0; i < data.length; i++) {
            daysRangeSet.append(data[i].value || 0)
        }
    }
    
    function loadOverdueTrend() {
        overdueTrendSeries.clear()
        
        var data = reportsManager.getOverdueTrendOverMonths(getDateRangeValue())
        
        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            overdueTrendSeries.append(date.getTime(), data[i].yValue)
        }
    }
    
    function loadUsersWithMostOverdue() {
        overdueUserBarSet.remove(0, overdueUserBarSet.count)
        
        var data = reportsManager.getUsersWithMostOverdue(15, getUserTypeFilter())
        var categories = []
        
        for (var i = data.length - 1; i >= 0; i--) {
            var name = data[i].label
            if (name.length > 25) {
                name = name.substring(0, 22) + "..."
            }
            categories.push(name)
            overdueUserBarSet.append(data[i].value)
        }
        
        overdueUserAxis.categories = categories
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
}
