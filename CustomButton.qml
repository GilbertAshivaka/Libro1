import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

RoundButton {
    id: control
    text: qsTr("Button")

    property string defaultColor: "transparent"
    property string hoveredColor: "#E0E0E0"

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.5
//        color: control.down ? "#17a81a" : "#21be2b"
        color: control.down ? "#585757" : "black"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        opacity: enabled ? 1 : 0.3
        color: control.hovered ? hoveredColor : defaultColor // Transparent by default, changes to #E0E0E0 when hovered over
        radius: 4 // Adjust radius to make it round
    }
    //#E0E0E0

    DropShadow {
        id: dropShadow
        anchors.fill: source
        source: background
        horizontalOffset: 3
        verticalOffset: 3
        radius: 8
        samples: 16
        color: "#80000000"
        visible: false
    }

    onHoveredChanged: {
        dropShadow.visible = control.hovered;
    }
}
