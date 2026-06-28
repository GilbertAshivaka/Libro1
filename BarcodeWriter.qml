import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import WriteBarcode 1.0

/*
  barcodeWriter is expected to be set as a rootContext property pointing to
  BarcodeWriter::instance(), e.g.:
      engine.rootContext()->setContextProperty("barcodeWriter", BarcodeWriter::instance());

  If you register it as a QML creatable type instead, uncomment the WriteBarcode{} block below.
*/

Page {
    id: barcodeWriterPage
    title: "Barcode Writer"
    anchors.fill: parent

    signal closeClicked()

    // ── Accent colours ──────────────────────────────────────
    readonly property color accentColor:   "#3498DB"
    readonly property color successColor:  "#27AE60"
    readonly property color errorColor:    "#E74C3C"
    readonly property color bgColor:       "#F7F9FC"
    readonly property color cardColor:     "#FFFFFF"
    readonly property color borderColor:   "#DEE2E6"
    readonly property color textPrimary:   "#2C3E50"
    readonly property color textSecondary: "#5D6D7E"

    // Block clicks from leaking to screens below
    MouseArea { anchors.fill: parent }

    // ── Close button ────────────────────────────────────────
    Rectangle {
        id: closeBtn
        width: 80; height: 32; radius: 25; z: 3
        border.color: "#878585"; border.width: 2; clip: true
        anchors { top: parent.top; topMargin: 10; right: parent.right; rightMargin: 30 }

        Text {
            id: closeBtnTxt; anchors.centerIn: parent
            text: "Close"; font.pixelSize: 16; font.bold: true
        }

        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onEntered: { closeBtn.color = "#878585"; closeBtnTxt.color = "white" }
            onExited:  { closeBtn.color = "white";   closeBtnTxt.color = "#878585" }
            onClicked: closeClicked()
        }
    }

    // ── Main scrollable content ─────────────────────────────
    ScrollView {
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // ════════════════════════════════════════════════
            //  SECTION 1 — Single Barcode Generation
            // ════════════════════════════════════════════════
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "Single Barcode Generation"

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    // ── Input mode switch ───────────────────
                    Label {
                        text: "Input Mode"
                        font.bold: true; color: textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        RadioButton {
                            id: rbBarcodeText
                            text: "Enter Barcode Text"
                            checked: true
                        }
                        RadioButton {
                            id: rbCallNumber
                            text: "Lookup by Call Number"
                        }
                    }

                    // ── Barcode text input ──────────────────
                    Label {
                        text: rbBarcodeText.checked ? "Barcode Text:" : "Call Number:"
                        font.bold: true; color: textPrimary
                    }

                    TextField {
                        id: singleInputField
                        Layout.fillWidth: true
                        placeholderText: rbBarcodeText.checked
                            ? "Enter the barcode text to encode..."
                            : "Enter the call number to look up..."
                    }

                    // ── Extra fields visible only in barcode-text mode ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: rbBarcodeText.checked

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "Book Title (optional):"; font.bold: true; color: textPrimary }
                            TextField {
                                id: singleTitleField
                                Layout.fillWidth: true
                                placeholderText: "Title for filename..."
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Label { text: "Author (optional):"; font.bold: true; color: textPrimary }
                            TextField {
                                id: singleAuthorField
                                Layout.fillWidth: true
                                placeholderText: "Author surname..."
                            }
                        }
                    }

                    // ── Include text under barcode toggle ───
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Include text under barcode:"; Layout.fillWidth: true; color: textPrimary }
                        Switch { id: includeTextSwitch; checked: true }
                    }

                    // ── Generate button ─────────────────────
                    Button {
                        text: rbBarcodeText.checked ? "Generate Barcode" : "Lookup & Generate"
                        highlighted: true
                        Layout.fillWidth: true
                        enabled: singleInputField.text.trim() !== ""
                        onClicked: {
                            if (rbBarcodeText.checked) {
                                barcodeWriter.writeAndSaveBarcode(
                                    "Code128",
                                    singleInputField.text.trim(),
                                    singleTitleField.text.trim(),
                                    singleAuthorField.text.trim(),
                                    includeTextSwitch.checked
                                )
                            } else {
                                barcodeWriter.generateFromCallNumber(
                                    singleInputField.text.trim()
                                )
                            }
                        }
                    }

                    // ── Barcode preview ─────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 220
                        color: "#FAFAFA"
                        radius: 8
                        border.color: borderColor; border.width: 1
                        visible: barcodeWriter.imageUrl !== ""

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 5

                            Label {
                                text: "Preview"
                                font.bold: true; font.pixelSize: 12; color: textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Image {
                                id: barcodePreviewImage
                                source: barcodeWriter.imageUrl
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                fillMode: Image.PreserveAspectFit
                                cache: false
                            }
                        }
                    }
                }
            }

            // ════════════════════════════════════════════════
            //  SECTION 2 — Output Settings
            // ════════════════════════════════════════════════
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "Output Settings"

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    // ── Output folder ───────────────────────
                    Label { text: "Output Folder:"; font.bold: true; color: textPrimary }

                    RowLayout {
                        Layout.fillWidth: true

                        TextField {
                            id: outputFolderField
                            Layout.fillWidth: true
                            text: barcodeWriter.outputFolder
                            readOnly: true
                        }

                        Button {
                            text: "Browse..."
                            onClicked: folderDialog.open()
                        }
                    }

                    Label {
                        text: "Barcodes will be saved as PNG images in this folder."
                        font.pixelSize: 10; color: textSecondary
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                    }

                    // ── Filename naming mode ────────────────
                    Label { text: "Filename Convention:"; font.bold: true; color: textPrimary }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        RadioButton {
                            id: rbNameBarcode
                            text: "BookTitle_BarcodeText.png"
                            checked: barcodeWriter.namingMode === 0
                            onCheckedChanged: if (checked) barcodeWriter.namingMode = 0
                        }

                        RadioButton {
                            id: rbNameCallNumber
                            text: "BookTitle_CallNumber.png"
                            checked: barcodeWriter.namingMode === 1
                            onCheckedChanged: if (checked) barcodeWriter.namingMode = 1
                        }
                    }
                }
            }

            // ════════════════════════════════════════════════
            //  SECTION 3 — Bulk Barcode Generation
            // ════════════════════════════════════════════════
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: 20
                title: "Bulk Barcode Generation"

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    Label {
                        text: "Generate barcodes for all books added within a date range. "
                            + "This runs in the background so you can continue using the app."
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        font.pixelSize: 12; color: textSecondary
                    }

                    // ── Date range inputs ───────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        ColumnLayout {
                            Layout.fillWidth: true

                            Label { text: "From Date:"; font.bold: true; color: textPrimary }
                            TextField {
                                id: bulkFromDate
                                Layout.fillWidth: true
                                placeholderText: "DD-MM-YYYY"
                                inputMask: "99-99-9999"
                                // validator: RegularExpressionValidator {
                                //     regularExpression: /^(0[1-9]|[12]\d|3[01])-(0[1-9]|1[0-2])-\d{4}$/
                                // }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            Label { text: "To Date (leave empty for today):"; font.bold: true; color: textPrimary }
                            TextField {
                                id: bulkToDate
                                Layout.fillWidth: true
                                placeholderText: "DD-MM-YYYY"
                                inputMask: "99-99-9999"
                                // validator: RegularExpressionValidator {
                                //     regularExpression: /^(0[1-9]|[12]\d|3[01])-(0[1-9]|1[0-2])-\d{4}$/
                                // }
                            }
                        }
                    }

                    // ── PDF sheet toggle ────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Also generate a printable PDF sheet:"
                            Layout.fillWidth: true
                            color: textPrimary
                        }
                        Switch { id: pdfSwitch; checked: false }
                    }

                    Label {
                        text: "The PDF will contain all barcodes arranged in a 3-column grid, ideal for printing on label sheets."
                        font.pixelSize: 10; color: textSecondary
                        wrapMode: Text.WordWrap; Layout.fillWidth: true
                        visible: pdfSwitch.checked
                    }

                    // ── Progress display ────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: bulkProgressColumn.height + 20
                        color: {
                            if (barcodeWriter.bulkRunning) return "#E3F2FD"
                            if (barcodeWriter.statusMessage.includes("Done")) return "#E8F5E9"
                            if (barcodeWriter.statusMessage.includes("failed") ||
                                barcodeWriter.statusMessage.includes("Invalid") ||
                                barcodeWriter.statusMessage.includes("No book")) return "#FFEBEE"
                            return "#F5F5F5"
                        }
                        radius: 8
                        visible: barcodeWriter.statusMessage !== ""

                        ColumnLayout {
                            id: bulkProgressColumn
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 12
                            spacing: 8

                            Label {
                                text: barcodeWriter.statusMessage
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                font.italic: true
                                horizontalAlignment: Text.AlignHCenter
                                color: textPrimary
                            }

                            ProgressBar {
                                Layout.fillWidth: true
                                visible: barcodeWriter.bulkRunning
                                from: 0
                                to: barcodeWriter.bulkTotal > 0 ? barcodeWriter.bulkTotal : 1
                                value: barcodeWriter.bulkProgress
                                indeterminate: barcodeWriter.bulkTotal === 0 && barcodeWriter.bulkRunning
                            }

                            Label {
                                visible: barcodeWriter.bulkRunning && barcodeWriter.bulkTotal > 0
                                text: barcodeWriter.bulkProgress + " / " + barcodeWriter.bulkTotal
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                font.pixelSize: 11; color: textSecondary
                            }
                        }
                    }

                    // ── Action buttons ──────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: "Generate Barcodes"
                            highlighted: true
                            Layout.fillWidth: true
                            enabled: !barcodeWriter.bulkRunning
                                     && bulkFromDate.text.replace(/-/g, "").trim() !== ""
                            onClicked: {
                                barcodeWriter.generateBulkBarcodes(
                                    bulkFromDate.text.trim(),
                                    bulkToDate.text.replace(/-/g, "").trim() === ""
                                        ? ""
                                        : bulkToDate.text.trim(),
                                    pdfSwitch.checked
                                )
                            }
                        }

                        Button {
                            text: "Cancel"
                            Layout.fillWidth: true
                            enabled: barcodeWriter.bulkRunning
                            onClicked: barcodeWriter.cancelBulk()
                        }
                    }
                }
            }

            // Bottom spacer
            Item { Layout.preferredHeight: 20 }
        }
    }

    // ── Folder dialog ───────────────────────────────────────
    FolderDialog {
        id: folderDialog
        title: "Select Output Folder"
        currentFolder: "file:///" + barcodeWriter.outputFolder

        onAccepted: {
            barcodeWriter.outputFolder = selectedFolder.toString()
            outputFolderField.text = barcodeWriter.outputFolder
        }
    }

    // ── Message dialog ──────────────────────────────────────
    Dialog {
        id: messageDialog
        property alias text: messageLabelText.text
        anchors.centerIn: parent
        modal: true; standardButtons: Dialog.Ok

        Text {
            id: messageLabelText
            color: textSecondary; text: ""
            wrapMode: Text.WordWrap; width: 400
        }
    }

    // ── Signal handlers ─────────────────────────────────────
    Connections {
        target: barcodeWriter

        function onBarcodeSaved(filePath) {
            // Force image reload by busting cache
            barcodePreviewImage.source = ""
            barcodePreviewImage.source = barcodeWriter.imageUrl
        }

        function onErrorOccurred(error) {
            messageDialog.title = "Error"
            messageDialog.text = error
            messageDialog.open()
        }

        function onBulkFinished(count) {
            messageDialog.title = "Bulk Generation Complete"
            messageDialog.text = count + " barcode(s) generated successfully."
            messageDialog.open()
        }
    }
}












