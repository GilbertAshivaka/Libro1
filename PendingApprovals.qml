import QtQuick 2.15
import QtQuick.Controls 2.15
import "DynamicComponentLoader.js" as CustomComponentLoader

Rectangle {
    id: pendingApprovals
    anchors.fill: parent

    signal closeClicked()

    MouseArea{
        id: pendingApprovalsMA
        anchors.fill: parent
    }

    Rectangle {
        id: pendingApprovalsTitleRect
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

            text: "Pending Requests"
            font.pointSize: 12
            color: "#878585"
        }

        Rectangle{
            id: mainCloseRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: parent.right
                rightMargin: 10
                verticalCenter: pendingApprovalsTitleRect.verticalCenter
            }

            Rectangle{
                id: mainCloseImageRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: mainClose
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/close.png"
                }
            }

            MouseArea{
                id: mainCloseMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    mainCloseRect.color = "#E8E3E4"
                }
                onExited: {
                    mainCloseRect.color = "white"
                }

                onClicked: {
                    pendingApprovals.closeClicked()
                }
            }
        }


        Rectangle{
            id: sortRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: mainCloseRect.left
                rightMargin: 10
                verticalCenter: pendingApprovalsTitleRect.verticalCenter
            }

            Rectangle{
                id: sortIconRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: sortIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/sort.png"
                }
            }

            MouseArea{
                id: sortMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    sortRect.color = "#E8E3E4"
                }
                onExited: {
                    sortRect.color = "white"
                }

                onClicked: {

                }
            }
        }


        Rectangle{
            id: searchRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: sortRect.left
                rightMargin: 10
                verticalCenter: pendingApprovalsTitleRect.verticalCenter
            }

            Rectangle{
                id: searchIconRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: searchIcon
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:Libro1/assets/searchIcon.png"
                }
            }

            MouseArea{
                id: searchMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    searchRect.color = "#E8E3E4"
                }
                onExited: {
                    searchRect.color = "white"
                }

                onClicked: {
                    pendingApprovalsSearchBox.visible = !pendingApprovalsSearchBox.visible
                }
            }
        }
    }


    Rectangle{
        id: pendingApprovalsDetailsContainer
        width: parent.width
        anchors{
            top: pendingApprovalsTitleRect.bottom
            bottom: parent.bottom
        }
        color: "#FBFBFB"
        clip: true


        Searchbox{
            id: pendingApprovalsSearchBox
            width: 300
            height: 30
            border.color: "#E0E0E0"
            placeHolderText: "Search"
            visible: false
            anchors{
                top: parent.top
                topMargin: 10
                left: parent.left
                leftMargin: 10
            }
        }

        ListView {
            id: listView
    //        width: parent.width
    //        height: parent.height
            clip: true
            anchors{
//                top: {
//                    if(pendingApprovalsSearchBox.visible == true){
//                        anchors.top = pendingApprovalsSearchBox.bottom
//                    }
//                    else{
//                        anchors.top = parent.top
//                    }
//                }
                top: pendingApprovalsSearchBox.visible == true ? pendingApprovalsSearchBox.bottom : parent.top

                topMargin: 10
                left: parent.left
                leftMargin: 10
                bottom: parent.bottom
                right: parent.right
            }

            model: ListModel {
                ListElement {
                    title: "Artificial Intelligence: A Modern Approach"
                    author: "Stuart Russell and Peter Norvig"
                    iconSource: "assets/delegateBook.png"
                }
                ListElement {
                    title: "Pattern Recognition and Machine Learning"
                    author: "Christopher M. Bishop"
                    iconSource: "assets/delegateBook.png"
                }
                ListElement {
                    title: "Operating Systems: Three Easy Pieces"
                    author: "Remzi H. Arpaci-Dusseau and Andrea C. Arpaci-Dusseau"
                    iconSource: "assets/delegateBook.png"
                }
                ListElement {
                    title: "Computer Architecture: A Quantitative Approach"
                    author: "John L. Hennessy and David A. Patterson"
                    iconSource: "assets/delegateBook.png"
                }
                ListElement {
                    title: "Discrete Mathematics and Its Applications"
                    author: "Kenneth H. Rosen"
                    iconSource: "assets/delegateBook.png"
                }
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
    //                anchors.leftMargin: 20

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Image {
                            id: icon
                            source: model.iconSource
                            width: 32
                            height: 32
                        }

                        Column {
                            spacing: 5

                            Text {
                                text: model.title
                                font.pixelSize: 16
                                color: "black"
                            }

                            Text {
                                text: model.author
                                font.pixelSize: 12
                                color: "#606060"
                            }
                        }
                    }

                    MouseArea{
                        id: delegateItemMA
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            delegateItemRect.color = "#F5F5F5"
                            approveIconRect.visible = true
                            rejectIconRect.visible = true
                        }

                        onExited: {
                            delegateItemRect.color = "transparent"
                            approveIconRect.visible = false
                            rejectIconRect.visible = false
                        }

                        onClicked: {
                            issueBookPopup.bookTitle = model.title
                            issueBookPopup.open()
                        }
                    }

                    Rectangle{
                        id: approveIconRect
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
                            id: approveIconMA
                            anchors.fill: parent
                            hoverEnabled: true

                            Image{
                                id: approveIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: "assets/checkmarkGreen.png"
                            }

                            onEntered: {
                                approveIconRect.color = "#7ED297"
                                approveIcon.source = "assets/checkmarkWhite.png"
                            }

                            onExited: {
                                approveIconRect.color = "transparent"
                                approveIcon.source = "assets/checkmarkGreen.png"
                            }

                            onClicked: {
                                issueBookPopup.bookTitle = model.title
                                issueBookPopup.open()
                            }
                        }
                    }

                    Rectangle{
                        id: rejectIconRect
                        visible: false
                        width: 20
                        height: 20
                        color: "transparent"
                        anchors{
                            right: approveIconRect.left
                            rightMargin: 7
                            verticalCenter: parent.verticalCenter
                        }

                        MouseArea{
                            id: rejectIconMA
                            anchors.fill: parent
                            hoverEnabled: true

                            Image{
                                id: rejectIcon
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: "assets/crossRed.png"
                            }

                            onEntered: {
                                rejectIconRect.color = "#EE4E4E"
                                rejectIcon.source = "assets/crossWhite.png"
                            }

                            onExited: {
                                rejectIconRect.color = "transparent"
                                rejectIcon.source = "assets/crossRed.png"
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
        }


        Popup {
            id: issueBookPopup
            width: parent.width * .7
            height: parent.height * .6
            anchors.centerIn: parent
            modal: true
            focus: true
            topInset: 8
            leftInset: 8
            rightInset: 8
            bottomInset: 8
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

            property string bookTitle: ""

            Rectangle {
                id: issueBookID
                color: "#FBFBFB"
                anchors.fill: parent
                radius: 8
                clip: true

                Rectangle {
                    id: issuedBookTitleRect
                    width: parent.width * 2 / 3
                    height: 50
                    anchors {
                        top: parent.top
                        topMargin: 10
                        horizontalCenter: parent.horizontalCenter
                    }
                    color: "transparent"
                    clip: true

                    Text {
                        id: bookTitleText
                        width: parent.width
                        anchors {
                            left: parent.left
                            leftMargin: 20
                            verticalCenter: parent.verticalCenter
                        }

                        text: issueBookPopup.bookTitle
                        font.pointSize: 14
                    }
                }

                Rectangle {
                    id: closeRect
                    width: 30
                    height: 30
                    radius: 4
                    color: "#EE4E4E"
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        top: parent.top
                        topMargin: 10
                    }

                    Rectangle {
                        id: closeImageRect
                        width: 15
                        height: 15
                        radius: 4
                        anchors.centerIn: parent
                        color: "transparent"

                        Image {
                            id: close
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: "qrc:Libro1/assets/close.png"
                        }
                    }

                    MouseArea {
                        id: closeMA
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            closeRect.color = "#CB0707"  //"#E8E3E4"
                        }
                        onExited: {
                            closeRect.color = "#EE4E4E"  //"transparent"
                        }

                        onClicked: {
                            issueBookPopup.close()
                        }
                    }
                }

                Rectangle{
                    id: menuRect
                    width: 40
                    height: 30
                    radius: 4
                    color: "transparent"
                    anchors{
                        right: closeRect.left
                        rightMargin: 20
                        verticalCenter: closeRect.verticalCenter
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
                            menuRect.color = "transparent"
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
                            text: "Modify lending policies"
                        }
                    }
                }

                Rectangle {
                    id: bookNumberRect
                    width: parent.width / 3
                    height: 50
                    color: "white"
                    clip: true
                    anchors {
                        left: parent.left
                        leftMargin: 20
                        top: issuedBookTitleRect.bottom
                        topMargin: 10
                    }

                    Label {
                        id: bookIDLabel
                        anchors {
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        text: "Book No/ID: "
                        font.pointSize: 12
                    }

                    Text {
                        id: bookID
                        anchors {
                            left: bookIDLabel.right
                            leftMargin: 20
                            verticalCenter: parent.verticalCenter
                        }

                        text: "13/NRW/2024"
                        font.pointSize: 12
                    }
                }

                Rectangle {
                    id: separater
                    width: 2
                    color: "#DDDDDD"
                    anchors {
                        top: bookNumberRect.top
                        left: bookNumberRect.right
                        leftMargin: 10
                        bottom: bookNumberRect.bottom
                    }
                }

                Rectangle {
                    id: locationRect
                    width: parent.width / 3
                    height: 50
                    clip: true
                    anchors {
                        left: bookNumberRect.right
                        leftMargin: 30
                        verticalCenter: bookNumberRect.verticalCenter
                    }

                    Label {
                        id: locationLabel
                        text: "Location: "
                        anchors {
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pointSize: 12
                    }

                    Text {
                        id: location
                        anchors {
                            left: locationLabel.right
                            leftMargin: 20
                            verticalCenter: parent.verticalCenter
                        }

                        text: "Shelf NO. 12"
                        font.pointSize: 12
                    }

                    Rectangle{
                        id: moreInfoRect
                        height: 20
                        width: 20
                        color: "transparent"
                        anchors{
                            right: parent.right
                            rightMargin: 5
                            bottom: parent.bottom
                            bottomMargin: 5
                        }

                        Image {
                            id: moreInfoIcon
                            anchors.fill: parent
                            source: "assets/issueInfo1.png"
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea{
                            id: moreInfoMA
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                moreInfoIcon.source = "assets/issueInfo.png"
                                messageBox.visible = !messageBox.visible
                            }
                            onExited: {
                                moreInfoIcon.source = "assets/issueInfo1.png"
                                messageBox.visible = !messageBox.visible
                            }
                        }
                    }
                }

                Rectangle {
                    id: borrowerNameRect
                    height: 50
                    width: 100
                    color: "transparent"
                    anchors {
                        left: bookNumberRect.left
                        top: bookNumberRect.bottom
                        topMargin: 20
                    }

                    Label {
                        id: borrowerNameLabel
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        text: qsTr("Issued to: ")
                        font.pointSize: 12
                    }
                }

                Text{
                    id: borrowerName1
                    anchors{
                        verticalCenter: borrowerNameRect.verticalCenter
                        left: borrowerNameRect.right
                        rightMargin: 5
                    }

                    text: "Gilbert Ashivaka"
                    font.pixelSize: 16
                }

                Rectangle{
                    id: underline
                    height: 2
                    width: borrowerName1.width + 5
                    color: "black"
                    anchors{
                        top: borrowerName1.bottom
                        topMargin: 2
                        horizontalCenter: borrowerName1.horizontalCenter
                    }
                }

                Rectangle {
                    id: returnDateRect
                    width: parent.width / 3
                    height: 50
                    clip: true
                    anchors {
                        top: borrowerNameRect.bottom
                        topMargin: 20
                        left: borrowerNameRect.left
                    }

                    Label {
                        id: returnDateLabel
                        text: "Return Date: "
                        anchors {
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pointSize: 12
                    }

                    Text {
                        id: returnDate
                        anchors {
                            left: returnDateLabel.right
                            leftMargin: 20
                            verticalCenter: parent.verticalCenter
                        }

                        text: "17/06/2024"
                        font.pointSize: 12
                    }
                }

                CustomButton {
                    id: issueBookBtn
                    defaultColor: "#399ED9"
                    hoveredColor: "#399ED9"
                    anchors {
                        top: returnDateRect.bottom
                        right: parent.right
                        topMargin: 20
                        rightMargin: 30
                    }

                    text: "Approve"
                    onClicked: {

                    }
                }

                CustomButton {
                    id: issueBookCancelBtn
                    text: "Cancel"
                    defaultColor: "#E0E0E0"
                    anchors {
                        bottom: issueBookBtn.bottom
                        right: issueBookBtn.left
                        rightMargin: 7
                    }
                }

                Rectangle {
                    id: messageBox
                    width: 100
                    height: messageText.height + 50
    //                color: "gray"
                    color: Qt.rgba(0,0,0, 0.6)
                    radius: 4
                    visible: false  // Initially hidden
                    anchors{
                        left: locationRect.right
                        leftMargin: 5
                        top: locationRect.verticalCenter
                    }

                    Rectangle{
                        id: infoIconRect
                        width: 20
                        height: 20
                        radius: 4
                        anchors{
                            left: parent.left
                            top: parent.top
                            margins: 5
                        }

                        color: "transparent"

                        Image{
                            id: infoIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: "qrc:Libro1/assets/issueInfo.png"
                        }
                    }

                    Text {
                        id: messageText
                        width: parent.width
                        anchors{
                            top: infoIconRect.bottom
                            topMargin: 10
                            left: parent.left
                            leftMargin: 5
                            right: parent.right
                            rightMargin: 10
                        }

                        text: "No more description about location"
                        color: "white"
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }
                }
            }

            CustomDropShadow {
                source: issueBookID
                visible: true
                horizontalOffset: -3
                verticalOffset: -3
                samples: 16
            }
        }
    }
}













