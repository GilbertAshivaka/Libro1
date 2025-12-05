import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsTextField.qml
 * A labeled text field for settings input.
 */
ColumnLayout {
    id: root

    property string label: ""
    property string value: ""
    property string placeholder: ""
    property string description: ""
    property bool isPassword: false

    signal textEdited(string newValue)

    Layout.fillWidth: true
    spacing: 4

    Label {
        text: label
        font.pixelSize: 13
        font.bold: true
        color: "#1A1A1A"
        visible: label !== ""
    }

    TextField {
        id: textField
        Layout.fillWidth: true
        text: root.value
        placeholderText: placeholder
        echoMode: isPassword ? TextInput.Password : TextInput.Normal
        font.pixelSize: 14

        background: Rectangle {
            implicitHeight: 40
            radius: 6
            color: textField.activeFocus ? "#FFFFFF" : "#F5F5F5"
            border.color: textField.activeFocus ? "#0078D4" : "#E0E0E0"
            border.width: textField.activeFocus ? 2 : 1
        }

        onTextChanged: {
            if (text !== root.value) {
                root.textEdited(text)
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
