import QtQuick
import QtQuick.Controls

Rectangle {
    id: settingsPage
    width: 800
    height: 600
    property double calculatedHeight: 0
    property double flowItemHeight: flowItem.calculateFlowHeight()

    Rectangle{
        id: settingsSearchBox
        width: parent.width* .5
        radius: 4
        height: 40
        anchors{
            top: parent.top
            topMargin: 30
            horizontalCenter: parent.horizontalCenter
        }
        clip: true
        color: "transparent"
        border.color: "blue"
        border.width: 2

        property string placeHolderText: "Search for tools..."

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
        }

        Text{
            id: searchBoxPlaceHolder
            visible: settingsTextInput.text === ""
            color: "#585757"
            text: "Search for settings..."
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
                id: settingsTextInput
                clip: true
                anchors{
                    right: parent.right
                    rightMargin: 5
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
        //            leftMargin: 20
                }

                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11
                onTextChanged: flowItem.updateVisibility(settingsTextInput.text)
            }
        }
    }

    Flow {
        id: flowItem
        anchors {
            top: settingsSearchBox.bottom
            topMargin: 30
            left: parent.left
            leftMargin: 10
            rightMargin: 10
            right: parent.right
        }
        spacing: 20

        function updateVisibility(query) {
            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (item.description) {
                    item.visible = item.description.toLowerCase().indexOf(query.toLowerCase()) !== -1 ||
                        item.headerTxt.toLowerCase().indexOf(query.toLowerCase()) !== -1;
                }
            }
            calculateFlowHeight();
        }

        function calculateFlowHeight() {
            let currentWidth = 0;
            let rowHeight = 0;
            let totalHeight = 0;
            let spacing = flowItem.spacing;

            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (!item.visible) continue;

                if (currentWidth + item.width > flowItem.width) {
                    totalHeight += rowHeight + spacing;
                    currentWidth = 0;
                    rowHeight = 0;
                }

                currentWidth += item.width + spacing;
                rowHeight = Math.max(rowHeight, item.height);
            }

            totalHeight += rowHeight; // Add the last row's height
            calculatedHeight = totalHeight;
//            console.log("Calculated Height: ", totalHeight);
            return totalHeight;
        }

        //Signal to calculate the height when items change
        onChildrenChanged: calculateFlowHeight()

        Component.onCompleted: calculateFlowHeight()

        // SettingsTemplate items...
        SettingsTemplate{
            id: general
            icon: "assets/library.png"
            headerTxt: "General"
            description: "Edit or modify library settings"
            instruction: function(){
                console.log("General Settings")
            }
        }

        SettingsTemplate{
            id: users
            icon: "assets/userSettings1.png"
            headerTxt: "Users"
            description: "Manage user settings"
            instruction: function(){
                console.log("User Settings")
            }
        }

        SettingsTemplate{
            id: books
            icon: "assets/book.png"
            headerTxt: "Books"
            description: "Checkout, return policies"
            instruction: function(){
                console.log("Book Settings")
            }
        }

        SettingsTemplate{
            id: backup
            icon: "assets/cloud-storage.png"
            headerTxt: "Backup"
            description: "Store data in the cloud for retrieval in case of damage or loss"
            instruction: function(){
                console.log("Backup, restore Settings")
            }
        }

        SettingsTemplate{
            id: reports
            icon: "assets/report.png"
            headerTxt: "Reports"
            description: "Usage analytics"
            instruction: function(){
                console.log("Reports Settings")
            }
        }

        SettingsTemplate{
            id: security
            icon: "assets/privacy-policy.png"
            headerTxt: "Security"
            description: "Data encryption, passwords"
            instruction: function(){
                console.log("Security Settings")
            }
        }

        SettingsTemplate{
            id: notifications
            icon: "assets/mail.png"
            headerTxt: "Notifications"
            description: "Mail configurations"
            instruction: function(){
                console.log("Notifications Settings")
            }
        }

        SettingsTemplate{
            id: digitalContent
            icon: "assets/content-management.png"
            headerTxt: "Digital Content"
            description: "Video tapes, Audio, Pictures, Ebooks"
            instruction: function(){
                console.log("Digital Content Settings")
            }
        }

        SettingsTemplate{
            id: ui
            icon: "assets/edit-document.png"
            headerTxt: "UI"
            description: "Customize user interface"
            instruction: function(){
                console.log("UI Settings")
            }
        }

        SettingsTemplate{
            id: system
            icon: "assets/modular.png"
            headerTxt: "System"
            description: "Autologout, system updates"
            instruction: function(){
                console.log("System Settings")
            }
        }

        SettingsTemplate{
            id: about
            icon: "assets/info3.png"
            headerTxt: "About"
            description: "Info about this application system"
            instruction: function(){
                console.log("About the system")
            }
        }
    }
}
