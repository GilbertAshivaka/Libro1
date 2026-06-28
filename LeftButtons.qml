import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "DynamicComponentLoader.js" as CustomComponentLoader


Rectangle{
    id: buttonsRect
//    width: parent.width * .21
//    anchors{
//        top: parent.top
//        left: parent.left
//        bottom: parent.bottom
//    }
        color: "#E3E8EC"
//    color: "#f4f4f4"
        property int btnWidth: width* .87

        property var addBooks: null
        property var quickTools: null
        property var addUser: null
        property var settingsContainer: null
        property var allBooks: null
        property var issueBook: null
        property var returnBook: null
        property var pendingApprovals: null
        property var allUsers: null
        property var reportsPage: null
        property var settingsPage: null

        function createAddUserPage(){
            if (addUser == null){
                var component = Qt.createComponent("AddUser.qml")
                addUser = component.createObject(mainPageContainer)
                if (addUser !==null){
                    addUser.anchors.centerIn = mainPageContainer
                    addUser.closeClicked.connect(destroyAddUserPage)
                }
            }
        }

        function destroyAddUserPage(){
            if (addUser !== null){
                addUser.destroy()
                addUser = null
            }
        }


    ScrollView{
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
        id: sideScroll
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        contentHeight: allBooksBtn.height + allUsersBtn.height + addBookBtn.height + quickActions.height +
                               addUserBtn.height + issueBookBtn.height + returnBookBtn.height + pendingApprovalsBtn.height +
                               reportBtn.height + settingsBtn.height + logoutBtn.height + (5 * 11) + 20



        CustomButton{
            id: allBooksBtn
            text: qsTr("All Books")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: parent.top
                left: parent.left
                leftMargin: 5
                topMargin: 10
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(allBooks,"AllBooks", mainContainer)
            }
        }

        CustomButton{
            id: allUsersBtn
            text: qsTr("All Users")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: allBooksBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(allUsers,"AllUsers", mainContainer)
            }
        }

        CustomButton{
            id: addBookBtn
            text: qsTr("Add Book")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: allUsersBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
            onClicked:{
                CustomComponentLoader.customCreateComponent(addBooks,"AddBooks", mainPageContainer)
            }
        }

        Rectangle{
            id: quickActions
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: addBookBtn.bottom
                left: parent.left
                right: parent.right
                leftMargin: 5
                topMargin: 5
            }
            color: "#E0E0E0"
            radius: 4
            Text{
                id: quickActionsTxt
                anchors.left: parent.left
                anchors.leftMargin: 5
                text: "Quick Actions"
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
            }
        }

        CustomButton{
            id: addUserBtn
            text: qsTr("Add User")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: quickActions.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                createAddUserPage()
            }
        }

        CustomButton{
            id: issueBookBtn
            text: qsTr("Issue Book")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: addUserBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(issueBook,"IssueBookSearchList", mainPageContainer)
            }
        }

        CustomButton{
            id: returnBookBtn
            text: qsTr("Return Book")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: issueBookBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(returnBook,"ReturnBook", mainPageContainer)
            }
        }

        CustomButton{
            id: pendingApprovalsBtn
            text: qsTr("Pending Approvals")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: returnBookBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(pendingApprovals,"PendingApprovals", mainPageContainer)
            }
        }

        CustomButton{
            id: reportBtn
            text: qsTr("Reports")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: pendingApprovalsBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(reportsPage,"ReportsPage", mainContainer)
            }
        }

        CustomButton{
            id: settingsBtn
            text: qsTr("Settings")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: reportBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
               CustomComponentLoader.customCreateComponent(settingsPage,"Settings/SettingsPage", page2)
            }
        }

        CustomButton{
            id: logoutBtn
            text: qsTr("Logout")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: settingsBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                // Actually end the admin session, then return to login.
                appManager.adminLogout()
                mainDrawer.close()
                mainLoader.source = "Login.qml"
            }
        }
    }
}











