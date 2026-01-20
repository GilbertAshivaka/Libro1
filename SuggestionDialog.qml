import QtQuick
import QtQuick.Controls

Popup {
    id: suggestionDialog
    width: 480
    height: 420
    modal: true
    focus: true
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Properties to receive user info from parent page
    property int userId: 0
    property string userName: ""
    property string userNumber: ""
    property string userRole: ""

    onOpened: {
        suggestionTextArea.clear()
        anonymousCheckBox.checked = false
        suggestionTextArea.forceActiveFocus()
    }

    background: Rectangle {
        color: "white"
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1
    }

    contentItem: Rectangle {
        id: suggestionFormContent
        color: "white"
        radius: 8

        Rectangle {
            id: suggestionFormTitleRect
            width: parent.width
            height: 50
            radius: 8
            anchors {
                top: parent.top
                left: parent.left
            }
            clip: true
            color: "white"

            Rectangle {
                id: libraryIconRect
                width: 40
                height: 40
                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Image {
                    id: libraryIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/libroIcon.ico"
                }
            }

            Text {
                id: feedbackFormTitle
                anchors {
                    left: libraryIconRect.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                text: "Suggestion Box"
                font.pointSize: 12
                color: "#878585"
            }

            Rectangle {
                id: mainCloseRect
                width: 40
                height: 40
                radius: 4
                color: "white"
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: mainCloseImageRect
                    width: 20
                    height: 20
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image {
                        id: mainClose
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/close.png"
                    }
                }

                MouseArea {
                    id: mainCloseMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        mainCloseRect.color = "#E8E3E4"
                    }
                    onExited: {
                        mainCloseRect.color = "white"
                    }

                    onClicked: {
                        suggestionDialog.close()
                    }
                }
            }

            Image {
                id: infoIcon
                width: 20
                height: 20
                anchors {
                    left: feedbackFormTitle.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                source: "assets/issueInfo1.png"

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        infoIcon.source = "assets/issueInfo.png"
                        suggestionTooltip1.visible = true
                    }
                    onExited: {
                        infoIcon.source = "assets/issueInfo1.png"
                        suggestionTooltip1.visible = false
                    }
                }
            }

            Rectangle {
                id: suggestionTooltip1
                width: 180
                height: 50
                color: Qt.rgba(0, 0, 0, 0.7)
                visible: false
                z: 3
                radius: 4
                anchors {
                    left: infoIcon.right
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    id: suggestionTooltipText
                    width: parent.width - 10
                    anchors {
                        left: parent.left
                        leftMargin: 5
                        rightMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    color: "white"
                    text: "Share your suggestions to help improve library services."
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            id: separator
            width: parent.width
            height: 1
            anchors {
                top: suggestionFormTitleRect.bottom
            }
            color: "#E0E0E0"
        }

        Rectangle {
            id: textAreaContainer
            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            color: "#F5F5F5"
            radius: 8

            TextArea {
                id: suggestionTextArea
                width: Math.floor(parent.width * 0.90)
                anchors {
                    top: parent.top
                    topMargin: 15
                    horizontalCenter: parent.horizontalCenter
                    bottom: anonymousCheckBox.top
                    bottomMargin: 10
                }
                placeholderText: "Type your suggestions and ideas here..."
                wrapMode: TextEdit.Wrap
                font.pixelSize: 14
                // background: Rectangle {
                //     color: "white"
                //     border.color: suggestionTextArea.activeFocus ? "#399ED9" : "#E0E0E0"
                //     border.width: suggestionTextArea.activeFocus ? 2 : 1
                //     radius: 4
                // }
                padding: 10
            }

            CheckBox {
                id: anonymousCheckBox
                text: "Submit anonymously"
                anchors {
                    left: suggestionTextArea.left
                    bottom: submitBtn.top
                    bottomMargin: 15
                }
                font.pixelSize: 12

                indicator: Rectangle {
                    implicitWidth: 20
                    implicitHeight: 20
                    x: anonymousCheckBox.leftPadding
                    y: parent.height / 2 - height / 2
                    radius: 3
                    border.color: anonymousCheckBox.checked ? "#399ED9" : "#878585"
                    color: anonymousCheckBox.checked ? "#399ED9" : "white"

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "white"
                        font.pixelSize: 14
                        visible: anonymousCheckBox.checked
                    }
                }

                contentItem: Text {
                    text: anonymousCheckBox.text
                    font: anonymousCheckBox.font
                    color: "#606060"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: anonymousCheckBox.indicator.width + anonymousCheckBox.spacing
                }
            }

            Text {
                id: anonymousHint
                anchors {
                    left: anonymousCheckBox.right
                    leftMargin: 10
                    verticalCenter: anonymousCheckBox.verticalCenter
                }
                text: "(Your identity will be hidden)"
                font.pixelSize: 11
                color: "#999999"
                visible: anonymousCheckBox.checked
            }

            CustomButton {
                id: submitBtn
                text: "Submit"
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 15
                    rightMargin: 20
                }
                defaultColor: "#399ED9"
                hoveredColor: "#2E86C1"

                onClicked: {
                    suggestionsManager.submitSuggestion(
                        suggestionDialog.userId,
                        suggestionDialog.userName,
                        suggestionDialog.userNumber,
                        suggestionDialog.userRole,
                        suggestionTextArea.text,
                        "suggestion",
                        anonymousCheckBox.checked
                    )
                }
            }

            CustomButton {
                id: cancelBtn
                text: "Cancel"
                anchors {
                    right: submitBtn.left
                    bottom: submitBtn.bottom
                    rightMargin: 10
                }
                defaultColor: "#E0E0E0"
                hoveredColor: "#BDBDBD"

                onClicked: {
                    suggestionDialog.close()
                }
            }
        }
    }

    // Connection to handle submit results
    Connections {
        target: suggestionsManager
        function onSubmitSuccess(message) {
            resultDialog.title = "Success"
            resultDialog.message = message
            resultDialog.open()
            suggestionDialog.close()
        }
        function onSubmitError(errorMessage) {
            resultDialog.title = "Error"
            resultDialog.message = errorMessage
            resultDialog.open()
        }
    }

    // Result dialog
    Dialog {
        id: resultDialog
        title: "Message"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok

        property string message: ""

        Label {
            text: resultDialog.message
            wrapMode: Text.WordWrap
            width: 300
        }
    }
}
