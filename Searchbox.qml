import QtQuick

Rectangle{
    id: navSearchBox
    width: 400
    radius: 4

    color: "transparent"
    border.color: "blue"

    signal textChanged()

    property string placeHolderText: "Search for tools and FAQs"

    Image {
        id: searchIcon

        anchors{
            left: parent.left
            leftMargin: 15
            verticalCenter: parent.verticalCenter
        }

        height: parent.height *.45
        fillMode: Image.PreserveAspectFit

        source: "assets/searchIcon.png"
    }

    Text{
        id: searchBoxPlaceHolder
        visible: navigationTextInput.text === ""
        color: "#585757"
        text: placeHolderText
        anchors{
            left: searchIcon.right
            verticalCenter: parent.verticalCenter
            leftMargin: 20
        }
    }

    MouseArea{
        id: toolBarSearchBoxMA
        cursorShape: "IBeamCursor"
        anchors{
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            left: searchIcon.right
            leftMargin: 20
        }

        TextInput{
            id: navigationTextInput
            clip: true
            anchors{
                right: parent.right
                rightMargin: 5
                top: parent.top
                bottom: parent.bottom
                left: parent.left
    //            leftMargin: 20
            }

            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 11
        }
    }
}
