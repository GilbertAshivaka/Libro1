import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
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

        // Filter buttons
        RowLayout {
            anchors{
                right: mainCloseRect.left
                rightMargin: 20
                verticalCenter: parent.verticalCenter
            }

            ButtonGroup {
                id: filterButtonGroup
            }

            Button {
                text: "All"
                checkable: true
                checked: true
                ButtonGroup.group: filterButtonGroup
                onClicked: {
                    reservationsModel.filterStatus = "all"
                    reservationsModel.refresh()
                }
            }

            Button {
                text: "Pending"
                checkable: true
                ButtonGroup.group: filterButtonGroup
                onClicked: {
                    reservationsModel.filterStatus = "pending"
                    reservationsModel.refresh()
                }
            }

            Button {
                text: "Notified"
                checkable: true
                ButtonGroup.group: filterButtonGroup
                onClicked: {
                    reservationsModel.filterStatus = "notified"
                    reservationsModel.refresh()
                }
            }

            Button {
                text: "Expired"
                checkable: true
                ButtonGroup.group: filterButtonGroup
                onClicked:{
                    reservationsModel.filterStatus = "expired"
                    reservationsModel.refresh()
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

        // Reservations list
        ListView {
            id: reservationsListView
            // Layout.fillWidth: true
            // Layout.preferredHeight: 400
            clip: true

            anchors{
                top: parent.top
                topMargin: 10
                right: parent.right
                left: parent.left
                bottom: parent.bottom
            }

            ScrollBar.vertical: ScrollBar {
                id: vbar
                active: true
                policy: ScrollBar.AsNeeded
                width: 6
                parent: reservationsListView
                anchors.right: reservationsListView.right
                anchors.top: reservationsListView.top
                anchors.bottom: reservationsListView.bottom

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: vbar.pressed ? "#818181" : "#c2c2c2"
                }

                background: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: "#f0f0f0"
                }
            }

            model: ListModel {
                id: reservationsModel

                property string filterStatus: "all"

                function refresh() {
                    clear()
                    var reservations = opacManager.getReservationsList(filterStatus)
                    for (var i = 0; i < reservations.length; i++) {
                        append(reservations[i])
                    }
                }

                Component.onCompleted: refresh()
            }

            delegate: ItemDelegate {
                width: reservationsListView.width

                contentItem: ColumnLayout {
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: model.bookTitle
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: statusLabel1.width + 10
                            height: statusLabel1.height + 4
                            radius: 3
                            color: {
                                if (model.status === "pending") return "#FFF3CD"
                                if (model.status === "notified") return "#D1ECF1"
                                if (model.status === "expired") return "#F8D7DA"
                                return "#D4EDDA"
                            }

                            Label {
                                id: statusLabel1
                                anchors.centerIn: parent
                                text: model.status.toUpperCase()
                                font.pixelSize: 10
                                font.bold: true
                                color: {
                                    if (model.status === "pending") return "#856404"
                                    if (model.status === "notified") return "#0C5460"
                                    if (model.status === "expired") return "#721C24"
                                    return "#155724"
                                }
                            }
                        }
                    }

                    Label {
                        text: "Author: " + model.bookAuthor
                        color: "gray"
                    }

                    Label {
                        text: "User: " + model.userName + " (" + model.userEmail + ")"
                        color: "gray"
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Reserved: " + Qt.formatDateTime(new Date(model.reservationDate), "yyyy-MM-dd hh:mm")
                            color: "gray"
                            font.pixelSize: 11
                        }

                        Label {
                            text: model.status === "notified"
                                  ? "Pickup by: " + Qt.formatDateTime(new Date(model.pickupDeadline), "yyyy-MM-dd")
                                  : "Expires: " + Qt.formatDateTime(new Date(model.expiryDate), "yyyy-MM-dd")
                            color: model.status === "notified" ? "#0C5460" : "gray"
                            font.pixelSize: 11
                            font.bold: model.status === "notified"
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Action buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Button {
                            text: "View Details"
                            flat: true
                            font.pixelSize: 11
                            onClicked: showReservationDetails(model)
                        }

                        Button {
                            text: "Cancel"
                            flat: true
                            font.pixelSize: 11
                            visible: model.status === "pending" || model.status === "notified"
                            onClicked: confirmCancelDialog.show(model.reservationId)
                        }

                        Button {
                            text: "Issue Book"
                            flat: true
                            font.pixelSize: 11
                            highlighted: true
                            visible: model.status === "pending" || model.status === "notified"
                            onClicked: {
                                issueBookPopup.bookTitle = model.bookTitle
                                issueBookPopup.bookNumber = model.callNumber
                                issueBookPopup.bookId = model.bookId
                                issueBookPopup.userNumber = model.userNo
                                issueBookPopup.userName = model.userName
                                issueBookPopup.availability = model.bookAvailability
                                issueBookPopup.reservationId = model.reservationId //for fulfilling reservation in opac manager
                                issueBookPopup.open()
                            }
                        }
                    }
                }
            }

            // ScrollBar.vertical: ScrollBar {}

            Label {
                anchors.centerIn: parent
                text: "No reservations found"
                visible: reservationsListView.count === 0
                color: "gray"
            }
        }

        // Reservation Details Dialog
        Dialog {
          id: reservationDetailsDialog
          title: "Reservation Details"
          anchors.centerIn: parent
          modal: true
          standardButtons: Dialog.Close
          width: 500

          property var currentReservation: null

          function showDetails(reservation) {
            currentReservation = reservation
            open()
          }

          ColumnLayout {
            width: parent.width
            spacing: 10

            GridLayout {
              Layout.fillWidth: true
              columns: 2
              columnSpacing: 10
              rowSpacing: 5

              Label { text: "Book Title:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.bookTitle : "" }

              Label { text: "Author:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.bookAuthor : "" }

              Label { text: "Call Number:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.callNumber : "" }

              Label { text: "User:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.userName : "" }

              Label { text: "Email:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.userEmail : "" }

              Label { text: "Status:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.status : "" }

              Label { text: "Reserved:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? Qt.formatDateTime(new Date(reservationDetailsDialog.currentReservation.reservationDate), "yyyy-MM-dd hh:mm") : "" }

              Label { text: "Expires:"; font.bold: true }
              Label { text: reservationDetailsDialog.currentReservation ? Qt.formatDateTime(new Date(reservationDetailsDialog.currentReservation.expiryDate), "yyyy-MM-dd") : "" }

              Label {
                text: "Pickup Deadline:";
                font.bold: true
                visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.status === "notified"
              }
              Label {
                text: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.pickupDeadline ?
                        Qt.formatDateTime(new Date(reservationDetailsDialog.currentReservation.pickupDeadline), "yyyy-MM-dd") : ""
                visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.status === "notified"
              }
            }

            Label {
              text: "Notes:"
              font.bold: true
              visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.notes
            }

            Label {
              Layout.fillWidth: true
              text: reservationDetailsDialog.currentReservation ? reservationDetailsDialog.currentReservation.notes : ""
              wrapMode: Text.WordWrap
              visible: reservationDetailsDialog.currentReservation && reservationDetailsDialog.currentReservation.notes
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
            property int bookId: null
            property string userNumber: ""
            property string userName: ""
            property string bookNumber: ""
            property string availability: ""

            //for fulfilling reservation in Opac manager
            property int  reservationId: null
            property int issuedBookId: null

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

                        text: issueBookPopup.bookNumber //"13/NRW/2024"
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
                        text: "Availability: "
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

                        text: issueBookPopup.availability //"Shelf NO. 12"
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

                    text: issueBookPopup.userName  //"Gilbert Ashivaka"
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

                        text: issueBooksList.returnDueDate() //"17/06/2024"
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
                        console.log("Book number:", issueBookPopup.bookNumber)
                        issueBooksList.issueBook(issueBookPopup.bookId, issueBookPopup.userNumber)
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

    // Confirm Cancel Reservation Dialog
    Dialog {
      id: confirmCancelDialog
      title: "Cancel Reservation"
      anchors.centerIn: parent
      modal: true
      standardButtons: Dialog.Yes | Dialog.No

      property int reservationId: -1

      function show(resId) {
        reservationId = resId
        open()
      }

      Label {
        text: "Are you sure you want to cancel this reservation?"
      }

      onAccepted: {
        if (opacManager.cancelReservation(reservationId)) {
          showSuccessMessage("Reservation cancelled successfully")
          reservationsModel.refresh()
        } else {
          showErrorMessage("Failed to cancel reservation")
        }
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
        target: issueBooksList
        function onErrorOcurred(errorMsg){
            // issueBookPopup.close()
            errorDialog.title = "Error!"
            errorDialog.text = errorMsg
            errorDialog.open()
        }

        function onOperationSuccessful(successMsg){
            // issueBookPopup.close()
            errorDialog.title = "Success!"
            errorDialog.text = successMsg
            errorDialog.open()
            opacManager.fulfillReservation(issueBookPopup.reservationId, issueBookPopup.issuedBookId)
        }

        function onBookIssued(bookId){
            issueBookPopup.issuedBookId = bookId
        }
    }

    Connections{
        target: opacManager
        function onReservationsUpdated(){
            reservationsModel.refresh()
        }
    }


    function showReservationDetails(reservation) {
      reservationDetailsDialog.showDetails(reservation)
    }
}













