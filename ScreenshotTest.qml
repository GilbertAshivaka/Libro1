import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "QML Screenshot Test"

    Rectangle {
        id: contentArea
        anchors.fill: parent
        color: "#f0f0f0"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Header
            Text {
                text: "Screenshot Test Page"
                font.pixelSize: 28
                font.bold: true
                color: "#2c3e50"
                Layout.alignment: Qt.AlignHCenter
            }

            // Content to capture
            Rectangle {
                id: captureContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                radius: 10
                border.color: "#3498db"
                border.width: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 20

                    // Animated circle
                    Rectangle {
                        width: 100
                        height: 100
                        radius: 50
                        color: "#e74c3c"
                        Layout.alignment: Qt.AlignHCenter

                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1000 }
                            NumberAnimation { to: 1.0; duration: 1000 }
                        }
                    }

                    // Some chart-like bars
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        Repeater {
                            model: [60, 80, 45, 90, 70]
                            Rectangle {
                                width: 40
                                height: modelData * 2
                                color: Qt.hsla(index * 0.2, 0.7, 0.5, 1)
                                radius: 5
                                anchors.bottom: parent.bottom
                            }
                        }
                    }

                    // Text content
                    Text {
                        text: "This is sample content\nwith multiple lines\nand some data: " + Math.floor(Math.random() * 100)
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        color: "#34495e"
                    }

                    // Gradient rectangle
                    Rectangle {
                        width: 200
                        height: 50
                        Layout.alignment: Qt.AlignHCenter
                        radius: 25
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#3498db" }
                            GradientStop { position: 1.0; color: "#9b59b6" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Gradient Box"
                            color: "white"
                            font.bold: true
                        }
                    }
                }
            }

            // Control buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: "Save Screenshot (Normal)"
                    onClicked: {
                        captureContent.grabToImage(function(result) {
                            result.saveToFile("C:/Users/Admin/Documents/Libro1/screenshot_normal.png")
                            statusText.text = "Saved: screenshot_normal.png"
                        })
                    }
                }

                Button {
                    text: "Save High-Res (2x)"
                    onClicked: {
                        captureContent.grabToImage(function(result) {
                            result.saveToFile("screenshot_highres.png")
                            statusText.text = "Saved: screenshot_highres.png (2x resolution)"
                        }, Qt.size(captureContent.width * 2, captureContent.height * 2))
                    }
                }

                Button {
                    text: "Save Full Window"
                    onClicked: {
                        contentArea.grabToImage(function(result) {
                            result.saveToFile("screenshot_fullwindow.png")
                            statusText.text = "Saved: screenshot_fullwindow.png"
                        })
                    }
                }
            }

            // Status text
            Text {
                id: statusText
                text: "Click a button to save a screenshot"
                font.pixelSize: 14
                color: "#27ae60"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
