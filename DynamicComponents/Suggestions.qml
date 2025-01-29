import QtQuick 2.15
import QtQuick.Controls

Item {
    id: suggestionsItem

    Rectangle{
        id:suggestionsRect
        radius: 8
        anchors.fill: parent
        color: "transparent"


        Text {
            id: msgTitle
            text: qsTr("Suggestion box Messages")
            color: "blue"
            anchors{
                top: parent.top
                topMargin: 20
                left: parent.left
                leftMargin: 20
            }
            font.bold: true
            font.pixelSize: 14
        }

        Text {
            id: suggestions
            anchors{
                top: msgTitle.bottom
                topMargin: 20
                left: msgTitle.left
                right: parent.right
                rightMargin: 10
            }
            width: parent.width
            text: qsTr("Please stock more setbooks because that is what is more on demand. The students don't have enough and they're struggling to keep up.")
            wrapMode: Text.WordWrap
        }

        Text {
            id: msgAuthor
            text: qsTr("Miss Nicky")
            anchors{
                top: suggestions.bottom
                topMargin:10
                left: suggestions.left
            }
            font.bold: true
            font.pixelSize: 14
        }
    }
}
