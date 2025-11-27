import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.6
import Qt5Compat.GraphicalEffects


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
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

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

                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export collection report")
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
                    onExportClicked: console.log("Export genre chart")

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
                    onExportClicked: console.log("Export availability chart")

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
                onExportClicked: console.log("Export publication year chart")

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
                onExportClicked: console.log("Export top borrowed chart")

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

    // Functions to load data
    // function loadFilters() {
    //     // Load available genres
    //     var genres = reportsManager.getAvailableGenres()
    //     for (var i = 0; i < genres.length; i++) {
    //         genreModel.append({ text: genres[i] })
    //     }

    //     // Load available languages
    //     var languages = reportsManager.getAvailableLanguages()
    //     for (var j = 0; j < languages.length; j++) {
    //         languageModel.append({ text: languages[j] })
    //     }
    // }

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

        for (var i = 0; i < data.length; i++) {
            categories.push(data[i].category)
            yearBarSet.append(data[i].value)
        }

        yearAxis.categories = categories
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

        for (var i = data.length - 1; i >= 0; i--) { // Reverse for better display
            var title = data[i].label
            if (title.length > 30) {
                title = title.substring(0, 27) + "..."
            }
            categories.push(title)
            borrowedBarSet.append(data[i].value)
        }

        bookAxis.categories = categories
    }
}
