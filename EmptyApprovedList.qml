import QtQuick
import QtQuick.Controls

Rectangle {
    id: emptyApprovedList
    width: parent.width

//    color: "lightgray"

    Rectangle{
        id: nothingIcon
        width: parent.width * 1/5
        height: width
        anchors.centerIn: parent

        Image {
            id: planet
            anchors.fill: parent
            source: "assets/planet.png"
            fillMode: Image.PreserveAspectFit
        }
    }

    Text {
        id: nothingText
        text: qsTr("Looks like there's nothing here!")
        font.pixelSize: 24
        color: "lightgray"
        anchors{
            horizontalCenter: parent.horizontalCenter
            bottom: nothingIcon.top
            bottomMargin: 20
        }
    }
}
