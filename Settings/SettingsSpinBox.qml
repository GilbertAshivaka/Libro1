import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsSpinBox.qml
 * A labeled spin box for integer settings.
 */
ColumnLayout {
    id: root

    property string label: ""
    property int value: 0
    property int from: 0
    property int to: 100
    property string suffix: ""
    property string description: ""

    // FIXED: Renamed to avoid conflict with auto-generated valueChanged signal
    signal numberChanged(int newValue)

    Layout.fillWidth: true
    spacing: 4

    Label {
        text: label
        font.pixelSize: 13
        font.bold: true
        color: "#1A1A1A"
        visible: label !== ""
    }

    SpinBox {
        id: spinBox
        Layout.fillWidth: true
        value: root.value
        from: root.from
        to: root.to
        editable: true
        font.pixelSize: 14

        textFromValue: function(value, locale) {
            return value + suffix
        }

        valueFromText: function(text, locale) {
            return parseInt(text.replace(suffix, ""))
        }

        // background: Rectangle {
        //     implicitHeight: 40
        //     implicitWidth: 120
        //     radius: 6
        //     color: spinBox.activeFocus ? "#FFFFFF" : "#F5F5F5"
        //     border.color: spinBox.activeFocus ? "#0078D4" : "#E0E0E0"
        //     border.width: spinBox.activeFocus ? 2 : 1
        // }

        contentItem: TextInput {
            z: 2
            text: spinBox.textFromValue(spinBox.value, spinBox.locale)
            font: spinBox.font
            color: "#1A1A1A"
            selectionColor: "#0078D4"
            selectedTextColor: "#FFFFFF"
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !spinBox.editable
            validator: spinBox.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly
        }

        up.indicator: Rectangle {
            x: spinBox.mirrored ? 0 : parent.width - width
            height: parent.height
            implicitWidth: 36
            implicitHeight: 40
            radius: 6
            color: spinBox.up.pressed ? "#E0E0E0" : (spinBox.up.hovered ? "#F0F0F0" : "transparent")

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 16
                font.bold: true
                color: spinBox.up.pressed ? "#0078D4" : "#666666"
            }
        }

        down.indicator: Rectangle {
            x: spinBox.mirrored ? parent.width - width : 0
            height: parent.height
            implicitWidth: 36
            implicitHeight: 40
            radius: 6
            color: spinBox.down.pressed ? "#E0E0E0" : (spinBox.down.hovered ? "#F0F0F0" : "transparent")

            Text {
                anchors.centerIn: parent
                text: "−"
                font.pixelSize: 16
                font.bold: true
                color: spinBox.down.pressed ? "#0078D4" : "#666666"
            }
        }

        onValueChanged: {
            if (value !== root.value) {
                root.numberChanged(value)  // FIXED: Use renamed signal
            }
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
