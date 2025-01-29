import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Effects
import QtQuick.Dialogs
import "DynamicComponentLoader.js" as CustomComponentLoader


Rectangle{
    id: registrationForm
    anchors.fill: parent
    radius: 8
    border.color: "#CDCACA"

    signal closeClicked()

    property var addManyUsers: null
    property string userImageSource: "qrc:Libro1/assets/userImage.png"


    Rectangle{
        id: registrationFormRect
        height: parent.height* .95
        width: parent.width* .95
        anchors.centerIn: parent




        Rectangle{
            id: closeRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: parent.right
                top: parent.top
            }

            Rectangle{
                id: closeImageRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: close
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/close.png"
                }
            }

            MouseArea{
                id: closeMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    closeRect.color = "#E8E3E4"
                }
                onExited: {
                    closeRect.color = "white"
                }

                onClicked: {
                    registrationForm.closeClicked()
                }
            }
        }

        Rectangle{
            id: menuRect
            width: 60
            height: 40
            radius: 4
            anchors{
                right: closeRect.left
                top: parent.top
            }

            Image{
                id: menuImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/menu.png"
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    menuRect.color = "#E8E3E4"
                }
                onExited: {
                    menuRect.color = "white"
                }

                onClicked: {
                    menu.open()
                }
            }

            Menu {
                id: menu
                width: 120
                y: menuRect.height

                MenuItem {
                    text: "New..."
                }
                MenuItem {
                    text: "Open..."
                }
                MenuItem {
                    text: "Save"
                }
            }
        }

        Rectangle{
            id: manyRect
            width: 40
            height: 40
            anchors{
                right: menuRect.left
                top: parent.top
            }

            Image{
                id: many
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/group1.png"
            }

            MouseArea{
                id: manyMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    many.source = "qrc:Libro1/assets/group.png"
                }
                onExited: {
                    many.source = "qrc:Libro1/assets/group1.png"
                }

                onClicked: {
                    CustomComponentLoader.customCreateComponent(addManyUsers,"AddManyUsers", mainPageContainer)
                }
            }
        }


        Item{
            id: scrollItem
            width: parent.width
            anchors{
                top: menuRect.bottom
                topMargin: 5
                bottom: parent.bottom
            }

            ScrollView{
                id: registrationSV
                anchors.fill: parent
    //                    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                contentHeight: 323

                Rectangle {
                    id: adminAvatarRect
                    height: 80
                    width: height
                    radius: width/2
    //                color: "#CECED7"
                    clip: true
                    anchors{
                        top: parent.top
    //                            topMargin: 20
                        left: parent.left
                        leftMargin: 5
                    }

                    color: "transparent"

//                    property string imageSource: "qrc:Libro1/assets/userImage.png"

                    Image {
                        id: sourceItem
                        source: userImageSource
                        anchors.centerIn: parent
                        width: parent.width //* 0.4688
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
                                userImageSource = fileUrl
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
                        onEntered: tooltip.visible = true
                        onExited: tooltip.visible = false
                    }
                }

                //This is a tooltip that shows up when the profilePic is hovered over
                Rectangle {
                    id: tooltip
                    implicitWidth: 166
                    height: 20
                    color: "black"
                    visible: false
                    anchors{
                        left: adminAvatarRect.horizontalCenter
                        verticalCenter: adminAvatarRect.verticalCenter

                    }

                    radius: 5

                    Text {
                        anchors.centerIn: parent
                        color: "white"
                        text: "Click to change profile picture"
                        font.pixelSize: 12
                    }
                }


                //Fisrt Name

                CustomTxtInput{
                    id: firstName
                    anchors{
                        left: parent.left
                        leftMargin: 5
                        top: adminAvatarRect.bottom
                        topMargin: 20
                    }
                    placeHolderText: "FIRST NAME"
                }

                //Second Name

                CustomTxtInput{
                    id: secondName
                    anchors{
                        left: firstName.right
                        leftMargin: 5
                        top: firstName.top
                    }

                    placeHolderText: "SURNAME"
                }

                //ADM

                CustomTxtInput{
                    id: admNo
                    width: parent.width* .27
                    anchors{
                        left: firstName.left
                        top: firstName.bottom
                        topMargin: 10
                        right: firstName.horizontalCenter
                    }

                    placeHolderText: "ADM NO."
                }

                CustomTxtInput{
                    id: wing
                    width: admNo.width
                    anchors{
                        left: admNo.right
                        top: admNo.top
                        leftMargin: 5
                        right: secondName.horizontalCenter
                    }

                    placeHolderText: "BRANCH"
                }

                CustomTxtInput{
                    id: year
                    width: admNo.width
                    anchors{
                        left: wing.right
                        leftMargin: 5
                        top: admNo.top
                        right: secondName.right
                    }

                    placeHolderText: "YEAR"
                }

                CustomTxtInput{
                    id: email
                    anchors{
                        left: firstName.left
                        top: admNo.bottom
                        topMargin: 10
                        right: wing.right
                    }

                    placeHolderText: "EMAIL"
                }

                CustomTxtInput{
                    id: cartegory
                    anchors{
                        left: email.right
                        leftMargin: 5
                        top: email.top
                        right: secondName.right
                    }

                    placeHolderText: "CARTEGORY"
                }

                CustomButton{
                    id: registerButton
                    anchors{
                        right: cartegory.right
                        top: cartegory.bottom
                        topMargin: 20
                    }
                    text: "Register"
                    defaultColor: "#399ED9"
                    hoveredColor: "#399ED9"

                    onClicked: {
                        messageText.text = "User added succsessfully!"
                        messageBox.visible = true
                        notificationSound.play()
                        messageTimer.restart()  // Restart the timer
                    }
                }

                CustomButton{
                    id: cancelButton
                    anchors{
                        right: registerButton.left
                        rightMargin: 7
                        top: registerButton.top
                    }
                    text: "Cancel"
                    defaultColor: "#E0E0E0"
                }

                Rectangle {
                    id: messageBox
                    width: 200
                    height: 100
    //                color: "gray"
                    color: Qt.rgba(0,0,0, 0.4)
                    radius: 8
                    visible: false  // Initially hidden
                    anchors{
                        centerIn: parent
                    }

                    Rectangle{
                        id: infoIconRect
                        width: 20
                        height: 20
                        radius: 4
                        anchors{
                            left: parent.left
                            top: parent.top
                            margins: 5
                        }

                        color: "transparent"

                        Image{
                            id: infoIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: "qrc:Libro1/assets/info.png"
                        }
                    }

                    Text {
                        id: messageText
                        anchors.centerIn: parent
                        color: "white"
                        font.pixelSize: 16
                    }
                }

                // Timer to hide the message after a short delay
                Timer {
                    id: messageTimer
                    interval: 1000  // 3 seconds
                    repeat: false
                    onTriggered: {
                        messageBox.visible = false
                        notificationSound.stop()
                    }
                }

                SoundEffect {
                    id: notificationSound
                    source: "qrc:Libro1/assets/messagePop.wav"
                    volume: 1.0
                    muted: false
    //                onPlayingChanged: {
    //                    if (!playing && messageTimer.running) {
    //                        messageTimer.stop()
    //                        notificationSound.play()
    //                    }
    //                }
                }
            }
        }
    }
}

