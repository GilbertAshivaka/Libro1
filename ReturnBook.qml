import QtQuick
import QtQuick.Controls
import "DynamicComponentLoader.js" as CustomComponentLoader

Rectangle {
    id: returnBook
    anchors.fill: parent
    color: "#FBFBFB"

    signal closeClicked()
    property var returnBookNumberRect: null


    MouseArea{
        id: returnBookMA
        anchors.fill: parent
    }

    Rectangle{
        id: returnBookTitleRect
        width: parent.width
        height: 50
        anchors{
            top: parent.top
            left: parent.left
        }

        Text{
            id: returnBookTitle
            anchors{
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "Return book"
            font.pointSize: 12
            color: "#878585"
        }

        Rectangle{
            id: closeRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: parent.right
                rightMargin: 30
                verticalCenter: parent.verticalCenter            }

            Rectangle{
                id: closeImageRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: close
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/close.png"
                }
            }

            MouseArea{
                id: closeMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    closeRect.color = "#E8E3E4"
                }
                onExited: {
                    closeRect.color = "white"
                }

                onClicked: {
                    returnBook.closeClicked()
                }
            }
        }
    }



    Rectangle{
        id: returnDetailsContainer
        width: parent.width
        anchors{
            top: returnBookTitleRect.bottom
            bottom: parent.bottom
        }
        color: parent.color
        clip: true
        visible: false

        Rectangle{
            id: bookTitleRect
            width: parent.width* 2/3
            height: 50
            anchors{
                top: parent.top
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            color: "transparent"
            clip: true

            Text{
                id: bookTitle
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                text: "Artificial Intelligence: A Modern Approach"
                font.pointSize: 14
            }
        }

        Rectangle{
            id: bookNumberRect
            width: parent.width/4
            height: 50
            color: "white"
            clip: true
            anchors{
                left:  parent.left
                top:  bookTitleRect.bottom
                topMargin: 10
            }

            Label{
                id: bookIDLabel
                anchors{
                    left:  parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                text:  "Book No/ID: "
                font.pointSize: 12
            }

            Text{
                id: bookID
                anchors{
                    left:bookIDLabel.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                text: "13/NRW/2024"
                font.pointSize: 12
            }
        }

        Rectangle{
            id: separater
            width: 2
            color: "#DDDDDD"
            anchors{
                top: bookNumberRect.top
                left: bookNumberRect.right
                leftMargin: 10
                bottom: bookNumberRect.bottom
            }
        }


        Rectangle{
            id: dueDateRect
            width: parent.width/4
            height: 50
            clip: true
            anchors{
                left: bookNumberRect.right
                leftMargin: 30
                verticalCenter: bookNumberRect.verticalCenter
            }

            Label{
                id: dueDateLabel
                text: "Due Date: "
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                font.pointSize: 12
            }

            Text{
                id: dueDate
                anchors{
                    left: dueDateLabel.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                text: "11/06/2024"
                font.pointSize: 12
            }
        }

        Rectangle{
            id: conditionRect
            height: 50
            width: parent.width/4
            color: "transparent"

            anchors{
                left: parent.left
                top: bookNumberRect.bottom
                topMargin: 	20
            }

            Label{
                id: conditionLabel
                anchors{
                    left: parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                text: qsTr("Condition: ")
                font.pointSize: 12
            }

            ComboBox {
                id: conditionComboBox
                height: 40
                editable: false
                anchors{
                    left: conditionLabel.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                model: ListModel {
                    ListElement { text: "Perfect" }
                    ListElement { text: "Good" }
                    ListElement { text: "Fair" }
                    ListElement { text: "Damaged" }
                }
            }
        }

        Rectangle{
            id: statusRect
            width: parent.width/4
            height: 50
            clip: true
            anchors{
                left: conditionRect.right
                leftMargin: 30
                top: conditionRect.top
            }

            Label{
                id: statusLabel
                text: "Status: "
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                font.pointSize: 12
            }

            Text{
                id: status
                anchors{
                    left: statusLabel.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                text: "Expired"
                font.pointSize: 12
            }

            Rectangle{
                id: statusIndicator
                width: 12
                height: width
                radius: width/2
                color: status.text === "Active" ? "#7ED297" : "red"
                anchors{
                    left: status.right
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle{
            id: separater1
            width: 2
            color: "#DDDDDD"
            anchors{
                top: bookNumberRect.top
                left: dueDateRect.right
                leftMargin: 10
                bottom: statusRect.bottom
            }
        }

        Rectangle{
            id: userSectionRect
            height: 30
            width: 60
            color: "transparent"
            anchors{
                top: bookTitleRect.bottom
                topMargin: 10
//                horizontalCenter: someRect.horizontalCenter
                left: separater1.right
                leftMargin: 30
            }

            Text {
                id: userSection
                text: qsTr("User")
                font.pointSize: 14
            }
        }

        Rectangle{
            id: borrowerNameRect
            width: parent.width/4
            height: 50
            clip: true
            anchors{
                left: separater1.right
                leftMargin: 30
                top: userSectionRect.bottom
                topMargin: 10
            }

            Label{
                id: borrowerNameLabel
                text: "Name: "
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                font.pointSize: 12
            }

            Text{
                id: borrowerName
                anchors{
                    left: borrowerNameLabel.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                text: "Gilbert Ashivaka"
                font.pointSize: 12
            }
        }


        Rectangle{
            id: fineRect
            width: parent.width/4
            height: 50
            clip: true
            visible: status.text === "Expired"
            anchors{
                top: conditionRect.bottom
                topMargin: 20
                left: parent.left
            }

            Label{
                id: fineLabel
                text: "Fine: "
                anchors{
                    left: parent.left
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }
                font.pointSize: 12
            }

            Text{
                id: fine
                anchors{
                    left: fineLabel.right
                    leftMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                text: "56"
                font.pointSize: 12
            }
        }

        CustomButton{
            id: returnBookBtn
            text: "Return"
            defaultColor: "#399ED9"
            hoveredColor: "#399ED9"
            anchors{
                bottom: fineRect.bottom
                right: parent.right
                rightMargin: 30
            }

            onClicked: {
                returnDetailsContainer.visible = !returnDetailsContainer.visible
                CustomComponentLoader.customCreateComponent(returnBookNumberRect,"ReturnBookNumberRect", returnBook)
            }
        }

        CustomButton{
            id: returnCancelBtn
            text: "Cancel"
            defaultColor: "#E0E0E0"
            anchors{
                bottom: returnBookBtn.bottom
                right: returnBookBtn.left
                rightMargin: 7
            }
        }

        Rectangle{
            id: menuRect
            width: 40
            height: 30
            radius: 4
            color: "transparent"
            anchors{
                right: returnBookBtn.right
                verticalCenter: userSectionRect.verticalCenter
            }

            Image{
                id: menuImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/menu.png"
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    menuRect.color = "#E8E3E4"
                }
                onExited: {
                    menuRect.color = "transparent"
                }

                onClicked: {
                    menu.open()
                }
            }

            Menu {
                id: menu
                width: 120
                y: menuRect.height

                MenuItem {
                    height: 40
                    text: "Show user history"
                }
            }
        }
    }

    Component.onCompleted: {
        CustomComponentLoader.customCreateComponent(returnBookNumberRect,"ReturnBookNumberRect", returnBook)
    }
}








