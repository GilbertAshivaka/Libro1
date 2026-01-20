import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: receipt

    property var clearanceData: null

    width: 600
    height: receiptColumn.height + 40
    color: "white"
    border.width: 2
    border.color: "#2c3e50"

    ColumnLayout {
        id: receiptColumn
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Header
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Library Management System"
                font.pixelSize: 18
                font.bold: true
                color: "#2c3e50"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Clearance Certificate"
                font.pixelSize: 14
                color: "#3498db"
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#3498db"
                Layout.topMargin: 8
            }
        }

        // Status Banner
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 6
            color: clearanceData && clearanceData.approved ? "#d4edda" : "#f8d7da"

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: clearanceData && clearanceData.approved ? "✓" : "✗"
                    font.pixelSize: 16
                    font.bold: true
                    color: clearanceData && clearanceData.approved ? "#155724" : "#721c24"
                }

                Text {
                    text: clearanceData && clearanceData.approved ? "CLEARANCE APPROVED" : "CLEARANCE REJECTED"
                    font.pixelSize: 14
                    font.bold: true
                    color: clearanceData && clearanceData.approved ? "#155724" : "#721c24"
                }
            }
        }

        // User Information Grid
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 4
            columnSpacing: 12

            Text { text: "Name:"; font.pixelSize: 11; font.bold: true; color: "#2c3e50" }
            Text { text: clearanceData ? clearanceData.user_name || "" : ""; font.pixelSize: 11; color: "#34495e" }
            Text { text: getIdLabel() + ":"; font.pixelSize: 11; font.bold: true; color: "#2c3e50" }
            Text { text: clearanceData ? clearanceData.user_number || "" : ""; font.pixelSize: 11; color: "#34495e" }

            Text { text: "Type:"; font.pixelSize: 11; font.bold: true; color: "#2c3e50" }
            Text { text: clearanceData ? (clearanceData.user_type || "").toUpperCase() : ""; font.pixelSize: 11; color: "#34495e" }
            Text { text: "Date:"; font.pixelSize: 11; font.bold: true; color: "#2c3e50" }
            Text { text: clearanceData ? clearanceData.clearance_date || "" : ""; font.pixelSize: 11; color: "#34495e" }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#e0e0e0"
        }

        // Check Items
        Column {
            Layout.fillWidth: true
            spacing: 4

            ReceiptCheckItem {
                width: parent.width
                checkTitle: "Borrowed Books"
                checkData: clearanceData ? clearanceData.borrowed_books : null
                detailsType: "books"
            }

            ReceiptCheckItem {
                width: parent.width
                checkTitle: "Digital Materials"
                checkData: clearanceData ? clearanceData.digital_materials : null
                detailsType: "materials"
            }

            ReceiptCheckItem {
                width: parent.width
                checkTitle: "Lost Books"
                checkData: clearanceData ? clearanceData.lost_books : null
                detailsType: "lost"
            }

            ReceiptCheckItem {
                width: parent.width
                checkTitle: "Unpaid Fines"
                checkData: clearanceData ? clearanceData.unpaid_fines : null
                detailsType: "fines"
            }
        }

        // Footer
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Layout.topMargin: 8

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#3498db"
            }

            Text {
                text: "Official Library Clearance Certificate"
                font.pixelSize: 9
                color: "#7f8c8d"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
            }

            Text {
                text: "Library Management System © 2026"
                font.pixelSize: 9
                color: "#7f8c8d"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    function getIdLabel() {
        if (!clearanceData) return "ID"
        var userType = clearanceData.user_type || ""
        if (userType === "student") return "Adm No"
        if (userType === "staff") return "Staff No"
        return "User No"
    }
}

