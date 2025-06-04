import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import com.bookImporter 1.0
import com.databaseManager 1.0

Rectangle {
    id: importBooksPage
    anchors.fill: parent
    radius: 8
    color: "#DDDDDD"
    focus: true

    signal closeClicked()

    MouseArea {
        anchors.fill: parent
        onDoubleClicked: {
            fileDialog.open()
        }
    }

    BookImporter {
        id: bookImporter
    }

    DatabaseManager {
        id: dbManager
    }

    // Open the fileDialog when Ctrl+O is pressed
    Shortcut {
        sequence: "Ctrl+O"
        onActivated: {
            fileDialog.open()
        }
    }

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
                importBooksPage.closeClicked()
            }
        }
    }

    Rectangle {
        id: addRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors {
            right: parent.right
            rightMargin: 10
            top: parent.top
            topMargin: 10
        }

        Rectangle {
            id: addImageRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"

            Image {
                id: close
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/plus.png"
            }
        }

        MouseArea {
            id: addMA
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                addRect.color = "#E8E3E4"
            }
            onExited: {
                addRect.color = "#DDDDDD"
            }
            onClicked: {
                fileDialog.open()
            }
        }
    }

    Rectangle {
        id: menuRect
        width: 60
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors {
            right: addRect.left
            verticalCenter: addRect.verticalCenter
        }

        Image {
            id: menuImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "assets/menu.png"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                menuRect.color = "#E8E3E4"
            }
            onExited: {
                menuRect.color = "#DDDDDD"
            }

            onClicked: {
                menu.open()
            }
        }

        Menu {
            id: menu
            width: 150
            y: menuRect.height

            MenuItem {
                text: "Detailed guide"
                // Provide functionality if needed
            }
            MenuItem {
                text: "Help"
                // Provide functionality if needed
            }
        }
    }

    Rectangle {
        id: instructions
        width: parent.width * 0.5
        height: parent.height * 0.6
        color: "#DDDDDD"
        anchors.centerIn: parent

        // Visual for dragging
        Rectangle {
            id: dragIndicator
            anchors.fill: parent
            color: "#8E8E8E"
            opacity: 0
            radius: 8

            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 20
                }
                text: "Drop CSV file here"
                color: "white"
                font.pixelSize: 20
                font.bold: true
            }
        }

        Rectangle {
            id: titleBar
            width: parent.width
            height: 40
            color: "#CECED7"

            Text {
                id: titleText
                text: "Import Books In One Go"
                anchors.centerIn: parent
                font.bold: true
                font.pixelSize: 16
                color: "#8E8E8E"
            }

            Rectangle {
                id: underline
                width: titleText.width + 10
                height: 2
                color: "#8E8E8E"
                anchors.top: titleText.bottom
                anchors.horizontalCenter: titleText.horizontalCenter
                anchors.topMargin: 2
            }
        }

        ListView {
            id: listView
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 5
            interactive: false

            model: [
                "**• Supported format:** Import data using a **.csv file**. You can create this file in Ms Excel or any other spreadsheet application that supports saving as CSV.",
                "**• File structure:** Each column in the data should represent one book with attributes such as **Title, Author, ISBN, etc.**. Ensure each value is comma separated.",
                "**• How to obtain data:**",
                " - Open a spreadsheet application (e.g., Excel).",
                " - Enter book details in separate columns (Title, Author, ISBN, etc.).",
                " - Save the file as CSV (Comma delimited) (.csv) format.",
                "**• Adding Books:**",
                " - Click the '+' button in the top right corner to select a file and start the import process.",
                " - Double-click anywhere on this page to quickly re-open the file selection dialog.",
                "**• Error handling:**",
                " - Ensure your CSV file has no blank rows and follows the correct structure.",
                " - If an error occurs during import, review your file format and structure, then try again.",
                "**• Keyboard shortcuts:**",
                " - Ctrl + O: Open file dialog directly from the keyboard."
            ]

            delegate: Text {
                text: modelData
                color: "#8E8E8E"
                wrapMode: Text.Wrap
                width: parent.width
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: 8
                }
                textFormat: Text.MarkdownText
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }
    }

    // ProgressBar to show import progress
    ProgressBar {
        id: importProgress
        width: parent.width * 0.8
        height: 6
        anchors {
            bottom: parent.bottom
            bottomMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
        value: 0
        from: 0
        to: 100
        visible: value > 0 && value < 100

        Text {
            anchors {
                bottom: parent.top
                bottomMargin: 5
                horizontalCenter: parent.horizontalCenter
            }
            text: Math.round(importProgress.value) + "%"
            color: "#8E8E8E"
            visible: importProgress.visible
        }
    }

    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFile
        title: "Open File"
        currentFolder: "file:///C:/Users/Admin/Downloads"
        nameFilters: ["CSV files (*.csv)", "All files (*)"]
        onAccepted: {
            var filePath = fileDialog.currentFile.toString().replace("file:///", "")
            startImportProcess(filePath)
        }
        onRejected: {
            addMA.enabled = true
            backMA.enabled = true
        }
    }

    // Function to handle the import process
    function startImportProcess(filePath) {
        // Check if it's a CSV file
        if (filePath.toLowerCase().endsWith(".csv")) {
            backMA.enabled = false
            addMA.enabled = false
            importProgress.value = 0
            importProgress.visible = true
            bookImporter.startImport(filePath)
        } else {
            errorDialog.text = "Please select a CSV file."
            errorDialog.open()
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: (drag) => {
            drag.accepted = drag.hasUrls
            if (drag.accepted) {
                dragIndicator.opacity = 0.3
            }
        }

        onExited: {
            dragIndicator.opacity = 0
        }

        onDropped: (drop) => {
            dragIndicator.opacity = 0
            fileDialog.close()

            if (drop.hasUrls) {
                var fileUrl = drop.urls[0]
                var filePath = bookImporter.urlToLocalFile(fileUrl)
                startImportProcess(filePath)
            }
        }
    }

    Dialog {
        id: errorDialog
        title: "Error"
        property alias text: errorLabel.text
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Text {
            id: errorLabel
            color: "#8E8E8E"
        }
    }

    Connections {
        target: bookImporter

        function onImportProgress(progress) {
            importProgress.value = progress
        }

        function onImportCompleted(successCount, failCount) {
            backMA.enabled = true
            addMA.enabled = true
            importProgress.visible = false

            // Show completion dialog
            if (failCount === 0) {
                errorDialog.title = "Success"
                errorDialog.text = `Successfully imported ${successCount} books.`
            } else {
                errorDialog.title = "Import Complete"
                errorDialog.text = `Imported ${successCount} books successfully.\n${failCount} books failed to import.`
            }
            errorDialog.open()
        }

        function onImportError(error) {
            backMA.enabled = true
            addMA.enabled = true
            importProgress.visible = false

            errorDialog.title = "Error"
            errorDialog.text = error
            errorDialog.open()
        }
    }

//    Button{
//        id: deleteButton
//        text: "Delete Database"
//        anchors{
//            right: parent.right
//            bottom: parent.bottom
//            rightMargin: 20
//            bottomMargin: 20
//        }
//        onClicked: {
//            dbManager.deleteTables()
//        }
//    }

    Component.onCompleted: {
        // Optionally, perform any initialization for books here.
    }
}

