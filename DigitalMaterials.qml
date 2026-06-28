import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import com.digitalMaterialsManager

Rectangle {
    id: digitalMaterialPage
    anchors.fill: parent
    color: "#F5F5F5"

    property alias digitalMaterialsManager: digitalMaterialsManager
    signal closeClicked()

    DigitalMaterialsManager{
        id: digitalMaterialsManager
        onErrorOccured: (error) =>{
                            errorDialog.title = "Error!"
                            errorDialog.text = error
                            errorDialog.open()
                        }

        onItemAdded: (itemName) =>{
                         errorDialog.title = "Success!"
                         errorDialog.text = "Successfully added item: " + itemName
                         errorDialog.open()
                     }

        onItemUpdated: (itemName) =>{
                           errorDialog.title = "Success!"
                           errorDialog.text = "Successfully updated item: " + itemName
                           errorDialog.open()
                       }

        onItemIssued: (itemName, userNumber, quantity) =>{
                          errorDialog.title = "Success!"
                          errorDialog.text = "Successfully issued(" + itemName + ")" + " to " + userNumber + "\nQuantity: " + quantity
                          errorDialog.open()
                      }

        onItemReturned: (itemName, quantity) => {
                            errorDialog.title = "Success!"
                            errorDialog.text = "Successfully returned " + itemName + "\nQuantity: " + quantity
                            errorDialog.open()
                        }

        onItemDeleted: (itemName) => {
                           errorDialog.title = "Success!"
                           errorDialog.text = "Successfully deleted item: " + itemName
                           errorDialog.open()
                       }

        onUserBorrowedQuantityChecked: (userNumber, quantity, message) =>{
                                           console.log(message)
                                           if (userNumber === userNumberField.text.trim()) {
                                               returnDialog.maxUserQuantity = quantity
                                               userBorrowedInfo.text = message
                                            }

                                           //update the enabled status of the quantity being returned
                                           if (quantity > 0){
                                               returnDialog.maxUserQuantity = quantity
                                               returnQuantityField.enabled = true
                                           }
        }
    }

    MouseArea{
        id: digitalMaterialPageMA
        anchors.fill: parent
    }

    // Title Bar
    Rectangle {
        id: titleBar
        width: parent.width
        height: 60
        color: "#FFFFFF"
        anchors.top: parent.top

        Text {
            id: titleText
            text: "Digital Materials Management"
            font.pixelSize: 16
            font.bold: true
            color: "#878585" //"#333333"
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
        }

        // Action buttons
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Button {
                text: "Add New Item"
                width: 120
                height: 44
                anchors.verticalCenter: parent.verticalCenter
                background: Rectangle {
                    color: parent.pressed ? "#45A049" : "#4CAF50"
                    // radius: 5
                    radius: 25
                    clip: true
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: addEditDialog.openForAdd()
            }

            Button {
                text: "View History"
                width: 100
                height: 44
                anchors.verticalCenter: parent.verticalCenter

                background: Rectangle {
                    color: parent.pressed ? "#8E24AA" : "#9C27B0"
                    // radius: 5
                    radius: 25
                    clip: true
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: historyDialog.open()
            }

            Button {
                text: "Refresh"
                width: 80
                height: 44
                anchors.verticalCenter: parent.verticalCenter

                background: Rectangle {
                    color: parent.pressed ? "#357ABD" : "#2196F3"
                    // radius: 5
                    radius: 25
                    clip: true
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (digitalMaterialsManager) {
                        digitalMaterialsManager.refreshItems()
                    }
                }
            }

            Rectangle{
                id: closeBtn
                width: 80
                height: 32
                radius: 25
    //            color: "#878585"
                border.color: "#878585"
                border.width: 2
                clip: true
                anchors.verticalCenter: parent.verticalCenter


                Text{
                    id: closeBtnTxt
                    anchors.centerIn: parent
                    text: "Close"
    //                color: "white"
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
                        closeClicked()
                    }
                }
            }
        }
    }

    // Separator
    Rectangle {
        id: separator
        width: parent.width
        height: 1
        color: "#E0E0E0"
        anchors.top: titleBar.bottom
    }

    // Main content area
    Rectangle {
        id: contentArea
        width: parent.width
        height: parent.height - titleBar.height - 1
        color: "#F5F5F5"
        anchors.top: separator.bottom

        // Header Row
        Row {
            id: headerRow
            width: parent.width - 40
            height: 50
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: parent.width / 5
                height: parent.height
                color: "lightgray"
                clip: true
                Text {
                    anchors.centerIn: parent
                    text: "Item Name"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#333333"
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
                    text: "Item Type"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#333333"
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
                    text: "Available"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#333333"
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
                    text: "Status"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#333333"
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
                    text: "Actions"
                    font.bold: true
                    font.pixelSize: 16
                    color: "#333333"
                }
            }
        }

        // List View
        ListView {
            boundsBehavior: Flickable.StopAtBounds
            id: itemsListView
            width: parent.width - 40
            height: parent.height - headerRow.height - 40
            anchors.top: headerRow.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            model: digitalMaterialsManager ? digitalMaterialsManager.itemsModel : null

            delegate: Rectangle {
                width: itemsListView.width
                height: 60
                color: index % 2 === 0 ? "#FFFFFF" : "#F9F9F9"
                border.color: "#E0E0E0"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        detailsDialog.openForItem(model)
                    }

                    onEntered: {
                        editButton.visible = !editButton.visible
                        issueButton.visible = !issueButton.visible
                        returnButton.visible = !returnButton.visible
                        deleteButton.visible = !deleteButton.visible
                    }

                    onExited: {
                        editButton.visible = !editButton.visible
                        issueButton.visible = !issueButton.visible
                        returnButton.visible = !returnButton.visible
                        deleteButton.visible = !deleteButton.visible
                    }
                }

                Row {
                    width: parent.width
                    height: parent.height

                    // Item Name
                    Rectangle {
                        width: parent.width / 5
                        height: parent.height
                        color: "transparent"
                        clip: true
                        Text {
                            width: parent.width -8
                            // anchors.centerIn: parent
                            anchors{
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            text: model.itemName || ""
                            font.pixelSize: 14
                            color: "#333333"
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: "#E0E0E0"
                    }

                    // Item Type
                    Rectangle {
                        width: parent.width / 5
                        height: parent.height
                        color: "transparent"
                        clip: true
                        Text {
                            anchors.centerIn: parent
                            text: model.itemType || ""
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: "#E0E0E0"
                    }

                    // Available Quantity
                    Rectangle {
                        width: parent.width / 5
                        height: parent.height
                        color: "transparent"
                        clip: true
                        Text {
                            anchors.centerIn: parent
                            text: (model.quantity - model.quantityBorrowed) + "/" + model.quantity
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle {
                        width: 1
                        height: parent.height
                        color: "#E0E0E0"
                    }

                    // Status
                    Rectangle {
                        width: parent.width / 5
                        height: parent.height
                        color: "transparent"
                        clip: true
                        Rectangle {
                            width: 80
                            height: 25
                            radius: 12
                            color: {
                                if (model.status === "Available") return "#4CAF50"
                                else if (model.status === "Borrowed") return "#FF9800"
                                else if (model.status === "Maintenance") return "#F44336"
                                else return "#9E9E9E"
                            }
                            anchors.centerIn: parent
                            Text {
                                text: model.status || ""
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                    }
                    // Rectangle {
                    //     width: 1
                    //     height: parent.height
                    //     color: "#E0E0E0"
                    // }

                    // Actions
                    Rectangle {
                        width: parent.width / 5
                        height: parent.height
                        color: "transparent"

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            Button {
                                id: editButton
                                text: "Edit"
                                width: 50
                                height: 30
                                visible: false
                                background: Rectangle {
                                    color: parent.pressed ? "#1976D2" : "#2196F3"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    addEditDialog.openForEdit(model)
                                }
                            }

                            Button {
                                id: issueButton
                                text: "Issue"
                                width: 50
                                height: 30
                                enabled: (model.quantity - model.quantityBorrowed) > 0
                                visible: false
                                background: Rectangle {
                                    color: parent.enabled ? (parent.pressed ? "#388E3C" : "#4CAF50") : "#CCCCCC"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.enabled ? "white" : "#666666"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    issueDialog.openForItem(model)
                                }
                            }

                            Button {
                                id: returnButton
                                text: "Return"
                                width: 50
                                height: 30
                                enabled: model.quantityBorrowed > 0
                                visible: false
                                background: Rectangle {
                                    color: parent.enabled ? (parent.pressed ? "#F57C00" : "#FF9800") : "#CCCCCC"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.enabled ? "white" : "#666666"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    returnDialog.openForItem(model)
                                }
                            }

                            Button {
                                id: deleteButton
                                text: "Delete"
                                width: 50
                                height: 30
                                visible: false
                                background: Rectangle {
                                    color: parent.pressed ? "#D32F2F" : "#F44336"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    deleteConfirmDialog.openForItem(model)
                                }
                            }
                        }
                    }
                }
            }
        }

        // No items message
        Text {
            anchors.centerIn: parent
            text: "No digital materials found"
            font.pixelSize: 18
            color: "#666666"
            visible: itemsListView.count === 0
        }
    }

    // Details Dialog
    Dialog {
        id: detailsDialog
        title: "Item Details"
        width: 500
        height: 600
        modal: true

        property var currentItem: null

        function openForItem(item) {
            currentItem = item
            open()
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F5F5"

            ScrollView {
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                anchors.fill: parent
                anchors.margins: 10

                Column {
                    width: parent.width
                    spacing: 15

                    // Item Name
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Item Name: " + (detailsDialog.currentItem ? detailsDialog.currentItem.itemName : "")
                            font.pixelSize: 16
                            font.bold: true
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Item Type
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Item Type: " + (detailsDialog.currentItem ? detailsDialog.currentItem.itemType : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Quantity Info
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Quantity: " + (detailsDialog.currentItem ? detailsDialog.currentItem.quantity : "") +
                                  " | Available: " + (detailsDialog.currentItem ? (detailsDialog.currentItem.quantity - detailsDialog.currentItem.quantityBorrowed) : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Status
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Status: " + (detailsDialog.currentItem ? detailsDialog.currentItem.status : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Location
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Location: " + (detailsDialog.currentItem ? (detailsDialog.currentItem.location || "Not specified") : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Condition
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Condition: " + (detailsDialog.currentItem ? (detailsDialog.currentItem.condition || "Not specified") : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Value
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Value: $" + (detailsDialog.currentItem ? (detailsDialog.currentItem.value || "0") : "0")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Date Added
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Date Added: " + (detailsDialog.currentItem ? detailsDialog.currentItem.dateAdded : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Current Holder
                    Rectangle {
                        width: parent.width
                        height: 50
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"
                        visible: false  //detailsDialog.currentItem && detailsDialog.currentItem.holder
                        /* Do not show this because it retrieves all the people that have ever borrowed the item*/

                        Text {
                            text: "Current Holder: " + (detailsDialog.currentItem ? (detailsDialog.currentItem.holder || "") : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Details
                    Rectangle {
                        width: parent.width
                        height: 100
                        color: "#FFFFFF"
                        radius: 5
                        border.color: "#E0E0E0"

                        Text {
                            text: "Details: " + (detailsDialog.currentItem ? (detailsDialog.currentItem.details || "No details provided") : "")
                            font.pixelSize: 14
                            color: "#333333"
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.top: parent.top
                            anchors.topMargin: 15
                            anchors.right: parent.right
                            anchors.rightMargin: 15
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        standardButtons: Dialog.Close
    }

    // Add/Edit Dialog
    Dialog {
        id: addEditDialog
        title: isEditing ? "Edit Item" : "Add New Item"
        width: 500
        height: 600
        modal: true

        property bool isEditing: false
        property var currentItem: null

        function openForAdd() {
            isEditing = false
            currentItem = null
            clearFields()
            open()
        }

        function openForEdit(item) {
            isEditing = true
            currentItem = item
            populateFields(item)
            open()
        }

        function clearFields() {
            nameField.text = ""
            typeCombo.currentIndex = 0
            quantityField.text = ""
            locationField.text = ""
            conditionCombo.currentIndex = 0
            valueField.text = ""
            statusCombo.currentIndex = 0
            detailsField.text = ""
        }

        function populateFields(item) {
            nameField.text = item.itemName || ""

            // Find and set the index for combo boxes
            var typeIndex = typeCombo.find(item.itemType || "")
            if (typeIndex !== -1) {
                typeCombo.currentIndex = typeIndex
            }
            quantityField.text = item.quantity || ""
            locationField.text = item.location || ""

            var conditionIndex = conditionCombo.find(item.condition || "")
            if (conditionIndex !== -1) {
                conditionCombo.currentIndex = conditionIndex
            }

            valueField.text = item.value || ""

            var statusIndex = statusCombo.find(item.status || "")
            if (statusIndex !== -1) {
                statusCombo.currentIndex = statusIndex
            }

            detailsField.text = item.details || ""
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F5F5"

            ScrollView {
                Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                anchors.fill: parent
                anchors.margins: 10

                Column {
                    width: parent.width
                    spacing: 15

                    // Item Name
                    Column {
                        width: parent.width
                        Text {
                            text: "Item Name *"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }

                        CustomTextField{
                            id: nameField
                            width: parent.width
                            placeholderText: "Enter item name"
                        }
                    }

                    // Item Type
                    Column {
                        width: parent.width
                        Text {
                            text: "Item Type *"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }
                        ComboBox {
                            id: typeCombo
                            width: parent.width
                            height: 40
                            model: ["DVD", "CD", "USB Drive", "Tablet", "Projector", "Laptop", "Camera", "Headphones", "Other"]
                            background: Rectangle {
                                color: "#FFFFFF"
                                border.color: "#E0E0E0"
                                border.width: 1
                                radius: 5
                            }
                        }
                    }

                    // Quantity
                    Column {
                        width: parent.width
                        Text {
                            text: "Quantity *"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }

                        CustomTextField{
                            id: quantityField
                            width: parent.width
                            placeholderText: "Enter quantity"
                            validator: IntValidator { bottom: 1; top: 9999 }
                        }
                    }

                    // Location
                    Column {
                        width: parent.width
                        Text {
                            text: "Location"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }

                        CustomTextField{
                            id: locationField
                            width: parent.width
                            placeholderText: "Enter location (optional)"
                        }
                    }

                    // Condition
                    Column {
                        width: parent.width
                        Text {
                            text: "Condition"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }
                        ComboBox {
                            id: conditionCombo
                            width: parent.width
                            height: 40
                            model: ["Good", "Fair", "Poor", "Excellent", "New"]
                            background: Rectangle {
                                color: "#FFFFFF"
                                border.color: "#E0E0E0"
                                border.width: 1
                                radius: 5
                            }
                        }
                    }

                    // Value
                    Column {
                        width: parent.width
                        Text {
                            text: "Value ($)"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }

                        CustomTextField{
                            id: valueField
                            width: parent.width
                            placeholderText: "Enter value (optional)"
                            validator: DoubleValidator { bottom: 0; top: 999999 }
                        }
                    }

                    // Status
                    Column {
                        width: parent.width
                        Text {
                            text: "Status"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }
                        ComboBox {
                            id: statusCombo
                            width: parent.width
                            height: 40
                            model: ["Available", "Borrowed", "Maintenance", "Out of Stock"]
                            background: Rectangle {
                                color: "#FFFFFF"
                                border.color: "#E0E0E0"
                                border.width: 1
                                radius: 5
                            }
                        }
                    }

                    // Details
                    Column {
                        width: parent.width
                        Text {
                            text: "Details"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#333333"
                        }
                        ScrollView {
                            Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds
                            width: parent.width
                            height: 80
                            TextArea {
                                id: detailsField
                                placeholderText: "Enter additional details (optional)"
                                wrapMode: TextArea.Wrap
                            }
                        }
                    }
                }
            }
        }

        standardButtons: Dialog.Save | Dialog.Cancel

        onAccepted: {
            if (nameField.text.trim() === "" || quantityField.text.trim() === "") {
                // Show error message
                return
            }

            if (digitalMaterialsManager) {
                if (isEditing) {
                    digitalMaterialsManager.updateItem(
                        currentItem.itemID,
                        nameField.text.trim(),
                        typeCombo.currentText,
                        parseInt(quantityField.text),
                        locationField.text.trim(),
                        conditionCombo.currentText,
                        parseFloat(valueField.text) || 0,
                        statusCombo.currentText,
                        detailsField.text.trim()
                    )
                } else {
                    digitalMaterialsManager.addItem(
                        nameField.text.trim(),
                        typeCombo.currentText,
                        parseInt(quantityField.text),
                        locationField.text.trim(),
                        conditionCombo.currentText,
                        parseFloat(valueField.text) || 0,
                        statusCombo.currentText,
                        detailsField.text.trim()
                    )
                }
            }
        }
    }

    // Issue Dialog
    Dialog {
        id: issueDialog
        title: "Issue Item"
        width: 400
        height: 400
        modal: true

        property var currentItem: null

        function openForItem(item) {
            currentItem = item
            userNumberField.text = ""
            issueQuantityField.text = "1"
            open()
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F5F5"
            clip: true

            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 20

                Text {
                    text: "Issue: " + (issueDialog.currentItem ? issueDialog.currentItem.itemName : "")
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333333"
                    width: parent.width - 8
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Column {
                    width: parent.width
                    spacing: 5
                    Text {
                        id: userNoText
                        text: "User Number *"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#333333"
                    }
                    TextField {
                        id: userNumberField
                        width: parent.width
                        height: 40
                        placeholderText: "Enter user number"
                    }
                }

                Column {
                    width: parent.width
                    spacing: 5
                    Text {
                        id: quantityText
                        text: "Quantity *"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#333333"
                    }
                    TextField {
                        id: issueQuantityField
                        width: parent.width
                        height: 40
                        placeholderText: "Enter quantity"
                        validator: IntValidator { bottom: 1; top: issueDialog.currentItem ? (issueDialog.currentItem.quantity - issueDialog.currentItem.quantityBorrowed) : 1 }
                    }
                }

                Text {
                    text: "Available: " + (issueDialog.currentItem ? (issueDialog.currentItem.quantity - issueDialog.currentItem.quantityBorrowed) : "0")
                    font.pixelSize: 14
                    color: "#666666"
                    anchors{
                        right: parent.right
                        // rightMargin:10
                    }
                }
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            if (userNumberField.text.trim() === "" || issueQuantityField.text.trim() === "") {
                return
            }

            if (digitalMaterialsManager) {
                digitalMaterialsManager.issueItem(
                    currentItem.itemID,
                    userNumberField.text.trim(),
                    parseInt(issueQuantityField.text)
                )
            }
        }
    }

    Dialog {
        id: returnDialog
        title: "Return Item"
        width: 400
        height: 400  // Increased height to accommodate user number field
        modal: true

        property var currentItem: null
        property int maxUserQuantity: 0  // Track max quantity user can return

        function openForItem(item) {
            currentItem = item
            returnQuantityField.text = "1"  // Default to 1 instead of total borrowed
            returnUserNumberField.text = ""       // Clear user number field
            maxUserQuantity = 0            // Reset max quantity
            open()
        }

        // Function to check user's borrowed quantity
        function checkUserBorrowedQuantity() {
            if (returnUserNumberField.text.trim() === "" || !currentItem) {
                returnDialog.maxUserQuantity = 0
                userBorrowedInfo.text = ""
                return
            }

            // Call C++ function to get user's borrowed quantity
            if (digitalMaterialsManager) {
                digitalMaterialsManager.getUserBorrowedQuantity(
                    currentItem.itemID,
                    returnUserNumberField.text.trim()
                )
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F5F5"
            radius: 8

            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 10

                Text {
                    text: "Return: " + (returnDialog.currentItem ? returnDialog.currentItem.itemName : "")
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333333"
                }

                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "User Number *"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#333333"
                    }

                    TextField {
                        id: returnUserNumberField
                        width: parent.width
                        height: 40
                        placeholderText: "Enter user number"
                        onTextChanged: {
                            // Add a small delay to avoid too many calls while typing
                            userCheckTimer.restart()
                        }
                    }

                    Timer {
                        id: userCheckTimer
                        interval: 500  // 500ms delay
                        onTriggered: returnDialog.checkUserBorrowedQuantity()
                    }
                }

                Text {
                    id: userBorrowedInfo
                    text: ""  // Will be updated when user is checked
                    font.pixelSize: 12
                    color: returnDialog.maxUserQuantity > 0 ? "#4CAF50" : "#F44336"  // Green if user found, red if not
                    wrapMode: Text.Wrap
                    width: parent.width
                }

                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Return Quantity *"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#333333"
                    }

                    TextField {
                        id: returnQuantityField
                        width: parent.width
                        height: 40
                        placeholderText: "Enter quantity to return"
                        enabled: returnDialog.maxUserQuantity > 0  // Only enable if user has borrowed items
                        validator: IntValidator {
                            bottom: 1
                            top: Math.max(1, returnDialog.maxUserQuantity)  // Use user's max quantity
                        }
                    }
                }

                Text {
                    text: "Total Items Borrowed: " + (returnDialog.currentItem ? returnDialog.currentItem.quantityBorrowed : "0")
                    font.pixelSize: 14
                    color: "#666666"
                    anchors.right: parent.right
                }
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            if (returnUserNumberField.text.trim() === "") {
                // Show error for missing user number
                console.log("User number not found")
                return
            }

            if (returnQuantityField.text.trim() === "") {
                // Show error for missing quantity
                console.log("Invalid quantity")
                return
            }

            if (returnDialog.maxUserQuantity === 0) {
                // Show error that user hasn't borrowed this item
                console.log("User has not borrowed this item")
                return
            }

            if (digitalMaterialsManager) {
                digitalMaterialsManager.returnItem(
                    currentItem.itemID,
                    parseInt(returnQuantityField.text),
                    returnUserNumberField.text.trim()
                )

                console.log(currentItem.itemID,
                            parseInt(returnQuantityField.text),
                            returnUserNumberField.text.trim()
                            )
            }
        }
    }

    // Delete Confirmation Dialog
    Dialog {
        id: deleteConfirmDialog
        title: "Confirm Delete"
        width: 400
        height: 300
        modal: true

        property var currentItem: null

        function openForItem(item) {
            currentItem = item
            open()
        }

        Rectangle {
            anchors.fill: parent
            color: "#F5F5F5"
            clip: true
            radius: 8

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width - 40

                Text {
                    text: "Are you sure you want to delete this item?"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333333"
                    anchors.horizontalCenter: parent.horizontalCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: deleteConfirmDialog.currentItem ? deleteConfirmDialog.currentItem.itemName : ""
                    font.pixelSize: 14
                    color: "#666666"
                    width: parent.width - 8
                    anchors{
                        left: parent.left
                        // leftMargin: 10
                        horizontalCenter: parent.horizontalCenter
                    }

                    // anchors.horizontalCenter: parent.horizontalCenter
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: "This action cannot be undone."
                    font.pixelSize: 12
                    color: "#F44336"
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.italic: true
                }
            }
        }

        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: {
            if (digitalMaterialsManager && currentItem) {
                digitalMaterialsManager.deleteItem(currentItem.itemID)
            }
        }
    }

    // History Dialog
    Dialog {
        id: historyDialog
        title: "Borrowing History"
        width: 800
        height: 600
        modal: true

        Rectangle {
            anchors.fill: parent
            color: "#F5F5F5"

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Header Row for History
                Row {
                    width: parent.width
                    height: 40

                    Rectangle {
                        width: parent.width / 6
                        height: parent.height
                        color: "lightgray"
                        Text {
                            anchors.centerIn: parent
                            text: "Item Name"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                    Rectangle {
                        width: parent.width / 6
                        height: parent.height
                        color: "lightgray"
                        Text {
                            anchors.centerIn: parent
                            text: "User"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                    Rectangle {
                        width: parent.width / 6
                        height: parent.height
                        color: "lightgray"
                        Text {
                            anchors.centerIn: parent
                            text: "Quantity"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                    Rectangle {
                        width: parent.width / 6
                        height: parent.height
                        color: "lightgray"
                        Text {
                            anchors.centerIn: parent
                            text: "Issue Date"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                    Rectangle {
                        width: parent.width / 6
                        height: parent.height
                        color: "lightgray"
                        Text {
                            anchors.centerIn: parent
                            text: "Return Date"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                    Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                    Rectangle {
                        width: parent.width / 6
                        height: parent.height
                        color: "lightgray"
                        Text {
                            anchors.centerIn: parent
                            text: "Status"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }
                }

                // History ListView
                ListView {
                    boundsBehavior: Flickable.StopAtBounds
                    width: parent.width
                    height: parent.height - 50
                    clip: true

                    model: digitalMaterialsManager ? digitalMaterialsManager.historyModel : null

                    ScrollBar.vertical: ScrollBar {
                        id: vbar
                        active: true
                        policy: ScrollBar.AsNeeded
                        width: 6

                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: width / 2
                            color: vbar.pressed ? "#818181" : "#c2c2c2"  // Darker when pressed
                        }
                        background: Rectangle {
                            implicitWidth: 6
                            radius: width / 2
                            color: "#f0f0f0"  // Light background color
                        }
                    }

                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: index % 2 === 0 ? "#FFFFFF" : "#F9F9F9"
                        border.color: "#E0E0E0"
                        border.width: 1

                        Row {
                            width: parent.width
                            height: parent.height

                            Rectangle {
                                width: parent.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    width: parent.width -8
                                    anchors{
                                        left: parent.left
                                        leftMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }

                                    text: model.itemName || ""
                                    font.pixelSize: 12
                                    color: "#333333"
                                    elide:  Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                            Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                            Rectangle {
                                width: parent.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: model.userNumber || ""
                                    font.pixelSize: 12
                                    color: "#333333"
                                }
                            }
                            Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                            Rectangle {
                                width: parent.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: model.quantityBorrowed || ""
                                    font.pixelSize: 12
                                    color: "#333333"
                                }
                            }
                            Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                            Rectangle {
                                width: parent.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: model.issueDate || ""
                                    font.pixelSize: 12
                                    color: "#333333"
                                }
                            }
                            Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                            Rectangle {
                                width: parent.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: model.returnDate || "Not returned"
                                    font.pixelSize: 12
                                    color: "#333333"
                                }
                            }
                            Rectangle { width: 1; height: parent.height; color: "#E0E0E0" }
                            Rectangle {
                                width: parent.width / 6
                                height: parent.height
                                color: "transparent"
                                Rectangle {
                                    width: 60
                                    height: 20
                                    radius: 10
                                    color: model.status === "Returned" ? "#4CAF50" : "#FF9800"
                                    anchors.centerIn: parent
                                    Text {
                                        text: model.status || ""
                                        color: "white"
                                        font.pixelSize: 10
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        standardButtons: Dialog.Close
    }

    // Error Dialog
    Dialog {
        id: errorDialog
        title: "Error!"
        property alias text: errorLabel.text
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: parent

        Text {
            id: errorLabel
            color: "#8E8E8E"
        }
    }

    Connections {
        target: digitalMaterialsManager
        function onUserBorrowedQuantityChecked(userNumber, quantity, message) {
            if (userNumber === userNumberField.text.trim()) {
                returnDialog.maxUserQuantity = quantity
                userBorrowedInfo.text = message

            }
        }
    }

}
