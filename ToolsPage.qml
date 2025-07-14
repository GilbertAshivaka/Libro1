import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Pdf
import QtQuick.Dialogs
import Qt.labs.settings
import QtQuick.Effects
import QtWebEngine
import QtWebView
import QtWebChannel
import "DynamicComponents"
import "DynamicComponentLoader.js" as CustomComponentLoader



Rectangle {
    id: toolsPage
    width: parent.width
    height: parent.width
    color: "#FBFBFB"
    property double calculatedHeight: 0
    property double flowItemHeight: flowItem.calculateFlowHeight()


    // Color scheme from welcome page
    readonly property color lightGrey: "#f8f9fa"
    readonly property color toolbarGrey: "#6c757d"
    readonly property color textGrey: "#343a40"
    readonly property color white: "#ffffff"

    property var reportsPage: null
    property var inventoryTracking: null
    property var backupPage: null
    property var activityLogs: null
    property var bookshopScreen: null
    property var pdfRoot: null
    property var libroAIPage: null
    property var storageManagerScreen: null
    // property var root

    Rectangle{
        id: navSearchBox
        width: parent.width* .85
        radius: 4
        height: 40
        anchors{
            top: parent.top
            topMargin: 30
            horizontalCenter: parent.horizontalCenter
        }

        color: "transparent"
        border.color: "blue"

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
            visible: navigationTextInput.text === ""
            color: "#585757"
            text: "Search for tools..."
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
                id: navigationTextInput
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
                onTextChanged: flowItem.updateVisibility(navigationTextInput.text)
            }
        }
    }


    Flow {
        id: flowItem
        anchors{
            top: navSearchBox.bottom
            topMargin: 30
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        spacing: 10

        function updateVisibility(query) {
            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (item.description) {
                    item.visible = item.description.toLowerCase().indexOf(query.toLowerCase()) !== -1;
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

        ToolsTemplate{
            id: reportsItem
            icon: "assets/reports.png"
            description: "Reports and analytics"
            instruction1: function() {
                CustomComponentLoader.customCreateComponent(reportsPage,"ReportsPage", mainContainer)
            }

//            instruction2:
        }

        ToolsTemplate{
            id: inventoryItem
            icon: "assets/inventory2.png"
            description: "Inventory tracking"
            instruction1: function() {
                CustomComponentLoader.customCreateComponent(inventoryTracking,"InventoryTracking", mainContainer)
            }
//            instruction2:
        }


        ToolsTemplate{
            id: backupItem
            icon: "assets/cloudBackuprestore.png"
            description: "Backup and restore"
            instruction1: function() {
                CustomComponentLoader.customCreateComponent(backupPage,"BackupPage", mainPageContainer)
            }

            instruction2: function() {
                console.log("Instruction 2")
            }
        }


        ToolsTemplate{
            id: loggerItem
            icon: "assets/logging.png"
            description: "Activity logger"
            instruction1: function() {
                CustomComponentLoader.customCreateComponent(activityLogs,"ActivityLogs", mainPageContainer)
            }

            instruction2: function() {
                console.log("Instruction 2")
            }
        }

        ToolsTemplate{
            id: genAI1
            icon: "assets/genAI.png"
            description: "Libro AI"

            instruction1: function(){
                CustomComponentLoader.customCreateComponent(libroAIPage,"LibroAIPage", mainPageContainer)
            }

           instruction2:{
               console.log("Instruction 2")
           }
        }

        ToolsTemplate{
            id: pdfReader
            icon: "assets/pdf.png"
            description: "Ebook reader"
           instruction1: function() {
               // root.show()
               CustomComponentLoader.customCreateComponent(pdfRoot,"PDFReaderScreen", mainPageContainer)
            }

           instruction2:{
               console.log("Instruction 2")
           }
        }


        ToolsTemplate{
            id: digitalMaterial
            icon: "assets/digitalContent.png"
            description: "Digital material"
//            instruction1:
//            instruction2:
        }

        ToolsTemplate{
            id: bookStore
            icon: "assets/bookstore.png"
            description: "Online Bookshops"
           instruction1: function() {
               CustomComponentLoader.customCreateComponent(bookshopScreen,"BookshopScreen", mainPageContainer)
           }
//            instruction2:
        }

        ToolsTemplate{
            id: storageItem
            icon: "assets/storage.png"
            description: "Storage manager"
            instruction1:function(){
                CustomComponentLoader.customCreateComponent(storageManagerScreen,"StorageManager", mainPageContainer)
            }

            //            instruction2:
        }

        ToolsTemplate{
            id: notifications
            icon: "assets/emailNotification.png"
            description: "Send Notifications"
//            instruction1:
//            instruction2:
        }

        ToolsTemplate{
            id: documentation
            icon: "assets/documentation.png"
            description: "Help and documentation"
//            instruction1:
//            instruction2:
        }   
    }
}
