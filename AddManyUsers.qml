import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

Rectangle{
    id: manyUsersPage
    anchors.fill: parent
    radius: 8
    color: "#DDDDDD"

    signal closeClicked()

    MouseArea{
        anchors.fill: parent
        onDoubleClicked: {
            fileDialog.open()
        }
    }

    Rectangle{
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors{
            left: parent.left
            leftMargin: 10
            top: parent.top
            topMargin: 10
        }

        Rectangle{
            id: backBtnRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"

            Image{
                id: back
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/backArrow.png"
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
                manyUsersPage.closeClicked()
            }
        }
    }


    Rectangle{
        id: addRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors{
            right: parent.right
            rightMargin: 10
            top: parent.top
            topMargin: 10
        }

        Rectangle{
            id: addImageRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"

            Image{
                id: close
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/plus.png"
            }
        }

        MouseArea{
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
        id: instructions
        width: parent.width*.5
        height: parent.height* .6
        color: "#DDDDDD"
        anchors.centerIn: parent

        Rectangle {
            id: titleBar
            width: parent.width
            height: 40
//            color: "gray"
            color: "#CECED7"

            Text {
                id: titleText
                text: "Open a document"
                anchors.centerIn: parent
                font.bold: true
                font.pixelSize: 16
                color: "#8E8E8E"  // Cool gray color
            }

            Rectangle {
                id: underline
                width: titleText.width + 10  // some extra width for spacing
                height: 2
                color: "#8E8E8E"  // Cool gray color
                anchors.top: titleText.bottom
                anchors.horizontalCenter: titleText.horizontalCenter
                anchors.topMargin: 2  // spacing between text and underline
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
                "• Supported format: Import data using a .csv file. You can create this file in Ms Excel or any other spreadsheet application that supports saving as CSV",
                "• File structure:  Each colums in the data should represent one user with attibutes such as name, email e.t.c. Ensure each value is comma separated.",
                "• How to obtain data: ",
                "  - Open a spreadsheet application (e.g., Excel).",
                "  - Enter user details in separate columns (Name, Email, User ID).",
                "  - Save the file as CSV (Comma delimited) (.csv) format.",
                "• Adding Users: ",
                "  - Click the "+" button in the top right corner to select a file and start the import process.",
                "  - Double-click anywhere on this page to quickly re-open the file selection dialog.",
                "• Error handling: ",
                "  - Ensure your CSV file has no blank rows and follows the correct structure.",
                "  - If an error occurs during import, review your file format and structure, then try again.",
                "• Keyboard shotcuts: ",
                "  - Ctrl + O: Open file dialog directly from the keyboard."
            ]

            delegate: Text {
                text: modelData
                color: "#8E8E8E"  // Cool gray color
                wrapMode: Text.Wrap
            }
        }
    }

    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFile
        title: "Open File"
        currentFolder: "file:///C:/Users/Admin/Downloads" // Set initial folder
        nameFilters: ["Text files (*.txt)", "All files (*)"] // Set file filters
        onAccepted: {
//            console.log("Selected file:", fileDialog.currentFile)
            var filePath = fileDialog.currentFile
            filePath =filePath.toString().replace("file:///", "")
            console.log("Selected file:", filePath)
            // Handle the selected file(s) here
        }
        onRejected: {
            console.log("Dialog Rejected")
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent

        onDropped: {
            // Handle the dropped file(s)
            if (dropArea.data.length > 0) {
                var filePath = dropArea.data[0].toString().replace("file:///", "");
                console.log("Dropped file:", filePath);

                // Check if the dropped file is a CSV file
                if (filePath.endsWith(".csv")) {
                    console.log("CSV file dropped:", filePath);
                    // Trigger your process for CSV files here
                    // For example:
                    // processCSVFile(filePath);
                } else {
                    console.log("Unsupported file dropped:", filePath);
                    // Handle unsupported file types here
                }
            } else {
                console.log("No file dropped");
            }
        }
    }
}
