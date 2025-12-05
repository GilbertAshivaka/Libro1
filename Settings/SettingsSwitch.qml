import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsSwitch.qml
 * A labeled toggle switch for boolean settings.
 * Windows 11 inspired design.
 */
RowLayout {
    id: root

    property string label: ""
    property bool checked: false
    property string description: ""

    // FIXED: Renamed to avoid conflict with auto-generated checkedChanged signal
    signal toggled(bool isChecked)

    Layout.fillWidth: true
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Label {
            text: label
            font.pixelSize: 13
            font.bold: true
            color: "#1A1A1A"
            visible: label !== ""
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

    Switch {
        id: toggleSwitch
        checked: root.checked

        indicator: Rectangle {
            implicitWidth: 46
            implicitHeight: 24
            x: toggleSwitch.leftPadding
            y: parent.height / 2 - height / 2
            radius: 12
            color: toggleSwitch.checked ? "#0078D4" : "#767676"

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Rectangle {
                x: toggleSwitch.checked ? parent.width - width - 3 : 3
                y: 3
                width: 18
                height: 18
                radius: 9
                color: "#FFFFFF"

                Behavior on x {
                    NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }
            }
        }

        onCheckedChanged: {
            if (checked !== root.checked) {
                root.toggled(checked)  // FIXED: Use renamed signal
            }
        }
    }
}
