import QtQuick
import QtQuick.Controls.Windows
import com.bookmanager 1.0

Rectangle {
    id: addBooksContainer
    anchors.fill: parent
    color: "white"
    radius: 8
    border.color: "#CDCACA"

    signal closeClicked()

    //the book manager class for adding and removing books
    BookManager{
        id: bookManager

        onErrorOccured: (error) => {
                            console.log(error)
                        }

        onBookAdded: {
            console.log("Book added successfully!")
        }
    }

    Rectangle{
        id: topItemsContainer
        height: 50
        width: parent.width
        radius: 8
        //        color: "#F0F0F0"
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Rectangle{
            id: backRect
            width: 40
            height: 40
            radius: 4
            color: "#DDDDDD"
            anchors{
                left: parent.left
                leftMargin: 5
                top: parent.top
                topMargin: 5
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
                    addBooksContainer.closeClicked()
                }
            }
        }

        Rectangle{
            id: addBooksTxtRect
            implicitWidth: addBooksTxt.width
            color: "transparent"

            anchors{
                left: backRect.right
                leftMargin: 30
                top: backRect.top
                bottom: backRect.bottom
            }

            Text {
                id: addBooksTxt
                anchors.verticalCenter: parent.verticalCenter

                text: "Add a new book"
                font.bold: false
                font.pointSize: 12
            }
        }
    }



    ScrollView{
        id: addBooksSV
        anchors{
            top: topItemsContainer.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: bookDetailsRect.height

        Rectangle{
            id: bookDetailsRect
            width: parent.width* .95
            radius: 8
            height: parent.height* .98
            anchors{
                top: parent.top
                topMargin: 10
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 20
            }
//            border.color: "#DDDDDD"


            Rectangle{
                id: coverImgRect
                width: parent.width/6
                height: parent.height/3
                anchors{
                    left: parent.left
                    leftMargin: 10
                    top: parent.top
                    topMargin: 10
                }
                color: "transparent"
                //                border.color: "lightblue"

                Image{
                    id: coverImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/stack-of-books.png"
                }
            }

            Rectangle{
                id: firstSeparater
                height: parent.height/2
                width: 2
                //                color: "#DDDDDD"
                //                color: "#8E8E8E"
                color: "transparent"
                anchors{
                    top: parent.top
                    left: coverImgRect.right
                    leftMargin: 30
                    topMargin: 10
                }
            }

            Rectangle{
                id: metadataTxtRect
                implicitWidth: meatadataTxt.width
                height: 40
                color: "transparent"

                anchors{
                    left: firstSeparater.right
                    leftMargin: 30
                    top: firstSeparater.top
                }

                Text {
                    id: meatadataTxt
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Metadata"
                    font.bold: false
                    font.pointSize: 12
                }
            }

            Rectangle{
                id: metadataContainer
                width: parent.width/2
                height: Math.min(260, parent.height/2)
                anchors{
                    left: metadataTxtRect.left
                    top: metadataTxtRect.bottom
                    bottom: firstSeparater.bottom
                }
//                border.color: "lightgray"

                CustomTextField{
                    id: bookTitle
                    width: parent.width* .6
                    height: 40
                    anchors{
                        left: parent.left
                        top: parent.top
                        leftMargin: 5
                        topMargin: 5
                    }
                    placeholderText: "Title"
                }

                CustomTextField{
                    id: bookAuthor
                    height: 40
                    anchors{
                        left: bookTitle.right
                        top: bookTitle.top
                        leftMargin: 5
                        right: parent.right
                        rightMargin: 5
                    }
                    placeholderText: "Author"
                }

                CustomTextField{
                    id: callNumber
                    width: parent.width/3
                    height: 40
                    anchors{
                        left: parent.left
                        top: bookTitle.bottom
                        leftMargin: 5
                        topMargin: 5
                    }
                    placeholderText: "Call Number"
                }

                CustomTextField{
                    id: bookPublisher
                    height: 40
                    anchors{
                        left: callNumber.right
                        top: callNumber.top
                        leftMargin: 5
                        right: bookTitle.right
                        rightMargin: 5
                    }
                    placeholderText: "Publisher"
                }

                CustomTextField{
                    id: isbn
                    height: 40
                    anchors{
                        left: bookPublisher.right
                        top: bookPublisher.top
                        leftMargin: 5
                        right: parent.right
                        rightMargin: 5
                    }
                    placeholderText: "ISBN"
                }

                //make it readOnly so that it's contents will be decided by the generateBarcode function
                CustomTextField{
                    id: barcode
                    width: parent.width/3
                    height: 40
                    anchors{
                        left: parent.left
                        top: isbn.bottom
                        leftMargin: 5
                        topMargin: 5
                    }
                    readOnly: true
                    placeholderText: "Barcode"
                }

                CustomTextField{
                    id: yearPublished
                    width: parent.width/3
                    height: 40
                    anchors{
                        left: barcode.right
                        top: isbn.bottom
                        leftMargin: 5
                        topMargin: 5
                    }
                    placeholderText: "Year Published"
                }

                Rectangle{
                    id: locationTxtRect
                    implicitWidth: locationTxt.width
                    height: 40
                    color: "transparent"

                    anchors{
                        top: barcode.bottom
                        leftMargin: 5
                        topMargin: 5
                    }

                    Text {
                        id: locationTxt
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Location"
                        font.bold: false
                        font.pointSize: 12
                    }
                }

                Rectangle{
                    id: shelfNumberRect
                    radius: 4
                    width: (parent.width/2) - 10
                    height: 40
                    border.color: shelfNumber.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        left: locationTxtRect.left
                        top: locationTxtRect.bottom
                        leftMargin: 5
                    }

                    MouseArea{
                        id: shelfMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: shelfNumber
                            clip: true
                            anchors{
                                right: parent.right
                                rightMargin: 5
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                leftMargin: 5
                            }

                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
//                            validator: RegularExpressionValidator {
//                                // Regular expression to validate only letters and spaces
//                                regularExpression: /^[a-zA-Z\s]+$/
//                            }
                        }
                    }

                    Text{
                        id: shelfTextInputPlaceHolder
                        visible: shelfNumber.text === ""
                        color: "#585757"
                        text: "Shelf number"
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }

                CustomTextField{
                    id: language
                    width: parent.width/3
                    height: 40
                    anchors{
                        left: locationTxtRect.left
                        top: shelfNumberRect.bottom
                        topMargin: 20
                    }
                    placeholderText: "Language"
                }

                Rectangle{
                    id: descriptionRect
                    radius: 4
                    width: (parent.width/2) - 10
                    height: 40
                    border.color: description.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        top: shelfNumberRect.top
                        left: shelfNumberRect.right
                        leftMargin: 10
                    }

                    MouseArea{
                        id: descriptionMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: description
                            clip: true
                            anchors{
                                right: parent.right
                                rightMargin: 5
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                leftMargin: 5
                            }

                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
//                            validator: RegularExpressionValidator {
//                                // Regular expression to validate only letters and spaces
//                                regularExpression: /^[a-zA-Z\s]+$/
//                            }
                        }
                    }

                    Text{
                        id: descriptionTextInputPlaceHolder
                        visible: description.text === ""
                        color: "#585757"
                        text: "Description"
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }
            }

            Rectangle{
                id: secondSeparater
                width: 2
                color: "#DDDDDD"
                anchors{
                    top: metadataTxtRect.bottom
                    left: metadataContainer.right
                    leftMargin: 10
                    topMargin: 10
                    bottom: metadataContainer.bottom
//                    bottom: parent.bottom
                }
            }

            Rectangle{
                id: cartegoryTxtRect
                implicitWidth: cartegoryTxt.width
                height: 40
                color: "transparent"

                anchors{
                    left: secondSeparater.right
                    leftMargin: 0
                    top: metadataTxtRect.top
                }

                Text {
                    id: cartegoryTxt
                    anchors.verticalCenter: parent.verticalCenter

                    text: "Cartegory"
                    font.bold: false
                    font.pointSize: 12
                }
            }

            Rectangle{
                id: cartegoryRect
                anchors{
                    top: cartegoryTxtRect.bottom
                    bottom: metadataContainer.bottom
                    left: secondSeparater.right
                    leftMargin: 10
                    right: parent.right
                    rightMargin: 20
                }
//                border.color: "lightgray"

                Label{
                    id: subjectLabel
                    width: parent.width/2
                    height: 40
                    anchors{
                        left: parent.left
                        top: parent.top
                        leftMargin: 5
                        topMargin: 5
                    }
                    text: qsTr("Subject: ")
                    verticalAlignment: "AlignVCenter"
                }

                ComboBox {
                    id: subjectComboBox
                    width: parent.width/2
                    height: 40
                    editable: true
                    anchors{
                        left: subjectLabel.right
                        right: parent.right
                        rightMargin: 5
                        top: parent.top
                        leftMargin: 5
                        topMargin: 5
                    }
                    model: ListModel {
                        ListElement { text: "Mathematics" }
                        ListElement { text: "History" }
                        ListElement { text: "Biology" }
                        ListElement { text: "Computer Science" }
                        ListElement { text: "Literature" }
                        ListElement { text: "Religous Studies" }
                    }
                    Keys.onReturnPressed: {
                        var newText = subjectComboBox.editText
                        console.log("Return pressed with text:", newText)
                        if (newText && !containsGenre(newText)) {
                            console.log("Adding new Subject:", newText)
                            subjectComboBox.model.append({"text": newText})
                            subjectComboBox.currentIndex = subjectComboBox.count - 1
                        } else {
                            console.log("Subject already exists or invalid:", newText)
                        }
                    }

                    function containsGenre(genre) {
                        for (var i = 0; i < subjectComboBox.count; i++) {
                            if (subjectComboBox.model.get(i).text === genre) {
                                return true
                            }
                        }
                        return false
                    }

                }

                Label{
                    id: genreLabel
                    width: parent.width/2
                    height: 40
                    anchors{
                        left: parent.left
                        top: subjectLabel.bottom
                        leftMargin: 5
                        topMargin: 5
                    }
                    text: qsTr("Genre: ")
                    verticalAlignment: "AlignVCenter"
                }

                ComboBox {
                    id: genreComboBox
                    width: parent.width/2
                    height: 40
                    editable: true
                    anchors{
                        left: genreLabel.right
                        right: parent.right
                        rightMargin: 5
                        top: subjectComboBox.bottom
                        leftMargin: 5
                        topMargin: 5
                    }
                    model: ListModel {
                        ListElement { text: "Fiction" }
                        ListElement { text: "Non-fiction" }
                        ListElement { text: "Science Fiction" }
                        ListElement { text: "Fantasy" }
                        ListElement { text: "Mystery" }
                        ListElement { text: "Biography" }
                        ListElement { text: "Academic" }
                        ListElement { text: "Reference" }
                    }
                    Keys.onReturnPressed: {
                        var newText = genreComboBox.editText
                        console.log("Return pressed with text:", newText)
                        if (newText && !containsGenre(newText)) {
                            console.log("Adding new genre:", newText)
                            genreComboBox.model.append({"text": newText})
                            genreComboBox.currentIndex = genreComboBox.count -1
                        } else {
                            console.log("Genre already exists or invalid:", newText)
                        }
                    }

                    function containsGenre(genre) {
                        for (var i = 0; i < genreComboBox.count; i++) {
                            if (genreComboBox.model.get(i).text === genre) {
                                return true
                            }
                        }
                        return false
                    }
                }

                Rectangle{
                    id: acquisitionTxtRect
                    implicitWidth: acquisitionTxt.width
                    height: 40
                    color: "transparent"

                    anchors{
                        top: genreLabel.bottom
                        left: genreLabel.left
                        topMargin: 5
                    }

                    Text {
                        id: acquisitionTxt
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Acquisition"
                        font.bold: false
                        font.pointSize: 12
                    }
                }

                CustomTextField{
                    id: bookValue
                    width: parent.width* .75
                    height: 40
                    anchors{
                        left: acquisitionTxtRect.left
                        top: acquisitionTxtRect.bottom
                        bottomMargin: 5
                    }
                    placeholderText: "Estimated Value: KES"
                }

                Label{
                    id: acquisitionLabel
                    width: parent.width/2
                    height: 40
                    anchors{
                        left: subjectLabel.left
                        top: bookValue.bottom
                        topMargin: 5
                    }
                    text: qsTr("Method: ")
                    verticalAlignment: "AlignVCenter"
                }

                ComboBox {
                    id: acquisitionMethodComboBox
                    width: parent.width/2
                    height: 40
                    editable: true
                    anchors{
                        left: acquisitionLabel.right
                        right: parent.right
                        rightMargin: 5
                        top: acquisitionLabel.top
                        leftMargin: 5
                        topMargin: 5
                    }
                    model: ListModel {
                        ListElement { text: "Purchase" }
                        ListElement { text: "Donation" }
                    }
                    Keys.onReturnPressed: {
                        var newText = acquisitionMethodComboBox.editText
                        console.log("Return pressed with text:", newText)
                        if (newText && !containsAcquisition(newText)) {
                            console.log("Adding new method:", newText)
                            acquisitionMethodComboBox.model.append({"text": newText})
                            acquisitionMethodComboBox.currentText = newText
                        } else {
                            console.log("Method already exists or invalid:", newText)
                        }
                    }

                    function containsAcquisition(genre) {
                        for (var i = 0; i < acquisitionMethodComboBox.count; i++) {
                            if (acquisitionMethodComboBox.model.get(i).text === genre) {
                                return true
                            }
                        }
                        return false
                    }
                }

                CustomButton{
                    id: closeBtn
                    anchors{
                        right: parent.right
                        top: acquisitionMethodComboBox.bottom
                        topMargin: 40
//                        rightMargin: 10
                    }
                    defaultColor: "#399ED9"
                    hoveredColor: "#399ED9"
                    text: "Add"

                    onClicked: {
                        barcode.text = generateBarcode(subjectComboBox.currentText)
                        console.log(shelfNumber.text)
                        allBooksList.addBook(bookTitle.text,
                                            bookAuthor.text,
                                            callNumber.text,
                                            bookPublisher.text,
                                            isbn.text,
                                            barcode.text,
                                            yearPublished.text,
                                            shelfNumber.text,
                                            description.text,
                                            language.text,
                                            subjectComboBox.currentText,
                                            genreComboBox.currentText,
                                            bookValue.text,
                                            acquisitionMethodComboBox.currentText
                                            )
                    }
                }

                CustomButton{
                    id: cancelButton
                    anchors{
                        right: closeBtn.left
                        rightMargin: 7
                        top: closeBtn.top
                    }
                    text: "Cancel"
                    defaultColor: "#E0E0E0"
                    onClicked: {

                    }
                }
            }
        }
    }

    function generateBarcode(category = "") {
        // use the first two characters of category, or default to "BC"
        const prefix = category ? category.substring(0, 2).toUpperCase() : "BC";

        //get current date in YYDDMM format
        const now = new Date();
        const year = now.getFullYear().toString().slice(-2);
        const month = (now.getMonth() + 1).toString().padStart(2, '0');
        const day = now.getDate().toString().padStart(2, '0');
        const timestamp = year + month + day;

        // Generate random 6-digit number
        const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');

        return prefix + timestamp + random;
    }
}

