import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Date range picker with preset options and custom range
Rectangle {
    id: root
    
    // Properties
    property string selectedRange: "last30days"
    property date customStartDate: new Date()
    property date customEndDate: new Date()
    
    // Signals
    signal rangeChanged(string range)
    
    // Styling
    implicitWidth: 320
    implicitHeight: 45
    radius: 8
    color: "#FFFFFF"
    border.color: "#E0E0E0"
    border.width: 1
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        // Date range icon
        Label {
            text: "📅"
            font.pixelSize: 18
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Preset dropdown
        ComboBox {
            id: rangeCombo
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            model: ListModel {
                ListElement { text: "Today"; value: "today" }
                ListElement { text: "Yesterday"; value: "yesterday" }
                ListElement { text: "Last 7 Days"; value: "last7days" }
                ListElement { text: "Last 30 Days"; value: "last30days" }
                ListElement { text: "Last 3 Months"; value: "last3months" }
                ListElement { text: "Last 6 Months"; value: "last6months" }
                ListElement { text: "Last 12 Months"; value: "last12months" }
                ListElement { text: "Current Month"; value: "currentMonth" }
                ListElement { text: "Current Year"; value: "currentYear" }
                ListElement { text: "All Time"; value: "all" }
                ListElement { text: "Custom Range..."; value: "custom" }
            }
            
            currentIndex: 3 // Default to "Last 30 Days"
            
            onActivated: {
                var selectedValue = model.get(currentIndex).value
                root.selectedRange = selectedValue
                
                if (selectedValue === "custom") {
                    customRangeDialog.open()
                } else {
                    root.rangeChanged(selectedValue)
                }
            }
            
            background: Rectangle {
                color: rangeCombo.hovered ? "#F5F5F5" : "transparent"
                radius: 6
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }
    
    // Custom date range dialog
    Dialog {
        id: customRangeDialog
        title: "Select Custom Date Range"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        width: 400
        height: 250
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 20
            
            // Start date
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Label {
                    text: "Start Date:"
                    font.pixelSize: 14
                    Layout.preferredWidth: 80
                }
                
                TextField {
                    id: startDateField
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: Qt.formatDate(root.customStartDate, "yyyy-MM-dd")
                    
                    validator: RegExpValidator {
                        regExp: /^\d{4}-\d{2}-\d{2}$/
                    }
                }
                
                Button {
                    text: "📅"
                    onClicked: {
                        // Could open a calendar picker here
                        console.log("Calendar picker for start date")
                    }
                }
            }
            
            // End date
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Label {
                    text: "End Date:"
                    font.pixelSize: 14
                    Layout.preferredWidth: 80
                }
                
                TextField {
                    id: endDateField
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: Qt.formatDate(root.customEndDate, "yyyy-MM-dd")
                    
                    validator: RegExpValidator {
                        regExp: /^\d{4}-\d{2}-\d{2}$/
                    }
                }
                
                Button {
                    text: "📅"
                    onClicked: {
                        console.log("Calendar picker for end date")
                    }
                }
            }
            
            // Info text
            Label {
                text: "Note: Custom date ranges are applied as filters on the data."
                font.pixelSize: 11
                color: "#757575"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        
        onAccepted: {
            root.customStartDate = new Date(startDateField.text)
            root.customEndDate = new Date(endDateField.text)
            root.rangeChanged("custom")
        }
        
        onRejected: {
            // Reset combo to previous selection
            for (var i = 0; i < rangeCombo.model.count; i++) {
                if (rangeCombo.model.get(i).value === root.selectedRange) {
                    rangeCombo.currentIndex = i
                    break
                }
            }
        }
    }
}
