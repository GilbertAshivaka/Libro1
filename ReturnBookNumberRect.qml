import QtQuick

Item {
    id: returnBookNumberRect
    signal closeClicked()


    Rectangle{
        id: returnBookNumberRect1
        width: 400
        height: 200
        radius: 4
        anchors.centerIn: parent


        Text {
            id: returnBookMsg
            anchors{
                left: parent.left
                leftMargin: 20
                top: parent.top
                topMargin: 20
            }
            text: qsTr("Please enter the book number")
            font.pointSize: 10
        }

        CustomTextField{
            id: bookNumberTxtField
            width: parent.width* .8
            anchors.centerIn: parent
            placeholderText: "Book number"
        }

        CustomButton{
            id: showDetailsBtn
            text: "Continue"
            anchors{
                right: parent.right
                rightMargin: 20
                bottom: parent.bottom
                bottomMargin: 20
            }
            hoveredColor: "#399ED9"
            defaultColor: "#E0E0E0"

            onClicked: {
                returnBookNumberRect.closeClicked()
                returnDetailsContainer.visible = !returnDetailsContainer.visible
            }
        }
    }

    CustomDropShadow{
        source: returnBookNumberRect1
        visible: true
        samples: 24
    }

    CustomDropShadow{
        source: returnBookNumberRect1
        visible: true
        horizontalOffset: -3
        verticalOffset: -3
        samples: 24
    }
}
