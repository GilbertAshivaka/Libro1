import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

/**
 * EditDetailsDialog - Dialog for editing user account details
 *
 * Shows user details and allows editing with admin password verification.
 * Fields cannot be saved until a valid admin password is provided.
 */
Popup {
    id: editDetailsDialog

    width: Math.min(500, parent.width * 0.9)
    height: Math.min(600, parent.height * 0.85)
    anchors.centerIn: parent
    modal: true
    closePolicy: Popup.CloseOnEscape

    // User properties to be set by parent
    property int userId: 0
    property string userRole: ""  // "Student", "Staff", or "Other"
    property var userDetails: ({})

    // State
    property bool isEditing: false
    property bool passwordVerified: false
    property string errorMessage: ""

    signal detailsUpdated()

    background: Rectangle {
        color: "#FFFFFF"
        radius: 12
        border.color: "#E0E0E0"
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.5
            shadowVerticalOffset: 4
        }
    }

    onOpened: {
        loadUserDetails()
        passwordVerified = false
        isEditing = false
        errorMessage = ""
        adminPasswordField.text = ""
    }

    function loadUserDetails() {
        if (userId > 0 && typeof userManager !== 'undefined') {
            userDetails = userManager.getUserById(userId)
            populateFields()
        }
    }

    function populateFields() {
        firstNameField.text = userDetails.firstName || ""
        secondNameField.text = userDetails.secondName || ""
        emailField.text = userDetails.email || ""
        phoneField.text = userDetails.phone || ""

        // Role-specific fields
        if (userRole === "Student") {
            roleSpecificLabel1.text = "Admission No:"
            roleSpecificField1.text = userDetails.admNo || ""
            roleSpecificLabel2.text = "Branch:"
            roleSpecificField2.text = userDetails.branch || ""
            roleSpecificLabel3.text = "Level:"
            roleSpecificField3.text = userDetails.level || ""
            roleSpecificRow3.visible = true
        } else if (userRole === "Staff") {
            roleSpecificLabel1.text = "Staff No:"
            roleSpecificField1.text = userDetails.staffNo || ""
            roleSpecificLabel2.text = "Department:"
            roleSpecificField2.text = userDetails.department || ""
            roleSpecificLabel3.text = "Category:"
            roleSpecificField3.text = userDetails.category || ""
            roleSpecificRow3.visible = true
        } else if (userRole === "Other") {
            roleSpecificLabel1.text = "User No:"
            roleSpecificField1.text = userDetails.userNo || ""
            roleSpecificLabel2.text = "Residence:"
            roleSpecificField2.text = userDetails.residence || ""
            roleSpecificRow3.visible = false
        }
    }

    function saveChanges() {
        if (!passwordVerified) {
            errorMessage = "Please verify admin password first"
            return
        }

        var updates = {}

        // Common fields
        if (firstNameField.text !== userDetails.firstName) {
            updates["first_name"] = firstNameField.text
        }
        if (secondNameField.text !== userDetails.secondName) {
            updates["second_name"] = secondNameField.text
        }
        if (emailField.text !== userDetails.email) {
            updates["email"] = emailField.text
        }
        if (phoneField.text !== userDetails.phone) {
            updates["phone"] = phoneField.text
        }

        // Role-specific fields
        if (userRole === "Student") {
            if (roleSpecificField2.text !== userDetails.branch) {
                updates["branch"] = roleSpecificField2.text
            }
            if (roleSpecificField3.text !== userDetails.level) {
                updates["level"] = roleSpecificField3.text
            }
        } else if (userRole === "Staff") {
            if (roleSpecificField2.text !== userDetails.department) {
                updates["department"] = roleSpecificField2.text
            }
            if (roleSpecificField3.text !== userDetails.category) {
                updates["category"] = roleSpecificField3.text
            }
        } else if (userRole === "Other") {
            if (roleSpecificField2.text !== userDetails.residence) {
                updates["residence"] = roleSpecificField2.text
            }
        }

        if (Object.keys(updates).length === 0) {
            errorMessage = "No changes to save"
            return
        }

        if (typeof userManager !== 'undefined') {
            var success = userManager.updateUserDetails(userId, updates, adminPasswordField.text)
            if (success) {
                editDetailsDialog.close()
                detailsUpdated()
            } else {
                errorMessage = "Failed to save changes"
            }
        }
    }

    function verifyPassword() {
        if (adminPasswordField.text.length === 0) {
            errorMessage = "Please enter admin password"
            return
        }

        if (typeof userManager !== 'undefined') {
            passwordVerified = userManager.verifyAdminPassword(adminPasswordField.text)
            if (passwordVerified) {
                isEditing = true
                errorMessage = ""
            } else {
                errorMessage = "Invalid admin password"
                passwordVerified = false
            }
        } else {
            // Fallback for testing - use placeholder password
            passwordVerified = (adminPasswordField.text === "admin123")
            if (passwordVerified) {
                isEditing = true
                errorMessage = ""
            } else {
                errorMessage = "Invalid admin password"
            }
        }
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Edit Account Details"
                font.pixelSize: 20
                font.bold: true
                color: "#333333"
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: closeMA.containsMouse ? "#F0F0F0" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 16
                    color: "#666666"
                }

                MouseArea {
                    id: closeMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editDetailsDialog.close()
                }
            }
        }

        // Status badge
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 4
            color: passwordVerified ? "#E8F5E9" : "#FFF3E0"

            Text {
                anchors.centerIn: parent
                text: passwordVerified ? "✓ Editing enabled" : "🔒 Read-only mode - verify admin password to edit"
                font.pixelSize: 12
                color: passwordVerified ? "#2E7D32" : "#E65100"
            }
        }

        // Scrollable content
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 12

                // Common fields
                Text {
                    text: "Personal Information"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#555555"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 15
                    rowSpacing: 10

                    Text { text: "First Name:"; color: "#666666"; font.pixelSize: 13 }
                    TextField {
                        id: firstNameField
                        Layout.fillWidth: true
                        enabled: isEditing
                        placeholderText: "First name"
                    }

                    Text { text: "Second Name:"; color: "#666666"; font.pixelSize: 13 }
                    TextField {
                        id: secondNameField
                        Layout.fillWidth: true
                        enabled: isEditing
                        placeholderText: "Second name"
                    }

                    Text { text: "Email:"; color: "#666666"; font.pixelSize: 13 }
                    TextField {
                        id: emailField
                        Layout.fillWidth: true
                        enabled: isEditing
                        placeholderText: "Email address"
                    }

                    Text { text: "Phone:"; color: "#666666"; font.pixelSize: 13 }
                    TextField {
                        id: phoneField
                        Layout.fillWidth: true
                        enabled: isEditing
                        placeholderText: "Phone number"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#E0E0E0"
                }

                // Role-specific fields
                Text {
                    text: userRole === "Student" ? "Student Information" :
                          userRole === "Staff" ? "Staff Information" : "User Information"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#555555"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 15
                    rowSpacing: 10

                    Text { id: roleSpecificLabel1; color: "#666666"; font.pixelSize: 13 }
                    TextField {
                        id: roleSpecificField1
                        Layout.fillWidth: true
                        enabled: false  // User number cannot be edited
                        background: Rectangle {
                            color: "#F5F5F5"
                            border.color: "#E0E0E0"
                            radius: 4
                        }
                    }

                    Text { id: roleSpecificLabel2; color: "#666666"; font.pixelSize: 13 }
                    TextField {
                        id: roleSpecificField2
                        Layout.fillWidth: true
                        enabled: isEditing
                    }

                    RowLayout {
                        id: roleSpecificRow3
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        spacing: 15

                        Text { id: roleSpecificLabel3; color: "#666666"; font.pixelSize: 13 }
                        TextField {
                            id: roleSpecificField3
                            Layout.fillWidth: true
                            enabled: isEditing
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#E0E0E0"
                }

                // Statistics (read-only)
                Text {
                    text: "Library Statistics"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#555555"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 15
                    rowSpacing: 8

                    Text { text: "Total Books Issued:"; color: "#666666"; font.pixelSize: 13 }
                    Text {
                        text: userDetails.totalBooksIssued || "0"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#333333"
                    }

                    Text { text: "Currently Borrowed:"; color: "#666666"; font.pixelSize: 13 }
                    Text {
                        text: userDetails.currentlyBorrowed || "0"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#333333"
                    }

                    Text { text: "Overdue Books:"; color: "#666666"; font.pixelSize: 13 }
                    Text {
                        text: userDetails.overdueCount || "0"
                        font.pixelSize: 13
                        font.bold: true
                        color: (userDetails.overdueCount || 0) > 0 ? "#D32F2F" : "#333333"
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
        }

        // Admin password section
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Admin Password:"
                font.pixelSize: 13
                color: "#666666"
            }

            TextField {
                id: adminPasswordField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "Enter admin password to enable editing"
                enabled: !passwordVerified
            }

            Button {
                text: passwordVerified ? "Verified ✓" : "Verify"
                enabled: !passwordVerified && adminPasswordField.text.length > 0
                onClicked: verifyPassword()

                background: Rectangle {
                    color: passwordVerified ? "#4CAF50" : (parent.enabled ? "#2196F3" : "#CCCCCC")
                    radius: 4
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Error message
        Text {
            Layout.fillWidth: true
            text: errorMessage
            color: "#D32F2F"
            font.pixelSize: 12
            visible: errorMessage.length > 0
            horizontalAlignment: Text.AlignHCenter
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item { Layout.fillWidth: true }

            Button {
                text: "Cancel"
                onClicked: editDetailsDialog.close()

                background: Rectangle {
                    color: parent.hovered ? "#F0F0F0" : "#FFFFFF"
                    border.color: "#CCCCCC"
                    border.width: 1
                    radius: 4
                }
            }

            Button {
                text: "Save Changes"
                enabled: passwordVerified
                onClicked: saveChanges()

                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#1976D2" : "#2196F3") : "#CCCCCC"
                    radius: 4
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
