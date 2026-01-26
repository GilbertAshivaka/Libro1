import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import "DynamicComponentLoader.js" as CustomComponentLoader

/**
 * OtherUserPage.qml - Profile page for "Other Users" (non-student, non-staff)
 *
 * Displays user information and library statistics for community members,
 * visiting researchers, or other library users.
 */
Rectangle {
    id: otherUserPage
    width: parent.width
    color: "#FBFBFB"

    property string imageSource: "assets/1_jWx9suY2k3Ifq4B8A_vz9g.jpeg"
    property var issueBook: null

    // User info properties - populated from LoginManager after successful login
    property int currentUserId: loginManager ? loginManager.currentUserId : 0
    property string currentUserName: loginManager ? loginManager.currentUserName : "Library User"
    property string currentUserNumber: loginManager ? loginManager.currentUserNumber : ""
    property string currentUserRole: loginManager ? loginManager.currentUserRole : "Other"

    // Additional details from UserManager
    property var userDetails: ({})
    property string residence: ""
    property int totalBooksIssued: 0

    // Load user details on component completion
    Component.onCompleted: {
        loadUserDetails()
    }

    function loadUserDetails() {
        if (currentUserId > 0 && typeof userManager !== 'undefined') {
            userDetails = userManager.getUserById(currentUserId)
            residence = userDetails.residence || ""
            totalBooksIssued = userDetails.totalBooksIssued || 0

            // Update display
            name.text = userDetails.fullName || currentUserName
            _residence.text = residence
            _registrationNumber.text = userDetails.userNo || currentUserNumber
            _borrowCount.text = totalBooksIssued.toString()
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
        id: otherUserPageTitleRect
        width: parent.width
        height: 50
        anchors {
            top: parent.top
            left: parent.left
        }
        clip: true

        Text {
            id: pageTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "Library User"
            font.pointSize: 12
            color: "#878585"
        }
    }

    Item{
        id: container
        anchors{
            top: otherUserPageTitleRect.bottom
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
                    source: profilePicRect.imageSource
                    anchors.centerIn: parent
                    width: parent.width
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
            text: currentUserName
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
            id: residenceLabel
            text: "Residence:"
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
            id: _residence
            text: residence
            anchors{
                verticalCenter: residenceLabel.verticalCenter
                left: residenceLabel.right
                leftMargin: 5
            }
            font.pointSize: 11
            color: "gray"
        }

        Text{
            id: registrationNumber
            text: "User Number:"
            anchors{
                top: residenceLabel.bottom
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
            text: currentUserNumber
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
                    editDetailsDialog.userId = otherUserPage.currentUserId
                    editDetailsDialog.userRole = "Other"
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
                text: "Place book request"
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
                onClicked:{
                    // TODO: Implement reservation page loading
                    console.log("Open reservation page")
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
                text: "Logout"
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
                    }
                    onExited: {
                        suggestion.color = "blue"
                    }
                    onClicked:{
                        suggestionDialog.open()
                    }
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
                    }
                    onExited: {
                        feedback.color = "blue"
                    }
                    onClicked: {
                        feedbackDialog.open()
                    }
                }
            }
        }

        HistoryPage{
            id: historyPage
            visible: false
        }

        // Suggestion Dialog
        SuggestionDialog {
            id: suggestionDialog
            userId: otherUserPage.currentUserId
            userName: otherUserPage.currentUserName
            userNumber: otherUserPage.currentUserNumber
            userRole: otherUserPage.currentUserRole
        }

        // Feedback Dialog
        FeedbackDialog {
            id: feedbackDialog
            userId: otherUserPage.currentUserId
            userName: otherUserPage.currentUserName
            userNumber: otherUserPage.currentUserNumber
            userRole: otherUserPage.currentUserRole
        }

        // Edit Details Dialog
        EditDetailsDialog {
            id: editDetailsDialog
            userId: otherUserPage.currentUserId
            userRole: "Other"
        }
    }
}
