import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick.Dialogs
import "ui"
import "DynamicComponentLoader.js" as CustomComponentLoader



Rectangle {
    id: page2
    width: 1000
    height: 500
    visible: true
    color: "#f4f4f4"

    property string toolBarAdminProfilePic: "qrc:Libro1/assets/userImage.png"
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
                    onClicked: fileDialog.open()
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
}

