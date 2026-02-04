import QtQuick 2.15
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item{
    id: gausianItem
//    height: parent.height
//    width: parent.width

    Image{
        id: library
        source: "qrc:Libro1/assets/library1"
        sourceSize: Qt.size(parent.width, parent.height)
        smooth: true
//            visible: false
    }

    GaussianBlur{
        id: libraryGausian
        anchors.fill: parent
        source: library
        radius: 8
        samples: 8
    }

//    RoundButton{
//        id: gausianButton
//        height: parent.height/12
//        width: parent.width * 1/10
//        anchors{
//            bottom: parent.bottom
//            right: parent.right
//        }
//        text: "Hide"
//        onClicked: {
//            gausianItem.visible = !gausianItem.visible
//        }
//    }



    Rectangle{
        id: adminLogin
        width: parent.width* .5
        height: parent.height* .65
//        color: "#6AEF9E"
        color: "transparent"
        radius: 5
        y: parent.height* .25

//        anchors.centerIn: parent

        anchors{
            horizontalCenter: parent.horizontalCenter
        }

        Component.onCompleted: console.log(width, height)

        Rectangle{
            id: adminAvatarRect
            height: 80
            width: height
            radius: width/2
            color: "#CECED7"
            clip: true
            anchors{
                top: parent.top
                topMargin: 20
//                horizontalCenter: adminUsername.horizontalCenter
                left: parent.left
            }

            Rectangle{
                id: profileRect
                height: adminAvatarRect.height* .7
                width: height
                color: "#CECED7"
                anchors{
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                Image{
                    id: adminAvatar
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/user.png"
//                    source: "qrc:Libro1/assets/1_jWx9suY2k3Ifq4B8A_vz9g.jpeg"

                }
            }
        }

        Rectangle{
            id: adminUsername
            radius: 5
            width: parent.width* .85
//            height: parent.height* 1/7
            height: 40
            anchors{
                left: parent.left
                top: adminAvatarRect.bottom
                topMargin: 20
                leftMargin: 10
            }

//            color: "#CBCECE"
            color: "white"

            MouseArea{
                id: adminUsernameMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: adminUsernameTextInput
                    clip: true
                    anchors{
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: 5
                    }

                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }
            }

            Text{
                id: usernamePlaceHolder
                visible: adminUsernameTextInput.text === ""
                color: "#585757"
                text: "Username"
                anchors{
                    left: parent.left
//                    bottom: parent.bottom
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: 16
            }


//            DropShadow {
//                    anchors.fill: source
//                    horizontalOffset: 3
//                    verticalOffset: 3
//                    radius: 8
//                    samples: 16
//                    color: "#80000000"
//                    source: adminUsername
//                }




        }

        Rectangle{
            id: adminPassword
            radius: 5
            width: parent.width* .85
//            height: parent.height* 1/7
            height: 40
            anchors{
                left: parent.left
                top: adminUsername.bottom
                topMargin: 20 //* (parent.height/350)
                leftMargin: 10
            }

//            color: "#CBCECE"
            color: "white"


            Text{
                id: passwordPlaceHolder
                visible: adminPasswordTextInput.text === ""
                color: "#585757"
                text: "Password"
                anchors{
                    left: parent.left
                    leftMargin: 5
//                    bottom: parent.bottom
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: 16
            }

            MouseArea{
                id: admPassMouse
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: adminPasswordTextInput
                    clip: true
                    anchors{
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        leftMargin: 5
                    }

                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    echoMode: TextInput.Password
                }
            }


        }

        RoundButton{
            id: adminLoginButton
//            width: parent.width* 1/3
            width: 120
            height: 40
//            height: parent.height* 1/8
            anchors{
                right: adminPassword.right
//                bottom: parent.bottom
                top: adminReset.bottom
            }
            text: "Login"
            onClicked: {
                if(appManager.adminLogin(adminUsernameTextInput.text.trim(), adminPasswordTextInput.text.trim())){
                  mainLoader.source = "Page2.qml"
                }
            }
        }

        Rectangle{
            id: adminReset
            width: parent.width* .5
//            height: parent.height* 1/7
            height: 40
            color: "transparent"
            anchors{
                left: adminPassword.left
//                bottom: parent.bottom
                top: adminPassword.bottom
                topMargin: 10
            }

            Text{
                id: adminResetText
                text: "New admin? Sign Up"
                anchors{
                    left: parent.left
                    bottom: parent.bottom
                    bottomMargin: 10
                }
                font.pixelSize: 16 /** (adminLogin.width/300)*/
                font.underline: true
                color: "blue"

                MouseArea{
                    id: resetMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked:{
                        console.log("Button Clicked")
                        loginSV.pop("MainLogin.qml")
                    }
                    onPressed: adminResetText.color = "darkblue"
                    onReleased: adminResetText.color = "blue"
                }
            }
        }
    }
}


