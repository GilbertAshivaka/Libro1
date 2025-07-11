import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Pdf
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: parent.width
    height: parent.height
    title: qsTr("PDF Reader" + doc.title)
    color: "lightgrey"
    property string source: "file:///C:/Users/Admin/Downloads/the-illusion-of-thinking.pdf"

    signal closeClicked()
    signal showRequested()
    signal hideRequested()

    onShowRequested: show()
    onHideRequested: hide()

    header: ToolBar{
        RowLayout{
            anchors.fill: parent
            anchors.rightMargin: 6

            ToolButton{
                action: Action{
                    shortcut: StandardKey.Open
                    icon.source: "assets/openFolder.png"
                    onTriggered: {
                        fileDialog.open()
                    }
                }
            }

            ToolButton{
                action: Action{
                    shortcut: StandardKey.ZoomIn
                    icon.source: "assets/zoomIn"
                    enabled: view.renderScale < 10
                    onTriggered: {
                        view.renderScale *= Math.sqrt(2)
                    }
                }
            }

            ToolButton{
                action: Action{
                    shortcut: StandardKey.ZoomOut
                    icon.source: "assets/zoomOut.png"
                    enabled: view.renderScale > 0.1
                    onTriggered: {
                        view.renderScale /= Math.sqrt(2)
                    }
                }

                ToolTip.visible: enabled && hovered
                ToolTip.delay: 2000
                ToolTip.text: "go back"
            }

            ToolButton{
                action: Action {
                    icon.source: "assets/leftArrow.png"
                    enabled: view.backEnabled
                    onTriggered:{
                        view.back()
                    }
                }
            }

            SpinBox{
                id: currentPageSB
                from: 1
                to: doc.pageCount
                editable:  true
                onValueModified: view.goToPage(value -1)
                Shortcut{
                    sequence: StandardKey.MoveToPreviousPage
                    onActivated: view.goToPage(currentPageSB.value -2)
                }

                Shortcut{
                    sequence: StandardKey.MoveToNextPage
                    onActivated: view.goToPage(currentPageSB.value)
                }
            }

            ToolButton{
                action: Action{
                    icon.source: "assets/rightArrow.png"
                    enabled: view.forwardEnabled
                    onTriggered: view.forward()
                }

                ToolTip.visible: enabled && hovered
                ToolTip.delay: 2000
                ToolTip.text: "goo forward"
            }

            ToolButton{
                action: Action{
                    shortcut: StandardKey.SelectAll
                    icon.source: "assets/selection.png"
                    onTriggered: {
                        view.selectAll()
                    }
                }
            }

            ToolButton{
                action: Action{
                    shortcut: StandardKey.Copy
                    icon.source: "assets/copySymbol.png"
                    enabled: view.selectedText !== ""
                    onTriggered: {
                        view.copySelectionToClipboard()
                    }
                }
            }

            Shortcut{
                sequence: StandardKey.Find
                onActivated: {
                    searchField.forceActiveFocus()
                    searchField.selectAll()
                }
            }

            Shortcut{
                sequence: StandardKey.Quit
                onActivated: Qt.quit()
            }
        }
    }

    FileDialog{
        id: fileDialog
        title: "Open a PDF file"
        nameFilters: [ "PDF files (*.pdf)" ]
        onAccepted: doc.source = selectedFile
    }

    Dialog{
        id: passwordDialog
        title: "Password"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent
        width: 300

        contentItem: TextField{
            id: passwordTextField
            placeholderText: qsTr("Please provide the password")
            echoMode: TextInput.Password
            width: parent.width
            onAccepted: passwordDialog.accept()
        }

        onOpened: passwordTextField.forceActiveFocus()
        onAccepted: doc.password = passwordTextField.text
    }

    Dialog{
        id: errrorDialog
        title: "Error loading " + doc.source
        standardButtons: Dialog.Close
        modal: true
        closePolicy: Popup.CloseOnEscape
        width: 300
        anchors.centerIn: parent
        visible: doc.status == PdfDocument.Error

        contentItem: Label{
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
                       doc.source = drop.urls[0]
                       drop.acceptProposedAction()
                   }
    }


    PdfDocument{
        id: doc
        source: Qt.resolvedUrl(root.source)
        onPasswordRequired: passwordDialog.open()
    }

    PdfMultiPageView{
        id: view
        anchors.fill: parent
        anchors.leftMargin: sideBar.position * sideBar.width
        document: doc
        searchString: searchField.text
        onCurrentPageChanged: currentPageSB.value = view.currentPage +1
    }

    Drawer{
        id: sideBar
        edge: Qt.LeftEdge
        modal: false
        width: 300
        y: root.header.height
        height: view.height
        dim: false
        clip: true


        TabBar{
            id: sideBarTabs
            x: -width
            rotation: -90
            transformOrigin: Item.TopRight
            currentIndex: 2 //bookmarks by default

            TabButton{
                text: qsTr("Info")
            }

            TabButton{
                text: qsTr("Search Results")
            }

            TabButton{
                text: qsTr("Bookmarks")
            }

            TabButton{
                text: qsTr("Pages")
            }
        }

        GroupBox{
            anchors.fill: parent
            anchors.left: sideBarTabs.right

            StackLayout{
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

                ListView{
                    id: searchResultList
                    implicitHeight: parent.height
                    model: view.searchModel
                    currentIndex:  view.searchModel.currentResult
                    ScrollBar.vertical: ScrollBar{}

                    delegate: ItemDelegate {
                        id: resultDelegate
                        required property int index
                        required property int page
                        required property string contextBefore
                        required property string contextAfter
                        width: parent ? parent.width : 0

                        RowLayout{
                            anchors.fill: parent
                            spacing: 0

                            Label{
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

                TreeView{
                    id: bookmarksTree
                    implicitHeight: parent.height
                    implicitWidth: parent.width
                    columnWidthProvider: function (){
                        return width
                    }

                    delegate: TreeViewDelegate{
                        required property int page
                        required property point  location
                        required property real zoom

                        onClicked: view.goToLocation(page, location, zoom)
                    }

                    model: PdfBookmarkModel{
                        document: doc
                    }

                    ScrollBar.vertical: ScrollBar{}
                }

                GridView{
                    id: thumbnailsView
                    implicitHeight: parent.implicitHeight
                    implicitWidth: parent.implicitWidth
                    model: doc.pageModel
                    cellWidth: width/ 2
                    cellHeight: cellWidth + 10

                    delegate: Item{
                        required property int  index
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
                            PdfPageImage{
                                id: image
                                document: doc
                                currentFrame: index
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit

                                property bool landscape: pointSize.width > pointSize.height


                                width: landscape ? thumbnailsView.cellWidth - 6
                                                 : height * pointSize.width / pointSize.height
                                height: landscape ? width * pointSize.height / pointSize.width
                                                  : thumbnailsView.cellHeight - 14
                                sourceSize.width: width
                                sourceSize.height: height
                            }
                        }

                        Text {
                            id: pageNumber
                            anchors.bottom:  parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: label
                        }

                        TapHandler{
                            onTapped:{
                                view.goToPage(index)
                            }
                        }
                    }
                }
            }
        }
    }

    footer: ToolBar{
        height: footerRow.implicitHeight + 6

        RowLayout{
            id: footerRow
            anchors.fill: parent
            ToolButton{
                action: Action {
                    id: sideBarOpenAction
                    checkable: true
                    checked: sideBar.opened
                    icon.source: checked ? "assets/leftArrow.png" : "assets/rightArrow.png"
                    onTriggered: {
                        sideBar.open()
                    }
                }

                ToolTip.visible: enabled  && hovered
                ToolTip.delay: 2000
                ToolTip.text: "open sidebar"
            }

            ToolButton {
                action: Action{
                    icon.source: "assets/leftArrow.png"
                    shortcut: StandardKey.FindPrevious
                    enabled: view.searchModel > 0
                    onTriggered: {
                        view.searchBack()
                    }
                }

                ToolTip.visible: enabled && hovered
                ToolTip.delay: 2000
                ToolTip.text: "find previous"
            }

            TextField {
                id: searchField
                placeholderText: "search"

                Layout.minimumWidth: 150
                Layout.fillWidth: true
                Layout.bottomMargin: 3

                onAccepted: {
                    sideBar.open()
                    sideBarTabs.setCurrentIndex(1)
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
                    TapHandler {
                        onTapped: searchField.clear()
                    }
                }
            }

            ToolButton {
                action: Action {
                    icon.source: "assets/rightArrow.png"
                    shortcut: StandardKey.FindNext
                    enabled: view.searchModel.count > 0
                    onTriggered: view.searchForward()
                }
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 2000
                ToolTip.text: "find next"
            }

            Label {
                id: statusLabel
                property size implicitPointSize: doc.pagePointSize(view.currentPage)
                text: "page " + (currentPageSB.value) + " of " + doc.pageCount +
                      " scale " + view.renderScale.toFixed(2) +
                      " original " + implicitPointSize.width.toFixed(1) + "x" + implicitPointSize.height.toFixed(1) + " pt"
                visible: doc.pageCount > 0
            }
        }
    }
}












