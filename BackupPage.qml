import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import com.backupManager
import QtCore
import com.libro.settings 1.0

Rectangle {
    id: backupScreen
    visible: true
    width: parent.width
    height: parent.height
    color: "#FBFBFB"

    signal closeClicked()

    // BackupManager instance is a qml Singleton (check main.cpp)
    property var backupManager: BackupManagerInstance /*BackupManager {
        id: backupManagerInstance
    }*/

    // Current backup path
    property string currentBackupPath: backupManager.defaultBackupPath

    MouseArea {
        id: backupScreenMA
        anchors.fill: parent
    }

    //Settings
    Settings {
        id: backupSettings

        category: "BackupPreferences"
        property bool preferLocalBackup: true
        property int cloudProvider: 0 // Default to Google Drive
        property string backupPath: backupManager.defaultBackupPath
        property bool enableEncryption: true
        property bool enableScheduledBackup: false
        property int backupFrequencyIndex: 2 // Default to Daily

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
            enabled: !(backupManager.currentStatus === BackupManagerInstance.InProgress)
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
                    source: "assets/folder.png"
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
                    backupSettings.preferLocalBackup = true
                    currentBackupPath = backupManager.defaultBackupPath //reset the backupPath text to the local path
                    updateBackupPath()
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
                    source: "assets/cloud.png"
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
                    backupSettings.preferLocalBackup = false
                    currentBackupPath = getCloudProviderName(cloudProviderDialog.provider)
                    updateBackupPath()
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
                }                onClicked: {
                    restoreFileDialog.open()
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
                }                onClicked: {
                    scheduleDialog.open()
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
                        id: lastBackupTime
                        text: getLastBackupText()
                        font.pixelSize: 14
                        color: getLastBackupColor()
                        font.bold: true
                    }

                    Text {
                        id: lastBackupDetails
                        text: getLastBackupDetails()
                        font.pixelSize: 10
                        color: "#6C757D"
                    }
                }
                Rectangle {
                    id: lastBackupIndicator
                    width: 8
                    height: 8
                    color: getLastBackupIndicatorColor()
                    radius: 4
                    anchors {
                        right: parent.right
                        rightMargin: 15
                        top: parent.top
                        topMargin: 15
                    }
                }

                Component.onCompleted: {
                    getLastBackupText()
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
                    }                    Text {
                        text: formatBytes(getAvailableSpace())
                        font.pixelSize: 14
                        color: "#007BFF"
                        font.bold: true
                    }

                    Text {
                        text: "of " + formatBytes(getTotalSpace()) + " total"
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
                        width: parent.width * (getAvailableSpace() / getTotalSpace())
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
                    }                    Text {
                        text: getNextScheduledText()
                        font.pixelSize: 14
                        color: "#FD7E14"
                        font.bold: true
                    }

                    Text {
                        text: getScheduleDescription()
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
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
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
                            text: "Choose cloud provider"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#212529"
                        }

                        ButtonGroup{
                            id: providerCheckButtons
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: googleDriveCheck
                                    checked: true
                                    text: "Google Drive"
                                    enabled: cloudBackupCard.isSelected
                                    ButtonGroup.group: providerCheckButtons
                                    onClicked: {
                                        cloudProviderDialog.provider = 0
                                    }
                                }
                                Text {
                                    text: "• Sync and store files with your Google account."
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: amazonS3Check
                                    text: "Amazon S3"
                                    enabled: cloudBackupCard.isSelected
                                    ButtonGroup.group: providerCheckButtons
                                    onClicked: {
                                        cloudProviderDialog.provider = 1
                                    }
                                }
                                Text {
                                    text: "• Scalable, reliable cloud storage from AWS."
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: dropBoxCheck
                                    text: "Drop Box"
                                    enabled: cloudBackupCard.isSelected
                                    ButtonGroup.group: providerCheckButtons
                                    onClicked: {
                                        cloudProviderDialog.provider = 2
                                    }
                                }
                                Text {
                                    text: "• Simple file storage and sharing with auto-sync."
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: oneDriveCheck
                                    text: "One Drive"
                                    enabled: cloudBackupCard.isSelected
                                    ButtonGroup.group: providerCheckButtons
                                    onClicked: {
                                        cloudProviderDialog.provider = 3
                                    }
                                }
                                Text {
                                    text: "• Microsoft's cloud storage linked to your Microsoft account."
                                    font.pixelSize: 11
                                    color: "#6C757D"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                spacing: 10
                                CheckBox {
                                    id: genericCheck
                                    text: "Generic Provider"
                                    enabled: cloudBackupCard.isSelected
                                    ButtonGroup.group: providerCheckButtons
                                    onClicked: {
                                        cloudProviderDialog.provider = 4
                                    }
                                }
                                Text {
                                    text: "• Use any other custom or self-hosted cloud service."
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
                                    id: locationPathText
                                    text: currentBackupPath
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
                                        if (localBackupCard.isSelected) {
                                            folderDialog.open()
                                        } else {
                                            cloudProviderDialog.open()
                                        }
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
                        performBackup()
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
                    }                    onClicked: {
                        testBackup()
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
                        historyDialog.open()
                    }
                }
            }
        }
    }


    Rectangle {
        id: navigationRect
        width: parent.width *0.90
        height: 80
        radius: 8
        border.color: "lightgray"
        color: "white"
        opacity: 0.9
        visible: backupManager.currentStatus === BackupManagerInstance.InProgress

        anchors{
            bottom: parent.bottom
            bottomMargin: 10
            horizontalCenter: parent.horizontalCenter
        }

        // Progress Bar for backup/restore operations
        ProgressBar {
            id: backupProgress
            width: parent.width * 0.8
            height: 6
            anchors {
                // bottom: parent.bottom
                // bottomMargin: 20
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            value: backupManager.progressPercentage
            from: 0
            to: 100
            visible: backupManager.currentStatus === BackupManagerInstance.InProgress

            Text {
                anchors {
                    bottom: parent.top
                    bottomMargin: 5
                    horizontalCenter: parent.horizontalCenter
                }
                text: Math.round(backupProgress.value) + "% - " + backupManager.currentOperation
                color: "#8E8E8E"
                visible: backupProgress.visible
            }
        }

        RoundButton{
            id: backupCancelButton
            anchors {
                right: parent.right
                rightMargin: 10
                bottom: parent.bottom
                bottomMargin: 10
            }

            text: "Cancel"

            onClicked: {
                BackupManagerInstance.cancelCurrentBackup()
                BackupManagerInstance.cancelCurrentBackup()
            }
        }
    }

    // Progress Bar for backup/restore operations
    // ProgressBar {
    //     id: backupProgress
    //     width: parent.width * 0.8
    //     height: 6
    //     anchors {
    //         bottom: parent.bottom
    //         bottomMargin: 20
    //         horizontalCenter: parent.horizontalCenter
    //     }
    //     value: backupManager.progressPercentage
    //     from: 0
    //     to: 100
    //     visible: backupManager.currentStatus === BackupManager.InProgress

    //     Text {
    //         anchors {
    //             bottom: parent.top
    //             bottomMargin: 5
    //             horizontalCenter: parent.horizontalCenter
    //         }
    //         text: Math.round(backupProgress.value) + "% - " + backupManager.currentOperation
    //         color: "#8E8E8E"
    //         visible: backupProgress.visible
    //     }
    // }

    // Error Dialog
    Dialog {
        id: errorDialog
        title: "Error!"
        property alias text: errorLabel.text
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Text {
            id: errorLabel
            color: "#8E8E8E"
        }
    }

    // Success Dialog
    Dialog {
        id: successDialog
        title: "Success!"
        property alias text: successLabel.text
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Text {
            id: successLabel
            color: "#28A745"
        }
    }

    // Folder Dialog for Local Backup
    FolderDialog {
        id: folderDialog
        title: "Select Backup Location"
        currentFolder: "file:///" + currentBackupPath

        onAccepted: {
            currentBackupPath = selectedFolder.toString().replace("file:///", "")
            backupManager.setDefaultBackupPath(currentBackupPath)
            backupSettings.backupPath = currentBackupPath
            updateBackupPath()
        }
    }

    // File Dialog for Restore
    FileDialog {
        id: restoreFileDialog
        title: "Select Backup File to Restore"
        nameFilters: ["Database Backup files (*.db *.zip)", "All files (*)"]
        fileMode: FileDialog.OpenFile

        onAccepted: {
            var filePath = selectedFile.toString().replace("file:///", "")
            confirmRestoreDialog.backupFilePath = filePath
            confirmRestoreDialog.open()
        }
    }

    // Cloud Provider Selection Dialog
    Dialog {
        id: cloudProviderDialog
        title: "Select Cloud Provider"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent

        property var provider: null

        Column {
            spacing: 10
            width: 300

            Text {
                text: "Choose your cloud storage provider:"
                font.bold: true
                color: "#212529"
            }

            ButtonGroup {
                id: cloudProviderGroup
            }

            RadioButton {
                id: googleDriveRadio
                text: "Google Drive"
                // checked: true
                ButtonGroup.group: cloudProviderGroup
                onClicked: {
                    cloudProviderDialog.provider = 0
                }
            }

            RadioButton {
                id: dropboxRadio
                text: "Dropbox"
                ButtonGroup.group: cloudProviderGroup
                onClicked: {
                    cloudProviderDialog.provider = 2
                }
            }

            RadioButton {
                id: oneDriveRadio
                text: "OneDrive"
                ButtonGroup.group: cloudProviderGroup
                onClicked: {
                    cloudProviderDialog.provider = 3
                }
            }

            RadioButton {
                id: amazonS3Radio
                text: "Amazon S3"
                ButtonGroup.group: cloudProviderGroup
                onClicked: {
                    cloudProviderDialog.provider = 1
                }
            }

            RadioButton {
                id: genericRadio
                text: "Generic provider"
                ButtonGroup.group: cloudProviderGroup
                onClicked: {
                    cloudProviderDialog.provider = 4
                }
            }
        }

        onAccepted: {
            // var selectedProvider = BackupManagerInstance.GoogleDrive
            // if (dropboxRadio.checked)
            //     selectedProvider = BackupManagerInstance.DropBox
            // else if (oneDriveRadio.checked)
            //     selectedProvider = BackupManagerInstance.OneDrive
            // else if (amazonS3Radio.checked)
            //     selectedProvider = BackupManagerInstance.AmazonS3
            // else if (genericRadio.checked)
            //     selectedProvider = BackupManagerInstance.Generic

            console.log("Provider: ", cloudProviderDialog.provider)
            backupSettings.cloudProvider = cloudProviderDialog.provider
            BackupManagerInstance.openCloudDialog(cloudProviderDialog.provider, BackupManagerInstance.defaultBackupPath)
            currentBackupPath = getCloudProviderName(cloudProviderDialog.provider)
            updateBackupPath()
        }
    }

    // Schedule Backup Dialog
    Dialog {
        id: scheduleDialog
        title: "Schedule Automatic Backups"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent

        Column {
            spacing: 15
            width: 350

            Row {
                spacing: 10
                Switch {
                    id: enableScheduleSwitch
                    // checked: SettingsManager.autoBackupEnabled //backupManager.scheduledBackupEnabled
                    Binding {
                        target: enableScheduleSwitch
                        property: "checked"
                        value: SettingsManager.autoBackupEnabled
                    }
                    onToggled: {
                        SettingsManager.autoBackupEnabled = checked
                    }
                }
                Text {
                    text: "Enable automatic backups"
                    font.bold: true
                    color: "#212529"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Column {
                width: parent.width
                spacing: 10
                enabled: enableScheduleSwitch.checked

                Text {
                    text: "Backup frequency:"
                    color: "#6C757D"
                }

                ComboBox {
                    id: frequencyCombo
                    width: parent.width
                    model: ["Every 6 hours", "Every 12 hours", "Daily", "Every 2 days", "Weekly"]
                    currentIndex: getFrequencyIndex()

                    onCurrentIndexChanged: {
                        var hours = [6, 12, 24, 48, 168][currentIndex]
                        backupManager.setBackupFrequencyHours(hours)
                    }
                }
            }
        }

        onAccepted: {
            backupManager.setScheduledBackupEnabled(enableScheduleSwitch.checked)
            backupSettings.enableScheduledBackup = enableScheduleSwitch.checked
            backupSettings.backupFrequencyIndex = frequencyCombo.currentIndex
        }
    }

    // Restore Confirmation Dialog
    Dialog {
        id: confirmRestoreDialog
        title: "Confirm Database Restore"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        anchors.centerIn: parent

        property string backupFilePath: ""

        Column {
            spacing: 10
            width: 400

            Text {
                text: "Are you sure you want to restore the database?"
                font.bold: true
                color: "#DC3545"
            }

            Text {
                text: "This will replace your current database with the backup. All current data will be lost."
                wrapMode: Text.Wrap
                width: parent.width
                color: "#6C757D"
            }

            Text {
                text: "Backup file: " + confirmRestoreDialog.backupFilePath
                wrapMode: Text.Wrap
                width: parent.width
                color: "#495057"
                font.pixelSize: 12
            }
        }

        onAccepted: {
            backupManager.restoreBackup(backupFilePath)
        }
    }

    // History Dialog
    Dialog {
        id: historyDialog
        title: "Backup History"
        modal: true
        standardButtons: Dialog.Close
        anchors.centerIn: parent
        width: 700
        height: 500

        Rectangle {
            anchors.fill: parent
            color: "#FBFBFB"
            border.color: "#E0E0E0"
            border.width: 1
            radius: 8

            ScrollView {
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                anchors.fill: parent
                anchors.margins: 10
                clip: true


                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                ListView {
                    boundsBehavior: Flickable.StopAtBounds
                    id: historyListView
                    model: backupManager.getBackupHistory()
                    spacing: 5

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        active: true
                        policy: ScrollBar.AsNeeded
                        width: 10

                        contentItem: Rectangle {
                            implicitWidth: 10
                            radius: width / 2
                            color: vbar.pressed ? "#818181" : "#c2c2c2"  // Darker when pressed
                        }
                        background: Rectangle {
                            implicitWidth: 10
                            radius: width / 2
                            color: "#f0f0f0"  // Light background color
                        }
                    }

                    delegate: Rectangle {
                        width: historyListView.width
                        height: 80
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
                            spacing: 15

                            // Status indicator
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: getStatusColor(modelData.status)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 3
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: Qt.formatDateTime(modelData.timeStamp, "MMM dd, yyyy hh:mm AP")
                                    font.bold: true
                                    color: "#212529"
                                }

                                Text {
                                    text: getBackupTypeText(modelData.type) +
                                          (modelData.compressed ? " • Compressed" : "") +
                                          (modelData.encrypted ? " • Encrypted" : "")
                                    color: "#6C757D"
                                    font.pixelSize: 11
                                }

                                Text {
                                    text: getStatusText(modelData.status) +
                                          (modelData.fileSize > 0 ? " • " + formatBytes(modelData.fileSize) : "")
                                    color: getStatusColor(modelData.status)
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Action buttons
                        Row {
                            anchors {
                                right: parent.right
                                rightMargin: 15
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 10

                            Rectangle {
                                width: 60
                                height: 25
                                color: "transparent"
                                border.color: "#007BFF"
                                border.width: 1
                                radius: 4
                                visible: modelData.status === BackupManagerInstance.Completed

                                Text {
                                    text: "Restore"
                                    color: "#007BFF"
                                    font.pixelSize: 10
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        confirmRestoreDialog.backupFilePath = modelData.filePath
                                        confirmRestoreDialog.open()
                                        historyDialog.close()
                                    }
                                }
                            }

                            Rectangle {
                                width: 50
                                height: 25
                                color: "transparent"
                                border.color: "#DC3545"
                                border.width: 1
                                radius: 4

                                Text {
                                    text: "Delete"
                                    color: "#DC3545"
                                    font.pixelSize: 10
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        backupManager.deleteBackupRecord(modelData.backupId)
                                        historyListView.model = backupManager.getBackupHistory()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    // Helper Functions
    function performBackup() {
        let config = ({
                          type: localBackupCard.isSelected ? BackupManagerInstance.LocalBackup : BackupManagerInstance.CloudBackup,
                          destinationPath: currentBackupPath,
                          provider: localBackupCard.isSelected ? BackupManagerInstance.GoogleDrive : getCurrentCloudProvider(),
                          compressBackup: true,
                          encryptBackup: encryptionSwitch.checked,
                          encryptionPassword: ""
                      })

        backupManager.configureBackup(config)
    }

    function testBackup() {
        var estimatedSize = backupManager.estimateBackupSize()
        var availableSpace = backupManager.getAvailableSpace(backupManager.defaultBackupPath)

        if (estimatedSize > availableSpace) {
            errorDialog.title = "Insufficient Space"
            errorDialog.text = "Not enough space available for backup. Need " +
                    formatBytes(estimatedSize) + ", but only " +
                    formatBytes(availableSpace) + " available."
            errorDialog.open()
        } else {
            successDialog.title = "Backup Test"
            successDialog.text = "Backup test successful! Estimated backup size: " +
                    formatBytes(estimatedSize) + "\nAvailable space: " +
                    formatBytes(availableSpace)
            successDialog.open()
        }
    }


    function updateBackupPath() {
        if (localBackupCard.isSelected) {
            locationPathText.text = currentBackupPath
        } else {
            locationPathText.text = "Cloud Storage - " + currentBackupPath
        }
    }

    function getCurrentCloudProvider() {
        if (googleDriveRadio.checked) return BackupManagerInstance.GoogleDrive
        if (dropboxRadio.checked) return BackupManagerInstance.Dropbox
        if (oneDriveRadio.checked) return BackupManagerInstance.OneDrive
        if (amazonS3Radio.checked) return BackupManagerInstance.AmazonS3
        return BackupManagerInstance.GoogleDrive
    }

    function getCloudProviderName(provider) {
        switch (provider) {
        case BackupManagerInstance.GoogleDrive: return "Google Drive"
        case BackupManagerInstance.Dropbox: return "Dropbox"
        case BackupManagerInstance.OneDrive: return "OneDrive"
        case BackupManagerInstance.AmazonS3: return "Amazon S3"
        default: return "Cloud Storage"
        }
    }

    function getFrequencyIndex() {
        var hours = backupManager.backupFrequencyHours
        switch (hours) {
        case 6: return 0
        case 12: return 1
        case 24: return 2
        case 48: return 3
        case 168: return 4
        default: return 2
        }
    }

    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        var k = 1024
        var sizes = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
    }

    function getLastBackupText() {
        var history = backupManager.getBackupHistory()
        if (history.length === 0) return "Never"

        var lastBackup = history[0]
        var now = new Date()
        // var backupTime = lastBackup.timestamp
        var backupTime = new Date(lastBackup.timeStamp)

        console.log("Backup Time: ", backupTime)
        console.log("Now: ", now)
        console.log("Backup Time valid: ", !isNaN(backupTime.getTime()))
        console.log("Backup Time: ", backupTime)

        var diffMs = now - backupTime
        var diffHours = Math.floor(diffMs / (1000 * 60 * 60))

        if (diffHours < 1) return "Less than 1 hour ago"
        if (diffHours < 24) return diffHours + " hours ago"
        var diffDays = Math.floor(diffHours / 24)
        return diffDays + " days ago"
    }

    function getLastBackupColor() {
        var history = backupManager.getBackupHistory()
        if (history.length === 0) return "#6C757D"

        var lastBackup = history[0]
        return getStatusColor(lastBackup.status)
    }

    function getLastBackupDetails() {
        var history = backupManager.getBackupHistory()
        if (history.length === 0) return "No backups found"

        var lastBackup = history[0]
        return getStatusText(lastBackup.status) +
                (lastBackup.fileSize > 0 ? " • " + formatBytes(lastBackup.fileSize) : "")
    }

    function getLastBackupIndicatorColor() {
        var history = backupManager.getBackupHistory()
        if (history.length === 0) return "#6C757D"

        var lastBackup = history[0]
        return getStatusColor(lastBackup.status)
    }

    function getAvailableSpace() {
        return backupManager.getAvailableSpace(backupManager.defaultBackupPath) //using the currentBackupPath returns gibberish
    }

    function getTotalSpace() {
        return backupManager.getDeviceStorage()
    }

    // function getNextScheduledText() {
    //     if (!backupManager.scheduledBackupEnabled) return "Not scheduled"

    //     var hours = backupManager.backupFrequencyHours
    //     var now = new Date()
    //     var nextBackup = new Date(now.getTime() + (hours * 60 * 60 * 1000))

    //     if (hours < 24) {
    //         return "In " + hours + " hours"
    //     } else if (hours === 24) {
    //         return "Tomorrow " + Qt.formatTime(nextBackup, "hh:mm AP")
    //     } else {
    //         // For more than 24 hours, show the actual date
    //         var diffDays = Math.floor(hours / 24)
    //         if (diffDays === 1) {
    //             return "Tomorrow " + Qt.formatTime(nextBackup, "hh:mm AP")
    //         } else if (diffDays < 7) {
    //             // For within a week, you might want to show day name
    //             return Qt.formatDateTime(nextBackup, "dddd hh:mm AP")
    //         } else {
    //             return Qt.formatDateTime(nextBackup, "MMM dd hh:mm AP")
    //         }
    //     }
    // }

    function getNextScheduledText() {
        if (!backupManager.scheduledBackupEnabled) return "Not scheduled"

        var nextBackup = backupManager.nextScheduledBackup
        if (!nextBackup || !nextBackup.toString()) return "Not scheduled"

        var now = new Date()
        var diffMs = nextBackup - now
        var diffHours = Math.floor(diffMs / (1000 * 60 * 60))

        if (diffHours < 1) {
            var diffMins = Math.floor(diffMs / (1000 * 60))
            return "In " + diffMins + " minutes"
        } else if (diffHours < 24) {
            return "In " + diffHours + " hours"
        } else {
            var diffDays = Math.floor(diffHours / 24)
            if (diffDays === 1) {
                return "Tomorrow " + Qt.formatTime(nextBackup, "hh:mm AP")
            } else if (diffDays < 7) {
                return Qt.formatDateTime(nextBackup, "dddd hh:mm AP")
            } else {
                return Qt.formatDateTime(nextBackup, "MMM dd hh:mm AP")
            }
        }
    }

    function getScheduleDescription() {
        if (!backupManager.scheduledBackupEnabled) return "Automatic backup disabled"

        var hours = backupManager.backupFrequencyHours
        if (hours === 6) return "Every 6 hours"
        if (hours === 12) return "Every 12 hours"
        if (hours === 24) return "Daily automatic"
        if (hours === 48) return "Every 2 days"
        if (hours === 168) return "Weekly automatic"
        return "Every " + hours + " hours"
    }

    function getStatusColor(status) {
        switch (status) {
        case BackupManagerInstance.Completed: return "#28A745"
        case BackupManagerInstance.InProgress: return "#007BFF"
        case BackupManagerInstance.Failed: return "#DC3545"
        case BackupManagerInstance.Cancelled: return "#6C757D"
        default: return "#6C757D"
        }
    }

    function getStatusText(status) {
        switch (status) {
        case BackupManagerInstance.Completed: return "Complete"
        case BackupManagerInstance.InProgress: return "In Progress"
        case BackupManagerInstance.Failed: return "Failed"
        case BackupManagerInstance.Cancelled: return "Cancelled"
        case BackupManagerInstance.Idle: return "Idle"
        default: return "Unknown"
        }
    }

    function getBackupTypeText(type) {
        switch (type) {
        case BackupManagerInstance.LocalBackup: return "Local Backup"
        case BackupManagerInstance.CloudBackup: return "Cloud Backup"
        default: return "Unknown"
        }
    }

    // Signal connections
    Connections {
        target: backupManager

        function onBackupStarted() {
            successDialog.title = "Backup Started"
            successDialog.text = "Backup operation has started successfully."
            successDialog.open()
        }

        function onBackupCompleted(backupId, filePath) {
            successDialog.title = "Backup Complete"
            successDialog.text = "Backup completed successfully!\nBackup ID: " + backupId + "\nSaved to: " + filePath
            successDialog.open()
        }

        function onBackupFailed(error) {
            errorDialog.title = "Backup Failed"
            errorDialog.text = error
            errorDialog.open()
        }

        function onBackupCancelled() {
            errorDialog.title = "Backup Cancelled"
            errorDialog.text = "Backup operation was cancelled by user."
            errorDialog.open()
        }

        function onRestoreStarted() {
            successDialog.title = "Restore Started"
            successDialog.text = "Database restore operation has started."
            successDialog.open()
        }

        function onRestoreCompleted() {
            successDialog.title = "Restore Complete"
            successDialog.text = "Database has been restored successfully!"
            successDialog.open()
        }

        function onRestoreFailed(error) {
            errorDialog.title = "Restore Failed"
            errorDialog.text = error
            errorDialog.open()
        }

        function onRestoreCancelled() {
            errorDialog.title = "Restore Cancelled"
            errorDialog.text = "Restore operation was cancelled by user."
            errorDialog.open()
        }

        function errorOccured(error){
            errorDialog.title = "Error!"
            errorDialog.text = error
            errorDialog.open()
        }

        function onGearingUp(message){
            successDialog.title = "Gearing up"
            successDialog.text = message
            successDialog.open()
        }

        function onOperationSuccessful(message){
            successDialog.title = "Operation successful"
            successDialog.text = message
            successDialog.open()
        }

        function onApplicationRestarting(message){  //applicationRestarting
            successDialog.title = "Success!"
            successDialog.text = message
            successDialog.open()
        }
    }


    Component.onCompleted: {
        // Initialize backup screen
        localBackupCard.color = "#E3F2FD"
        updateBackupPath()

        localBackupCard.isSelected = backupSettings.preferLocalBackup
        cloudBackupCard.isSelected = !backupSettings.preferLocalBackup
        localBackupCard.color = backupSettings.preferLocalBackup ? "#E3F2FD" : "#F8F9FA"
        cloudBackupCard.color = !backupSettings.preferLocalBackup ? "#E3F2FD" : "#F8F9FA"

        // Set cloud provider
        cloudProviderDialog.provider = backupSettings.cloudProvider
        if (!backupSettings.preferLocalBackup) {
            currentBackupPath = getCloudProviderName(backupSettings.cloudProvider)
        } else {
            currentBackupPath = backupManager.defaultBackupPath
        }

        // Set schedule
        enableScheduleSwitch.checked = backupSettings.enableScheduledBackup
        frequencyCombo.currentIndex = backupSettings.backupFrequencyIndex
        backupManager.setScheduledBackupEnabled(backupSettings.enableScheduledBackup)
        var hours = [6, 12, 24, 48, 168][backupSettings.backupFrequencyIndex]
        backupManager.setBackupFrequencyHours(hours)

        updateBackupPath()
    }
}













