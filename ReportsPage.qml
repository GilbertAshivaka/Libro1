import QtQuick
import QtCharts
import QtQuick.Controls
import QtQuick.Layouts
import "DynamicComponentLoader.js" as CustomComponentLoader

Rectangle {
    id: reportsPage
    anchors.fill: parent
    signal closeClicked()

    property var reportComponentsContainer: null
    property var collectionReportsPage: null
    property var circulationReportsPage: null
    property var userEngagementPage: null
    property var trendsInsightsPage: null
    property var reservationReportsPage: null
    property var overdueReportsPage: null
    property var financialReportsPage: null
    property var lostDamagedPage: null
    property var systemPerformancePage: null
    property var digitalMaterialsPage: null

    MouseArea{
        id: reportsPageMA
        anchors.fill: parent
    }

    ScrollView{
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        id: reportsPageSV
        anchors.fill: parent
        contentHeight: 350 + reportLoader.height

        Rectangle{
            id: topRect
            width: parent.width
            height: 50
            anchors{
                top: parent.top
            }

            Rectangle{
                id: backRect
                width: 32
                height: 32
                radius: 4
                color: "#DDDDDD"
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                Rectangle{
                    id: backBtnRect
                    width: 20
                    height: 20
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image{
                        id: back
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/backArrow.png"
                    }
                }

                MouseArea{
                    id: backMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        backRect.color = "#E8E3E4"
                    }
                    onExited: {
                        backRect.color = "#DDDDDD"
                    }

                    onClicked: {
                        reportsPage.closeClicked()
                    }
                }
            }


            Image {
                id: reportsIcon
                source: "assets/reportsIcon.png"
                width: 48
                height: 48
                anchors{
                    left: backRect.right
                    leftMargin: 30
                    verticalCenter: parent.verticalCenter
                }
            }

            Text {
                id: reportTxt
                text: qsTr("Reports and analytics")
                anchors{
                    left: reportsIcon.right
                    leftMargin: 10
                    verticalCenter: reportsIcon.verticalCenter
                }
                font.family: "Arial"
            }

            Rectangle{
                id: toptionsRect
                height: 32
                width: 200
                radius: 4
                border.color: "#DCD8D8"
                anchors{
                    right: parent.right
                    rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                Image {
                    id: print
                    source: "assets/print.png"
                    width: 20
                    height: 20
                    anchors{
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    MouseArea{
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            printMenu.open()
                        }
                    }

                    Menu{
                        id: printMenu
                        width: 160
                        y: print.height

                        MenuItem{
                            text: "Print overview"
                            enabled: !reportExporter.isBusy
                            onTriggered: reportExporter.printReport(buildOverviewPayload())
                        }
                    }
                }
                Text{
                    id: printTxt
                    anchors{
                        left: print.right
                        leftMargin: 5
                        verticalCenter: print.verticalCenter
                    }
                    text: "Print"
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            printMenu.open()
                        }
                    }
                }

                Image {
                    id: exportIcon
                    source: "assets/export.png"
                    height: 20
                    width: 20
                    anchors{
                        left: printTxt.right
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            formatMenu.open()
                        }
                    }

                    Menu{
                        id: formatMenu
                        title: "Choose format"
                        width: 150
                        y: exportIcon.height

                        MenuItem{
                            text: "Choose format"
                            enabled: false
                        }
                        MenuItem{
                            text: "PDF"
                            enabled: !reportExporter.isBusy
                            onTriggered: reportExporter.exportToPdf(buildOverviewPayload())
                        }
                        MenuItem{
                            text: "CSV/Excel"
                            enabled: !reportExporter.isBusy
                            onTriggered: reportExporter.exportToCsv(buildOverviewPayload())
                        }
                    }
                }

                Text {
                    id: exportTxt
                    text: qsTr("Export")
                    anchors{
                        left: exportIcon.right
                        leftMargin: 5
                        verticalCenter: exportIcon.verticalCenter
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            formatMenu.open()
                        }
                    }
                }
            }
        }

        Rectangle{
            id: separator
            width: parent.width* .95
            height: 1
            color: "#DCD8D8"
            anchors{
                top: topRect.bottom
                horizontalCenter: parent.horizontalCenter
            }
        }

        Item {
            id: keyStatsItem
            width: parent.width
            height: 150
            anchors{
                top: separator.bottom
            }

            Rectangle{
                id: firstRect
                width: 400
                height: parent.height
                //            color: "#F5F5F5"
                anchors{
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Image {
                    id: totalBooksIcon
                    source: "assets/allBooks.png"
                    width: 16
                    height: 16
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        top: parent.top
                        topMargin: 20
                    }
                }
                Text {
                    id: totalBooksTxt
                    text: qsTr("Total number of books")
                    color: "#8C8989"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors{
                        left: totalUsersIcon.right
                        leftMargin: 10
                        verticalCenter: totalBooksIcon.verticalCenter
                    }
                }

                Image {
                    id: totalUsersIcon
                    source: "assets/allUsers.png"
                    width: 16
                    height: 16
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        top: totalBooksIcon.bottom
                        topMargin: 20
                    }
                }
                Text {
                    id: totalUsersTxt
                    text: qsTr("Total number of users")
                    color: "#8C8989"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors{
                        left: totalUsersIcon.right
                        leftMargin: 10
                        verticalCenter: totalUsersIcon.verticalCenter
                    }
                }

                Image {
                    id: mostActiveIcon
                    source: "assets/category.png"
                    width: 16
                    height: 16
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        top: totalUsersIcon.bottom
                        topMargin: 20
                    }
                }
                Text {
                    id: mostActiveTxt
                    text: qsTr("Active Users")
                    color: "#8C8989"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors{
                        left: mostActiveIcon.right
                        leftMargin: 10
                        verticalCenter: mostActiveIcon.verticalCenter
                    }
                }

                Rectangle{
                    id: separator2
                    width: 1
                    height: parent.height
                    color: "transparent"
                    anchors{
                        left: totalBooksTxt.right
                        leftMargin: 50
                        top: parent.top
                        bottom: parent.bottom
                    }
                }

                Text {
                    id: totalBooks
                    text: "0"//qsTr("20234")
                    anchors{
                        left: separator2.right
                        verticalCenter: totalBooksTxt.verticalCenter
                    }
                    font.family: "Arial"
                }

                Text {
                    id: totalUsers
                    text: "0" //qsTr("3046")
                    anchors{
                        left: separator2.right
                        verticalCenter: totalUsersTxt.verticalCenter
                    }
                    font.family: "Arial"
                }

                Text {
                    id: mostActive
                    text: "0" //qsTr("Form 4 East")
                    anchors{
                        left: separator2.right
                        verticalCenter: mostActiveTxt.verticalCenter
                    }
                    font.family: "Arial"
                }
            }

            Rectangle{
                id: secondRect
                width: 400
                height: parent.height
                //            color: "#F5F5F5"
                anchors{
                    left: firstRect.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 50
                }

                Image {
                    id: issuedBooksIcon
                    source: "assets/issuedBooks.png"
                    width: 16
                    height: 16
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        top: parent.top
                        topMargin: 20
                    }
                }
                Text {
                    id: issuedBooksTxt
                    text: qsTr("Books due today")
                    color: "#8C8989"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors{
                        left: issuedBooksIcon.right
                        leftMargin: 10
                        verticalCenter: issuedBooksIcon.verticalCenter
                    }
                }

                Image {
                    id: overdueBooksIcon
                    source: "assets/overdueBooks.png"
                    width: 16
                    height: 16
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        top: issuedBooksIcon.bottom
                        topMargin: 20
                    }
                }
                Text {
                    id: overdueBooksTxt
                    text: qsTr("Overdue Books")
                    color: "#8C8989"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors{
                        left: overdueBooksIcon.right
                        leftMargin: 10
                        verticalCenter: overdueBooksIcon.verticalCenter
                    }
                }

                Image {
                    id: lostBooksIcon
                    source: "assets/lostBooks.png"
                    width: 16
                    height: 16
                    anchors{
                        left: parent.left
                        leftMargin: 20
                        top: overdueBooksIcon.bottom
                        topMargin: 20
                    }
                }
                Text {
                    id: lostBooksTxt
                    text: qsTr("Lost books")
                    color: "#8C8989"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors{
                        left: lostBooksIcon.right
                        leftMargin: 10
                        verticalCenter: lostBooksIcon.verticalCenter
                    }
                }

                Rectangle{
                    id: separator3
                    width: 1
                    height: parent.height
                    color: "transparent"
                    anchors{
                        left: issuedBooksTxt.right
                        leftMargin: 50
                        top: parent.top
                        bottom: parent.bottom
                    }
                }

                //changed to show books issued today
                Text {
                    id: issuedBooks
                    text: "0" //qsTr("203")
                    anchors{
                        left: separator3.right
                        verticalCenter: issuedBooksTxt.verticalCenter
                    }
                    font.family: "Arial"
                }

                Text {
                    id: overdueBooks
                    text: "0" //qsTr("23")
                    anchors{
                        left: separator3.right
                        verticalCenter: overdueBooksTxt.verticalCenter
                    }
                    font.family: "Arial"
                }

                Text {
                    id: lostBooks
                    text: "0" //qsTr("5")
                    anchors{
                        left: separator3.right
                        verticalCenter: lostBooksTxt.verticalCenter
                    }
                    font.family: "Arial"
                }
            }
        }

        Rectangle{
            id: separator4
            width: parent.width
            height: 1
            color: "#DCD8D8"
            anchors{
                top: keyStatsItem.bottom
                horizontalCenter: parent.horizontalCenter
            }
        }

        RowLayout {
            id: filterButtonsLayout
            height: 40
            Layout.fillWidth: true
            anchors{
                top: separator4.bottom
                left: parent.left
                leftMargin: 20
            }

            ButtonGroup {
                id: filterButtonGroup
            }

            Button {
                text: "Overview"
                checkable: true
                checked: true
                ButtonGroup.group: filterButtonGroup
                onClicked: reportLoader.source = "ReportsOverviewContainer.qml"
            }

            Button {
                text: "Activity"
                checkable: true
                ButtonGroup.group: filterButtonGroup
                onClicked: reportLoader.source = "ReportsActivityContainer.qml"
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "More..."
                icon.name: "view-refresh"
                ButtonGroup.group: filterButtonGroup
                onClicked: {
                    menu.open()
                }
            }

            Menu {
                id: menu
                width: 250
                y: filterButtonsLayout.height - height
                x: filterButtonsLayout.x + filterButtonsLayout.width

                MenuItem {
                    text: "Collection Overview"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(collectionReportsPage, "Reports/CollectionReportsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Ciculation Analysis"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(circulationReportsPage, "Reports/CirculationReportsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "User Engagement"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(userEngagementPage, "Reports/UserEngagementPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Popular Trends && Insights"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(trendsInsightsPage, "Reports/TrendsInsightsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Reservation Analytics"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(reservationReportsPage, "Reports/ReservationReportsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Overdue && Compliance"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(overdueReportsPage, "Reports/OverdueReportsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Financial Reports"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(financialReportsPage, "Reports/FinancialReportsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Lost && Damaged Books"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(lostDamagedPage, "Reports/LostDamagedReportsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "Digital Material Analytics"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(digitalMaterialsPage, "Reports/DigitalMaterialsPage", mainContainer)
                    }
                }
                MenuItem {
                    text: "System Performance"
                    onTriggered: {
                        CustomComponentLoader.customCreateComponent(systemPerformancePage, "Reports/SystemPerformancePage", mainContainer)
                    }
                }
            }
        }

        Loader{
            id: reportLoader
            width: parent.width
            anchors{
                top: filterButtonsLayout.bottom
                topMargin: 10
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            source: "ReportsOverviewContainer.qml"
        }
    }

    //use the reportsManager module registered as a singleton to get the total number of books displayed on this page
    function loadCollectionStats() {
        var stats = reportsManager.getCollectionStats()
        totalBooks.text = stats.totalBooks || "0"
    }

    function loadEngagementStats() {
        var stats = reportsManager.getUserEngagementStats()

        totalUsers.text = stats.totalUsers || "0"
        mostActive.text = stats.activeUsers || "0"
        // inactiveUsersCard.value = stats.inactiveUsers || "0"
        // newUsersCard.value = stats.newUsersThisMonth || "0"
        // avgBooksPerUserCard.value = (stats.averageBooksPerUser || 0).toFixed(1)
    }

    function loadCirculationStats() {
        var stats = reportsManager.getCirculationStats(getDateRangeValue())

        issuedBooks.text = stats.dueToday || "0"
        // currentlyOnLoanCard.value = stats.currentlyOnLoan || "0"
        // dueThisWeekCard.value = stats.dueThisWeek || "0"
        // totalCirculationsCard.value = stats.totalCirculations || "0"
        // avgLoanDurationCard.value = (stats.averageLoanDuration || 0).toFixed(1)
    }

    function loadOverdueStats() {
        var stats = reportsManager.getOverdueStats()

        overdueBooks.text = stats.totalOverdue || "0"
        // longestOverdueCard.value = Math.floor(stats.longestOverdueDays || 0)
        // avgDaysOverdueCard.value = (stats.averageDaysOverdue || 0).toFixed(1)
        // critical30PlusCard.value = stats.overdue30Plus || "0"
        // overdueRateCard.value = (stats.overdueRate || 0).toFixed(1)
    }

    function loadLostDamagedStats() {
        var stats = reportsManager.getLostDamagedStats()

        lostBooks.text = stats.totalLostBooks || "0"
        // lostThisYearCard.value = stats.lostBooksThisYear || "0"
        // replacementCostCard.value = "$" + (stats.replacementCostOutstanding || 0).toFixed(2)
        // damagedBooksCard.value = stats.damagedBooks || "0"
        // lossRateCard.value = (stats.lossRate || 0).toFixed(2)
    }


    Component.onCompleted:{
        loadCollectionStats()
        loadEngagementStats()
        loadLostDamagedStats()
        loadOverdueStats()
        loadLostDamagedStats()
    }

    // ========================================================================
    // Overview report export / print
    //
    // Builds a single document summarising the whole library: a top-level
    // overview KPI block, a few cross-category snapshot charts, then a compact
    // KPI block for each of the 10 report categories. Reuses the same
    // ReportExporter engine and payload schema as the detail pages.
    // ========================================================================

    function overviewMetricsSection() {
        var col  = reportsManager.getCollectionStats()
        var eng  = reportsManager.getUserEngagementStats()
        var circ = reportsManager.getCirculationStats("last30days")
        var ov   = reportsManager.getOverdueStats()
        var lost = reportsManager.getLostDamagedStats()
        var sys  = reportsManager.getSystemPerformanceStats()
        return {
            title: "Library Overview", kind: "metrics",
            data: [
                { label: "Total Books",       value: String(col.totalBooks || 0) },
                { label: "Available Books",   value: String(col.availableBooks || 0) },
                { label: "Total Users",       value: String(eng.totalUsers || 0) },
                { label: "Active Users (30d)",value: String(eng.activeUsers || 0) },
                { label: "Due Today",         value: String(circ.dueToday || 0) },
                { label: "Currently On Loan", value: String(circ.currentlyOnLoan || 0) },
                { label: "Total Overdue",     value: String(ov.totalOverdue || 0) },
                { label: "Lost Books",        value: String(lost.totalLostBooks || 0) },
                { label: "Database Size",     value: String(sys.databaseSize || "0 MB") }
            ]
        }
    }

    function availabilityChartSection() {
        var data = reportsManager.getBookAvailabilityStatus()
        var colorMap = {
            "Available": "#4CAF50", "Borrowed": "#FF9800", "Lost": "#F44336",
            "Reserved": "#2196F3", "Damaged": "#9E9E9E"
        }
        var labels = [], values = [], colors = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
            colors.push(colorMap[data[i].label] || "#607D8B")
        }
        return {
            title: "Book Availability Status",
            subtitle: "Current status of the whole collection",
            kind: "chart", chartType: "doughnut",
            labels: labels,
            datasets: [ { label: "Status", data: values, colors: colors } ]
        }
    }

    function genreChartSection() {
        var data = reportsManager.getBooksByGenreDistribution("all")
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
        }
        return {
            title: "Books by Genre",
            subtitle: "Collection composition",
            kind: "chart", chartType: "pie",
            labels: labels,
            datasets: [ { label: "Books", data: values } ]
        }
    }

    function borrowingTrendChartSection() {
        var data = reportsManager.getBorrowingTrends("last30days", "day")
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].xValue)
            values.push(data[i].yValue)
        }
        return {
            title: "Borrowing Trends (Last 30 Days)",
            subtitle: "Recent circulation activity",
            kind: "chart", chartType: "line",
            labels: labels,
            datasets: [ { label: "Borrows", color: "#2196F3", data: values } ]
        }
    }

    function monthlyCirculationChartSection() {
        var data = reportsManager.getMonthlyCirculation("last6months")
        var labels = [], issues = [], returns = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].month)
            issues.push(data[i].issues || 0)
            returns.push(data[i].returns || 0)
        }
        return {
            title: "Monthly Circulation",
            subtitle: "Issues vs Returns (last 6 months)",
            kind: "chart", chartType: "stackedBar",
            labels: labels,
            datasets: [
                { label: "Issues",  color: "#2196F3", data: issues },
                { label: "Returns", color: "#4CAF50", data: returns }
            ]
        }
    }

    // Compact KPI block per category
    function categorySummarySections() {
        var sections = []

        var col = reportsManager.getCollectionStats()
        sections.push({ title: "Collection Overview", kind: "metrics", data: [
            { label: "Total Books",      value: String(col.totalBooks || 0) },
            { label: "Available",        value: String(col.availableBooks || 0) },
            { label: "Added This Month", value: String(col.booksAddedThisMonth || 0) },
            { label: "Avg Value",        value: "$" + (col.averageBookValue || 0).toFixed(2) }
        ]})

        var circ = reportsManager.getCirculationStats("last30days")
        sections.push({ title: "Circulation Analytics", kind: "metrics", data: [
            { label: "Currently On Loan", value: String(circ.currentlyOnLoan || 0) },
            { label: "Due Today",         value: String(circ.dueToday || 0) },
            { label: "Due This Week",     value: String(circ.dueThisWeek || 0) },
            { label: "Total Circulations",value: String(circ.totalCirculations || 0) },
            { label: "Avg Loan Duration", value: (circ.averageLoanDuration || 0).toFixed(1), unit: "days" }
        ]})

        var eng = reportsManager.getUserEngagementStats()
        sections.push({ title: "User Engagement", kind: "metrics", data: [
            { label: "Total Users",     value: String(eng.totalUsers || 0) },
            { label: "Active (30d)",    value: String(eng.activeUsers || 0) },
            { label: "Inactive (90+d)", value: String(eng.inactiveUsers || 0) },
            { label: "New This Month",  value: String(eng.newUsersThisMonth || 0) },
            { label: "Avg Books/User",  value: (eng.averageBooksPerUser || 0).toFixed(1) }
        ]})

        var tr = reportsManager.getTrendsInsightsStats()
        sections.push({ title: "Trends & Insights", kind: "metrics", data: [
            { label: "Trending Genre",       value: String(tr.trendingGenre || "N/A") },
            { label: "Top Author",           value: String(tr.mostBorrowedAuthor || "N/A") },
            { label: "Avg Borrow Frequency", value: (tr.averageBorrowingFrequency || 0).toFixed(1) },
            { label: "Turnover Rate",        value: (tr.collectionTurnoverRate || 0).toFixed(2) },
            { label: "Never Borrowed",       value: String(tr.booksNeverBorrowed || 0) }
        ]})

        var res = reportsManager.getReservationStats()
        sections.push({ title: "Reservation Analytics", kind: "metrics", data: [
            { label: "Active Reservations", value: String(res.activeReservations || 0) },
            { label: "Avg Wait Time",       value: (res.averageWaitTime || 0).toFixed(1), unit: "days" },
            { label: "Fulfillment Rate",    value: (res.fulfillmentRate || 0).toFixed(1), unit: "%" },
            { label: "Expired",             value: String(res.expiredReservations || 0) },
            { label: "Books w/ Pending",    value: String(res.booksWithPendingReservations || 0) }
        ]})

        var ov = reportsManager.getOverdueStats()
        sections.push({ title: "Overdue & Compliance", kind: "metrics", data: [
            { label: "Total Overdue",    value: String(ov.totalOverdue || 0) },
            { label: "Longest Overdue",  value: String(Math.floor(ov.longestOverdueDays || 0)), unit: "days" },
            { label: "Avg Days Overdue", value: (ov.averageDaysOverdue || 0).toFixed(1), unit: "days" },
            { label: "30+ Days",         value: String(ov.overdue30Plus || 0) },
            { label: "Overdue Rate",     value: (ov.overdueRate || 0).toFixed(1), unit: "%" }
        ]})

        var fin = reportsManager.getFinancialStats("currentMonth")
        sections.push({ title: "Financial Reports", kind: "metrics", data: [
            { label: "Fines Generated", value: "$" + (fin.totalFinesGenerated || 0).toFixed(2) },
            { label: "Fines Collected", value: "$" + (fin.totalFinesCollected || 0).toFixed(2) },
            { label: "Outstanding",     value: "$" + (fin.outstandingFines || 0).toFixed(2) },
            { label: "Lost Book Cost",  value: "$" + (fin.lostBooksReplacementCost || 0).toFixed(2) },
            { label: "Collection Rate", value: (fin.fineCollectionRate || 0).toFixed(1), unit: "%" }
        ]})

        var lost = reportsManager.getLostDamagedStats()
        sections.push({ title: "Lost & Damaged Books", kind: "metrics", data: [
            { label: "Total Lost",       value: String(lost.totalLostBooks || 0) },
            { label: "Lost This Year",   value: String(lost.lostBooksThisYear || 0) },
            { label: "Replacement Cost", value: "$" + (lost.replacementCostOutstanding || 0).toFixed(2) },
            { label: "Damaged",          value: String(lost.damagedBooks || 0) },
            { label: "Loss Rate",        value: (lost.lossRate || 0).toFixed(2), unit: "%" }
        ]})

        var dig = reportsManager.getDigitalMaterialsStats()
        sections.push({ title: "Digital Materials & Equipment", kind: "metrics", data: [
            { label: "Total Items",       value: String(dig.totalItems || 0) },
            { label: "On Loan",           value: String(dig.currentlyOnLoan || 0) },
            { label: "Most Popular",      value: String(dig.mostPopularType || "N/A") },
            { label: "Avg Loan Duration", value: (dig.averageLoanDuration || 0).toFixed(1), unit: "days" },
            { label: "Utilization",       value: (dig.utilizationRate || 0).toFixed(1), unit: "%" }
        ]})

        var sys = reportsManager.getSystemPerformanceStats()
        sections.push({ title: "System Activity & Performance", kind: "metrics", data: [
            { label: "Operations Today", value: String(sys.operationsToday || 0) },
            { label: "Errors (24h)",     value: String(sys.errorCount24h || 0) },
            { label: "Database Size",    value: String(sys.databaseSize || "0 MB") },
            { label: "Peak Usage Hour",  value: String(sys.peakUsageHour || "N/A") }
        ]})

        return sections
    }

    function buildOverviewPayload() {
        var sections = [
            overviewMetricsSection(),
            availabilityChartSection(),
            genreChartSection(),
            borrowingTrendChartSection(),
            monthlyCirculationChartSection()
        ]
        sections = sections.concat(categorySummarySections())
        return {
            title: "Library Reports — Overview",
            subtitle: "Summary across all report categories",
            filters: [],
            sections: sections
        }
    }

    Connections {
        target: reportExporter
        function onExportFinished(success, outputPath, message) {
            if (success && outputPath)
                console.log("Overview report exported to:", outputPath)
            else if (!success && message)
                console.warn("Overview report export failed:", message)
        }
    }
}

