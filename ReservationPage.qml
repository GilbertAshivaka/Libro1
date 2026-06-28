import QtQuick 2.15
import QtQuick.Controls 2.15
import "DynamicComponentLoader.js" as CustomComponentLoader
import com.issueBooksListModel
import com.reservationManager

Rectangle {
    id: reservationPage
    anchors.fill: parent
    property string iconSource: "assets/delegateBook" // the icon for the books list

    //hold the user's database ID for reservations
    property string userID: ""
    property string preservedUserNumber: ""

    //for pagination
    property int itemsPerPage: 100
    property int previousPage: 0
    property int currentPage: 1
    property int nextPage: 2
    property int totalPages: Math.ceil(issueBooksList.getTotalBooksCount()/itemsPerPage)

    signal closeClicked()

    MouseArea {
        id: reservationPageMA
        anchors.fill: parent
    }

    ReservationManager{
        id: reservationManager
    }

    Rectangle {
        id: reservationTitleRect
        width: parent.width
        height: 50
        anchors {
            top: parent.top
            left: parent.left
        }

        Text {
            id: reservationTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "Reserve Book"
            font.pointSize: 12
            color: "#878585"
        }
    }

    Rectangle {
        id: closeBtn
        width: 80
        height: 32
        radius: 25
        border.color: "#878585"
        border.width: 2
        clip: true
        anchors {
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 20
        }

        Text {
            id: closeBtnTxt
            anchors.centerIn: parent
            text: "Close"
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea {
            id: closeBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: {
                closeBtn.color = "#878585"
                closeBtnTxt.color = "white"
            }
            onExited: {
                closeBtn.color = "white"
                closeBtnTxt.color = "#878585"
            }

            onClicked: {
                reservationPage.closeClicked()
            }
        }
    }

    Rectangle {
        id: reservationSearchBox
        width: parent.width / 2
        height: 40
        radius: 4
        color: "transparent"
        border.color: "#E0E0E0"

        property string placeHolderText: "Search books"

        anchors {
            left: parent.left
            leftMargin: 10
            top: reservationTitleRect.bottom
        }

        Image {
            id: searchIcon
            anchors {
                left: parent.left
                leftMargin: 15
                verticalCenter: parent.verticalCenter
            }
            height: parent.height * .45
            fillMode: Image.PreserveAspectFit
            source: "assets/searchIcon.png"
        }

        Text {
            id: searchBoxPlaceHolder
            visible: searchTextInput.text === ""
            color: "#585757"
            text: "Search books"
            anchors {
                left: searchIcon.right
                verticalCenter: parent.verticalCenter
                leftMargin: 20
            }
        }

        MouseArea {
            id: searchBoxMA
            cursorShape: "IBeamCursor"
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                left: searchIcon.right
                leftMargin: 20
            }

            TextInput {
                id: searchTextInput
                clip: true
                anchors {
                    right: parent.right
                    rightMargin: 5
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11

                onTextChanged: {
                    resetPagination()
                    issueBooksList.searchBooks(searchTextInput.text, 1, 100)
                }
            }
        }
    }

    Rectangle {
        id: topOptionsRect
        height: 32
        width: 100
        radius: 4
        border.color: "#DCD8D8"
        anchors {
            right: parent.right
            rightMargin: 20
            verticalCenter: reservationSearchBox.verticalCenter
        }

        Image {
            id: reloadAllBooks
            source: "assets/reload.png"
            width: 20
            height: 20
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                onClicked: {
                    issueBooksList.fetchBooks(1, 100)
                }
            }
        }

        Text {
            id: reloadTxt
            anchors {
                left: reloadAllBooks.right
                leftMargin: 5
                verticalCenter: reloadAllBooks.verticalCenter
            }
            text: "Reload All"

            MouseArea {
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                onClicked: {
                    issueBooksList.fetchBooks(1, 100)
                }
            }
        }
    }

    ListView {
        boundsBehavior: Flickable.StopAtBounds
        id: reservationListView
        clip: true
        anchors {
            top: reservationSearchBox.bottom
            topMargin: 20
            left: parent.left
            leftMargin: 10
            bottom: parent.bottom
            right: parent.right
        }

        model: IssueBooksListModel {
            id: reservationBooksListModel
            list: issueBooksList
        }

        ScrollBar.vertical: ScrollBar {
            id: vbar
            active: true
            policy: ScrollBar.AlwaysOn
            width: 10

            contentItem: Rectangle {
                implicitWidth: 10
                radius: width / 2
                color: vbar.pressed ? "#818181" : "#c2c2c2"
            }
            background: Rectangle {
                implicitWidth: 6
                radius: width / 2
                color: "#f0f0f0"
            }
        }

        delegate: Item {
            width: reservationListView.width
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

                    Image {
                        id: icon
                        source: reservationPage.iconSource
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

                MouseArea {
                    id: delegateItemMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        delegateItemRect.color = "#F5F5F5"
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                    }

                    onClicked: {
                        reservationPopup.bookID = model.bookID
                        reservationPopup.bookTitle = model.title
                        reservationPopup.author = model.author
                        reservationPopup.callNumber = model.callNumber
                        reservationPopup.shelfNumber = model.shelfNumber
                        reservationPopup.internalDBBookID = model.bookID

                        // Get book status and expected return date
                        reservationPopup.bookStatus = reservationManager.getBookStatus(model.bookID)
                        reservationPopup.expectedReturnDate = reservationManager.getExpectedReturnDate(model.bookID)

                        reservationPopup.open()
                    }
                }
            }

            Rectangle {
                id: separator
                width: delegateItemRect.width * .95
                height: 1
                color: "#E0E0E0"
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Popup {
        id: reservationPopup
        width: parent.width * .7
        height: parent.height * .65
        anchors.centerIn: parent
        modal: true
        focus: true
        topInset: 8
        leftInset: 8
        rightInset: 8
        bottomInset: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        property var bookID: null
        property string bookTitle: ""
        property string author: ""
        property string callNumber: ""
        property string shelfNumber: ""
        property var internalDBBookID: null
        property string bookStatus: "Available"
        property string expectedReturnDate: ""

        onOpened: {
            // Reset user input fields when popup opens
            userIdInput.text = ""
            userNameDisplay.text = ""
            reservationCountDisplay.text = ""
        }

        Rectangle {
            id: reservationPopupContent
            color: "#FBFBFB"
            anchors.fill: parent
            radius: 8
            clip: true

            Rectangle {
                id: bookTitleRect
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

                    text: reservationPopup.bookTitle
                    font.pointSize: 14
                    font.bold: true
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
                        id: closeImg
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/close.png"
                    }
                }

                MouseArea {
                    id: closeMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        closeRect.color = "#CB0707"
                    }
                    onExited: {
                        closeRect.color = "#EE4E4E"
                    }

                    onClicked: {
                        reservationPopup.close()
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
                    top: bookTitleRect.bottom
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
                    id: bookIDText
                    anchors {
                        left: bookIDLabel.right
                        leftMargin: 20
                        verticalCenter: parent.verticalCenter
                    }

                    text: reservationPopup.callNumber
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
                    id: locationText
                    anchors {
                        left: locationLabel.right
                        leftMargin: 20
                        verticalCenter: parent.verticalCenter
                    }

                    text: reservationPopup.shelfNumber ? reservationPopup.shelfNumber : "Unknown Location"
                    font.pointSize: 12
                }

                Rectangle {
                    id: moreInfoRect
                    height: 20
                    width: 20
                    color: "transparent"
                    anchors {
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

                    MouseArea {
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

            // Book Status Row
            Rectangle {
                id: bookStatusRect
                width: parent.width / 3
                height: 50
                clip: true
                anchors {
                    left: bookNumberRect.left
                    top: bookNumberRect.bottom
                    topMargin: 10
                }

                Label {
                    id: statusLabel
                    text: "Status: "
                    anchors {
                        left: parent.left
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }
                    font.pointSize: 12
                }

                Text {
                    id: statusText
                    anchors {
                        left: statusLabel.right
                        leftMargin: 20
                        verticalCenter: parent.verticalCenter
                    }

                    text: reservationPopup.bookStatus
                    font.pointSize: 12
                    color: reservationPopup.bookStatus === "Available" ? "#4CAF50" : "#FF9800"
                }
            }

            // Expected Return Date (only visible when book is borrowed)
            Rectangle {
                id: expectedReturnRect
                width: parent.width / 3
                height: 50
                clip: true
                visible: reservationPopup.bookStatus !== "Available" && reservationPopup.expectedReturnDate !== ""
                anchors {
                    left: bookStatusRect.right
                    leftMargin: 30
                    verticalCenter: bookStatusRect.verticalCenter
                }

                Label {
                    id: expectedReturnLabel
                    text: "Expected Return: "
                    anchors {
                        left: parent.left
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }
                    font.pointSize: 12
                }

                Text {
                    id: expectedReturnText
                    anchors {
                        left: expectedReturnLabel.right
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    text: reservationPopup.expectedReturnDate
                    font.pointSize: 12
                    color: "#FF9800"
                }
            }

            // User ID Input Row
            Rectangle {
                id: userIdRect
                height: 50
                width: 100
                color: "transparent"
                anchors {
                    left: bookNumberRect.left
                    top: bookStatusRect.bottom
                    topMargin: 20
                }

                Label {
                    id: userIdLabel
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Reserved by: ")
                    font.pointSize: 12
                }
            }

            CustomTextField {
                id: userIdInput
                height: 40
                width: parent.width / 3
                anchors {
                    bottom: userIdRect.bottom
                    left: userIdRect.right
                    rightMargin: 5
                }
                placeholderText: "USER ID."
                onTextChanged: {
                    if (text.length > 0) {
                        userNameCheckTimer.restart()
                    } else {
                        userNameDisplay.text = ""
                        reservationCountDisplay.text = ""
                    }
                }
            }

            // Timer for user lookup
            Timer {
                id: userNameCheckTimer
                interval: 1500
                repeat: false
                onTriggered: {
                    var userInput = userIdInput.text.trim()
                    reservationPage.preservedUserNumber = userInput

                    if (userInput.length > 0) {
                        var foundName = reservationManager.lookUpUserNumber(userInput)

                        if (foundName && foundName.length > 0) {
                            userNameDisplay.text = foundName
                            userNameDisplay.color = "#4CAF50"

                            // Show reservation count
                            var count = reservationManager.getUserReservationCount(userInput)
                            var maxReservations = reservationManager.getMaxReservations()
                            var remaining = maxReservations - count
                            reservationCountDisplay.text = "(" + remaining + "/" + maxReservations + " reservations remaining)"
                            reservationCountDisplay.color = remaining > 0 ? "#4CAF50" : "#F44336"
                        } else {
                            userNameDisplay.text = "User not found"
                            userNameDisplay.color = "#F44336"
                            reservationCountDisplay.text = ""
                        }
                    }

                    reservationPage.userID = reservationManager.getInternalUserID(userInput)
                }
            }

            // User Name Display
            Rectangle {
                id: userNameDisplayRect
                width: parent.width / 3
                height: 50
                color: "white"
                clip: true
                visible: userNameDisplay.text.length > 0
                anchors {
                    left: userIdInput.right
                    leftMargin: 20
                    top: userIdInput.top
                }

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    Text {
                        id: userNameDisplay
                        color: "#4CAF50"
                        font.pointSize: 12
                    }

                    Text {
                        id: reservationCountDisplay
                        font.pointSize: 10
                        color: "#4CAF50"
                    }
                }
            }

            // Reservation Expiry Date Row
            Rectangle {
                id: expiryDateRect
                width: parent.width / 3
                height: 50
                clip: true
                anchors {
                    top: userIdRect.bottom
                    topMargin: 20
                    left: userIdRect.left
                }

                Label {
                    id: expiryDateLabel
                    text: "Reservation Expires: "
                    anchors {
                        left: parent.left
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }
                    font.pointSize: 12
                }

                Text {
                    id: expiryDateText
                    anchors {
                        left: expiryDateLabel.right
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    text: reservationManager.getReservationExpiryDate()
                    font.pointSize: 12
                    color: "#2196F3"
                }
            }

            CustomButton {
                id: reserveBookBtn
                defaultColor: "#399ED9"
                hoveredColor: "#2196F3"
                anchors {
                    top: expiryDateRect.bottom
                    right: parent.right
                    topMargin: 20
                    rightMargin: 30
                }

                text: "Reserve"
                onClicked: {
                    var userInput = userIdInput.text.trim()
                    if (userInput.length === 0) {
                        resultDialog.title = "Error!"
                        resultDialog.text = "Please enter a User ID."
                        resultDialog.open()
                        return
                    }

                    reservationManager.reserveBook(reservationPopup.internalDBBookID, userInput)
                }
            }

            CustomButton {
                id: cancelBtn
                text: "Cancel"
                defaultColor: "#E0E0E0"
                anchors {
                    bottom: reserveBookBtn.bottom
                    right: reserveBookBtn.left
                    rightMargin: 7
                }
                onClicked: {
                    reservationPopup.close()
                }
            }

            Rectangle {
                id: messageBox
                width: 100
                height: messageText.height + 50
                color: Qt.rgba(0, 0, 0, 0.6)
                radius: 4
                visible: false
                anchors {
                    left: locationRect.right
                    leftMargin: 5
                    top: locationRect.verticalCenter
                }

                Rectangle {
                    id: infoIconRect
                    width: 20
                    height: 20
                    radius: 4
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: 5
                    }

                    color: "transparent"

                    Image {
                        id: infoIcon
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/issueInfo.png"
                    }
                }

                Text {
                    id: messageText
                    width: parent.width
                    anchors {
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
            source: reservationPopupContent
            visible: true
            horizontalOffset: -3
            verticalOffset: -3
            samples: 16
        }
    }

    // Navigation Rectangle
    Rectangle {
        id: navigationRect
        width: 200
        height: 50
        radius: 8
        border.color: "lightgray"
        color: "white"
        opacity: 0.9

        x: Math.min(Math.max(0, parent.width - 230), parent.width - width)
        y: Math.min(Math.max(0, parent.height - 80), parent.height - height)

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
            enabled: previousPage > 0
            anchors {
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }

            MouseArea {
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
            anchors {
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
            anchors {
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }

            MouseArea {
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
            anchors {
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
                    text = currentPage
                }
            }
        }
    }

    Dialog {
        id: resultDialog
        title: "Error"
        property alias text: resultLabel.text
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Text {
            id: resultLabel
            color: "#8E8E8E"
        }
    }

    Connections {
        target: reservationManager
        function onReservationError(errorMsg) {
            resultDialog.title = "Error!"
            resultDialog.text = errorMsg
            resultDialog.open()
        }

        function onReservationSuccessful(successMsg) {
            resultDialog.title = "Success!"
            resultDialog.text = successMsg
            resultDialog.open()
            reservationPopup.close()
        }
    }


    function resetPagination() {
        currentPage = 1
        previousPage = 0
        nextPage = 2
    }

    function fetchCurrentPageData() {
        const offset = currentPage
        issueBooksList.fetchBooks(currentPage, 100)
    }

    Component.onCompleted: {
        issueBooksList.fetchBooks(1, 100)
    }
}
