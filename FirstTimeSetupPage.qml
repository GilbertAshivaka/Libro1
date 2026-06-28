import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * FirstTimeSetupPage.qml
 * Shown after activation when no admin exists.
 * Creates the first admin account (users → staff → admins).
 */
Rectangle {
    id: setupPage
    anchors.fill: parent
    color: "#F5F5F5"

    // Signals
    signal setupComplete()

    // Colors
    readonly property color accentColor: "#0078D4"
    readonly property color errorColor: "#D32F2F"
    readonly property color successColor: "#388E3C"

    // State
    property string errorMessage: ""
    property bool isProcessing: false

    // Handle errors from AppManager
    Connections {
        target: appManager
        function onErrorOccurred(error) {
            errorMessage = error
            isProcessing = false
        }
    }



    ScrollView {
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        id: contentSV
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            x: (parent.width - width) / 2
            y: 30
            width: Math.min(550, contentSV.width - 60)
            spacing: 24

            // Header
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Image {
                    source: "assets/libroIcon.ico"
                    width: 64
                    height: 64
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: "Welcome to Libro!"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#1A1A1A"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Let's set up your administrator account"
                    font.pixelSize: 14
                    color: "#666666"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Organization info display
            Rectangle {
                Layout.fillWidth: true
                height: orgInfoColumn.height + 24
                color: "#E3F2FD"
                radius: 8
                border.color: accentColor
                border.width: 1

                Column {
                    id: orgInfoColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 4

                    Text {
                        text: "Organization"
                        font.pixelSize: 11
                        font.bold: true
                        color: accentColor
                    }

                    Text {
                        text: appManager ? appManager.organizationName : "Loading..."
                        font.pixelSize: 16
                        font.bold: true
                        color: "#1A1A1A"
                    }

                    Text {
                        text: appManager ? appManager.organizationLocation : ""
                        font.pixelSize: 13
                        color: "#666666"
                        visible: text !== ""
                    }
                }
            }

            // Setup form card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: formColumn.height + 48
                color: "white"
                radius: 12
                border.color: "#E0E0E0"
                border.width: 1

                ColumnLayout {
                    id: formColumn
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 24
                    }
                    spacing: 20

                    // Section: Personal Details
                    Text {
                        text: "Personal Details"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#1A1A1A"
                    }

                    // Name row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "First Name *"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: firstNameField
                                width: parent.width
                                height: 40
                                placeholderText: "John"
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Last Name *"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: lastNameField
                                width: parent.width
                                height: 40
                                placeholderText: "Doe"
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }
                    }

                    // Email and phone row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Email Address *"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: emailField
                                width: parent.width
                                height: 40
                                placeholderText: "admin@library.com"
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Phone Number"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: phoneField
                                width: parent.width
                                height: 40
                                placeholderText: "+254..."
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#E0E0E0"
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                    }

                    // Section: Staff Details
                    Text {
                        text: "Staff Details"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#1A1A1A"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Staff Number *"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: staffNoField
                                width: parent.width
                                height: 40
                                placeholderText: "ADM-001"
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Department *"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: departmentField
                                width: parent.width
                                height: 40
                                placeholderText: "Administration"
                                text: "Administration"
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#E0E0E0"
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                    }

                    // Section: Login Credentials
                    Text {
                        text: "Login Credentials"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#1A1A1A"
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Username *"
                            font.pixelSize: 13
                            color: "#333333"
                        }

                        TextField {
                            id: usernameField
                            width: parent.width
                            height: 40
                            placeholderText: "admin"
                            enabled: !isProcessing

                            // background: Rectangle {
                            //     color: parent.enabled ? "white" : "#F5F5F5"
                            //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                            //     radius: 6
                            // }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

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
                                enabled: !isProcessing

                                background: Rectangle {
                                    color: parent.enabled ? "white" : "#F5F5F5"
                                    border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                    radius: 6
                                }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Confirm Password *"
                                font.pixelSize: 13
                                color: "#333333"
                            }

                            TextField {
                                id: confirmPasswordField
                                width: parent.width
                                height: 40
                                placeholderText: "Repeat password"
                                echoMode: TextInput.Password
                                enabled: !isProcessing

                                // background: Rectangle {
                                //     color: parent.enabled ? "white" : "#F5F5F5"
                                //     border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                //     radius: 6
                                // }
                            }
                        }
                    }

                    // Error message
                    Rectangle {
                        Layout.fillWidth: true
                        height: setupErrorText.height + 16
                        color: "#FFEBEE"
                        radius: 6
                        visible: errorMessage !== ""
                        border.color: errorColor
                        border.width: 1

                        Text {
                            id: setupErrorText
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

                    // Create button
                    Button {
                        id: createButton
                        Layout.fillWidth: true
                        height: 48
                        enabled: !isProcessing && canSubmit()

                        function canSubmit() {
                            return firstNameField.text.trim() !== "" &&
                                    lastNameField.text.trim() !== "" &&
                                    emailField.text.trim() !== "" &&
                                    staffNoField.text.trim() !== "" &&
                                    departmentField.text.trim() !== "" &&
                                    usernameField.text.trim() !== "" &&
                                    passwordField.text !== "" &&
                                    confirmPasswordField.text !== ""
                        }

                        contentItem: Row {
                            spacing: 8
                            anchors.centerIn: parent

                            BusyIndicator {
                                running: isProcessing
                                visible: isProcessing
                                width: 20
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: isProcessing ? "Creating Account..." : "Create Admin Account"
                                color: "white"
                                font.pixelSize: 15
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        background: Rectangle {
                            color: createButton.enabled ?
                                       (createButton.pressed ? Qt.darker(accentColor, 1.1) :
                                                               createButton.hovered ? Qt.lighter(accentColor, 1.1) : accentColor) :
                                       "#CCCCCC"
                            radius: 6
                        }

                        onClicked: {
                            errorMessage = ""

                            // Validate passwords match
                            if (passwordField.text !== confirmPasswordField.text) {
                                errorMessage = "Passwords do not match"
                                return
                            }

                            // Validate password length
                            if (passwordField.text.length < 6) {
                                errorMessage = "Password must be at least 6 characters"
                                return
                            }

                            // Validate email format (basic)
                            if (!emailField.text.includes("@")) {
                                errorMessage = "Please enter a valid email address"
                                return
                            }

                            isProcessing = true

                            if (appManager) {
                                var success = appManager.setupFirstAdmin(
                                            firstNameField.text.trim(),
                                            lastNameField.text.trim(),
                                            emailField.text.trim(),
                                            phoneField.text.trim(),
                                            staffNoField.text.trim(),
                                            departmentField.text.trim(),
                                            usernameField.text.trim(),
                                            passwordField.text
                                            )

                                if (success) {
                                    setupComplete()
                                } else {
                                    isProcessing = false
                                }
                            }
                        }
                    }

                    // Info text
                    Text {
                        Layout.fillWidth: true
                        text: "This will be the main administrator account with full system access."
                        font.pixelSize: 12
                        color: "#666666"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
