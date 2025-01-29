import QtQuick 2.15
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item{
    id: staffLogin
//    height: parent.height
//    width: parent.width
    property var staffPage: null

    Image{
        id: library
        source: "qrc:Libro1/assets/library1"
        sourceSize: Qt.size(parent.width, parent.height)
        smooth: true
    }

    GaussianBlur{
        id: staffGausian
        anchors.fill: parent
        source: library
        radius: 8
        samples: 8
    }

    Rectangle{
        id: staffLoginRect
        width: parent.width* .5
        height: parent.height* .7
        color: "transparent"
        radius: 5
        y: parent.height* .25

        anchors{
//            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter

        }

        Rectangle{
            id: staffAvatarRect
            height: 80
            width: height
            radius: width/2
            color: "#CECED7"
            clip: true
            anchors{
                top: parent.top
                topMargin: 20
//                horizontalCenter: parent.horizontalCenter
                left: parent.left
            }

            Rectangle{
                id: profileRect
                height: staffAvatarRect.height* .7
                width: height
                color: "#CECED7"
                anchors{
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                Image{
                    id: staffAvatar
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/user.png"
                }

            }
        }


        Rectangle{
            id: staffUsername
            radius: 4
            width: parent.width* .85
//            height: parent.height* 1/7
            height: 40

            anchors{
                left: parent.left
                top: staffAvatarRect.bottom
                topMargin: 20
                leftMargin: 10
            }

//            color: "#CBCECE"
            color: "white"

            MouseArea{
                id: staffUsernameMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: staffUsernameTextInput
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
                id: usernamePlaceholder
                visible: staffUsernameTextInput.text ===""
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

        //DropShadow


        Rectangle{
            id: staffPassword
            radius: 5
            width: parent.width* .85
//            height: parent.height* 1/7
            height: 40

            anchors{
                left: parent.left
                top: staffUsername.bottom
                topMargin: 20 //* (parent.height/350)
                leftMargin: 10
            }
//            color: "#CBCECE"
            color: "white"

            Text{
                id: passwordPlaceholder
                visible: staffPasswordTextInput.text === ""
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
                id: staffPasswordMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: staffPasswordTextInput
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
                    echoMode: "Password"
                }
            }
        }



        Rectangle{
            id: staffCancel
            width: parent.width* .5
//            height: parent.height* 1/7
            height: 40
            color: "transparent"
            anchors{
                left: staffPassword.left
                top: staffPassword.bottom
                topMargin: 10
            }

            Text{
                id: cancel
                text: "Cancel"
                anchors{
                    left: parent.left
                    bottom: parent.bottom
                    bottomMargin: 10
                }
                font.pixelSize: 16 /**(staffLoginRect.width/300)*/
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

        RoundButton{
            id: staffLoginButton
//            width: parent.width* 1/3
            width: 120
//            height: parent.height* 1/8
            height: 40
            anchors{
                right: staffPassword.right
//                bottom: parent.bottom
                top: staffCancel.bottom
            }
            text: "Login"

            onClicked: {
                mainLoader.source = "StaffPage.qml"
            }
        }

    }
}
