import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    width: 1080
    height: 500
    visible: true
    title: qsTr("Libro")

    Loader{
        id: mainLoader
        anchors.fill: parent
        source: "Login.qml"
        active: true
    }
}
