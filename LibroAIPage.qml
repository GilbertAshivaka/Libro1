import QtQuick
import QtQuick.Effects
import QtWebEngine
import QtWebView
import QtWebChannel
import QtQuick.Dialogs

Rectangle{
    id: libroAIPage
    anchors.fill: parent

    signal closeClicked()

    Rectangle {
        id: titleRect
        width: parent.width
        height: 50
        color: "white"
        anchors {
            top: parent.top
            left: parent.left
        }
        clip: true

        Text {
            id: toolsPageTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "Libro AI"

            font.pointSize: 12
            color: "#878585"
        }

        Rectangle{
            id: closeBtn
            width: 80
            height: 32
            radius: 25
//            color: "#878585"
            border.color: "#878585"
            border.width: 2
            clip: true
            anchors{
                verticalCenter: parent.verticalCenter
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
    }


    WebEngineView{
        id: aiView
        anchors{
            top: titleRect.bottom
            right: parent.right
            left: parent.left
            bottom: parent.bottom
        }

        url: Qt.resolvedUrl("http://localhost:5173/embed/ai")  //http://localhost:5173/embed/ai //webPages/LibroAI.html
        onLoadingChanged: {
            if(loadProgress === 100){
                console.log("Loaded the AI page.")
            }
        }
    }
}
