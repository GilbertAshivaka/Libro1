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

    property int itemsPerPage: 100
    property string category: "all"
    property int totalPages: Math.ceil(activityLogsClass.getTotalLogsCount() / itemsPerPage)
    property int previousPage: 0
    property int currentPage: 1
    property int nextPage: 2


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
                    resetPagination()
                    fetchCurrentPageData()
                    // logsListView.model = activityLogsClass.getLogs(selectedLevel, "")
                }
            }

            ComboBox {
                id: categoryFilter
                model: ["All Categories", "USER_MANAGEMENT", "BOOK_OPERATIONS", "AUTHENTICATION", "SYSTEM"]
                currentIndex: 0
                onCurrentTextChanged: {
                    selectedCategory = currentIndex === 0 ? "" : currentText
                    filterChanged(selectedLevel, selectedCategory)
                    resetPagination()
                    fetchCurrentPageData()
                    // logsListView.model = activityLogsClass.getLogs("", selectedCategory)
                }
            }

            Button {
                text: "Refresh"
                onClicked: {
                    selectedLevel = ""
                    selectedCategory = ""
                    fetchCurrentPageData()
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
                    Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }


                    ListView {
                        boundsBehavior: Flickable.StopAtBounds
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
            Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
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

    Rectangle {
        id: navigationRect
        width: 200
        height: 50
        radius: 8
        border.color: "lightgray"
        color: "white"
        opacity: 0.9

        // Initial position
        x: Math.min(Math.max(0, parent.width - 230), parent.width - width)
        y: Math.min(Math.max(0, parent.height - 80), parent.height - height)

        // Ensure the rectangle stays within parent bounds when parent is resized
        onXChanged: {
            if (x < 0) x = 0
            if (x > parent.width - width) x = parent.width - width
        }
        onYChanged: {
            if (y < 0) y = 0
            if (y > parent.height - height) y = parent.height - height
        }

        MouseArea {
            id: navigationRectMA
            anchors.fill: parent
            drag {
                target: parent
                minimumX: 0
                minimumY: 0
                maximumX: parent.parent.width - parent.width
                maximumY: parent.parent.height - parent.height
                smoothed: true
            }
            onReleased: console.log("Rectangle moved to x:", parent.x, "y:", parent.y)
        }

        Image {
            id: previousNavigator
            width: 32
            height: 32
            source: enabled ? "assets/leftArrow.png" : "assets/leftChevron.png"
            enabled: previousPage >0
            anchors{
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }

            MouseArea{
                id: previousPageMA
                anchors.fill: parent
                onClicked: {
                    if (currentPage > 1) {
                        --currentPage
                        --previousPage
                        --nextPage
                        fetchCurrentPageData()
                    }
                }
            }
        }

        Text {
            id: previousPageText
            text: previousPage == 0 ? "" : previousPage
            color: "gray"
            font.pointSize: 11
            anchors{
                left: previousNavigator.right
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
        }

        Image {
            id: nextNavigator
            width: 32
            height: 32
            source: enabled ? "assets/rightArrow.png" : "assets/rightChevron.png"
            enabled: currentPage < totalPages
            anchors{
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }

            MouseArea{
                id: nextPageMA
                anchors.fill: parent
                onClicked: {
                    if (currentPage < totalPages) {
                        ++currentPage
                        ++previousPage
                        ++nextPage
                        fetchCurrentPageData()
                    }
                }
            }
        }

        Text {
            id: nextPageText
            text: nextPage <= totalPages ? nextPage : ""
            color: "gray"
            font.pointSize: 11
            anchors{
                right: nextNavigator.left
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
        }

        TextField {
            id: pageInput
            height: parent.height * 0.8
            font.pointSize: 11
            color: "red"
            validator: IntValidator { bottom: 1; top: totalPages }
            anchors {
                left: previousPageText.right
                leftMargin: 5
                right: nextPageText.left
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }
            text: currentPage
            horizontalAlignment: TextField.AlignHCenter
            verticalAlignment: TextField.AlignVCenter

            onAccepted: {
                let newPage = parseInt(text)
                if (newPage >= 1 && newPage <= totalPages) {
                    currentPage = newPage
                    previousPage = Math.max(0, newPage - 1)
                    nextPage = Math.min(totalPages, newPage + 1)
                    fetchCurrentPageData()
                } else {
                    text = currentPage  // Reset to valid value
                }
            }
        }
    }


    function resetPagination() {
        currentPage = 1
        previousPage = 0
        nextPage = 2
    }

    function fetchCurrentPageData() {
        const offset = (currentPage -1) * itemsPerPage //we set currentPage at 1 so we subtract to get the offset to be 0
        const newData = activityLogsClass.getLogs(selectedLevel, selectedCategory, 100, offset)
        logsListView.model = newData

        totalPages = Math.ceil(activityLogsClass.getTotalLogsCount(selectedLevel, selectedCategory) / itemsPerPage)
    }



    Component.onCompleted: {
        resetPagination()
        fetchCurrentPageData()
        totalPages = Math.ceil(activityLogsClass.getTotalLogsCount() / itemsPerPage)
        console.log("Activity Logs Pages: ", totalPages)
    }
}
