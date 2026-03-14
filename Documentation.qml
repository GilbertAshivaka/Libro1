import QtQuick
import QtQuick.Effects
import QtWebEngine
import QtWebView
import QtWebChannel
import QtQuick.Dialogs

Rectangle{
    id: documentationPage
    anchors.fill: parent

    //this prevents the clicks from leaking to the components underneath this one
    MouseArea{
        id: documentationMA
        anchors.fill: parent
    }

    signal closeClicked()

    // ── Close button ────────────────────────────────────────
    Rectangle {
        id: closeBtn
        width: 80; height: 32; radius: 25; z: 3
        border.color: "#878585"; border.width: 2; clip: true
        anchors { top: parent.top; topMargin: 10; right: parent.right; rightMargin: 30 }

        Text {
            id: closeBtnTxt; anchors.centerIn: parent
            text: "Close"; font.pixelSize: 16; font.bold: true
        }

        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onEntered: { closeBtn.color = "#878585"; closeBtnTxt.color = "white" }
            onExited:  { closeBtn.color = "white";   closeBtnTxt.color = "#878585" }
            onClicked: closeClicked()
        }
    }


    WebEngineView{
        id: documentationView
        anchors.fill: parent

        url: Qt.resolvedUrl("docs/libro-docs.html")
        onLoadingChanged: {
            if(loadProgress === 100){
                console.log("Loaded the Documentation page.")
            }
        }
    }
}
