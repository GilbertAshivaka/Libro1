import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import com.libro.settings 1.0
import ".." //import Searchbox.qml


/**
 * SettingsPage.qml
 * Main settings page with Windows 11-inspired design.
 * Features a left navigation panel and right content area.
 */
Page {
    id: settingsPage
    title: "Settings"
    anchors.fill: parent

    signal closeClicked()

    // Access the SettingsManager singleton
    readonly property var settings: SettingsManager

    // Current selected category
    property int currentCategoryIndex: 0

    // Category definitions
    readonly property var categories: [
        { name: "General", icon: "../assets/settingsIcon.png", description: "Library information and branding" },
        { name: "Circulation", icon: "../assets/booksSettingsIcon.png", description: "Loan rules and fine settings" },
        { name: "Reservations", icon: "../assets/reservationsSettings.png", description: "Reservation policies" },
        { name: "Email", icon: "../assets/mailSettings.png", description: "SMTP and notification settings" },
        { name: "System", icon: "../assets/systemSettings.png", description: "Maintenance and backup options" },
        { name: "About", icon: "../assets/info3.png", description: "Application information" }
    ]

    // Color scheme (Windows 11 inspired)
    readonly property color accentColor: "#0078D4"
    readonly property color backgroundColor: "#F3F3F3"
    readonly property color cardColor: "#FFFFFF"
    readonly property color textColor: "#1A1A1A"
    readonly property color secondaryTextColor: "#666666"
    readonly property color borderColor: "#E0E0E0"
    readonly property color hoverColor: "#E8E8E8"
    readonly property color selectedColor: "#E5F1FB"

    // background: Rectangle {
    //     color: backgroundColor
    // }

    // Block mouse events from propagating
    MouseArea {
        anchors.fill: parent
        preventStealing: true
    }

    // Main layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════════════════════════════════
        // LEFT NAVIGATION PANEL
        // ═══════════════════════════════════════════════════════════════════════
        Rectangle {
            id: navPanel
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: cardColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Header with title and close button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // Label {
                    //     text: "⚙️ Settings"
                    //     font.pixelSize: 24
                    //     font.bold: true
                    //     color: textColor
                    //     Layout.fillWidth: true
                    // }

                    // // Close button
                    // Rectangle {
                    //     width: 36
                    //     height: 36
                    //     radius: 18
                    //     color: closeMA.containsMouse ? hoverColor : "transparent"

                    //     Text {
                    //         anchors.centerIn: parent
                    //         text: "✕"
                    //         font.pixelSize: 16
                    //         color: textColor
                    //     }

                    //     MouseArea {
                    //         id: closeMA
                    //         anchors.fill: parent
                    //         hoverEnabled: true
                    //         cursorShape: Qt.PointingHandCursor
                    //         onClicked: settingsPage.closeClicked()
                    //     }
                    // }

                    Rectangle{
                        id: backRect
                        width: 36
                        height: 36
                        radius: 4
                        color: "#DDDDDD"
                        // anchors{
                        //     left: parent.left
                        //     leftMargin: 5
                        //     top: parent.top
                        //     topMargin: 5
                        // }

                        Rectangle{
                            id: backBtnRect
                            width: 18
                            height: 18
                            radius: 4
                            anchors.centerIn: parent
                            color: "transparent"

                            Image{
                                id: back
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: "../assets/backArrow.png"
                            }
                        }

                        MouseArea{
                            id: backMA
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: {
                                backRect.color = "#E8E3E4"
                            }
                            onExited: {
                                backRect.color = "#DDDDDD"
                            }

                            onClicked: {
                                settingsPage.closeClicked()
                            }
                        }
                    }

                    Rectangle{
                        id: settingsTxtRect
                        implicitWidth: settingsTxt.width
                        color: "transparent"

                        // anchors{
                        //     left: backRect.right
                        //     leftMargin: 30
                        //     top: backRect.top
                        //     bottom: backRect.bottom
                        // }

                        Text {
                            id: settingsTxt
                            anchors.verticalCenter: parent.verticalCenter

                            text: "Settings"
                            font.bold: false
                            font.pointSize: 12
                        }
                    }
                }

                // Search box (visual placeholder)
                Searchbox {
                    Layout.fillWidth: true
                    placeHolderText: "Find a setting"
                    height: 50
                    radius: 8
                    color: backgroundColor
                    border.color: borderColor
                    border.width: 1
                }

                Item { height: 8 }

                // Navigation items
                ListView {
                    id: navListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: categories
                    spacing: 4
                    clip: true
                    currentIndex: currentCategoryIndex

                    delegate: Rectangle {
                        width: navListView.width
                        height: 56
                        radius: 8
                        color: {
                            if (index === currentCategoryIndex) return selectedColor
                            if (navItemMA.containsMouse) return hoverColor
                            return "transparent"
                        }

                        // Left accent bar for selected item
                        Rectangle {
                            width: 3
                            height: parent.height - 16
                            radius: 2
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            color: accentColor
                            visible: index === currentCategoryIndex
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            // Text {
                            //     text: modelData.icon
                            //     font.pixelSize: 20
                            // }

                            Rectangle{
                                id: iconRect
                                width: 24
                                height: 24
                                radius: 4
                                color: "transparent"

                                Image{
                                    id: settingsIcon
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    source: modelData.icon
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.name
                                    font.pixelSize: 14
                                    font.bold: index === currentCategoryIndex
                                    color: textColor
                                }

                                Label {
                                    text: modelData.description
                                    font.pixelSize: 11
                                    color: secondaryTextColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: navItemMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentCategoryIndex = index
                        }
                    }
                }

                // Bottom actions
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: borderColor
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "Export"
                        Layout.fillWidth: true
                        onClicked: exportDialog.open()
                    }

                    Button {
                        text: "Import"
                        Layout.fillWidth: true
                        onClicked: importDialog.open()
                    }
                }

                Button {
                    text: "Reset All to Defaults"
                    Layout.fillWidth: true
                    onClicked: resetConfirmDialog.open()

                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        color: "#D32F2F"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Separator line
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: borderColor
        }

        // ═══════════════════════════════════════════════════════════════════════
        // RIGHT CONTENT AREA
        // ═══════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent" //backgroundColor

            ScrollView {
                id: contentScrollView
                anchors.fill: parent
                anchors.margins: 24
                contentWidth: availableWidth
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    active: true
                    policy: ScrollBar.AsNeeded
                    width: 6
                    parent: contentScrollView
                    anchors.right: contentScrollView.right
                    anchors.top: contentScrollView.top
                    anchors.bottom: contentScrollView.bottom

                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: width / 2
                        color: vbar.pressed ? "#818181" : "#c2c2c2"
                    }

                    background: Rectangle {
                        implicitWidth: 6
                        radius: width / 2
                        color: "#f0f0f0"
                    }
                }

                ColumnLayout {
                    width: contentScrollView.availableWidth
                    spacing: 24

                    RowLayout{
                        // Page title
                        width: contentScrollView.availableWidth
                        spacing: 20

                        Rectangle{
                            id: rightIconRect
                            width: 32
                            height: 32
                            radius: 4
                            color: "transparent"

                            Image{
                                id: rightsettingsIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: categories[currentCategoryIndex].icon
                            }
                        }

                        Label {
                            text: categories[currentCategoryIndex].name
                            font.pixelSize: 18
                            font.bold: true
                            color: textColor
                            Layout.fillWidth: true
                        }
                    }

                    // Content loader based on current category
                    Loader {
                        id: contentLoader
                        Layout.fillWidth: true
                        sourceComponent: {
                            switch (currentCategoryIndex) {
                            case 0: return generalSettingsComponent
                            case 1: return circulationSettingsComponent
                            case 2: return reservationSettingsComponent
                            case 3: return emailSettingsComponent
                            case 4: return systemSettingsComponent
                            case 5: return aboutComponent
                            default: return generalSettingsComponent
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GENERAL SETTINGS COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: generalSettingsComponent

        ColumnLayout {
            width: parent.width
            spacing: 16

            // Application Info Card
            SettingsCard {
                title: "Application"
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    SettingsTextField {
                        label: "Application Title"
                        value: settings.applicationTitle
                        onTextEdited:(newValue) =>{
                                         settings.applicationTitle = newValue
                                     }
                        description: "The main title displayed in the application"
                    }

                    SettingsTextField {
                        label: "Organization Name"
                        value: settings.organizationName
                        onTextEdited: settings.organizationName = newValue
                    }

                    SettingsLabelField {
                        label: "Database File"
                        value: settings.databaseFileName
                        description: "Read-only. The database file cannot be changed."
                    }
                }
            }

            // Library Info Card
            SettingsCard {
                title: "Library Information"
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    SettingsTextField {
                        label: "Library Name"
                        value: settings.libraryName
                        onTextEdited: settings.libraryName = newValue
                        placeholder: "Enter your library name"
                    }

                    SettingsTextField {
                        label: "Address"
                        value: settings.libraryAddress
                        onTextEdited: settings.libraryAddress = newValue
                        placeholder: "Library physical address"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        SettingsTextField {
                            label: "Phone"
                            value: settings.libraryPhone
                            onTextEdited: settings.libraryPhone = newValue
                            placeholder: "+254 xxx xxx xxx"
                            Layout.fillWidth: true
                        }

                        SettingsTextField {
                            label: "Email"
                            value: settings.libraryEmail
                            onTextEdited: settings.libraryEmail = newValue
                            placeholder: "library@example.com"
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CIRCULATION SETTINGS COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: circulationSettingsComponent

        ColumnLayout {
            width: parent.width
            spacing: 16

            // Student Rules
            SettingsCard {
                title: "👨‍🎓 Student Borrowing Rules"
                Layout.fillWidth: true

                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: 24
                    rowSpacing: 12

                    SettingsSpinBox {
                        label: "Max Loan Days"
                        value: settings.studentMaxLoanDays
                        onNumberChanged: settings.studentMaxLoanDays = newValue
                        from: 1
                        to: 90
                        suffix: " days"
                    }

                    SettingsSpinBox {
                        label: "Max Books"
                        value: settings.studentMaxBooksAllowed
                        onNumberChanged: settings.studentMaxBooksAllowed = newValue
                        from: 1
                        to: 20
                        suffix: " books"
                    }

                    SettingsSpinBox {
                        label: "Max Renewals"
                        value: settings.studentMaxRenewals
                        onNumberChanged: settings.studentMaxRenewals = newValue
                        from: 0
                        to: 10
                        suffix: " times"
                    }
                }
            }

            // Staff Rules
            SettingsCard {
                title: "👨‍💼 Staff Borrowing Rules"
                Layout.fillWidth: true

                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: 24
                    rowSpacing: 12

                    SettingsSpinBox {
                        label: "Max Loan Days"
                        value: settings.staffMaxLoanDays
                        onNumberChanged: settings.staffMaxLoanDays = newValue
                        from: 1
                        to: 180
                        suffix: " days"
                    }

                    SettingsSpinBox {
                        label: "Max Books"
                        value: settings.staffMaxBooksAllowed
                        onNumberChanged: settings.staffMaxBooksAllowed = newValue
                        from: 1
                        to: 50
                        suffix: " books"
                    }

                    SettingsSpinBox {
                        label: "Max Renewals"
                        value: settings.staffMaxRenewals
                        onNumberChanged: settings.staffMaxRenewals = newValue
                        from: 0
                        to: 10
                        suffix: " times"
                    }
                }
            }

            // Other Users Rules
            SettingsCard {
                title: "👤 Other Users Borrowing Rules"
                Layout.fillWidth: true

                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: 24
                    rowSpacing: 12

                    SettingsSpinBox {
                        label: "Max Loan Days"
                        value: settings.otherMaxLoanDays
                        onNumberChanged: settings.otherMaxLoanDays = newValue
                        from: 1
                        to: 30
                        suffix: " days"
                    }

                    SettingsSpinBox {
                        label: "Max Books"
                        value: settings.otherMaxBooksAllowed
                        onNumberChanged: settings.otherMaxBooksAllowed = newValue
                        from: 1
                        to: 10
                        suffix: " books"
                    }

                    SettingsSpinBox {
                        label: "Max Renewals"
                        value: settings.otherMaxRenewals
                        onNumberChanged: settings.otherMaxRenewals = newValue
                        from: 0
                        to: 5
                        suffix: " times"
                    }
                }
            }

            // Fine Settings
            SettingsCard {
                title: "💰 Fine Settings"
                Layout.fillWidth: true

                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: 24
                    rowSpacing: 12

                    SettingsTextField {
                        label: "Currency Symbol"
                        value: settings.currencySymbol
                        onTextEdited: settings.currencySymbol = newValue
                        placeholder: "KES"
                        Layout.preferredWidth: 100
                    }

                    SettingsDoubleSpinBox {
                        label: "Fine Rate Per Day"
                        value: settings.fineRatePerDay
                        onNumberChanged: settings.fineRatePerDay = newValue
                        from: 0
                        to: 1000
                        prefix: settings.currencySymbol + " "
                    }

                    SettingsDoubleSpinBox {
                        label: "Maximum Fine"
                        value: settings.maxFineAmount
                        onNumberChanged: settings.maxFineAmount = newValue
                        from: 0
                        to: 10000
                        prefix: settings.currencySymbol + " "
                        description: "Fine cap - fines won't exceed this amount"
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // RESERVATION SETTINGS COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: reservationSettingsComponent

        ColumnLayout {
            width: parent.width
            spacing: 16

            SettingsCard {
                title: "Reservation Policies"
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    SettingsSpinBox {
                        label: "Pickup Deadline"
                        value: settings.reservationPickupDays
                        onNumberChanged: settings.reservationPickupDays = newValue
                        from: 1
                        to: 14
                        suffix: " days"
                        description: "Days users have to pick up a reserved book after notification"
                    }

                    SettingsSpinBox {
                        label: "Reservation Expiry"
                        value: settings.reservationExpiryDays
                        onNumberChanged: settings.reservationExpiryDays = newValue
                        from: 1
                        to: 30
                        suffix: " days"
                        description: "Days a reservation remains active before expiring"
                    }

                    SettingsSpinBox {
                        label: "Max Reservations Per User"
                        value: settings.maxReservationsPerUser
                        onNumberChanged: settings.maxReservationsPerUser = newValue
                        from: 1
                        to: 10
                        suffix: " books"
                        description: "Maximum number of books a user can reserve at once"
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EMAIL SETTINGS COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: emailSettingsComponent

        ColumnLayout {
            width: parent.width
            spacing: 16

            // Email toggle
            SettingsCard {
                title: "Notifications"
                Layout.fillWidth: true

                SettingsSwitch {
                    label: "Enable Email Notifications"
                    checked: settings.emailNotificationsEnabled
                    onToggled: settings.emailNotificationsEnabled = isChecked
                    description: "Send automatic email notifications for overdue books, reservations, etc."
                }
            }

            // SMTP Configuration
            SettingsCard {
                title: "SMTP Server Configuration"
                Layout.fillWidth: true
                enabled: settings.emailNotificationsEnabled

                ColumnLayout {
                    width: parent.width
                    spacing: 12
                    opacity: settings.emailNotificationsEnabled ? 1.0 : 0.5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        SettingsTextField {
                            label: "SMTP Server"
                            value: settings.smtpServer
                            onTextEdited: settings.smtpServer = newValue
                            placeholder: "smtp.gmail.com"
                            Layout.fillWidth: true
                        }

                        SettingsSpinBox {
                            label: "Port"
                            value: settings.smtpPort
                            onNumberChanged: settings.smtpPort = newValue
                            from: 1
                            to: 65535
                            Layout.preferredWidth: 150
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        SettingsTextField {
                            label: "Username"
                            value: settings.smtpUsername
                            onTextEdited: settings.smtpUsername = newValue
                            placeholder: "your-email@gmail.com"
                            Layout.fillWidth: true
                        }

                        SettingsTextField {
                            label: "Password"
                            value: settings.smtpPassword
                            onTextEdited: settings.smtpPassword = newValue
                            placeholder: "••••••••"
                            isPassword: true
                            Layout.fillWidth: true
                        }
                    }

                    SettingsSwitch {
                        label: "Use TLS/SSL"
                        checked: settings.smtpUseTLS
                        onToggled: settings.smtpUseTLS = isChecked
                        description: "Enable secure connection (recommended)"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: borderColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        SettingsTextField {
                            label: "Sender Email"
                            value: settings.senderEmail
                            onTextEdited: settings.senderEmail = newValue
                            placeholder: "noreply@library.com"
                            Layout.fillWidth: true
                        }

                        SettingsTextField {
                            label: "Sender Name"
                            value: settings.senderName
                            onTextEdited: settings.senderName = newValue
                            placeholder: "Library System"
                            Layout.fillWidth: true
                        }
                    }

                    // Test connection button
                    Button {
                        text: "Test Connection"
                        enabled: settings.smtpServer !== "" && settings.smtpUsername !== ""
                        onClicked: {
                            // TODO: Implement test connection
                            testResultLabel.text = "Test connection feature coming soon..."
                            testResultLabel.visible = true
                        }
                    }

                    Label {
                        id: testResultLabel
                        visible: false
                        font.italic: true
                        color: secondaryTextColor
                    }
                }
            }

            // Email Templates
            SettingsCard {
                title: "Email Templates"
                Layout.fillWidth: true
                enabled: settings.emailNotificationsEnabled

                ColumnLayout {
                    width: parent.width
                    spacing: 16
                    opacity: settings.emailNotificationsEnabled ? 1.0 : 0.5

                    Label {
                        text: "Available placeholders: {USER_NAME}, {BOOK_TITLE}, {BOOK_AUTHOR}, {DUE_DATE}, {DAYS_OVERDUE}, {FINE_AMOUNT}, {CURRENCY_SYMBOL}, {PICKUP_DAYS}, {LIBRARY_NAME}, {LIBRARY_EMAIL}, {MAX_BOOKS}, {LOAN_DAYS}, {MAX_RENEWALS}"
                        font.pixelSize: 11
                        color: secondaryTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    SettingsTextArea {
                        label: "Overdue Notification Template"
                        value: settings.overdueEmailTemplate
                        onTextEdited: settings.overdueEmailTemplate = newValue
                        Layout.fillWidth: true
                    }

                    SettingsTextArea {
                        label: "Pickup Notification Template"
                        value: settings.pickupEmailTemplate
                        onTextEdited: settings.pickupEmailTemplate = newValue
                        Layout.fillWidth: true
                    }

                    SettingsTextArea {
                        label: "Welcome Email Template"
                        value: settings.welcomeEmailTemplate
                        onTextEdited: settings.welcomeEmailTemplate = newValue
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SYSTEM SETTINGS COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: systemSettingsComponent

        ColumnLayout {
            width: parent.width
            spacing: 16

            // Logging
            SettingsCard {
                title: "Logging"
                Layout.fillWidth: true

                SettingsSpinBox {
                    label: "Log Retention Period"
                    value: settings.logRetentionDays
                    onNumberChanged: settings.logRetentionDays = newValue
                    from: 7
                    to: 365
                    suffix: " days"
                    description: "System logs older than this will be automatically deleted"
                }
            }

            // Backup
            SettingsCard {
                title: "Backup"
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    SettingsSwitch {
                        label: "Enable Automatic Backup"
                        checked: settings.autoBackupEnabled

                        onToggled: function(isChecked) {
                        settings.autoBackupEnabled = isChecked
                    }
                        description: "Automatically backup the database at regular intervals"
                    }

                    SettingsSpinBox {
                        label: "Backup Interval"
                        value: settings.backupIntervalDays
                        onNumberChanged: settings.backupIntervalDays = newValue
                        from: 1
                        to: 30
                        suffix: " days"
                        enabled: settings.autoBackupEnabled
                        opacity: settings.autoBackupEnabled ? 1.0 : 0.5
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        enabled: settings.autoBackupEnabled
                        opacity: settings.autoBackupEnabled ? 1.0 : 0.5

                        SettingsTextField {
                            label: "Backup Location"
                            value: settings.backupLocation
                            onTextEdited: settings.backupLocation = newValue
                            placeholder: "Select backup folder..."
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "Browse..."
                            onClicked: folderDialog.open()
                        }
                    }

                    Button {
                        text: "Backup Now"
                        enabled: settings.backupLocation !== ""
                        onClicked: {
                            // TODO: Implement immediate backup
                            backupStatusLabel.text = "Manual backup feature coming soon..."
                            backupStatusLabel.visible = true
                        }
                    }

                    Label {
                        id: backupStatusLabel
                        visible: false
                        font.italic: true
                        color: secondaryTextColor
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ABOUT COMPONENT
    // ═══════════════════════════════════════════════════════════════════════════
    Component {
        id: aboutComponent

        ColumnLayout {
            width: parent.width
            spacing: 16

            SettingsCard {
                title: "About Libro"
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    // Logo placeholder
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 80
                        radius: 16
                        color: "transparent"

                        Rectangle{
                            id: appIconRect
                            anchors.centerIn: parent
                            width: 80
                            height: 80
                            radius: 4
                            color: "transparent"

                            Image{
                                id: appIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: "../assets/libroIcon.ico"
                            }
                        }
                    }

                    Label {
                        text: settings.applicationTitle
                        font.pixelSize: 20
                        font.bold: true
                        color: textColor
                    }

                    Label {
                        text: "Version 1.0.0"
                        font.pixelSize: 14
                        color: secondaryTextColor
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: borderColor
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 24
                        rowSpacing: 8

                        Label { text: "Database:"; color: secondaryTextColor }
                        Label { text: settings.databaseFileName; color: textColor }

                        Label { text: "Settings Initialized:"; color: secondaryTextColor }
                        Label { text: settings.isInitialized() ? "Yes" : "No"; color: textColor }

                        Label { text: "Organization:"; color: secondaryTextColor }
                        Label { text: settings.organizationName; color: textColor }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: borderColor
                    }

                    Label {
                        text: "© 2024 Libro Library Management System\nAll rights reserved."
                        font.pixelSize: 12
                        color: secondaryTextColor
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DIALOGS
    // ═══════════════════════════════════════════════════════════════════════════

    FileDialog {
        id: exportDialog
        title: "Export Settings"
        // selectExisting: false
        nameFilters: ["JSON files (*.json)"]
        onAccepted: {
            var path = fileUrl.toString().replace("file:///", "")
            if (settings.exportSettings(path)) {
                exportSuccessDialog.open()
            }
        }
    }

    FileDialog {
        id: importDialog
        title: "Import Settings"
        // selectExisting: true
        nameFilters: ["JSON files (*.json)"]
        onAccepted: {
            var path = fileUrl.toString().replace("file:///", "")
            if (settings.importSettings(path)) {
                importSuccessDialog.open()
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Backup Folder"
        // selectFolder: true
        onAccepted: {
            var path = folderDialog.selectedFolder.toString().replace("file:///", "")
            settings.backupLocation = path
        }
    }

    Dialog {
        id: resetConfirmDialog
        title: "Reset Settings"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        anchors.centerIn: parent

        Label {
            text: "Are you sure you want to reset all settings to their default values?\n\nThis action cannot be undone."
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            settings.resetToDefaults()
        }
    }

    Dialog {
        id: exportSuccessDialog
        title: "Export Successful"
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Label {
            text: "Settings have been exported successfully."
        }
    }

    Dialog {
        id: importSuccessDialog
        title: "Import Successful"
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Label {
            text: "Settings have been imported successfully."
        }
    }
}
