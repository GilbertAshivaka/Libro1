import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: digitalMaterialsPage
    title: "Digital Materials & Equipment"
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
                title: "💻 Digital Materials & Equipment"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Monitor non-book resources and digital material usage"
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
                            onActivated: loadDigitalMaterialsData()
                        }
                        
                        Label {
                            text: "Item Type:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: itemTypeCombo
                            Layout.preferredWidth: 150
                            model: ["All Types", "E-Reader", "Tablet", "Laptop", "CD/DVD", "Other"]
                            currentIndex: 0
                            onActivated: loadDigitalMaterialsData()
                        }
                        
                        Label {
                            text: "Status:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: statusCombo
                            Layout.preferredWidth: 150
                            model: ["All", "Available", "Borrowed"]
                            currentIndex: 0
                            onActivated: loadDigitalMaterialsData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadDigitalMaterialsData()
                        }
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export digital materials report")
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
                        id: totalItemsCard
                        Layout.fillWidth: true
                        title: "Total Items"
                        value: "0"
                        accentColor: "#3F51B5"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: onLoanCard
                        Layout.fillWidth: true
                        title: "Currently On Loan"
                        value: "0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: popularTypeCard
                        Layout.fillWidth: true
                        title: "Most Popular"
                        value: "N/A"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: avgLoanDurationCard
                        Layout.fillWidth: true
                        title: "Avg Loan Duration"
                        value: "0"
                        unit: "days"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: utilizationRateCard
                        Layout.fillWidth: true
                        title: "Utilization Rate"
                        value: "0"
                        unit: "%"
                        accentColor: "#00BCD4"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20
                
                // Digital Materials by Type
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Digital Materials by Type"
                    subtitle: "Distribution of resource types"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadMaterialsByType()
                    onExportClicked: console.log("Export materials by type")
                    
                    contentItem: ChartView {
                        id: materialsByTypeChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"
                        
                        PieSeries {
                            id: materialsByTypeSeries
                        }
                    }
                }
                
                // Available vs Borrowed
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Available vs Borrowed"
                    subtitle: "Utilization and availability"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadAvailableVsBorrowed()
                    onExportClicked: console.log("Export available vs borrowed")
                    
                    contentItem: ChartView {
                        id: availableVsBorrowedChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignBottom
                        backgroundColor: "transparent"
                        
                        BarSeries {
                            id: availableVsBorrowedSeries
                            axisX: BarCategoryAxis { id: itemTypeAxis }
                            axisY: ValuesAxis {
                                id: availableVsBorrowedAxis
                                titleText: "Quantity"
                                min: 0
                                max: 100
                            }
                            
                            BarSet {
                                id: totalSet
                                label: "Total"
                                color: "#2196F3"
                            }
                            
                            BarSet {
                                id: borrowedSet
                                label: "Borrowed"
                                color: "#FF9800"
                            }
                        }
                    }
                }
            }
            
            // Digital Material Loans Over Time
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Digital Material Loans Over Time"
                subtitle: "Usage trends for digital resources"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadLoansOverTime()
                onExportClicked: console.log("Export loans trend")
                
                contentItem: ChartView {
                    id: loansTimeChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    LineSeries {
                        id: loansTimeSeries
                        name: "Loans"
                        color: "#3F51B5"
                        width: 3
                        
                        axisX: DateTimeAxis {
                            id: loansDateAxis
                            format: "MMM yyyy"
                            titleText: "Month"
                            min: new Date( new Date().getFullYear() , 0, 1)
                            max:  new Date()
                        }
                        axisY: ValuesAxis {
                            id: loansValueAxis
                            titleText: "Loans"
                            min: 0
                            max: 100
                        }
                    }
                }
            }
            
            // Most Borrowed Digital Items
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 500
                title: "Most Borrowed Digital Items"
                subtitle: "Top 15 popular digital resources"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadMostBorrowedDigital()
                onExportClicked: console.log("Export most borrowed digital")
                
                contentItem: ChartView {
                    id: mostBorrowedChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    HorizontalBarSeries {
                        id: mostBorrowedSeries
                        axisY: BarCategoryAxis { id: digitalItemAxis }
                        axisX: ValuesAxis {
                            id: digitalBorrowedAxis
                            titleText: "Loan Count"
                            min: 0
                            max: 100
                        }
                        
                        BarSet {
                            id: digitalBorrowedSet
                            label: "Borrows"
                            color: "#00BCD4"
                        }
                    }
                }
            }
            
            Item { height: 20 }
        }
    }
    
    Component.onCompleted: {
        loadDigitalMaterialsData()
    }
    
    function getDateRangeValue() {
        var ranges = ["all", "last30days", "last3months", "last6months", "last12months"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getItemTypeFilter() {
        return itemTypeCombo.currentIndex === 0 ? "all" : itemTypeCombo.currentText
    }
    
    function getStatusFilter() {
        return statusCombo.currentIndex === 0 ? "all" : statusCombo.currentText
    }
    
    function loadDigitalMaterialsData() {
        loadDigitalMaterialsStats()
        loadMaterialsByType()
        loadMostBorrowedDigital()
        loadLoansOverTime()
        loadAvailableVsBorrowed()
    }
    
    function loadDigitalMaterialsStats() {
        var stats = reportsManager.getDigitalMaterialsStats()
        
        totalItemsCard.value = stats.totalItems || "0"
        onLoanCard.value = stats.currentlyOnLoan || "0"
        popularTypeCard.value = stats.mostPopularType || "N/A"
        avgLoanDurationCard.value = (stats.averageLoanDuration || 0).toFixed(1)
        utilizationRateCard.value = (stats.utilizationRate || 0).toFixed(1)
    }
    
    function loadMaterialsByType() {
        materialsByTypeSeries.clear()

        var data = reportsManager.getDigitalMaterialsByType()
        var colors = ["#3F51B5", "#2196F3", "#00BCD4", "#009688", "#4CAF50"]

        for (var i = 0; i < data.length; i++) {
            var slice = materialsByTypeSeries.append(data[i].label, data[i].value)
            slice.color = colors[i % colors.length]
            slice.labelVisible = true
        }
    }

    function loadMostBorrowedDigital() {
        digitalBorrowedSet.remove(0, digitalBorrowedSet.count)

        var data = reportsManager.getMostBorrowedDigitalItems(15)
        var categories = []
        var maxValue = 0

        for (var i = data.length - 1; i >= 0; i--) {
            var name = data[i].label
            if (name.length > 25) {
                name = name.substring(0, 22) + "..."
            }
            categories.push(name)
            digitalBorrowedSet.append(data[i].value)

            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        digitalItemAxis.categories = categories

        // Set X-axis max dynamically with 10% padding
        digitalBorrowedAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    function loadLoansOverTime() {
        loansTimeSeries.clear()

        var data = reportsManager.getDigitalMaterialLoansOverTime(getDateRangeValue())
        var minDate = null
        var maxDate = null
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            var timestamp = date.getTime()
            loansTimeSeries.append(timestamp, data[i].yValue)

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
        loansValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis to actual data range with 1 month padding on each side
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            // Add 1 month padding on each side
            minDateObj.setMonth(minDateObj.getMonth() - 1)
            maxDateObj.setMonth(maxDateObj.getMonth() + 1)

            loansDateAxis.min = minDateObj
            loansDateAxis.max = maxDateObj
        }
    }

    function loadAvailableVsBorrowed() {
        totalSet.remove(0, totalSet.count)
        borrowedSet.remove(0, borrowedSet.count)

        var data = reportsManager.getDigitalMaterialsAvailableVsBorrowed()
        var categories = []
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].ItemType)

            var totalVal = data[i].total || 0
            var borrowedVal = data[i].borrowed || 0

            totalSet.append(totalVal)
            borrowedSet.append(borrowedVal)

            // Track the maximum between both values
            if (totalVal > maxValue) {
                maxValue = totalVal
            }
            if (borrowedVal > maxValue) {
                maxValue = borrowedVal
            }
        }

        itemTypeAxis.categories = categories

        // Set Y-axis max dynamically with 10% padding
        availableVsBorrowedAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }
}
