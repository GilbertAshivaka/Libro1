import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsCard.qml - FIXED VERSION
 */
Rectangle {
    id: card

    property string title: ""
    default property alias content: contentColumn.data  // CRITICAL: Use 'data' not 'children'

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 40

    radius: 8
    color: "#FFFFFF"
    border.color: "#E0E0E0"
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            visible: title !== ""

            Label {
                text: title
                font.pixelSize: 16
                font.bold: true
                color: "#1A1A1A"
            }

            Item { Layout.fillWidth: true }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            visible: title !== ""
        }

        // Content area
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
