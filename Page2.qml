import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick.Dialogs
import QtCharts
import QtCore
import "ui"
import "DynamicComponentLoader.js" as CustomComponentLoader



Rectangle {
    id: page2
    width: 1000
    height: 500
    visible: true
    color: "#f4f4f4"

    property string toolBarAdminProfilePic: "assets/userImage.png"
    property var moreTools: null
    property var settingsPage: null

    Settings {
        id: appSettings
        category: "UserProfile"
        property string profilePicturePath: "assets/userImage.png" // default image
    }

    ToolBar {
        id: toolBar
        anchors.top: parent.top
        height: 50
        width: parent.width

        Rectangle{
            anchors.fill: parent

            Rectangle {
                id: libraryIconRect
                width: 40
                height: 40
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Image {
                    id: libraryIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/libroIcon.ico"
                }
            }

            Rectangle {
                id: libraryNameRect
                width: libraryName.width
                anchors {
                    left: libraryIconRect.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    id: libraryName
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Libro Integrated Library Management System")
                    font.pointSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                id: toolBarAdminProfilePicRect
                height: 45
                width: height
                radius: width / 2
                clip: true
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 5
                }

                color: "transparent"

                Image {
                    id: sourceItem
                    source: appSettings.profilePicturePath
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                }

                MultiEffect {
                    source: sourceItem
                    anchors.fill: sourceItem
                    maskEnabled: true
                    maskSource: mask
                }

                Item {
                    id: mask
                    width: sourceItem.width
                    height: sourceItem.height
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        width: sourceItem.width
                        height: sourceItem.height
                        radius: width / 2
                        color: "black"
                    }
                }

                FileDialog {
                    id: fileDialog
                    title: "Select Profile Picture"
                    nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif)"]
                    onAccepted: {
                        if (fileDialog.currentFile) {
                            var fileUrl = fileDialog.currentFile
                            console.log("Selected file:", fileUrl)
                            toolBarAdminProfilePic = fileUrl
                        }
                    }
                    onRejected: {
                        console.log("Canceled")
                    }
                }

                MouseArea {
                    anchors.fill: sourceItem
                    cursorShape: "PointingHandCursor"
                    onClicked: {
                        mainDrawer.open()
                        // fileDialog.open()
                    }
                    hoverEnabled: true
                }
            }

            Rectangle{
                id: otherToolsRect
                width: 40
                height: 40
                radius: 4
                anchors{
                    right: toolBarAdminProfilePicRect.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Rectangle{
                    id: otherToolsIconRect
                    width: 20
                    height: 20
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image{
                        id: otherToolsIcon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/otherToolsIcon.png"
                    }
                }

                MouseArea{
                    id: otherToolsMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        otherToolsRect.color = "#E8E3E4"
                    }
                    onExited: {
                        otherToolsRect.color = "white"
                    }

                    onClicked: {
                        CustomComponentLoader.customCreateComponent(moreTools,"ToolsContainerPage", mainPageContainer)
                    }
                }
            }

            Rectangle{
                id: helpRect
                width: 40
                height: 40
                radius: 4
                anchors{
                    right: otherToolsRect.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Rectangle{
                    id: helpIconRect
                    width: 30
                    height: 30
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image{
                        id: helpIcon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/helpIcon.png"
                    }
                }

                MouseArea{
                    id: helpMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        helpRect.color = "#E8E3E4"
                    }
                    onExited: {
                        helpRect.color = "white"
                    }

                    onClicked: {

                    }
                }
            }

            Searchbox{
                id: mainScreenSearchbox
                width: 400
                height: 30
                anchors{
                    right: helpRect.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Rectangle{
        id: mainContainer
        anchors{
            left: parent.left
            right: parent.right
            top: toolBar.bottom
            bottom: parent.bottom
        }
        color: "transparent"
        clip: true


        Rectangle {
            id: mainPageContainer
            radius: 8
            anchors {
                left: buttonsRect.right
                leftMargin: 20
                //                top: toolBar.bottom
                top: parent.top
                topMargin: 10
                right: parent.right
                bottom: parent.bottom
            }
            color: "#FBFBFB"
            border.color: "#CDCACA"
            clip: true

            Loader{
                id: mainPageContainerLoader
                anchors.fill: parent
                source: "QuickTools1.qml"
            }
        }

        LeftButtons {
            id: buttonsRect
            width: parent.width * 0.21
            height: parent.height * 0.65
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        DynamicBox {
            id: dynamicBox
            visible: width > 200 && height > 210

            anchors {
                top: buttonsRect.bottom
                topMargin: 10
                left: parent.left
                right: buttonsRect.right
                bottom: parent.bottom
            }
            Component.onCompleted: {
                console.log("Width: ", width, "Height: ", height)
            }
        }
    }

    Drawer{
        id: mainDrawer
        edge: Qt.RightEdge
        width: parent.width* .25
        height: parent.height //* .88

        Rectangle{
            id: rightPane
            anchors.fill: parent
            radius: 8
            color: "#DBE0E7"
            clip: true

            Image {
                id: notificationIcon
                source: "assets/bell.png"
                width: 24
                height: 24
                anchors{
                    top: parent.top
                    topMargin: 20
                    left: parent.left
                    leftMargin: 20
                }
                fillMode: Image.PreserveAspectFit
                MouseArea{
                    anchors.fill: parent
                    cursorShape: "PointingHandCursor"
                }
            }

            Image {
                id: settingsIcon
                source: "assets/settings.png"
                width: 24
                height: 24
                anchors{
                    top: parent.top
                    topMargin: 20
                    right: parent.right
                    rightMargin: 20
                }
                fillMode: Image.PreserveAspectFit
                MouseArea{
                    anchors.fill: parent
                    cursorShape: "PointingHandCursor"

                    onClicked: {
                        mainDrawer.close()
                        CustomComponentLoader.customCreateComponent(settingsPage,"Settings/SettingsPage", page2)
                    }
                }
            }

            Rectangle {
                id: userProfileRect
                width: parent.width * 0.50
                height: width
                radius: width/2
                clip: true
                border.width: 2
                border.color: "white"
                anchors {
                    top: parent.top
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                color: "transparent"

                Image {
                    id: sourceItem2
                    source: appSettings.profilePicturePath  // Load from Settings
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    visible: false
                    fillMode: Image.PreserveAspectCrop

                    // Fallback if image fails to load
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Failed to load profile picture, using default")
                            source = "assets/userImage.png" // default image
                        }
                    }
                }

                MultiEffect {
                    source: sourceItem2
                    anchors.fill: sourceItem2
                    maskEnabled: true
                    maskSource: mask2
                }

                Item {
                    id: mask2
                    width: sourceItem2.width
                    height: sourceItem2.height
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        width: sourceItem2.width
                        height: sourceItem2.height
                        radius: width / 2
                        color: "black"
                    }
                }

                FileDialog {
                    id: fileDialog2
                    title: "Select Profile Picture"
                    nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif *.bmp)"]
                    onAccepted: {
                        if (fileDialog2.currentFile) {
                            var fileUrl = fileDialog2.currentFile.toString()
                            console.log("Selected file:", fileUrl)

                            // Save to Settings
                            appSettings.profilePicturePath = fileUrl
                            console.log("Profile picture saved to settings")

                            // Optional: Show confirmation
                            // showNotification("Profile picture updated successfully")
                        }
                    }
                    onRejected: {
                        console.log("File selection canceled")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fileDialog2.open()
                    hoverEnabled: true

                    // Optional: Add hover effect
                    onEntered: {
                        userProfileRect.opacity = 0.8
                    }
                    onExited: {
                        userProfileRect.opacity = 1.0
                    }
                }

                // Optional: Add a camera icon overlay to indicate it's clickable
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "#000000"
                    opacity: 0.6
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: 8
                    }

                    Text {
                        text: "📷"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fileDialog2.open()
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            Text {
                id:adminLabel
                text: "Admin: " + "Noel Nonstein" //the name should be dynamically fetched from the database
                color: "#1E293B"
                font.pixelSize: 12
                font.weight: Font.Bold
                font.italic: true
                anchors{
                    top: userProfileRect.bottom
                    topMargin: 20
                    horizontalCenter: userProfileRect.horizontalCenter
                }
            }

            RoundButton{
                id: helpButton
                text: "Help and Documentation"
                width: parent.width * .90
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: adminLabel.bottom
                    topMargin: 10
                }

                onClicked: {

                }
            }

            RoundButton{
                id: logoutButton
                text: "Logout"
                width: parent.width * .90
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: helpButton.bottom
                    topMargin: 10
                }

                onClicked: {
                    mainDrawer.close()
                    mainLoader.source = "Login.qml"
                }
            }

            Rectangle {
                id: graphRect
                width: parent.width * 0.95
                height: parent.height* 0.40
                color: "transparent"
                anchors {
                    top: logoutButton.bottom
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }

                ChartView {
                    id: usageChart
                    anchors.fill: parent
                    title: "Today's Activity"
                    antialiasing: true
                    legend.visible: true

                    ValuesAxis {
                        id: xAxis
                        titleText: "Hour of Day"
                        min: 0
                        max: 23
                        tickCount: 12
                        labelFormat: "%d"
                    }

                    ValuesAxis {
                        id: yAxis
                        titleText: "Transactions"
                        min: 0
                        tickCount: 5
                        labelFormat: "%d"
                    }

                    LineSeries {
                        id: activitySeries
                        name: "Books Issued & Returned"
                        color: "#3B82F6"
                        width: 2
                        axisX: xAxis
                        axisY: yAxis

                        Component.onCompleted: {
                            updateChartData()
                        }
                    }
                }

                Rectangle {
                    id: refreshButton
                    width: 36
                    height: 36
                    radius: 18
                    color: "#F1F5F9"
                    border.color: "#E2E8F0"
                    border.width: 1
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 12
                    }

                    Text {
                        text: "↻"
                        color: "#475569"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: {
                            refreshButton.color = "#E2E8F0"
                            refreshButton.scale = 1.1
                        }
                        onExited: {
                            refreshButton.color = "#F1F5F9"
                            refreshButton.scale = 1.0
                        }
                        onClicked: {
                            analyticsManager.refreshData()
                            refreshButton.rotation += 360
                        }
                    }

                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                }

                // No data message
                Text {
                    visible: activitySeries.count === 0
                    text: "No activity recorded today"
                    color: "#64748B"
                    font.pixelSize: 14
                    anchors.centerIn: parent
                }

                Connections {
                    target: analyticsManager
                    function onTodayActivityDataChanged() {
                        updateChartData()
                    }
                }
            }

            // Footer with copyright
            Rectangle {
                id: footerSection
                width: parent.width * 0.9
                height: 50
                radius: 8
                color: "transparent"
                // border.color: "#E2E8F0"
                // border.width: 1
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 10
                    // right: parent.right
                    // rightMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }

                Item {
                    height: 32
                    width: parent.width
                    anchors{
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        id: version
                        text: "Libro ILMS 1.0.0"
                        color: "#1E293B"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.italic: true
                        anchors{
                            bottom: copyright.top
                            bottomMargin: 2
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Text {
                        id: copyright
                        text: "© Libro 2025"
                        color: "#64748B"
                        font.pixelSize: 10
                        font.italic: true
                        anchors{
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }

    //update the activity chart
    function updateChartData() {
        activitySeries.clear()

        var data = analyticsManager.todayActivityData
        var maxCount = 0

        // Find max count for Y axis scaling
        for (var i = 0; i < data.length; i++) {
            if (data[i].count > maxCount) {
                maxCount = data[i].count
            }
        }

        // Set Y axis max to a nice round number
        yAxis.max = Math.max(10, Math.ceil(maxCount * 1.2))

        // Add data points
        for (var j = 0; j < data.length; j++) {
            activitySeries.append(data[j].hour, data[j].count)
        }

        // Update X axis range based on data
        if (data.length > 0) {
            var minHour = data[0].hour
            var maxHour = data[data.length - 1].hour

            // Add padding to X axis
            xAxis.min = Math.max(0, minHour - 1)
            xAxis.max = Math.min(23, maxHour + 1)
        } else {
            // Default to full day if no data
            xAxis.min = 0
            xAxis.max = 23
        }

        console.log("Chart updated with", data.length, "data points")
    }
}














