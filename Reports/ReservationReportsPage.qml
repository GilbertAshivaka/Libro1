import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15
import QtQuick.Dialogs

Page {
    id: reservationReportsPage
    title: "Reservation Analytics"
    anchors.fill: parent

    property string statusText: ""
    
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
        contentHeight: captureContent.height

        Item {
            id: captureContent
            width: parent.width
            height: columnLayout.implicitHeight

            ColumnLayout {
                id: columnLayout
                width: parent.width
                spacing: 20

                Item { height: 10 }

                // Header Section
                GroupBox {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    title: "📖 Reservation Analytics"

                    ColumnLayout {
                        width: parent.width
                        spacing: 15

                        Label {
                            text: "Track book demand and reservation efficiency"
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
                                onActivated: loadReservationData()
                            }

                            Label {
                                text: "Status:"
                                font.bold: true
                            }

                            ComboBox {
                                id: statusCombo
                                Layout.preferredWidth: 150
                                model: ["All", "Pending", "Fulfilled", "Expired", "Cancelled"]
                                currentIndex: 0
                                onActivated: loadReservationData()
                            }

                            Label {
                                text: "Source:"
                                font.bold: true
                            }

                            ComboBox {
                                id: sourceCombo
                                Layout.preferredWidth: 150
                                model: ["All", "Online", "In-person"]
                                currentIndex: 0
                                onActivated: loadReservationData()
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: "⟳ Refresh"
                                onClicked: loadReservationData()
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
                            id: activeReservationsCard
                            Layout.fillWidth: true
                            title: "Active Reservations"
                            value: "0"
                            accentColor: "#2196F3"
                            isLoading: reportsManager.isLoading
                        }

                        StatCard {
                            id: avgWaitTimeCard
                            Layout.fillWidth: true
                            title: "Avg Wait Time"
                            value: "0"
                            unit: "days"
                            accentColor: "#FF9800"
                            isLoading: reportsManager.isLoading
                        }

                        StatCard {
                            id: fulfillmentRateCard
                            Layout.fillWidth: true
                            title: "Fulfillment Rate"
                            value: "0"
                            unit: "%"
                            accentColor: "#4CAF50"
                            isLoading: reportsManager.isLoading
                        }

                        StatCard {
                            id: expiredReservationsCard
                            Layout.fillWidth: true
                            title: "Expired"
                            value: "0"
                            accentColor: "#F44336"
                            isLoading: reportsManager.isLoading
                        }

                        StatCard {
                            id: booksPendingCard
                            Layout.fillWidth: true
                            title: "Books w/ Pending"
                            value: "0"
                            accentColor: "#9C27B0"
                            isLoading: reportsManager.isLoading
                        }
                    }
                }

                // Reservations Over Time
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    Layout.preferredHeight: 400
                    title: "Reservations Over Time"
                    subtitle: "Demand patterns over time"
                    isLoading: reportsManager.isLoading

                    onRefreshClicked: loadReservationsOverTime()
                    onExportClicked: exportChart(reservationsOverTimeSection())

                    contentItem: ChartView {
                        id: reservationsTimeChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"

                        LineSeries {
                            id: reservationsTimeSeries
                            name: "Reservations"
                            color: "#2196F3"
                            width: 3

                            axisX: DateTimeAxis {
                                id: reservationsDateAxis
                                format: "MMM yyyy"
                                titleText: "Month"
                                min: new Date(new Date().getFullYear() , 0, 1)  // Start of this year
                                max: new Date()  // Today
                            }
                            axisY: ValuesAxis {
                                id: reservationsValueAxis
                                titleText: "Reservations"
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

                    // Reservation Status Distribution
                    ChartContainer {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        title: "Reservation Status Distribution"
                        subtitle: "Breakdown of reservation statuses"
                        isLoading: reportsManager.isLoading

                        onRefreshClicked: loadStatusDistribution()
                        onExportClicked: exportChart(statusDistributionSection())

                        contentItem: ChartView {
                            id: statusDistributionChart
                            anchors.fill: parent
                            antialiasing: true
                            legend.alignment: Qt.AlignRight
                            backgroundColor: "transparent"

                            PieSeries {
                                id: statusDistributionSeries
                            }
                        }
                    }

                    // Reservation Source
                    ChartContainer {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        title: "Reservation Source"
                        subtitle: "Online vs In-person reservations"
                        isLoading: reportsManager.isLoading

                        onRefreshClicked: loadReservationSource()
                        onExportClicked: exportChart(reservationSourceSection())

                        contentItem: ChartView {
                            id: sourceChart
                            anchors.fill: parent
                            antialiasing: true
                            legend.alignment: Qt.AlignRight
                            backgroundColor: "transparent"

                            PieSeries {
                                id: sourceSeries
                                holeSize: 0.4
                            }
                        }
                    }
                }

                // Most Reserved Books
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.margins: 20
                    Layout.preferredHeight: 500
                    title: "Most Reserved Books"
                    subtitle: "Top 20 high-demand books that may need more copies"
                    isLoading: reportsManager.isLoading

                    onRefreshClicked: loadMostReservedBooks()
                    onExportClicked: exportChart(mostReservedBooksSection())

                    contentItem: ChartView {
                        id: mostReservedChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"

                        HorizontalBarSeries {
                            id: mostReservedSeries
                            axisY: BarCategoryAxis { id: bookAxis }
                            axisX: ValuesAxis {
                                id: mostReservedAxis
                                titleText: "Reservation Count"
                                min: 0
                                max: 100
                            }

                            BarSet {
                                id: reservedBarSet
                                label: "Reservations"
                                color: "#00BCD4"
                            }
                        }
                    }
                }

                Item { height: 20 }
            }
        }
    }

    Component.onCompleted: {
        loadReservationData()
    }
    
    function getDateRangeValue() {
        var ranges = ["all", "last30days", "last3months", "last6months", "last12months"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getStatusFilter() {
        return statusCombo.currentIndex === 0 ? "all" : statusCombo.currentText.toLowerCase()
    }
    
    function getSourceFilter() {
        return sourceCombo.currentIndex === 0 ? "all" : sourceCombo.currentText.toLowerCase()
    }
    
    function loadReservationData() {
        loadReservationStats()
        loadReservationsOverTime()
        loadMostReservedBooks()
        loadStatusDistribution()
        loadReservationSource()
    }
    
    function loadReservationStats() {
        var stats = reportsManager.getReservationStats()
        
        activeReservationsCard.value = stats.activeReservations || "0"
        avgWaitTimeCard.value = (stats.averageWaitTime || 0).toFixed(1)
        fulfillmentRateCard.value = (stats.fulfillmentRate || 0).toFixed(1)
        expiredReservationsCard.value = stats.expiredReservations || "0"
        booksPendingCard.value = stats.booksWithPendingReservations || "0"
    }
    
    // function loadReservationsOverTime() {
    //     reservationsTimeSeries.clear()
        
    //     var data = reportsManager.getReservationsOverTime(getDateRangeValue())
        
    //     for (var i = 0; i < data.length; i++) {
    //         var date = new Date(data[i].xValue + "-01")
    //         reservationsTimeSeries.append(date.getTime(), data[i].yValue)
    //     }
    // }

    function loadReservationsOverTime() {
        reservationsTimeSeries.clear()

        var data = reportsManager.getReservationsOverTime(getDateRangeValue())
        var maxValue = 0
        var minDate = null
        var maxDate = null

        for (var i = 0; i < data.length; i++) {
            var dateStr = data[i].xValue  // "2025-11-01"
            var date = new Date(dateStr + "T12:00:00")
            var timestamp = date.getTime()

            reservationsTimeSeries.append(timestamp, data[i].yValue)

            // Track min/max dates from actual data
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
        reservationsValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis to actual data range with small padding
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            // Add 1 month padding on each side for better visualization
            minDateObj.setMonth(minDateObj.getMonth() - 1)
            maxDateObj.setMonth(maxDateObj.getMonth() + 1)

            reservationsDateAxis.min = minDateObj
            reservationsDateAxis.max = maxDateObj

            console.log("Date range set:", minDateObj.toString(), "to", maxDateObj.toString())
        }
    }

    function loadMostReservedBooks() {
        reservedBarSet.remove(0, reservedBarSet.count)
        
        var data = reportsManager.getMostReservedBooks(20)
        var categories = []
        var maxValue = 0
        
        for (var i = data.length - 1; i >= 0; i--) {
            var title = data[i].label
            if (title.length > 30) {
                title = title.substring(0, 27) + "..."
            }
            categories.push(title)
            reservedBarSet.append(data[i].value)

            if(data[i].value > maxValue){
                maxValue = data[i].value
            }
        }
        
        bookAxis.categories = categories

        // Set the Y-axis max to slightly above the max value (e.g., 10% padding)
        mostReservedAxis.max = Math.ceil(maxValue * 1.1)
    }
    
    function loadStatusDistribution() {
        statusDistributionSeries.clear()
        
        var data = reportsManager.getReservationStatusDistribution()
        var colors = {
            "pending": "#FF9800",
            "fulfilled": "#4CAF50",
            "expired": "#F44336",
            "cancelled": "#9E9E9E"
        }
        
        for (var i = 0; i < data.length; i++) {
            var slice = statusDistributionSeries.append(data[i].label, data[i].value)
            if (colors[data[i].label]) {
                slice.color = colors[data[i].label]
            }
            slice.labelVisible = true
        }
    }
    
    function loadReservationSource() {
        sourceSeries.clear()
        
        var data = reportsManager.getReservationSource()
        var colors = {
            "online": "#2196F3",
            "in-person": "#4CAF50"
        }
        
        for (var i = 0; i < data.length; i++) {
            var slice = sourceSeries.append(data[i].label, data[i].value)
            if (colors[data[i].label.toLowerCase()]) {
                slice.color = colors[data[i].label.toLowerCase()]
            }
            slice.labelVisible = true
        }
    }

    // ========================================================================
    // Report export / print
    // ========================================================================

    function filtersList() {
        return [
            { label: "Date Range", value: dateRangeCombo.currentText },
            { label: "Status",     value: statusCombo.currentText },
            { label: "Source",     value: sourceCombo.currentText }
        ]
    }

    function metricsSection() {
        var s = reportsManager.getReservationStats()
        return {
            title: "Key Metrics", kind: "metrics",
            data: [
                { label: "Active Reservations", value: String(s.activeReservations || 0) },
                { label: "Avg Wait Time",       value: (s.averageWaitTime || 0).toFixed(1), unit: "days" },
                { label: "Fulfillment Rate",    value: (s.fulfillmentRate || 0).toFixed(1), unit: "%" },
                { label: "Expired",             value: String(s.expiredReservations || 0) },
                { label: "Books w/ Pending",    value: String(s.booksWithPendingReservations || 0) }
            ]
        }
    }

    function reservationsOverTimeSection() {
        var data = reportsManager.getReservationsOverTime(getDateRangeValue())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].xValue)
            values.push(data[i].yValue)
        }
        return {
            title: "Reservations Over Time",
            subtitle: "Demand patterns over time",
            kind: "chart", chartType: "line",
            labels: labels,
            datasets: [ { label: "Reservations", color: "#2196F3", data: values } ]
        }
    }

    function statusDistributionSection() {
        var data = reportsManager.getReservationStatusDistribution()
        var colorMap = {
            "pending": "#FF9800", "fulfilled": "#4CAF50", "expired": "#F44336", "cancelled": "#9E9E9E"
        }
        var labels = [], values = [], colors = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
            colors.push(colorMap[String(data[i].label).toLowerCase()] || "#607D8B")
        }
        return {
            title: "Reservation Status Distribution",
            subtitle: "Breakdown of reservation statuses",
            kind: "chart", chartType: "pie",
            labels: labels,
            datasets: [ { label: "Reservations", data: values, colors: colors } ]
        }
    }

    function reservationSourceSection() {
        var data = reportsManager.getReservationSource()
        var colorMap = { "online": "#2196F3", "in-person": "#4CAF50" }
        var labels = [], values = [], colors = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
            colors.push(colorMap[String(data[i].label).toLowerCase()] || "#607D8B")
        }
        return {
            title: "Reservation Source",
            subtitle: "Online vs In-person reservations",
            kind: "chart", chartType: "doughnut",
            labels: labels,
            datasets: [ { label: "Source", data: values, colors: colors } ]
        }
    }

    function mostReservedBooksSection() {
        var data = reportsManager.getMostReservedBooks(20)
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            var title = data[i].label
            if (title.length > 30)
                title = title.substring(0, 27) + "..."
            labels.push(title)
            values.push(data[i].value)
        }
        return {
            title: "Most Reserved Books",
            subtitle: "Top 20 high-demand books that may need more copies",
            kind: "chart", chartType: "horizontalBar",
            labels: labels,
            datasets: [ { label: "Reservations", color: "#00BCD4", data: values } ]
        }
    }

    function buildReportPayload() {
        return {
            title: "Reservation Analytics",
            subtitle: "Track book demand and reservation efficiency",
            filters: filtersList(),
            sections: [
                metricsSection(),
                reservationsOverTimeSection(),
                statusDistributionSection(),
                reservationSourceSection(),
                mostReservedBooksSection()
            ]
        }
    }

    function exportChart(section) {
        reportExporter.exportToPdf({
            title: "Reservation Analytics — " + section.title,
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
