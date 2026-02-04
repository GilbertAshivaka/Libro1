import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * AddAdminDialog.qml
 * Dialog to promote an existing staff member to admin.
 */
Dialog {
    id: addAdminDialog

    title: "Add Administrator"
    modal: true

    width: Math.min(450, parent.width - 40)
    height: 420 //dialogContent.height + 140

    anchors.centerIn: parent

    // Colors
    readonly property color accentColor: "#0078D4"
    readonly property color errorColor: "#D32F2F"

    // State
    property string errorMessage: ""
    property var selectedStaff: null

    // Staff list model
    ListModel {
        id: staffListModel
    }

    function loadStaffList() {
        staffListModel.clear()
        selectedStaff = null
        staffComboBox.currentIndex = -1

        if (appManager) {
            var staffList = appManager.getStaffNotAdmins()
            for (var i = 0; i < staffList.length; i++) {
                staffListModel.append(staffList[i])
            }
        }
    }

    onOpened: {
        loadStaffList()
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        errorMessage = ""
    }

    // background: Rectangle {
    //     color: "white"
    //     radius: 12
    //     border.color: "#E0E0E0"
    //     border.width: 1
    // }

    header: Rectangle {
        height: 50
        color: "white"
        radius: 12

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 12
            color: "white"
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            text: "Add Administrator"
            font.pixelSize: 18
            font.bold: true
            color: "#1A1A1A"
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#E0E0E0"
        }
    }

    contentItem: ColumnLayout {
        id: dialogContent
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: "Select a staff member to promote to administrator. They will be able to access admin functions and add other admins."
            font.pixelSize: 13
            color: "#666666"
            wrapMode: Text.WordWrap
        }

        // Staff selection
        Column {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Select Staff Member *"
                font.pixelSize: 13
                color: "#333333"
            }

            ComboBox {
                id: staffComboBox
                width: parent.width
                height: 40

                model: staffListModel
                textRole: "fullName"

                delegate: ItemDelegate {
                    width: staffComboBox.width
                    height: 50

                    contentItem: Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: model.fullName
                            font.pixelSize: 13
                            font.bold: true
                            color: "#1A1A1A"
                        }

                        Text {
                            text: model.department + " • " + model.staffNo
                            font.pixelSize: 11
                            color: "#666666"
                        }
                    }

                    highlighted: staffComboBox.highlightedIndex === index
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < staffListModel.count) {
                        selectedStaff = staffListModel.get(currentIndex)
                    } else {
                        selectedStaff = null
                    }
                }

                background: Rectangle {
                    color: "white"
                    border.color: staffComboBox.activeFocus ? accentColor : "#CCCCCC"
                    border.width: staffComboBox.activeFocus ? 2 : 1
                    radius: 6
                }
            }

            Text {
                visible: staffListModel.count === 0
                text: "No eligible staff members found. All staff are already admins."
                font.pixelSize: 12
                color: "#999999"
                font.italic: true
            }
        }

        // Username
        Column {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Admin Username *"
                font.pixelSize: 13
                color: "#333333"
            }

            TextField {
                id: usernameField
                width: parent.width
                height: 40
                placeholderText: "Choose a username"

                // background: Rectangle {
                //     color: "white"
                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                //     border.width: parent.activeFocus ? 2 : 1
                //     radius: 6
                // }

                onTextChanged: {
                    // Check username availability
                    if (text.trim() !== "" && appManager) {
                        usernameAvailability.visible = true
                        if (appManager.isUsernameAvailable(text.trim())) {
                            usernameAvailability.text = "✓ Username available"
                            usernameAvailability.color = "#388E3C"
                        } else {
                            usernameAvailability.text = "✗ Username taken"
                            usernameAvailability.color = errorColor
                        }
                    } else {
                        usernameAvailability.visible = false
                    }
                }
            }

            Text {
                id: usernameAvailability
                font.pixelSize: 11
                visible: false
            }
        }

        // Password
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Password *"
                    font.pixelSize: 13
                    color: "#333333"
                }

                TextField {
                    id: passwordField
                    width: parent.width
                    height: 40
                    placeholderText: "Min. 6 characters"
                    echoMode: TextInput.Password

                    // background: Rectangle {
                    //     color: "white"
                    //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                    //     border.width: parent.activeFocus ? 2 : 1
                    //     radius: 6
                    // }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Confirm *"
                    font.pixelSize: 13
                    color: "#333333"
                }

                TextField {
                    id: confirmPasswordField
                    width: parent.width
                    height: 40
                    placeholderText: "Repeat password"
                    echoMode: TextInput.Password

                    // background: Rectangle {
                    //     color: "white"
                    //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                    //     border.width: parent.activeFocus ? 2 : 1
                    //     radius: 6
                    // }
                }
            }
        }

        // Error message
        Rectangle {
            Layout.fillWidth: true
            height: errorText.height + 12
            color: "#FFEBEE"
            radius: 6
            visible: errorMessage !== ""
            border.color: errorColor
            border.width: 1

            Text {
                id: errorText
                text: errorMessage
                color: errorColor
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 10
                }
            }
        }
    }

    footer: DialogButtonBox {
        background: Rectangle {
            color: "white"
            radius: 12

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 12
                color: "white"
            }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#E0E0E0"
            }
        }

        Button {
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole

            contentItem: Text {
                text: "Cancel"
                color: "#666666"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.pressed ? "#E0E0E0" : parent.hovered ? "#F0F0F0" : "white"
                radius: 6
                border.color: "#CCCCCC"
                border.width: 1
            }
        }

        Button {
            text: "Add Admin"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled: selectedStaff !== null &&
                     usernameField.text.trim() !== "" &&
                     passwordField.text !== "" &&
                     confirmPasswordField.text !== "" &&
                     (appManager ? appManager.isUsernameAvailable(usernameField.text.trim()) : false)

            contentItem: Text {
                text: "Add Admin"
                color: "white"
                font.pixelSize: 13
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.enabled ?
                       (parent.pressed ? Qt.darker(accentColor, 1.1) :
                        parent.hovered ? Qt.lighter(accentColor, 1.1) : accentColor) :
                       "#CCCCCC"
                radius: 6
            }

            onClicked: {
                errorMessage = ""

                // Validate
                if (passwordField.text !== confirmPasswordField.text) {
                    errorMessage = "Passwords do not match"
                    return
                }

                if (passwordField.text.length < 6) {
                    errorMessage = "Password must be at least 6 characters"
                    return
                }

                if (appManager && selectedStaff) {
                    var success = appManager.addAdmin(
                        selectedStaff.staffId,
                        usernameField.text.trim(),
                        passwordField.text
                    )

                    if (success) {
                        addAdminDialog.close()
                    }
                    // Error will be shown via errorOccurred signal
                }
            }
        }
    }

    // Handle errors
    Connections {
        target: appManager
        function onErrorOccurred(error) {
            if (addAdminDialog.visible) {
                errorMessage = error
            }
        }
    }
}
