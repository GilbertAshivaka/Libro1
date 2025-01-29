import QtQuick
import QtQuick.Controls

Rectangle {
    id: allBooks
    visible: true
    width: parent.width //600
    height: parent.height //400
    color: "#FBFBFB"
//    title: "Library Management System"

//    property int btnWidth: width* .87
    signal closeClicked()

    MouseArea{
        id: allBooksMA
        anchors.fill: parent
    }


    Rectangle{
        id: cartegoryContainer
        color: "#FBFBFB"
        width: parent.width* .21
        property int btnWidth: width* .87

        anchors{
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        Rectangle{
            id: cartegories
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: parent.top
                topMargin: 10
                left: parent.left
//                right: parent.right
                leftMargin: 5
            }
            color: "transparent"
            radius: 4
            Label{
                id: quickActionsTxt
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: "Quick Actions"
                verticalAlignment: Text.AlignVCenter
    //                verticalCenter: parent.verticalCenter
                font.bold: true
            }
        }

        CustomButton{
            id: homeBtn
            text: qsTr("English")
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: cartegories.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 10
            }

            onClicked: {

            }
        }


        CustomButton{
            id: allBooksBtn
            text: qsTr("Maths")
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: homeBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
            onClicked:{

            }
        }

        CustomButton{
            id: pendingBtn
            text: qsTr("History")
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: allBooksBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{

            }
        }

        CustomButton{
            id: closeBtn
            text: qsTr("Close")
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: pendingBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
            defaultColor: "#399ED9"
            hoveredColor: "#399ED9"

            onClicked:{
                allBooks.closeClicked()
            }
        }
    }

    Rectangle{
        id: pageTitleRect
        height: 50
        width: pageTitle.width
        color: "transparent"
        anchors{
            top: parent.top
            topMargin: 20
            left: cartegoryContainer.right
            leftMargin: 20
        }

        Text{
            id: pageTitle
            text: "All books"
            font.pointSize: 16
            font.bold: true
            color: "#878585"
            anchors{
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }
    }

    Searchbox{
        id: allBooksSearchBox
        width: 300
        height: 30
        border.color: "#E0E0E0"
        placeHolderText: "Search"
        anchors{
            right: parent.right
            rightMargin: 10
            verticalCenter: pageTitleRect.verticalCenter
        }
    }

    ListView {
        id: listView
//        width: parent.width
//        height: parent.height
        clip: true
        anchors{
            top: pageTitleRect.bottom
            topMargin: 10
            left: cartegoryContainer.right
            leftMargin: 20
            bottom: parent.bottom
            right: parent.right
        }

        model: ListModel {
            ListElement {
                title: "Artificial Intelligence: A Modern Approach"
                author: "Stuart Russell and Peter Norvig"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Pattern Recognition and Machine Learning"
                author: "Christopher M. Bishop"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Operating Systems: Three Easy Pieces"
                author: "Remzi H. Arpaci-Dusseau and Andrea C. Arpaci-Dusseau"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Computer Architecture: A Quantitative Approach"
                author: "John L. Hennessy and David A. Patterson"
                iconSource: "assets/delegateBook.png"
            }
            ListElement {
                title: "Discrete Mathematics and Its Applications"
                author: "Kenneth H. Rosen"
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
                            text: model.author
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
                        deleteIconRect.visible = true
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                        deleteIconRect.visible = false
                    }
                }

                Rectangle{
                    id: deleteIconRect
                    visible: false
                    width: 20
                    height: 20
                    color: "transparent"
                    anchors{
                        right: parent.right
                        rightMargin: 50
                        verticalCenter: parent.verticalCenter
                    }

                    MouseArea{
                        id: deleteIconMA
                        anchors.fill: parent
                        hoverEnabled: true

                        Image{
                            id: deleteIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: "assets/deleteClosed.png"
                        }

                        onEntered: {
                            deleteIcon.source = "assets/deleteOpen.png"
                        }

                        onExited: {
                            deleteIcon.source = "assets/deleteClosed.png"
                        }
                    }
                }
            }

            Rectangle {
                id: separator
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
