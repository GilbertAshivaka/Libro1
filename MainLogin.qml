import QtQuick
import QtQuick.Controls
import "ui"
import Qt5Compat.GraphicalEffects


Rectangle {
    id: login
//    width: 1000
//    height: 500
    visible: false


    MouseArea{
        id: loginWindowMA
        anchors.fill: parent

        onPressed: {
            loginOptions.visible = false
        }
    }

    Image{
        id: backGroundImage
        anchors.fill: parent
        source: "qrc:Libro1/assets/library1"
    }

    Rectangle{
        id: loginLabelRect
        height: parent.height* .25
        width: parent.width* 1/3
        anchors{
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
//        color: Qt.rgba(255,255,255, 0.2)
        color: "transparent"
        border.color: "transparent"
        radius: 5

        Image{
            id: lockIcon
            width: parent.width* 1/14
            anchors{
                top: parent.top
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            source: "qrc:Libro1/assets/lock2.png"
            fillMode: Image.PreserveAspectFit
        }

        Label{
            text: "System locked. Some features may not be available in this mode. Click here to login and unlock."
            width: parent.width
            wrapMode: Text.Wrap
            anchors{
                left: parent.left
                top: lockIcon.bottom
                topMargin: 20
                bottom: parent.bottom
            }
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }

        MouseArea{
            id: loginLabelMA
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
//                loginLabelRect.border.color = "black"
                loginLabelRect.color = Qt.rgba(0,0,0, 0.4)
            }

            onExited: {
                loginLabelRect.border.color = "transparent"
//                loginLabelRect.color = Qt.rgba(255,255,255, 0.2)
                loginLabelRect.color = "transparent"
            }

            onPressed: {
                loginOptions.visible = !loginOptions.visible
            }

        }
    }

    Rectangle{
        id: askLogin
        visible: loginOptions.visible
        anchors{
            bottom: loginOptions.top
            bottomMargin: 5
            left: loginOptions.left
        }
        height: loginOptions.height/3
        width: loginLabelRect.width/2
        radius: 5
        color: Qt.rgba(0,0,0, 0.8)
        Text{
            id: loginAskText
            anchors{
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 5
            }
            verticalAlignment: Text.AlignVCenter
            text: "Who is loging in?"
            color: "white"
            font.pixelSize: 14
        }
    }

    Rectangle{
        id: loginOptions
        height: loginLabelRect.height
        width: loginLabelRect.width* .355
        anchors{
            left: loginLabelRect.right
            top: loginLabelRect.verticalCenter
            leftMargin: 5
        }
        radius: 3
        visible: false
        color: "transparent"

        RoundButton{
            id: showAdminLogin
            height: loginOptions.height/3
            anchors{
                left: loginOptions.left
                right: loginOptions.right
                top: loginOptions.top
            }
            text: "Admin"
            radius: 7

            onClicked: {
                loginSV.push("ui/AdminLogin.qml")
                loginOptions.visible = false
            }

        }

        RoundButton{
            id: showStaffLogin
            height: loginOptions.height/3
            anchors{
                left: loginOptions.left
                right: loginOptions.right
                top: showAdminLogin.bottom
            }
            text: "Teacher/ Staff"
            radius: 7

            onClicked: {
                loginSV.push("ui/StaffLogin.qml")
                loginOptions.visible = false
            }
        }

        RoundButton{
            id: showUserLogin
            height: loginOptions.height/3
            anchors{
                left: loginOptions.left
                right: loginOptions.right
                top: showStaffLogin.bottom
            }
            text: "Student/ Other User"
            radius: 7

            onClicked: {
                loginSV.push("ui/UserLogin.qml")
                loginOptions.visible = false
            }
        }
    }

//    AdminLogin{
//        id: adminLogin
//        width: parent.width
//        height: parent.height
//        visible: false
//    }

//    StaffLogin{
//        id: staffLogin
//        width: parent.width
//        height: parent.height
//        visible: false
//    }

//    UserLogin{
//        id: userLogin
//        width: parent.width
//        height: parent.height
//        visible: false
//    }
}
