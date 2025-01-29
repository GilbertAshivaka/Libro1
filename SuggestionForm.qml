import QtQuick
import QtQuick.Controls

Window {
    id: suggestionForm
    width: 480
    height: 400
    maximumHeight: 400
    minimumHeight: 400
    maximumWidth: 480
    minimumWidth: 480
//    color: "F5F5F5"
    title: "History"
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowCloseButtonHint

    Rectangle {
        id: suggestionFormTitleRect
        width: parent.width
        height: 50
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

        Rectangle{
            id: mainCloseRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: parent.right
                rightMargin: 10
                verticalCenter: suggestionFormTitleRect.verticalCenter
            }

            Rectangle{
                id: mainCloseImageRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: mainClose
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/close.png"
                }
            }

            MouseArea{
                id: mainCloseMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    mainCloseRect.color = "#E8E3E4"
                }
                onExited: {
                    mainCloseRect.color = "white"
                }

                onClicked: {
                    suggestionForm.visible = !suggestionForm.visible
                    suggestionTextArea.clear()
                }
            }
        }

        Image{
            id: infoIcon
            width: 20
            height: 20
            anchors{
                left: feedbackFormTitle.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            source: "assets/issueInfo1.png"

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    infoIcon.source = "assets/issueInfo.png"
                    suggestionTooltip1.visible = !suggestionTooltip1.visible
                }
                onExited:{
                    infoIcon.source = "assets/issueInfo1.png"
                    suggestionTooltip1.visible = !suggestionTooltip1.visible
                }
            }
        }

        //Tooltp
        Rectangle {
            id: suggestionTooltip1
            width: 120
            height: 40
            color: Qt.rgba(0,0,0,0.5)
            visible: false
            z: 3
            radius: 4
            anchors{
                left: infoIcon.left
                leftMargin: 25
                verticalCenter: parent.verticalCenter
            }

            Text {
                id: suggestionTooltipText
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 5
                    rightMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                color: "white"
                text: "Grab the edges and hold to move."
                font.pixelSize:12
                wrapMode: Text.WordWrap
            }
        }
    }

    Rectangle{
        id: separator
        width: parent.width
        height: 1
        anchors{
            top: suggestionFormTitleRect.bottom
        }
        color: "black"
    }

    Rectangle {
        id: textAreaContainer
        anchors{
            top: separator.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        color: "#F5F5F5"

        TextArea{
            id: suggestionTextArea
            width: Math.floor(parent.width* .90)
//            height: Math.floor(parent.height* .95)
            anchors{
                top: parent.top
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
                bottom: submitBtn.top
                bottomMargin: 10
            }
            placeholderText: "Type your suggestions and complains here...."
            wrapMode: TextEdit.Wrap
            font.pixelSize: 16
        }

        CustomButton{
            id: submitBtn
            text: "Submit"
            anchors{
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 10
                rightMargin: 20
            }
            defaultColor: "#399ED9"
            hoveredColor: "#399ED9"
        }

        CustomButton{
            id: cancelBtn
            text: "Cancel"
            anchors{
                right: submitBtn.left
                bottom: submitBtn.bottom
                rightMargin: 7
            }
            defaultColor: "#E0E0E0"
            hoveredColor: "#E0E0E0"
        }
    }
}
