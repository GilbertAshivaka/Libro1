import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: historyPage
    width: 480
    height: 400
    maximumHeight: 400
    minimumHeight: 400
    maximumWidth: 480
    minimumWidth: 480
//    color: "F5F5F5"
    title: "History"
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowCloseButtonHint

    // User ID to fetch history for - set by parent page
    property int userId: loginManager ? loginManager.currentUserId : 0

    // History data model
    ListModel {
        id: historyModel
    }

    // Load history when window becomes visible or userId changes
    onVisibleChanged: {
        if (visible) {
            loadHistory()
        }
    }

    onUserIdChanged: {
        if (visible) {
            loadHistory()
        }
    }

    function loadHistory() {
        historyModel.clear()

        if (userId <= 0 || typeof userManager === 'undefined') {
            return
        }

        var history = userManager.getBorrowingHistory(userId, 10)

        for (var i = 0; i < history.length; i++) {
            var record = history[i]
            var dateStr = record.issueDate ? formatDate(record.issueDate) : "N/A"
            var status = record.status || "Unknown"

            historyModel.append({
                title: record.title || "Unknown Book",
                author: record.author || "",
                date: dateStr,
                status: status,
                dueDate: record.dueDate ? formatDate(record.dueDate) : "N/A",
                returnDate: record.returnDate ? formatDate(record.returnDate) : "",
                iconSource: "assets/delegateBook.png"
            })
        }
    }

    // Format date string to display format
    function formatDate(dateString) {
        if (!dateString) return "N/A"
        var date = new Date(dateString)
        if (isNaN(date.getTime())) return dateString
        return Qt.formatDate(date, "dd/MM/yyyy")
    }

    Rectangle {
        id: historyPageTitleRect
        width: parent.width
        height: 50
        anchors {
            top: parent.top
            left: parent.left
        }
        clip: true
        color: "white"

        Rectangle {
            id: libraryIconRect
            width: 40
            height: 40
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            Image {
                id: libraryIcon
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/libroIcon.ico"
            }
        }

        Text {
            id: historyPageTitle
            anchors {
                left: libraryIconRect.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            text: "History"
            font.pointSize: 12
            color: "#878585"
        }

        Rectangle{
            id: mainCloseRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: parent.right
                rightMargin: 10
                verticalCenter: historyPageTitleRect.verticalCenter
            }

            Rectangle{
                id: mainCloseImageRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: mainClose
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/close.png"
                }
            }

            MouseArea{
                id: mainCloseMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    mainCloseRect.color = "#E8E3E4"
                }
                onExited: {
                    mainCloseRect.color = "white"
                }

                onClicked: {
                    historyPage.visible = !historyPage.visible
                }
            }
        }

        Image{
            id: infoIcon
            width: 20
            height: 20
            anchors{
                left: historyPageTitle.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            source: "assets/issueInfo1.png"

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    infoIcon.source = "assets/issueInfo.png"
                    historyTooltip1.visible = !historyTooltip1.visible
                }
                onExited:{
                    infoIcon.source = "assets/issueInfo1.png"
                    historyTooltip1.visible = !historyTooltip1.visible
                }
            }
        }

        //Tooltp
        Rectangle {
            id: historyTooltip1
            width: 120
            height: 40
            color: Qt.rgba(0,0,0,0.5)
            visible: false
            z: 3
            radius: 4
            anchors{
                left: infoIcon.left
                leftMargin: 25
                verticalCenter: parent.verticalCenter
            }

            Text {
                id: historyToolTipText
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 5
                    rightMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                color: "white"
                text: "Grab the edges and hold to move."
                font.pixelSize:12
                wrapMode: Text.WordWrap
            }
        }
    }

    Rectangle{
        id: separator
        width: parent.width
        height: 1
        anchors{
            top: historyPageTitleRect.bottom
        }
        color: "black"
    }

    // Empty state display
    Item {
        id: emptyState
        anchors.fill: parent
        anchors.topMargin: historyPageTitleRect.height + separator.height + 20
        visible: historyModel.count === 0

        Column {
            anchors.centerIn: parent
            spacing: 20

            // Empty state icon
            Rectangle {
                width: 100
                height: 100
                radius: 50
                color: "#F0F0F0"
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    source: "assets/delegateBook.png"
                    opacity: 0.5
                    fillMode: Image.PreserveAspectFit
                }
            }

            Text {
                id: emptyTitle
                text: "No Borrowing History"
                font.pointSize: 16
                font.bold: true
                color: "#606060"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: emptyDescription
                text: "You haven't borrowed any books yet.\nPlace reservation to get started!"
                font.pointSize: 11
                color: "#909090"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                lineHeight: 1.4
            }
        }
    }

    ListView {
        id: listView
        width: parent.width
        height: parent.height
        anchors.top: separator.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 10
        clip: true
        visible: historyModel.count > 0

        model: historyModel

        delegate: Item {
            width: listView.width
            height: 60

            Rectangle {
                id: delegateItemRect
                width: parent.width
                height: parent.height
                color: "transparent"
                anchors.left: parent.left

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Image {
                        id: icon
                        source: model.iconSource
                        width: 32
                        height: 32
                    }

                    Column {
                        spacing: 3
                        width: listView.width - icon.width - statusBadge.width - 40

                        Text {
                            text: model.title
                            font.pixelSize: 14
                            font.bold: true
                            color: "black"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: model.author
                            font.pixelSize: 11
                            color: "#808080"
                            elide: Text.ElideRight
                            width: parent.width
                            visible: model.author !== ""
                        }

                        Text {
                            text: "Issued: " + model.date + (model.returnDate ? " • Returned: " + model.returnDate : " • Due: " + model.dueDate)
                            font.pixelSize: 11
                            color: "#606060"
                        }
                    }

                    // Status badge
                    Rectangle {
                        id: statusBadge
                        width: statusText.width + 16
                        height: 22
                        radius: 11
                        color: model.status === "Borrowed" ? "#FFF3E0" :
                               model.status === "Returned" ? "#E8F5E9" : "#FFEBEE"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: statusText
                            text: model.status
                            font.pixelSize: 10
                            font.bold: true
                            color: model.status === "Borrowed" ? "#E65100" :
                                   model.status === "Returned" ? "#2E7D32" : "#C62828"
                            anchors.centerIn: parent
                        }
                    }
                }

                MouseArea{
                    id: delegateItemMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        delegateItemRect.color = "#F5F5F5"
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                    }
                }
            }

            Rectangle {
                width: delegateItemRect.width* .95
                height: 1
                color: "#E0E0E0"
                anchors{
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

            }
        }
    }
}
