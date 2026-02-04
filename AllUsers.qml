import QtQuick
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import com.allUsersListModel 1.0
import com.databaseManager 1.0
import "DynamicComponentLoader.js" as ComponentLoader


Rectangle {
    id: allUsers
    visible: true
    width: parent.width //600
    height: parent.height //400
    color: "#FBFBFB"

    property var addNewUser: null
    property var settingsPage: null

    //Initialize databaseManager here
    DatabaseManager{
        id: dbManager
    }

    property int itemsPerPage: 100
    property string currentUserType: "all"
    property int totalPages: Math.ceil(allUsersList.getTotalUsersCount(currentUserType)/itemsPerPage)

    property int previousPage: 0
    property int currentPage: 1
    property int nextPage: 2

    signal closeClicked()

    MouseArea{
        id: allUsersMA
        anchors.fill: parent
    }

    Rectangle{
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors{
            left: parent.left
            leftMargin: 10
            top: parent.top
            topMargin: 10
        }

        Rectangle{
            id: backBtnRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"

            Image{
                id: back
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/backArrow.png"
            }
        }

        MouseArea{
            id: backMA
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                backRect.color = "#E8E3E4"
            }
            onExited: {
                backRect.color = "#DDDDDD"
            }

            onClicked: {
                allUsers.closeClicked()
            }
        }
    }

    Rectangle{
        id: cartegoryContainer
        color: "#FBFBFB" //"#e2dada"
        width: parent.width* .21
        property int btnWidth: width* .87

        anchors{
            left: parent.left
            top: backRect.bottom
            bottom: parent.bottom
        }

        Rectangle{
            id: categoriesLabelRect
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: parent.top
                topMargin: 16
                left: parent.left
                leftMargin: 5
            }

            color: "transparent"
            radius: 4

            Label{
                id: categoriesTxt
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                text: " Categories and Quick Actions"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                elide: "ElideRight"
                maximumLineCount: 1
            }
        }

        CustomButton{
            id: category0Btn
            text: qsTr("All users")
            height: 50
            width: cartegoryContainer.btnWidth
            anchors{
                top: categoriesLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                pageTitle.text = qsTr("All Users")
                currentUserType = "all"
                resetPagination()
                fetchCurrentPageData()
            }
        }

        CustomButton{
            id: category1Btn
            text: qsTr("Students")
            height: 50
            width: cartegoryContainer.btnWidth
            anchors{
                top: category0Btn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                pageTitle.text = qsTr("Students")
                currentUserType = "student"
                resetPagination()
                fetchCurrentPageData()
            }
        }


        CustomButton{
            id: category2Btn
            text: qsTr("Staff")
            height: 50
            width: cartegoryContainer.btnWidth
            anchors{
                top: category1Btn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }
            onClicked: {
                pageTitle.text = qsTr("Staff")
                currentUserType = "staff"
                resetPagination()
                fetchCurrentPageData()
            }
        }

        CustomButton{
            id: category3Btn
            text: qsTr("Other users")
            height: 50
            width: cartegoryContainer.btnWidth
            anchors{
                top: category2Btn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked: {
                pageTitle.text = qsTr("Other users")
                currentUserType = "other_users"
                resetPagination()
                fetchCurrentPageData()
            }
        }

        Rectangle{
            id: actionsLabelRect
            height:40
            width: cartegoryContainer.btnWidth
            anchors{
                top: category3Btn.bottom
                topMargin: 16
                left: parent.left
                leftMargin: 5
            }

            color: "transparent"
            radius: 4

            Label{
                id: quickActionsTxt
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                text: "Quick Actions"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                elide: "ElideRight"
                maximumLineCount: 1
            }
        }

        CustomButton{
            id: action1Btn
            text: qsTr("Add new user")
            height: 50
            width: cartegoryContainer.btnWidth
            anchors{
                top: actionsLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                ComponentLoader.customCreateComponent(addNewUser, "AddUser", mainContainer)
            }
        }

        CustomButton{
            id: openSettingsBtn
            text: qsTr("Open settings")
            height: 50
            width: cartegoryContainer.btnWidth
            anchors{
                top: action1Btn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                ComponentLoader.customCreateComponent(settingsPage,"Settings/SettingsPage", page2)
            }
        }
    }

    Rectangle{
        id: pageTitleRect
        height: 40
        width: pageTitle.width
        color: "transparent"
        anchors{
            top: parent.top
            topMargin: 10
            left: cartegoryContainer.right
            leftMargin: 20
        }

        Text{
            id: pageTitle
            text: qsTr("All users")
            font.pointSize: 16
            font.bold: true
            color: "#878585"
            anchors{
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }
    }

    Rectangle{
        id: allUsersSearchBox
        width: allUsers.width < 680 ? 400* (parent.width/1080) : 400
        height: 40
        radius: 4
        color: "transparent"
        border.color: "#E0E0E0"
        visible: allUsers.width > 325
        anchors{
            right: parent.right
            rightMargin: 10
            verticalCenter: pageTitleRect.verticalCenter
        }

        Image {
            id: searchIcon
            anchors{
                left: parent.left
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }

            height: parent.height *.45
            fillMode: Image.PreserveAspectFit
            source: "assets/searchIcon.png"

            MouseArea{
                id: searchMA
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                enabled: navigationTextInput.text !== ""
                onClicked: {

                }
            }
        }

        Text{
            id: searchBoxPlaceHolder
            visible: navigationTextInput.text === ""
            color: "#585757"
            text: "Search"
            anchors{
                left: searchIcon.right
                verticalCenter: parent.verticalCenter
                leftMargin: 20
            }
        }

        MouseArea{
            id: toolBarSearchBoxMA
            cursorShape: "IBeamCursor"
            anchors{
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                left: searchIcon.right
                leftMargin: 20
            }

            TextInput{
                id: navigationTextInput
                clip: true
                anchors{
                    right: parent.right
                    rightMargin: 5
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11

                // Real-time search as user types
                onTextChanged: {
                    searchDebounceTimer.restart()
                }
            }

            // Debounce timer to avoid too many searches while typing
            Timer {
                id: searchDebounceTimer
                interval: 300  // Wait 300ms after user stops typing
                onTriggered: {
                    if (navigationTextInput.text.trim().length > 0) {
                        allUsersList.searchUsers(navigationTextInput.text)
                    } else {
                        // When search is cleared, reload current view
                        fetchCurrentPageData()
                    }
                }
            }
        }
    }


    ListView {
        id: listView
        clip: true
        anchors{
            top: pageTitleRect.bottom
            topMargin: 10
            left: cartegoryContainer.right
            leftMargin: 20
            bottom: parent.bottom
            right: parent.right
        }

        model: AllUsersListModel{
            userList: allUsersList
        }

        delegate: Item {
            width: listView.width
            height: 50

            Rectangle {
                id: delegateItemRect
                width: parent.width
                height: parent.height
                color: "transparent"
                anchors.left: parent.left

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10



                    Rectangle {
                        id: userProfileRect2
                        height: parent.height* .80
                        width: height
                        radius: width/2
                        clip: true
                        color: "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: sourceItem2
                            source: "assets/userImage2.jpg"
                            anchors.centerIn: parent
                            width: parent.width //* 0.4688
                            height: width
                            visible: false
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }

                        MultiEffect {
                            source: sourceItem2
                            anchors.fill: sourceItem2
                            maskEnabled: true
                            maskSource: mask2
                            smooth: true
                        }

                        Item {
                            id: mask2
                            width: sourceItem2.width
                            height: sourceItem2.height
                            layer.enabled: true
                            visible: false

                            Rectangle {
                                width: sourceItem2.width
                                height: sourceItem2.height
                                radius: width / 2
                                color: "black"
                            }
                        }

                        Rectangle{
                            id: borderRect
                            height: parent.height + 2
                            width: parent.width + 2
                            anchors.centerIn: parent
                            color: "transparent"
                            border.color: "white"
                            border.width: 2
                            radius: width/2
                        }
                    }


                    Column {
                        spacing: 5

                        Row{
                            spacing: 5
                            Text {
                                text: model.firstName
                                font.pixelSize: 16
                                color: "black"
                                elide: "ElideRight"
                                maximumLineCount: 1
                            }

                            Text {
                                text: model.lastName
                                font.pixelSize: 16
                                color: "black"
                                elide: "ElideRight"
                                maximumLineCount: 1
                            }
                        }

                        Row{
//                            spacing: 5
                            Text {
                                text: model.userRole
                                font.pixelSize: 12
                                color: "#606060"
                                elide: "ElideRight"
                                maximumLineCount: 1
                            }

                            Text {
                                text: {
                                    if(model.userRole === "Student" && model.admNo){
                                        return ": " + model.admNo
                                    }else if(model.userRole === "Staff" && model.staffNo){
                                        return ": " + model.staffNo
                                    }else if(model.userRole === "Other user" && model.userNo){
                                        return ": " + model.userNo
                                    }else{
                                        return ""
                                    }
                                }

                                font.pixelSize: 12
                                color: "#606060"
                                elide: "ElideRight"
                                maximumLineCount: 1
                            }
                        }
                    }
                }

                MouseArea{
                    id: delegateItemMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        delegateItemRect.color = "#F5F5F5"
                        deleteIconRect.visible = true
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                        deleteIconRect.visible = false
                    }
                }

                Rectangle{
                    id: deleteIconRect
                    visible: false
                    width: 20
                    height: 20
                    color: "transparent"
                    anchors{
                        right: parent.right
                        rightMargin: 50
                        verticalCenter: parent.verticalCenter
                    }

                    MouseArea{
                        id: deleteIconMA
                        anchors.fill: parent
                        hoverEnabled: true

                        Image{
                            id: deleteIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: "assets/deleteClosed.png"
                        }

                        onEntered: {
                            deleteIcon.source = "assets/deleteOpen.png"
                        }

                        onExited: {
                            deleteIcon.source = "assets/deleteClosed.png"
                        }
                        onClicked: {
                            allUsersList.removeUser(index)//to be changed
                        }
                    }
                }
            }

            Rectangle {
                id: separator
                width: delegateItemRect.width* .95
                height: 1
                color: "#E0E0E0"
                anchors{
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }
    }

    //navigation to next and previous pages
    Rectangle {
        id: navigationRect
        width: 200
        height: 50
        radius: 8
        border.color: "lightgray"
        color: "white"
        opacity: 0.9

        // Initial position
        x: Math.min(Math.max(0, parent.width - 230), parent.width - width)
        y: Math.min(Math.max(0, parent.height - 80), parent.height - height)

        // Ensure the rectangle stays within parent bounds when parent is resized
        onXChanged: {
            if (x < 0) x = 0
            if (x > parent.width - width) x = parent.width - width
        }
        onYChanged: {
            if (y < 0) y = 0
            if (y > parent.height - height) y = parent.height - height
        }

        MouseArea {
            id: navigationRectMA
            anchors.fill: parent
            drag {
                target: parent
                minimumX: 0
                minimumY: 0
                maximumX: parent.parent.width - parent.width
                maximumY: parent.parent.height - parent.height
                smoothed: true
            }
            onReleased: console.log("Rectangle moved to x:", parent.x, "y:", parent.y)
        }

        Image {
            id: previousNavigator
            width: 32
            height: 32
            source: enabled ? "assets/leftArrow.png" : "assets/leftChevron.png"
            enabled: previousPage >0
            anchors{
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }

            MouseArea{
                id: previousPageMA
                anchors.fill: parent
                onClicked: {
                    if (currentPage > 1) {
                        --currentPage
                        --previousPage
                        --nextPage
                        fetchCurrentPageData()
                    }
                }
            }
        }

        Text {
            id: previousPageText
            text: previousPage == 0 ? "" : previousPage
            color: "gray"
            font.pointSize: 11
            anchors{
                left: previousNavigator.right
                leftMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
        }

        Image {
            id: nextNavigator
            width: 32
            height: 32
            source: enabled ? "assets/rightArrow.png" : "assets/rightChevron.png"
            enabled: currentPage < totalPages
            anchors{
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }

            MouseArea{
                id: nextPageMA
                anchors.fill: parent
                onClicked: {
                    if (currentPage < totalPages) {
                        ++currentPage
                        ++previousPage
                        ++nextPage
                        fetchCurrentPageData()
                    }
                }
            }
        }

        Text {
            id: nextPageText
            text: nextPage <= totalPages ? nextPage : ""
            color: "gray"
            font.pointSize: 11
            anchors{
                right: nextNavigator.left
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }
            verticalAlignment: Text.AlignVCenter
        }

        TextField {
            id: pageInput
            height: parent.height * 0.8
            font.pointSize: 11
            color: "red"
            validator: IntValidator { bottom: 1; top: totalPages }
            anchors {
                left: previousPageText.right
                leftMargin: 5
                right: nextPageText.left
                rightMargin: 5
                verticalCenter: parent.verticalCenter
            }
            text: currentPage
            horizontalAlignment: TextField.AlignHCenter
            verticalAlignment: TextField.AlignVCenter

            onAccepted: {
                let newPage = parseInt(text)
                if (newPage >= 1 && newPage <= totalPages) {
                    currentPage = newPage
                    previousPage = Math.max(0, newPage - 1)
                    nextPage = Math.min(totalPages, newPage + 1)
                    fetchCurrentPageData()
                } else {
                    text = currentPage  // Reset to valid value
                }
            }
        }
    }
    function resetPagination() {
        currentPage = 1
        previousPage = 0
        nextPage = 2
        totalPages= Math.ceil(allUsersList.getTotalUsersCount(currentUserType)/itemsPerPage)
    }

    function fetchCurrentPageData() {
        const offset = currentPage //* itemsPerPage
        allUsersList.fetchUsers(currentUserType, offset, itemsPerPage)
    }

    Component.onCompleted:{
        //allUsersList.fetchUsers("Student", 0, 100)
        currentUserType = "all"
        resetPagination()
        fetchCurrentPageData()
        totalPages= Math.ceil(allUsersList.getTotalUsersCount(currentUserType)/itemsPerPage)
    }
}
