import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick.Dialogs
import QtCharts
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
                    source: toolBarAdminProfilePic
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
                }
            }

            Rectangle {
                id: userProfileRect
                width: parent.width* 0.50
                height: width
                radius: width/2
                clip: true
                border.width: 2
                border.color: "white"
                anchors{
                    top: parent.top
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }

                color: "transparent"

                Image {
                    id: sourceItem2
                    source: toolBarAdminProfilePic
                    anchors.centerIn: parent
                    width: parent.width //* 0.4688
                    height: width
                    visible: false
                    fillMode: Image.PreserveAspectCrop
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
                    nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif)"]
                    onAccepted: {
                        if (fileDialog2.currentFile) {
                            var fileUrl = fileDialog2.currentFile
                            console.log("Selected file:", fileUrl)
                            toolBarAdminProfilePic = fileUrl
                        }
                    }
                    onRejected: {
                        console.log("Canceled")
                    }
                }

                MouseArea {
                    anchors.fill: sourceItem2
                    cursorShape: "PointingHandCursor"
                    onClicked: fileDialog2.open()
                    hoverEnabled: true
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

                    LineSeries {
                        name: "Books issued and returned per hour"
                        color: "red"
                        XYPoint { x: 0; y: 5.0 }
                        XYPoint { x: 1; y: 7.5 }
                        XYPoint { x: 2; y: 6.0 }
                        XYPoint { x: 3; y: 8.5 }
                        XYPoint { x: 4; y: 10.0 }
                        XYPoint { x: 5; y: 9.0 }
                        XYPoint { x: 6; y: 11.0 }
                        XYPoint { x: 7; y: 12.5 }
                        XYPoint { x: 8; y: 10.5 }
                        XYPoint { x: 9; y: 8.0 }
                        XYPoint { x: 10; y: 7.0 }
                        XYPoint { x: 11; y: 6.5 }
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
                        cursorShape: "PointingHandCursor"
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
                            // updateChartData()
                            refreshButton.rotation += 360
                        }
                    }

                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
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
}














