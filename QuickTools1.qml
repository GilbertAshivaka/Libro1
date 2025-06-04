import QtQuick
import QtQuick.Controls
import "DynamicComponentLoader.js" as CustomComponentLoader


Rectangle{
    id: quickTools1
    anchors.fill: parent
    color: "#FDFDFD"
//    color: "#EEEEEE"

    property var returnBook: null
    property var addUser: null
    property var pendingApprovals: null
    property var issueBook: null
    property var approved: null
    property var moreTools: null

    TextUtils{
        id: textUtils
    }

    Rectangle{
        id: mainRect
        width: parent.width* 14/24
        height: 400
        radius: 10
        color: "white"
        border.color: "#E0E0E0"
        clip: true
        anchors{
            top: parent.top
            left: parent.left
            topMargin: 30
            leftMargin: 40
        }

        Rectangle{
            id: menuRect
            width: 40
            height: 30
            radius: 4
            anchors{
                right: parent.right
                rightMargin: 30
                verticalCenter: mainRectTitle.verticalCenter
            }

            Image{
                id: menuImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/menu.png"
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    menuRect.color = "#E8E3E4"
                }
                onExited: {
                    menuRect.color = "white"
                }

                onClicked: {
                    menu.open()
                }
            }

            Menu {
                id: menu
                width: 120
                y: menuRect.height

                MenuItem {
                    height: 40
                    text: "All tools..."
                }
            }
        }

        Rectangle{
            id: mainRectTitle
            height: mainTitleTxt.height
            width: parent.width
            color: "transparent"
            clip: true
            anchors{
                top: parent.top
                topMargin: 10
                left: parent.left
                leftMargin: 10
                right: menuRect.left
            }

            Text{
                id: mainTitleTxt
                width: parent.width
                text: "Quick tools for you"
                font.pixelSize: 16
                font.bold: true
//                wrapMode: Text.WordWrap
            }
        }

        Rectangle{
            id: issueBookContainer
            width: parent.width/2- (40*(mainRect.width/quickTools1.width))
            color: "transparent"
            height: 160
            clip: true
            anchors{
                left: parent.left
                leftMargin: 10
                top: mainRectTitle.bottom
                topMargin: 20
            }

            Rectangle{
                id: issueBookIconRect
                width: 48
                height: 48
                color: "transparent"
                anchors{
                    top: parent.top
                    topMargin: 10
                    left: parent.left
                    leftMargin: 10
                }

                Image{
                    id: issueBookIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/contract.png"
                }
            }

            Rectangle{
                id: issueBookRect
                color: "transparent"
                width: parent.width
                height: issueBookTxt.height
                anchors{
                    left: issueBookIconRect.right
                    rightMargin: 10
                    bottom: issueBookIconRect.bottom
                }

                Text{
                    id: issueBookTxt
                    width: parent.width
                    text: "Check out"
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle{
                id: issueBookDescriptionRect
                color: "transparent"
                width: parent.width- 10
                height: issueBookDescription.height
                anchors{
                    top: issueBookRect.bottom
                    topMargin: 10
                    left: parent.left
                    leftMargin: 10
                }

                Text{
                    id: issueBookDescription
                    anchors{
                        left: parent.left
                        right: parent.right
                        rightMargin: 10
                    }
                    text: "Easily lend book to users, you can specify issuing policies in settings"
                    width: parent.width
                    font.pixelSize: 10
                    color: "#606060"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            MouseArea{
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onEntered: {
                    issueBookContainer.color = "#EFEDED"
                }

                onExited: {
                    issueBookContainer.color = "transparent"
                }


                onClicked: {
                    CustomComponentLoader.customCreateComponent(issueBook,"IssueBookSearchList", mainPageContainer)
                }
            }

            Button {
                text: "Check out"
                anchors{
                    top: issueBookDescriptionRect.bottom
                    topMargin: 10
                    right: parent.right
                    rightMargin: 20
                }

                background: Rectangle {
                    color: "transparent"
                    border.color: "#0078D4"
                    border.width: 1
                    radius: 5
                }
                contentItem: Text {
                    text: "Check out now"
                    color: "#0078D4"
                    font.pixelSize: 12
                }

                onClicked: {
                    CustomComponentLoader.customCreateComponent(issueBook,"IssueBookSearchList", mainPageContainer)  
                }
            }
            Component.onCompleted: {
                console.log(width)
            }
        }

        Rectangle{
            id: returnBookContainer
//            width: parent.width/2
            color: "transparent"
            height: 160
            clip: true
            anchors{
                left: issueBookContainer.right
                leftMargin: 20
                top: issueBookContainer.top
                right: parent.right
                rightMargin: 10
            }

            Rectangle{
                id: returnBookIconRect
                width: 48
                height: 48
                color: "transparent"
                anchors{
                    top: returnBookContainer.top
                    topMargin: 10
                    left: parent.left
                    leftMargin: 10
                }

                Image{
                    id: returnBookIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/returnBook.png"
                }
            }

            Rectangle{
                id: returnBookRect
                color: "transparent"
                width: parent.width
                height: returnBookTxt.height
                anchors{
                    left: returnBookIconRect.right
                    leftMargin: 10
                    bottom: returnBookIconRect.bottom
                }
                clip: true

                Text{
                    id: returnBookTxt
                    width: parent.width
                    text: "Check in"
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle{
                id: returnBookDescriptionRect
                color: "transparent"
                width: parent.width- 10
                height: returnBookDescription.height
                anchors{
                    top: returnBookRect.bottom
                    topMargin: 10
                    left: parent.left
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 10
                }

                Text{
                    id: returnBookDescription
                    anchors{
                        left: parent.left
                        right: parent.right
                        rightMargin: 10
                    }

                    text: "Manage the return process smoothly and and update the status of borrowed books"
                    width: parent.width
                    font.pixelSize: 10
                    color: "#606060"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            MouseArea{
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onEntered: {
                    returnBookContainer.color = "#EFEDED"
                }

                onExited: {
                    returnBookContainer.color = "transparent"
                }


                onClicked:{
                    CustomComponentLoader.customCreateComponent(returnBook,"ReturnBook", mainPageContainer)
                }
            }

            Button {
                text: "Check in"
                anchors{
                    top: returnBookDescriptionRect.bottom
                    topMargin: 10
                    right: parent.right
                    rightMargin: 20
                }

                background: Rectangle {
                    color: "transparent"
                    border.color: "#0078D4"
                    border.width: 1
                    radius: 5
                }
                contentItem: Text {
                    text: "Check in now"
                    color: "#0078D4"
                    font.pixelSize: 12
                }

                onClicked:{
                    CustomComponentLoader.customCreateComponent(returnBook,"ReturnBook", mainPageContainer)
                }
            }
        }

        Rectangle{
            id: addUserContainer
//            width: parent.width/2
            color: "transparent"
            height: 160
            clip: true
            anchors{
                left: parent.left
                leftMargin: 10
                top: issueBookContainer.bottom
                right: issueBookContainer.right
            }

            Rectangle{
                id: addUserIconRect
                width: 48
                height: 48
                color: "transparent"
                anchors{
                    top: addUserContainer.top
                    topMargin: 10
                    left: parent.left
//                    leftMargin: 10
                }

                Image{
                    id: addUserIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/addGroup1.png"
                }
            }

            Rectangle{
                id: addUserRect
                color: "transparent"
                width: parent.width
                height: returnBookTxt.height
                anchors{
                    left: addUserIconRect.right
//                    leftMargin: 10
                    bottom: addUserIconRect.bottom
                }

                Text{
                    id: addUserTxt
                    width: parent.width
                    text: "Add user"
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle{
                id: addUserDescriptionRect
                color: "transparent"
                width: parent.width -10
                height: returnBookDescription.height
                anchors{
                    top: addUserRect.bottom
                    topMargin: 10
                    left: parent.left
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 10
                }

                Text{
                    id: addUserDescription
                    anchors.left: parent.left
                    text: "Register and manage new library members, there's an option to add many users at once"
                    width: parent.width
                    font.pixelSize: 10
                    color: "#606060"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            MouseArea{
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onEntered: {
                    addUserContainer.color = "#EFEDED"
                }

                onExited: {
                    addUserContainer.color = "transparent"
                }


                onClicked:{
                    CustomComponentLoader.customCreateComponent(addUser,"AddUser", mainPageContainer)
                }
            }

            Button {
                text: "Add user"
                anchors{
                    top: addUserDescriptionRect.bottom
                    topMargin: 10
                    right: parent.right
                    rightMargin: 20
                }

                background: Rectangle {
                    color: "transparent"
                    border.color: "#0078D4"
                    border.width: 1
                    radius: 5
                }
                contentItem: Text {
                    text: "Add user"
                    color: "#0078D4"
                    font.pixelSize: 12
                }

                onClicked:{
                    CustomComponentLoader.customCreateComponent(addUser,"AddUser", mainPageContainer)
                }
            }
        }

        Text {
            id: allToolsBtn
            text: "Show more tools"
            font.pixelSize: 12
            color: "#0078D4"
            anchors{
                bottom: parent.bottom
                bottomMargin: 10
                right: parent.right
                rightMargin: 20
            }

            Rectangle {
                id: underline
                visible: false
                width: allToolsBtn.width + 5  // some extra width for spacing
                height: 1
                color: "#0078D4"
                anchors.top: allToolsBtn.bottom
                anchors.horizontalCenter: allToolsBtn.horizontalCenter
                anchors.topMargin: 0  // spacing between text and underline
            }

            MouseArea{
                id: allToolsBtnMA
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: {
                    underline.visible = true
                }
                onExited: {
                    underline.visible = false
                }

                onClicked: {
                    CustomComponentLoader.customCreateComponent(moreTools,"ToolsContainerPage", mainPageContainer)
                }
                onPressed: {
                    allToolsBtn.color = "darkblue"
                    underline.color = "darkblue"
                }
                onReleased: {
                    allToolsBtn.color = "#0078D4"
                    underline.color = "#0078D4"
                }
            }
        }
    }

    Rectangle{
        id: secondRect
        width: parent.width/3
        height: 200
        radius: 10
        color: "white"
        border.color: "#E0E0E0"
        clip: true
        anchors{
            left: mainRect.right
            leftMargin: 20
            top: mainRect.top
        }

        Rectangle{
            id: secondRectTitle
            height: secondRectTitleTxt.height
            width: parent.width
            color: "transparent"
            clip: true
            anchors{
                top: parent.top
                topMargin: 20
                left: parent.left
                leftMargin: 20
//                right: approvedMenuRect.left
            }

            Text{
                id: secondRectTitleTxt
                width: parent.width
                text: textUtils.truncateText("Check and approve pending requests", textUtils.calculateMaxLength(parent.width, 16)) //"Check and approve pending requests"
                font.pixelSize: 16
                font.bold: true
//                wrapMode: Text.WordWrap
            }
        }

        Rectangle{
            id: approvedMenuRect
            width: 30
            height: 20
            radius: 4
            anchors{
                right: parent.right
                rightMargin: 10
                verticalCenter: secondRectTitle.verticalCenter
            }

            Image{
                id: approvedMenuImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:Libro1/assets/menu.png"
            }

            MouseArea{
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    approvedMenuRect.color = "#E8E3E4"
                }
                onExited: {
                    approvedMenuRect.color = "white"
                }

                onClicked: {
                    approvedMenu.open()
                }
            }

            Menu {
                id: approvedMenu
                width: 120
                y: approvedMenuRect.height

                MenuItem {
                    height: 40
                    text: "All tools..."
                }
            }
        }


        Rectangle{
            id: pendingRequestsContainer
//            width: parent.width/2
            color: "transparent"
            height: 80
            clip: true
            anchors{
                left: parent.left
                leftMargin: 10
                top: secondRectTitle.bottom
                topMargin: 10
                right: parent.right
                rightMargin: 10
            }

            Rectangle{
                id: pendingRequestsIconRect
                width: 24
                height: 24
                color: "transparent"
                anchors{
                    top: pendingRequestsContainer.top
                    topMargin: 10
                    left: parent.left
//                    leftMargin: 10
                }

                Image{
                    id: pendingRequestsIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/pending.png"
                }
            }

            Rectangle{
                id: pendingRequestsRect
                color: "transparent"
                width: parent.width
                height: pendingRequestsTxt.height
                clip: true
                anchors{
                    left: pendingRequestsIconRect.right
                    leftMargin: 10
                    bottom: pendingRequestsIconRect.bottom
                }

                Text{
                    id: pendingRequestsTxt
                    width: parent.width
                    text: "Pending requests"
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            Rectangle{
                id: pendingRequestsDescriptionRect
                color: "transparent"
                width: parent.width -10
                height: pendingRequestsDescription.height
                anchors{
                    top: pendingRequestsRect.bottom
                    topMargin: 10
                    left: parent.left
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 10
                }

                Text{
                    id: pendingRequestsDescription
                    anchors.left: parent.left
                    text: "Review and approve pending requests from users, ensuring each adheres to lending policies before proceeding"
                    width: parent.width
                    font.pixelSize: 10
                    color: "#606060"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            MouseArea{
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    CustomComponentLoader.customCreateComponent(pendingApprovals,"PendingApprovals", mainPageContainer)
                }
            }
        }

        Rectangle{
            id: approvedBtn
            width: parent.width* .5
            height: parent.height* .16
            radius: parent.width/4
//            color: "#878585"
            border.color: "#878585"
            border.width: 2
            clip: true
            anchors{
                bottom: parent.bottom
                bottomMargin: 20
                right: parent.right
                topMargin: 10
                rightMargin: 20
            }

            Text{
                id: approvedBtnTxt
                anchors.centerIn: parent
                text: "Approved"
//                color: "white"
                font.pixelSize: 16
                font.bold: true
            }

            Rectangle{
                id: approvedIconRect
                height: parent.height* .8
                width: 16
                color: "transparent"
                anchors{
                    left: approvedBtnTxt.right
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                Image{
                    id: approvedIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/tickMark.png"
                }
            }


            MouseArea{
                id: approvedBtnMA
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: {
                    approvedBtn.color = "#878585"
                    approvedBtnTxt.color = "white"
                }
                onExited: {
                    approvedBtn.color = "white"
                    approvedBtnTxt.color ="#878585"
                }

                onClicked:{
                    CustomComponentLoader.customCreateComponent(approved,"IssuedBooks", mainPageContainer)
                }
            }
        }

        Rectangle{
            id: quarterCircleRect
            height: 60
            width: 60
            radius: 10
            clip: true
            color: "transparent"
            anchors{
                left: parent.left
                bottom: parent.bottom
            }

            Image{
                id: quarterCircle
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/graduationHat.png"
            }
        }
    }
}
