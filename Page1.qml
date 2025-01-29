import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import"ui"

//EEEFF8 ghost white
//F8F8F8 seasalt
//DBF8FF light cyan
//DBEEF3 azure
//E5F0F3 alice blue


Rectangle {
    id: page1
    width: 1000
    height: 500
    visible: true
//    title: qsTr("Hello World")
    color: "#f4f4f4"


    ToolBar{
        id: toolBar
        anchors.top: parent.top
        height: 30
        width: parent.width

        Rectangle{
            id: lockRect
            height: parent.height* .9
            width: height
            anchors.left: parent.left
            color: "#f4f4f4"

            Image{
                id: lockIcon
                anchors.fill: parent
                source: "qrc:Libro1/assets/lock1.png"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea{
                id: lockMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    lockRect.color = "#E8E3E4"
                }
                onExited: {
                    lockRect.color = "white"
                }

                onClicked: {
                    mainLoader.source = "Login.qml"
                }
            }
        }
    }


    LeftButtons{
        id: buttonsRect
        width: parent.width * .21
        height: parent.height* .65
        anchors{
//            top: parent.top
            top: toolBar.bottom
            left: parent.left
//            bottom: parent.bottom
        }
    }



    TopButtons{
        id: topButtons
        width: parent.width* 0.5
        height: parent.height* .3
        anchors{
            top: toolBar.bottom
            left: buttonsRect.right
            leftMargin: 20
            topMargin: 20* (parent.height/1080)
        }
    }

    DropShadow {
        anchors.fill: source
        horizontalOffset: 3
        verticalOffset: 3
        radius: 8
        samples: 16
        color: "#80000000"
        source: topButtons
    }

    Rectangle{
        id: centralRect
        width: parent.width* .51146
        height: parent.height* .55
        anchors{
            bottom: parent.bottom
            left: buttonsRect.right
            right: parent.right
            leftMargin: 20
            rightMargin: 30
            bottomMargin: 5
        }
        radius: 8
        border.color: "#CDCACA"

//        AddUser{
//            id: addUser
//        }
    }


    RoundButton{
        id: approveButton
        width: parent.width* .14583
        anchors{
            top: topButtons.top
            bottom: topButtons.bottom
            left: topButtons.right
            right: parent.right
            leftMargin: 20
            rightMargin: 30
        }
        radius: 25

        Label{
            id: pendingApprovalsLabel
            width: parent.width* .71886
            anchors.centerIn: parent
            text: "Check for users whose borrow requests are pending"
            wrapMode: Text.WordWrap
            font.italic: true

        }


        RoundButton{
            id: approvedButton
            width: parent.width* .56583
            height: parent.height* .16
            anchors{
                top: parent.top
                right: parent.right
                topMargin: 10
                rightMargin: 20
            }
            text: "Approved"
            hoverEnabled: true

            ToolTip.delay: 1000
            ToolTip.timeout: 5000
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Show approved requests.")

            onClicked: {
                login.visible = !login.visible
            }
        }
    }

    DynamicBox{
        id: dynamicBox
        anchors{
            top:buttonsRect.bottom
            topMargin: 10
            left: parent.left
            right: buttonsRect.right
            bottom: centralRect.bottom
        }
    }
}

