import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Export button with dropdown menu for different formats
Button {
    id: root
    
    // Signals
    signal exportPDF()
    signal exportCSV()
    signal exportExcel()
    signal printReport()
    
    text: "Export"
    icon.source: "⤓"
    
    implicitWidth: 120
    implicitHeight: 40
    
    background: Rectangle {
        radius: 8
        color: root.hovered ? "#43A047" : "#4CAF50"
        border.color: "#388E3C"
        border.width: 1
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    contentItem: RowLayout {
        spacing: 8
        
        Label {
            text: "⤓"
            font.pixelSize: 16
            color: "#FFFFFF"
        }
        
        Label {
            text: root.text
            font.pixelSize: 14
            font.weight: Font.Medium
            color: "#FFFFFF"
        }
    }
    
    onClicked: exportMenu.open()
    
    Menu {
        id: exportMenu
        y: root.height
        
        MenuItem {
            text: "Export as PDF"
            icon.source: "📄"
            onTriggered: root.exportPDF()
        }
        
        MenuItem {
            text: "Export as CSV"
            icon.source: "📊"
            onTriggered: root.exportCSV()
        }
        
        MenuItem {
            text: "Export as Excel"
            icon.source: "📑"
            onTriggered: root.exportExcel()
        }
        
        MenuSeparator { }
        
        MenuItem {
            text: "Print Report"
            icon.source: "🖨"
            onTriggered: root.printReport()
        }
    }
}
