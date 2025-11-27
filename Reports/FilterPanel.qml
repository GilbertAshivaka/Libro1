import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Reusable filter panel with collapsible sections
Rectangle {
    id: root
    
    // Properties
    property alias dateRangePicker: dateRange
    property var filterOptions: [] // Array of {label, key, values: []}
    property var selectedFilters: ({})
    
    // Signals
    signal filtersChanged(var filters)
    signal applyClicked()
    signal resetClicked()
    
    // Styling
    implicitHeight: filterLayout.implicitHeight + 40
    radius: 8
    color: "#FAFAFA"
    border.color: "#E0E0E0"
    border.width: 1
    
    ColumnLayout {
        id: filterLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Label {
                text: "Filters"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: "#212121"
                Layout.fillWidth: true
            }
            
            Button {
                text: "Reset"
                flat: true
                font.pixelSize: 13
                
                background: Rectangle {
                    radius: 6
                    color: parent.hovered ? "#FFEBEE" : "transparent"
                    border.color: parent.hovered ? "#F44336" : "#E0E0E0"
                    border.width: 1
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? "#F44336" : "#757575"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                
                onClicked: root.resetClicked()
            }
            
            Button {
                text: "Apply"
                font.pixelSize: 13
                
                background: Rectangle {
                    radius: 6
                    color: parent.hovered ? "#1976D2" : "#2196F3"
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                
                onClicked: root.applyClicked()
            }
        }
        
        // Date range picker
        DateRangePicker {
            id: dateRange
            Layout.fillWidth: true
            
            onRangeChanged: {
                root.selectedFilters["dateRange"] = range
                root.filtersChanged(root.selectedFilters)
            }
        }
        
        // Dynamic filter options
        Repeater {
            model: root.filterOptions
            
            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Label {
                    text: modelData.label
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: "#424242"
                }
                
                ComboBox {
                    Layout.fillWidth: true
                    
                    model: modelData.values
                    currentIndex: 0
                    
                    onActivated: {
                        root.selectedFilters[modelData.key] = currentText
                        root.filtersChanged(root.selectedFilters)
                    }
                    
                    background: Rectangle {
                        color: parent.hovered ? "#FFFFFF" : "#F5F5F5"
                        radius: 6
                        border.color: parent.activeFocus ? "#2196F3" : "#E0E0E0"
                        border.width: parent.activeFocus ? 2 : 1
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
    }
}
