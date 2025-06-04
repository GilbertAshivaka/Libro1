import QtQuick
import QtQuick.Controls
import "DynamicComponentLoader.js" as CustomComponentLoader
import com.issuedBooksListModel 1.0

Rectangle {
    id: approved
    visible: true
    width: parent.width
    height: parent.height
    color: "#FBFBFB"

    signal closeClicked()

    MouseArea{
        id: issuedBooksMA
        anchors.fill: parent
    }

    TextUtils{
        id: textUtils
    }

    Rectangle {
        id: approvedTitleRect
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

            text: "Issued Books"
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
                verticalCenter: approvedTitleRect.verticalCenter
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
                    approved.closeClicked()
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
                verticalCenter: approvedTitleRect.verticalCenter
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
                enabled: emptyApprovedList.visible ? false : true

                onEntered: {
                    sortRect.color = "#E8E3E4"
                }
                onExited: {
                    sortRect.color = "white"
                }

                onClicked: {
                    sortMenu.open()
                }
            }

            Menu {
                id: sortMenu
                title: "Sort by: "
                width: 160
                y: sortRect.height
                x: -sortMenu.width +sortRect.width //place top right corner at the bottom right corner of sortRect
                enabled: emptyApprovedList.visible ? false : true

                MenuItem {
                    text: "Issue date: ASC"
                    onClicked: {
                        issuedBooksList.loadSortedIssuedBooks("ASC")
                    }
                }

                MenuItem {
                    text: "Issue date: DESC"
                    onClicked: {
                        issuedBooksList.loadSortedIssuedBooks("DESC")
                    }
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
                verticalCenter: approvedTitleRect.verticalCenter
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
                enabled: emptyApprovedList.visible ? false : true

                onEntered: {
                    searchRect.color = "#E8E3E4"
                }
                onExited: {
                    searchRect.color = "white"
                }

                onClicked: {
                    approvedSearchBox.visible = !approvedSearchBox.visible
                }
            }
        }

        Rectangle{
            id: menuRect
            width: 60
            height: 40
            radius: 4
            anchors{
                right: searchRect.left
                rightMargin: 10
                verticalCenter: approvedTitleRect.verticalCenter
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
                enabled: emptyApprovedList.visible ? false : true

                MenuItem {
                    text: "Return"
                    onClicked: {
                        issuedBooksList.returnSelectedBooks()
                    }
                }

                MenuItem {
                    text: "Select all"
                    onClicked: {
                        issuedBooksList.selectAllBooks()
                    }
                }
                MenuItem {
                    text: "Deselect all"
                    onClicked: {
                        issuedBooksList.deselectAllBooks()
                    }
                }
                MenuItem {
                    text: emptyApprovedList.visible ? "Hide empty page" : "Show empty page"
                    onClicked: {
                        emptyApprovedList.visible = !emptyApprovedList.visible
                    }
                }
            }
        }

        Rectangle{
            id: approvedSearchBox
            width: approved.width < 680 ? 400* (parent.width/1080) : 400
            height: 40
            radius: 4
            color: "transparent"
            border.color: "#E0E0E0"
            visible: approved.width > 325
            anchors{
                right: menuRect.left
                rightMargin: 10
                verticalCenter: menuRect.verticalCenter
            }

            Image {
                id: searchBoxIcon
                anchors{
                    left: parent.left
                    leftMargin: 15
                    verticalCenter: parent.verticalCenter
                }

                height: parent.height *.45
                fillMode: Image.PreserveAspectFit
                source: "assets/searchIcon.png"

                MouseArea{
                    id: searchBoxMA
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
                text: "Search issued books"
                anchors{
                    left: searchBoxIcon.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20
                }
            }

            MouseArea{
                id: approvedSearchBoxMA
                cursorShape: "IBeamCursor"
                anchors{
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    left: searchBoxIcon.right
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

                    onTextChanged: {
                        issuedBooksList.searchBooksInDatabase(navigationTextInput.text)
                    }
                }
            }
        }
    }

    Row {
        id: headerRow
        width: parent.width
        height: 50
        anchors{
            top: approvedTitleRect.bottom
        }

        Rectangle {
            width: parent.width / 5
            height: parent.height
            color: "lightgray"
            clip: true

            Text {
                anchors.centerIn: parent
                text: "Name"
                font.bold: true
                font.pixelSize: 16
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: "#E0E0E0"
        }

        Rectangle {
            width: parent.width / 5
            height: parent.height
            color: "lightgray"
            clip: true

            Text {
                anchors.centerIn: parent
                text: "Book Number"
                font.bold: true
                font.pixelSize: 16
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: "#E0E0E0"
        }

        Rectangle {
            width: parent.width / 5
            height: parent.height
            color: "lightgray"
            clip: true

            Text {
                anchors.centerIn: parent
                text: "Issue Date"
                font.bold: true
                font.pixelSize: 16
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: "#E0E0E0"
            clip: true
        }

        Rectangle {
            width: parent.width / 5
            height: parent.height
            color: "lightgray"
            clip: true

            Text {
                anchors.centerIn: parent
                text: "Status"
                font.bold: true
                font.pixelSize: 16
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: "#E0E0E0"
            clip: true
        }

        Rectangle {
            width: parent.width / 5
            height: parent.height
            color: "lightgray"
            clip: true

            Text {
                anchors.centerIn: parent
                text: "Return"
                font.bold: true
                font.pixelSize: 16
            }
        }
    }

    ListView {
        id: listView
        width: parent.width
        height: parent.height
        anchors.top: headerRow.bottom
        anchors.bottom: parent.bottom
        clip: true

        model: IssuedBooksListModel{
            id: issuedBooksListModel
            list: issuedBooksList
        }

        delegate: Rectangle {
            id: delegateItemRect
            width: listView.width
            height: 50

            property bool hovered: false

            MouseArea{
                id: delegateItemMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    delegateItemRect.hovered = true
                    delegateItemRect.color = "#F5F5F5"
                }
                onExited: {
                    delegateItemRect.hovered = false
                    delegateItemRect.color = "transparent"
                }
            }

            Row {
                width: parent.width
                height: parent.height

                // Name column
                Rectangle {
                    width: parent.width / 5
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: textUtils.truncateText(model.name, textUtils.calculateMaxLength(parent.width, 16))
                        font.pixelSize: 16
                        color: "black"
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#E0E0E0"
                }

                // Book Number column
                Rectangle {
                    width: parent.width / 5
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: textUtils.truncateText(model.bookNumber, textUtils.calculateMaxLength(parent.width, 16))
                        font.pixelSize: 16
                        color: "black"
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#E0E0E0"
                }

                // Issue Date column
                Rectangle {
                    width: parent.width / 5
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: textUtils.truncateText(model.issueDate, textUtils.calculateMaxLength(parent.width, 16))
                        font.pixelSize: 16
                        color: "black"
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#E0E0E0"
                }

                // Status column
                Rectangle {
                    width: parent.width / 5
                    height: parent.height
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: textUtils.truncateText(model.status, textUtils.calculateMaxLength(parent.width, 16))
                        font.pixelSize: 16
                        color: model.status === "Pending" ? "green" : "red"
                    }
                }

                // Separator
//                Rectangle {
//                    width: 1
//                    height: parent.height
//                    color: "#E0E0E0"
//                }

                // Return column
                Rectangle {
                    width: parent.width / 5
                    height: parent.height
                    color: "transparent"

                    MouseArea {
                        id: returnMA
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: {
                            delegateItemRect.color = "#F5F5F5"
                            delegateItemRect.hovered = true
                        }

                        onExited: {
                            delegateItemRect.color = "transparent"
                            delegateItemRect.hovered = false
                        }

                        onClicked: {
                            model.isSelected = !model.isSelected
                        }

                        Image {
                            id: returnIcon
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                            source: model.isSelected ? "assets/check.png" : (delegateItemRect.hovered ? "assets/square.png" : "")
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width * 0.95
                height: 1
                color: "#E0E0E0"
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    EmptyApprovedList{
        id: emptyApprovedList
        width: parent.width
        visible: false // issuedBooksListModel.rowCount() === 0 ? true : false

        anchors{
            top: approvedTitleRect.bottom
            bottom: parent.bottom
        }
    }

    Dialog {
        id: errorDialog
        title: "Error"
        property alias text: errorLabel.text
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Text {
            id: errorLabel
            color: "#8E8E8E"
        }
    }

    Connections{
        target: issuedBooksList

        function onErrorOccured(errorMsg){
            errorDialog.title = "Error!"
            errorDialog.text = errorMsg
            errorDialog.open()
        }

        function onOperationSuccessful(successMsg){
            errorDialog.title = "Success!"
            errorDialog.text = successMsg
            errorDialog.open()
        }
    }


    function removeSelectedBooks() {
        // Iterate from the end to avoid index issues when removing items
        for (var i = listView.model.count - 1; i >= 0; i--) {
            if (listView.model.get(i).isSelected) {
                listView.model.remove(i);
            }
        }
        // Update menu item enabled state
//        menu.items[2].enabled = listView.model.count > 0 && listView.model.some(book => !book.isSelected);
//        menu.items[3].enabled = listView.model.some(book => book.isSelected);
    }

    Component.onCompleted:{
        issuedBooksList.loadIssuedBooks()
    }

}
