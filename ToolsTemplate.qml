import QtQuick
import QtQuick.Controls


Rectangle {
    id: backupItem
    width: 200
    height: 200
    color: "transparent"
    property string icon: "assets/cloudBackuprestore.png"
    property string description: "Backup and Restore"
    property var instruction1: null
    property var instruction2: null
    property var instruction3: null



    Item {
        id: containerItem3
        anchors{
            top: parent.top
            bottom: parent.verticalCenter
            right: parent.right
            left: parent.left
        }

        Rectangle{
            id: iconRect3
            width: 64
            height: 64
            color: "transparent"
            anchors{
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }

            Image{
                id: backupIcon
                anchors.fill: parent
                source: icon
                fillMode: Image.PreserveAspectFit
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: "PointingHandCursor"
                onEntered: {
    //                        x.color = "blue"
                }
                onExited: {
    //                        x.color = "#878585"
                }
                onClicked: {
                    if(instruction1){
                        instruction1()
                    }
                }
            }
        }

        Text {
            id: description3
            text: qsTr(description)
            anchors{
                top: iconRect3.bottom
//                        topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            font.pixelSize: 14
        }
    }

    Rectangle{
        id:openBtn3
        width: parent.width/4
        height: 32
        radius: 4
        color: "transparent"
        border.color: "lightgray"
        anchors{
            right: parent.horizontalCenter
            top: containerItem3.bottom
            topMargin: 25
        }
        Text {
            id: open3
            text: qsTr("Open")
            anchors.centerIn: parent
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                openBtn3.border.color = "#878585"
            }
            onExited: {
                openBtn3.border.color = "lightgray"
            }
            onPressed: {
                openBtn3.color = "#F5F5F5"
            }
            onReleased: {
                openBtn3.color = "transparent"
            }

            onClicked: {
                if(instruction1){
                    instruction1()
                }
            }
        }
    }

    Rectangle{
        id:moreBtn3
        width: parent.width/5
        height: 32
        radius: 4
        color: "transparent"
        border.color: "lightgray"
        anchors{
            left: openBtn3.right
            leftMargin: 7
            top: openBtn3.top
        }

        Image {
            id: moreIcon
            source: "assets/menu.png"
            width: parent.width* .75
            height: parent.height* .5
            anchors.centerIn: parent
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                moreBtn3.border.color = "#878585"
            }
            onExited: {
                moreBtn3.border.color = "lightgray"
            }
            onPressed: {
                moreBtn3.color = "#F5F5F5"
            }
            onReleased: {
                moreBtn3.color = "transparent"
            }
            onClicked: {
                learnMoreMenu.open()
            }
        }

        Menu{
            id: learnMoreMenu
            width: 100
            y: moreBtn3.height + 5

            MenuItem{
                height: 32
                text: "Learn more"
                onClicked: {
                    if(instruction2){
                        instruction2()
                    }
                }
            }
        }
    }
}
