import QtQuick 2.15
import QtQuick.Controls 2.15
import "DynamicComponents"

Item {
    property int currentIndex: 0
    property var componentsList: [
        "DynamicComponents/SocialMediaPage.qml",
        "DynamicComponents/UserTips.qml",
        "DynamicComponents/Stats.qml",
        "DynamicComponents/StatsGraph.qml",
        "DynamicComponents/Suggestions.qml",
        "DynamicComponents/QuotesPage.qml"
    ]

    Timer {
        id: scrollTimer
        interval: 20000 // 20 seconds
        repeat: true
        running: true

        onTriggered: {
            incrementCurrentIndex()
        }
    }

    Rectangle {
        id: dynamicRect
        anchors.fill: parent
        radius: 8
        border.color: "blue"
        color: "#E8E3E4" //"lightgray"
        clip: true

        Loader {
            id: dynamicLoader
            anchors.fill: parent
            source: componentsList[currentIndex]
        }

        Rectangle {
            id: nextBtn
            height: parent.height * 0.5
            width: 30
            radius: 4
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            color: "transparent"
            border.color: "transparent"

            Rectangle {
                id: nextRect
                height: 24
                width: height
                anchors.centerIn: parent
                color: "transparent"
                visible: false

                Image {
                    id: nextImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/rightArrow.png"
                }
            }

            MouseArea {
                id: nextMA
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    nextBtn.color = Qt.rgba(255, 255, 255, 0.5)
                    nextRect.visible = true
                }

                onExited: {
                    nextBtn.color = "transparent"
                    nextRect.visible = false
                }

                onClicked: {
                    incrementCurrentIndex()
                    scrollTimer.restart()
                }

                Shortcut {
                    sequence: "Right"
                    onActivated: {
                        incrementCurrentIndex()
                        scrollTimer.restart()
                    }
                }
            }
        }

        Rectangle {
            id: prevBtn
            height: parent.height * 0.5
            width: 30
            radius: 4
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            color: "transparent"
            border.color: "transparent"

            Rectangle {
                id: prevRect
                height: 24
                width: height
                anchors.centerIn: parent
                color: "transparent"
                visible: false

                Image {
                    id: prevImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/leftArrow.png"
                }
            }

            MouseArea {
                id: prevMA
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    prevBtn.color = Qt.rgba(255, 255, 255, 0.5)
                    prevRect.visible = true
                }

                onExited: {
                    prevBtn.color = "transparent"
                    prevRect.visible = false
                }

                onClicked: {
                    decrementCurrentIndex()
                    scrollTimer.restart()
                }

                Shortcut {
                    sequence: "Left"
                    onActivated: {
                        decrementCurrentIndex()
                        scrollTimer.restart()
                    }
                }
            }
        }
    }

    function incrementCurrentIndex() {
        if (currentIndex < componentsList.length - 1) {
            currentIndex += 1
        } else {
            currentIndex = 0 // Wrap around to the first component
        }
        dynamicLoader.source = componentsList[currentIndex]
    }

    function decrementCurrentIndex() {
        if (currentIndex > 0) {
            currentIndex -= 1
        } else {
            currentIndex = componentsList.length - 1 // Wrap around to the last component
        }
        dynamicLoader.source = componentsList[currentIndex]
    }
}
