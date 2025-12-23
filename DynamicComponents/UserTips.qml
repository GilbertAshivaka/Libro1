import QtQuick 2.15
import QtQuick.Controls

Item {
    id: userTips

    Rectangle{
        id:tipsRect
        radius: 8
        anchors.fill: parent
        color: "transparent"


        Row {
            id: tipTitleRow
            spacing: 8

            anchors{
                top: parent.top
                topMargin: 20
                left: parent.left
                leftMargin: 20
            }

            Text {
                text: "💡"
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: tipTitle
                text: qsTr("Tips")
                font.bold: true
                font.pixelSize: 15
                color: "#3B82F6"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Text {
        //     id: tipTitle
        //     text: qsTr("Tips")
        //     anchors{
        //         top: parent.top
        //         topMargin: 20
        //         left: parent.left
        //         leftMargin: 20
        //     }
        //     font.bold: true
        //     font.pixelSize: 14
        //     color: "blue"
        // }

        Text {
            id: tip1
//            anchors.centerIn: parent
            anchors{
                top: tipTitleRow.bottom
                topMargin: 20
                left: tipTitleRow.left
                right: parent.right
                rightMargin: 10
            }
            width: parent.width
            text: qsTr("Use the searchbar at the top of this page to quickly find tools.")
            wrapMode: Text.WordWrap
        }

        Rectangle{
            id: separator
            width: parent.width*.78
            height: 2
            anchors{
                horizontalCenter: parent.horizontalCenter
                top: tip1.bottom
                topMargin: 16
            }
            color: "gray"
        }

        Text {
            id: dot1
            anchors{
                right: separator.left
                rightMargin: 5
                verticalCenter: separator.verticalCenter
            }
            text: qsTr("•")
            color: "gray"
        }

        Text {
            id: dot2
            anchors{
                left: separator.right
                leftMargin: 5
                verticalCenter: separator.verticalCenter
            }
            text: qsTr("•")
            color: "gray"
        }

        Text {
            id: tip2
//            anchors.centerIn: parent
            anchors{
                top: separator.bottom
                topMargin: 16
                left: tipTitleRow.left
                right: parent.right
                rightMargin: 10
            }
            width: parent.width
            text: qsTr("Click \"Show more\" on the Stats page in this box to see more statistics on library usage.")
            wrapMode: Text.WordWrap
        }
    }
}
