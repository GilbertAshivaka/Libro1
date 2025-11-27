import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects


// Reusable container for charts with title and controls
Rectangle {
    id: root
    
    // Properties
    property string title: ""
    property string subtitle: ""
    property alias contentItem: contentArea.data
    property bool showExportButton: true
    property bool showRefreshButton: true
    property bool isLoading: false
    
    // Signals
    signal exportClicked()
    signal refreshClicked()
    
    // Styling
    radius: 12
    color: "#FFFFFF"
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
        color: "#15000000"
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#FAFAFA"
            radius: root.radius
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12
                
                // Title and subtitle
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    
                    Label {
                        text: root.title
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: "#212121"
                    }
                    
                    Label {
                        text: root.subtitle
                        font.pixelSize: 12
                        color: "#757575"
                        visible: root.subtitle !== ""
                    }
                }
                
                // Refresh button
                Button {
                    visible: root.showRefreshButton
                    flat: true
                    text: "⟳"
                    font.pixelSize: 18
                    implicitWidth: 40
                    implicitHeight: 40
                    
                    background: Rectangle {
                        radius: 20
                        color: parent.hovered ? "#E3F2FD" : "transparent"
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                    
                    onClicked: root.refreshClicked()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Refresh data"
                    ToolTip.delay: 500
                }
                
                // Export button
                Button {
                    visible: root.showExportButton
                    flat: true
                    text: "⤓"
                    font.pixelSize: 18
                    implicitWidth: 40
                    implicitHeight: 40
                    
                    background: Rectangle {
                        radius: 20
                        color: parent.hovered ? "#E8F5E9" : "transparent"
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                    
                    onClicked: root.exportClicked()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Export chart"
                    ToolTip.delay: 500
                }
            }
        }
        
        // Content area
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            
            // Loading overlay
            Rectangle {
                anchors.fill: parent
                color: "#F0FFFFFF"
                visible: root.isLoading
                radius: 8
                
                BusyIndicator {
                    anchors.centerIn: parent
                    running: root.isLoading
                    width: 50
                    height: 50
                }
                
                Label {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 40
                    text: "Loading data..."
                    font.pixelSize: 13
                    color: "#757575"
                }
            }
        }
    }
}
