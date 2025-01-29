import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: quickTools
    width: parent.width
    height: parent.height
    color: "#F7F7F7" // Background color similar to the image

    signal closeClicked()

    Row {
        id: mainRow
        width: parent.width
        spacing: 20
        anchors{
            top: parent.top
            left: parent.left
            topMargin: 10
            leftMargin: 20
        }

        padding: 20

        // First Section
        Rectangle {
            width: parent.width* 13/24
            height: 400
            radius: 10
            color: "white"
            border.color: "#E0E0E0"
            border.width: 1

            Column {
                width: parent.width
                spacing: 10
                padding: 10

                Text {
                    text: "Recommended tools for you"
                    font.pixelSize: 16
                    font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: 10

                    // Add comments tool
                    Column {
                        width: parent.width/2
                        spacing: 5
                        Rectangle {
                            width: 50
                            height: 50
                            //                                color: "#FFD700"
                            color: "transparent"
                            radius: 5
                            // Replace with appropriate icon
                            Image {
                                source: "assets/message.png"
                                anchors.centerIn: parent
                            }
                        }
                        Text {
                            text: "Add comments"
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }

                        Rectangle{
                            width: parent.width
                            height: col1Txt.height
                            Text {
                                id: col1Txt
                                width: parent.width
                                text: "Add sticky notes, highlights, and other annotations."
                                font.pixelSize: 12
                                color: "#606060"
                                wrapMode: Text.WordWrap
                            }
                        }


                        Button {
                            text: "Use now"
                            background: Rectangle {
                                color: "transparent"
                                border.color: "#0078D4"
                                border.width: 1
                                radius: 5
                            }
                            contentItem: Text {
                                text: "Use now"
                                color: "#0078D4"
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Request e-signatures tool
                    Column {
                        width: parent.width/2- 22
                        spacing: 5
                        Rectangle {
                            width: 50
                            height: 50
                            //                                color: "#C71585"
                            color: "transparent"
                            radius: 5
                            // Replace with appropriate icon
                            Image {
                                source: "assets/contract.png"
                                anchors.centerIn: parent
                            }
                        }
                        Text {
                            text: "Request e-signatures"
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }

                        Rectangle{
                            width: parent.width
                            height: col2Txt.height
                            Text {
                                id: col2Txt
                                width: parent.width
                                text: "Send a document to anyone to e-sign online fast."
                                font.pixelSize: 12
                                color: "#606060"
                                wrapMode: Text.WordWrap
                            }
                        }


                        Button {
                            text: "Use now"
                            background: Rectangle {
                                color: "transparent"
                                border.color: "#0078D4"
                                border.width: 1
                                radius: 5
                            }
                            contentItem: Text {
                                text: "Use now"
                                color: "#0078D4"
                                font.pixelSize: 12
                            }
                            onClicked: {
                                quickTools.closeClicked()
                            }
                        }
                    }
                }

                // "See all tools" link
                Text {
                    text: "See all tools"
                    font.pixelSize: 12
                    color: "#0078D4"
                    anchors{
                        right: parent.right
                        rightMargin: 5
                    }
                }
            }
        }

        // Second Section
        Rectangle {
            width: parent.width* 1/3
            height: 200
            radius: 10
            color: "white"
            border.color: "#E0E0E0"
            border.width: 1

            Column {
                width: parent.width
                spacing: 10
                padding: 10

                Text {
                    text: "Get documents signed fast"
                    font.pixelSize: 16
                    font.bold: true
                }

                Rectangle{
                    width: parent.width- 22
                    height: signatureTxt.height

                    Text {
                        id: signatureTxt
                        text: "Get documents signed in minutes with trusted e-signatures."
                        font.pixelSize: 12
                        color: "#606060"
                        wrapMode: Text.WordWrap
                    }
                }


                Button {
                    text: "Request e-signatures"
                    background: Rectangle {
                        color: "transparent"
                        border.color: "#0078D4"
                        border.width: 1
                        radius: 5
                    }
                    contentItem: Text {
                        text: "Request e-signatures"
                        color: "#0078D4"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}

