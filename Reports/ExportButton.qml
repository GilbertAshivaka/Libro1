import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

// Export button with dropdown menu for different formats.
// Uses the default Button shape/metrics (same as the neighbouring Refresh
// button) and only recolours it green via the Material attached properties.
Button {
    id: root

    // Signals
    signal exportPDF()
    signal exportCSV()
    signal exportExcel()
    signal printReport()

    text: "⤓ Export"
    highlighted: true

    Material.background: root.hovered ? "#43A047" : "#4CAF50"
    Material.foreground: "#FFFFFF"

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
