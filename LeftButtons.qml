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
        property var pendingApprovals: null
        property var allUsers: null

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
        id: sideScroll
        anchors.fill: parent
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        contentHeight: allBooksBtn.height + addBooktn.height + addUserBtn.height + quickActions.height +
                               addBooksBtn.height + cartegoryBtn.height + settingsBtn.height + logoutBtn.height + reportBtn.height +
                               pendingApprovalsBtn.height + allUsersBtn.height + (10 * 6) + 10 // Add the space between items (5 units) for each item



        CustomButton{
            id: allBooksBtn
            text: qsTr("All books")
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
            id: addBooktn
            text: qsTr("Add book")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: allBooksBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
            onClicked:{
                CustomComponentLoader.customCreateComponent(addBooks,"AddBooks", mainPageContainer)
            }
        }

        CustomButton{
            id: addUserBtn
            text: qsTr("Add User")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: addBooktn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                createAddUserPage()
            }
        }

        Rectangle{
            id: quickActions
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: addUserBtn.bottom
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
            id: addBooksBtn
            text: qsTr("Add books")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: quickActions.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(addBooks,"AddBooks", mainContainer)
            }
        }



        CustomButton{
            id: cartegoryBtn
            text: qsTr("Issue book")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: addBooksBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(issueBook,"IssueBookSearchList", mainPageContainer)
            }
        }


        CustomButton{
            id: settingsBtn
            text: qsTr("Settings")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: cartegoryBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
               CustomComponentLoader.customCreateComponent(settingsContainer,"Settings", page2)
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
        }

        CustomButton{
            id: pendingApprovalsBtn
            text: qsTr("Pending Approvals")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: logoutBtn.bottom
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
            text: qsTr("Report")
            height: 50
            width: buttonsRect.btnWidth
            enabled: false
            anchors{
                top: pendingApprovalsBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
        }

        CustomButton{
            id: allUsersBtn
            text: qsTr("All Users")
            height: 50
            width: buttonsRect.btnWidth
            anchors{
                top: reportBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                CustomComponentLoader.customCreateComponent(allUsers,"AllUsers", mainContainer)
            }
        }
    }
}











