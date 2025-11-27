import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

Page {
    id: trendsInsightsPage
    title: "Trends & Insights"
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
                title: "📈 Trends & Insights"
                
                ColumnLayout {
                    width: parent.width
                    spacing: 15
                    
                    Label {
                        text: "Discover popular trends and reading patterns for strategic decisions"
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
                            onActivated: loadTrendsData()
                        }
                        
                        Label {
                            text: "Genre:"
                            font.bold: true
                        }
                        
                        ComboBox {
                            id: genreCombo
                            Layout.preferredWidth: 150
                            model: genreModel
                            currentIndex: 0
                            onActivated: loadTrendsData()
                        }
                        
                        Label {
                            text: "Min Borrows:"
                            font.bold: true
                        }
                        
                        SpinBox {
                            id: minBorrowsSpinBox
                            Layout.preferredWidth: 120
                            from: 0
                            to: 100
                            value: 5
                            onValueChanged: loadTrendsData()
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "⟳ Refresh"
                            onClicked: loadTrendsData()
                        }
                        
                        Button {
                            text: "⤓ Export"
                            highlighted: true
                            onClicked: console.log("Export trends report")
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
                        id: trendingGenreCard
                        Layout.fillWidth: true
                        title: "Trending Genre"
                        value: "N/A"
                        accentColor: "#FF5722"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: topAuthorCard
                        Layout.fillWidth: true
                        title: "Top Author"
                        value: "N/A"
                        accentColor: "#9C27B0"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: avgBorrowingCard
                        Layout.fillWidth: true
                        title: "Avg Borrow Frequency"
                        value: "0"
                        accentColor: "#2196F3"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: turnoverRateCard
                        Layout.fillWidth: true
                        title: "Turnover Rate"
                        value: "0"
                        accentColor: "#4CAF50"
                        isLoading: reportsManager.isLoading
                    }
                    
                    StatCard {
                        id: neverBorrowedCard
                        Layout.fillWidth: true
                        title: "Never Borrowed"
                        value: "0"
                        accentColor: "#FF9800"
                        isLoading: reportsManager.isLoading
                    }
                }
            }
            
            // Popular Subjects/Genres
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Popular Subjects/Genres"
                subtitle: "Top 20 genres weighted by total borrows"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadPopularSubjects()
                onExportClicked: console.log("Export popular subjects")
                
                contentItem: ChartView {
                    id: popularSubjectsChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: false
                    backgroundColor: "transparent"
                    
                    HorizontalBarSeries {
                        id: popularSubjectsSeries
                        axisY: BarCategoryAxis { id: subjectAxis }
                        axisX: ValueAxis {
                            titleText: "Total Borrows"
                            min: 0
                        }
                        
                        BarSet {
                            id: subjectBarSet
                            label: "Borrows"
                            color: "#FF5722"
                        }
                    }
                }
            }
            
            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20
                
                // Top Authors
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    title: "Authors with Most Borrowed Books"
                    subtitle: "Top 20 popular authors"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadTopAuthors()
                    onExportClicked: console.log("Export top authors")
                    
                    contentItem: ChartView {
                        id: topAuthorsChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: false
                        backgroundColor: "transparent"
                        
                        HorizontalBarSeries {
                            id: topAuthorsSeries
                            axisY: BarCategoryAxis { id: authorAxis }
                            axisX: ValueAxis {
                                titleText: "Total Borrows"
                                min: 0
                            }
                            
                            BarSet {
                                id: authorBarSet
                                label: "Borrows"
                                color: "#9C27B0"
                            }
                        }
                    }
                }
                
                // Books Performance Matrix (Top 50)
                ChartContainer {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    title: "Books Performance Matrix"
                    subtitle: "Top 50 performing books"
                    isLoading: reportsManager.isLoading
                    
                    onRefreshClicked: loadPerformanceMatrix()
                    onExportClicked: console.log("Export performance matrix")
                    
                    contentItem: ScrollView {
                        anchors.fill: parent
                        clip: true
                        
                        ListView {
                            id: performanceListView
                            width: parent.width
                            spacing: 5
                            
                            delegate: Rectangle {
                                width: performanceListView.width - 20
                                height: 50
                                color: index % 2 === 0 ? "#F5F5F5" : "#FAFAFA"
                                radius: 4
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    
                                    Label {
                                        text: (index + 1) + "."
                                        font.bold: true
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 25
                                    }
                                    
                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true
                                        
                                        Label {
                                            text: modelData.title || ""
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        
                                        Label {
                                            text: modelData.author || ""
                                            font.pixelSize: 10
                                            color: "#757575"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    
                                    Label {
                                        text: modelData.timesBorrowed || "0"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#2196F3"
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Genre Popularity Trends
            ChartContainer {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 400
                title: "Genre Popularity Trends Over Time"
                subtitle: "How genre preferences change monthly"
                isLoading: reportsManager.isLoading
                
                onRefreshClicked: loadGenreTrends()
                onExportClicked: console.log("Export genre trends")
                
                contentItem: ChartView {
                    id: genreTrendsChart
                    anchors.fill: parent
                    antialiasing: true
                    legend.alignment: Qt.AlignBottom
                    backgroundColor: "transparent"
                    
                    DateTimeAxis {
                        id: genreTrendsDateAxis
                        format: "MMM yyyy"
                        titleText: "Month"
                    }
                    ValueAxis {
                        id: genreTrendsValueAxis
                        titleText: "Borrows"
                        min: 0
                    }
                }
            }
            
            Item { height: 20 }
        }
    }
    
    // Data Models
    ListModel {
        id: genreModel
        ListElement { text: "All Genres" }
    }
    
    Component.onCompleted: {
        loadGenres()
        loadTrendsData()
    }
    
    function loadGenres() {
        var genres = reportsManager.getAvailableGenres()
        for (var i = 0; i < genres.length; i++) {
            genreModel.append({ text: genres[i] })
        }
    }
    
    function getDateRangeValue() {
        var ranges = ["all", "last3months", "last6months", "last12months", "currentYear"]
        return ranges[dateRangeCombo.currentIndex]
    }
    
    function getGenreFilter() {
        return genreCombo.currentIndex === 0 ? "all" : genreCombo.currentText
    }
    
    function loadTrendsData() {
        loadTrendsStats()
        loadPopularSubjects()
        loadTopAuthors()
        loadPerformanceMatrix()
        loadGenreTrends()
    }
    
    function loadTrendsStats() {
        var stats = reportsManager.getTrendsInsightsStats()
        
        trendingGenreCard.value = stats.trendingGenre || "N/A"
        topAuthorCard.value = stats.mostBorrowedAuthor || "N/A"
        avgBorrowingCard.value = (stats.averageBorrowingFrequency || 0).toFixed(1)
        turnoverRateCard.value = (stats.collectionTurnoverRate || 0).toFixed(2)
        neverBorrowedCard.value = stats.booksNeverBorrowed || "0"
    }
    
    function loadPopularSubjects() {
        subjectBarSet.remove(0, subjectBarSet.count)
        
        var data = reportsManager.getPopularSubjectsGenres(20)
        var categories = []
        
        for (var i = data.length - 1; i >= 0; i--) {
            var genre = data[i].label
            if (genre.length > 20) {
                genre = genre.substring(0, 17) + "..."
            }
            categories.push(genre)
            subjectBarSet.append(data[i].value)
        }
        
        subjectAxis.categories = categories
    }
    
    function loadTopAuthors() {
        authorBarSet.remove(0, authorBarSet.count)
        
        var data = reportsManager.getTopAuthors(20)
        var categories = []
        
        for (var i = data.length - 1; i >= 0; i--) {
            var author = data[i].label
            if (author.length > 25) {
                author = author.substring(0, 22) + "..."
            }
            categories.push(author)
            authorBarSet.append(data[i].value)
        }
        
        authorAxis.categories = categories
    }
    
    function loadPerformanceMatrix() {
        var data = reportsManager.getBooksPerformanceMatrix()
        performanceListView.model = data
    }
    
    function loadGenreTrends() {
        // Clear existing series
        genreTrendsChart.removeAllSeries()
        
        var data = reportsManager.getGenrePopularityTrends(getDateRangeValue())
        var seriesMap = {}
        var colors = ["#F44336", "#2196F3", "#4CAF50", "#FF9800", "#9C27B0", "#00BCD4", "#FF5722"]
        var colorIndex = 0
        
        // Group data by genre
        for (var i = 0; i < data.length; i++) {
            var genre = data[i].genre
            if (!seriesMap[genre]) {
                var series = genreTrendsChart.createSeries(ChartView.SeriesTypeLine, genre, genreTrendsDateAxis, genreTrendsValueAxis)
                series.color = colors[colorIndex % colors.length]
                series.width = 2
                seriesMap[genre] = series
                colorIndex++
            }
            
            var date = new Date(data[i].month + "-01")
            seriesMap[genre].append(date.getTime(), data[i].count)
        }
    }
}
