import QtQuick 2.15
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
//import "DynamicComponentLoader.js" as CustomComponentLoader

/**
 * UserLogin.qml - Login page for "Other Users" (non-student, non-staff)
 *
 * Authentication:
 * - Username: User's full name or email
 * - Password: user_no from other_users table
 */
Item{
    id: userLogin
//    height: parent.height
//    width: parent.width
    property var studentPage: null
    property string errorMessage: ""

    // Connect to LoginManager signals
    Connections {
        target: loginManager

        function onLoginSuccessful(userName, userRole) {
            if (userRole === "Other") {
                // Other users use a generic user page (can be StudentPage or a dedicated OtherUserPage)
                mainLoader.source = "OtherUserPage.qml"
            }
        }

        function onLoginFailed(error) {
            errorMessage = error
        }
    }

    Image{
        id: library
        source: "qrc:Libro1/assets/library1"
        sourceSize: Qt.size(parent.width, parent.height)
        smooth: true
    }

    GaussianBlur{
        id: userGausian
        anchors.fill: parent
        source: library
        radius: 8
        samples: 8
    }

    Rectangle{
        id: userLoginRect
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
            id: userAvatarRect
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
                height: userAvatarRect.height* .7
                width: height
                color: "#CECED7"
                anchors{
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                Image{
                    id: userAvatar
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/user.png"
                }

            }
        }


        Rectangle{
            id: userUsername
            radius: 4
            width: parent.width* .85
//            height: parent.height* 1/7
            height: 40

            anchors{
                left: parent.left
                top: userAvatarRect.bottom
                topMargin: 20
                leftMargin: 10
            }

//            color: "#CBCECE"
            color: "white"

            MouseArea{
                id: userUsernameMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: userUsernameTextInput
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
                visible: userUsernameTextInput.text ===""
                color: "#585757"
                text: "Name or Email"

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
            id: userPassword
            radius: 5
            width: parent.width* .85
//            height: parent.height* 1/7
            height: 40

            anchors{
                left: parent.left
                top: userUsername.bottom
                topMargin: 20 //* (parent.height/350)
                leftMargin: 10
            }
//            color: "#CBCECE"
            color: "white"

            Text{
                id: passwordPlaceholder
                visible: userPasswordTextInput.text === ""
                color: "#585757"
                text: "User Number"
                anchors{
                    left: parent.left
                    leftMargin: 5
//                    bottom: parent.bottom
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: 16
            }

             MouseArea{
                id: userPasswordMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: userPasswordTextInput
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
            id: userCancel
            width: parent.width* .5
//            height: parent.height* 1/7
            height: 40
            color: "transparent"
            anchors{
                left: userPassword.left
                top: userPassword.bottom
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
            id: userLoginButton
//            width: parent.width* 1/3
            width: 120
//            height: parent.height* 1/8
            height: 40
            anchors{
                right: userPassword.right
//                bottom: parent.bottom
                top: userCancel.bottom
            }
            text: "Login"

            onClicked: {
                errorMessage = ""
                if (userUsernameTextInput.text.trim() === "" || userPasswordTextInput.text.trim() === "") {
                    errorMessage = "Please enter your name/email and user number"
                    return
                }

                // Use LoginManager to authenticate as Other user
                if (typeof loginManager !== 'undefined') {
                    loginManager.login(userUsernameTextInput.text.trim(),
                                       userPasswordTextInput.text.trim(),
                                       "Other")
                } else {
                    // Fallback for testing without LoginManager
                    mainLoader.source = "OtherUserPage.qml"
                }
            }
        }

        // Error message display
        Text {
            id: errorText
            text: errorMessage
            color: "#FF6B6B"
            font.pixelSize: 14
            visible: errorMessage !== ""
            anchors {
                top: userLoginButton.bottom
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            wrapMode: Text.WordWrap
            width: parent.width * 0.85
            horizontalAlignment: Text.AlignHCenter
        }

    }
}
