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
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export lost/damaged report")
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
                onExportClicked: console.log("Export lost books trend")
                
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
                        }
                        axisY: ValuesAxis {
                            id: lostBooksValueAxis
                            titleText: "Lost Books"
                            min: 0
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
                    onExportClicked: console.log("Export genre breakdown")
                    
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
                                titleText: "Lost Books"
                                min: 0
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
                    onExportClicked: console.log("Export resolution status")
                    
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
                onExportClicked: console.log("Export users with lost books")
                
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
                            titleText: "Lost Books"
                            min: 0
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
        
        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            lostBooksTimeSeries.append(date.getTime(), data[i].yValue)
        }
    }
    
    function loadLostBooksByGenre() {
        genreBarSet.remove(0, genreBarSet.count)
        
        var data = reportsManager.getLostBooksByGenre()
        var categories = []
        
        for (var i = 0; i < Math.min(data.length, 10); i++) {
            var genre = data[i].category
            if (genre.length > 15) {
                genre = genre.substring(0, 12) + "..."
            }
            categories.push(genre)
            genreBarSet.append(data[i].value)
        }
        
        genreAxis.categories = categories
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
        
        for (var i = data.length - 1; i >= 0; i--) {
            var name = data[i].label
            if (name.length > 25) {
                name = name.substring(0, 22) + "..."
            }
            categories.push(name)
            userLostBarSet.append(data[i].value)
        }
        
        userAxis.categories = categories
    }
}
