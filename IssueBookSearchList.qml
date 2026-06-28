import QtQuick 2.15
import QtQuick.Controls 2.15
import "DynamicComponentLoader.js" as CustomComponentLoader
import com.issueBooksListModel 1.0
import QtMultimedia
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Window
import QtQuick.Dialogs
import ZXing

Rectangle {
    id: issueBook
    anchors.fill: parent
    property string iconSource: "assets/delegateBook" // the icon for the books list

    //hold the user's database ID for issuing books
    property string userID: ""
    property string preservedUserNumber: ""

    //for pagination
    property int itemsPerPage: 100
    property int  previousPage: 0
    property int  currentPage: 1
    property int  nextPage: 2
    property int  totalPages: Math.ceil(issueBooksList.getTotalBooksCount()/itemsPerPage)


    signal closeClicked()

    MouseArea{
        id: issueBookMA
        anchors.fill: parent
    }

    Rectangle {
        id: issueBookTitleRect
        width: parent.width
        height: 50
        anchors {
            top: parent.top
            left: parent.left
        }

        Text {
            id: returnBookTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }

            text: "Issue book"
            font.pointSize: 12
            color: "#878585"
        }
    }

    Rectangle{
        id: closeBtn
        width: 80
        height: 32
        radius: 25
        border.color: "#878585"
        border.width: 2
        clip: true
        anchors{
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 20
            // verticalCenter: issueBooksSearchBox.verticalCenter
        }

        Text{
            id: closeBtnTxt
            anchors.centerIn: parent
            text: "Close"
            font.pixelSize: 16
            font.bold: true
        }

        MouseArea{
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
                closeBtnTxt.color ="#878585"
            }

            onClicked:{
                issueBook.closeClicked()
            }
        }
    }

    Rectangle {
        id: issueBooksSearchBox
        width: parent.width / 2
        height: 40
        radius: 4
        color: "transparent"
        border.color: "#E0E0E0"

        property string placeHolderText: "Search books"

        anchors {
            left: parent.left
            leftMargin: 10
            top: issueBookTitleRect.bottom
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
            visible: navigationTextInput.text === ""
            color: "#585757"
            text: "Search books"
            anchors {
                left: searchIcon.right
                verticalCenter: parent.verticalCenter
                leftMargin: 20
            }
        }

        MouseArea {
            id: toolBarSearchBoxMA
            cursorShape: "IBeamCursor"
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                left: searchIcon.right
                leftMargin: 20
            }

            TextInput {
                id: navigationTextInput
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
                    issueBooksList.searchBooks(navigationTextInput.text, 1, 100)
                }
            }
        }
    }

    Rectangle{
        id: topOptionsRect
        height: 32
        width: 230
        radius: 4
        border.color: "#DCD8D8"
        anchors{
            right: parent.right
            rightMargin: 20
            verticalCenter: issueBooksSearchBox.verticalCenter
        }
        Image {
            id: reloadAllBooks
            source: "assets/reload.png"
            width: 20
            height: 20
            anchors{
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }

            MouseArea{
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                onClicked: {
                    issueBooksList.fetchBooks(1,100)
                }
            }
        }

        Text {
            id: barcodeScanTxt
            anchors{
                left: reloadAllBooks.right
                leftMargin: 5
                verticalCenter: reloadAllBooks.verticalCenter
            }
            text: "Reload All"

            MouseArea{
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                onClicked: {
                    issueBooksList.fetchBooks(1,100)
                }
            }
        }

        Image {
            id: barcodeReaderIcon
            source: "assets/barcodeScan.png"
            height: 20
            width: 20
            anchors{
                left: barcodeScanTxt.right
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            MouseArea{
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                onClicked: {
                    barcodeReaderPopup.open()
                }
            }
        }

        Text {
            id: barcodeReaderTxt
            text: qsTr("Scan Barcode")
            anchors{
                left: barcodeReaderIcon.right
                leftMargin: 5
                verticalCenter: barcodeReaderIcon.verticalCenter
            }
            MouseArea{
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                onClicked: {
                    barcodeReaderPopup.open()
                }
            }
        }
    }

    ListView {
        boundsBehavior: Flickable.StopAtBounds
        id: issueBooksListView
        clip: true
        anchors {
            top: issueBooksSearchBox.bottom
            topMargin: 20
            left: parent.left
            leftMargin: 10
            bottom: parent.bottom
            right: parent.right
        }

        model: IssueBooksListModel{
            id: issueBooksListModel
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
                color: vbar.pressed ? "#818181" : "#c2c2c2"  // Darker when pressed
            }
            background: Rectangle {
                implicitWidth: 6
                radius: width / 2
                color: "#f0f0f0"  // Light background color
            }
        }

        delegate: Item {
            width: issueBooksListView.width
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
                        source: issueBook.iconSource
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
                        issueBookPopup.bookID = model.bookID
                        issueBookPopup.bookTitle = model.title
                        issueBookPopup.author = model.author
                        issueBookPopup.callNumber = model.callNumber
                        issueBookPopup.barcode = model.barcode
                        issueBookPopup.shelfNumber = model.shelfNumber
                        issueBookPopup.internalDBBookID = model.bookID
                        issueBookPopup.open()
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

        property var bookID: null
        property string bookTitle: ""
        property string author: ""
        property string callNumber: ""
        property string barcode: ""
        property string shelfNumber: ""
        property var internalDBBookID: null // internal bookID in the database for the issuing function

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
                        source: "assets/close.png"
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

                    text: issueBookPopup.callNumber
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

                    text: issueBookPopup.shelfNumber ? issueBookPopup.shelfNumber : "Unknown Location" //"Shelf NO. 12"
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

            CustomTextField {
                id: borrowerName
                height: 40
                width: parent.width / 3
                anchors {
                    bottom: borrowerNameRect.bottom
                    left: borrowerNameRect.right
                    rightMargin: 5
                }
                placeholderText: "USER ID."
                onTextChanged: {
                    if (text.length > 0) {
                        userNameCheckTimer.restart()
                    } else {
                        userNameDisplay.text = ""
                    }
                }
            }

            // we don't want to be calling the function everytime the user types for efficiency so we use a timer
            Timer{
                id: userNameCheckTimer
                interval: 2000
                repeat: false
                onTriggered:{
                    var userInput = borrowerName.text.trim()
                    //preserve the user number
                    issueBook.preservedUserNumber = userInput //obsolete
                    if(userInput.length > 0){
                        var foundName = issueBooksList.lookUpUserNumber(userInput) //returns the name of the user when the number is entered


                        if (foundName && foundName.length > 0){
                            userNameDisplay.text = foundName
                            userNameDisplay.color = "green"
                        }else{
                            userNameDisplay.text = "User not found"
                            userNameDisplay.color = "red"
                        }
                    }

                    //get the database userID for use by the ussuing function
                    issueBook.userID = issueBooksList.getInternalUserID(userInput)
                    console.log(issueBook.userID)
                }
            }

            //a separate display for the user's name
            Rectangle {
                id: userNameDisplayRect
                width: parent.width / 3
                height: 50
                color: "white"
                clip: true
                visible: userNameDisplay.text.length > 0
                anchors {
                    left: borrowerName.right
                    leftMargin: 20
                    top: borrowerName.top
                }

                Text {
                    id: userNameDisplay
                    anchors {
                        left: parent.left
                        leftMargin: 20
                        verticalCenter: parent.verticalCenter
                    }
                    color: "green"
                    font.pointSize: 12
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

                    text: issueBooksList.returnDueDate() // "17/06/2024"
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

                text: "Continue"
                onClicked: {
                    var dueDate = issueBooksList.getDueDate() // get the date after the userType is known
                    returnDate.text = dueDate
                    issueBooksList.issueBook(issueBookPopup.internalDBBookID, borrowerName.text.trim())
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
                onClicked: {
                    issueBookPopup.close()
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
                        source: "assets/issueInfo.png"
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

    Popup {
        id: barcodeReaderPopup
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

        //cleanup: reset the points when the popup is closed
        onClosed: {
            barcodeReaderRect.points = barcodeReaderRect.nullPoints
            info.text = ""
        }

        Rectangle {
            id: barcodeReaderRect
            visible: true
            width: parent.width
            height: parent.height

            property var nullPoints: [Qt.point(0,0), Qt.point(0,0), Qt.point(0,0), Qt.point(0,0)]
            property var points: nullPoints

            Timer {
                id: resetInfo
                interval: 1000
            }

            Rectangle {
                id: barcodePopupCloseRect
                width: 30
                height: 30
                radius: 4
                color: "#EE4E4E"
                anchors {
                    right: parent.right
                    rightMargin: 0
                    top: parent.top
                    topMargin: 0
                }

                Rectangle {
                    id: barcodePopupCloseImageRect
                    width: 15
                    height: 15
                    radius: 4
                    anchors.centerIn: parent
                    color: "transparent"

                    Image {
                        id: barcodePopupClose
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "assets/close.png"
                    }
                }

                MouseArea {
                    id: barcodePopupMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        barcodePopupCloseRect.color = "#CB0707"  //"#E8E3E4"
                    }
                    onExited: {
                        barcodePopupCloseRect.color = "#EE4E4E"  //"transparent"
                    }

                    onClicked: {
                        barcodeReaderPopup.close()
                    }
                }
            }


            BarcodeReader {
                id: barcodeReader
                videoSink: videoOutput.videoSink


                // formats: (linearSwitch.checked ? (ZXing.LinearCodes) : ZXing.None) | (matrixSwitch.checked ? (ZXing.MatrixCodes) : ZXing.None)
                formats: (ZXing.LinearCodes) | ZXing.None
                tryRotate: true //tryRotateSwitch.checked
                tryHarder: false // tryHarderSwitch.checked
                tryInvert: true// tryInvertSwitch.checked
                tryDownscale: true // tryDownscaleSwitch.checked
                textMode: ZXing.TextMode.HRI

                // callback with parameter 'barcode', called for every successfully processed frame
                onFoundBarcode: (barcode)=> {
                    barcodeReaderRect.points = [barcode.position.topLeft, barcode.position.topRight, barcode.position.bottomRight, barcode.position.bottomLeft]
                    info.text = qsTr("Format: \t %1 \nText: \t %2 \nType: \t %3 \nTime: \t %4 ms").arg(barcode.formatName).arg(barcode.text).arg(barcode.contentTypeName).arg(runTime)
                                    barcodeReaderPopup.close()
                                    resetPagination()//reset the page info
                                    issueBooksList.searchByBarcode(barcode.text)

                                    //automatically open the popup with prefilled details
                                    if (issueBooksListModel.rowCount() > 0){
                                    var book = issueBooksListModel.get(0)
                                    issueBookPopup.bookID = book.bookID
                                    console.log(issueBookPopup.bookID)
                                    issueBookPopup.bookTitle = book.title
                                    issueBookPopup.author = book.author
                                    issueBookPopup.callNumber = book.callNumber
                                    issueBookPopup.barcode = book.barcode
                                    issueBookPopup.shelfNumber = book.shelfNumber
                                    issueBookPopup.open()
                                    }else {
                                        console.log("No book found with barcode: " + barcode.text)
                                    }


                    resetInfo.restart()
                }

                // called for every processed frame where no barcode was detected
                onFailedRead: ()=> {
                    barcodeReaderRect.points = barcodeReaderRect.nullPoints

                    if (!resetInfo.running)
                        info.text = "No barcode found (in %1 ms)".arg(runTime)
                }
            }

            MediaDevices {
                id: devices
            }

            Camera {
                id: camera
                cameraDevice: devices.videoInputs[camerasComboBox.currentIndex] ? devices.videoInputs[camerasComboBox.currentIndex] : devices.defaultVideoInput
                focusMode: Camera.FocusModeAutoNear
                onErrorOccurred: console.log("camera error:" + errorString)
                active: barcodeReaderPopup.opened
            }

            CaptureSession {
                id: captureSession
                camera: camera
                videoOutput: videoOutput
            }

            ColumnLayout {
                anchors.fill: parent

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    visible: devices.videoInputs.length > 1
                    Label {
                        text: qsTr("Camera: ")
                        Layout.fillWidth: false
                    }
                    ComboBox {
                        id: camerasComboBox
                        Layout.fillWidth: true
                        model: devices.videoInputs
                        textRole: "description"
                        currentIndex: 0
                    }
                }

                VideoOutput {
                    id: videoOutput
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    function mapPointToItem(point)
                    {
                        if (videoOutput.sourceRect.width === 0 || videoOutput.sourceRect.height === 0)
                            return Qt.point(0, 0);

                        let dx = point.x;
                        let dy = point.y;

                        if ((videoOutput.orientation % 180) == 0)
                        {
                            dx = dx * videoOutput.contentRect.width / videoOutput.sourceRect.width;
                            dy = dy * videoOutput.contentRect.height / videoOutput.sourceRect.height;
                        }
                        else
                        {
                            dx = dx * videoOutput.contentRect.height / videoOutput.sourceRect.height;
                            dy = dx * videoOutput.contentRect.width / videoOutput.sourceRect.width;
                        }

                        switch ((videoOutput.orientation + 360) % 360)
                        {
                            case 0:
                            default:
                                return Qt.point(videoOutput.contentRect.x + dx, videoOutput.contentRect.y + dy);
                            case 90:
                                return Qt.point(videoOutput.contentRect.x + dy, videoOutput.contentRect.y + videoOutput.contentRect.height - dx);
                            case 180:
                                return Qt.point(videoOutput.contentRect.x + videoOutput.contentRect.width - dx, videoOutput.contentRect.y + videoOutput.contentRect.height -dy);
                            case 270:
                                return Qt.point(videoOutput.contentRect.x + videoOutput.contentRect.width - dy, videoOutput.contentRect.y + dx);
                        }
                    }

                    Shape {
                        id: polygon
                        anchors.fill: parent
                        visible: barcodeReaderRect.points.length === 4

                        ShapePath {
                            strokeWidth: 3
                            strokeColor: "red"
                            strokeStyle: ShapePath.SolidLine
                            fillColor: "transparent"
                            //TODO: really? I don't know qml...
                            startX: videoOutput.mapPointToItem(barcodeReaderRect.points[3]).x
                            startY: videoOutput.mapPointToItem(barcodeReaderRect.points[3]).y

                            PathLine {
                                x: videoOutput.mapPointToItem(barcodeReaderRect.points[0]).x
                                y: videoOutput.mapPointToItem(barcodeReaderRect.points[0]).y
                            }
                            PathLine {
                                x: videoOutput.mapPointToItem(barcodeReaderRect.points[1]).x
                                y: videoOutput.mapPointToItem(barcodeReaderRect.points[1]).y
                            }
                            PathLine {
                                x: videoOutput.mapPointToItem(barcodeReaderRect.points[2]).x
                                y: videoOutput.mapPointToItem(barcodeReaderRect.points[2]).y
                            }
                            PathLine {
                                x: videoOutput.mapPointToItem(barcodeReaderRect.points[3]).x
                                y: videoOutput.mapPointToItem(barcodeReaderRect.points[3]).y
                            }
                        }
                    }

                    Label {
                        id: info
                        color: "white"
                        padding: 10
                        background: Rectangle { color: "#80808080" }
                    }

                    ColumnLayout {
                        anchors{
                            right: parent.right
                            bottom: parent.bottom
                        }

                        CustomButton {
                            id: barcodeReaderCancelBtn
                            text: "Cancel"
                            defaultColor: "#E0E0E0"
                            anchors{
                                bottom: parent.bottom
                                right: parent.right
                            }

                            onClicked: {
                                barcodeReaderPopup.close()
                            }
                        }
                    }
                }
            }
        }
    }

    //navigation Rectangle
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
        }
    }


    function resetPagination() {
        currentPage = 1
        previousPage = 0
        nextPage = 2
    }

    function fetchCurrentPageData() {
        const offset = currentPage //* itemsPerPage
        issueBooksList.fetchBooks(currentPage,100)
    }


    Component.onCompleted:{
        issueBooksList.fetchBooks(1,100)
    }
}















