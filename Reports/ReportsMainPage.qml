import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15
import Qt5Compat.GraphicalEffects
import "../DynamicComponentLoader.js" as CustomComponentLoader

Rectangle {
    id: reportsMainPage
    anchors.fill: parent

    // Signal for closing/going back
    signal closeClicked()

    property var collectionReportsPage: null
    property var circulationReportsPage: null

    // Mouse area to catch clicks
    MouseArea {
        id: reportsPageMA
        anchors.fill: parent
        onPressed: mouse.accepted = false
    }

    color: "#F5F5F5"

    // Header section
    Rectangle {
        id: topRect
        width: parent.width
        height: 80
        color: "#FFFFFF"
        anchors.top: parent.top

        Rectangle {
            id: backRect
            width: 32
            height: 32
            radius: 4
            color: backMA.containsMouse ? "#E8E3E4" : "#DDDDDD"
            anchors {
                left: parent.left
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }

            Image {
                id: back
                width: 20
                height: 20
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/backArrow.png"
            }

            MouseArea {
                id: backMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    reportsMainPage.closeClicked()
                }
            }
        }

        RowLayout {
            anchors {
                left: backRect.right
                leftMargin: 30
                right: parent.right
                rightMargin: 30
                verticalCenter: parent.verticalCenter
            }
            spacing: 20

            Image {
                id: reportsIcon
                source: "assets/reportsIcon.png"
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "Reports & Analytics"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: "#212121"
                    font.family: "Arial"
                }

                Text {
                    text: "Comprehensive insights into your library operations"
                    font.pixelSize: 13
                    color: "#757575"
                    font.family: "Arial"
                }
            }

            Rectangle {
                id: topOptionsRect
                Layout.preferredHeight: 32
                Layout.preferredWidth: 200
                radius: 4
                border.color: "#DCD8D8"
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 10

                    Image {
                        id: print
                        source: "assets/print.png"
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: printMenu.open()
                        }
                    }

                    Text {
                        id: printTxt
                        text: "Print"
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Arial"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: printMenu.open()
                        }
                    }

                    Image {
                        id: exportIcon
                        source: "assets/export.png"
                        height: 20
                        width: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: formatMenu.open()
                        }
                    }

                    Text {
                        id: exportTxt
                        text: "Export"
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Arial"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: formatMenu.open()
                        }
                    }
                }

                Menu {
                    id: printMenu
                    y: topOptionsRect.height

                    MenuItem { text: "Whole page" }
                    MenuItem { text: "Only charts" }
                }

                Menu {
                    id: formatMenu
                    y: topOptionsRect.height

                    MenuItem { text: "Choose format"; enabled: false }
                    MenuItem { text: "PDF" }
                    MenuItem { text: "CSV/Excel" }
                    MenuItem { text: "Image" }
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#E0E0E0"
        }
    }

    // Main content area
    ScrollView {
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        anchors {
            top: topRect.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 30

            Item { height: 10 }

            // Quick Stats Overview
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                spacing: 16

                Text {
                    text: "Quick Overview"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: "#212121"
                    font.family: "Arial"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 16
                    columnSpacing: 16

                    StatCard {
                        title: "Total Books"
                        value: "12,547"
                        trend: "+145 this month"
                        trendDirection: "up"
                        accentColor: "#2196F3"
                        Layout.fillWidth: true
                    }

                    StatCard {
                        title: "Active Loans"
                        value: "1,823"
                        trend: "-12 from last week"
                        trendDirection: "down"
                        accentColor: "#4CAF50"
                        Layout.fillWidth: true
                    }

                    StatCard {
                        title: "Overdue Items"
                        value: "47"
                        trend: "+5 from yesterday"
                        trendDirection: "up"
                        accentColor: "#FF9800"
                        Layout.fillWidth: true
                    }

                    StatCard {
                        title: "Active Users"
                        value: "3,421"
                        trend: "89% engagement"
                        trendDirection: "up"
                        accentColor: "#9C27B0"
                        Layout.fillWidth: true
                    }
                }
            }

            // Report Categories
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 30
                Layout.rightMargin: 30
                spacing: 16

                Text {
                    text: "Report Categories"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: "#212121"
                    font.family: "Arial"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 20
                    columnSpacing: 20

                    ReportCategoryCard {
                        title: "Collection Overview"
                        description: "Analyze your book collection, genres, and availability"
                        icon: "📚"
                        cardColor: "#2196F3"
                        stats: ["12,547 Books", "45 Genres", "89% Available"]
                        Layout.fillWidth: true
                        onClicked: function(){
                            CustomComponentLoader.customCreateComponent(collectionReportsPage,"Reports/CollectionReportsPage", mainPageContainer)
                        }
                    }

                    ReportCategoryCard {
                        title: "Circulation Analytics"
                        description: "Track borrowing trends and circulation patterns"
                        icon: "🔄"
                        cardColor: "#4CAF50"
                        stats: ["1,823 Active", "156 Today", "24 days avg"]
                        Layout.fillWidth: true
                        onClicked: CustomComponentLoader.customCreateComponent(circulationReportsPage,"CirculationReportsPage", mainPageContainer)
                    }

                    ReportCategoryCard {
                        title: "User Engagement"
                        description: "Monitor user activity and demographics"
                        icon: "👥"
                        cardColor: "#9C27B0"
                        stats: ["3,421 Users", "2,847 Active", "574 New"]
                        Layout.fillWidth: true
                        onClicked: console.log("Users clicked")
                    }

                    ReportCategoryCard {
                        title: "Financial Reports"
                        description: "View fines, payments, and financial metrics"
                        icon: "💰"
                        cardColor: "#FF9800"
                        stats: ["$12,450 Collected", "$2,340 Pending", "84% Rate"]
                        Layout.fillWidth: true
                        onClicked: console.log("Financial clicked")
                    }

                    ReportCategoryCard {
                        title: "Overdue & Compliance"
                        description: "Monitor overdue items and compliance rates"
                        icon: "⚠️"
                        cardColor: "#F44336"
                        stats: ["47 Overdue", "12 days avg", "8 Critical"]
                        Layout.fillWidth: true
                        onClicked: console.log("Overdue clicked")
                    }

                    ReportCategoryCard {
                        title: "Lost & Damaged"
                        description: "Track lost and damaged book reports"
                        icon: "📕"
                        cardColor: "#E91E63"
                        stats: ["23 Lost", "15 Damaged", "$2,450 Cost"]
                        Layout.fillWidth: true
                        onClicked: console.log("Lost clicked")
                    }

                    ReportCategoryCard {
                        title: "Reservation Analytics"
                        description: "Analyze reservation patterns and fulfillment"
                        icon: "📖"
                        cardColor: "#00BCD4"
                        stats: ["89 Active", "145 Fulfilled", "92% Rate"]
                        Layout.fillWidth: true
                        onClicked: console.log("Reservations clicked")
                    }

                    ReportCategoryCard {
                        title: "Digital Materials"
                        description: "Monitor digital resources and equipment loans"
                        icon: "💻"
                        cardColor: "#3F51B5"
                        stats: ["342 Items", "87 Borrowed", "74% Usage"]
                        Layout.fillWidth: true
                        onClicked: console.log("Digital clicked")
                    }

                    ReportCategoryCard {
                        title: "Trends & Insights"
                        description: "Discover popular trends and reading patterns"
                        icon: "📈"
                        cardColor: "#FF5722"
                        stats: ["Fiction Top", "45% Growth", "320 Authors"]
                        Layout.fillWidth: true
                        onClicked: console.log("Trends clicked")
                    }
                }
            }

            Item { height: 20 }
        }
    }

    // StatCard component
    component StatCard: Rectangle {
        id: statCard

        property string title: ""
        property string value: ""
        property string trend: ""
        property string trendDirection: "up"
        property color accentColor: "#2196F3"

        height: 120
        radius: 8
        color: "#FFFFFF"
        border.color: "#E0E0E0"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text {
                text: statCard.title
                font.pixelSize: 13
                color: "#757575"
                font.family: "Arial"
            }

            Text {
                text: statCard.value
                font.pixelSize: 28
                font.weight: Font.Bold
                color: "#212121"
                font.family: "Arial"
            }

            Item { Layout.fillHeight: true }

            Text {
                text: statCard.trend
                font.pixelSize: 11
                color: statCard.trendDirection === "up" ? "#4CAF50" : "#F44336"
                font.family: "Arial"
            }
        }

        Rectangle {
            width: parent.width
            height: 3
            color: statCard.accentColor
            anchors.top: parent.top
            radius: statCard.radius
        }
    }

    // ReportCategoryCard component
    component ReportCategoryCard: Rectangle {
        id: categoryCard

        property string title: ""
        property string description: ""
        property string icon: ""
        property color cardColor: "#2196F3"
        property var stats: []

        signal clicked()

        height: 200
        radius: 12
        color: "#FFFFFF"
        border.color: mouseArea.containsMouse ? categoryCard.cardColor : "#E0E0E0"
        border.width: mouseArea.containsMouse ? 2 : 1

        Behavior on border.color { ColorAnimation { duration: 200 } }
        Behavior on border.width { NumberAnimation { duration: 200 } }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: categoryCard.clicked()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Text {
                    text: categoryCard.icon
                    font.pixelSize: 32
                }

                Text {
                    text: categoryCard.title
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#212121"
                    Layout.fillWidth: true
                    font.family: "Arial"
                }
            }

            Text {
                text: categoryCard.description
                font.pixelSize: 13
                color: "#757575"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.family: "Arial"
            }

            Item { Layout.fillHeight: true }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: categoryCard.stats

                    Rectangle {
                        width: statLabel.width + 16
                        height: 28
                        radius: 14
                        color: Qt.rgba(categoryCard.cardColor.r,
                                      categoryCard.cardColor.g,
                                      categoryCard.cardColor.b, 0.1)

                        Text {
                            id: statLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: categoryCard.cardColor
                            font.family: "Arial"
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 4
            color: categoryCard.cardColor
            anchors.top: parent.top
            radius: categoryCard.radius
        }
    }
}
