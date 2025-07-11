import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Pdf
import QtQuick.Dialogs
import Qt.labs.settings
import QtQuick.Effects
import QtWebEngine
import QtWebView
import QtWebChannel
import "DynamicComponentLoader.js" as CustomComponentLoader

Rectangle {
    id: pdfRoot
    anchors.fill: parent
    color: "#f4f4f4" //"lightgrey"
    // visible: false

    // // Color scheme from welcome page
    // readonly property color lightGrey: "#f8f9fa"
    // readonly property color toolbarGrey: "#6c757d"
    // readonly property color textGrey: "#343a40"
    // readonly property color white: "#ffffff"

    // State management
    property string source: ""
    property var recentFiles: []
    property bool isMouseNearBottom: false // property to help control the visibility of the boottomToolbar
    signal closeClicked()

    MouseArea{
        id: pdfRootMA
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // No clicks, only hover tracking
        onPositionChanged: {
            // Set to true if mouse is within 50 pixels of the bottom
            isMouseNearBottom = (mouseY > parent.height - 80)
        }
    }

    Settings {
        id: settings
        category: "RecentFiles"
        property var recentFiles: []
        onRecentFilesChanged: pdfRoot.recentFiles = recentFiles
    }

    function addRecentFile(fileUrl) {
        let files = pdfRoot.recentFiles
        files = files.filter(item => item !== fileUrl)
        files.unshift(fileUrl)
        files = files.slice(0, 10)
        pdfRoot.recentFiles = files
        settings.recentFiles = files
    }

    //close Button
    Rectangle{
        id: closeBtn
        width: 80
        height: 32
        radius: 25
//            color: "#878585"
        border.color: "#878585"
        border.width: 2
        clip: true
        // x: parent.width - width +20
        // y: 10
        z:3 //have the highest z to be visible
        anchors{
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 30
        }

        Text{
            id: closeBtnTxt
            anchors.centerIn: parent
            text: "Close"
//                color: "white"
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea{
            id: closeBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: {
                closeBtn.color = "#878585"
                closeBtnTxt.color = "white"
            }
            onExited: {
                closeBtn.color = "white"
                closeBtnTxt.color ="#878585"
            }

            onClicked:{
                closeClicked()
            }
        }
    }


    // Main content switch
    StackLayout {
        id: mainLayout
        anchors.fill: parent
        currentIndex: pdfRoot.source === "" ? 0 : 1

        // Welcome Page
        Rectangle {
            id: welcomeRoot
            color: lightGrey
            visible: pdfRoot.source === ""

            MouseArea{
                id:welcomeRootMA
                anchors.fill: parent
            }

            Rectangle {
                id: recentFilesPanel
                width: 300
                height: 400
                color: "#f8f9fa"
                border.color: "#dee2e6"
                border.width: 1
                radius: 8

                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.leftMargin: 2
                    color: "#00000015"
                    radius: parent.radius
                    z: parent.z - 1
                }

                // Slide-in animation from left
                transform: Translate {
                    id: slideTransform
                    x: -recentFilesPanel.width
                }

                PropertyAnimation {
                    id: slideInAnimation
                    target: slideTransform
                    property: "x"
                    from: -recentFilesPanel.width
                    to: 0
                    duration: 300
                    easing.type: Easing.OutCubic
                }

                PropertyAnimation {
                    id: slideOutAnimation
                    target: slideTransform
                    property: "x"
                    from: 0
                    to: -recentFilesPanel.width
                    duration: 250
                    easing.type: Easing.InCubic
                }

                // Functions to control animation
                function slideIn() {
                    slideInAnimation.start()
                }

                function slideOut() {
                    slideOutAnimation.start()
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Header with icon and title
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 4
                            height: 24
                            color: "#6c757d"
                            radius: 2
                        }

                        Label {
                            text: "Recent Files"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#495057"
                            Layout.fillWidth: true
                        }
                    }

                    // Separator line
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#e9ecef"
                    }

                    // ListView container with subtle background
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#ffffff"
                        border.color: "#e9ecef"
                        border.width: 1
                        radius: 6

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 4
                            model: pdfRoot.recentFiles
                            clip: true
                            spacing: 2

                            ScrollBar.vertical: ScrollBar {
                                id: vbar
                                active: true
                                policy: ScrollBar.AsNeeded
                                width: 6

                                contentItem: Rectangle {
                                    implicitWidth: 6
                                    radius: width / 2
                                    color: vbar.pressed ? "#818181" : "#c2c2c2"  // Darker when pressed
                                }
                                background: Rectangle {
                                    implicitWidth: 6
                                    radius: width / 2
                                    color: "#f0f0f0"  // Light background color
                                }
                            }



                            delegate: ItemDelegate {
                                width: parent.width
                                height: 40

                                onClicked: {
                                    pdfRoot.source = modelData
                                    addRecentFile(modelData)
                                    recentFilesPanel.slideOut()
                                }

                                background: Rectangle {
                                    color: parent.hovered ? "#f1f3f4" : "transparent"
                                    radius: 4

                                    Rectangle {
                                        anchors.left: parent.left
                                        width: 3
                                        height: parent.height
                                        color: parent.parent.hovered ? "#6c757d" : "transparent"
                                        radius: 1
                                    }
                                }

                                contentItem: Text {
                                    text: modelData.toString().replace("file:///", "")
                                    color: "#495057"
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }

                    // Clear button with enhanced styling
                    Button {
                        text: "Clear Recent Files"
                        Layout.fillWidth: true
                        implicitHeight: 36

                        onClicked: {
                            pdfRoot.recentFiles = []
                            settings.recentFiles = []
                        }

                        background: Rectangle {
                            color: parent.hovered ? "#5a6268" : "#6c757d"
                            radius: 6

                            Rectangle {
                                anchors.fill: parent
                                color: parent.parent.pressed ? "#ffffff20" : "transparent"
                                radius: parent.radius
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Optional: Add a close button in the top right
                Button {
                    anchors{
                        top: parent.top
                        right: parent.right
                        rightMargin: 8
                        topMargin: 4
                        leftMargin: 8
                        bottomMargin: 8
                    }

                    // width: 48
                    height: 32

                    text: "x"

                    onClicked: {
                        recentFilesPanel.slideOut()
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 30

                Text {
                    text: "Welcome to PDF Viewer"
                    font.pixelSize: 32
                    font.bold: true
                    color: textGrey
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Open a PDF file to get started"
                    font.pixelSize: 16
                    color: toolbarGrey
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Button {
                    text: "Open PDF File"
                    onClicked: fileDialog.open()
                    anchors.horizontalCenter: parent.horizontalCenter
                    background: Rectangle {
                        color: parent.hovered ? "#495057" : toolbarGrey
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: white
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text {
                    text: "or drag and drop a PDF file here"
                    font.pixelSize: 12
                    color: toolbarGrey
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Button {
                    text: "Recent Files"
                    onClicked: recentFilesPanel.slideIn()
                    anchors.horizontalCenter: parent.horizontalCenter
                    background: Rectangle {
                        color: parent.hovered ? "#495057" : toolbarGrey
                        radius: 6
                    }
                    contentItem: Text {
                        text: parent.text
                        color: white
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]

                onEntered: function(drag) {
                    drag.accepted = drag.hasUrls && drag.urls[0].toString().toLowerCase().endsWith(".pdf")
                }

                onDropped: function(drop) {
                    if (drop.hasUrls) {
                        const url = drop.urls[0].toString()
                        pdfRoot.source = url
                        addRecentFile(url)
                        drop.acceptProposedAction()
                        view.scaleToWidth(parent.width, parent.height)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.7, 0.7, 0.7, 0.3)
                    visible: parent.containsDrag
                    radius: 10
                    border.color: toolbarGrey
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "Drop PDF file here"
                        color: textGrey
                        font.pixelSize: 18
                        font.bold: true
                    }
                }
            }
        }

        // PDF Viewer
        Rectangle {
            id: pdfViewer
            color: "#F8F8F8" //"lightgrey"

            PdfMultiPageView {
                id: view
                anchors.top: parent.top
                anchors.bottom: parent.bottom //bottomToolBar.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: sideBar.visible ? sideBar.width : 0
                document: doc
                searchString: searchField.text
                onCurrentPageChanged: currentPageSB.value = view.currentPage + 1
            }

            ToolBar {
                id: bottomToolBar
                width: parent.width
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                height: 50
                visible: isMouseNearBottom


                // Override the default ToolBar background
                background: Rectangle {
                    color: "transparent"  // Make toolbar background transparent
                }

                RowLayout {
                    id: footerRow
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 8

                    ToolButton {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        action: Action {
                            id: sideBarOpenAction
                            checkable: true
                            checked: sideBar.visible
                            icon.source: checked ? "assets/leftArrow.png" : "assets/rightArrow.png"
                            onTriggered: sideBar.visible = !sideBar.visible
                        }

                        background: Rectangle {
                            color: parent.hovered ? "#f0f0f0" : "transparent"
                            radius: 4
                            border.color: parent.hovered ? "#d0d0d0" : "transparent"
                            border.width: 1
                        }

                        icon.color: enabled ? "#333333" : "#999999"
                        icon.width: 24
                        icon.height: 24

                        ToolTip.visible: enabled && hovered
                        ToolTip.delay: 1000
                        ToolTip.text: "Toggle Sidebar"
                    }

                    ToolButton {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        action: Action {
                            icon.source: "assets/leftArrow.png"
                            shortcut: StandardKey.FindPrevious
                            enabled: view.searchModel.rowCount() > 0
                            onTriggered: view.searchBack()
                        }

                        background: Rectangle {
                            color: parent.hovered && enabled ? "#f0f0f0" : "transparent"
                            radius: 4
                            border.color: parent.hovered && enabled ? "#d0d0d0" : "transparent"
                            border.width: 1
                        }

                        icon.color: enabled ? "#333333" : "#999999"
                        icon.width: 24
                        icon.height: 24

                        ToolTip.visible: enabled && hovered
                        ToolTip.delay: 1000
                        ToolTip.text: "Find Previous"
                    }

                    TextField {
                        id: searchField
                        placeholderText: "search"
                        Layout.minimumWidth: 150
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter

                        color: "#333333"

                        onAccepted: {
                            sideBar.visible = true
                            sideBarTabs.currentIndex = 1
                        }

                        Image {
                            visible: searchField.text !== ""
                            source: "assets/clear.png"
                            sourceSize.height: searchField.height - 6
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 3
                            }

                            // Style the clear button icon
                            opacity: clearHandler.hovered ? 1.0 : 0.7

                            TapHandler {
                                id: clearHandler
                                onTapped: searchField.clear()
                            }
                        }
                    }

                    ToolButton {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        action: Action {
                            icon.source: "assets/rightArrow.png"
                            shortcut: StandardKey.FindNext
                            enabled: view.searchModel.count > 0
                            onTriggered: view.searchForward()
                        }

                        background: Rectangle {
                            color: parent.hovered && enabled ? "#f0f0f0" : "transparent"
                            radius: 4
                            border.color: parent.hovered && enabled ? "#d0d0d0" : "transparent"
                            border.width: 1
                        }

                        icon.color: enabled ? "#333333" : "#999999"
                        icon.width: 24
                        icon.height: 24

                        ToolTip.visible: enabled && hovered
                        ToolTip.delay: 1000
                        ToolTip.text: "Find Next"
                    }

                    Label {
                        id: statusLabel
                        property size implicitPointSize: doc.pagePointSize(view.currentPage)
                        text: "page " + (currentPageSB.value) + " of " + doc.pageCount +
                              " scale " + view.renderScale.toFixed(2) +
                              " original " + implicitPointSize.width.toFixed(1) + "x" + implicitPointSize.height.toFixed(1) + " pt"
                        visible: doc.pageCount > 0

                        // Style the status label
                        color: "#666666"
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 8

                        // Add a subtle background for better readability
                        background: Rectangle {
                            color: "#f8f8f8"
                            radius: 3
                            border.color: "#e0e0e0"
                            border.width: 1
                            opacity: 0.8
                        }

                        // Add padding around the text
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 4
                        bottomPadding: 4
                    }
                }
            }

            Rectangle {
                id: sideBar
                width: 0
                height: view.height - bottomToolBar.height - 20
                anchors.bottom: bottomToolBar.top
                y: parent.y
                color: "white"
                visible: width > 0
                clip: true

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                states: [
                    State {
                        name: "open"
                        when: sideBar.visible
                        PropertyChanges { target: sideBar; width: 300 }
                    },
                    State {
                        name: "closed"
                        when: !sideBar.visible
                        PropertyChanges { target: sideBar; width: 0 }
                    }
                ]

                TabBar {
                    id: sideBarTabs
                    x: -width
                    rotation: -90
                    transformOrigin: Item.TopRight
                    currentIndex: 2 // Bookmarks by default

                    TabButton { text: qsTr("Info") }
                    TabButton { text: qsTr("Search Results") }
                    TabButton { text: qsTr("Bookmarks") }
                    TabButton { text: qsTr("Pages") }
                }

                GroupBox {
                    anchors.fill: parent
                    anchors.leftMargin: sideBarTabs.height

                    StackLayout {
                        anchors.fill: parent
                        currentIndex: sideBarTabs.currentIndex
                        component InfoField: TextInput {
                            width: parent.width
                            selectByMouse: true
                            readOnly: true
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            spacing: 6
                            width: parent.width - 6
                            Label { font.bold: true; text: qsTr("Title") }
                            InfoField { text: doc.title }
                            Label { font.bold: true; text: qsTr("Author") }
                            InfoField { text: doc.author }
                            Label { font.bold: true; text: qsTr("Subject") }
                            InfoField { text: doc.subject }
                            Label { font.bold: true; text: qsTr("Keywords") }
                            InfoField { text: doc.keywords }
                            Label { font.bold: true; text: qsTr("Producer") }
                            InfoField { text: doc.producer }
                            Label { font.bold: true; text: qsTr("Creator") }
                            InfoField { text: doc.creator }
                            Label { font.bold: true; text: qsTr("Creation date") }
                            InfoField { text: doc.creationDate }
                            Label { font.bold: true; text: qsTr("Modification date") }
                            InfoField { text: doc.modificationDate }
                        }

                        ListView {
                            id: searchResultList
                            implicitHeight: parent.height
                            model: view.searchModel
                            currentIndex: view.searchModel.currentResult
                            ScrollBar.vertical: ScrollBar {}

                            delegate: ItemDelegate {
                                id: resultDelegate
                                required property int index
                                required property int page
                                required property string contextBefore
                                required property string contextAfter
                                width: parent ? parent.width : 0

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Label {
                                        text: "Page " + (resultDelegate.page + 1) + ": "
                                    }

                                    Label {
                                        text: resultDelegate.contextBefore
                                        elide: Text.ElideLeft
                                        horizontalAlignment: Text.AlignRight
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: parent.width / 2
                                    }

                                    Label {
                                        font.bold: true
                                        text: view.searchString
                                        width: implicitWidth
                                    }

                                    Label {
                                        text: resultDelegate.contextAfter
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: parent.width / 2
                                    }
                                }

                                highlighted: ListView.isCurrentItem
                                onClicked: view.searchModel.currentResult = resultDelegate.index
                            }
                        }

                        TreeView {
                            id: bookmarksTree
                            implicitHeight: parent.height
                            implicitWidth: parent.width
                            columnWidthProvider: function() { return width }
                            delegate: TreeViewDelegate {
                                required property int page
                                required property point location
                                required property real zoom
                                onClicked: view.goToLocation(page, location, zoom)
                            }
                            model: PdfBookmarkModel { document: doc }
                            ScrollBar.vertical: ScrollBar {}
                        }

                        GridView {
                            id: thumbnailsView
                            implicitHeight: parent.implicitHeight
                            implicitWidth: parent.implicitWidth
                            model: doc.pageModel
                            cellWidth: width / 2
                            cellHeight: cellWidth + 10

                            delegate: Item {
                                required property int index
                                required property size pointSize
                                required property string label
                                width: thumbnailsView.cellWidth
                                height: thumbnailsView.cellHeight

                                Rectangle {
                                    id: paper
                                    width: image.width
                                    height: image.height
                                    x: (parent.width - width) / 2
                                    y: (parent.height - height - pageNumber.height) / 2
                                    PdfPageImage {
                                        id: image
                                        document: doc
                                        currentFrame: index
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectFit
                                        property bool landscape: pointSize.width > pointSize.height
                                        width: landscape ? thumbnailsView.cellWidth - 6 : height * pointSize.width / pointSize.height
                                        height: landscape ? width * pointSize.height / pointSize.width : thumbnailsView.cellHeight - 14
                                        sourceSize.width: width
                                        sourceSize.height: height
                                    }
                                }

                                Text {
                                    id: pageNumber
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: label
                                }

                                TapHandler {
                                    onTapped: view.goToPage(index)
                                }
                            }
                        }
                    }
                }
            }

            FileDialog {
                id: fileDialog
                title: "Open a PDF file"
                nameFilters: ["PDF files (*.pdf)"]
                onAccepted: {
                    pdfRoot.source = selectedFile
                    view.scaleToWidth(parent.width, parent.height)
                    addRecentFile(selectedFile)
                }
            }

            Dialog {
                id: passwordDialog
                title: "Password"
                standardButtons: Dialog.Ok | Dialog.Cancel
                modal: true
                closePolicy: Popup.CloseOnEscape
                anchors.centerIn: parent
                width: 300

                contentItem: TextField {
                    id: passwordTextField
                    placeholderText: qsTr("Please provide the password")
                    echoMode: TextInput.Password
                    width: parent.width
                    onAccepted: passwordDialog.accept()
                }

                onOpened: passwordTextField.forceActiveFocus()
                onAccepted: doc.password = passwordTextField.text
            }

            Dialog {
                id: errorDialog
                title: "Error loading " + doc.source
                standardButtons: Dialog.Close
                modal: true
                closePolicy: Popup.CloseOnEscape
                width: 300
                anchors.centerIn: parent
                visible: false//doc.status === PdfDocument.Error

                contentItem: Label {
                    id: errorField
                    text: doc.error
                }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]
                onEntered: (drag) => {
                    drag.accepted = (drag.proposedAction === Qt.MoveAction || drag.proposedAction === Qt.CopyAction) &&
                                    drag.hasUrls && drag.urls[0].endsWith("pdf")
                }
                onDropped: (drop) => {
                               pdfRoot.source = drop.urls[0]
                               addRecentFile(drop.urls[0])
                               drop.acceptProposedAction()
                               view.scaleToWidth(parent.width, parent.height)
                           }
            }

            PdfDocument {
                id: doc
                source: Qt.resolvedUrl(pdfRoot.source)
                onPasswordRequired: passwordDialog.open()
            }
        }
    }


    Rectangle {
        id: navigationRect
        width: 50
        height:verticalToolBar.height + 20 //parent.height * 0.60
        radius: 8
        border.color: "lightgray"
        color: "white"
        opacity: 0.9


        // Position on the right side
        x: parent.width - width - 10  // Right side with 10px margin
        y: (parent.height - height)/2 - 40 //add 40 to cover for the spinbox

        // Ensure the rectangle stays within parent bounds when parent is resized
        onXChanged: {
            if (x < 0) x = 0
            if (x > parent.width - width) x = parent.width - width
        }
        onYChanged: {
            if (y < 0) y = 0
            if (y > parent.height - height) y = parent.height - height
        }

        Rectangle {
            id: moveHandle
            width: parent.width * 0.75
            height: 4
            radius: width/2
            anchors {
                top: parent.top
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            color: "lightgray"

            MouseArea {
                id: handleRectMA
                anchors.fill: parent
                hoverEnabled: true
                drag {
                    target: navigationRect
                    minimumX: 0
                    minimumY: 0
                    maximumX: navigationRect.parent.width - navigationRect.width
                    maximumY: navigationRect.parent.height - navigationRect.height
                    smoothed: true
                }
                onReleased: {
                    console.log("Rectangle moved to x:", navigationRect.x, "y:", navigationRect.y)
                    moveHandle.color = "lightgray"
                }
                onPressed:{
                    moveHandle.color = "black"
                }
                onEntered: {
                    moveHandle.color = "gray"
                }
                onExited: {
                    moveHandle.color = "lightgray"
                }
            }
        }

        MouseArea {
            id: navigationRectMA
            anchors.fill: parent
            drag {
                target: parent
                minimumX: 0
                minimumY: 0
                maximumX: parent.parent.width - parent.width
                maximumY: parent.parent.height - parent.height
                smoothed: true
            }
            onReleased: console.log("Rectangle moved to x:", parent.x, "y:", parent.y)
        }

        ToolBar {
            id: verticalToolBar
            height: verticalColumn.height
            width: parent.width - 2
            anchors {
                top: moveHandle.bottom
                topMargin: 10
            }

            // Override the default ToolBar background
            background: Rectangle {
                color: "transparent"  // Make toolbar background transparent
            }

            ColumnLayout {
                id: verticalColumn
                anchors.centerIn: parent
                anchors.topMargin: 10
                spacing: 4  // Add some spacing between buttons

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        shortcut: StandardKey.Open
                        icon.source: "assets/openFolder.png"
                        onTriggered: fileDialog.open()
                    }

                    // Custom styling for the button
                    background: Rectangle {
                        color: parent.hovered ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    // Style the icon to be dark/visible
                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Open File"
                }

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        shortcut: StandardKey.ZoomIn
                        icon.source: "assets/zoomIn"
                        enabled: view.renderScale < 10
                        onTriggered: view.renderScale *= Math.sqrt(2)
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Zoom In"
                }

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        shortcut: StandardKey.ZoomOut
                        icon.source: "assets/zoomOut.png"
                        enabled: view.renderScale > 0.1
                        onTriggered: view.renderScale /= Math.sqrt(2)
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Zoom Out"
                }

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        icon.source: "assets/leftArrow.png"
                        enabled: view.backEnabled
                        onTriggered: view.back()
                    }

                    background: Rectangle {
                        color: parent.hovered && enabled ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered && enabled ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Go Back"
                }

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        icon.source: "assets/rightArrow.png"
                        enabled: view.forwardEnabled
                        onTriggered: view.forward()
                    }

                    background: Rectangle {
                        color: parent.hovered && enabled ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered && enabled ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Go Forward"
                }

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        shortcut: StandardKey.SelectAll
                        icon.source: "assets/selection.png"
                        onTriggered: view.selectAll()
                    }

                    background: Rectangle {
                        color: parent.hovered ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Select All"
                }

                ToolButton {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    action: Action {
                        shortcut: StandardKey.Copy
                        icon.source: "assets/copySymbol.png"
                        enabled: view.selectedText !== ""
                        onTriggered: view.copySelectionToClipboard()
                    }

                    background: Rectangle {
                        color: parent.hovered && enabled ? "#f0f0f0" : "transparent"
                        radius: 4
                        border.color: parent.hovered && enabled ? "#d0d0d0" : "transparent"
                        border.width: 1
                    }

                    icon.color: enabled ? "#333333" : "#999999"
                    icon.width: 24
                    icon.height: 24

                    ToolTip.visible: hovered
                    ToolTip.delay: 1000
                    ToolTip.text: "Copy Selection"
                }

                Shortcut {
                    sequence: StandardKey.Find
                    onActivated: {
                        searchField.forceActiveFocus()
                        searchField.selectAll()
                    }
                }

                Shortcut {
                    sequence: StandardKey.Quit
                    onActivated: Qt.quit()
                }
            }
        }
    }

    //spinbox
    SpinBox {
        id: currentPageSB
        anchors{
            top: navigationRect.bottom
            horizontalCenter: navigationRect.horizontalCenter
        }

        from: 1
        to: doc.pageCount
        editable: true
        onValueModified: view.goToPage(value - 1)

        // Consistent sizing with other toolbar elements
        Layout.preferredWidth: 80
        Layout.preferredHeight: 40

        // Style the SpinBox background
        background: Rectangle {
            color: currentPageSB.activeFocus ? "#ffffff" : "#f8f8f8"
            border.color: currentPageSB.activeFocus ? "#0078d4" : "#d0d0d0"
            border.width: 1
            radius: 4
        }

        // Style the text input
        contentItem: TextInput {
            text: currentPageSB.textFromValue(currentPageSB.value, currentPageSB.locale)
            font.pixelSize: 12
            color: "#333333"
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !currentPageSB.editable
            validator: currentPageSB.validator
            inputMethodHints: Qt.ImhDigitsOnly

            // Add padding for better appearance
            leftPadding: 8
            rightPadding: 8
        }

        // Style the up button
        up.indicator: Rectangle {
            x: currentPageSB.mirrored ? 0 : parent.width - width
            height: parent.height / 2
            width: 20
            color: currentPageSB.up.pressed ? "#e0e0e0" : (currentPageSB.up.hovered ? "#f0f0f0" : "transparent")
            border.color: "#d0d0d0"
            border.width: currentPageSB.up.hovered ? 1 : 0
            radius: 2

            Text {
                text: "▲"
                font.pixelSize: 8
                color: currentPageSB.up.enabled ? "#333333" : "#999999"
                anchors.centerIn: parent
            }
        }

        // Style the down button
        down.indicator: Rectangle {
            x: currentPageSB.mirrored ? 0 : parent.width - width
            y: parent.height / 2
            height: parent.height / 2
            width: 20
            color: currentPageSB.down.pressed ? "#e0e0e0" : (currentPageSB.down.hovered ? "#f0f0f0" : "transparent")
            border.color: "#d0d0d0"
            border.width: currentPageSB.down.hovered ? 1 : 0
            radius: 2

            Text {
                text: "▼"
                font.pixelSize: 8
                color: currentPageSB.down.enabled ? "#333333" : "#999999"
                anchors.centerIn: parent
            }
        }

        // Add tooltip for better UX
        ToolTip.visible: hovered
        ToolTip.delay: 1000
        ToolTip.text: "Page " + value + " of " + to

        Shortcut {
            sequence: StandardKey.MoveToPreviousPage
            onActivated: view.goToPage(currentPageSB.value - 2)
        }

        Shortcut {
            sequence: StandardKey.MoveToNextPage
            onActivated: view.goToPage(currentPageSB.value)
        }
    }
}
