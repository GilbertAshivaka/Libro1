import QtQuick
import QtCharts
import QtQuick.Controls

Rectangle {
    id: reportsPage
    anchors.fill: parent
    signal closeClicked()

    MouseArea{
        id: reportsPageMA
        anchors.fill: parent
    }

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
                    width: 100
                    y: print.height

                    MenuItem{
                        text: "Whole page"
                    }
                    MenuItem{
                        text: "Only charts"
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
                    width: 100
                    y: exportIcon.height

                    MenuItem{
                        text: "Choose format"
                        enabled: false
                    }
                    MenuItem{
                        text: "PDF"
                    }
                    MenuItem{
                        text: "CSV/Exel"
                    }
                    MenuItem{
                        text: "Image"
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
                text: qsTr("Most active category")
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
                text: qsTr("20234")
                anchors{
                    left: separator2.right
                    verticalCenter: totalBooksTxt.verticalCenter
                }
                font.family: "Arial"
            }

            Text {
                id: totalUsers
                text: qsTr("3046")
                anchors{
                    left: separator2.right
                    verticalCenter: totalUsersTxt.verticalCenter
                }
                font.family: "Arial"
            }

            Text {
                id: mostActive
                text: qsTr("Form 4 East")
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
                text: qsTr("Books issued today")
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

            Text {
                id: issuedBooks
                text: qsTr("203")
                anchors{
                    left: separator3.right
                    verticalCenter: issuedBooksTxt.verticalCenter
                }
                font.family: "Arial"
            }

            Text {
                id: overdueBooks
                text: qsTr("23")
                anchors{
                    left: separator3.right
                    verticalCenter: overdueBooksTxt.verticalCenter
                }
                font.family: "Arial"
            }

            Text {
                id: lostBooks
                text: qsTr("5")
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

    Rectangle{
        id: overviewBtnRect
        height: 40
        width: overview.width +16
        anchors{
            top: separator4.bottom
            left: parent.left
            leftMargin: 20
        }
        Text {
            id: overview
            text: qsTr("Overview")
            anchors{
                left: parent.left
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }

        Rectangle{
            id: bottomRect
            width: parent.width
            height: 2
            visible: true
            anchors{
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            color: "#399ED9"
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered:{
                overviewBtnRect.color = "#F5F5F5"
            }

            onExited: {
                overviewBtnRect.color = "transparent"
            }

            onClicked: {
                reportLoader.source = "ReportsOverviewContainer.qml"
                bottomRect2.visible = false
                bottomRect3.visible = false
                bottomRect4.visible = false
                bottomRect.visible = true
            }
        }
    }

    Rectangle{
        id: separator5
        width: 1
        height: overviewBtnRect.height* .7
        anchors{
            left: overviewBtnRect.right
            verticalCenter: overviewBtnRect.verticalCenter
        }
        color: "lightgray"
    }

    Rectangle{
        id: booksBtnRect
        height: 40
        width: overview.width +16
        anchors{
            top: separator4.bottom
            left: separator5.right
//            leftMargin: 20
        }
        Text {
            id: books
            text: qsTr("Books")
            anchors{
                left: parent.left
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }

        Rectangle{
            id: bottomRect2
            width: parent.width
            height: 2
            visible: false
            anchors{
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            color: "#399ED9"
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered:{
                booksBtnRect.color = "#F5F5F5"
            }

            onExited: {
                booksBtnRect.color = "transparent"
            }

            onClicked: {
                reportLoader.source = "ReportsBooksContainer.qml"
                bottomRect.visible = false
                bottomRect3.visible = false
                bottomRect4.visible = false
                bottomRect2.visible = true
            }
        }
    }

    Rectangle{
        id: separator6
        width: 1
        height: booksBtnRect.height* .7
        anchors{
            left: booksBtnRect.right
            verticalCenter: booksBtnRect.verticalCenter
        }
        color: "lightgray"
    }

    Rectangle{
        id: usersBtnRect
        height: 40
        width: overview.width +16
        anchors{
            top: separator4.bottom
            left: separator6.right
//            leftMargin: 20
        }
        Text {
            id: users
            text: qsTr("Users")
            anchors{
                left: parent.left
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }

        Rectangle{
            id: bottomRect3
            width: parent.width
            height: 2
            visible: false
            anchors{
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            color: "#399ED9"
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered:{
                usersBtnRect.color = "#F5F5F5"
            }

            onExited: {
                usersBtnRect.color = "transparent"
            }

            onClicked: {
                reportLoader.source = "ReportsUsersContainer.qml"
                bottomRect2.visible = false
                bottomRect.visible = false
                bottomRect4.visible = false
                bottomRect3.visible = true
            }
        }
    }

    Rectangle{
        id: separator7
        width: 1
        height: usersBtnRect.height* .7
        anchors{
            left: usersBtnRect.right
            verticalCenter: usersBtnRect.verticalCenter
        }
        color: "lightgray"
    }


    Rectangle{
        id: activityBtnRect
        height: 40
        width: overview.width +16
        anchors{
            top: separator4.bottom
            left: separator7.right
//            leftMargin: 20
        }
        Text {
            id: activity
            text: qsTr("Activity")
            anchors{
                left: parent.left
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }

        Rectangle{
            id: bottomRect4
            width: parent.width
            height: 2
            visible: false
            anchors{
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            color: "#399ED9"
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered:{
                activityBtnRect.color = "#F5F5F5"
            }

            onExited: {
                activityBtnRect.color = "transparent"
            }

            onClicked: {
                reportLoader.source = "ReportsActivityContainer.qml"
                bottomRect2.visible = false
                bottomRect3.visible = false
                bottomRect.visible = false
                bottomRect4.visible = true
            }
        }
    }

    Loader{
        id: reportLoader
        width: parent.width
        anchors{
            top: overviewBtnRect.bottom
            topMargin: 10
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        source: "ReportsOverviewContainer.qml"
    }
}

