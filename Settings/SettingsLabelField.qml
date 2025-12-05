import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsLabelField.qml
 * A read-only labeled field for displaying non-editable values.
 */
ColumnLayout {
    id: root

    property string label: ""
    property string value: ""
    property string description: ""

    Layout.fillWidth: true
    spacing: 4

    Label {
        text: label
        font.pixelSize: 13
        font.bold: true
        color: "#1A1A1A"
        visible: label !== ""
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 6
        color: "#F0F0F0"
        border.color: "#E0E0E0"
        border.width: 1

        Label {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: Text.AlignVCenter
            text: root.value
            font.pixelSize: 14
            color: "#666666"
            elide: Text.ElideRight
        }

        // Lock icon to indicate read-only
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "🔒"
            font.pixelSize: 12
            opacity: 0.5
        }
    }

    Label {
        text: description
        font.pixelSize: 11
        color: "#666666"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        visible: description !== ""
    }
}
