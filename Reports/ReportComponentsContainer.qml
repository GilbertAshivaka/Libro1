import QtQuick
import QtQuick.Controls

Item {
    id: reportComponentsContainer
    signal closeClicked()

    property alias componentsLoader: componentsLoader

    anchors.fill: parent

    Rectangle{
        id: closeBtn
        width: 80
        height: 32
        radius: 25
//            color: "#878585"
        border.color: "#878585"
        border.width: 2
        clip: true
        // x: parent.width - width +20
        // y: 10
        z:3 //have the highest z to be visible
        anchors{
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 30
        }

        Text{
            id: closeBtnTxt
            anchors.centerIn: parent
            text: "Close"
//                color: "white"
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea{
            id: closeBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: {
                closeBtn.color = "#878585"
                closeBtnTxt.color = "white"
            }
            onExited: {
                closeBtn.color = "white"
                closeBtnTxt.color ="#878585"
            }

            onClicked:{
                closeClicked()
            }
        }
    }

    Loader{
        id: componentsLoader
        anchors.fill: parent
        source: ""//"CollectionReportsPage.qml"
    }
}
