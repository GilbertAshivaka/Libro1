import QtQuick 2.15
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item{
    id: staffLogin
//    height: parent.height
//    width: parent.width
    property var staffPage: null
    property string errorMessage: ""

    // Connect to LoginManager signals
    Connections {
        target: loginManager

        function onLoginSuccessful(userName, userRole) {
            if (userRole === "Staff") {
                mainLoader.source = "StaffPage.qml"
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
                text: "Staff Number"
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

        //toggle password visibility
        Rectangle {
            id: passwordToggleRect
            height: staffPassword.height/2
            width: height
            color: "transparent"
            anchors{
                left: staffPassword.right
                leftMargin: 8
                verticalCenter: staffPassword.verticalCenter
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
                    staffPasswordTextInput.echoMode = passwordToggleRect.passwordVisible
                            ? TextInput.Normal
                            : TextInput.Password
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
                errorMessage = ""
                if (staffUsernameTextInput.text.trim() === "" || staffPasswordTextInput.text.trim() === "") {
                    errorMessage = "Please enter your name/email and staff number"
                    return
                }

                // Use LoginManager to authenticate
                if (typeof loginManager !== 'undefined') {
                    loginManager.login(staffUsernameTextInput.text.trim(),
                                       staffPasswordTextInput.text.trim(),
                                       "Staff")
                } else {
                    // Fallback for testing without LoginManager
                    mainLoader.source = "StaffPage.qml"
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
                top: staffLoginButton.bottom
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            wrapMode: Text.WordWrap
            width: parent.width * 0.85
            horizontalAlignment: Text.AlignHCenter
        }

    }
}
