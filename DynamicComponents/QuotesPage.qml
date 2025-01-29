import QtQuick 2.15
import QtQuick.Controls

Item {
    id: quotesItem

    Rectangle{
        id:quotesRect
        radius: 8
        anchors.fill: parent
        color: "transparent"

        Text {
            id: quoteTitle
            text: qsTr("Quote of the day")
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
            id: quote
            anchors{
                top: quoteTitle.bottom
                topMargin: 20
                left: quoteTitle.left
                right: parent.right
                rightMargin: 10
            }
            width: parent.width
            text: qsTr("Every generation has it's purpose, ours is to reveal and spread the truth and reverse the brainwashing.")
            wrapMode: Text.WordWrap
            font.italic: true
        }

        Text {
            id: quoteAuthor
            text: qsTr("Kentah Gwanjes")
            anchors{
                top: quote.bottom
                topMargin:10
                left: quote.left
            }
            font.bold: true
            font.pixelSize: 14
            font.italic: true
        }
    }
}
