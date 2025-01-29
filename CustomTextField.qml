import QtQuick
import QtQuick.Controls

TextField {
    id: customTextField
//    placeholderText: "Enter text..."
    font.pixelSize: 16
    selectByMouse: true

    property string backgroundRectColor: ""

    verticalAlignment: "AlignVCenter"

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 30
        radius: 5
        color: "transparent"
//        border.color: customTextField.activeFocus ? "#FF6B6B" : "transparent"

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: customTextField.activeFocus ? "#4CC0E4" : "black"
        }
    }
}
