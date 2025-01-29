import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Dialogs

Rectangle {
    id: settingsContainer
    width: 400
    height: 300
    anchors.fill: parent

    property string imageSource: "assets/userImage.png"
    signal closeClicked()


    Rectangle{
        id: topItemsContainer
        height: 50
        width: parent.width
        color: "#F0F0F0"
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Rectangle{
            id: backRect
            width: 40
            height: 40
            radius: 4
            color: "#DDDDDD"
            anchors{
                left: parent.left
                leftMargin: 5
                top: parent.top
                topMargin: 5
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
                    settingsContainer.closeClicked()
                }
            }
        }

        Rectangle{
            id: settingsTxtRect
            implicitWidth: settingsTxt.width
            color: "transparent"

            anchors{
                left: backRect.right
                leftMargin: 30
                top: backRect.top
                bottom: backRect.bottom
            }

            Text {
                id: settingsTxt
                anchors.verticalCenter: parent.verticalCenter

                text: "Settings"
                font.bold: false
                font.pointSize: 12
            }
        }
    }

    Rectangle{
        id: accountSettingsRect
        width: parent.width
        height: 140
        anchors{
            top: topItemsContainer.bottom
        }
//        color: "transparent"
        color: "#F0F0F0"


        Rectangle {
            id: profileContainer
            width: parent.width/2
            height: parent.height
            color: "transparent"
            clip: true

            Rectangle{
                id: adminSettingsProfileRect
                width: parent.width* .75
                height: parent.height
                x: profileContainer.width* .20
                anchors{
                    right: parent.right
                }
                color: "transparent"


                //Display the admin profile picture in settings
                Rectangle {
                    id: adminAvatarRect
                    height: 120
                    width: height
                    radius: width/2
    //                color: "#CECED7"
                    clip: true
                    anchors{
                        top: parent.top
                        left: parent.left
                    }


                    color: "transparent"

    //                property string imageSource: "assets/userImage.png"

                    Image {
                        id: sourceItem
                        source: imageSource
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
                                imageSource = fileUrl
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

                Item{
                    id: profileDetailsContainer
                    height: parent.height
                    anchors{
                        left: adminAvatarRect.right
                        leftMargin: 10
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    Text{
                        id: admin
                        y: adminAvatarRect.height* .25
                        //                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Admin")
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Text{
                        id: adminName
                        anchors{
                            top: admin.bottom
                            topMargin: 10
                        }
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Gilbert Ashivaka")
                        font.pixelSize: 16
                    }

                    Text{
                        id: adminNameEdit
                        text: "Edit profile details"
                        anchors{
                            top: adminName.bottom
                        }
                        font.pixelSize: 14 /** (adminLogin.width/300)*/
                        //                        font.underline: true
                        color: "#82C0D3"

                        MouseArea{
                            id: adminNameEditMA
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked:{
                                fileDialog.open()
                            }
                            onPressed: adminNameEdit.color = "blue"
                            onReleased: adminNameEdit.color = "#82C0D3"
                        }
                    }
                }
            }
        }


        Rectangle {
            id: accountOptions
            width: parent.width/2
            height: parent.height
            color: "transparent"
            clip: true
            anchors{
                left: profileContainer.right
                right: parent.right
            }

            Item{
                id: accountOptionsContainer
                width:parent.width* .75
                height: parent.height
                anchors{
                    left: parent.left
                    leftMargin: 20
                }

                Rectangle{
                    id: feedbackRect
                    width: (parent.width-40)/3
                    height: parent.height
                    anchors{
                        left: parent.left
                    }
                    color: "transparent"

                    Rectangle{
                        id: feedbackIconRect
                        height: 40
                        width: 40
                        anchors{
                            left: parent.left
                            top: parent.top
                        }
                        color: "transparent"

                        Image{
                            id: feedbackIcon
                            anchors.fill: parent
                            source: "assets/send-mail.png"
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle{
                        id: feedbackTxtRect
                        anchors{
                            top: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        color: "transparent"

                        Text{
                            id: feedbackTxt
                            width: parent.width
                            height: parent.height
                            anchors{
                                left: parent.left
                                rightMargin: 8
                            }
                            text: "Send feedback about performance of the system"
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
//                            maximumLineCount: 2
                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                Rectangle{
                    id: helpRect
                    width: (parent.width-40)/3
                    height: parent.height
                    anchors{
                        left: feedbackRect.right
                        leftMargin: 20
                    }
                    color: "transparent"

                    Rectangle{
                        id: helpIconRect
                        height: 40
                        width: 40
                        anchors{
                            left: parent.left
                            top: parent.top
                        }
                        color: "transparent"

                        Image{
                            id: helpIcon
                            anchors.fill: parent
                            source: "assets/support-services.png"
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle{
                        id: helpTxtRect
                        anchors{
                            top: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        color: "transparent"

                        Text{
                            id: helpTxt
                            width: parent.width
                            height: parent.height
                            anchors{
                                left: parent.left
                                rightMargin: 8
                            }
                            text: "Contact customer support to get help and resolve issues"
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
//                            maximumLineCount: 2

                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                Rectangle{
                    id: logoutRect
                    width: (parent.width-40)/3
                    height: parent.height
                    anchors{
                        left: helpRect.right
                        leftMargin: 20
                    }
                    color: "transparent"

                    Rectangle{
                        id: logoutIconRect
                        height: 40
                        width: 40
                        anchors{
                            left: parent.left
                            top: parent.top
                        }
                        color: "transparent"

                        Image{
                            id: logoutIcon
                            anchors.fill: parent
                            source: "assets/logout.png"
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                mainLoader.source = "Login.qml"
                            }
                        }
                    }

                    Rectangle{
                        id: logoutTxtRect
                        anchors{
                            top: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        color: "transparent"

                        Text{
                            id: logoutTxt
                            width: parent.width
                            height: parent.height
                            anchors{
                                left: parent.left
                                rightMargin: 8
                            }
                            text: "Logout\nThis will return the application to login page"
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
//                            maximumLineCount: 2
                        }

                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                mainLoader.source = "Login.qml"
                            }
                        }
                    }
                }

            }
        }
    }

    Rectangle{
        id: midRect
        width: parent.width
        height: 20
        anchors.top: accountSettingsRect.bottom
    }

    ScrollView{
        id: settingsSV
        anchors{
            top: midRect.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: settingsPage.flowItemHeight + 120

        SettingsPage{
            id: settingsPage
            width: settingsSV.width
        }
    }
}
