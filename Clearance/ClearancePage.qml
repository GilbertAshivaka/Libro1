import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import com.clearanceManager

Rectangle {
    id: clearancePage
    color: "#f5f5f5"
    anchors.fill: parent

    signal closeClicked()

    //mouseArea to prevent clicks from leaking to components underneath the page
    MouseArea{
        id: clearancePageMA
        anchors.fill: parent
    }

    ClearanceManager{
        id: clearanceManager
    }

    // property var clearanceManager: clearanceManager
    property int currentAdminId: 1 // This should be passed from your main application

    // Connect to clearanceManager error signal
    Connections {
        target: clearanceManager
        function onErrorOccurred(error) {
            errorDialog.text = error
            errorDialog.open()
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "white" //"#2c3e50"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "Library Clearance System"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#878585"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Text {
                    //     text: "Process user clearance for library exit"
                    //     font.pixelSize: 14
                    //     color: "#B3B1B1"
                    //     Layout.alignment: Qt.AlignHCenter
                    // }
                }

                // Back button
                Rectangle {
                    id: backBtn
                    width: 80
                    height: 32
                    radius: 25
                    border.color: "#878585"
                    border.width: 2
                    clip: true
                    z: 3
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: 20
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onEntered: {
                            backBtn.color = "#878585"
                            parent.children[0].color = "white"
                        }
                        onExited: {
                            backBtn.color = "white"
                            parent.children[0].color = "#878585"
                        }
                        onClicked: closeClicked()
                    }
                }
            }

            // User Input Section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: inputColumn.height + 40
                color: "white"
                radius: 8
                border.color: "#bdc3c7"
                border.width: 1

                ColumnLayout {
                    id: inputColumn
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    Text {
                        text: "User Information"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#2c3e50"
                    }

                    // User Type Selection
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "User Type:"
                            font.pixelSize: 14
                            Layout.preferredWidth: 120
                        }

                        ComboBox {
                            id: userTypeCombo
                            Layout.fillWidth: true
                            model: ["student", "staff", "other_user"]
                            currentIndex: 0

                            onCurrentTextChanged: {
                                userNumberField.placeholderText = currentText === "student" ? "Enter Admission Number" :
                                                                  currentText === "staff" ? "Enter Staff Number" :
                                                                  "Enter User Number"
                            }
                        }
                    }

                    // User Number Input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: userTypeCombo.currentText === "student" ? "Admission No:" :
                                  userTypeCombo.currentText === "staff" ? "Staff No:" : "User No:"
                            font.pixelSize: 14
                            Layout.preferredWidth: 120
                        }

                        TextField {
                            id: userNumberField
                            Layout.fillWidth: true
                            placeholderText: "Enter Admission Number"
                            font.pixelSize: 14
                        }
                    }

                    // User Name Input (Optional for verification)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "User Name:"
                            font.pixelSize: 14
                            Layout.preferredWidth: 120
                        }

                        TextField {
                            id: userNameField
                            Layout.fillWidth: true
                            placeholderText: "Enter user name (optional)"
                            font.pixelSize: 14
                        }
                    }

                    // Process Button
                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 50
                        text: clearanceManager && clearanceManager.isProcessing ? "Processing..." : "Process Clearance"
                        enabled: userNumberField.text.length > 0 &&
                                clearanceManager && !clearanceManager.isProcessing

                        background: Rectangle {
                            color: parent.enabled ? (parent.pressed ? "#2980b9" : "#3498db") : "#95a5a6"
                            radius: 6
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if (clearanceManager) {
                                clearanceManager.processClearance(
                                    userNameField.text,
                                    userNumberField.text,
                                    userTypeCombo.currentText,
                                    currentAdminId
                                )
                            }
                        }
                    }
                }
            }


            // Results Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: resultsCol.height + 24
                color: "white"
                radius: 10
                visible: clearanceManager.clearanceStatus !== "idle"

                //a fix to prevent mouse leakage
                MouseArea{
                    id: resultsMA
                    anchors.fill: parent
                }

                ColumnLayout {
                    id: resultsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 10

                    // Status Badge
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 8
                        color: clearanceManager.clearanceStatus === "approved" ? "#d4edda" :
                                                                                 clearanceManager.clearanceStatus === "rejected" ? "#f8d7da" : "#fff3cd"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: clearanceManager.clearanceStatus === "approved" ? "✓" :
                                                                                        clearanceManager.clearanceStatus === "rejected" ? "✗" : "⟳"
                                font.pixelSize: 16
                                font.bold: true
                                color: clearanceManager.clearanceStatus === "approved" ? "#155724" :
                                                                                         clearanceManager.clearanceStatus === "rejected" ? "#721c24" : "#856404"
                            }

                            Text {
                                text: clearanceManager.clearanceStatus === "approved" ? "APPROVED" :
                                                                                        clearanceManager.clearanceStatus === "rejected" ? "REJECTED" : "PROCESSING"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: clearanceManager.clearanceStatus === "approved" ? "#155724" :
                                                                                         clearanceManager.clearanceStatus === "rejected" ? "#721c24" : "#856404"
                            }
                        }
                    }

                    // User Info Grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 4
                        columnSpacing: 8

                        Text { text: "Name"; font.pixelSize: 11; color: "#8e8e93" }
                        Text {
                            text: clearanceManager.clearanceResult.user_name || "-"
                            font.pixelSize: 11; color: "#1c1c1e"
                            elide: Text.ElideRight
                        }
                        Text { text: "ID"; font.pixelSize: 11; color: "#8e8e93" }
                        Text {
                            text: clearanceManager.clearanceResult.user_number || "-"
                            font.pixelSize: 11; color: "#1c1c1e"
                        }

                        Text { text: "Type"; font.pixelSize: 11; color: "#8e8e93" }
                        Text {
                            text: (clearanceManager.clearanceResult.user_type || "-").toUpperCase()
                            font.pixelSize: 11; color: "#1c1c1e"
                        }
                        Text { text: "Date"; font.pixelSize: 11; color: "#8e8e93" }
                        Text {
                            text: clearanceManager.clearanceResult.clearance_date || "-"
                            font.pixelSize: 11; color: "#1c1c1e"
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#e5e5ea"
                    }

                    // Checks Section
                    Text {
                        text: "Clearance Checks"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#1c1c1e"
                    }

                    // Compact Check Items
                    ClearanceCheckItem {
                        Layout.fillWidth: true
                        checkTitle: "Borrowed Books"
                        checkData: clearanceManager.clearanceResult.borrowed_books
                        detailsType: "books"
                    }

                    ClearanceCheckItem {
                        Layout.fillWidth: true
                        checkTitle: "Digital Materials"
                        checkData: clearanceManager.clearanceResult.digital_materials
                        detailsType: "materials"
                    }

                    ClearanceCheckItem {
                        Layout.fillWidth: true
                        checkTitle: "Lost Books"
                        checkData: clearanceManager.clearanceResult.lost_books
                        detailsType: "lost"
                    }

                    ClearanceCheckItem {
                        Layout.fillWidth: true
                        checkTitle: "Unpaid Fines"
                        checkData: clearanceManager.clearanceResult.unpaid_fines
                        detailsType: "fines"
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#e5e5ea"
                    }

                    // Action Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // HTML Receipt
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 6
                            color: clearanceManager.clearanceStatus === "approved" ?
                                       (htmlMA.containsMouse ? "#218838" : "#28a745") : "#c8c8c8"

                            Text {
                                anchors.centerIn: parent
                                text: "HTML"
                                font.pixelSize: 12
                                color: "white"
                            }

                            MouseArea {
                                id: htmlMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: clearanceManager.clearanceStatus === "approved"
                                onClicked: {
                                    var html = clearanceManager.generateHTMLReceipt(clearanceManager.clearanceResult)
                                    htmlDialog.htmlContent = html
                                    htmlDialog.open()
                                }
                            }
                        }

                        // QML Receipt
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 6
                            color: clearanceManager.clearanceStatus === "approved" ?
                                       (qmlMA.containsMouse ? "#7b2cbf" : "#9b59b6") : "#c8c8c8"

                            Text {
                                anchors.centerIn: parent
                                text: "Receipt"
                                font.pixelSize: 12
                                color: "white"
                            }

                            MouseArea {
                                id: qmlMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: clearanceManager.clearanceStatus === "approved"
                                onClicked: qmlReceiptDialog.open()
                            }
                        }

                        // Complete & Remove User (only when approved)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 6
                            color: clearanceManager.clearanceStatus === "approved" ?
                                       (completeMA.containsMouse ? "#c82333" : "#dc3545") : "#c8c8c8"
                            visible: clearanceManager.clearanceStatus === "approved"

                            Text {
                                anchors.centerIn: parent
                                text: "Complete"
                                font.pixelSize: 12
                                color: "white"
                            }

                            MouseArea {
                                id: completeMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: clearanceManager.clearanceStatus === "approved"
                                onClicked: confirmDeleteDialog.open()
                            }
                        }

                        // Clear Results
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 6
                            color: clearMA.containsMouse ? "#5a6268" : "#6c757d"

                            Text {
                                anchors.centerIn: parent
                                text: "Clear"
                                font.pixelSize: 12
                                color: "white"
                            }

                            MouseArea {
                                id: clearMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    clearanceManager.clearResult()
                                    userNumberField.text = ""
                                    userNameField.text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // HTML Receipt Dialog
    Dialog {
        id: htmlDialog
        title: "Clearance Receipt (HTML)"
        width: parent.width * 0.8
        height: parent.height * 0.8
        modal: true
        standardButtons: Dialog.Close | Dialog.Save

        property string htmlContent: ""

        ScrollView {
            anchors.fill: parent

            TextArea {
                text: htmlDialog.htmlContent
                readOnly: true
                wrapMode: TextEdit.Wrap
                selectByMouse: true
            }
        }

        onAccepted: {
            // Pass HTML content to file dialog and open it
            fileDialog.htmlToSave = htmlDialog.htmlContent
            fileDialog.open()
        }
    }

    // QML Receipt Dialog
    Dialog {
        id: qmlReceiptDialog
        title: "Clearance Receipt"
        width: parent.width * 0.8
        height: parent.height * 0.9
        modal: true
        standardButtons: Dialog.Close

        ScrollView {
            anchors.fill: parent

            ClearanceReceipt {
                id: clearanceReceipt
                width: qmlReceiptDialog.width - 40
                clearanceData: clearanceManager ? clearanceManager.clearanceResult : null

                Component.onCompleted: {
                    // Add capture button
                    var captureBtn = Qt.createQmlObject('
                        import QtQuick 2.15
                        import QtQuick.Controls 2.15
                        Button {
                            text: "Save as Image"
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 10
                            onClicked: {
                                parent.grabToImage(function(result) {
                                    var path = "clearance_" + Date.now() + ".png"
                                    result.saveToFile(path)
                                    console.log("Receipt saved to:", path)
                                })
                            }
                        }
                    ', qmlReceiptDialog)
                }
            }
        }
    }

    // File Save Dialog
    FileDialog {
        id: fileDialog
        title: "Save Clearance Receipt"
        // selectExisting: false
        nameFilters: ["HTML files (*.html)", "All files (*)"]
        defaultSuffix: "html"

        property string htmlToSave: ""

        onAccepted: {
            if (clearanceManager && htmlToSave.length > 0) {
                var success = clearanceManager.saveHTMLReceipt(fileUrl.toString(), htmlToSave)
                if (success) {
                    console.log("HTML receipt saved successfully to:", fileUrl)
                    // Show success message
                    successDialog.text = "Receipt saved successfully!"
                    successDialog.open()
                } else {
                    // Error is already emitted by C++
                    errorDialog.text = "Failed to save receipt. Check console for details."
                    errorDialog.open()
                }
            }
        }

        onRejected: {
            console.log("File save cancelled")
        }
    }

    // Success Dialog
    Dialog {
        id: successDialog
        title: "Success"
        modal: true
        standardButtons: Dialog.Ok

        property alias text: successText.text

        Text {
            id: successText
            wrapMode: Text.WordWrap
        }
    }

    // Error Dialog
    Dialog {
        id: errorDialog
        title: "Error"
        modal: true
        standardButtons: Dialog.Ok

        property alias text: errorText.text

        Text {
            id: errorText
            wrapMode: Text.WordWrap
            color: "#dc3545"
        }
    }
}
