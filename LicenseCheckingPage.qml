import QtQuick
import QtQuick.Controls

/**
 * LicenseCheckingPage.qml
 * Loading screen shown while verifying license status on startup.
 */
Rectangle {
    id: root
    color: "#FFFFFF"

    Column {
        anchors.centerIn: parent
        spacing: 20

        // App logo or icon placeholder
        Rectangle {
            width: 80
            height: 80
            radius: 16
            color: "#0078D4"
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.centerIn: parent
                text: "L"
                font.pixelSize: 48
                font.bold: true
                color: "white"
            }
        }

        Text {
            text: "Libro"
            font.pixelSize: 28
            font.bold: true
            color: "#1A1A1A"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Library Management System"
            font.pixelSize: 14
            color: "#666666"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { height: 20; width: 1 }  // Spacer

        BusyIndicator {
            running: true
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48
        }

        Text {
            text: "Verifying license..."
            font.pixelSize: 13
            color: "#999999"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Version info at bottom
    Text {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 20
        }
        text: "Version 1.0.0"
        font.pixelSize: 11
        color: "#CCCCCC"
    }
}
