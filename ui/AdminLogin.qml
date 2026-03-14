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

        //toggle password visibility
        Rectangle {
            id: passwordToggleRect
            height: adminPassword.height/2
            width: height
            color: "transparent"
            anchors{
                left: adminPassword.right
                leftMargin: 8
                verticalCenter: adminPassword.verticalCenter
            }

            property bool passwordVisible: false  // ← track state

            Image {
                id: passwordToggle
                anchors.fill: parent
                source: passwordToggleRect.passwordVisible ? "../assets/hidden.png" :  "../assets/eye.png"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    passwordToggleRect.passwordVisible = !passwordToggleRect.passwordVisible
                    adminPasswordTextInput.echoMode = passwordToggleRect.passwordVisible
                            ? TextInput.Normal
                            : TextInput.Password
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
                top: loginErrorRect.bottom
            }
            text: "Login"
            onClicked: {
                if(appManager.adminLogin(adminUsernameTextInput.text.trim(), adminPasswordTextInput.text.trim())){
                    mainLoader.source = "Page2.qml"
                }else{
                    loginErrorRect.visible = true
                    logginErrorTimer.start()
                }
            }
        }

        Rectangle{
            id: adminCancel
            width: parent.width* .5
            height: 40
            color: "transparent"
            anchors{
                left: adminPassword.left
                top: adminPassword.bottom
                topMargin: 10
            }

            Text{
                id: cancel
                text: "Back"
                visible: !loginErrorRect.visible
                anchors{
                    left: parent.left
                    bottom: parent.bottom
                    bottomMargin: 10
                }
                font.pixelSize: 16
                font.underline: true
                color: "white"

                MouseArea{
                    id: cancelMA
                    anchors.fill: parent
                    cursorShape: "PointingHandCursor"
                    onClicked: {
                        loginSV.pop("MainLogin.qml")
                    }
                    onPressed: cancel.color = "darkblue"
                    onReleased: cancel.color = "white"
                }
            }
        }


        Rectangle{
            id: loginErrorRect
            width: parent.width* .5
            //height: parent.height* 1/7
            height: 40
            color: "transparent"
            visible: false
            anchors{
                left: adminPassword.left
                top: adminPassword.bottom
                topMargin: 10
            }

            Text{
                id: loginErrorRectText
                text: "Invalid password or username! Check details and try again."
                anchors{
                    left: parent.left
                    bottom: parent.bottom
                    bottomMargin: 10
                }
                font.pixelSize: 16 /** (adminLogin.width/300)*/
                color: "red"
            }
        }

        Timer{
            id: logginErrorTimer
            interval: 5000
            onTriggered: {
                if (loginErrorRect.visible){
                    loginErrorRect.visible = false
                }
            }
        }
    }
}


