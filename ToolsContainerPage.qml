import QtQuick
import QtQuick.Controls

Rectangle{
    id: moreTools
    anchors.fill: parent
    color: "#FBFBFB"
    signal closeClicked()

    Rectangle {
        id: toolsTitleRect
        width: parent.width
        height: 50
        color: "white"
        anchors {
            top: parent.top
            left: parent.left
        }
        clip: true

        Text {
            id: toolsPageTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "More Tools"

            font.pointSize: 12
            color: "#878585"
        }

        Rectangle{
            id: closeBtn
            width: 80
            height: 32
            radius: 25
//            color: "#878585"
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
//                color: "white"
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

    ScrollView{
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        id: moreToolsPageSV
        anchors{
            top: toolsTitleRect.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: toolsPage.flowItemHeight + 120

        ToolsPage{
            id: toolsPage
            width: moreToolsPageSV.width
            height: flowItemHeight + 170
        }
    }
}
