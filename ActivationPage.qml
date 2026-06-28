import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * ActivationPage.qml
 * First screen shown when the app is not activated.
 * User enters Organization ID and License Key to activate.
 */
Rectangle {
    id: activationPage
    anchors.fill: parent
    color: "#F5F5F5"

    // Signals
    signal activationComplete()

    // Colors
    readonly property color accentColor: "#0078D4"
    readonly property color errorColor: "#D32F2F"
    readonly property color successColor: "#388E3C"

    // State
    property bool isLoading: appManager ? appManager.isValidating : false
    property string errorMessage: ""
    property string successMessage: ""

    // Handle activation result
    Connections {
        target: appManager
        function onActivationSucceeded() {
            successMessage = "License activated successfully!"
            errorMessage = ""
            // Small delay to show success message
            successTimer.start()
        }
        function onActivationFailed(error) {
            errorMessage = error
            successMessage = ""
        }
    }

    Timer {
        id: successTimer
        interval: 1500
        onTriggered: activationComplete()
    }

    // Main content
    ScrollView {
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            x: (parent.width - width) / 2
            y: Math.max(30, (activationPage.height - height) / 2)
            width: Math.min(500, activationPage.width - 80)
            spacing: 24

            // Logo and title
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Image {
                    source: "assets/libroIcon.ico"
                    width: 80
                    height: 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: "Libro"
                    font.pixelSize: 32
                    font.bold: true
                    color: "#1A1A1A"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Integrated Library Management System"
                    font.pixelSize: 14
                    color: "#666666"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Activation card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: cardContent.height + 48
                color: "white"
                radius: 12
                border.color: "#E0E0E0"
                border.width: 1

                ColumnLayout {
                    id: cardContent
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 24
                    }
                    spacing: 20

                    Text {
                        text: "Activate Your License"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#1A1A1A"
                    }

                    Text {
                        text: "Enter your Organization ID and License Key from the Libro portal to activate this installation."
                        font.pixelSize: 13
                        color: "#666666"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Organization ID field
                    Column {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Organization ID"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#333333"
                        }

                        TextField {
                            id: orgIdField
                            width: parent.width
                            height: 44
                            placeholderText: "e.g., LIB-2026-00001"
                            font.pixelSize: 14
                            enabled: !isLoading

                            // background: Rectangle {
                            //     color: orgIdField.enabled ? "white" : "#F5F5F5"
                            //     border.color: orgIdField.activeFocus ? accentColor : "#CCCCCC"
                            //     border.width: orgIdField.activeFocus ? 2 : 1
                            //     radius: 6
                            // }
                        }
                    }

                    // License Key field
                    Column {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "License Key"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#333333"
                        }

                        TextField {
                            id: licenseKeyField
                            width: parent.width
                            height: 44
                            placeholderText: "e.g., LIBRO-XXXX-XXXX-XXXX-XXXX"
                            font.pixelSize: 14
                            font.family: "Consolas"
                            enabled: !isLoading

                            // background: Rectangle {
                            //     color: licenseKeyField.enabled ? "white" : "#F5F5F5"
                            //     border.color: licenseKeyField.activeFocus ? accentColor : "#CCCCCC"
                            //     border.width: licenseKeyField.activeFocus ? 2 : 1
                            //     radius: 6
                            // }
                        }
                    }

                    // Error message
                    Rectangle {
                        Layout.fillWidth: true
                        height: errorText.height + 16
                        color: "#FFEBEE"
                        radius: 6
                        visible: errorMessage !== ""
                        border.color: errorColor
                        border.width: 1

                        Text {
                            id: errorText
                            text: errorMessage
                            color: errorColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                        }
                    }

                    // Success message
                    Rectangle {
                        Layout.fillWidth: true
                        height: successText.height + 16
                        color: "#E8F5E9"
                        radius: 6
                        visible: successMessage !== ""
                        border.color: successColor
                        border.width: 1

                        Text {
                            id: successText
                            text: successMessage
                            color: successColor
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                        }
                    }

                    // Activate button
                    Button {
                        id: activateButton
                        Layout.fillWidth: true
                        height: 48
                        enabled: !isLoading && orgIdField.text.trim() !== "" && licenseKeyField.text.trim() !== ""

                        contentItem: Row {
                            spacing: 8
                            anchors.centerIn: parent

                            BusyIndicator {
                                running: isLoading
                                visible: isLoading
                                width: 20
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: isLoading ? "Activating..." : "Activate License"
                                color: "white"
                                font.pixelSize: 15
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        background: Rectangle {
                            color: activateButton.enabled ?
                                   (activateButton.pressed ? Qt.darker(accentColor, 1.1) :
                                    activateButton.hovered ? Qt.lighter(accentColor, 1.1) : accentColor) :
                                   "#CCCCCC"
                            radius: 6
                        }

                        onClicked: {
                            errorMessage = ""
                            successMessage = ""
                            if (appManager) {
                                appManager.activateLicense(orgIdField.text.trim(), licenseKeyField.text.trim())
                            }
                        }
                    }
                }
            }

            // Help text
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Text {
                    text: "Don't have a license key?"
                    font.pixelSize: 13
                    color: "#666666"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Visit libro.yoursite.com to register for a free trial or purchase a license."
                    font.pixelSize: 12
                    color: accentColor
                    anchors.horizontalCenter: parent.horizontalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://libro.yoursite.com")
                    }
                }
            }

            // Version info
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Version 1.0.0"
                font.pixelSize: 11
                color: "#999999"
            }
        }
    }
}
