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
                onExportClicked: exportChart(fineCollectionSection())
                
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
                            min: new Date(new Date().getFullYear() , 0, 1) //start of the year
                            max: new Date() //today
                        }
                        axisY: ValuesAxis {
                            id: fineCollectionValueAxis
                            titleText: "Amount ($)"
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
                
                // Fine Amount vs Paid
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Fine Amount vs Fine Paid"
                    subtitle: "Monthly comparison of generated vs collected fines"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadFineAmountVsPaid()
                    onExportClicked: exportChart(amountVsPaidSection())
                    
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
                                id: amoutVsPaidMonthValuesAxis
                                titleText: "Amount ($)"
                                min: 0
                                max: 10
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
                    onExportClicked: exportChart(paymentStatusSection())
                    
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
                onExportClicked: exportChart(lostBookCostsSection())
                
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
                            id: replacementCostAxis
                            titleText: "Replacement Cost ($)"
                            min: 0
                            max: 10
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
        var minDate = null
        var maxDate = null
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            var date = new Date(data[i].xValue + "-01")
            var timestamp = date.getTime()
            fineCollectionSeries.append(timestamp, data[i].yValue)

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
        fineCollectionValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis to actual data range with 1 month padding on each side
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            // Add 1 month padding on each side
            minDateObj.setMonth(minDateObj.getMonth() - 1)
            maxDateObj.setMonth(maxDateObj.getMonth() + 1)

            fineCollectionDateAxis.min = minDateObj
            fineCollectionDateAxis.max = maxDateObj
        }
    }

    function loadFineAmountVsPaid() {
        generatedSet.remove(0, generatedSet.count)
        paidSet.remove(0, paidSet.count)

        var data = reportsManager.getFineAmountVsPaid(getDateRangeValue())
        var categories = []
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].month)

            var generatedVal = data[i].generated || 0
            var paidVal = data[i].paid || 0

            generatedSet.append(generatedVal)
            paidSet.append(paidVal)

            // Track the maximum between both values
            if (generatedVal > maxValue) {
                maxValue = generatedVal
            }
            if (paidVal > maxValue) {
                maxValue = paidVal
            }
        }

        amountVsPaidMonthAxis.categories = categories

        // Set Y-axis max dynamically with 10% padding
        amoutVsPaidMonthValuesAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
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
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].category)

            var value = data[i].value || 0
            lostBookCostsSet.append(value)

            if (value > maxValue) {
                maxValue = value
            }
        }

        lostBookMonthAxis.categories = categories

        // Set Y-axis max dynamically with 10% padding
        replacementCostAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    // ========================================================================
    // Report export / print
    //
    // Each section is built from the same reportsManager getters used on screen
    // (results are cached, so this is cheap and respects the current filters).
    // The section helpers are reused for both whole-page and per-chart export.
    // ========================================================================

    function filtersList() {
        return [
            { label: "Date Range",     value: dateRangeCombo.currentText },
            { label: "User Type",      value: userTypeCombo.currentText },
            { label: "Payment Status", value: paymentStatusCombo.currentText }
        ]
    }

    function metricsSection() {
        var s = reportsManager.getFinancialStats(getDateRangeValue())
        return {
            title: "Key Metrics",
            kind: "metrics",
            data: [
                { label: "Fines Generated", value: "$" + (s.totalFinesGenerated || 0).toFixed(2) },
                { label: "Fines Collected", value: "$" + (s.totalFinesCollected || 0).toFixed(2) },
                { label: "Outstanding",     value: "$" + (s.outstandingFines || 0).toFixed(2) },
                { label: "Lost Book Cost",  value: "$" + (s.lostBooksReplacementCost || 0).toFixed(2) },
                { label: "Collection Rate", value: (s.fineCollectionRate || 0).toFixed(1), unit: "%" },
                { label: "Avg Fine",        value: "$" + (s.averageFinePerOverdue || 0).toFixed(2) }
            ]
        }
    }

    function fineCollectionSection() {
        var data = reportsManager.getFineCollectionOverTime(getDateRangeValue())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].xValue)
            values.push(data[i].yValue)
        }
        return {
            title: "Fine Collection Over Time",
            subtitle: "Revenue from fines collected monthly",
            kind: "chart", chartType: "line",
            labels: labels,
            datasets: [ { label: "Collected", color: "#4CAF50", data: values } ]
        }
    }

    function amountVsPaidSection() {
        var data = reportsManager.getFineAmountVsPaid(getDateRangeValue())
        var labels = [], generated = [], paid = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].month)
            generated.push(data[i].generated || 0)
            paid.push(data[i].paid || 0)
        }
        return {
            title: "Fine Amount vs Fine Paid",
            subtitle: "Monthly comparison of generated vs collected fines",
            kind: "chart", chartType: "bar",
            labels: labels,
            datasets: [
                { label: "Generated", color: "#FF9800", data: generated },
                { label: "Paid",      color: "#4CAF50", data: paid }
            ]
        }
    }

    function paymentStatusSection() {
        var data = reportsManager.getFinePaymentStatus()
        var colorMap = {
            "No Fine": "#9E9E9E", "Fully Paid": "#4CAF50",
            "Partially Paid": "#FF9800", "Unpaid": "#F44336"
        }
        var labels = [], values = [], colors = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
            colors.push(colorMap[data[i].label] || "#2196F3")
        }
        return {
            title: "Fine Payment Status",
            subtitle: "Distribution of payment statuses",
            kind: "chart", chartType: "pie",
            labels: labels,
            datasets: [ { label: "Payments", data: values, colors: colors } ]
        }
    }

    function lostBookCostsSection() {
        var data = reportsManager.getLostBookCostsByMonth(getDateRangeValue())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].category)
            values.push(data[i].value || 0)
        }
        return {
            title: "Lost Book Costs by Month",
            subtitle: "Financial impact of lost books over time",
            kind: "chart", chartType: "bar",
            labels: labels,
            datasets: [ { label: "Cost", color: "#F44336", data: values } ]
        }
    }

    // Whole-page report payload
    function buildReportPayload() {
        return {
            title: "Financial Reports",
            subtitle: "Monitor fines, losses, and financial metrics",
            filters: filtersList(),
            sections: [
                metricsSection(),
                fineCollectionSection(),
                amountVsPaidSection(),
                paymentStatusSection(),
                lostBookCostsSection()
            ]
        }
    }

    // Single-chart export (PDF) reusing the shared section helpers
    function exportChart(section) {
        reportExporter.exportToPdf({
            title: "Financial Reports — " + section.title,
            filters: filtersList(),
            sections: [ section ]
        })
    }

    // Lightweight user feedback on completion
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
