import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * AppManagerPage.qml
 * Main page for viewing license status, managing admins, and changing passwords.
 * Displayed in the More Tools content area.
 */
Rectangle {
    id: appManagerPage
    color: "#F5F5F5"

    // Colors
    readonly property color accentColor: "#0078D4"
    readonly property color successColor: "#388E3C"
    readonly property color warningColor: "#F57C00"
    readonly property color errorColor: "#D32F2F"
    readonly property color cardColor: "#FFFFFF"

    // Refresh admin list
    function refreshAdmins() {
        if (appManager) {
            adminListModel.clear()
            var admins = appManager.getAllAdmins()
            for (var i = 0; i < admins.length; i++) {
                adminListModel.append(admins[i])
            }
        }
    }

    Component.onCompleted: {
        refreshAdmins()
    }

    // Admin list model
    ListModel {
        id: adminListModel
    }

    // Handle admin state changes
    Connections {
        target: appManager
        function onAdminStateChanged() {
            refreshAdmins()
        }
        function onValidationCompleted(success, message) {
            validationMessage.text = message
            validationMessage.color = success ? successColor : warningColor
            validationMessageTimer.start()
        }
    }

    Timer {
        id: validationMessageTimer
        interval: 5000
        onTriggered: validationMessage.text = ""
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: cardColor

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 20
                        rightMargin: 20
                    }

                    Text {
                        text: "App Manager"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#1A1A1A"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        id: validationMessage
                        font.pixelSize: 12
                        visible: text !== ""
                    }
                }
            }

            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 20

                // ============ LICENSE STATUS CARD ============
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: licenseContent.height + 32
                    color: cardColor
                    radius: 8
                    border.color: "#E0E0E0"
                    border.width: 1

                    ColumnLayout {
                        id: licenseContent
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 16
                        }
                        spacing: 16

                        // Card header
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "License Status"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#1A1A1A"
                            }

                            Item { Layout.fillWidth: true }

                            // Status badge
                            Rectangle {
                                width: statusBadgeText.width + 16
                                height: 26
                                radius: 13
                                color: {
                                    if (!appManager) return "#E0E0E0"
                                    switch(appManager.licenseStatus) {
                                        case "active": return "#E8F5E9"
                                        case "trial": return "#E3F2FD"
                                        case "grace_period": return "#FFF3E0"
                                        case "expired":
                                        case "blocked": return "#FFEBEE"
                                        default: return "#E0E0E0"
                                    }
                                }

                                Text {
                                    id: statusBadgeText
                                    anchors.centerIn: parent
                                    text: {
                                        if (!appManager) return "Unknown"
                                        switch(appManager.licenseStatus) {
                                            case "active": return "● Active"
                                            case "trial": return "● Trial"
                                            case "grace_period": return "● Grace Period"
                                            case "expired": return "● Expired"
                                            case "blocked": return "● Blocked"
                                            default: return "● Unknown"
                                        }
                                    }
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: {
                                        if (!appManager) return "#666666"
                                        switch(appManager.licenseStatus) {
                                            case "active": return successColor
                                            case "trial": return accentColor
                                            case "grace_period": return warningColor
                                            case "expired":
                                            case "blocked": return errorColor
                                            default: return "#666666"
                                        }
                                    }
                                }
                            }

                            // Refresh button
                            Button {
                                width: 36
                                height: 36
                                enabled: !appManager || !appManager.isValidating

                                contentItem: Text {
                                    text: "⟳"
                                    font.pixelSize: 18
                                    color: accentColor
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.hovered ? "#F0F0F0" : "transparent"
                                    radius: 4
                                }

                                onClicked: {
                                    if (appManager) appManager.manualValidation()
                                }

                                ToolTip.visible: hovered
                                ToolTip.text: "Refresh license status"
                            }
                        }

                        // License details grid
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 40
                            rowSpacing: 12

                            // Organization
                            Text { text: "Organization"; font.pixelSize: 13; font.bold: true; color: "#666666" }
                            Text { text: appManager ? appManager.organizationName : "N/A"; font.pixelSize: 13; color: "#1A1A1A" }

                            // Location
                            Text { text: "Location"; font.pixelSize: 13; font.bold: true; color: "#666666" }
                            Text { text: appManager ? appManager.organizationLocation : "N/A"; font.pixelSize: 13; color: "#1A1A1A" }

                            // License Tier
                            Text { text: "Plan"; font.pixelSize: 13; font.bold: true; color: "#666666" }
                            Text {
                                text: appManager ? (appManager.licenseTier.charAt(0).toUpperCase() + appManager.licenseTier.slice(1)) : "N/A"
                                font.pixelSize: 13
                                color: "#1A1A1A"
                            }

                            // Expiry
                            Text { text: "Expires"; font.pixelSize: 13; font.bold: true; color: "#666666" }
                            Row {
                                spacing: 8
                                Text {
                                    text: appManager ? Qt.formatDate(appManager.expiryDate, "MMMM d, yyyy") : "N/A"
                                    font.pixelSize: 13
                                    color: "#1A1A1A"
                                }
                                Text {
                                    text: appManager && appManager.daysRemaining > 0 ?
                                          "(" + appManager.daysRemaining + " days)" :
                                          appManager && appManager.isGracePeriod ?
                                          "(Grace: " + appManager.graceDaysRemaining + " days left)" : ""
                                    font.pixelSize: 12
                                    color: appManager && appManager.isGracePeriod ? warningColor : "#999999"
                                }
                            }

                            // Last check
                            Text { text: "Last Validated"; font.pixelSize: 13; font.bold: true; color: "#666666" }
                            Text { text: appManager ? appManager.lastValidationTime : "Never"; font.pixelSize: 13; color: "#1A1A1A" }

                            // Org ID
                            Text { text: "Organization ID"; font.pixelSize: 13; font.bold: true; color: "#666666" }
                            Text { text: appManager ? appManager.organizationId : "N/A"; font.pixelSize: 13; font.family: "Consolas"; color: "#666666" }
                        }
                    }
                }

                // ============ ADMINISTRATORS CARD ============
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: adminContent.height + 32
                    color: cardColor
                    radius: 8
                    border.color: "#E0E0E0"
                    border.width: 1

                    ColumnLayout {
                        id: adminContent
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 16
                        }
                        spacing: 16

                        // Card header
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Administrators"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#1A1A1A"
                            }

                            Item { Layout.fillWidth: true }

                            // Add admin button (only if logged in as admin)
                            Button {
                                visible: appManager && appManager.isAdminLoggedIn
                                height: 32

                                contentItem: Row {
                                    spacing: 6
                                    anchors.centerIn: parent

                                    Text {
                                        text: "+"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Add Admin"
                                        font.pixelSize: 13
                                        color: "white"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                background: Rectangle {
                                    color: parent.pressed ? Qt.darker(accentColor, 1.1) :
                                           parent.hovered ? Qt.lighter(accentColor, 1.1) : accentColor
                                    radius: 4
                                }

                                onClicked: addAdminDialog.open()
                            }
                        }

                        // Admin list
                        ListView {
                            id: adminListView
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 300)
                            model: adminListModel
                            spacing: 8
                            clip: true

                            delegate: Rectangle {
                                width: adminListView.width
                                height: 56
                                color: mouseArea.containsMouse ? "#F5F5F5" : "transparent"
                                radius: 6

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: 12
                                        rightMargin: 12
                                    }
                                    spacing: 12

                                    // Avatar
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: model.isSuperAdmin ? "#E3F2FD" : "#F5F5F5"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "👤"
                                            font.pixelSize: 18
                                        }
                                    }

                                    // Info
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Row {
                                            spacing: 8

                                            Text {
                                                text: model.adminName
                                                font.pixelSize: 14
                                                font.bold: true
                                                color: "#1A1A1A"
                                            }

                                            Text {
                                                text: "(" + model.username + ")"
                                                font.pixelSize: 13
                                                color: "#666666"
                                            }

                                            // Super admin badge
                                            Rectangle {
                                                visible: model.isSuperAdmin
                                                width: superAdminText.width + 8
                                                height: 18
                                                radius: 9
                                                color: "#E3F2FD"

                                                Text {
                                                    id: superAdminText
                                                    anchors.centerIn: parent
                                                    text: "Super"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: accentColor
                                                }
                                            }
                                        }

                                        Text {
                                            text: model.department + " • " + model.staffNo
                                            font.pixelSize: 12
                                            color: "#999999"
                                        }
                                    }

                                    // Status
                                    Rectangle {
                                        width: statusText.width + 12
                                        height: 22
                                        radius: 11
                                        color: model.isActive ? "#E8F5E9" : "#FFEBEE"

                                        Text {
                                            id: statusText
                                            anchors.centerIn: parent
                                            text: model.isActive ? "Active" : "Inactive"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: model.isActive ? successColor : errorColor
                                        }
                                    }

                                    // Actions menu (only for logged in admin, not for self)
                                    Button {
                                        visible: appManager && appManager.isAdminLoggedIn &&
                                                 model.adminId !== appManager.currentAdminId
                                        width: 32
                                        height: 32

                                        contentItem: Text {
                                            text: "⋮"
                                            font.pixelSize: 18
                                            color: "#666666"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        background: Rectangle {
                                            color: parent.hovered ? "#E0E0E0" : "transparent"
                                            radius: 4
                                        }

                                        onClicked: {
                                            adminActionMenu.adminId = model.adminId
                                            adminActionMenu.isActive = model.isActive
                                            adminActionMenu.popup()
                                        }

                                        Menu {
                                            id: adminActionMenu
                                            property int adminId: 0
                                            property bool isActive: true

                                            MenuItem {
                                                text: adminActionMenu.isActive ? "Deactivate" : "Reactivate"
                                                onTriggered: {
                                                    if (adminActionMenu.isActive) {
                                                        appManager.deactivateAdmin(adminActionMenu.adminId)
                                                    } else {
                                                        appManager.reactivateAdmin(adminActionMenu.adminId)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                visible: adminListModel.count === 0
                                anchors.centerIn: parent
                                text: "No administrators found"
                                font.pixelSize: 13
                                color: "#999999"
                            }
                        }
                    }
                }

                // ============ CHANGE PASSWORD CARD ============
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: passwordContent.height + 32
                    color: cardColor
                    radius: 8
                    border.color: "#E0E0E0"
                    border.width: 1
                    visible: appManager && appManager.isAdminLoggedIn

                    ColumnLayout {
                        id: passwordContent
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 16
                        }
                        spacing: 16

                        Text {
                            text: "Change Password"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#1A1A1A"
                        }

                        Text {
                            text: "Logged in as: " + (appManager ? appManager.currentAdminUsername : "")
                            font.pixelSize: 13
                            color: "#666666"
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 12

                            Text { text: "Current Password"; font.pixelSize: 13; color: "#333333" }
                            TextField {
                                id: currentPasswordField
                                Layout.fillWidth: true
                                height: 36
                                echoMode: TextInput.Password
                                placeholderText: "Enter current password"
                                background: Rectangle {
                                    color: "white"
                                    border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                    radius: 4
                                }
                            }

                            Text { text: "New Password"; font.pixelSize: 13; color: "#333333" }
                            TextField {
                                id: newPasswordField
                                Layout.fillWidth: true
                                height: 36
                                echoMode: TextInput.Password
                                placeholderText: "Min. 6 characters"
                                background: Rectangle {
                                    color: "white"
                                    border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                    radius: 4
                                }
                            }

                            Text { text: "Confirm Password"; font.pixelSize: 13; color: "#333333" }
                            TextField {
                                id: confirmNewPasswordField
                                Layout.fillWidth: true
                                height: 36
                                echoMode: TextInput.Password
                                placeholderText: "Repeat new password"
                                background: Rectangle {
                                    color: "white"
                                    border.color: parent.activeFocus ? accentColor : "#CCCCCC"
                                    radius: 4
                                }
                            }
                        }

                        // Error/success message
                        Text {
                            id: passwordMessage
                            Layout.fillWidth: true
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            visible: text !== ""
                        }

                        Button {
                            height: 36
                            enabled: currentPasswordField.text !== "" &&
                                     newPasswordField.text !== "" &&
                                     confirmNewPasswordField.text !== ""

                            contentItem: Text {
                                text: "Update Password"
                                color: "white"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: parent.enabled ?
                                       (parent.pressed ? Qt.darker(accentColor, 1.1) :
                                        parent.hovered ? Qt.lighter(accentColor, 1.1) : accentColor) :
                                       "#CCCCCC"
                                radius: 4
                            }

                            onClicked: {
                                passwordMessage.text = ""

                                if (newPasswordField.text !== confirmNewPasswordField.text) {
                                    passwordMessage.text = "Passwords do not match"
                                    passwordMessage.color = errorColor
                                    return
                                }

                                if (newPasswordField.text.length < 6) {
                                    passwordMessage.text = "Password must be at least 6 characters"
                                    passwordMessage.color = errorColor
                                    return
                                }

                                if (appManager) {
                                    var success = appManager.changeAdminPassword(
                                        appManager.currentAdminId,
                                        currentPasswordField.text,
                                        newPasswordField.text
                                    )

                                    if (success) {
                                        passwordMessage.text = "Password updated successfully"
                                        passwordMessage.color = successColor
                                        currentPasswordField.text = ""
                                        newPasswordField.text = ""
                                        confirmNewPasswordField.text = ""
                                    } else {
                                        passwordMessage.text = "Failed to update password. Check current password."
                                        passwordMessage.color = errorColor
                                    }
                                }
                            }
                        }
                    }
                }

                // Spacer
                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: 20
                }
            }
        }
    }

    // Add Admin Dialog
    AddAdminDialog {
        id: addAdminDialog
        anchors.centerIn: parent
    }
}
