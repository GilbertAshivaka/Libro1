import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: checkItem

    property string checkTitle: ""
    property var checkData: null
    property string detailsType: "books"

    // Fines and lost-book charges can be settled (paid/waived) inline.
    readonly property bool actionable: detailsType === "fines" || detailsType === "lost"

    signal payRequested(var issue)
    signal waiveRequested(var issue)

    implicitHeight: mainColumn.implicitHeight + 12
    color: "transparent"

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        spacing: 4

        RowLayout {
            id: checkRow
            Layout.fillWidth: true
            spacing: 8

            // Status Icon
            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: checkData && checkData.cleared ? "#d4edda" : "#f8d7da"

                Text {
                    anchors.centerIn: parent
                    text: checkData && checkData.cleared ? "✓" : "✗"
                    font.pixelSize: 11
                    font.bold: true
                    color: checkData && checkData.cleared ? "#155724" : "#721c24"
                }
            }

            // Title
            Text {
                text: checkTitle
                font.pixelSize: 12
                font.weight: Font.Medium
                color: "#1c1c1e"
                Layout.fillWidth: true
            }

            // Count Badge
            Rectangle {
                width: 24
                height: 18
                radius: 9
                color: checkData && checkData.cleared ? "#d4edda" : "#f8d7da"
                visible: checkData !== null

                Text {
                    anchors.centerIn: parent
                    text: checkData ? (checkData.count || 0) : "0"
                    font.pixelSize: 10
                    font.bold: true
                    color: checkData && checkData.cleared ? "#155724" : "#721c24"
                }
            }
        }

        // Issues List (compact, only shows when there are issues)
        ColumnLayout {
            id: issuesCol
            Layout.fillWidth: true
            spacing: 2
            visible: checkData && !checkData.cleared && checkData.issues && checkData.issues.length > 0

            Repeater {
                // Actionable categories show every item (each needs its own
                // Pay/Waive buttons); others stay compact (first 3).
                model: checkData && checkData.issues
                       ? (checkItem.actionable ? checkData.issues : checkData.issues.slice(0, 3))
                       : []

                Rectangle {
                    Layout.fillWidth: true
                    height: checkItem.actionable ? 24 : 18
                    color: "#fff8e1"
                    radius: 3

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: formatIssue(modelData)
                            font.pixelSize: 10
                            color: "#856404"
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Pay
                        Rectangle {
                            visible: checkItem.actionable
                            width: 38; height: 17; radius: 3
                            color: payMA.containsMouse ? "#218838" : "#28a745"
                            Text { anchors.centerIn: parent; text: "Pay"; font.pixelSize: 9; color: "white" }
                            MouseArea {
                                id: payMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: checkItem.payRequested(modelData)
                            }
                        }

                        // Waive
                        Rectangle {
                            visible: checkItem.actionable
                            width: 46; height: 17; radius: 3
                            color: waiveMA.containsMouse ? "#5a6268" : "#6c757d"
                            Text { anchors.centerIn: parent; text: "Waive"; font.pixelSize: 9; color: "white" }
                            MouseArea {
                                id: waiveMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: checkItem.waiveRequested(modelData)
                            }
                        }
                    }
                }
            }

            // Show more indicator (compact, non-actionable categories only)
            Text {
                visible: !checkItem.actionable && checkData && checkData.issues && checkData.issues.length > 3
                text: "+" + (checkData.issues.length - 3) + " more..."
                font.pixelSize: 9
                font.italic: true
                color: "#8e8e93"
                Layout.leftMargin: 6
            }
        }
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "#e5e5ea"
    }

    function formatIssue(issue) {
        if (!issue) return ""
        switch(detailsType) {
            case "books":
                return "• " + (issue.title || "Unknown") + " (" + (issue.call_number || "N/A") + ")"
            case "materials":
                return "• " + (issue.item_name || "Unknown") + " - " + (issue.item_type || "N/A")
            case "lost":
                return "• " + (issue.book_title || "Unknown") + " - KSh " + (issue.balance || 0).toFixed(0)
            case "fines":
                return "• " + (issue.book_title || "Unknown") + " - KSh " + (issue.balance || 0).toFixed(0)
            default:
                return "• Item"
        }
    }
}
