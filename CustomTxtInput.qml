import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle{
    id: textInputRect
    radius: 4
    width: parent.width* .48
    height: 40
    border.color: "#D2D2D2"
    property string placeHolderText: ""
//                color: "#CBCECE"
    color: "white"

    MouseArea{
        id: textInputMA
        anchors.fill: parent
        cursorShape: "IBeamCursor"

        TextInput{
            id: textInput
            clip: true
            anchors{
                right: parent.right
                rightMargin: 5
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                leftMargin: 5
            }

            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

    }

    Text{
        id: textInputPlaceHolder
        visible: textInput.text === ""
        color: "#585757"
        text: placeHolderText
        anchors{
            left: parent.left
//                    bottom: parent.bottom
            leftMargin: 5
            verticalCenter: parent.verticalCenter
        }
        font.pixelSize: 16
    }

}
