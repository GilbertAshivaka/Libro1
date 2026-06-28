import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.6
import Qt5Compat.GraphicalEffects
import QtCore
import QtQuick.Dialogs


Page {
    id: collectionReportsPage
    title: "Collection Overview & Statistics"
    anchors.fill: parent

    signal closeClicked()

    // Mouse area to prevent events leaking through
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
        id: collectionScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: ScrollBar {
            id: vbar
            active: true
            policy: ScrollBar.AsNeeded
            parent: collectionScrollView
            anchors.right: collectionScrollView.right
            anchors.top: collectionScrollView.top
            anchors.bottom: collectionScrollView.bottom

            property bool isExpanded: vbar.hovered || vbar.pressed

            contentItem: Rectangle {
                implicitWidth: vbar.isExpanded ? 12 : 6
                radius: width / 2
                color: vbar.pressed ? "#818181" : "#c2c2c2"

                Behavior on implicitWidth {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
            }

            background: Rectangle {
                implicitWidth: vbar.isExpanded ? 12 : 6
                radius: width / 2
                color: "#f0f0f0"

                Behavior on implicitWidth {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: 20

            Item { height: 10 } // Top padding

            // Header Section
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "📚 Collection Overview & Statistics"

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    Label {
                        text: "Monitor your library inventory and collection health"
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
                            model: ["All Time", "Last 7 Days", "Last 30 Days", "Last 3 Months", "Last 6 Months", "Last 12 Months", "Current Year"]
                            currentIndex: 0
                            onActivated: loadCollectionData()
                        }

                        Label {
                            text: "Genre:"
                            font.bold: true
                        }

                        ComboBox {
                            id: genreFilterCombo
                            Layout.preferredWidth: 150
                            model: genreModel
                            currentIndex: 0
                            onActivated: loadCollectionData()
                        }

                        Label {
                            text: "Language:"
                            font.bold: true
                        }

                        ComboBox {
                            id: languageFilterCombo
                            Layout.preferredWidth: 150
                            model: languageModel
                            currentIndex: 0
                            onActivated: loadCollectionData()
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadCollectionData()
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
                id: collectionStatsGroupBox
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
                        id: totalBooksCard
                        Layout.fillWidth: true
                        title: "Total Books"
                        value: "0"
                        accentColor: "#2196F3"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: availableBooksCard
                        Layout.fillWidth: true
                        title: "Available"
                        value: "0"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: booksAddedCard
                        Layout.fillWidth: true
                        title: "Added This Month"
                        value: "0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: avgBookValueCard
                        Layout.fillWidth: true
                        title: "Average Value"
                        value: "$0"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }

                    StatCard {
                        id: goodConditionCard
                        Layout.fillWidth: true
                        title: "Good Condition"
                        value: "0"
                        unit: "%"
                        accentColor: "#00BCD4"
                        isLoading: reportsManager.isLoading
                    }
                }
            }

            // Charts Section
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20

                // Genre Distribution Pie Chart
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Books by Genre Distribution"
                    subtitle: "Percentage of books across genres"
                    isLoading: reportsManager.isLoading

                    onRefreshClicked: loadGenreDistribution()
                    onExportClicked: exportChart(genreSection())

                    contentItem: ChartView {
                        id: genreChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"

                        PieSeries {
                            id: genreSeries
                        }
                    }
                }

                // Availability Status Donut Chart
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    title: "Book Availability Status"
                    subtitle: "Current status of all books"
                    isLoading: reportsManager.isLoading

                    onRefreshClicked: loadAvailabilityStatus()
                    onExportClicked: exportChart(availabilitySection())

                    contentItem: ChartView {
                        id: availabilityChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.alignment: Qt.AlignRight
                        backgroundColor: "transparent"

                        PieSeries {
                            id: availabilitySeries
                            holeSize: 0.4
                        }
                    }
                }
            }

            // Publication Year Bar Chart
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Books by Publication Year"
                subtitle: "Top 10 recent years showing collection age"
                isLoading: reportsManager.isLoading

                onRefreshClicked: loadPublicationYears()
                onExportClicked: exportChart(publicationYearSection())

                contentItem: ChartView {
                    id: publicationYearChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"

                    BarCategoryAxis {
                        id: yearAxis
                    }

                    ValuesAxis{
                        id: valueAxisY
                        titleText: "Number of Books"
                        min: 0
                        max: 100
                    }

                    BarSeries {
                        id: publicationYearSeries

                        BarSet {
                            id: yearBarSet
                            label: "Books"
                            color: "#2196F3"
                        }

                        Component.onCompleted: {
                            publicationYearChart.setAxisX(yearAxis, publicationYearSeries)
                            publicationYearChart.setAxisY(valueAxisY, publicationYearSeries)
                        }
                    }
                }
            }

            // Top Borrowed Books
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 500
                title: "Top 10 Most Borrowed Books"
                subtitle: "Most popular books in your collection"
                isLoading: reportsManager.isLoading

                onRefreshClicked: loadTopBorrowedBooks()
                onExportClicked: exportChart(topBorrowedSection())

                contentItem: ChartView {
                    id: topBorrowedChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"

                    BarCategoryAxis {
                        id: bookAxis
                    }

                    ValuesAxis {
                        id: borrowedValueAxis
                        titleText: "Times Borrowed"
                        min: 0
                        max: 100
                    }

                    HorizontalBarSeries {
                        id: topBorrowedSeries

                        BarSet {
                            id: borrowedBarSet
                            label: "Borrows"
                            color: "#4CAF50"
                        }

                        Component.onCompleted: {
                            topBorrowedChart.setAxisY(bookAxis, topBorrowedSeries)
                            topBorrowedChart.setAxisX(borrowedValueAxis, topBorrowedSeries)
                        }
                    }
                }
            }

            Item { height: 20 } // Bottom padding
        }
    }

    // Data Models
    ListModel {
        id: genreModel
        ListElement { text: "All Genres" }
    }

    ListModel {
        id: languageModel
        ListElement { text: "All Languages" }
    }

    // Load data on component completion
    Component.onCompleted: {
        loadFilters()
        loadCollectionData()
    }

    function loadFilters() {
        var genres = reportsManager.getAvailableGenres()
        for (var i = 0; i < genres.length; i++) {
            var genre = genres[i]
            // genre is a map → pick the correct key (most likely "genre", "label", or "value")
            genreModel.append({ text: genre.genre || genre.label || genre.value || genre.toString() })
        }

        var languages = reportsManager.getAvailableLanguages()
        for (var j = 0; j < languages.length; j++) {
            var lang = languages[j]
            languageModel.append({ text: lang.language || lang.label || lang.value || lang.toString() })
        }
    }

    function getDateRangeValue() {
        var ranges = ["all", "last7days", "last30days", "last3months", "last6months", "last12months", "currentYear"]
        return ranges[dateRangeCombo.currentIndex]
    }

    function getGenreFilter() {
        return genreFilterCombo.currentIndex === 0 ? "all" : genreFilterCombo.currentText
    }

    function getLanguageFilter() {
        return languageFilterCombo.currentIndex === 0 ? "all" : languageFilterCombo.currentText
    }

    function loadCollectionData() {
        loadCollectionStats()
        loadGenreDistribution()
        loadPublicationYears()
        loadAvailabilityStatus()
        loadTopBorrowedBooks()
    }

    function loadCollectionStats() {
        var stats = reportsManager.getCollectionStats()

        totalBooksCard.value = stats.totalBooks || "0"
        availableBooksCard.value = stats.availableBooks || "0"
        booksAddedCard.value = stats.booksAddedThisMonth || "0"
        avgBookValueCard.value = "$" + (stats.averageBookValue || 0).toFixed(2)

        var total = parseInt(stats.totalBooks) || 1
        var good = parseInt(stats.booksInGoodCondition) || 0
        goodConditionCard.value = ((good / total) * 100).toFixed(1)
    }

    function loadGenreDistribution() {
        genreSeries.clear()

        var data = reportsManager.getBooksByGenreDistribution(getDateRangeValue())

        for (var i = 0; i < data.length; i++) {
            var slice = genreSeries.append(data[i].label, data[i].value)
            slice.labelVisible = data[i].percentage > 5 // Show label if > 5%
        }
    }

    function loadPublicationYears() {
        yearBarSet.remove(0, yearBarSet.count)
        var data = reportsManager.getBooksByPublicationYear(10)
        var categories = []
        var maxValue = 0

        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].category)
            yearBarSet.append(data[i].value)

            // Track the maximum value
            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        yearAxis.categories = categories

        // Set the Y-axis max to slightly above the max value (e.g., 10% padding)
        valueAxisY.max = Math.ceil(maxValue * 1.1)
    }

    function loadAvailabilityStatus() {
        availabilitySeries.clear()

        var data = reportsManager.getBookAvailabilityStatus()
        var colors = {
            "Available": "#4CAF50",
            "Borrowed": "#FF9800",
            "Lost": "#F44336",
            "Reserved": "#2196F3",
            "Damaged": "#9E9E9E"
        }

        for (var i = 0; i < data.length; i++) {
            var slice = availabilitySeries.append(data[i].label, data[i].value)
            if (colors[data[i].label]) {
                slice.color = colors[data[i].label]
            }
            slice.labelVisible = true
        }
    }

    function loadTopBorrowedBooks() {
        borrowedBarSet.remove(0, borrowedBarSet.count)

        var data = reportsManager.getTopBorrowedBooks(10, getGenreFilter(), getLanguageFilter())
        var categories = []
        var maxValue = 0

        for (var i = data.length - 1; i >= 0; i--) { // Reverse for better display
            var title = data[i].label
            if (title.length > 30) {
                title = title.substring(0, 27) + "..."
            }
            categories.push(title)
            borrowedBarSet.append(data[i].value)

            // Track the maximum value
            if (data[i].value > maxValue) {
                maxValue = data[i].value
            }
        }

        bookAxis.categories = categories

        //set the max value on the axis
        borrowedValueAxis.max = Math.ceil(maxValue * 1.1)
    }

    // ========================================================================
    // Report export / print
    // ========================================================================

    function filtersList() {
        return [
            { label: "Date Range", value: dateRangeCombo.currentText },
            { label: "Genre",      value: genreFilterCombo.currentText },
            { label: "Language",   value: languageFilterCombo.currentText }
        ]
    }

    function metricsSection() {
        var s = reportsManager.getCollectionStats()
        var total = parseInt(s.totalBooks) || 1
        var good = parseInt(s.booksInGoodCondition) || 0
        return {
            title: "Key Metrics", kind: "metrics",
            data: [
                { label: "Total Books",      value: String(s.totalBooks || 0) },
                { label: "Available",        value: String(s.availableBooks || 0) },
                { label: "Added This Month", value: String(s.booksAddedThisMonth || 0) },
                { label: "Average Value",    value: "$" + (s.averageBookValue || 0).toFixed(2) },
                { label: "Good Condition",   value: ((good / total) * 100).toFixed(1), unit: "%" }
            ]
        }
    }

    function genreSection() {
        var data = reportsManager.getBooksByGenreDistribution(getDateRangeValue())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].label)
            values.push(data[i].value)
        }
        return {
            title: "Books by Genre Distribution",
            subtitle: "Percentage of books across genres",
            kind: "chart", chartType: "pie",
            labels: labels,
            datasets: [ { label: "Books", data: values } ]
        }
    }

    function availabilitySection() {
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
            subtitle: "Current status of all books",
            kind: "chart", chartType: "doughnut",
            labels: labels,
            datasets: [ { label: "Status", data: values, colors: colors } ]
        }
    }

    function publicationYearSection() {
        var data = reportsManager.getBooksByPublicationYear(10)
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            labels.push(data[i].category)
            values.push(data[i].value)
        }
        return {
            title: "Books by Publication Year",
            subtitle: "Top 10 recent years showing collection age",
            kind: "chart", chartType: "bar",
            labels: labels,
            datasets: [ { label: "Books", color: "#2196F3", data: values } ]
        }
    }

    function topBorrowedSection() {
        var data = reportsManager.getTopBorrowedBooks(10, getGenreFilter(), getLanguageFilter())
        var labels = [], values = []
        for (var i = 0; i < data.length; i++) {
            var title = data[i].label
            if (title.length > 40)
                title = title.substring(0, 37) + "..."
            labels.push(title)
            values.push(data[i].value)
        }
        return {
            title: "Top 10 Most Borrowed Books",
            subtitle: "Most popular books in your collection",
            kind: "chart", chartType: "horizontalBar",
            labels: labels,
            datasets: [ { label: "Borrows", color: "#4CAF50", data: values } ]
        }
    }

    function buildReportPayload() {
        return {
            title: "Collection Overview & Statistics",
            subtitle: "Monitor your library inventory and collection health",
            filters: filtersList(),
            sections: [
                metricsSection(),
                genreSection(),
                availabilitySection(),
                publicationYearSection(),
                topBorrowedSection()
            ]
        }
    }

    function exportChart(section) {
        reportExporter.exportToPdf({
            title: "Collection Overview — " + section.title,
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
