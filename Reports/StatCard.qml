import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

// Reusable stat card component for displaying metrics
Rectangle {
    id: root

    // Properties
    property string title: ""
    property var value: ""
    property string unit: ""
    property string trend: ""
    property string trendDirection: "neutral" // "up", "down", "neutral"
    property color cardColor: "#FFFFFF"
    property color accentColor: "#2196F3"
    property bool isLoading: false

    // Styling
    width: 240
    height: 120
    radius: 8
    color: cardColor
    border.color: "#E0E0E0"
    border.width: 1

    // Shadow effect
    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 2
        radius: 8
        samples: 16
        color: "#20000000"
    }

    // Hover effect
    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            parent.border.color = accentColor
            parent.border.width = 2
        }

        onExited: {
            parent.border.color = "#E0E0E0"
            parent.border.width = 1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        // Title
        Label {
            id: titleLabel
            text: root.title
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "#757575"
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Value container
        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            // Main value
            Label {
                id: valueLabel
                text: isLoading ? "..." : String(root.value)
                font.pixelSize: 28
                font.weight: Font.Bold
                color: "#212121"
                Layout.fillWidth: true

                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation {
                            target: valueLabel
                            property: "opacity"
                            to: 0.5
                            duration: 150
                        }
                        NumberAnimation {
                            target: valueLabel
                            property: "opacity"
                            to: 1.0
                            duration: 150
                        }
                    }
                }
            }

            // Unit
            Label {
                text: root.unit
                font.pixelSize: 14
                font.weight: Font.Normal
                color: "#757575"
                visible: root.unit !== ""
            }
        }

        // Trend indicator
        RowLayout {
            spacing: 4
            visible: root.trend !== ""
            Layout.fillWidth: true

            // Trend icon
            Text {
                text: {
                    if (root.trendDirection === "up") return "↗"
                    if (root.trendDirection === "down") return "↘"
                    return "→"
                }
                font.pixelSize: 14
                color: {
                    if (root.trendDirection === "up") return "#4CAF50"
                    if (root.trendDirection === "down") return "#F44336"
                    return "#9E9E9E"
                }
            }

            // Trend text
            Label {
                text: root.trend
                font.pixelSize: 11
                color: {
                    if (root.trendDirection === "up") return "#4CAF50"
                    if (root.trendDirection === "down") return "#F44336"
                    return "#9E9E9E"
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Accent bar at bottom
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: accentColor
        radius: parent.radius
    }

    // Loading indicator
    BusyIndicator {
        anchors.centerIn: parent
        running: root.isLoading
        visible: root.isLoading
        width: 32
        height: 32
    }

    // // Accent bar at the top
    // Rectangle {
    //     width: parent.width
    //     height: 4
    //     color: root.accentColor
    //     radius: root.radius
    //     anchors.top: parent.top
    // }
}
