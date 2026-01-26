import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import "DynamicComponentLoader.js" as CustomComponentLoader


Rectangle {
    id: studentPage
    width: parent.width
    color: "#FBFBFB"

    property string imageSource: "assets/1_jWx9suY2k3Ifq4B8A_vz9g.jpeg"
    property var reservationPage: null


    // User info properties - populated from LoginManager after successful login
    property int currentUserId: loginManager ? loginManager.currentUserId : 0
    property string currentUserName: loginManager ? loginManager.currentUserName : "Student"
    property string currentUserNumber: loginManager ? loginManager.currentUserNumber : ""
    property string currentUserRole: loginManager ? loginManager.currentUserRole : "Student"

    // Additional details from UserManager
    property var userDetails: ({})
    property string branch: ""
    property string level: ""
    property int totalBooksIssued: 0

    // Load user details on component completion
    Component.onCompleted: {
        loadUserDetails()
    }

    function loadUserDetails() {
        if (currentUserId > 0 && typeof userManager !== 'undefined') {
            userDetails = userManager.getUserById(currentUserId)
            branch = userDetails.branch ? userDetails.branch : ""
            totalBooksIssued = userDetails.totalBooksIssued
            level = userDetails.level ? userDetails.level : ""
        }
    }

    // Refresh details when dialog updates them
    Connections {
        target: editDetailsDialog
        function onDetailsUpdated() {
            loadUserDetails()
        }
    }

    TextUtils{
        id: textUtils
    }

    Rectangle {
        id: studentPageTitleRect
        width: parent.width
        height: 50
        anchors {
            top: parent.top
            left: parent.left
        }
        clip: true

        Text {
            id: returnBookTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "Student"
            font.pointSize: 12
            color: "#878585"
        }
    }

//    Rectangle{
//        id: separator
//        width: parent.width
//        height: 1
//        anchors{
//            top: studentPageTitleRect.bottom
//        }
//        color: "lightgray"
//    }

    Item{
        id: container
        anchors{
            top: studentPageTitleRect.bottom //separator.bottom
            right: parent.right
            left: parent.left
            bottom: parent.bottom
        }

        Text {
            id: yourInfo
            text: qsTr("Your Info")
            anchors{
                top: container.top
                topMargin: 20
                left: parent.left
                leftMargin: 20
            }
            font.pointSize: 18
        }

        Rectangle{
            id: profilePicRect
            width: 200
            height: width
            radius: width/2
            property string imageSource: "assets/1_jWx9suY2k3Ifq4B8A_vz9g.jpeg"

            anchors{
                top: yourInfo.bottom
                topMargin: 10
                left: parent.left
                leftMargin: 20
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"

                Image {
                    id: sourceItem
                    source: profilePicRect.imageSource  //"assets/1_jWx9suY2k3Ifq4B8A_vz9g.jpeg"
                    anchors.centerIn: parent
                    width: parent.width //* 0.4688
                    height: width
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                }

                MultiEffect {
                    source: sourceItem
                    anchors.fill: sourceItem
                    maskEnabled: true
                    maskSource: mask
                }

                Item {
                    id: mask
                    width: sourceItem.width
                    height: sourceItem.height
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        width: sourceItem.width
                        height: sourceItem.height
                        radius: width / 2
                        color: "black"
                    }
                }

                FileDialog {
                    id: fileDialog
                    title: "Select Profile Picture"
                    nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif)"]
                    onAccepted: {
                        if (fileDialog.currentFile) {
                            var fileUrl = fileDialog.currentFile
                            console.log("Selected file:", fileUrl)
                            profilePicRect.imageSource = fileUrl
                        }
                    }
                    onRejected: {
                        console.log("Canceled")
                    }
                }

                Rectangle {
                    id: tooltip
                    width: parent.width/2
                    height: toolTipText.height + 20
                    color: Qt.rgba(0,0,0,0.5)
                    visible: false
                    anchors{
                        left: sourceItem.horizontalCenter
                        verticalCenter: sourceItem.verticalCenter

                    }

                    radius: 5

                    Text {
                        id: toolTipText
                        width: parent.width
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            rightMargin: 5
                            verticalCenter: parent.verticalCenter
                        }

                        color: "white"
                        text: "Click to change profile picture"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }

                MouseArea {
                    anchors.fill: sourceItem
                    cursorShape: "PointingHandCursor"
                    onClicked: fileDialog.open()
                    hoverEnabled: true
                    onEntered: tooltip.visible = true
                    onExited: tooltip.visible = false
                }
            }
        }

        Text{
            id: name
            text: userDetails.fullName || currentUserName
            anchors{
                top: profilePicRect.top
                topMargin: 10
                left: profilePicRect.right
                leftMargin: 20
            }
            font.pointSize: 14
            font.bold: true
        }

        Text{
            id: level
            text: "Level of Study:"
            anchors{
                top: name.bottom
                topMargin: 10
                left: profilePicRect.right
                leftMargin: 20
            }
            font.pointSize: 11
            font.bold: true
            color: "gray"
        }

        Text{
            id: _level
            text: studentPage.level || "N/A"
            anchors{
                verticalCenter: level.verticalCenter
                left: level.right
                leftMargin: 5
            }
            font.pointSize: 11
            color: "gray"
        }

        Text{
            id: registrationNumber
            text: "Registration Number:"
            anchors{
                top: level.bottom
                topMargin: 10
                left: profilePicRect.right
                leftMargin: 20
            }
            font.pointSize: 11
            font.bold: true
            color: "gray"
        }

        Text{
            id: _registrationNumber
            text: userDetails.admNo || currentUserNumber || "N/A"
            anchors{
                verticalCenter: registrationNumber.verticalCenter
                left: registrationNumber.right
                leftMargin: 5
            }
            font.pointSize: 11
            color: "gray"
        }

        Text{
            id: borrowScore
            text: "Currently Borrowed:"
            anchors{
                top: registrationNumber.bottom
                topMargin: 10
                left: profilePicRect.right
                leftMargin: 20
            }
            font.pointSize: 11
            font.bold: true
            color: "gray"
        }

        Text{
            id: _borrowScore
            text: typeof userManager !== 'undefined' && currentUserId > 0 ?
                  userManager.getCurrentlyBorrowedCount(currentUserId).toString() : "0"
            anchors{
                verticalCenter: borrowScore.verticalCenter
                left: borrowScore.right
                leftMargin: 5
            }
            font.pointSize: 11
            color: "gray"
        }

        Text{
            id: borrowCount
            text: "Total Books Issued:"
            anchors{
                top: borrowScore.bottom
                topMargin: 10
                left: profilePicRect.right
                leftMargin: 20
            }
            font.pointSize: 11
            font.bold: true
            color: "gray"
        }

        Text{
            id: _borrowCount
            text: totalBooksIssued.toString()
            anchors{
                verticalCenter: borrowCount.verticalCenter
                left: borrowCount.right
                leftMargin: 5
            }
            font.pointSize: 11
            color: "gray"
        }

        Text {
            id: editAcc
            text: qsTr("Edit account details")
            anchors{
                top: profilePicRect.bottom
                topMargin: 20
                left: profilePicRect.left
            }
            color: "blue"

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: "PointingHandCursor"
                onEntered: {
                    editAcc.color = "#878585"
                }
                onExited: {
                    editAcc.color = "blue"
                }
                onClicked: {
                    editDetailsDialog.userId = studentPage.currentUserId
                    editDetailsDialog.userRole = "Student"
                    editDetailsDialog.open()
                }
            }
        }

        Text {
            id: editAccExplanation
            text: qsTr("Your account details can only be edited with the admin's approval\nif they are not close let them know")
            anchors{
                top: editAcc.bottom
                topMargin: 10
                left: profilePicRect.left
            }
        }

        Rectangle{
            id: requestBtn
            width: 120
            height: 40
            color: "lightgray"
            border.width: 2
            border.color: "transparent"
            anchors{
                top: editAccExplanation.bottom
                topMargin: 20
                left: profilePicRect.left
            }

            Text{
                id: requestBtnText
                text: "Place book request" //textUtils.truncateText("Place book request", textUtils.calculateMaxLength(parent.width, requestBtnText.font.pixelSize))
                anchors.centerIn: parent
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    requestBtn.border.color = "gray"
                }
                onExited: {
                    requestBtn.border.color = "transparent"
                }
                onPressed: {
                    requestBtn.color = "gray"
                    requestBtn.width = 118
                    requestBtn.height = 38
                }
                onReleased: {
                    requestBtn.color = "lightgray"
                    requestBtn.width = 120
                    requestBtn.height = 40
                }
                onClicked: {
                    CustomComponentLoader.customCreateComponent(reservationPage,"ReservationPage", container)
                    historyPage.visible = false
                    feedbackForm.visible = false
                    suggestionForm.visible = false
                }
            }
        }

        Rectangle{
            id: logoutBtn
            width: 120
            height: 40
            color: "lightgray"
            border.width: 2
            border.color: "transparent"
            anchors{
                top: requestBtn.top
                left: requestBtn.right
                leftMargin: 10
            }

            Text{
                id: logoutBtnText
                text: "Logout" //textUtils.truncateText("Place book request", textUtils.calculateMaxLength(parent.width, requestBtnText.font.pixelSize))
                anchors.centerIn: parent
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    logoutBtn.border.color = "gray"
                }
                onExited: {
                    logoutBtn.border.color = "transparent"
                }
                onPressed: {
                    logoutBtn.color = "gray"
                    logoutBtn.width = 118
                    logoutBtn.height = 38
                }
                onReleased: {
                    logoutBtn.color = "lightgray"
                    logoutBtn.width = 120
                    logoutBtn.height = 40
                }
                onClicked: {
                    // Logout using LoginManager
                    if (typeof loginManager !== 'undefined') {
                        loginManager.logout()
                    }
                    mainLoader.source = "Login.qml"
                }
            }
        }

        Text {
            id: history
            text: qsTr("Show history")
            anchors{
                top: parent.height < 500 ? editAcc.top : requestBtn.bottom
                topMargin: parent.height < 500 ? 0 : 20
                left: parent.height < 500 ? parent.horizontalCenter : profilePicRect.left
            }
            color: "blue"

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: "PointingHandCursor"
                onEntered: {
                    history.color = "#878585"
                }
                onExited: {
                    history.color = "blue"
                }
                onClicked: {
                    historyPage.visible = !historyPage.visible
                }
            }
        }

        Text {
            id: historyExplanation
            text: qsTr("This will show your issue and return history starting with the most recent")
            anchors{
                top: history.bottom
                topMargin: 10
                left: history.left
            }
        }

        Item{
            id: feedbackItem
            width: 200
            height: 200
            anchors{
                right: parent.right
                top: parent.top
            }

            Image {
                id: suggestionBoxIcon
                source: "assets/suggestionIcon"
                anchors{
                    top: parent.verticalCenter
                    left: parent.left
                }
            }

            Text {
                id: suggestion
                text: qsTr("Suggestion box")
                anchors{
                    verticalCenter: suggestionBoxIcon.verticalCenter
                    left: suggestionBoxIcon.right
                    leftMargin: 10
                }
                color: "blue"

                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: "PointingHandCursor"
                    onEntered: {
                        suggestion.color = "#878585"
                        tooltip1.visible = !tooltip1.visible
                    }
                    onExited: {
                        suggestion.color = "blue"
                        tooltip1.visible = !tooltip1.visible
                    }
                    onClicked:{
                        suggestionDialog.open()
                    }
                }
            }

            Rectangle {
                id: tooltip1
                width: parent.width/2
                height: toolTipText.height + 20
                color: Qt.rgba(0,0,0,0.5)
                visible: false
                anchors{
                    bottom: suggestion.top
                    horizontalCenter: suggestion.horizontalCenter
                }

                Text {
                    id: toolTipText1
                    width: parent.width
                    anchors{
                        left: parent.left
                        leftMargin: 5
                        rightMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    color: "white"
                    text: "Suggestions and complains to Admin"
                    font.pixelSize:12
                    wrapMode: Text.WordWrap
                }
            }


            Image {
                id: feedbackIcon
                source: "assets/feedbackIcon"
                anchors{
                    top: suggestionBoxIcon.bottom
                    topMargin: 20
                    left: parent.left
                }
            }

            Text {
                id: feedback
                text: qsTr("Give feedback")
                anchors{
                    verticalCenter: feedbackIcon.verticalCenter
                    left: feedbackIcon.right
                    leftMargin: 10
                }
                color: "blue"

                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: "PointingHandCursor"
                    onEntered: {
                        feedback.color = "#878585"
                        tooltip2.visible = !tooltip2.visible
                    }
                    onExited: {
                        feedback.color = "blue"
                        tooltip2.visible = !tooltip2.visible
                    }
                    onClicked: {
                        feedbackDialog.open()
                    }
                }
            }

            Rectangle {
                id: tooltip2
                width: parent.width/2
                height: toolTipText.height + 20
                color: Qt.rgba(0,0,0,0.5)
                visible: false
                anchors{
                    top: feedback.bottom
                    horizontalCenter: suggestion.horizontalCenter
                }

                Text {
                    id: toolTipText2
                    width: parent.width
                    anchors{
                        left: parent.left
                        leftMargin: 5
                        rightMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    color: "white"
                    text: "Send feedback to developers"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }

        HistoryPage{
            id: historyPage
            visible: false
    //        anchors{
    //            top: profilePicRect.verticalCenter
    //            left: parent.horizontalCenter
    //        }
        }

        // Suggestion Dialog
        SuggestionDialog {
            id: suggestionDialog
            userId: studentPage.currentUserId
            userName: studentPage.currentUserName
            userNumber: studentPage.currentUserNumber
            userRole: studentPage.currentUserRole
        }

        // Feedback Dialog
        FeedbackDialog {
            id: feedbackDialog
            userId: studentPage.currentUserId
            userName: studentPage.currentUserName
            userNumber: studentPage.currentUserNumber
            userRole: studentPage.currentUserRole
        }

        // Edit Details Dialog
        EditDetailsDialog {
            id: editDetailsDialog
            userId: studentPage.currentUserId
            userRole: "Student"
        }
    }
}
