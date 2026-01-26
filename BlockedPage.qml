import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * BlockedPage.qml
 * Shown when license has expired and grace period has ended.
 * User must renew license to continue using the application.
 */
Rectangle {
    id: blockedPage
    anchors.fill: parent
    color: "#F5F5F5"

    // Signals
    signal retryValidation()

    // Colors
    readonly property color errorColor: "#D32F2F"
    readonly property color accentColor: "#0078D4"

    // State
    property bool isValidating: appManager ? appManager.isValidating : false

    Item {
        anchors.centerIn: parent
        width: Math.min(500, parent.width - 80)
        height: contentColumn.height

        ColumnLayout {
            id: contentColumn
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: 24

            // Error icon
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 100
                height: 100
                radius: 50
                color: "#FFEBEE"
                border.color: errorColor
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "⚠"
                    font.pixelSize: 48
                    color: errorColor
                }
            }

            // Title
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "License Expired"
                font.pixelSize: 28
                font.bold: true
                color: errorColor
            }

            // Message
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: "Your Libro license has expired and the grace period has ended.\nPlease renew your subscription to continue using the application."
                font.pixelSize: 14
                color: "#666666"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }

            // License details card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: detailsColumn.height + 32
                color: "white"
                radius: 12
                border.color: "#E0E0E0"
                border.width: 1

                Column {
                    id: detailsColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 16
                    }
                    spacing: 12

                    // Organization
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "Organization:"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#333333"
                            width: 120
                        }

                        Text {
                            text: appManager ? appManager.organizationName : "N/A"
                            font.pixelSize: 13
                            color: "#666666"
                        }
                    }

                    // License Tier
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "License Type:"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#333333"
                            width: 120
                        }

                        Text {
                            text: appManager ? (appManager.licenseTier.charAt(0).toUpperCase() + appManager.licenseTier.slice(1)) : "N/A"
                            font.pixelSize: 13
                            color: "#666666"
                        }
                    }

                    // Expiry date
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "Expired On:"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#333333"
                            width: 120
                        }

                        Text {
                            text: appManager ? Qt.formatDate(appManager.expiryDate, "MMMM d, yyyy") : "N/A"
                            font.pixelSize: 13
                            color: errorColor
                        }
                    }

                    // Organization ID
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "Organization ID:"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#333333"
                            width: 120
                        }

                        Text {
                            text: appManager ? appManager.organizationId : "N/A"
                            font.pixelSize: 13
                            font.family: "Consolas"
                            color: "#666666"
                        }
                    }
                }
            }

            // Actions
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Renew button
                Button {
                    id: renewButton
                    Layout.fillWidth: true
                    height: 48

                    contentItem: Text {
                        text: "Renew License"
                        color: "white"
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: renewButton.pressed ? Qt.darker(accentColor, 1.1) :
                               renewButton.hovered ? Qt.lighter(accentColor, 1.1) : accentColor
                        radius: 6
                    }

                    onClicked: {
                        Qt.openUrlExternally("https://libro.yoursite.com/renew")
                    }
                }

                // Retry validation button
                Button {
                    id: retryButton
                    Layout.fillWidth: true
                    height: 44
                    enabled: !isValidating

                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent

                        BusyIndicator {
                            running: isValidating
                            visible: isValidating
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: isValidating ? "Checking..." : "I've renewed, check again"
                            color: accentColor
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    background: Rectangle {
                        color: retryButton.pressed ? "#E8E8E8" :
                               retryButton.hovered ? "#F0F0F0" : "transparent"
                        radius: 6
                        border.color: accentColor
                        border.width: 1
                    }

                    onClicked: {
                        if (appManager) {
                            appManager.manualValidation()
                        }
                        retryValidation()
                    }
                }
            }

            // Help section
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Text {
                    text: "Need help?"
                    font.pixelSize: 13
                    color: "#666666"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Contact support at support@libro.yoursite.com"
                    font.pixelSize: 12
                    color: accentColor
                    anchors.horizontalCenter: parent.horizontalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("mailto:support@libro.yoursite.com")
                    }
                }
            }
        }
    }
}
