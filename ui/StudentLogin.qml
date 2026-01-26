import QtQuick 2.15
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

/**
 * StudentLogin.qml - Login page for Students
 *
 * Authentication:
 * - Username: Student's full name or email
 * - Password: adm_no (admission number) from students table
 */
Item{
    id: studentLogin
    property string errorMessage: ""

    // Connect to LoginManager signals
    Connections {
        target: loginManager

        function onLoginSuccessful(userName, userRole) {
            if (userRole === "Student") {
                mainLoader.source = "StudentPage.qml"
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
        id: studentGausian
        anchors.fill: parent
        source: library
        radius: 8
        samples: 8
    }

    Rectangle{
        id: studentLoginRect
        width: parent.width* .5
        height: parent.height* .7
        color: "transparent"
        radius: 5
        y: parent.height* .25

        anchors{
            horizontalCenter: parent.horizontalCenter
        }

        Rectangle{
            id: studentAvatarRect
            height: 80
            width: height
            radius: width/2
            color: "#CECED7"
            clip: true
            anchors{
                top: parent.top
                topMargin: 20
                left: parent.left
            }

            Rectangle{
                id: profileRect
                height: studentAvatarRect.height* .7
                width: height
                color: "#CECED7"
                anchors{
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }

                Image{
                    id: studentAvatar
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/user.png"
                }
            }
        }

        // Title
        Text {
            id: loginTitle
            text: "Student Login"
            font.pixelSize: 20
            font.bold: true
            color: "white"
            anchors {
                left: studentAvatarRect.right
                leftMargin: 15
                verticalCenter: studentAvatarRect.verticalCenter
            }
        }

        Rectangle{
            id: studentUsername
            radius: 4
            width: parent.width* .85
            height: 40

            anchors{
                left: parent.left
                top: studentAvatarRect.bottom
                topMargin: 20
                leftMargin: 10
            }

            color: "white"

            MouseArea{
                id: studentUsernameMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: studentUsernameTextInput
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
                visible: studentUsernameTextInput.text === ""
                color: "#585757"
                text: "Name or Email"

                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: 16
            }
        }

        Rectangle{
            id: studentPassword
            radius: 5
            width: parent.width* .85
            height: 40

            anchors{
                left: parent.left
                top: studentUsername.bottom
                topMargin: 20
                leftMargin: 10
            }
            color: "white"

            Text{
                id: passwordPlaceholder
                visible: studentPasswordTextInput.text === ""
                color: "#585757"
                text: "Admission Number"
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: 16
            }

            MouseArea{
                id: studentPasswordMA
                anchors.fill: parent
                cursorShape: "IBeamCursor"

                TextInput{
                    id: studentPasswordTextInput
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

        Rectangle{
            id: studentCancel
            width: parent.width* .5
            height: 40
            color: "transparent"
            anchors{
                left: studentPassword.left
                top: studentPassword.bottom
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

        RoundButton{
            id: studentLoginButton
            width: 120
            height: 40
            anchors{
                right: studentPassword.right
                top: studentCancel.bottom
            }
            text: "Login"

            onClicked: {
                errorMessage = ""
                if (studentUsernameTextInput.text.trim() === "" || studentPasswordTextInput.text.trim() === "") {
                    errorMessage = "Please enter your name/email and admission number"
                    return
                }

                // Use LoginManager to authenticate
                if (typeof loginManager !== 'undefined') {
                    loginManager.login(studentUsernameTextInput.text.trim(),
                                       studentPasswordTextInput.text.trim(),
                                       "Student")
                } else {
                    // Fallback for testing without LoginManager
                    mainLoader.source = "StudentPage.qml"
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
                top: studentLoginButton.bottom
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
            }
            wrapMode: Text.WordWrap
            width: parent.width * 0.85
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
