import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQuick.Effects
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "DynamicComponentLoader.js" as CustomComponentLoader

// import UserAddition 1.0

Rectangle{
    id: registrationForm
    anchors.fill: parent
    radius: 8
    border.color: "white" //"#CDCACA"

    signal closeClicked()

    property var addManyUsers: null
    property string userImageSource: "assets/userImage.png"

    // UserAddition{
    //     id: userAddition
    //     onErrorOccurred: (erroMessage) =>{
    //         console.log(erroMessage)
    //         messageText.text = (erroMessage)
    //         messageBox.visible = true
    //         notificationSound.play()
    //         messageTimer.restart()
    //     }
    // }

    Connections{
        target: userManager
        function onErrorOccurred(erroMessage){
        console.log(erroMessage)
        messageText.text = (erroMessage)
        messageBox.visible = true
        notificationSound.play()
        messageTimer.restart()
    }
    }


    Rectangle{
        id: registrationFormRect
        height: parent.height* .95
        width: parent.width* .95
        anchors.centerIn: parent

        Rectangle{
            id: closeRect
            width: 40
            height: 40
            radius: 4
            anchors{
                right: parent.right
                top: parent.top
            }

            Rectangle{
                id: closeImageRect
                width: 20
                height: 20
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image{
                    id: close
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/close.png"
                }
            }

            MouseArea{
                id: closeMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    closeRect.color = "#E8E3E4"
                }
                onExited: {
                    closeRect.color = "white"
                }

                onClicked: {
                    registrationForm.closeClicked()
                }
            }
        }

        Rectangle{
            id: menuRect
            width: 60
            height: 40
            radius: 4
            anchors{
                right: closeRect.left
                top: parent.top
            }

            Image{
                id: menuImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/menu.png"
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
                    text: "New..."
                }
                MenuItem {
                    text: "Open..."
                }
                MenuItem {
                    text: "Save"
                }
            }
        }

        Rectangle{
            id: manyRect
            width: 40
            height: 40
            anchors{
                right: menuRect.left
                top: parent.top
            }

            Image{
                id: many
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/group1.png"
            }

            MouseArea{
                id: manyMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    many.source = "assets/group.png"
                }
                onExited: {
                    many.source = "assets/group1.png"
                }

                onClicked: {
                    CustomComponentLoader.customCreateComponent(addManyUsers,"AddManyUsers", registrationForm)
                }
            }
        }

        Text {
            id: titleText
            text: qsTr("Add User")
            color: "#897575"
            anchors{
                verticalCenter: manyRect.verticalCenter
                left: parent.left
            }
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pointSize: 14
        }


        Item{
            id: scrollItem
            width: parent.width
            anchors{
                top: menuRect.bottom
                topMargin: 5
                bottom: parent.bottom
            }

            ScrollView{
                id: registrationSV
                anchors.fill: parent
                contentHeight: 323
                visible: false

                Rectangle {
                    id: adminAvatarRect
                    height: 80
                    width: height
                    radius: width/2
                    clip: true
                    anchors{
                        top: parent.top
                        left: parent.left
                        leftMargin: 5
                    }

                    color: "transparent"

                    Image {
                        id: sourceItem
                        source: userImageSource
                        anchors.centerIn: parent
                        width: parent.width //* 0.4688
                        height: width
                        visible: false
                        fillMode: Image.PreserveAspectCrop
                    }

                    MultiEffect {
                        source: sourceItem
                        anchors.fill: sourceItem
                        maskEnabled: true
                        maskSource: mask
                    }

                    Item {
                        id: mask
                        width: sourceItem.width
                        height: sourceItem.height
                        layer.enabled: true
                        visible: false

                        Rectangle {
                            width: sourceItem.width
                            height: sourceItem.height
                            radius: width / 2
                            color: "black"
                        }
                    }

                    FileDialog {
                        id: fileDialog
                        title: "Select Profile Picture"
                        nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif)"]
                        onAccepted: {
                            if (fileDialog.currentFile) {
                                var fileUrl = fileDialog.currentFile
                                console.log("Selected file:", fileUrl)
                                userImageSource = fileUrl
                            }
                        }
                        onRejected: {
                            console.log("Canceled")
                        }
                    }

                    MouseArea {
                        anchors.fill: sourceItem
                        cursorShape: "PointingHandCursor"
                        onClicked: fileDialog.open()
                        hoverEnabled: true
                        onEntered: tooltip.visible = true
                        onExited: tooltip.visible = false
                    }
                }

                //This is a tooltip that shows up when the profilePic is hovered over
                Rectangle {
                    id: tooltip
                    implicitWidth: 166
                    height: 20
                    color: "black"
                    visible: false
                    anchors{
                        left: adminAvatarRect.horizontalCenter
                        verticalCenter: adminAvatarRect.verticalCenter

                    }

                    radius: 5

                    Text {
                        anchors.centerIn: parent
                        color: "white"
                        text: "Click to change profile picture"
                        font.pixelSize: 12
                    }
                }


                //Fisrt Name
                Rectangle{
                    id: firstName
                    radius: 4
                    width: parent.width* .48
                    height: 40
                    border.color: fNameTextInput.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        left: parent.left
                        leftMargin: 5
                        top: adminAvatarRect.bottom
                        topMargin: 20
                    }

                    MouseArea{
                        id: fNameTextInputMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: fNameTextInput
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
                            validator: RegularExpressionValidator {
                                // Regular expression to validate only letters and spaces
                                regularExpression: /^[a-zA-Z\s]+$/
                            }
                        }

                    }

                    Text{
                        id: fNameTextInputPlaceHolder
                        visible: fNameTextInput.text === ""
                        color: "#585757"
                        text: "FIRST NAME"
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }


                //Second Name
                Rectangle{
                    id: secondName
                    radius: 4
                    width: parent.width* .48
                    height: 40
                    border.color: sNametextInput.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        left: firstName.right
                        leftMargin: 5
                        top: firstName.top
                    }


                    MouseArea{
                        id: sNameMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: sNametextInput
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
                            validator: RegularExpressionValidator {
                                // Regular expression to validate only letters and spaces
                                regularExpression: /^[a-zA-Z\s]+$/
                            }
                        }
                    }

                    Text{
                        id: sNameTextInputPlaceHolder
                        visible: sNametextInput.text === ""
                        color: "#585757"
                        text: "SURNAME"
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }


                //ADM
                Rectangle {
                    id: admNo
                    radius: 4
                    height: 40
                    border.color: admNoTextInput.activeFocus ? "#399ED9" : "transparent"
                    color: "#E0E0E0"
                    border.width: 2

                    anchors {
                        left: firstName.left
                        top: firstName.bottom
                        topMargin: 10
                        right: firstName.horizontalCenter
                    }

                    MouseArea {
                        id: admNoMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput {
                            id: admNoTextInput
                            clip: true
                            anchors {
                                right: parent.right
                                rightMargin: 5
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                leftMargin: 5
                            }
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        id: admNoTextInputPlaceHolder
                        visible: admNoTextInput.text === ""
                        color: "#585757"
                        property alias userRole: rolePopup.userRole
                        text: {
                            // Dynamically change the placeholder based on userRole
                            if (userRole === "Student") {
                                return "ADM NO."
                            } else if (userRole === "Staff") {
                                return "STAFF ID"
                            } else if (userRole === "Other user") {
                                return "ID NO."
                            } else {
                                return "ADM NO." // Default to ADM NO if no role selected
                            }
                        }
                        anchors {
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }

                Rectangle{
                    id: wing
                    radius: 4
                    width: admNo.width
                    height: 40
                    border.color: wingTextInput.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        left: admNo.right
                        top: admNo.top
                        leftMargin: 5
                        right: secondName.horizontalCenter
                    }


                    MouseArea{
                        id: wingMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: wingTextInput
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
                            validator: RegularExpressionValidator {
                                // Regular expression to validate only letters and spaces
                                regularExpression: /^[a-zA-Z\s]+$/
                            }
                        }
                    }

                    Text{
                        id: wingTextInputPlaceHolder
                        visible: wingTextInput.text === ""
                        color: "#585757"
                        property alias userRole: rolePopup.userRole
                        text: {
                            // Dynamically change the placeholder based on userRole
                            if (userRole === "Student") {
                                return "BRANCH/WING"
                            } else if (userRole === "Staff") {
                                return "DEPARTMENT"
                            } else if (userRole === "Other user") {
                                return "RESIDENCE"
                            } else {
                                return "BRANCH/WING" // Default to BRANCH/WING if no role selected
                            }
                        }
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }

                Rectangle{
                    id: year
                    radius: 4
                    width: admNo.width
                    height: 40
                    border.color: yearTextInput.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        left: wing.right
                        leftMargin: 5
                        top: admNo.top
                        right: secondName.right
                    }



                    MouseArea{
                        id: yearMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"
                        TextInput{
                            id: yearTextInput
                            clip: true
                            property alias userRole: rolePopup.userRole
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
                            validator: IntValidator {
                                bottom: 1960
                                top: 2024
                            }
                        }
                    }

                    Text{
                        id: yearTextInputPlaceHolder
                        visible: yearTextInput.text === ""
                        color: "#585757"
                        property alias userRole: rolePopup.userRole
                        text: {
                            // Dynamically change the placeholder based on userRole
                            if (userRole === "Student") {
                                return "ENROLLMENT YEAR"
                            } else if (userRole === "Staff") {
                                return "START YEAR"
                            } else if (userRole === "Other user") {
                                return "AGE"
                            } else {
                                return "ENROLLMENT YEAR" // Default to ENROLLMENT YEAR if no role selected
                            }
                        }
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }

                Rectangle{
                    id: email
                    radius: 4
                    height: 40
                    border.color: emailTextInput.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2

                    anchors{
                        left: firstName.left
                        top: admNo.bottom
                        topMargin: 10
                        right: wing.right
                    }

                    MouseArea{
                        id: emailMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: emailTextInput
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

                            validator: RegularExpressionValidator {
                                // Regular expression to validate email address
                                regularExpression: /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
                            }
                        }
                    }

                    Text{
                        id: emailTextInputPlaceHolder
                        visible: emailTextInput.text === ""
                        color: "#585757"
                        text: "EMAIL"
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }

                ListModel{
                    id: studentModel
                    ListElement { text: "Select level" }
                    ListElement { text: "Undergraduate" }
                    ListElement { text: "Postgraduate" }
                    ListElement { text: "Short course" }
                    ListElement { text: "TVET" }
                }

                ListModel{
                    id: staffModel
                    ListElement { text: "Select staff category" }
                    ListElement { text: "Administrative" }
                    ListElement { text: "Library staff" }
                    ListElement { text: "Academic" }
                    ListElement { text: "Non-Academic" }
                }

                ListModel{
                    id: otherUserModel
                    ListElement { text: "Gender" }
                    ListElement { text: "Male" }
                    ListElement { text: "Female" }
                }

                ComboBox {
                    id: categoryComboBox
                    width: parent.width / 2
                    height: 50
                    editable: true
                    property alias userRole: rolePopup.userRole
                    anchors {
                        left: email.right
                        leftMargin: 5
                        top: email.top
                        right: secondName.right
                    }
                    model: {
                        // Dynamically change the placeholder based on userRole
                        if (userRole === "Student") {
                            return studentModel;
                        } else if (userRole === "Staff") {
                            return staffModel;
                        } else if (userRole === "Other user") {
                            return otherUserModel;
                        } else {
                            return studentModel; // Default to ENROLLMENT YEAR if no role selected
                        }
                    }
                    Keys.onReturnPressed: {
                        var newText = categoryComboBox.editText;
                        console.log("Return pressed with text:", newText);
                        if (newText && !containsCategory(newText)) {
                            console.log("Adding new category:", newText);
                            categoryComboBox.model.append({"text": newText});
                            categoryComboBox.currentText = newText;
                        } else {
                            console.log("Category already exists or invalid:", newText);
                        }

                        if (!isValidSelection()) {
                            console.log("Please select a valid level.");
                            return; // Do not proceed if placeholder is selected
                        }

                        // Proceed with saving the selected value to the database
                        console.log("Selected level:", categoryComboBox.currentText);
                    }

                    function containsCategory(category) {
                        for (var i = 0; i < categoryComboBox.count; i++) {
                            if (categoryComboBox.model.get(i).text === category) {
                                return true;
                            }
                        }
                        return false;
                    }

                    // Add a validation function
                    function isValidSelection() {
                        return currentIndex > 0; // Ensure user did not select "Select level"
                    }

                    onAccepted: {
                        if (!isValidSelection()) {
                            console.log("Please select a valid level.");
                            return; // Do not proceed if placeholder is selected
                        }

                        // Proceed with saving the selected value to the database
                        console.log("Selected level:", categoryComboBox.currentText);
                    }
                }

                Rectangle{
                    id: phoneNo
                    radius: 4
                    height: 40
                    border.color: phoneNoTextInput.activeFocus ? "#399ED9" : "transparent" //"#D2D2D2"
                    property string placeHolderText: ""
                    color: "#E0E0E0" //"#CBCECE"
                    border.width: 2
                    visible: true //rolePopup.userRole === "Other user"

                    anchors{
                        left: firstName.left
                        top: email.bottom
                        topMargin: 10
                        right: firstName.horizontalCenter
                    }


                    MouseArea{
                        id: phoneNoMA
                        anchors.fill: parent
                        cursorShape: "IBeamCursor"

                        TextInput{
                            id: phoneNoTextInput
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

                            validator: RegularExpressionValidator {
                                // Regular expression to validate phone number (e.g. country code + digits)
                                regularExpression: /^(\+\d{1,3})?\d{7,12}$/
                            }
                        }
                    }

                    Text{
                        id: phoneNoTextInputPlaceHolder
                        visible: phoneNoTextInput.text === ""
                        color: "#585757"
                        text: "PHONE NO."
                        anchors{
                            left: parent.left
                            leftMargin: 5
                            verticalCenter: parent.verticalCenter
                        }
                        font.pixelSize: 16
                    }
                }


                CustomButton{
                    id: registerButton
                    anchors{
                        right: categoryComboBox.right
                        top: categoryComboBox.bottom
                        topMargin: 20
                    }
                    text: "Register"
                    defaultColor: "#399ED9"
                    hoveredColor: "#399ED9"

                    onClicked: {
                        // Perform validation check before proceeding
                        if(validateInputs()){
                            if (!categoryComboBox.isValidSelection()) {
                                console.log("Please select a valid input.");

                                messageText.text = "Please select a valid input.!"
                                messageBox.visible = true
                                notificationSound.play()
                                errorMessageTimer.restart()
                                return; // Do not proceed if placeholder is selected
                            }

                            // Proceed with saving the user details to the database
                            handleRegistration()
//                            console.log("User added successfully with level:", categoryComboBox.currentText);
//                            messageText.text = "User added successfully!"
//                            messageBox.visible = true
//                            notificationSound.play()
//                            messageTimer.restart()  // Restart the timer

                            //clear the text inputs
//                            fNameTextInput.clear()
//                            sNametextInput.clear()
//                            admNoTextInput.clear()
//                            wingTextInput.clear()
//                            yearTextInput.clear()
//                            emailTextInput.clear()
//                            phoneNoTextInput.clear()
//                            categoryComboBox.currentIndex = 0

                        }
                    }
                }

                CustomButton{
                    id: cancelButton
                    anchors{
                        right: registerButton.left
                        rightMargin: 7
                        top: registerButton.top
                    }
                    text: "Cancel"
                    defaultColor: "#E0E0E0"
                }

                Rectangle {
                    id: messageBox
                    width: 200
                    height: Math.max(100, messageText.height + 40)
                    //                color: "gray"
                    color: Qt.rgba(0,0,0, 0.4)
                    radius: 8
                    visible: false  // Initially hidden
                    anchors{
                        centerIn: parent
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
                            source: "assets/info.png"
                        }
                    }

                    Text {
                        id: messageText
                        color: "white"
                        anchors{
                            top: infoIconRect.bottom
                            topMargin: 10 //messageBox.height > 100 ? 10 : 20
                            left: parent.left
                            leftMargin: 10
                            right: parent.right
                            rightMargin: 8
                        }

                        font.pixelSize: 16
                        wrapMode: Text.WordWrap
                    }
                }

                // Timer to hide the message after a short delay
                Timer {
                    id: messageTimer
                    interval: 2000  // 3 seconds
                    repeat: false
                    onTriggered: {
                        messageBox.visible = false
                        notificationSound.stop()
                        registrationSV.visible = !registrationSV.visible
                        rolePopup.open()
                    }
                }

                //another timer to hide message box if theres an input error
                Timer {
                    id: errorMessageTimer
                    interval: 6000  // 2 seconds
                    repeat: false
                    onTriggered: {
                        messageBox.visible = false
                        notificationSound.stop()
                    }
                }

                Timer {
                    id: emptyMessageTimer
                    interval: 5000  // 2 seconds
                    repeat: false
                    onTriggered: {
                        messageBox.visible = false
                        notificationSound.stop()
                    }
                }

                SoundEffect {
                    id: notificationSound
                    source: "assets/messagePop.wav"
                    volume: 1.0
                    muted: false
                }
            }

            //adding a popup to ask for user role
            Popup{
                id: rolePopup
                width: Math.max(roleSetterBtn.width+popupCancelBtn.width+ 40, 200* (parent.width/1000)) //200* (parent.width/1000)
                height: 300 //100* (parent.width/480)
                anchors.centerIn: parent
                modal: true
                focus: true
                topInset: 8
                leftInset: 8
                rightInset: 8
                bottomInset: 8
                closePolicy: Popup.NoAutoClose

                property string userRole: "Student"

                Rectangle{
                    id: roleDisplayRect
                    anchors.fill: parent
                    clip: true
                    radius: 8
                    color: "#FBFBFB"

                    Text {
                        id: roleTitle
                        text: qsTr("Please select user role")
                        anchors{
                            left: parent.left
                            leftMargin: 10
                            top: parent.top
                            topMargin: 10
                        }
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.pointSize: 12
                    }

                    ColumnLayout{
                        id: roleLayout
                        spacing: 10
                        anchors{
                            left: parent.left
                            leftMargin: 10
                            top: roleTitle.bottom
                            topMargin: 10
                        }

                        RadioButton{
                            id: studentRadio
                            checked: true
                            text: "Student"
                            onClicked: {
                                rolePopup.userRole = "Student"
                            }
                        }
                        RadioButton{
                            id: staffRadio
                            text: "Staff"
                            onClicked: {
                                rolePopup.userRole = "Staff"
                            }
                        }
                        RadioButton{
                            id: otherUserRadio
                            text: "Other user"
                            onClicked: {
                                rolePopup.userRole = "Other user"
                            }
                        }
                    }

                    CustomButton{
                        id: roleSetterBtn
                        text: "Continue"
                        anchors{
                            right: parent.right
                            rightMargin: 10
                            top: roleLayout.bottom
                            topMargin: 20
                        }

                        defaultColor: "#399ED9"
                        hoveredColor: "#399ED9"

                        onClicked: {
                            console.log("User role: ", rolePopup.userRole)
                            registrationSV.visible = !registrationSV.visible
                            rolePopup.close()
                        }
                    }

                    CustomButton{
                        id: popupCancelBtn
                        text: "Cancel"
                        anchors{
                            right: roleSetterBtn.left
                            rightMargin: 7
                            verticalCenter: roleSetterBtn.verticalCenter
                        }
                        defaultColor: "#E0E0E0"
                        hoveredColor: "#E0E0E0"

                        onClicked: {
                            rolePopup.close()
                            registrationForm.closeClicked()
                        }
                    }
                }

                CustomDropShadow {
                    source: roleDisplayRect
                    visible: true
                    horizontalOffset: -3
                    verticalOffset: -3
                    samples: 16
                }
            }
        }
    }

    // Function to validate inputs
        function validateInputs() {
            let emptyFields = [];
            if (fNameTextInput.text === "") {
                emptyFields.push("First Name");
            }
            if (sNametextInput.text === "") {
                emptyFields.push("Second Name");
            }
            if (admNoTextInput.text === "") {
                emptyFields.push("Admission Number");
            }
            if (wingTextInput.text === "") {
                emptyFields.push("Wing");
            }
            if (emailTextInput.text === "") {
                emptyFields.push("Email");
            }
            if (rolePopup.userRole ==="Other user" && phoneNoTextInput.text === "") {
                emptyFields.push("Phone Number");
            }
            if (emptyFields.length > 0) {
                showMessageBox("Please fill in the following fields: " + emptyFields.join(", "));
                return false; // Validation failed
            }
            return true; // Validation successful
        }

        // Function to show the message box with empty fields
        function showMessageBox(message) {
            messageText.text = message;
            messageBox.visible = true;
            notificationSound.play()
            emptyMessageTimer.start()
        }

        // a function to add users
        function handleRegistration(){
            var additionalInfo = {}

            if(rolePopup.userRole === "Student"){
                additionalInfo = {
                    adm_no: admNoTextInput.text,
                    branch: wingTextInput.text,
                    enrollment_year: yearTextInput.text,
                    level: categoryComboBox.currentText
                }
            }else if(rolePopup.userRole === "Staff"){
                additionalInfo = {
                    staff_no: admNoTextInput.text,
                    department: wingTextInput.text,
                    start_year: yearTextInput.text,
                    category: categoryComboBox.currentText
                }
            }else if (rolePopup.userRole === "Other user"){
                additionalInfo = {
                    user_no: admNoTextInput.text,
                    residence: wingTextInput.text,
                    age: yearTextInput.text,
                    gender: categoryComboBox.currentText,
                    phone: phoneNoTextInput.text
                }
            }

            userManager.addUser(
                fNameTextInput.text,
                sNametextInput.text,
                emailTextInput.text,
                phoneNoTextInput.text,
                rolePopup.userRole,
                additionalInfo
            )
        }

    Component.onCompleted:{
        registrationSV.visible = false
        rolePopup.open()
    }
}
