import QtQuick
import QtQuick.Controls
import "DynamicComponentLoader.js" as ComponentLoader
import com.inventoryManager
import QtQuick.Layouts

Rectangle {
    id: inventoryTracking
    visible: true
    width: parent.width
    height: parent.height
    clip: true
    color: "#FBFBFB"

    property var dynamicComponent: null
    // property var mainContainer: null
    property var addBooks: null
    property var importBooks: null



    signal closeClicked()

    MouseArea{
        id: inventoryTrackingMA
        anchors.fill: parent
    }

    InventoryManager{
        id: inventoryManager

        onErrorOccured:(error) =>{
                           errorDialog.text = error
                           errorDialog.open();
                       }

        onOperationCompleted:(successMsg) =>{
                                 errorDialog.title = "Success!"
                                 errorDialog.text = successMsg
                                 errorDialog.open()
                             }
    }

    // Page Title
    Rectangle{
        id: pageTitleRect
        height: 50
        width: parent.width
        color: "white" //"transparent"
        clip: true
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Text{
            id: pageTitle
            text: "Inventory Tracking"
            font.pointSize: 16
            font.bold: true
            color: "#878585"
            anchors{
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
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
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 30
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
                    inventoryTracking.closeClicked()
                }
            }
        }
    }


    ScrollView{
        id: inventorySV
        height: parent.height
        contentHeight: parent.height
        clip: true
        anchors{
            top: pageTitleRect.bottom
            right: parent.right
            left: parent.left
            bottom: parent.bottom
        }


        ScrollBar.vertical: ScrollBar {
            id: vbar
            active: true
            policy: ScrollBar.AlwaysOn
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


        // Main Dashboard Stats Cards
        Rectangle{
            id: dashboardContainer
            width: parent.width * 0.55
            height: 240
            color: "transparent"
            anchors{
                top: parent.top
                topMargin: 20
                left: parent.left
                leftMargin: 20
            }

            // Row 1 - First 3 cards
            Rectangle{
                id: totalBooksCard
                width: (parent.width - 20) / 3
                height: 110
                radius: 8
                color: "#90CAF9" // "#4A90E2"
                border.width: 1
                border.color: "#3A7BC8"
                clip: true
                anchors{
                    top: parent.top
                    left: parent.left
                }

                Text{
                    id: totalBooksNumber
                    text: inventoryManager.getTotalBooksCount() //"3,042"
                    font.pointSize: 18
                    font.bold: true
                    color: "white"
                    anchors{
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 15
                    }
                }

                Text{
                    text: "Total Books"
                    font.pointSize: 10
                    color: "white"
                    anchors{
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                }
            }

            Rectangle{
                id: availableBooksCard
                width: (parent.width - 20) / 3
                height: 110
                radius: 8
                color: "#A4CCA4" //"#7ED321"
                border.width: 1
                border.color: "#6BB91A"
                clip: true
                anchors{
                    top: parent.top
                    left: totalBooksCard.right
                    leftMargin: 10
                }

                Text{
                    text: inventoryManager.getAvailableBooksCount() //"2,893"
                    font.pointSize: 18
                    font.bold: true
                    color: "white"
                    anchors{
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 15
                    }
                }

                Text{
                    text: "Available"
                    font.pointSize: 10
                    color: "white"
                    anchors{
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                }
            }

            Rectangle{
                id: checkedOutCard
                width: (parent.width - 20) / 3
                height: 110
                radius: 8
                color: "#DBE169" //"#F5A623"
                border.width: 1
                border.color: "#E8941B"
                clip: true
                anchors{
                    top: parent.top
                    left: availableBooksCard.right
                    leftMargin: 10
                }

                Text{
                    text: inventoryManager.getCheckedOutBooksCount() //"149"
                    font.pointSize: 18
                    font.bold: true
                    color: "white"
                    anchors{
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                        topMargin: 15
                    }
                }

                Text{
                    text: "Checked Out"
                    font.pointSize: 10
                    color: "white"
                    anchors{
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                }
            }

            // Row 2 - Overdue and Missing with fees
            Rectangle{
                id: overdueCard
                width: (parent.width - 10) / 2
                height: 120
                radius: 8
                color: "#C67171" //"#D0021B"
                border.width: 1
                border.color: "#B8001A"
                clip: true
                anchors{
                    top: totalBooksCard.bottom
                    topMargin: 10
                    left: parent.left
                }

                Text{
                    text: "Overdue"
                    font.pointSize: 16
                    color: "white"
                    anchors{
                        left: parent.left
                        leftMargin: 10
                        top: parent.top
                        topMargin: 10
                    }
                }

                Text{
                    text: inventoryManager.getOverdueBooksCount() //"13"
                    font.pointSize: 18
                    font.bold: true
                    color: "white"
                    anchors.centerIn: parent
                }

                Text{
                    text: "Total Fees: $47.50"
                    font.pointSize: 8
                    color: "#FFE6E6"
                    anchors{
                        right: parent.right
                        rightMargin: 10
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                }
            }

            Rectangle{
                id: missingCard
                width: (parent.width - 10) / 2
                height: 120
                radius: 8
                color: "#B0A0A0" //"#9013FE"
                border.width: 1
                border.color: "#4A4747" //"#7B0FD6"
                clip: true
                anchors{
                    top: totalBooksCard.bottom
                    topMargin: 10
                    left: overdueCard.right
                    leftMargin: 10
                }

                Text{
                    text: "Missing"
                    font.pointSize: 16
                    color: "white"
                    anchors{
                        left: parent.left
                        leftMargin: 10
                        top: parent.top
                        topMargin: 10
                    }
                }

                Text{
                    text: inventoryManager.getMissingBooksCount() //"3"
                    font.pointSize: 18
                    font.bold: true
                    color: "white"
                    anchors.centerIn: parent
                }

                Text{
                    text: "Replacement: $156.43"
                    font.pointSize: 8
                    color: "#F3E5F5"
                    anchors{
                        right: parent.right
                        rightMargin: 10
                        bottom: parent.bottom
                        bottomMargin: 10
                    }
                }
            }
        }

        // Book Management Section
        Rectangle{
            id: bookManagementContainer
            width: parent.width * 0.4
            height: 240
            color: "transparent"
            radius: 8
            border.width: 1
            border.color: "#E0E0E0"
            clip: true
            anchors{
                top: parent.top
                topMargin: 20
                right: parent.right
                rightMargin: 20
            }

            Text{
                id: bookManagementTitle
                text: "Book Management"
                font.pointSize: 14
                font.bold: true
                color: "#878585"
                anchors{
                    top: parent.top
                    topMargin: 15
                    left: parent.left
                    leftMargin: 15
                }
            }

            CustomButton{
                id: addBookBtn
                text: "Add Book"
                width: (parent.width - 45) / 2
                height: 50
                anchors{
                    top: bookManagementTitle.bottom
                    topMargin: 15
                    left: parent.left
                    leftMargin: 15
                }
                onClicked: {
                    ComponentLoader.customCreateComponent(addBooks, "AddBooks", mainPageContainer)
                }
            }

            CustomButton{
                id: importBooksBtn
                text: "Import Books"
                width: (parent.width - 45) / 2
                height: 50
                anchors{
                    top: bookManagementTitle.bottom
                    topMargin: 15
                    right: parent.right
                    rightMargin: 15
                }
                onClicked: {
                    ComponentLoader.customCreateComponent(importBooks, "ImportBooks", mainPageContainer)
                }
            }

            CustomButton{
                id: editBookBtn
                text: "Edit Book"
                width: (parent.width - 45) / 2
                height: 50
                anchors{
                    top: addBookBtn.bottom
                    topMargin: 10
                    left: parent.left
                    leftMargin: 15
                }
                onClicked: {
                    // Edit book functionality
                }
            }

            CustomButton{
                id: deleteBtn
                text: "Delete"
                width: (parent.width - 45) / 2
                height: 50
                anchors{
                    top: importBooksBtn.bottom
                    topMargin: 10
                    right: parent.right
                    rightMargin: 15
                }
                onClicked: {
                    bookNumberPopup.caller = "delete"
                    bookNumberPopup.open()
                }
            }

            CustomButton{
                id: archiveBtn
                text: "Archive"
                width: parent.width - 30
                height: 50
                anchors{
                    top: editBookBtn.bottom
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    // Archive functionality
                    bookNumberPopup.caller = "archive"
                    bookNumberPopup.open()
                }
            }
        }

        // Inventory Reports Section
        Rectangle{
            id: inventoryReportsContainer
            width: parent.width * 0.20
            height: 300
            color: "transparent"
            radius: 8
            border.width: 1
            border.color: "#E0E0E0"
            clip: true
            anchors{
                top: dashboardContainer.bottom
                topMargin: 20
                left: parent.left
                leftMargin: 20
            }

            Text{
                id: reportsTitle
                text: "Inventory Reports"
                font.pointSize: 14
                font.bold: true
                color: "#878585"
                anchors{
                    top: parent.top
                    topMargin: 15
                    left: parent.left
                    leftMargin: 15
                }
            }

            CustomButton{
                id: getCountBtn
                text: "Get Count"
                width: parent.width - 30
                height: 50
                anchors{
                    top: reportsTitle.bottom
                    topMargin: 15
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    categoryMenu.open()
                }

                Menu{
                    id: categoryMenu
                    x: getCountBtn.width
                    y: getCountBtn.y

                    MenuItem{
                        id: title
                        text: "Title"
                        onTriggered: {
                            categoryInputDialog.caller = "title"
                            categoryInputDialog.open()
                        }
                    }

                    MenuItem{
                        id: author
                        text: "Author"
                        onTriggered: {
                            categoryInputDialog.caller = "author"
                            categoryInputDialog.open()
                        }
                    }

                    MenuItem{
                        id: subject
                        text: "Subject"
                        onTriggered: {
                            categoryInputDialog.caller = "subject"
                            categoryInputDialog.open()
                        }
                    }

                    MenuItem{
                        id: genre
                        text: "Genre"
                        onTriggered:{
                            categoryInputDialog.caller = "genre"
                            categoryInputDialog.open()
                        }
                    }

                    MenuItem{
                        id: publisher
                        text: "Publisher"
                        onTriggered: {
                            categoryInputDialog.caller = "publisher"
                            categoryInputDialog.open()
                        }
                    }
                }
            }

            CustomButton{
                id: recentAcquisitionsBtn
                text: "Recent Acquisitions"
                width: parent.width - 30
                height: 50
                anchors{
                    top: getCountBtn.bottom
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    fromDateInputDialog.open()
                    fromDateTextInput.focus = true
                }
            }

            CustomButton{
                id: itemsNeedingAttentionBtn
                text: "Items Needing Attention"
                width: parent.width - 30
                height: 50
                anchors{
                    top: recentAcquisitionsBtn.bottom
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    inventoryManager.getItemsNeedingAttention()
                    dynamicContentLoader.state = "attentionItems"
                }
            }

            CustomButton{
                id: underMaintenanceBtn
                text: "Under Maintenance"
                width: parent.width - 30
                height: 50
                anchors{
                    top: itemsNeedingAttentionBtn.bottom
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    inventoryManager.getBooksUnderMaintenance()
                    dynamicContentLoader.state = "underMaintenance"
                }
            }
        }

        // Physical Tracking Section
        Rectangle{
            id: physicalTrackingContainer
            width: parent.width * 0.20
            height: 200
            color: "transparent"
            radius: 8
            border.width: 1
            border.color: "#E0E0E0"
            clip: true
            anchors{
                top: dashboardContainer.bottom
                topMargin: 20
                left: inventoryReportsContainer.right
                leftMargin: 20
            }

            Text{
                id: physicalTrackingTitle
                text: "Physical Tracking"
                font.pointSize: 14
                font.bold: true
                color: "#878585"
                anchors{
                    top: parent.top
                    topMargin: 15
                    left: parent.left
                    leftMargin: 15
                }
            }

            CustomButton{
                id: shelfSegmentBtn
                text: "Segment by Shelf"
                width: parent.width - 30
                height: 50
                anchors{
                    top: physicalTrackingTitle.bottom
                    topMargin: 15
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    inventoryManager.getBooksByShelf()
                    dynamicContentLoader.state = "shelfList"
                }
            }

            CustomButton{
                id: numberOfCopiesBtn
                text: "Number of copies"
                width: parent.width - 30
                height: 50
                anchors{
                    top: shelfSegmentBtn.bottom
                    topMargin: 15
                    horizontalCenter: parent.horizontalCenter
                }
                onClicked: {
                    inventoryManager.getNumberOfCopies()
                    dynamicContentLoader.state = "copies"
                }
            }
        }

        // Dynamic Component Area
        Rectangle{
            id: dynamicArea
            color: "#FFFFFF"
            radius: 8
            border.width: 1
            border.color: "#E0E0E0"
            clip: true
            anchors{
                top: dashboardContainer.bottom
                topMargin: 20
                left: physicalTrackingContainer.right
                leftMargin: 20
                right: parent.right
                rightMargin: 20
                bottom: parent.bottom
                bottomMargin: 20
            }

            // Dynamic content loader
            Rectangle {
                id: dynamicContentLoader
                anchors {
                    fill: parent
                    margins: 15
                }
                color: "transparent"

                // Placeholder text when no list is selected
                Text {
                    id: placeholderText
                    text: "Select an option to view details"
                    font.pointSize: 12
                    color: "#CCCCCC"
                    anchors.centerIn: parent
                    visible: dynamicContentLoader.state === ""
                }

                // Error text for failed data loading
                Text {
                    id: errorText
                    text: "Failed to load data"
                    font.pointSize: 12
                    color: "#dc3545"
                    anchors.centerIn: parent
                    visible: false
                }

                // Recent Books ListView
                ListView {
                    id: recentBooksListView
                    anchors.fill: parent
                    visible: false
                    model: inventoryManager.recentAcquisitions
                    spacing: 8
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: recentBooksVbar
                        active: true
                        policy: ScrollBar.AlwaysOn
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
                        width: recentBooksListView.width
                        height: 50 //delegateContent.height + 20
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        radius: 6

                        RowLayout {
                            id: delegateContent
                            // anchors.fill: parent
                            // anchors.margins: 10
                            height: parent.height
                            width: parent.width
                            spacing: 15

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: "#28a745"
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "📚"
                                    font.family: "Segoe UI Emoji"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: modelData.title || "Unknown"
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Added: " + (modelData.dateAdded || "Unknown")
                                    font.pixelSize: 11
                                    color: "#868e96"
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // Category Count ListView
                ListView {
                    id: categoryCountListView
                    anchors.fill: parent
                    visible: false
                    model: inventoryManager.categoryCount
                    spacing: 8
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: categoryVbar
                        active: true
                        policy: ScrollBar.AlwaysOn
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
                        width: categoryCountListView.width
                        height: 50 //delegateContent1.height + 20
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        radius: 6

                        RowLayout {
                            id: delegateContent1
                            // anchors.fill: parent
                            // anchors.margins: 10
                            height: parent.height
                            width: parent.width
                            spacing: 15

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: "#ffc107"
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "⭐"
                                    font.family: "Segoe UI Emoji"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: "Category: " + (modelData.category || "Unknown")
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Count: " + (modelData.count || "0")
                                    font.pixelSize: 11
                                    color: "#868e96"
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // Attention Items ListView
                ListView {
                    id: attentionItemsListView
                    anchors.fill: parent
                    visible: false
                    model: inventoryManager.attentionItems
                    spacing: 8
                    clip: true
                    delegate: Rectangle {
                        width: attentionItemsListView.width
                        height: delegateContent2.height + 20
                        color: "#fff3f3"
                        border.color: "#dc3545"
                        border.width: 1
                        radius: 6

                        RowLayout {
                            id: delegateContent2
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 15

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: "#dc3545"
                                Text {
                                    anchors.centerIn: parent
                                    text: "⚠️"
                                    font.family: "Segoe UI Emoji"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: modelData.title || "Unknown"
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Condition: " + (modelData.condition || "Unknown")
                                    font.pixelSize: 11
                                    color: "#dc3545"
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // Under Maintenance ListView
                ListView {
                    id: underMaintenanceListView
                    anchors.fill: parent
                    visible: false
                    model: inventoryManager.underMaintenance
                    spacing: 8
                    clip: true
                    delegate: Rectangle {
                        width: underMaintenanceListView.width
                        height: delegateContent3.height + 20
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        radius: 6

                        RowLayout {
                            id: delegateContent3
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 15

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: "#6c757d"
                                Text {
                                    anchors.centerIn: parent
                                    text: "🛠️"
                                    font.family: "Segoe UI Emoji"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: modelData.title || "Unknown"
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Call Number: " + (modelData.callNumber || "Unknown")
                                    font.pixelSize: 11
                                    color: "#868e96"
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // Shelf List ListView
                ListView {
                    id: shelfListListView
                    anchors.fill: parent
                    visible: false
                    model: inventoryManager.shelfList
                    spacing: 8
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        id: shelfVbar
                        active: true
                        policy: ScrollBar.AlwaysOn
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
                        width: shelfListListView.width
                        height: 50
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        radius: 6

                        Item {
                            id: delegateContent4
                            // anchors.fill: parent
                            // anchors.margins: 10
                            height: parent.height
                            width: parent.width

                            // Icon circle
                            Rectangle {
                                id: iconCircle
                                width: 40
                                height: 40
                                radius: 20
                                color: "#17a2b8"
                                anchors{
                                    left: parent.left
                                    leftMargin: 4
                                    verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "🗄️"
                                    font.family: "Segoe UI Emoji"
                                    font.pixelSize: 16
                                }
                            }

                            // Text content
                            Rectangle {
                                id: shelfTextRect
                                anchors{
                                    left: iconCircle.right
                                    leftMargin: 16
                                    verticalCenter: parent.verticalCenter
                                    right: parent.right
                                }

                                Text {
                                    id: shelfText
                                    text: "Shelf: " + (modelData.shelfNumber || "Unknown")
                                    font.pixelSize: 14
                                    color: "#333"
                                    anchors{
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    text: "Count: " + (modelData.count || "0")
                                    font.pixelSize: 14 //11
                                    color: "#333" //"#868e96"
                                    anchors{
                                        left: shelfText.right
                                        leftMargin: 20
                                        verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // Copies ListView
                ListView {
                    id: copiesListView
                    anchors.fill: parent
                    visible: false
                    model: inventoryManager.copies
                    spacing: 8
                    clip: true
                    delegate: Rectangle {
                        width: copiesListView.width
                        height: delegateContent5.height + 20
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        radius: 6

                        RowLayout {
                            id: delegateContent5
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 15

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: "#007bff"
                                Text {
                                    anchors.centerIn: parent
                                    text: "📚"
                                    font.family: "Segoe UI Emoji"
                                    font.pixelSize: 16
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: modelData.title || "Unknown"
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Copies: " + (modelData.copies || "0")
                                    font.pixelSize: 11
                                    color: "#868e96"
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // States to control visibility
                states: [
                    State {
                        name: "recentBooks"
                        PropertyChanges { target: recentBooksListView; visible: true }
                        PropertyChanges { target: categoryCountListView; visible: false }
                        PropertyChanges { target: attentionItemsListView; visible: false }
                        PropertyChanges { target: underMaintenanceListView; visible: false }
                        PropertyChanges { target: shelfListListView; visible: false }
                        PropertyChanges { target: copiesListView; visible: false }
                        PropertyChanges { target: errorText; visible: recentBooksListView.count === 0 }
                    },
                    State {
                        name: "getCategoryCount"
                        PropertyChanges { target: recentBooksListView; visible: false }
                        PropertyChanges { target: categoryCountListView; visible: true }
                        PropertyChanges { target: attentionItemsListView; visible: false }
                        PropertyChanges { target: underMaintenanceListView; visible: false }
                        PropertyChanges { target: shelfListListView; visible: false }
                        PropertyChanges { target: copiesListView; visible: false }
                        PropertyChanges { target: errorText; visible: categoryCountListView.count === 0 }
                    },
                    State {
                        name: "attentionItems"
                        PropertyChanges { target: recentBooksListView; visible: false }
                        PropertyChanges { target: categoryCountListView; visible: false }
                        PropertyChanges { target: attentionItemsListView; visible: true }
                        PropertyChanges { target: underMaintenanceListView; visible: false }
                        PropertyChanges { target: shelfListListView; visible: false }
                        PropertyChanges { target: copiesListView; visible: false }
                        PropertyChanges { target: errorText; visible: attentionItemsListView.count === 0 }
                    },
                    State {
                        name: "underMaintenance"
                        PropertyChanges { target: recentBooksListView; visible: false }
                        PropertyChanges { target: categoryCountListView; visible: false }
                        PropertyChanges { target: attentionItemsListView; visible: false }
                        PropertyChanges { target: underMaintenanceListView; visible: true }
                        PropertyChanges { target: shelfListListView; visible: false }
                        PropertyChanges { target: copiesListView; visible: false }
                        PropertyChanges { target: errorText; visible: underMaintenanceListView.count === 0 }
                    },
                    State {
                        name: "shelfList"
                        PropertyChanges { target: recentBooksListView; visible: false }
                        PropertyChanges { target: categoryCountListView; visible: false }
                        PropertyChanges { target: attentionItemsListView; visible: false }
                        PropertyChanges { target: underMaintenanceListView; visible: false }
                        PropertyChanges { target: shelfListListView; visible: true }
                        PropertyChanges { target: copiesListView; visible: false }
                        PropertyChanges { target: errorText; visible: shelfListListView.count === 0 }
                    },
                    State {
                        name: "copies"
                        PropertyChanges { target: recentBooksListView; visible: false }
                        PropertyChanges { target: categoryCountListView; visible: false }
                        PropertyChanges { target: attentionItemsListView; visible: false }
                        PropertyChanges { target: underMaintenanceListView; visible: false }
                        PropertyChanges { target: shelfListListView; visible: false }
                        PropertyChanges { target: copiesListView; visible: true }
                        PropertyChanges { target: errorText; visible: copiesListView.count === 0 }
                    }
                ]

                // Bind state
                state: ""

                // Handle errors from InventoryManager
                Connections {
                    target: inventoryManager
                    function onErrorOccured(error) {
                        errorText.text = error
                        errorText.visible = true
                    }
                }
            }
        }

        function loadDynamicComponent(componentName) {
            // Hide all components first
            getCountComponent.visible = false
            shelfSegmentComponent.visible = false

            // Show the requested component
            dynamicContentLoader.visible = true

            switch(componentName) {
            case "GetCount":
                getCountComponent.visible = true
                break
            case "ShelfSegment":
                shelfSegmentComponent.visible = true
                break
            case "RecentAcquisitions":
                // Add implementation later
                break
            case "ItemsNeedingAttention":
                // Add implementation later
                break
            case "UnderMaintenance":
                // Add implementation later
                break
            default:
                dynamicContentLoader.visible = false
                break
            }
        }
    }

    Popup {
        id: bookNumberPopup
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

        property string caller: ""

        Rectangle{
            id: returnBookNumberRect
            width: parent.width
            height: parent.height
            anchors.centerIn: parent

            Text {
                id: inputMsg
                anchors{
                    left: parent.left
                    leftMargin: 20
                    top: parent.top
                    topMargin: 20
                }
                text: qsTr("Please enter the book number")
                elide: Text.ElideRight
                font.pointSize: 12
            }

            CustomTextField{
                id: bookNumberTxtField
                width: parent.width* .8
                anchors.centerIn: parent
                placeholderText: "Book number"
            }

            CustomButton{
                id: continueBtn
                text: "Continue"
                anchors{
                    right: parent.right
                    rightMargin: 20
                    bottom: parent.bottom
                    bottomMargin: 20
                }
                hoveredColor: "#399ED9"
                defaultColor: "#E0E0E0"

                onClicked: {
                    confirmDeleteDialog.open()

                    if (bookNumberTxtField.text.trim() === ""){
                        return
                    }

                    switch(bookNumberPopup.caller){
                    case "delete":
                        confirmDeleteDialog.text = "Are you sure you want to delete book: " +bookNumberTxtField.text + "?"
                        confirmDeleteDialog.open()
                        break
                    case "archive":
                        confirmDeleteDialog.text = "Are you sure you want to archive book: " +bookNumberTxtField.text + "?"
                        confirmDeleteDialog.open()
                        break
                    default:
                        errorDialog.text = "Unknown caller"
                        errorDialog.open()
                        break
                    }
                }
            }
        }

        Rectangle {
            id: bookNumberPopupCloseRect
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
                id: bookNumberPopupCloseImageRect
                width: 15
                height: 15
                radius: 4
                anchors.centerIn: parent
                color: "transparent"

                Image {
                    id: bookNumberPopupClose
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "assets/close.png"
                }
            }

            MouseArea {
                id: bookNumberPopupMA
                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    bookNumberPopupCloseRect.color = "#CB0707"
                }
                onExited: {
                    bookNumberPopupCloseRect.color = "#EE4E4E"
                }

                onClicked: {
                    bookNumberPopup.close()
                }
            }
        }
    }


    Dialog {
        id: confirmDeleteDialog
        title: "Confirm"
        property alias text: confirmLabel.text
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        anchors.centerIn: parent

        Text {
            id: confirmLabel
            color: "#8E8E8E"
            text: "Are you sure you want to delete book: " +bookNumberTxtField.text + "?"
        }

        onAccepted:{
            switch(bookNumberPopup.caller){
            case "delete":
                //call the function to delete
                break
            case "archive":
                //call the function to archive
                break
            default:

                break
            }
        }
        onRejected: {
            close()
        }
    }

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

    Dialog{
        id: categoryInputDialog
        property string caller: ""
        width: categoryTextInput.placeholderText.width +80
        title: "Get category count"
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel | Dialog.Ok

        CustomTextField{
            id: categoryTextInput
            width: parent.width* .8
            anchors.centerIn: parent
            placeholderText: "Specify " + categoryInputDialog.caller + " to search"
        }

        onAccepted: {
            if (categoryTextInput.text.trim() === ""){
                errorDialog.text = "The category search term cannot be empty."
                errorDialog.open()
            }else {
                inventoryManager.getCountByCategory(categoryInputDialog.caller, categoryTextInput.text.trim())
                dynamicContentLoader.state = "getCategoryCount"
            }
        }
    }

    Dialog{
        id: fromDateInputDialog
        property string caller: ""
        title: "From Date:"
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel | Dialog.Ok

        CustomTextField{
            id: fromDateTextInput
            width: parent.width* .8
            anchors.centerIn: parent
            placeholderText: "yyyy-MM-dd"
        }

        onAccepted: {
            if (fromDateTextInput.text.trim() === ""){
                errorDialog.text = "The date cannot be empty."
                errorDialog.open()
            }else {
                var selectedDate = Date.fromLocaleString(Qt.locale(), fromDateTextInput.text.trim(), "yyyy-MM-dd")
                inventoryManager.updateRecentAcquisitions(selectedDate) //fromDateTextInput.text.trim()

                dynamicContentLoader.state = "recentBooks"
            }
        }
    }

    Component.onCompleted:{
        var selectedDate = Date.fromLocaleString(Qt.locale(), "2024-11-01", "yyyy-MM-dd")
        inventoryManager.getRecentAcquisitions(selectedDate)
    }
}


        //#90CAF9 light sky blue
        //straw gold #DBE169
        //uranian blue #C2E8FF
        //Carnation pink #FFADC8
        //colombian blue #CDEEFC

