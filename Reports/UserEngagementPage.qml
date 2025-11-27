import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: userEngagementPage
    title: "User Engagement & Demographics"
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
                title: "👥 User Engagement & Demographics"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Understand your user base and participation levels"
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
                            onActivated: loadUserEngagementData()
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
                            onActivated: loadUserEngagementData()
                        }
                        
                        Label {
                            text: "Status:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: statusCombo
                            Layout.preferredWidth: 150
                            model: ["All", "Active", "Inactive", "Suspended"]
                            currentIndex: 0
                            onActivated: loadUserEngagementData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadUserEngagementData()
                        }
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export user engagement report")
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
                        id: totalUsersCard
                        Layout.fillWidth: true
                        title: "Total Users"
                        value: "0"
                        accentColor: "#2196F3"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: activeUsersCard
                        Layout.fillWidth: true
                        title: "Active (30 days)"
                        value: "0"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: inactiveUsersCard
                        Layout.fillWidth: true
                        title: "Inactive (90+ days)"
                        value: "0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: newUsersCard
                        Layout.fillWidth: true
                        title: "New This Month"
                        value: "0"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: avgBooksPerUserCard
                        Layout.fillWidth: true
                        title: "Avg Books/User"
                        value: "0"
                        accentColor: "#00BCD4"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // Charts Row 1
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20
                
                // User Distribution by Type
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "User Distribution by Type"
                    subtitle: "Breakdown of user categories"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadUserDistribution()
                    onExportClicked: console.log("Export user distribution")
                    
                    contentItem: ChartView {
                        id: userDistributionChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"
                        
                        PieSeries {
                            id: userDistributionSeries
                        }
                    }
                }
                
                // Borrowing Activity by User Category
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Borrowing Activity by Category"
                    subtitle: "Active vs total users per role"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadBorrowingActivity()
                    onExportClicked: console.log("Export borrowing activity")
                    
                    contentItem: ChartView {
                        id: borrowingActivityChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignBottom
                        backgroundColor: "transparent"
                        
                        BarSeries {
                            id: borrowingActivitySeries
                            axisX: BarCategoryAxis { id: categoryAxis }
                            axisY: ValuesAxis {
                                titleText: "Number of Users"
                                min: 0
                            }
                            
                            BarSet {
                                id: totalUsersSet
                                label: "Total Users"
                                color: "#2196F3"
                            }
                            
                            BarSet {
                                id: activeUsersSet
                                label: "Active Users"
                                color: "#4CAF50"
                            }
                        }
                    }
                }
            }
            
            // Top Active Borrowers
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 500
                title: "Top 20 Most Active Borrowers"
                subtitle: "Power users of the library"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadTopBorrowers()
                onExportClicked: console.log("Export top borrowers")
                
                contentItem: ChartView {
                    id: topBorrowersChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    HorizontalBarSeries {
                        id: topBorrowersSeries
                        axisY: BarCategoryAxis { id: borrowerAxis }
                        axisX: ValuesAxis {
                            titleText: "Number of Borrows"
                            min: 0
                        }
                        
                        BarSet {
                            id: borrowerBarSet
                            label: "Borrows"
                            color: "#9C27B0"
                        }
                    }
                }
            }
            
            // New User Registrations
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "New User Registrations Over Time"
                subtitle: "User growth trends"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadNewRegistrations()
                onExportClicked: console.log("Export new registrations")
                
                contentItem: ChartView {
                    id: newRegistrationsChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    LineSeries {
                        id: registrationsSeries
                        name: "New Users"
                        color: "#00BCD4"
                        width: 3
                        
                        axisX: DateTimeAxis {
                            id: registrationsDateAxis
                            format: "MMM yyyy"
                            titleText: "Month"
                        }
                        axisY: ValuesAxis {
                            id: registrationsValueAxis
                            titleText: "New Registrations"
                            min: 0
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
        loadUserEngagementData()
    }
    
    function loadUserTypes() {
        var types = reportsManager.getAvailableUserTypes();

        for (var i = 0; i < types.length; i++) {
            var map = types[i];
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
    
    function getStatusFilter() {
        return statusCombo.currentIndex === 0 ? "all" : statusCombo.currentText.toLowerCase()
    }
    
    function loadUserEngagementData() {
        loadEngagementStats()
        loadUserDistribution()
        loadTopBorrowers()
        loadNewRegistrations()
        loadBorrowingActivity()
    }
    
    function loadEngagementStats() {
        var stats = reportsManager.getUserEngagementStats()
        
        totalUsersCard.value = stats.totalUsers || "0"
        activeUsersCard.value = stats.activeUsers || "0"
        inactiveUsersCard.value = stats.inactiveUsers || "0"
        newUsersCard.value = stats.newUsersThisMonth || "0"
        avgBooksPerUserCard.value = (stats.averageBooksPerUser || 0).toFixed(1)
    }
    
    function loadUserDistribution() {
        userDistributionSeries.clear()
        
        var data = reportsManager.getUserDistributionByType()
        var colors = ["#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#F44336"]
        
        for (var i = 0; i < data.length; i++) {
            var slice = userDistributionSeries.append(data[i].label, data[i].value)
            slice.color = colors[i % colors.length]
            slice.labelVisible = true
        }
    }
    
    function loadTopBorrowers() {
        borrowerBarSet.remove(0, borrowerBarSet.count)
        
        var data = reportsManager.getTopActiveBorrowers(20, getUserTypeFilter())
        var categories = []
        
        for (var i = data.length - 1; i >= 0; i--) {
            var name = data[i].label
            if (name.length > 25) {
                name = name.substring(0, 22) + "..."
            }
            categories.push(name)
            borrowerBarSet.append(data[i].value)
        }
        
        borrowerAxis.categories = categories
    }
    
    function loadNewRegistrations() {
        registrationsSeries.clear()
        
        var data = reportsManager.getNewUserRegistrations(getDateRangeValue())
        
        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01") // Add day for valid date
            registrationsSeries.append(date.getTime(), data[i].yValue)
        }
    }
    
    function loadBorrowingActivity() {
        totalUsersSet.remove(0, totalUsersSet.count)
        activeUsersSet.remove(0, activeUsersSet.count)
        
        var data = reportsManager.getBorrowingActivityByUserCategory()
        var categories = []
        
        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].user_role)
            totalUsersSet.append(data[i].total_users)
            activeUsersSet.append(data[i].active_users)
        }
        
        categoryAxis.categories = categories
    }
}
