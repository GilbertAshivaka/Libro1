import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * GracePeriodWarningDialog.qml
 * Shown once the offline grace window is exhausted (status "reverify_required").
 * The license is still within its expiry date, but the app has been offline too
 * long since the last successful check, so the user must verify online before
 * continuing. (This is NOT the "expired, please renew" case - that goes to the
 * blocked page instead.)
 */
Dialog {
    id: gracePeriodDialog

    modal: true
    closePolicy: Popup.NoAutoClose

    // Center on the window overlay (robust for popups).
    parent: Overlay.overlay
    anchors.centerIn: parent

    width: Math.min(440, (parent ? parent.width : 440) - 40)
    padding: 0

    readonly property color warningColor: "#F57C00"
    readonly property color accentColor: "#0078D4"

    // Reflects an in-flight online validation.
    readonly property bool verifying: appManager ? appManager.isValidating : false
    // Last failure message to surface (offline / server error).
    property string statusMessage: ""

    // Surface verification results. On success the license status changes and
    // Main.qml routes away (closing this dialog); we only show failures here.
    Connections {
        target: appManager
        function onValidationCompleted(success, message) {
            if (!success) {
                gracePeriodDialog.statusMessage = (message && message.length)
                    ? message
                    : "Couldn't reach the licensing server. Check your internet connection and try again."
            }
        }
        function onNetworkError(error) {
            gracePeriodDialog.statusMessage = "No internet connection. Please connect and try again."
        }
    }

    background: Rectangle {
        color: "white"
        radius: 12
        border.color: "#E0E0E0"
        border.width: 1
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: 0

        // ---- Header band (top corners rounded) ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#FFF3E0"
            radius: 12

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 14
                color: "#FFF3E0"
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                Text { text: "🔄"; font.pixelSize: 22 }

                Text {
                    text: "Verify Your License"
                    font.pixelSize: 18
                    font.bold: true
                    color: gracePeriodDialog.warningColor
                }
            }
        }

        // ---- Body ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: "Libro has been offline for a while and needs to re-verify your license to continue.\n\n" +
                      "Please make sure you're connected to the internet, then verify."
                font.pixelSize: 14
                color: "#333333"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // Status / error message
            Text {
                Layout.fillWidth: true
                visible: gracePeriodDialog.statusMessage.length > 0 && !gracePeriodDialog.verifying
                text: gracePeriodDialog.statusMessage
                font.pixelSize: 12
                color: "#C62828"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 12

                Button {
                    id: quitButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    enabled: !gracePeriodDialog.verifying

                    contentItem: Text {
                        text: "Quit"
                        color: gracePeriodDialog.accentColor
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: quitButton.pressed ? "#E8E8E8" :
                               quitButton.hovered ? "#F0F0F0" : "white"
                        radius: 6
                        border.color: gracePeriodDialog.accentColor
                        border.width: 1
                    }

                    onClicked: Qt.quit()
                }

                Button {
                    id: verifyButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    enabled: !gracePeriodDialog.verifying

                    contentItem: Text {
                        text: gracePeriodDialog.verifying ? "Verifying…" : "Verify Now"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: !verifyButton.enabled ? "#9E9E9E" :
                               verifyButton.pressed ? Qt.darker(gracePeriodDialog.accentColor, 1.1) :
                               verifyButton.hovered ? Qt.lighter(gracePeriodDialog.accentColor, 1.1) :
                               gracePeriodDialog.accentColor
                        radius: 6
                    }

                    onClicked: {
                        gracePeriodDialog.statusMessage = ""
                        if (appManager)
                            appManager.manualValidation()
                    }
                }
            }
        }
    }
}
