import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: historyPage
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
        id: historyPageTitleRect
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
            id: historyPageTitle
            anchors {
                left: libraryIconRect.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            text: "History"
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
                verticalCenter: historyPageTitleRect.verticalCenter
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
                    historyPage.visible = !historyPage.visible
                }
            }
        }

        Image{
            id: infoIcon
            width: 20
            height: 20
            anchors{
                left: historyPageTitle.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            source: "assets/issueInfo1.png"

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    infoIcon.source = "assets/issueInfo.png"
                    historyTooltip1.visible = !historyTooltip1.visible
                }
                onExited:{
                    infoIcon.source = "assets/issueInfo1.png"
                    historyTooltip1.visible = !historyTooltip1.visible
                }
            }
        }

        //Tooltp
        Rectangle {
            id: historyTooltip1
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
                id: historyToolTipText
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
            top: historyPageTitleRect.bottom
        }
        color: "black"
    }



    ListView {
        id: listView
        width: parent.width
        height: parent.height
        anchors.top: separator.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 10
        clip: true

        model: ListModel {
            ListElement {
                title: "Artificial Intelligence: A Modern Approach"
                date: "01/08/2024"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Pattern Recognition and Machine Learning"
                date: "01/08/2024"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Operating Systems: Three Easy Pieces"
                date: "02/08/2024"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Computer Architecture: A Quantitative Approach"
                date: "03/08/2024"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Discrete Mathematics and Its Applications"
                date: "04/08/2024"
                iconSource: "assets/delegateBook.png"
            }
        }

        delegate: Item {
            width: listView.width
            height: 50

            Rectangle {
                id: delegateItemRect
                width: parent.width
                height: parent.height
                color: "transparent"
                anchors.left: parent.left
//                anchors.leftMargin: 20

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Image {
                        id: icon
                        source: model.iconSource
                        width: 32
                        height: 32
                    }

                    Column {
                        spacing: 5

                        Text {
                            text: model.title
                            font.pixelSize: 16
                            color: "black"
                        }

                        Text {
                            text: model.date
                            font.pixelSize: 12
                            color: "#606060"
                        }
                    }
                }

                MouseArea{
                    id: delegateItemMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        delegateItemRect.color = "#F5F5F5"
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                    }
                }
            }

            Rectangle {
                width: delegateItemRect.width* .95
                height: 1
                color: "#E0E0E0"
                anchors{
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

            }
        }
    }
}
