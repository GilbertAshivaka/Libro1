import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: circulationReportsPage
    title: "Circulation Analytics"
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
                title: "🔄 Circulation Analytics"

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    Label {
                        text: "Track borrowing patterns and library usage trends"
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
                            text: "Time Period:"
                            font.bold: true
                        }

                        ComboBox {
                            id: dateRangeCombo
                            Layout.preferredWidth: 200
                            model: ["Last 7 Days", "Last 30 Days", "Last 3 Months", "Last 6 Months", "Last 12 Months"]
                            currentIndex: 1
                            onActivated: loadCirculationData()
                        }

                        Label {
                            text: "Group By:"
                            font.bold: true
                        }

                        ComboBox {
                            id: groupByCombo
                            Layout.preferredWidth: 150
                            model: ["Day", "Week", "Month"]
                            currentIndex: 0
                            onActivated: loadBorrowingTrends()
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
                            onActivated: loadCirculationData()
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadCirculationData()
                        }

                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export circulation report")
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
                        id: currentlyOnLoanCard
                        Layout.fillWidth: true
                        title: "Currently On Loan"
                        value: "0"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: dueTodayCard
                        Layout.fillWidth: true
                        title: "Due Today"
                        value: "0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: dueThisWeekCard
                        Layout.fillWidth: true
                        title: "Due This Week"
                        value: "0"
                        accentColor: "#F44336"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: totalCirculationsCard
                        Layout.fillWidth: true
                        title: "Total Circulations"
                        value: "0"
                        accentColor: "#2196F3"
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
                }
            }

            // Borrowing Trends Line Chart
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Borrowing Trends Over Time"
                subtitle: "Daily, weekly, or monthly borrowing patterns"
                isLoading: reportsManager.isLoading

                onRefreshClicked: loadBorrowingTrends()
                onExportClicked: console.log("Export borrowing trends")

                contentItem: ChartView {
                    id: borrowingTrendsChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"

                    LineSeries {
                        id: trendsSeries
                        name: "Borrows"
                        color: "#2196F3"
                        width: 3

                        axisX: DateTimeAxis {
                            id: trendsDateAxis
                            format: "MMM dd"
                            titleText: "Date"
                            min: new Date(new Date().getFullYear() - 1, 0, 1)
                            max: new Date()
                        }
                        axisY: ValuesAxis {
                            id: trendsValueAxis
                            titleText: "Number of Borrows"
                            min: 0
                            max: 100
                        }
                    }
                }
            }

            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20

                // Borrowing by User Type Area Chart
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Borrowing by User Type"
                    subtitle: "Comparing activity across user groups"
                    isLoading: reportsManager.isLoading

                    onRefreshClicked: loadBorrowingByUserType()
                    onExportClicked: console.log("Export user type chart")

                    contentItem: ChartView {
                        id: userTypeChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignBottom
                        backgroundColor: "transparent"

                        // Dynamic series will be added in code
                        DateTimeAxis {
                            id: userTypeDateAxis
                            format: "MMM dd"
                            titleText: "Date"
                            min: new Date(new Date().getFullYear() , 0, 1)
                            max: new Date()
                        }
                        ValuesAxis {
                            id: userTypeValueAxis
                            titleText: "Borrows"
                            min: 0
                            max: 10
                        }
                    }
                }

                // Borrowing by Day of Week
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Borrowing by Day of Week"
                    subtitle: "Which days are busiest"
                    isLoading: reportsManager.isLoading

                    onRefreshClicked: loadBorrowingByDayOfWeek()
                    onExportClicked: console.log("Export day of week chart")

                    contentItem: ChartView {
                        id: dayOfWeekChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"

                        BarSeries {
                            id: dayOfWeekSeries
                            axisX: BarCategoryAxis {
                                id: dayAxis
                                categories: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                            }
                            axisY: ValuesAxis {
                                id: dayValueAxis
                                titleText: "Number of Borrows"
                                min: 0
                                max: 5
                            }

                            BarSet {
                                id: dayBarSet
                                label: "Borrows"
                                color: "#4CAF50"
                            }
                        }
                    }
                }
            }

            // Monthly Circulation (Issues vs Returns)
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Monthly Circulation - Issues vs Returns"
                subtitle: "Track circulation flow and return patterns"
                isLoading: reportsManager.isLoading

                onRefreshClicked: loadMonthlyCirculation()
                onExportClicked: console.log("Export monthly circulation")

                contentItem: ChartView {
                    id: monthlyCirculationChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.alignment: Qt.AlignBottom
                    backgroundColor: "transparent"

                    StackedBarSeries {
                        id: monthlyCirculationSeries
                        axisX: BarCategoryAxis { id: monthAxis }
                        axisY: ValuesAxis {
                            id: monthValueAxis
                            titleText: "Count"
                            min: 0
                            max: 10
                        }

                        BarSet {
                            id: issuesSet
                            label: "Issues"
                            color: "#2196F3"
                        }

                        BarSet {
                            id: returnsSet
                            label: "Returns"
                            color: "#4CAF50"
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
        loadCirculationData()
    }

    function loadUserTypes() {
        var types = reportsManager.getAvailableUserTypes();

        for (var i = 0; i < types.length; i++) {
            var map = types[i];
            userTypeModel.append({ text: map.userType || map.type || map.name || map.label || map.value || "" });
        }
    }

    function getDateRangeValue() {
        var ranges = ["last7days", "last30days", "last3months", "last6months", "last12months"]
        return ranges[dateRangeCombo.currentIndex]
    }

    function getGroupByValue() {
        var groups = ["day", "week", "month"]
        return groups[groupByCombo.currentIndex]
    }

    function getUserTypeFilter() {
        return userTypeCombo.currentIndex === 0 ? "all" : userTypeCombo.currentText
    }

    function loadCirculationData() {
        loadCirculationStats()
        loadBorrowingTrends()
        loadBorrowingByUserType()
        loadBorrowingByDayOfWeek()
        loadMonthlyCirculation()
    }

    function loadCirculationStats() {
        var stats = reportsManager.getCirculationStats(getDateRangeValue())

        currentlyOnLoanCard.value = stats.currentlyOnLoan || "0"
        dueTodayCard.value = stats.dueToday || "0"
        dueThisWeekCard.value = stats.dueThisWeek || "0"
        totalCirculationsCard.value = stats.totalCirculations || "0"
        avgLoanDurationCard.value = (stats.averageLoanDuration || 0).toFixed(1)
    }

    function loadBorrowingTrends() {
        trendsSeries.clear()

        var data = reportsManager.getBorrowingTrends(getDateRangeValue(), getGroupByValue())
        var maxValue = 0
        var minDate = null
        var maxDate = null

        for (var i = 0; i < data.length; i++) {
            var dateStr = data[i].xValue
            var date = new Date(dateStr + "T12:00:00")
            var timestamp = date.getTime()

            trendsSeries.append(timestamp, data[i].yValue)

            // Track min/max dates
            if (minDate === null || timestamp < minDate) {
                minDate = timestamp
            }
            if (maxDate === null || timestamp > maxDate) {
                maxDate = timestamp
            }

            // Track maximum value for Y-axis
            if (data[i].yValue > maxValue) {
                maxValue = data[i].yValue
            }
        }

        // Set Y-axis max with 10% padding, min to 0
        trendsValueAxis.min = 0
        trendsValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis date range with 1 day padding on each side
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            minDateObj.setDate(minDateObj.getDate() - 1)
            maxDateObj.setDate(maxDateObj.getDate() + 1)

            trendsDateAxis.min = minDateObj
            trendsDateAxis.max = maxDateObj
        }
    }

    function loadBorrowingByUserType() {
        // Clear existing series
        userTypeChart.removeAllSeries()

        var data = reportsManager.getBorrowingTrendsByUserType(getDateRangeValue())
        var seriesMap = {}
        var colors = ["#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#F44336"]
        var colorIndex = 0
        var maxValue = 0
        var minDate = null
        var maxDate = null

        // Group data by user role
        for (var i = 0; i < data.length; i++) {
            var role = data[i].user_role
            if (!seriesMap[role]) {
                // var series = userTypeChart.createSeries(ChartView.SeriesTypeArea, role, userTypeDateAxis, userTypeValueAxis)
                var series = userTypeChart.createSeries(ChartView.SeriesTypeLine, role, userTypeDateAxis, userTypeValueAxis)
                series.color = colors[colorIndex % colors.length]
                seriesMap[role] = series
                colorIndex++
            }

            var dateStr = data[i].date
            var date = new Date(dateStr + "T12:00:00")
            var timestamp = date.getTime()

            seriesMap[role].append(timestamp, data[i].count)
            // seriesMap[role].upperSeries().append(timestamp, data[i].count)

            // Track min/max dates
            if (minDate === null || timestamp < minDate) {
                minDate = timestamp
            }
            if (maxDate === null || timestamp > maxDate) {
                maxDate = timestamp
            }

            // Track maximum value for Y-axis
            if (data[i].count > maxValue) {
                maxValue = data[i].count
            }
        }

        // Set Y-axis max with 10% padding, min to 0
        userTypeValueAxis.min = 0
        userTypeValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10

        // Set X-axis date range with 1 day padding on each side
        if (minDate !== null && maxDate !== null) {
            var minDateObj = new Date(minDate)
            var maxDateObj = new Date(maxDate)

            minDateObj.setDate(minDateObj.getDate() - 1)
            maxDateObj.setDate(maxDateObj.getDate() + 1)

            userTypeDateAxis.min = minDateObj
            userTypeDateAxis.max = maxDateObj
        }
    }

    function loadBorrowingByDayOfWeek() {
        dayBarSet.remove(0, dayBarSet.count)

        var data = reportsManager.getBorrowingByDayOfWeek(getDateRangeValue())
        var dayOrder = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var dayMap = {}
        var maxValue = 0

        // Create map for easy lookup and track max value
        for (var i = 0; i < data.length; i++) {
            dayMap[data[i].category] = data[i].value
            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        // Append in correct order
        for (var j = 0; j < dayOrder.length; j++) {
            dayBarSet.append(dayMap[dayOrder[j]] || 0)
        }

        // Set Y-axis max dynamically with 10% padding, min to 0
        dayValueAxis.min = 0
        dayValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }

    function loadMonthlyCirculation() {
        issuesSet.remove(0, issuesSet.count)
        returnsSet.remove(0, returnsSet.count)

        var data = reportsManager.getMonthlyCirculation(getDateRangeValue())
        var categories = []
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].month)
            var issueVal = data[i].issues || 0
            var returnVal = data[i].returns || 0
            issuesSet.append(issueVal)
            returnsSet.append(returnVal)

            // Track maximum between both values
            if (issueVal > maxValue) {
                maxValue = issueVal
            }
            if (returnVal > maxValue) {
                maxValue = returnVal
            }
        }

        monthAxis.categories = categories

        // Set Y-axis max dynamically with 10% padding, min to 0
        monthValueAxis.min = 0
        monthValueAxis.max = maxValue > 0 ? Math.ceil(maxValue * 1.1) : 10
    }
}
