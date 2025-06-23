import QtQuick
import QtQuick.Controls

Rectangle {
    id: backupScreen
    visible: true
    width: parent.width
    height: parent.height
    color: "#FBFBFB"

    signal closeClicked()

    MouseArea {
        id: backupScreenMA
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
            leftMargin: 10
            top: parent.top
            topMargin: 10
        }

        Rectangle {
            id: backBtnRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"

            Image {
                id: back
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/backArrow.png"
            }
        }

        MouseArea {
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
                backupScreen.closeClicked()
            }
        }
    }

    // Left sidebar for backup options
    Rectangle {
        id: sidebarContainer
        color: "#FBFBFB"
        width: parent.width * 0.25
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

        // Backup Types Section
        Rectangle {
            id: backupTypesLabelRect
            height: 40
            width: sidebarContainer.btnWidth
            anchors {
                top: parent.top
                topMargin: 16
                left: parent.left
                leftMargin: 5
            }

            color: "transparent"
            radius: 4

            Label {
                id: backupTypesTxt
                width: parent.width
                anchors {
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                text: "Backup Types"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                elide: "ElideRight"
                maximumLineCount: 1
            }
        }

        // Local Backup Card
        Rectangle {
            id: localBackupCard
            width: sidebarContainer.btnWidth
            height: 80
            color: "#F8F9FA"
            border.color: "#DEE2E6"
            border.width: 1
            radius: 8
            anchors {
                top: backupTypesLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 10
            }

            property bool isSelected: true

            Rectangle {
                id: localBackupIndicator
                width: 4
                height: parent.height - 10
                color: localBackupCard.isSelected ? "#007BFF" : "transparent"
                radius: 2
                anchors {
                    left: parent.left
                    leftMargin: 2
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors {
                    left: localBackupIndicator.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Image {
                    id: localBackupIcon
                    source: "assets/localBackup.png"
                    width: 32
                    height: 32
                }

                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Local Backup"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#212529"
                    }

                    Text {
                        text: "Save to local drive"
                        font.pixelSize: 11
                        color: "#6C757D"
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if (!parent.isSelected) {
                        parent.color = "#E9ECEF"
                    }
                }
                onExited: {
                    if (!parent.isSelected) {
                        parent.color = "#F8F9FA"
                    }
                }
                onClicked: {
                    localBackupCard.isSelected = true
                    cloudBackupCard.isSelected = false
                    localBackupCard.color = "#E3F2FD"
                    cloudBackupCard.color = "#F8F9FA"
                }
            }
        }

        // Cloud Backup Card
        Rectangle {
            id: cloudBackupCard
            width: sidebarContainer.btnWidth
            height: 80
            color: "#F8F9FA"
            border.color: "#DEE2E6"
            border.width: 1
            radius: 8
            anchors {
                top: localBackupCard.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 10
            }

            property bool isSelected: false

            Rectangle {
                id: cloudBackupIndicator
                width: 4
                height: parent.height - 10
                color: cloudBackupCard.isSelected ? "#007BFF" : "transparent"
                radius: 2
                anchors {
                    left: parent.left
                    leftMargin: 2
                    verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors {
                    left: cloudBackupIndicator.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10

                Image {
                    id: cloudBackupIcon
                    source: "assets/cloudBackup.png"
                    width: 32
                    height: 32
                }

                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Cloud Backup"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#212529"
                    }

                    Text {
                        text: "Save to cloud storage"
                        font.pixelSize: 11
                        color: "#6C757D"
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if (!parent.isSelected) {
                        parent.color = "#E9ECEF"
                    }
                }
                onExited: {
                    if (!parent.isSelected) {
                        parent.color = "#F8F9FA"
                    }
                }
                onClicked: {
                    cloudBackupCard.isSelected = true
                    localBackupCard.isSelected = false
                    cloudBackupCard.color = "#E3F2FD"
                    localBackupCard.color = "#F8F9FA"
                }
            }
        }

        // Quick Actions Section
        Rectangle {
            id: actionsLabelRect
            height: 40
            width: sidebarContainer.btnWidth
            anchors {
                top: cloudBackupCard.bottom
                topMargin: 20
                left: parent.left
                leftMargin: 5
            }

            color: "transparent"
            radius: 4

            Label {
                id: quickActionsTxt
                width: parent.width
                anchors {
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                text: "Quick Actions"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                elide: "ElideRight"
                maximumLineCount: 1
            }
        }

        // Quick Action Buttons
        Rectangle {
            id: restoreBtn
            width: sidebarContainer.btnWidth
            height: 45
            color: "transparent"
            border.color: "#28A745"
            border.width: 1
            radius: 6
            anchors {
                top: actionsLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 10
            }

            Text {
                text: "Restore Backup"
                color: "#28A745"
                font.pixelSize: 13
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    parent.color = "#28A745"
                    parent.children[0].color = "white"
                }
                onExited: {
                    parent.color = "transparent"
                    parent.children[0].color = "#28A745"
                }
                onClicked: {
                    // Handle restore action
                }
            }
        }

        Rectangle {
            id: scheduleBtn
            width: sidebarContainer.btnWidth
            height: 45
            color: "transparent"
            border.color: "#17A2B8"
            border.width: 1
            radius: 6
            anchors {
                top: restoreBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 8
            }

            Text {
                text: "Schedule Backup"
                color: "#17A2B8"
                font.pixelSize: 13
                font.bold: true
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    parent.color = "#17A2B8"
                    parent.children[0].color = "white"
                }
                onExited: {
                    parent.color = "transparent"
                    parent.children[0].color = "#17A2B8"
                }
                onClicked: {
                    // Handle schedule action
                }
            }
        }
    }

    // Main content area
    Rectangle {
        id: mainContentArea
        color: "transparent"
        anchors {
            left: sidebarContainer.right
            leftMargin: 20
            top: backRect.bottom
            topMargin: 10
            right: parent.right
            rightMargin: 10
            bottom: parent.bottom
            bottomMargin: 10
        }

        // Page Title
        Rectangle {
            id: pageTitleRect
            height: 40
            width: pageTitle.width
            color: "transparent"
            anchors {
                top: parent.top
                topMargin: 10
                left: parent.left
            }

            Text {
                id: pageTitle
                text: "System Backup"
                font.pointSize: 16
                font.bold: true
                color: "#878585"
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        // Status Cards Row
        Row {
            id: statusCardsRow
            spacing: 15
            anchors {
                top: pageTitleRect.bottom
                topMargin: 20
                left: parent.left
            }

            // Last Backup Status Card
            Rectangle {
                id: lastBackupCard
                width: 200
                height: 80
                color: "#F8F9FA"
                border.color: "#DEE2E6"
                border.width: 1
                radius: 8

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 5

                    Text {
                        text: "Last Backup"
                        font.pixelSize: 12
                        color: "#6C757D"
                        font.bold: true
                    }

                    Text {
                        text: "2 hours ago"
                        font.pixelSize: 14
                        color: "#28A745"
                        font.bold: true
                    }

                    Text {
                        text: "Complete • 2.3 GB"
                        font.pixelSize: 10
                        color: "#6C757D"
                    }
                }

                Rectangle {
                    width: 8
                    height: 8
                    color: "#28A745"
                    radius: 4
                    anchors {
                        right: parent.right
                        rightMargin: 15
                        top: parent.top
                        topMargin: 15
                    }
                }
            }

            // Storage Space Card
            Rectangle {
                id: storageCard
                width: 200
                height: 80
                color: "#F8F9FA"
                border.color: "#DEE2E6"
                border.width: 1
                radius: 8

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 5

                    Text {
                        text: "Available Space"
                        font.pixelSize: 12
                        color: "#6C757D"
                        font.bold: true
                    }

                    Text {
                        text: "45.2 GB"
                        font.pixelSize: 14
                        color: "#007BFF"
                        font.bold: true
                    }

                    Text {
                        text: "of 100 GB total"
                        font.pixelSize: 10
                        color: "#6C757D"
                    }
                }

                Rectangle {
                    width: 40
                    height: 4
                    color: "#E9ECEF"
                    radius: 2
                    anchors {
                        right: parent.right
                        rightMargin: 15
                        bottom: parent.bottom
                        bottomMargin: 15
                    }

                    Rectangle {
                        width: parent.width * 0.45
                        height: parent.height
                        color: "#007BFF"
                        radius: 2
                    }
                }
            }

            // Next Backup Card
            Rectangle {
                id: nextBackupCard
                width: 200
                height: 80
                color: "#F8F9FA"
                border.color: "#DEE2E6"
                border.width: 1
                radius: 8

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 5

                    Text {
                        text: "Next Scheduled"
                        font.pixelSize: 12
                        color: "#6C757D"
                        font.bold: true
                    }

                    Text {
                        text: "Tonight 2:00 AM"
                        font.pixelSize: 14
                        color: "#FD7E14"
                        font.bold: true
                    }

                    Text {
                        text: "Daily automatic"
                        font.pixelSize: 10
                        color: "#6C757D"
                    }
                }

                Rectangle {
                    width: 8
                    height: 8
                    color: "#FD7E14"
                    radius: 4
                    anchors {
                        right: parent.right
                        rightMargin: 15
                        top: parent.top
                        topMargin: 15
                    }
                }
            }
        }

        // Backup Configuration Section
        Rectangle {
            id: configSection
            color: "white"
            border.color: "#DEE2E6"
            border.width: 1
            radius: 8
            anchors {
                top: statusCardsRow.bottom
                topMargin: 25
                left: parent.left
                right: parent.right
                bottom: actionButtonsRow.top
                bottomMargin: 25
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                clip: true

                Column {
                    width: parent.width
                    spacing: 25

                    // What to Backup Section
                    Column {
                        width: parent.width
                        spacing: 10

                        Text {
                            text: "What to backup"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#212529"
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: fullSystemCheck
                                    checked: true
                                    text: "Complete System Backup"
                                }
                                Text {
                                    text: "• Database, files, and configurations"
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: databaseOnlyCheck
                                    text: "Database Only"
                                }
                                Text {
                                    text: "• Books, patrons, transactions"
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: mediaFilesCheck
                                    text: "Media Files"
                                }
                                Text {
                                    text: "• Book covers, documents, attachments"
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: configOnlyCheck
                                    text: "Configuration Only"
                                }
                                Text {
                                    text: "• System settings and preferences"
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Backup Location Section
                    Column {
                        width: parent.width
                        spacing: 10

                        Text {
                            text: "Backup location"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#212529"
                        }

                        Rectangle {
                            width: parent.width
                            height: 45
                            color: "#F8F9FA"
                            border.color: "#DEE2E6"
                            border.width: 1
                            radius: 6

                            Row {
                                anchors {
                                    left: parent.left
                                    leftMargin: 15
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 10

                                Image {
                                    source: localBackupCard.isSelected ? "assets/folder.png" : "assets/cloud.png"
                                    width: 20
                                    height: 20
                                }

                                Text {
                                    text: localBackupCard.isSelected ? "C:\\ILMS\\Backups\\" : "Google Drive - ILMS Backups"
                                    font.pixelSize: 12
                                    color: "#495057"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 30
                                color: "transparent"
                                border.color: "#6C757D"
                                border.width: 1
                                radius: 4
                                anchors {
                                    right: parent.right
                                    rightMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Browse"
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onEntered: {
                                        parent.color = "#6C757D"
                                        parent.children[0].color = "white"
                                    }
                                    onExited: {
                                        parent.color = "transparent"
                                        parent.children[0].color = "#6C757D"
                                    }
                                    onClicked: {
                                        // Handle browse action
                                    }
                                }
                            }
                        }
                    }

                    // Encryption Section
                    Column {
                        width: parent.width
                        spacing: 10

                        Row {
                            spacing: 10
                            Switch {
                                id: encryptionSwitch
                                checked: true
                            }
                            Text {
                                text: "Encrypt backup files"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#212529"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: "Recommended for sensitive data protection"
                            font.pixelSize: 11
                            color: "#6C757D"
                            leftPadding: 50
                            visible: encryptionSwitch.checked
                        }
                    }
                }
            }
        }

        // Action Buttons Row
        Row {
            id: actionButtonsRow
            spacing: 15
            anchors {
                bottom: parent.bottom
                bottomMargin: 20
                horizontalCenter: parent.horizontalCenter
            }

            // Backup Now Button (Primary)
            Rectangle {
                id: backupNowBtn
                width: 140
                height: 45
                color: "#007BFF"
                radius: 6

                Text {
                    text: "Backup Now"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        parent.color = "#0056B3"
                    }
                    onExited: {
                        parent.color = "#007BFF"
                    }
                    onClicked: {
                        // Handle backup now action
                    }
                }
            }

            // Test Backup Button
            Rectangle {
                id: testBackupBtn
                width: 120
                height: 45
                color: "transparent"
                border.color: "#6C757D"
                border.width: 1
                radius: 6

                Text {
                    text: "Test Backup"
                    color: "#6C757D"
                    font.pixelSize: 14
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        parent.color = "#6C757D"
                        parent.children[0].color = "white"
                    }
                    onExited: {
                        parent.color = "transparent"
                        parent.children[0].color = "#6C757D"
                    }
                    onClicked: {
                        // Handle test backup action
                    }
                }
            }

            // View History Button
            Rectangle {
                id: historyBtn
                width: 120
                height: 45
                color: "transparent"
                border.color: "#6C757D"
                border.width: 1
                radius: 6

                Text {
                    text: "View History"
                    color: "#6C757D"
                    font.pixelSize: 14
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        parent.color = "#6C757D"
                        parent.children[0].color = "white"
                    }
                    onExited: {
                        parent.color = "transparent"
                        parent.children[0].color = "#6C757D"
                    }
                    onClicked: {
                        // Handle view history action
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // Initialize backup screen
        localBackupCard.color = "#E3F2FD"
    }
}
