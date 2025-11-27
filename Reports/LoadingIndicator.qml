import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Loading indicator with message
Rectangle {
    id: root
    
    // Properties
    property string message: "Loading..."
    property bool running: true
    property color overlayColor: "#E0FFFFFF"
    
    // Styling
    anchors.fill: parent
    color: overlayColor
    visible: running
    z: 999
    
    // Block mouse events when visible
    MouseArea {
        anchors.fill: parent
        enabled: root.running
        hoverEnabled: true
    }
    
    // Center content
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        BusyIndicator {
            running: root.running
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
        }
        
        Label {
            text: root.message
            font.pixelSize: 14
            color: "#616161"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
