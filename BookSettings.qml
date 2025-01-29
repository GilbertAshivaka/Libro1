import QtQuick

Item {
    id: backRectContainer
    Rectangle{
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors{
            left: parent.left
            leftMargin: 5
            top: parent.top
            topMargin: 5
        }

        Rectangle{
            id: backBtnRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"

            Image{
                id: back
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/backArrow.png"
            }
        }

        MouseArea{
            id: backMA
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                backRect.color = "#E8E3E4"
            }
            onExited: {
                backRect.color = "#DDDDDD"
            }

            onClicked: {
                mainLoader.source = "Settings.qml"
            }
        }
    }

    Rectangle{
        id: leftRect
        width: parent.width* .235
        anchors{
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        color: "transparent"
    }

    Rectangle{
        id: rightRect
        anchors{
            left: leftRect.right
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        color: "white"
    }
}
