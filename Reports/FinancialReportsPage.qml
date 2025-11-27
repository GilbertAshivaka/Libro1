import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: financialReportsPage
    title: "Financial Reports"
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
                title: "💰 Financial Reports"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Monitor fines, losses, and financial metrics"
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
                            model: ["Current Month", "Last 3 Months", "Last 6 Months", "Last 12 Months", "Current Year", "All Time"]
                            currentIndex: 0
                            onActivated: loadFinancialData()
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
                            onActivated: loadFinancialData()
                        }
                        
                        Label {
                            text: "Payment Status:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: paymentStatusCombo
                            Layout.preferredWidth: 150
                            model: ["All", "Paid", "Partially Paid", "Unpaid"]
                            currentIndex: 0
                            onActivated: loadFinancialData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadFinancialData()
                        }
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export financial report")
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
                    columns: 6
                    rowSpacing: 15
                    columnSpacing: 15
                    
                    StatCard {
                        id: finesGeneratedCard
                        Layout.fillWidth: true
                        title: "Fines Generated"
                        value: "$0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: finesCollectedCard
                        Layout.fillWidth: true
                        title: "Fines Collected"
                        value: "$0"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: outstandingFinesCard
                        Layout.fillWidth: true
                        title: "Outstanding"
                        value: "$0"
                        accentColor: "#F44336"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: lostBookCostCard
                        Layout.fillWidth: true
                        title: "Lost Book Cost"
                        value: "$0"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: collectionRateCard
                        Layout.fillWidth: true
                        title: "Collection Rate"
                        value: "0"
                        unit: "%"
                        accentColor: "#2196F3"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: avgFineCard
                        Layout.fillWidth: true
                        title: "Avg Fine"
                        value: "$0"
                        accentColor: "#00BCD4"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // Fine Collection Over Time
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Fine Collection Over Time"
                subtitle: "Revenue from fines collected monthly"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadFineCollectionOverTime()
                onExportClicked: console.log("Export fine collection chart")
                
                contentItem: ChartView {
                    id: fineCollectionChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    LineSeries {
                        id: fineCollectionSeries
                        name: "Collected"
                        color: "#4CAF50"
                        width: 3
                        
                        axisX: DateTimeAxis {
                            id: fineCollectionDateAxis
                            format: "MMM yyyy"
                            titleText: "Month"
                        }
                        axisY: ValuesAxis {
                            id: fineCollectionValueAxis
                            titleText: "Amount ($)"
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
                
                // Fine Amount vs Paid
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Fine Amount vs Fine Paid"
                    subtitle: "Monthly comparison of generated vs collected fines"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadFineAmountVsPaid()
                    onExportClicked: console.log("Export amount vs paid chart")
                    
                    contentItem: ChartView {
                        id: amountVsPaidChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignBottom
                        backgroundColor: "transparent"
                        
                        BarSeries {
                            id: amountVsPaidSeries
                            axisX: BarCategoryAxis { id: amountVsPaidMonthAxis }
                            axisY: ValuesAxis {
                                titleText: "Amount ($)"
                                min: 0
                            }
                            
                            BarSet {
                                id: generatedSet
                                label: "Generated"
                                color: "#FF9800"
                            }
                            
                            BarSet {
                                id: paidSet
                                label: "Paid"
                                color: "#4CAF50"
                            }
                        }
                    }
                }
                
                // Fine Payment Status
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Fine Payment Status"
                    subtitle: "Distribution of payment statuses"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadPaymentStatus()
                    onExportClicked: console.log("Export payment status chart")
                    
                    contentItem: ChartView {
                        id: paymentStatusChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"
                        
                        PieSeries {
                            id: paymentStatusSeries
                        }
                    }
                }
            }
            
            // Lost Book Costs
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Lost Book Costs by Month"
                subtitle: "Financial impact of lost books over time"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadLostBookCosts()
                onExportClicked: console.log("Export lost book costs")
                
                contentItem: ChartView {
                    id: lostBookCostsChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    BarSeries {
                        id: lostBookCostsSeries
                        axisX: BarCategoryAxis { id: lostBookMonthAxis }
                        axisY: ValuesAxis {
                            titleText: "Replacement Cost ($)"
                            min: 0
                        }
                        
                        BarSet {
                            id: lostBookCostsSet
                            label: "Cost"
                            color: "#F44336"
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
        loadFinancialData()
    }
    
    function loadUserTypes() {
        var types = reportsManager.getAvailableUserTypes();

        for (var i = 0; i < types.length; i++) {
            var map = types[i];
            userTypeModel.append({ text: map.userType || map.type || map.name || map.label || map.value || "" });
        }
    }
    
    function getDateRangeValue() {
        var ranges = ["currentMonth", "last3months", "last6months", "last12months", "currentYear", "all"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getUserTypeFilter() {
        return userTypeCombo.currentIndex === 0 ? "all" : userTypeCombo.currentText
    }
    
    function getPaymentStatusFilter() {
        return paymentStatusCombo.currentIndex === 0 ? "all" : paymentStatusCombo.currentText.toLowerCase()
    }
    
    function loadFinancialData() {
        loadFinancialStats()
        loadFineCollectionOverTime()
        loadFineAmountVsPaid()
        loadPaymentStatus()
        loadLostBookCosts()
    }
    
    function loadFinancialStats() {
        var stats = reportsManager.getFinancialStats(getDateRangeValue())
        
        finesGeneratedCard.value = "$" + (stats.totalFinesGenerated || 0).toFixed(2)
        finesCollectedCard.value = "$" + (stats.totalFinesCollected || 0).toFixed(2)
        outstandingFinesCard.value = "$" + (stats.outstandingFines || 0).toFixed(2)
        lostBookCostCard.value = "$" + (stats.lostBooksReplacementCost || 0).toFixed(2)
        collectionRateCard.value = (stats.fineCollectionRate || 0).toFixed(1)
        avgFineCard.value = "$" + (stats.averageFinePerOverdue || 0).toFixed(2)
    }
    
    function loadFineCollectionOverTime() {
        fineCollectionSeries.clear()
        
        var data = reportsManager.getFineCollectionOverTime(getDateRangeValue())
        
        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            fineCollectionSeries.append(date.getTime(), data[i].yValue)
        }
    }
    
    function loadFineAmountVsPaid() {
        generatedSet.remove(0, generatedSet.count)
        paidSet.remove(0, paidSet.count)
        
        var data = reportsManager.getFineAmountVsPaid(getDateRangeValue())
        var categories = []
        
        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].month)
            generatedSet.append(data[i].generated || 0)
            paidSet.append(data[i].paid || 0)
        }
        
        amountVsPaidMonthAxis.categories = categories
    }
    
    function loadPaymentStatus() {
        paymentStatusSeries.clear()
        
        var data = reportsManager.getFinePaymentStatus()
        var colors = {
            "No Fine": "#9E9E9E",
            "Fully Paid": "#4CAF50",
            "Partially Paid": "#FF9800",
            "Unpaid": "#F44336"
        }
        
        for (var i = 0; i < data.length; i++) {
            var slice = paymentStatusSeries.append(data[i].label, data[i].value)
            if (colors[data[i].label]) {
                slice.color = colors[data[i].label]
            }
            slice.labelVisible = true
        }
    }
    
    function loadLostBookCosts() {
        lostBookCostsSet.remove(0, lostBookCostsSet.count)
        
        var data = reportsManager.getLostBookCostsByMonth(getDateRangeValue())
        var categories = []
        
        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].category)
            lostBookCostsSet.append(data[i].value || 0)
        }
        
        lostBookMonthAxis.categories = categories
    }
}
