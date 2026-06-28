import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick.Dialogs
import QtCharts
import QtCore
import "ui"
import "DynamicComponentLoader.js" as CustomComponentLoader
import com.libro.settings



Rectangle {
    id: page2
    width: 1000
    height: 500
    visible: true
    color: "#f4f4f4"

    property string toolBarAdminProfilePic: "assets/userImage.png"
    property var moreTools: null
    property var settingsPage: null
    property var documentationPage: null

    // Tool page properties
    property var reportsPage: null
    property var inventoryTracking: null
    property var backupPage: null
    property var activityLogs: null
    property var libroAIPage: null
    property var pdfRoot: null
    property var digitalMaterialPage: null
    property var bookshopScreen: null
    property var storageManagerScreen: null
    property var emailNotifications: null
    property var opacConfigurationView: null
    property var clearancePage: null
    property var appManagerPage: null
    property var suggestionsAdminPage: null
    property var barcodeWriterPage: null

    ListModel {
        id: faqModel

        ListElement {
            question: "How do non-admin users log in?"
            answer: "Non-admin users (Students, Staff, Other Users) log in using their full name or email as the username and their identification number (Admission No, Staff No, or User No) as the password. They select their appropriate role on the login screen."
        }
        ListElement {
            question: "Can I have multiple admin accounts?"
            answer: "Yes. Additional admins can be created from the App Manager → Administrators section. Only existing staff members can be promoted to admin. The first admin created during setup is the Super Admin."
        }
        ListElement {
            question: "What happens when a user's loan period expires?"
            answer: "The book is marked as overdue in the system. Fines accrue daily at the configured rate (default: 10 KES/day) up to the maximum fine cap (default: 500 KES). When the book is returned, the admin is prompted to collect or waive the fine."
        }
        ListElement {
            question: "Can I change the currency from KES?"
            answer: "Yes. Go to Settings → Circulation → Fine Settings and change the Currency Symbol field to your preferred currency code."
        }
        ListElement {
            question: "How are barcodes generated?"
            answer: "Barcodes are auto-generated using the pattern: [2-char subject prefix][YYMMDD date][4-digit random number]. They are created in Code128 format. You can also generate barcodes in bulk by date range from the Barcode Writer tool."
        }
        ListElement {
            question: "What is OPAC?"
            answer: "OPAC (Online Public Access Catalog) is a system that makes your library catalog accessible online. Users can search for books and place reservations through a web portal, which then syncs with your Libro desktop application."
        }
        ListElement {
            question: "How does the clearance system work?"
            answer: "Clearance checks whether a user has any outstanding library obligations: unreturned books, unreturned digital materials, lost books with unpaid charges, and unpaid fines. All four checks must pass for clearance to be approved. A clearance receipt can be saved as HTML or image."
        }
        ListElement {
            question: "Is my data encrypted?"
            answer: "Admin passwords are hashed using SHA-256 with random salt. Database backups can optionally be encrypted. The database itself is stored locally in the application data directory."
        }
        ListElement {
            question: "What is the grace period?"
            answer: "When your license expires, you have a 7-day grace period during which all features remain available. A warning dialog shows how many days remain. After the grace period, the application is blocked until you renew your license."
        }
        ListElement {
            question: "Can I use Libro offline?"
            answer: "Libro stores all data locally in an SQLite database, so most features work offline. However, these features require network connectivity: license validation, OPAC synchronization, cloud backups, and sending email notifications."
        }
        ListElement {
            question: "How do I reset the application to factory defaults?"
            answer: "Go to Settings and click \"Reset All to Defaults\". This resets all settings to their default values. Note: this does not delete your book or user data — only configuration settings are reset."
        }
        ListElement {
            question: "What user data can non-admin users see and do?"
            answer: "Non-admin users have limited access. They can: view their profile, see their borrowing history, place book reservations, submit suggestions and feedback, and view their currently borrowed books count. They cannot modify the catalog, manage other users, or access administrative tools."
        }
    }

    ListModel {
        id: filteredFaqModel
    }

    ListModel {
        id: filteredToolsModel
    }

    function getToolsList() {
        return [
            { name: "Reports and analytics",   icon: "assets/reports.png",            component: "ReportsPage",               useMainContainer: true  },
            { name: "Inventory tracking",       icon: "assets/inventory2.png",         component: "InventoryTracking",         useMainContainer: true  },
            { name: "Backup and restore",       icon: "assets/cloudBackuprestore.png", component: "BackupPage",                useMainContainer: false },
            { name: "Activity logger",          icon: "assets/logging.png",            component: "ActivityLogs",              useMainContainer: false },
            { name: "Libro AI",                 icon: "assets/genAI.png",              component: "LibroAIPage",               useMainContainer: false },
            { name: "Ebook reader",             icon: "assets/pdf.png",                component: "PDFReaderScreen",           useMainContainer: false },
            { name: "Digital material",         icon: "assets/digitalContent.png",     component: "DigitalMaterials",          useMainContainer: false },
            { name: "Online Bookshops",         icon: "assets/bookstore.png",          component: "BookshopScreen",            useMainContainer: false },
            { name: "Storage manager",          icon: "assets/storage.png",            component: "StorageManager",            useMainContainer: false },
            { name: "Send Notifications",       icon: "assets/emailNotification.png",  component: "EmailNotifications",        useMainContainer: false },
            { name: "Opac Configuration",       icon: "assets/opac.png",               component: "OpacConfigurationView",     useMainContainer: false },
            { name: "Clearance",                icon: "assets/clearance.png",          component: "Clearance/ClearancePage",   useMainContainer: false },
            { name: "System Management",        icon: "assets/management.png",         component: "AppManagerPage",            useMainContainer: false },
            { name: "Suggestions and Feedback", icon: "assets/suggestion.png",         component: "SuggestionsAdminPage",      useMainContainer: false },
            { name: "Barcode Writer",           icon: "assets/barcodeWriter2.png",     component: "BarcodeWriter",             useMainContainer: false },
            { name: "Help and documentation",   icon: "assets/documentation.png",      component: "Documentation",             useMainContainer: true  }
        ]
    }

    function getPageVar(component) {
        switch (component) {
            case "ReportsPage":             return reportsPage
            case "InventoryTracking":       return inventoryTracking
            case "BackupPage":              return backupPage
            case "ActivityLogs":            return activityLogs
            case "LibroAIPage":             return libroAIPage
            case "PDFReaderScreen":         return pdfRoot
            case "DigitalMaterials":        return digitalMaterialPage
            case "BookshopScreen":          return bookshopScreen
            case "StorageManager":          return storageManagerScreen
            case "EmailNotifications":      return emailNotifications
            case "OpacConfigurationView":   return opacConfigurationView
            case "Clearance/ClearancePage": return clearancePage
            case "AppManagerPage":          return appManagerPage
            case "SuggestionsAdminPage":    return suggestionsAdminPage
            case "BarcodeWriter":           return barcodeWriterPage
            case "Documentation":           return documentationPage
            default:                        return null
        }
    }

    function openTool(component, useMainContainer) {
        var pageVar = getPageVar(component)
        var target = useMainContainer ? mainContainer : mainPageContainer
        CustomComponentLoader.customCreateComponent(pageVar, component, target)
    }

    function rebuildFaqResults() {
        var query = navigationTextInput.text.trim().toLowerCase()
        filteredToolsModel.clear()
        filteredFaqModel.clear()

        if (query.length === 0) {
            if (faqSearchPopup.visible)
                faqSearchPopup.close()
            return
        }

        // Populate tools
        var tools = getToolsList()
        for (var t = 0; t < tools.length; t++) {
            if (tools[t].name.toLowerCase().indexOf(query) !== -1) {
                filteredToolsModel.append({
                    name:             tools[t].name,
                    icon:             tools[t].icon,
                    component:        tools[t].component,
                    useMainContainer: tools[t].useMainContainer
                })
            }
        }

        // Populate FAQs
        for (var i = 0; i < faqModel.count; i++) {
            var faq = faqModel.get(i)
            if (faq.question.toLowerCase().indexOf(query) !== -1 ||
                faq.answer.toLowerCase().indexOf(query) !== -1) {
                filteredFaqModel.append({
                    question: faq.question,
                    answer:   faq.answer,
                    expanded: false
                })
            }
        }

        if (!faqSearchPopup.visible)
            faqSearchPopup.open()
    }

    function toggleFaqExpansion(index) {
        if (index < 0 || index >= filteredFaqModel.count)
            return

        var faq = filteredFaqModel.get(index)
        filteredFaqModel.setProperty(index, "expanded", !faq.expanded)
    }

    Settings {
        id: appSettings
        category: "UserProfile"
        property string profilePicturePath: "assets/userImage.png"
    }

    ToolBar {
        id: toolBar
        anchors.top: parent.top
        height: 50
        width: parent.width

        Rectangle{
            anchors.fill: parent

            Rectangle {
                id: libraryIconRect
                width: 40
                height: 40
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                Image {
                    id: libraryIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/libroIcon.ico"
                }
            }

            Rectangle {
                id: libraryNameRect
                width: libraryName.width
                anchors {
                    left: libraryIconRect.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    id: libraryName
                    anchors.verticalCenter: parent.verticalCenter
                    Binding {
                        target: libraryName
                        property: "text"
                        value: SettingsManager.libraryName
                    }
                    font.pointSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                id: toolBarAdminProfilePicRect
                height: 45
                width: height
                radius: width / 2
                clip: true
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 5
                }

                color: "transparent"

                Image {
                    id: sourceItem
                    source: appSettings.profilePicturePath
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                }

                MultiEffect {
                    source: sourceItem
                    anchors.fill: sourceItem
                    maskEnabled: true
                    maskSource: mask
                }

                Item {
                    id: mask
                    width: sourceItem.width
                    height: sourceItem.height
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        width: sourceItem.width
                        height: sourceItem.height
                        radius: width / 2
                        color: "black"
                    }
                }

                FileDialog {
                    id: fileDialog
                    title: "Select Profile Picture"
                    nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif)"]
                    onAccepted: {
                        if (fileDialog.currentFile) {
                            var fileUrl = fileDialog.currentFile
                            console.log("Selected file:", fileUrl)
                            toolBarAdminProfilePic = fileUrl
                        }
                    }
                    onRejected: {
                        console.log("Canceled")
                    }
                }

                MouseArea {
                    anchors.fill: sourceItem
                    cursorShape: "PointingHandCursor"
                    onClicked: {
                        mainDrawer.open()
                    }
                    hoverEnabled: true
                }
            }

            Rectangle{
                id: otherToolsRect
                width: 40
                height: 40
                radius: 4
                anchors{
                    right: toolBarAdminProfilePicRect.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Rectangle{
                    id: otherToolsIconRect
                    width: 20
                    height: 20
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image{
                        id: otherToolsIcon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/otherToolsIcon.png"
                    }
                }

                MouseArea{
                    id: otherToolsMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        otherToolsRect.color = "#E8E3E4"
                    }
                    onExited: {
                        otherToolsRect.color = "white"
                    }

                    onClicked: {
                        CustomComponentLoader.customCreateComponent(moreTools,"ToolsContainerPage", mainPageContainer)
                    }
                }
            }

            Rectangle{
                id: helpRect
                width: 40
                height: 40
                radius: 4
                anchors{
                    right: otherToolsRect.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Rectangle{
                    id: helpIconRect
                    width: 30
                    height: 30
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image{
                        id: helpIcon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/helpIcon.png"
                    }
                }

                MouseArea{
                    id: helpMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        helpRect.color = "#E8E3E4"
                    }
                    onExited: {
                        helpRect.color = "white"
                    }

                    onClicked: function() {
                        CustomComponentLoader.customCreateComponent(documentationPage,"Documentation", mainContainer)
                    }
                }
            }

            Rectangle{
                id: mainScreenSearchbox
                width: 400
                height: 30
                z: 3
                radius: 4
                anchors{
                    right: helpRect.left
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                color: "transparent"
                border.color: "blue"

                signal textChanged()

                property string placeHolderText: "Search for tools and FAQs"

                Image {
                    id: searchIcon

                    anchors{
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }

                    height: parent.height *.45
                    fillMode: Image.PreserveAspectFit

                    source: "assets/searchIcon.png"
                }

                Text{
                    id: searchBoxPlaceHolder
                    visible: navigationTextInput.text === ""
                    color: "#585757"
                    text: mainScreenSearchbox.placeHolderText
                    anchors{
                        left: searchIcon.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 20
                    }
                }

                MouseArea{
                    id: toolBarSearchBoxMA
                    cursorShape: "IBeamCursor"
                    anchors{
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        left: searchIcon.right
                        leftMargin: 20
                    }

                    TextInput{
                        id: navigationTextInput
                        clip: true
                        anchors{
                            right: parent.right
                            rightMargin: 5
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                        }

                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 11

                        onTextChanged: page2.rebuildFaqResults()
                        onActiveFocusChanged: {
                            if (!activeFocus && text.trim() === "" && faqSearchPopup.visible)
                                faqSearchPopup.close()
                        }
                    }
                }

                Popup {
                    id: faqSearchPopup
                    parent: page2
                    modal: false
                    focus: false
                    padding: 0
                    z: 3
                    x: mainScreenSearchbox.x
                    y: mainScreenSearchbox.y + mainScreenSearchbox.height + 6
                    width: mainScreenSearchbox.width
                    height: Math.min(page2.height * 0.6, popupFlickable.contentHeight + 16)
                    visible: false
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                    background: Rectangle {
                        radius: 8
                        color: "white"
                        border.color: "#CBD5E1"
                        border.width: 1
                    }

                    contentItem: Flickable {
                        id: popupFlickable
                        clip: true
                        contentWidth: width
                        contentHeight: popupMainColumn.implicitHeight + 16
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        Column {
                            id: popupMainColumn
                            width: popupFlickable.width - 16
                            x: 8
                            y: 8
                            spacing: 4

                            // ── Tools section ──────────────────────────────
                            Text {
                                visible: filteredToolsModel.count > 0
                                text: "Tools"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#334155"
                                topPadding: 4
                                bottomPadding: 4
                            }

                            Repeater {
                                model: filteredToolsModel

                                delegate: Rectangle {
                                    width: popupMainColumn.width
                                    height: 40
                                    radius: 6
                                    color: toolMA.containsMouse ? "#EFF6FF" : "#F8FAFC"
                                    border.color: toolMA.containsMouse ? "#BFDBFE" : "#E2E8F0"
                                    border.width: 1

                                    Row {
                                        spacing: 10
                                        anchors {
                                            left: parent.left
                                            leftMargin: 10
                                            verticalCenter: parent.verticalCenter
                                        }

                                        Image {
                                            width: 20
                                            height: 20
                                            source: icon
                                            fillMode: Image.PreserveAspectFit
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: name
                                            font.pixelSize: 12
                                            color: "#1E293B"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: toolMA
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: {
                                            faqSearchPopup.close()
                                            page2.openTool(component, useMainContainer)
                                        }
                                    }

                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }

                            // ── Divider ────────────────────────────────────
                            Rectangle {
                                visible: filteredToolsModel.count > 0 && filteredFaqModel.count > 0
                                width: popupMainColumn.width
                                height: 1
                                color: "#E2E8F0"
                            }

                            // ── FAQs section ───────────────────────────────
                            Text {
                                visible: filteredFaqModel.count > 0
                                text: "FAQs"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#334155"
                                topPadding: 4
                                bottomPadding: 4
                            }

                            Repeater {
                                model: filteredFaqModel

                                delegate: Rectangle {
                                    width: popupMainColumn.width
                                    height: faqItemCol.implicitHeight + 16
                                    radius: 6
                                    color: "#F8FAFC"
                                    border.color: "#E2E8F0"
                                    border.width: 1

                                    Column {
                                        id: faqItemCol
                                        width: parent.width - 20
                                        spacing: 8
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 10
                                        }

                                        Row {
                                            width: parent.width
                                            spacing: 8

                                            Text {
                                                text: expanded ? "▾" : "▸"
                                                font.pixelSize: 12
                                                color: "#3B82F6"
                                                anchors.verticalCenter: qText.verticalCenter
                                            }

                                            Text {
                                                id: qText
                                                width: parent.width - 20
                                                text: question
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: "#1E293B"
                                                wrapMode: Text.WordWrap
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            visible: expanded
                                            text: answer
                                            font.pixelSize: 11
                                            color: "#475569"
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: page2.toggleFaqExpansion(index)
                                    }
                                }
                            }

                            // ── No results ─────────────────────────────────
                            Rectangle {
                                visible: filteredToolsModel.count === 0 && filteredFaqModel.count === 0
                                width: popupMainColumn.width
                                height: 48
                                color: "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "No matching tools or FAQs found"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#334155"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle{
        id: mainContainer
        anchors{
            left: parent.left
            right: parent.right
            top: toolBar.bottom
            bottom: parent.bottom
        }
        color: "transparent"
        clip: true


        Rectangle {
            id: mainPageContainer
            radius: 8
            anchors {
                left: buttonsRect.right
                leftMargin: 20
                top: parent.top
                topMargin: 10
                right: parent.right
                bottom: parent.bottom
            }
            color: "#FBFBFB"
            border.color: "#CDCACA"
            clip: true

            Loader{
                id: mainPageContainerLoader
                anchors.fill: parent
                source: "QuickTools1.qml"
            }
        }

        LeftButtons {
            id: buttonsRect
            width: parent.width * 0.21
            height: parent.height * 0.65
            anchors {
                top: parent.top
                left: parent.left
            }
        }

        DynamicBox {
            id: dynamicBox
            visible: width > 200 && height > 210

            anchors {
                top: buttonsRect.bottom
                topMargin: 10
                left: parent.left
                right: buttonsRect.right
                bottom: parent.bottom
            }
            Component.onCompleted: {
                console.log("Width: ", width, "Height: ", height)
            }
        }
    }

    Drawer{
        id: mainDrawer
        edge: Qt.RightEdge
        width: parent.width* .25
        height: parent.height

        Rectangle{
            id: rightPane
            anchors.fill: parent
            radius: 8
            color: "#DBE0E7"
            clip: true

            Image {
                id: settingsIcon
                source: "assets/settings.png"
                width: 24
                height: 24
                anchors{
                    top: parent.top
                    topMargin: 20
                    right: parent.right
                    rightMargin: 20
                }
                fillMode: Image.PreserveAspectFit
                MouseArea{
                    anchors.fill: parent
                    cursorShape: "PointingHandCursor"

                    onClicked: {
                        mainDrawer.close()
                        CustomComponentLoader.customCreateComponent(settingsPage,"Settings/SettingsPage", page2)
                    }
                }
            }

            Rectangle {
                id: userProfileRect
                width: parent.width * 0.50
                height: width
                radius: width/2
                clip: true
                border.width: 2
                border.color: "white"
                anchors {
                    top: parent.top
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                color: "transparent"

                Image {
                    id: sourceItem2
                    source: appSettings.profilePicturePath
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    visible: false
                    fillMode: Image.PreserveAspectCrop

                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Failed to load profile picture, using default")
                            source = "assets/userImage.png"
                        }
                    }
                }

                MultiEffect {
                    source: sourceItem2
                    anchors.fill: sourceItem2
                    maskEnabled: true
                    maskSource: mask2
                }

                Item {
                    id: mask2
                    width: sourceItem2.width
                    height: sourceItem2.height
                    layer.enabled: true
                    visible: false
                    Rectangle {
                        width: sourceItem2.width
                        height: sourceItem2.height
                        radius: width / 2
                        color: "black"
                    }
                }

                FileDialog {
                    id: fileDialog2
                    title: "Select Profile Picture"
                    nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif *.bmp)"]
                    onAccepted: {
                        if (fileDialog2.currentFile) {
                            var fileUrl = fileDialog2.currentFile.toString()
                            console.log("Selected file:", fileUrl)
                            appSettings.profilePicturePath = fileUrl
                            console.log("Profile picture saved to settings")
                        }
                    }
                    onRejected: {
                        console.log("File selection canceled")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fileDialog2.open()
                    hoverEnabled: true

                    onEntered: {
                        userProfileRect.opacity = 0.8
                    }
                    onExited: {
                        userProfileRect.opacity = 1.0
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "#000000"
                    opacity: 0.6
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: 8
                    }

                    Text {
                        text: "📷"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fileDialog2.open()
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            Text {
                id:adminLabel
                text: "Admin: " + appManager.currentAdminName
                color: "#1E293B"
                font.pixelSize: 12
                font.weight: Font.Bold
                font.italic: true
                anchors{
                    top: userProfileRect.bottom
                    topMargin: 20
                    horizontalCenter: userProfileRect.horizontalCenter
                }
            }

            RoundButton{
                id: helpButton
                text: "Help and Documentation"
                width: parent.width * .90
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: adminLabel.bottom
                    topMargin: 10
                }

                onClicked: function() {
                    mainDrawer.close()
                    CustomComponentLoader.customCreateComponent(documentationPage,"Documentation", mainContainer)
                }
            }

            RoundButton{
                id: logoutButton
                text: "Logout"
                width: parent.width * .90
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: helpButton.bottom
                    topMargin: 10
                }

                onClicked: {
                    // Actually end the admin session, then return to login.
                    appManager.adminLogout()
                    mainDrawer.close()
                    mainLoader.source = "Login.qml"
                }
            }

            Rectangle {
                id: graphRect
                width: parent.width * 0.95
                height: parent.height* 0.40
                color: "transparent"
                anchors {
                    top: logoutButton.bottom
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }

                ChartView {
                    id: usageChart
                    anchors.fill: parent
                    title: "Today's Activity"
                    antialiasing: true
                    legend.visible: true

                    ValuesAxis {
                        id: xAxis
                        titleText: "Hour of Day"
                        min: 0
                        max: 23
                        tickCount: 12
                        labelFormat: "%d"
                    }

                    ValuesAxis {
                        id: yAxis
                        titleText: "Transactions"
                        min: 0
                        tickCount: 5
                        labelFormat: "%d"
                    }

                    LineSeries {
                        id: activitySeries
                        name: "Books Issued & Returned"
                        color: "#3B82F6"
                        width: 2
                        axisX: xAxis
                        axisY: yAxis

                        Component.onCompleted: {
                            updateChartData()
                        }
                    }
                }

                Rectangle {
                    id: refreshButton
                    width: 36
                    height: 36
                    radius: 18
                    color: "#F1F5F9"
                    border.color: "#E2E8F0"
                    border.width: 1
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 12
                    }

                    Text {
                        text: "↻"
                        color: "#475569"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: {
                            refreshButton.color = "#E2E8F0"
                            refreshButton.scale = 1.1
                        }
                        onExited: {
                            refreshButton.color = "#F1F5F9"
                            refreshButton.scale = 1.0
                        }
                        onClicked: {
                            analyticsManager.refreshData()
                            refreshButton.rotation += 360
                        }
                    }

                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                }

                Text {
                    visible: activitySeries.count === 0
                    text: "No activity recorded today"
                    color: "#64748B"
                    font.pixelSize: 14
                    anchors.centerIn: parent
                }

                Connections {
                    target: analyticsManager
                    function onTodayActivityDataChanged() {
                        updateChartData()
                    }
                }
            }

            Rectangle {
                id: footerSection
                width: parent.width * 0.9
                height: 50
                radius: 8
                color: "transparent"
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }

                Item {
                    height: 32
                    width: parent.width
                    anchors{
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        id: version
                        text: "Libro ILMS 1.0.0"
                        color: "#1E293B"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.italic: true
                        anchors{
                            bottom: copyright.top
                            bottomMargin: 2
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Text {
                        id: copyright
                        text: "© Libro 2025"
                        color: "#64748B"
                        font.pixelSize: 10
                        font.italic: true
                        anchors{
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }

    function updateChartData() {
        activitySeries.clear()

        var data = analyticsManager.todayActivityData
        var maxCount = 0

        for (var i = 0; i < data.length; i++) {
            if (data[i].count > maxCount) {
                maxCount = data[i].count
            }
        }

        yAxis.max = Math.max(10, Math.ceil(maxCount * 1.2))

        for (var j = 0; j < data.length; j++) {
            activitySeries.append(data[j].hour, data[j].count)
        }

        if (data.length > 0) {
            var minHour = data[0].hour
            var maxHour = data[data.length - 1].hour
            xAxis.min = Math.max(0, minHour - 1)
            xAxis.max = Math.min(23, maxHour + 1)
        } else {
            xAxis.min = 0
            xAxis.max = 23
        }

        console.log("Chart updated with", data.length, "data points")
    }
}
