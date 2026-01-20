import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: receiptCheckItem

    property string checkTitle: ""
    property var checkData: null
    property string detailsType: "books"

    width: parent.width
    height: itemRow.height + 8
    color: "#f8f9fa"
    radius: 4

    RowLayout {
        id: itemRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 8
        spacing: 8

        Text {
            text: checkData && checkData.cleared ? "✓" : "✗"
            font.pixelSize: 12
            font.bold: true
            color: checkData && checkData.cleared ? "#28a745" : "#dc3545"
        }

        Text {
            text: checkTitle
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#2c3e50"
            Layout.fillWidth: true
        }

        Text {
            text: getMessage()
            font.pixelSize: 10
            color: "#6c757d"
        }
    }

    function getMessage() {
        if (!checkData) return ""
        if (checkData.cleared) {
            return "Clear"
        }
        var count = checkData.count || 0
        if (detailsType === "lost" || detailsType === "fines") {
            var total = checkData.total_owed || 0
            return count + " item(s) - KSh " + total.toFixed(0)
        }
        return count + " item(s)"
    }
}
