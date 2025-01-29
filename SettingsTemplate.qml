import QtQuick

Rectangle {
    id: settingsTemplate
    width: 200
    height: 100
    color: "transparent"
    radius: 5
    border.color: "transparent"
    border.width: 2
    //                        clip: true
    property string icon: "null"
    property string headerTxt: "null"
    property string description: "null"
    property var instruction: null


    Rectangle {
        id: templateImgRect
        width: 40 //parent.width/5
        height: 40
        anchors {
            left: parent.left
            leftMargin: 5
            verticalCenter: parent.verticalCenter
        }
        color: "transparent"

        Image {
            id: settingIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: icon
        }
    }

    Text {
        width: settingsTemplate.width - templateImgRect.width - 8
        anchors{
            left: templateImgRect.right
            leftMargin: 4
            bottom: parent.verticalCenter
        }

        text: headerTxt
        wrapMode: Text.WordWrap
        font.pixelSize: 14

    }

    Text {
        width: settingsTemplate.width - templateImgRect.width - 8
        anchors{
            left: templateImgRect.right
            leftMargin: 4
            top: parent.verticalCenter
        }
        font.weight: 60
        text: description
        wrapMode: Text.WordWrap
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            settingsTemplate.border.color = "lightgray"
        }

        onExited: {
            settingsTemplate.border.color = "transparent"
        }

        onClicked: {
            if(instruction){
                instruction()
            }
        }
    }
}
