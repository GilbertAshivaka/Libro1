import QtQuick
import Qt5Compat.GraphicalEffects

DropShadow {
    id: customDS
    anchors.fill: source
    horizontalOffset: 3
    verticalOffset: 3
    radius: 8
    samples: 16
    color: "#80000000"
    source: homeBtn
    visible: false
}
