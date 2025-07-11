import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: logsContainer
    color: "#f8f9fa"
    anchors.fill: parent

    MouseArea{
        id: logsContainerMA
        anchors.fill: parent
    }

    property alias logsModel: logsListModel
    property string selectedLevel: ""
    property string selectedCategory: ""

    // Signals for backend communication
    signal refreshLogs()
    signal filterChanged(string level, string category)
    signal closeClicked()

    ListModel {
        id: logsListModel
        // This will be populated from C++ backend
    }

    Rectangle {
        id: activityLogsTitleRect
        width: parent.width
        height: 50
        color: "white"
        anchors {
            top: parent.top
            left: parent.left
        }
        clip: true

        Text {
            id: activityLogsTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "System Logs"
            font.pointSize: 12
            color: "#878585"
        }

        Rectangle{
            id: closeBtn
            width: 80
            height: 32
            radius: 25
            border.color: "#878585"
            border.width: 2
            clip: true
            anchors{
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 30
            }

            Text{
                id: closeBtnTxt
                anchors.centerIn: parent
                text: "Close"
                font.pixelSize: 16
                font.bold: true
            }

            MouseArea{
                id: closeBtnMA
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: {
                    closeBtn.color = "#878585"
                    closeBtnTxt.color = "white"
                }
                onExited: {
                    closeBtn.color = "white"
                    closeBtnTxt.color ="#878585"
                }

                onClicked:{
                    closeClicked()
                }
            }
        }
    }


    ColumnLayout {
        // anchors.fill: parent
        anchors{
            top: activityLogsTitleRect.bottom
            topMargin: 10
            bottom: parent.bottom
            bottomMargin: 20
            right: parent.right
            rightMargin: 20
            left: parent.left
            leftMargin: 20
        }

        spacing: 15


        // Filters Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            Text {
                text: "Filter by:"
                font.pixelSize: 14
                color: "#34495e"
            }

            ComboBox {
                id: levelFilter
                model: ["All Levels", "INFO", "WARNING", "ERROR", "DEBUG", "CRITICAL"]
                currentIndex: 0
                onCurrentTextChanged: {
                    selectedLevel = currentIndex === 0 ? "" : currentText
                    filterChanged(selectedLevel, selectedCategory)
                    logsListView.model = activityLogsClass.getLogs(selectedLevel, "")
                }
            }

            ComboBox {
                id: categoryFilter
                model: ["All Categories", "USER_MANAGEMENT", "BOOK_OPERATIONS", "AUTHENTICATION", "SYSTEM"]
                currentIndex: 0
                onCurrentTextChanged: {
                    selectedCategory = currentIndex === 0 ? "" : currentText
                    filterChanged(selectedLevel, selectedCategory)
                    logsListView.model = activityLogsClass.getLogs("", selectedCategory)
                }
            }

            Button {
                text: "Refresh"
                onClicked: {
                    logsListView.model = activityLogsClass.getLogs()
                }
            }

            Item { Layout.fillWidth: true } // Spacer
        }

        // Logs Table
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            border.color: "#e0e0e0"
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                // Table Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 45
                    color: "#f1f3f4"
                    border.color: "#e0e0e0"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 0

                        Text {
                            Layout.preferredWidth: 80
                            text: "Level"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#5f6368"
                        }

                        Text {
                            Layout.preferredWidth: 180
                            text: "Timestamp"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#5f6368"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Log Message"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#5f6368"
                        }
                    }
                }

                // Logs List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }


                    ListView {
                        id: logsListView
                        model: activityLogsClass.getLogs()
                        clip: true

                        ScrollBar.vertical: ScrollBar {
                            id: vbar
                            active: true
                            policy: ScrollBar.AlwaysOn
                            width: 10

                            contentItem: Rectangle {
                                implicitWidth: 10
                                radius: width / 2
                                color: vbar.pressed ? "#818181" : "#c2c2c2"  // Darker when pressed
                            }
                            background: Rectangle {
                                implicitWidth: 10
                                radius: width / 2
                                color: "#f0f0f0"  // Light background color
                            }
                        }

                        delegate: Rectangle {
                            width: logsListView.width
                            height: 50
                            color: index % 2 === 0 ? "white" : "#f8f9fa"
                            border.color: "#e0e0e0"
                            border.width: 0.5

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 15
                                anchors.rightMargin: 15
                                spacing: 0

                                // Log Level with colored indicator
                                Row {
                                    Layout.preferredWidth: 100
                                    spacing: 8

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: {
                                            switch(modelData.logLevel) {
                                                case "INFO": return "#4285f4"
                                                case "WARNING": return "#ff9800"
                                                case "ERROR": return "#f44336"
                                                case "CRITICAL": return "#d32f2f"
                                                case "DEBUG": return "#9c27b0"
                                                default: return "#757575"
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.logLevel || ""
                                        font.pixelSize: 12
                                        color: {
                                            switch(modelData.logLevel) {
                                                case "INFO": return "#4285f4"
                                                case "WARNING": return "#ff9800"
                                                case "ERROR": return "#f44336"
                                                case "CRITICAL": return "#d32f2f"
                                                case "DEBUG": return "#9c27b0"
                                                default: return "#757575"
                                            }
                                        }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Category
                                Text {
                                    Layout.preferredWidth: 140
                                    text: modelData.logCategory || ""
                                    font.pixelSize: 12
                                    color: "#5f6368"
                                    elide: Text.ElideRight
                                }

                                // Timestamp
                                Text {
                                    Layout.preferredWidth: 180
                                    text: {
                                        if (modelData.timestamp) {
                                            var date = new Date(modelData.timestamp)
                                            return Qt.formatDateTime(date, "yyyy-MM-dd hh:mm:ss")
                                        }
                                        return ""
                                    }
                                    font.pixelSize: 12
                                    color: "#5f6368"
                                    elide: Text.ElideRight
                                }

                                // Log Message
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.logMessage || ""
                                    font.pixelSize: 12
                                    color: "#202124"
                                    elide: Text.ElideRight
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    // Show detailed log information
                                    logDetailDialog.showDetails(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Pagination (optional)
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: logsListView.count + " of " + activityLogsClass.getTotalLogsCount() + " row(s) shown." //"10 of 2000 row(s) shown."
                font.pixelSize: 12
                color: "#5f6368"
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Previous"
                enabled: false // Implement pagination logic
            }

            Text {
                text: "1"
                font.pixelSize: 14
                color: "#fff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                width: 30
                height: 30
                // background: Rectangle {
                //     color: "#ff5722"
                //     radius: 4
                // }
            }

            Button {
                text: "Next"
                // Implement pagination logic
            }
        }
    }

    // Log Detail Dialog
    Dialog {
        id: logDetailDialog
        width: 600
        height: 400
        title: "Log Details"
        modal: true

        property var logData: null

        function showDetails(data) {
            logData = data
            open()
        }

        ScrollView {
            anchors.fill: parent

            Column {
                width: parent.width
                spacing: 10

                Text {
                    text: "Level: " + (logDetailDialog.logData ? logDetailDialog.logData.logLevel : "")
                    font.bold: true
                }

                Text {
                    text: "Category: " + (logDetailDialog.logData ? logDetailDialog.logData.logCategory : "")
                }

                Text {
                    text: "Timestamp: " + (logDetailDialog.logData ? logDetailDialog.logData.timestamp : "")
                }

                Text {
                    text: "User: " + (logDetailDialog.logData && logDetailDialog.logData.userName ? logDetailDialog.logData.userName : "System")
                }

                Text {
                    text: "Message:"
                    font.bold: true
                }

                Text {
                    text: logDetailDialog.logData ? logDetailDialog.logData.logMessage : ""
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Text {
                    text: "Details:"
                    font.bold: true
                    visible: logDetailDialog.logData && logDetailDialog.logData.details
                }

                Text {
                    text: logDetailDialog.logData ? logDetailDialog.logData.details : ""
                    wrapMode: Text.WordWrap
                    width: parent.width
                    visible: logDetailDialog.logData && logDetailDialog.logData.details
                }
            }
        }
    }
}
