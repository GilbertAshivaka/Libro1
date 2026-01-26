import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * GracePeriodWarningDialog.qml
 * Modal dialog shown on startup when license is in grace period.
 * Warns user about expiration and allows them to continue.
 */
Dialog {
    id: gracePeriodDialog

    title: "License Expired"
    modal: true
    closePolicy: Popup.NoAutoClose

    width: Math.min(450, parent.width - 40)
    height: contentColumn.height + 120

    anchors.centerIn: parent

    // Colors
    readonly property color warningColor: "#F57C00"
    readonly property color accentColor: "#0078D4"

    // Days remaining in grace period
    property int daysRemaining: appManager ? appManager.graceDaysRemaining : 0

    // Expiry date property for external binding
    property string expiryDateText: appManager ? Qt.formatDate(appManager.expiryDate, "MMMM d, yyyy") : "Unknown"

    // Signals for external handling
    signal continueClicked()
    signal renewClicked()

    background: Rectangle {
        color: "white"
        radius: 12
        border.color: "#E0E0E0"
        border.width: 1
    }

    header: Item {
        height: 60

        Rectangle {
            anchors.fill: parent
            color: "#FFF3E0"
            radius: 12

            // Only round top corners
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 12
                color: "#FFF3E0"
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: "⚠️"
                font.pixelSize: 24
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "License Grace Period"
                font.pixelSize: 18
                font.bold: true
                color: warningColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    contentItem: ColumnLayout {
        id: contentColumn
        spacing: 20

        // Warning message
        Text {
            Layout.fillWidth: true
            text: "Your Libro license expired on " +
                  (appManager ? Qt.formatDate(appManager.expiryDate, "MMMM d, yyyy") : "Unknown") + "."
            font.pixelSize: 14
            color: "#333333"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        // Days remaining highlight
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: daysBox.width + 40
            height: daysBox.height + 20
            color: "#FFF3E0"
            radius: 8
            border.color: warningColor
            border.width: 1

            Column {
                id: daysBox
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: daysRemaining.toString()
                    font.pixelSize: 36
                    font.bold: true
                    color: warningColor
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: daysRemaining === 1 ? "day remaining" : "days remaining"
                    font.pixelSize: 13
                    color: "#666666"
                }
            }
        }

        // Explanation
        Text {
            Layout.fillWidth: true
            text: "You can continue using Libro with full functionality during the grace period.\n\nAfter " +
                  daysRemaining + (daysRemaining === 1 ? " day" : " days") +
                  ", you will need to renew your license to continue."
            font.pixelSize: 13
            color: "#666666"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.4
        }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                id: renewButton
                Layout.fillWidth: true
                height: 44

                contentItem: Text {
                    text: "Renew Now"
                    color: accentColor
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: renewButton.pressed ? "#E8E8E8" :
                           renewButton.hovered ? "#F0F0F0" : "white"
                    radius: 6
                    border.color: accentColor
                    border.width: 1
                }

                onClicked: {
                    gracePeriodDialog.renewClicked()
                }
            }

            Button {
                id: continueButton
                Layout.fillWidth: true
                height: 44

                contentItem: Text {
                    text: "Continue to App"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: continueButton.pressed ? Qt.darker(accentColor, 1.1) :
                           continueButton.hovered ? Qt.lighter(accentColor, 1.1) : accentColor
                    radius: 6
                }

                onClicked: {
                    gracePeriodDialog.continueClicked()
                    gracePeriodDialog.accept()
                }
            }
        }
    }
}
