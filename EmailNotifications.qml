import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: emailNotifications
    visible: true
    width: parent.width
    height: parent.height
    color: "#FBFBFB"

    signal closeClicked()

    // Email controller - registered as a context property in main.cpp
    property var emailController: emailNotificationController

    MouseArea {
        id: emailNotificationsMA
        anchors.fill: parent
    }

    // Back button
    Rectangle {
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors {
            left: parent.left
            top: parent.top
            margins: 10
        }

        Rectangle {
            width: 20
            height: 20
            color: "transparent"
            anchors.centerIn: parent

            Image {
                anchors.fill: parent
                source: "assets/backArrow.png"
                fillMode: Image.PreserveAspectFit
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: parent.color = "#CCCCCC"
            onExited: parent.color = "#DDDDDD"
            onClicked: closeClicked()
        }
    }

    // Sidebar for quick actions
    Rectangle {
        id: actionsContainer
        color: "#FBFBFB"
        width: parent.width * 0.21
        radius: 8
        border.width: 1
        border.color: "#E0E0E0"
        clip: true
        property int btnWidth: width * 0.87

        anchors {
            left: parent.left
            top: backRect.bottom
            bottom: parent.bottom
            margins: 10
        }

        // Scrollable wrapper so the action buttons remain reachable when the
        // window is small / minimised. Thin scrollbar matches the email list.
        Flickable {
            id: actionsFlick
            anchors.fill: parent
            anchors.margins: 1
            contentWidth: width
            contentHeight: actionsContent.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                id: actionsVbar
                active: true
                policy: ScrollBar.AsNeeded
                width: 6
                parent: actionsFlick
                anchors.right: actionsFlick.right
                anchors.top: actionsFlick.top
                anchors.bottom: actionsFlick.bottom

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: actionsVbar.pressed ? "#818181" : "#c2c2c2"
                }

                background: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: "#f0f0f0"
                }
            }

            Item {
                id: actionsContent
                width: actionsFlick.width
                height: clearQueueBtn.y + clearQueueBtn.height + 10

        Rectangle {
            id: actionsLabelRect
            height: 40
            width: actionsContainer.btnWidth
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
            color: "transparent"
            radius: 4

            Text {
                id: quickActionsTxt
                width: parent.width
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                text: "Email Actions"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: 14
                color: "#333333"
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        CustomButton {
            id: overdueNotificationsBtn
            text: qsTr("Send Overdue Notifications")
            height: 50
            width: actionsContainer.btnWidth
            enabled: emailController ? emailController.isConfigured : false
            anchors {
                top: actionsLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                if (emailController) {
                    emailController.checkAndSendOverdueNotifications()
                }
            }
        }

        CustomButton {
            id: reservedNotificationsBtn
            text: qsTr("Send Reserved Notifications")
            height: 50
            width: actionsContainer.btnWidth
            enabled: emailController ? emailController.isConfigured : false
            anchors {
                top: overdueNotificationsBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                if (emailController) {
                    emailController.checkAndSendReservedBookNotifications()
                }
            }
        }

        CustomButton {
            id: configureBtn
            text: qsTr("Configure SMTP")
            height: 50
            width: actionsContainer.btnWidth
            anchors {
                top: reservedNotificationsBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                smtpConfigPopup.open()
            }
        }

        CustomButton {
            id: testEmailBtn
            text: qsTr("Send Test Email")
            height: 50
            width: actionsContainer.btnWidth
            enabled: emailController ? emailController.isConfigured : false
            anchors {
                top: configureBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                testEmailPopup.open()
            }
        }

        // Automation (daily scheduler) section
        Rectangle {
            id: automationSection
            width: actionsContainer.btnWidth
            height: autoColumn.height + 20
            color: "#F5F5F5"
            radius: 4
            border.color: "#E0E0E0"
            border.width: 1
            anchors {
                top: testEmailBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 15
            }

            Column {
                id: autoColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 10
                }
                spacing: 8

                Text {
                    text: "Automation"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#333333"
                }

                CheckBox {
                    id: autoSendCheck
                    text: "Auto-send daily"
                    font.pixelSize: 12
                    checked: emailController ? emailController.autoNotificationsEnabled : false
                    onToggled: {
                        if (emailController)
                            emailController.autoNotificationsEnabled = checked
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8
                    visible: autoSendCheck.checked

                    Text {
                        text: "Time:"
                        font.pixelSize: 12
                        color: "#666666"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextField {
                        id: notifTimeField
                        width: 70
                        height: 30
                        font.pixelSize: 12
                        placeholderText: "HH:mm"
                        inputMask: "99:99"
                        text: emailController ? emailController.notificationTime : "08:00"
                        onEditingFinished: {
                            if (emailController)
                                emailController.notificationTime = text
                        }
                    }
                }

                Text {
                    text: "Sends overdue + reserved reminders once a day."
                    font.pixelSize: 10
                    color: "#888888"
                    wrapMode: Text.WordWrap
                    width: parent.width
                    visible: autoSendCheck.checked
                }
            }
        }

        // Statistics section
        Rectangle {
            id: statsLabelRect
            height: 40
            width: actionsContainer.btnWidth
            anchors {
                top: automationSection.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 20
            }
            color: "transparent"
            radius: 4

            Text {
                width: parent.width
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                text: "Statistics"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: 14
                color: "#333333"
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Rectangle {
            id: statsContainer
            width: actionsContainer.btnWidth
            height: 120
            color: "#F5F5F5"
            radius: 4
            border.color: "#E0E0E0"
            border.width: 1
            anchors {
                top: statsLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            Column {
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 8

                Row {
                    width: parent.width
                    Text {
                        text: "Emails Sent: "
                        font.pixelSize: 12
                        color: "#666666"
                        width: parent.width * 0.6
                    }
                    Text {
                        text: emailController ? emailController.totalEmailsSent : "0"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#4CAF50"
                        width: parent.width * 0.4
                    }
                }

                Row {
                    width: parent.width
                    Text {
                        text: "Emails Failed: "
                        font.pixelSize: 12
                        color: "#666666"
                        width: parent.width * 0.6
                    }
                    Text {
                        text: emailController ? emailController.totalEmailsFailed : "0"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#F44336"
                        width: parent.width * 0.4
                    }
                }

                Row {
                    width: parent.width
                    Text {
                        text: "Queue Size: "
                        font.pixelSize: 12
                        color: "#666666"
                        width: parent.width * 0.6
                    }
                    Text {
                        text: emailController ? emailController.queueSize : "0"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#FF9800"
                        width: parent.width * 0.4
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#E0E0E0"
                }

                Text {
                    text: "Status: " + (emailController && emailController.isConfigured ? "Configured" : "Not Configured")
                    font.pixelSize: 11
                    color: emailController && emailController.isConfigured ? "#4CAF50" : "#F44336"
                    width: parent.width
                }
            }
        }

        CustomButton {
            id: clearQueueBtn
            text: qsTr("Clear Queue")
            height: 40
            width: actionsContainer.btnWidth
            enabled: emailController ? emailController.queueSize > 0 : false
            anchors {
                top: statsContainer.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 10
            }

            onClicked: {
                if (emailController) {
                    emailController.clearQueue()
                }
            }
        }

            } // actionsContent
        } // actionsFlick
    }

    // Main content area
    Rectangle {
        id: mainContent
        anchors {
            left: actionsContainer.right
            top: backRect.bottom
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        color: "transparent"

        // Page title
        Rectangle {
            id: pageTitleRect
            height: 40
            width: pageTitle.width
            color: "transparent"
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 10
                leftMargin: 10
            }

            Text {
                id: pageTitle
                text: "Email Notifications"
                font.pointSize: 16
                font.bold: true
                color: "#878585"
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        // Activity status
        Rectangle {
            id: activityRect
            height: 30
            width: parent.width - 20
            color: "#F5F5F5"
            radius: 4
            border.color: "#E0E0E0"
            border.width: 1
            anchors {
                top: pageTitleRect.bottom
                left: parent.left
                leftMargin: 10
                topMargin: 10
            }

            Text {
                text: emailController ? emailController.lastActivity : "System ready"
                font.pixelSize: 11
                color: "#666666"
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                elide: Text.ElideRight
                width: parent.width - 20
            }

            // Processing indicator
            Rectangle {
                id: processingIndicator  // Add an id
                width: 12
                height: 12
                radius: 6
                color: emailController && emailController.isProcessing ? "#4CAF50" : "#CCCCCC"
                opacity: 1.0  // Set default opacity explicitly
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 10
                }

                SequentialAnimation {
                    running: emailController && emailController.isProcessing
                    loops: Animation.Infinite

                    onRunningChanged: {
                        if (!running) {
                            processingIndicator.opacity = 1.0  // Reset when animation stops
                        }
                    }

                    PropertyAnimation {
                        target: processingIndicator
                        property: "opacity"
                        from: 1.0
                        to: 0.3
                        duration: 800
                    }
                    PropertyAnimation {
                        target: processingIndicator
                        property: "opacity"
                        from: 0.3
                        to: 1.0
                        duration: 800
                    }
                }
            }
        }

        // Email logs section
        Rectangle {
            id: logsSection
            anchors {
                top: activityRect.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 10
            }
            color: "white"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 1

            Rectangle {
                id: logsTitleRect
                height: 40
                width: parent.width
                color: "#F8F8F8"
                radius: 8
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Text {
                    text: "Email Activity Log"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#333333"
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 15
                    }
                }

                CustomButton {
                    text: "Clear Logs"
                    height: 25
                    width: 80
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 15
                    }
                    onClicked: {
                        if (emailController && emailController.emailLogs) {
                            emailController.emailLogs.clearLogs()
                        }
                    }
                }
            }

            ListView {
                boundsBehavior: Flickable.StopAtBounds
                id: emailLogsListView
                clip: true
                anchors {
                    top: logsTitleRect.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 1
                }

                // ScrollBar.vertical: ScrollBar {
                //     active: true
                //     policy: ScrollBar.AlwaysOn
                // }

                // ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    active: true
                    policy: ScrollBar.AlwaysOn
                    width: 6
                    parent: emailLogsListView
                    anchors.right: emailLogsListView.right
                    anchors.top: emailLogsListView.top
                    anchors.bottom: emailLogsListView.bottom

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

                model: emailController ? emailController.emailLogs : null

                delegate: Item {
                    width: emailLogsListView.width
                    height: 60

                    Rectangle {
                        id: logItemRect
                        width: parent.width
                        height: parent.height
                        color: "transparent"

                        Row {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 15
                            }
                            spacing: 15

                            // Status indicator
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: {
                                    switch(model.status) {
                                        case "Sent": return "#4CAF50"
                                        case "Failed": return "#F44336"
                                        case "Pending": return "#FF9800"
                                        default: return "#CCCCCC"
                                    }
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: model.recipient + " - " + model.subject
                                    font.pixelSize: 13
                                    color: "#333333"
                                    elide: Text.ElideRight
                                    width: emailLogsListView.width - 100
                                }

                                Row {
                                    spacing: 10
                                    Text {
                                        text: model.timestamp
                                        font.pixelSize: 11
                                        color: "#666666"
                                    }
                                    Text {
                                        text: "(" + model.type + ")"
                                        font.pixelSize: 11
                                        color: "#888888"
                                    }
                                    Text {
                                        text: model.status
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: {
                                            switch(model.status) {
                                                case "Sent": return "#4CAF50"
                                                case "Failed": return "#F44336"
                                                case "Pending": return "#FF9800"
                                                default: return "#CCCCCC"
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: model.error
                                    font.pixelSize: 10
                                    color: "#F44336"
                                    visible: model.error !== ""
                                    elide: Text.ElideRight
                                    width: emailLogsListView.width - 100
                                }
                            }
                        }

                        Rectangle {
                            id: separator
                            width: parent.width * 0.95
                            height: 1
                            color: "#E0E0E0"
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    text: "No email activity yet"
                    font.pixelSize: 14
                    color: "#CCCCCC"
                    visible: emailLogsListView.count === 0
                }
            }
        }
    }

    // SMTP Configuration Popup
    Popup {
        id: smtpConfigPopup
        width: 450
        height: 500
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "white"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 2
        }

        Rectangle {
            anchors.fill: parent
            color: "white"
            radius: 8

            Rectangle {
                id: configTitleRect
                height: 50
                width: parent.width
                color: "#F8F8F8"
                radius: 8
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Text {
                    text: "SMTP Configuration"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333333"
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 20
                    }
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: "#DDDDDD"
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 15
                    }

                    Text {
                        text: "×"
                        font.pixelSize: 18
                        color: "#666666"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: smtpConfigPopup.close()
                        onEntered: parent.color = "#CCCCCC"
                        onExited: parent.color = "#DDDDDD"
                    }
                }
            }

            Flickable {
                boundsBehavior: Flickable.StopAtBounds
                anchors {
                    top: configTitleRect.bottom
                    left: parent.left
                    right: parent.right
                    bottom: configButtonsRect.top
                    margins: 20
                }
                contentHeight: configForm.height
                clip: true

                Column {
                    id: configForm
                    width: parent.width
                    spacing: 15

                    // Server settings
                    Rectangle {
                        width: parent.width
                        height: serverColumn.height + 20
                        color: "#F8F8F8"
                        radius: 4
                        border.color: "#E0E0E0"
                        border.width: 1

                        Column {
                            id: serverColumn
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 15
                            }
                            spacing: 10

                            Text {
                                text: "Server Settings"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#333333"
                            }

                            Row {
                                width: parent.width
                                spacing: 10

                                Column {
                                    width: parent.width * 0.7 - 5
                                    Text {
                                        text: "SMTP Server:"
                                        font.pixelSize: 12
                                        color: "#666666"
                                    }
                                    TextField {
                                        id: serverField
                                        width: parent.width
                                        height: 35
                                        placeholderText: "smtp.gmail.com"
                                        text: emailController ? emailController.smtpServer : ""
                                        onTextChanged: {
                                            if (emailController) {
                                                emailController.smtpServer = text
                                            }
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width * 0.3 - 5
                                    Text {
                                        text: "Port:"
                                        font.pixelSize: 12
                                        color: "#666666"
                                    }
                                    SpinBox {
                                        id: portField
                                        width: parent.width
                                        height: 35
                                        from: 1
                                        to: 65535
                                        value: emailController ? emailController.smtpPort : 587
                                        onValueChanged: {
                                            if (emailController) {
                                                emailController.smtpPort = value
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Authentication settings
                    Rectangle {
                        width: parent.width
                        height: authColumn.height + 20
                        color: "#F8F8F8"
                        radius: 4
                        border.color: "#E0E0E0"
                        border.width: 1

                        Column {
                            id: authColumn
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 15
                            }
                            spacing: 10

                            Text {
                                text: "Authentication"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#333333"
                            }

                            Column {
                                width: parent.width
                                Text {
                                    text: "Username/Email:"
                                    font.pixelSize: 12
                                    color: "#666666"
                                }
                                TextField {
                                    id: usernameField
                                    width: parent.width
                                    height: 35
                                    placeholderText: "your.email@gmail.com"

                                    Component.onCompleted: {
                                        if (emailController) {
                                            text = emailController.smtpUsername
                                        }
                                    }

                                    onTextChanged: {
                                        if (emailController) {
                                            emailController.smtpUsername = text
                                        }
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                Text {
                                    text: "Password:"
                                    font.pixelSize: 12
                                    color: "#666666"
                                }
                                TextField {
                                    id: passwordField
                                    width: parent.width
                                    height: 35
                                    placeholderText: "App password recommended"
                                    echoMode: TextInput.Password

                                    Component.onCompleted: {
                                        if (emailController) {
                                            text = emailController.smtpPassword
                                        }
                                    }

                                    onTextChanged: {
                                        if (emailController) {
                                            emailController.smtpPassword = text
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Security settings
                    Rectangle {
                        width: parent.width
                        height: securityColumn.height + 20
                        color: "#F8F8F8"
                        radius: 4
                        border.color: "#E0E0E0"
                        border.width: 1

                        Column {
                            id: securityColumn
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 15
                            }
                            spacing: 10

                            Text {
                                text: "Security"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#333333"
                            }

                            CheckBox {
                                id: sslCheckBox
                                text: "Use SSL"

                                Component.onCompleted: {
                                    if (emailController) {
                                        checked = emailController.useSSL
                                    }
                                }

                                onCheckedChanged: {
                                    if (emailController) {
                                        emailController.useSSL = checked
                                    }
                                }
                            }

                            CheckBox {
                                id: tlsCheckBox
                                text: "Use TLS (Recommended)"

                                Component.onCompleted: {
                                    if (emailController) {
                                        checked = emailController.useTLS
                                    }
                                }

                                onCheckedChanged: {
                                    if (emailController) {
                                        emailController.useTLS = checked
                                    }
                                }
                            }
                        }
                    }

                    // Info section
                    Rectangle {
                        width: parent.width
                        height: infoText.contentHeight + 20
                        color: "#E3F2FD"
                        radius: 4
                        border.color: "#BBDEFB"
                        border.width: 1

                        Text {
                            id: infoText
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 15
                            }
                            text: "Common SMTP Settings:\n" +
                                  "• Gmail: smtp.gmail.com:587 (TLS)\n" +
                                  "• Outlook: smtp-mail.outlook.com:587 (TLS)\n" +
                                  "• Yahoo: smtp.mail.yahoo.com:587 (TLS)\n\n" +
                                  "For Gmail, use App Password instead of regular password."
                            font.pixelSize: 11
                            color: "#1976D2"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                id: configButtonsRect
                height: 60
                width: parent.width
                color: "#F8F8F8"
                radius: 8
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }

                Row {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 20
                    }
                    spacing: 10

                    CustomButton {
                        text: "Test Configuration"
                        height: 35
                        width: 130
                        enabled: emailController && emailController.smtpServer !== "" && emailController.smtpUsername !== ""
                        onClicked: {
                            testEmailPopup.open()
                        }
                    }

                    CustomButton {
                        text: "Save"
                        height: 35
                        width: 80
                        onClicked: {
                            if (emailController) {
                                emailController.saveConfiguration()
                                smtpConfigPopup.close()
                            }
                        }
                    }

                    CustomButton {
                        text: "Cancel"
                        height: 35
                        width: 80
                        onClicked: {
                            if (emailController) {
                                emailController.loadConfiguration()
                            }
                            smtpConfigPopup.close()
                        }
                    }
                }
            }
        }
    }

    // Test Email Popup
    Popup {
        id: testEmailPopup
        width: 400
        height: 300
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "white"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 2
        }

        Rectangle {
            anchors.fill: parent
            color: "white"
            radius: 8

            Rectangle {
                id: testTitleRect
                height: 50
                width: parent.width
                color: "#F8F8F8"
                radius: 8
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Text {
                    text: "Send Test Email"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333333"
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 20
                    }
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: "#DDDDDD"
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 15
                    }

                    Text {
                        text: "×"
                        font.pixelSize: 18
                        color: "#666666"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: testEmailPopup.close()
                        onEntered: parent.color = "#CCCCCC"
                        onExited: parent.color = "#DDDDDD"
                    }
                }
            }

            Column {
                anchors {
                    top: testTitleRect.bottom
                    left: parent.left
                    right: parent.right
                    bottom: testButtonsRect.top
                    margins: 20
                }
                spacing: 15

                Text {
                    text: "Enter an email address to send a test email:"
                    font.pixelSize: 12
                    color: "#666666"
                }

                TextField {
                    id: testEmailField
                    width: parent.width
                    height: 35
                    placeholderText: "test@example.com"
                    validator: RegularExpressionValidator {
                        regularExpression: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
                    }
                }

                Text {
                    text: "This will send a test email to verify your SMTP configuration is working correctly."
                    font.pixelSize: 11
                    color: "#888888"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            Rectangle {
                id: testButtonsRect
                height: 60
                width: parent.width
                color: "#F8F8F8"
                radius: 8
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }

                Row {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 20
                    }
                    spacing: 10

                    CustomButton {
                        text: "Send Test"
                        height: 35
                        width: 90
                        enabled: testEmailField.text !== "" && testEmailField.acceptableInput
                        onClicked: {
                            if (emailController) {
                                emailController.sendTestEmail(testEmailField.text)
                                testEmailPopup.close()
                                testEmailField.text = ""
                            }
                        }
                    }

                    CustomButton {
                        text: "Cancel"
                        height: 35
                        width: 80
                        onClicked: {
                            testEmailField.text = ""
                            testEmailPopup.close()
                        }
                    }
                }
            }
        }
    }

    // Connections for notifications
    Connections {
        target: emailController
        function onNotificationSent(message) {
            // You can show a toast notification here
            console.log("Notification:", message)
        }
        function onErrorOccured(error) { //spelling error here no double r in the C++ code, have to go with it :)
            // You can show an error dialog here
            console.log("Error:", error)
        }
    }
}
