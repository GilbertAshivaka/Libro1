import QtQuick 2.15
import QtQuick.Controls

Item {
    id: suggestionsItem

    // Current suggestion data
    property var currentSuggestion: ({})
    property bool hasSuggestions: false

    // Timer to cycle through suggestions
    Timer {
        id: cycleTimer
        interval: 8000 // 8 seconds
        repeat: true
        running: suggestionsItem.visible && hasSuggestions
        onTriggered: fetchRandomSuggestion()
    }

    function fetchRandomSuggestion() {
        var suggestion = suggestionsManager.getRandomActiveSuggestion()
        if (suggestion && suggestion.content) {
            currentSuggestion = suggestion
            hasSuggestions = true
        } else {
            hasSuggestions = false
        }
    }

    Rectangle {
        id: suggestionsRect
        radius: 8
        anchors.fill: parent
        color: "transparent"

        // Content when there are suggestions
        Item {
            id: suggestionContent
            anchors.fill: parent
            visible: hasSuggestions

            Text {
                id: msgTitle
                text: qsTr("Suggestion box Messages")
                color: "blue"
                anchors {
                    top: parent.top
                    topMargin: 20
                    left: parent.left
                    leftMargin: 20
                }
                font.bold: true
                font.pixelSize: 14
            }

            // Type indicator
            Rectangle {
                id: typeIndicator
                width: typeIndicatorText.width + 12
                height: 18
                radius: 9
                color: currentSuggestion.type === "feedback" ? "#FFF3E0" : "#E3F2FD"
                anchors {
                    left: msgTitle.right
                    leftMargin: 10
                    verticalCenter: msgTitle.verticalCenter
                }
                visible: currentSuggestion.type !== undefined

                Text {
                    id: typeIndicatorText
                    anchors.centerIn: parent
                    text: currentSuggestion.type === "feedback" ? "Feedback" : "Suggestion"
                    font.pixelSize: 9
                    color: currentSuggestion.type === "feedback" ? "#F57C00" : "#1976D2"
                }
            }

            Text {
                id: suggestions
                anchors {
                    top: msgTitle.bottom
                    topMargin: 15
                    left: msgTitle.left
                    right: parent.right
                    rightMargin: 15
                }
                width: parent.width - 35
                text: currentSuggestion.content || ""
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                color: "#333333"
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            Text {
                id: msgAuthor
                text: currentSuggestion.user_name || ""
                anchors {
                    top: suggestions.bottom
                    topMargin: 12
                    left: suggestions.left
                }
                font.bold: true
                font.pixelSize: 13
                color: "#606060"
            }

            // Subtle indicator that content is cycling
            Row {
                id: cycleIndicator
                spacing: 4
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                visible: suggestionsManager.getActiveSuggestionsCount() > 1

                Repeater {
                    model: 3
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: "#D0D0D0"

                        SequentialAnimation on color {
                            running: cycleTimer.running
                            loops: Animation.Infinite
                            ColorAnimation { to: "#399ED9"; duration: 300 }
                            PauseAnimation { duration: 2300 }
                            ColorAnimation { to: "#D0D0D0"; duration: 300 }
                            PauseAnimation { duration: (8000 / 3) * index }
                        }
                    }
                }
            }
        }

        // Empty state when no suggestions
        Item {
            id: emptyState
            anchors.fill: parent
            visible: !hasSuggestions

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "💭"
                    font.pixelSize: 36
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No suggestions yet"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#878585"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Suggestions and feedback will show \nwhen available in the system."
                    font.pixelSize: 12
                    color: "#AAAAAA"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Component.onCompleted: {
        fetchRandomSuggestion()
    }

    // Refresh when component becomes visible
    onVisibleChanged: {
        if (visible) {
            fetchRandomSuggestion()
        }
    }
}
