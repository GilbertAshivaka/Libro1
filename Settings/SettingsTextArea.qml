import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsTextArea.qml
 * A labeled multi-line text area for template editing.
 */
ColumnLayout {
    id: root

    property string label: ""
    property string value: ""
    property string placeholder: ""
    property string description: ""
    property int minHeight: 120

    signal textEdited(string newValue)

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true

        Label {
            text: label
            font.pixelSize: 13
            font.bold: true
            color: "#1A1A1A"
            visible: label !== ""
        }

        Item { Layout.fillWidth: true }

        // Character count
        Label {
            text: textArea.text.length + " characters"
            font.pixelSize: 11
            color: "#666666"
        }
    }

    ScrollView {
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(minHeight, textArea.contentHeight + 24)
        Layout.maximumHeight: 300

        clip: true

        // background: Rectangle {
        //     radius: 6
        //     color: textArea.activeFocus ? "#FFFFFF" : "#F5F5F5"
        //     border.color: textArea.activeFocus ? "#0078D4" : "#E0E0E0"
        //     border.width: textArea.activeFocus ? 2 : 1
        // }

        TextArea {
            id: textArea
            text: root.value
            placeholderText: placeholder
            font.pixelSize: 13
            font.family: "Consolas, Monaco, monospace"
            wrapMode: TextEdit.Wrap
            selectByMouse: true

            onTextChanged: {
                if (text !== root.value) {
                    root.textEdited(text)
                }
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
