import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import com.userImporter 1.0
import com.databaseManager 1.0

Rectangle{
    id: manyUsersPage
    anchors.fill: parent
    radius: 8
    color: "#DDDDDD"
    focus: true

    signal closeClicked()

    MouseArea{
        anchors.fill: parent
        onDoubleClicked: {
            fileDialog.open()
        }
    }

    UserImporter{
        id: userImporter
    }

    DatabaseManager{
        id: dbManager
    }

    //open the fileDialog when Ctrl+O is pressed
    Shortcut {
        sequence: "Ctrl+O"
        onActivated: {
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
                source: "assets/backArrow.png"
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
                source: "assets/plus.png"
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

    Rectangle{
        id: menuRect
        width: 60
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors{
            right: addRect.left
            verticalCenter: addRect.verticalCenter
        }

        Image{
            id: menuImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "assets/menu.png"
        }

        MouseArea{
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
            width: changeUserRole.width
            y: menuRect.height

            MenuItem {
                id: changeUserRole
                text: "Change user type"

                onClicked: {
                    rolePopup.open()
                }
            }
            MenuItem {
                text: "Detailed guide"
            }
            MenuItem {
                text: "Help"
//                icon.source: "assets/info3.png"
            }
        }
    }

    Rectangle {
        id: instructions
        width: parent.width*.5
        height: parent.height* .6
        color: "#DDDDDD"
        anchors.centerIn: parent

        //visual for draging
        Rectangle {
            id: dragIndicator
            anchors.fill: parent
            color: "#8E8E8E"
            opacity: 0
            radius: 8

            Text {
                anchors{
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
                "**• Supported format:** Import data using a **.csv file**. You can create this file in Ms Excel or any other spreadsheet application that supports saving as CSV",
                "**• File structure:**  Each colums in the data should represent one user with attibutes such as **name, email e.t.c**. Ensure each value is comma separated.",
                "**• How to obtain data:** ",
                " - Open a spreadsheet application (e.g., Excel).",
                " - Enter user details in separate columns (Name, Email, User ID). Open the menu on the top of this page to see detailed guide of how each user fields should look like.",
                " - Save the file as CSV (Comma delimited) (.csv) format.",
                "**• Adding Users:** ",
                " - Click the "+" button in the top right corner to select a file and start the import process.",
                " - Double-click anywhere on this page to quickly re-open the file selection dialog.",
                "**• Error handling:** ",
                " - Ensure your CSV file has no blank rows and follows the correct structure.",
                " - If an error occurs during import, review your file format and structure, then try again.",
                "**• Keyboard shotcuts:** ",
                " - Ctrl + O: Open file dialog directly from the keyboard."
            ]

            delegate: Text {
                text: modelData
                color: "#8E8E8E"  // Cool gray color
                wrapMode: Text.Wrap
                width: parent.width
                anchors{
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

    //progressBar to show import progress
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
//        visible: true
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
            userImporter.startImport(filePath)
        } else {
            // Show error for invalid file type
            errorDialog.text = "Please select a CSV file."
            errorDialog.open()
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["text/uri-list"]

        onEntered: (drag) =>{ //made a change here
            // Show visual feedback when file is dragged over
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
                // Get the first dropped file
                var fileUrl = drop.urls[0]
                // Convert URL to local file path
                var filePath = userImporter.urlToLocalFile(fileUrl)
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

    Popup{
        id: rolePopup
        width: Math.max(roleSetterBtn.width+popupCancelBtn.width+ 40, 200* (parent.width/1000)) //200* (parent.width/1000)
        height: 300 //100* (parent.width/480)
        anchors.centerIn: parent
        modal: true
        focus: true
        topInset: 8
        leftInset: 8
        rightInset: 8
        bottomInset: 8
        closePolicy: Popup.NoAutoClose

        property string userRole: "Student"

        Rectangle{
            id: roleDisplayRect
            anchors.fill: parent
            clip: true
            radius: 8
            color: "#FBFBFB"

            Text {
                id: roleTitle
                text: qsTr("Please select user role")
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: parent.top
                    topMargin: 10
                }
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pointSize: 12
            }

            ColumnLayout{
                id: roleLayout
                spacing: 10
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: roleTitle.bottom
                    topMargin: 10
                }

                RadioButton{
                    id: studentRadio
                    checked: true
                    text: "Student"
                    onClicked: {
                        rolePopup.userRole = "Student"
                        userImporter.setRole("Student")
                    }
                }
                RadioButton{
                    id: staffRadio
                    text: "Staff"
                    onClicked: {
                        rolePopup.userRole = "Staff"
                        userImporter.setRole("Staff")
                    }
                }
                RadioButton{
                    id: otherUserRadio
                    text: "Other user"
                    onClicked: {
                        rolePopup.userRole = "Other user"
                        userImporter.setRole("Other user")
                    }
                }
            }

            CustomButton{
                id: roleSetterBtn
                text: "Continue"
                anchors{
                    right: parent.right
                    rightMargin: 10
                    top: roleLayout.bottom
                    topMargin: 20
                }

                defaultColor: "#399ED9"
                hoveredColor: "#399ED9"

                onClicked: {
                    console.log("User role: ", rolePopup.userRole)
                    rolePopup.close()
                }
            }

            CustomButton{
                id: popupCancelBtn
                text: "Cancel"
                anchors{
                    right: roleSetterBtn.left
                    rightMargin: 7
                    verticalCenter: roleSetterBtn.verticalCenter
                }
                defaultColor: "#E0E0E0"
                hoveredColor: "#E0E0E0"

                onClicked: {
                    rolePopup.close()
                }
            }
        }

        CustomDropShadow {
            source: roleDisplayRect
            visible: true
            horizontalOffset: -3
            verticalOffset: -3
            samples: 16
        }
    }


    Connections {
        target: userImporter

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
                errorDialog.text = `Successfully imported ${successCount} users.`
            } else {
                errorDialog.title = "Import Complete"
                errorDialog.text = `Imported ${successCount} users successfully.\n${failCount} users failed to import.`
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

    Button{
        id: deleteButton
        text: "Delete Database"
        anchors{
            right: parent.right
            bottom: parent.bottom
            rightMargin: 20
            bottomMargin: 20
        }
        onClicked: {
            dbManager.deleteTables()
        }
    }

    Component.onCompleted: {
        rolePopup.open()
        userImporter.setRole("Student")
    }
}
