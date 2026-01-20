import QtQuick
import QtQuick.Controls
import "DynamicComponentLoader.js" as ComponentLoader
import com.allbookslistmodel 1.0
import com.categorylist 1.0

Rectangle {
    id: allBooks
    visible: true
    width: parent.width //600
    height: parent.height //400
    color: "#FBFBFB"

    property var addNewBook: null
    property var settingsPage: null

    property int itemsPerPage: 100
    property string category: "all"
    property int totalPages: Math.ceil(allBooksList.getTotalBooksCount / itemsPerPage)
    property int previousPage: 0
    property int currentPage: 1
    property int nextPage: 2

    //categoryList
    property var categoryList: CategoryList{}


    signal closeClicked()

    MouseArea{
        id: allBooksMA
        anchors.fill: parent
    }


    Rectangle{
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors{
            left: parent.left
            leftMargin: 10
            top: parent.top
            topMargin: 10
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
                allBooks.closeClicked()
            }
        }
    }

    Rectangle{
        id: cartegoryContainer
        color: "#FBFBFB" //"#e2dada"
        width: parent.width* .21
        radius: 8
        border.width: 1
        border.color: "#E0E0E0" //"#f0f0f0"
        clip: true
        property int btnWidth: width* .87

        anchors{
            left: parent.left
            top: backRect.bottom
            bottom: parent.bottom
            margins: 10
        }

        Rectangle{
            id: categoriesLabelRect
            height: 40
            width: cartegoryContainer.btnWidth
            anchors{
                top: parent.top
                topMargin: 16
                left: parent.left
                leftMargin: 5
            }

            color: "transparent"
            radius: 4

            Label{
                id: categoriesTxt
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                text: " Categories and Quick Actions"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                elide: "ElideRight"
                maximumLineCount: 1
            }
        }

        ListView{
            id: categoriesListView
            height: parent.height * 0.40
            clip: true

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

            anchors{
                top: categoriesLabelRect.bottom
                left: parent.left
                right: parent.right
                margins: 5
            }

            model: categoryList.getCategories()
            delegate: CustomButton{
                text: modelData
                width: cartegoryContainer.btnWidth
                height: 50

                onClicked: {
                    pageTitle.text = text
                    category = text
                    resetPagination()
                    fetchCurrentPageData()
                }
            }
        }

        Rectangle{
            id: actionsLabelRect
            height:40
            width: cartegoryContainer.btnWidth
            anchors{
                top: categoriesListView.bottom
                topMargin: 16
                left: parent.left
                leftMargin: 5
            }

            color: "transparent"
            radius: 4

            Label{
                id: quickActionsTxt
                width: parent.width
                anchors{
                    left: parent.left
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }

                text: "Quick Actions"
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                elide: "ElideRight"
                maximumLineCount: 1
            }
        }

        //to show up when the height of the window gets too small
        Rectangle {
            id: shortcutsContainer
            width: cartegoryContainer.btnWidth
            height: 32
            enabled: true
            opacity: enabled ? 1 : 0.3
            color: "transparent" //"white" //"#f0f0f0"
            radius: 4
            border.color: "#E0E0E0"
            visible: allBooks.height < 630
            anchors {
                top: actionsLabelRect.bottom
                left:actionsLabelRect.left
                leftMargin: 5
                topMargin: 5
            }

            // Calculate a reasonable size for icons based on container size
            property real iconSize: Math.min(height * 0.64, width / 5)  // Ensure icons don't get too large

            Row {
                anchors {
                    fill: parent
                    // Use percentage-based margins instead of fixed pixels
                    leftMargin: parent.width * 0.05
                    rightMargin: parent.width * 0.05
                    // Center vertically
                    topMargin: (parent.height - height) / 2
                    bottomMargin: (parent.height - height) / 2
                }
                spacing: (width - (shortcutsContainer.iconSize * 4)) / 3

                Image {
                    id: allBooksShortcut
                    source: "assets/allBooksList.png"
                    height: shortcutsContainer.iconSize
                    width: height
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked:{
                            pageTitle.text = "All Books"
                            category = "all"
                            resetPagination()
                            fetchCurrentPageData()
                        }
                    }
                }

                Image {
                    id: addNewBookShortcut
                    source: "assets/addNewBook.png"
                    height: shortcutsContainer.iconSize
                    width: height
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked:{
                            ComponentLoader.customCreateComponent(addNewBook, "AddBooks", mainContainer)
                        }
                    }
                }

                Image {
                    id: advancedSearchShortcut
                    source: "assets/advancedSearch.png"
                    height: shortcutsContainer.iconSize
                    width: height
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                        }
                    }
                }

                Image {
                    id: openSettingsShortcut
                    source: "assets/openSettings.png"
                    height: shortcutsContainer.iconSize
                    width: height
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: "PointingHandCursor"
                        onClicked: {
                            ComponentLoader.customCreateComponent(settingsPage,"Settings/SettingsPage", page2)
                        }
                    }
                }
            }
        }

        CustomButton{
            id: allBooksBtn
            text: qsTr("All Books")
            height: 50
            width: cartegoryContainer.btnWidth
            visible: !shortcutsContainer.visible
            anchors{
                top: actionsLabelRect.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                pageTitle.text = "All Books"
                category = "all"
                resetPagination()
                fetchCurrentPageData()
            }
        }

        CustomButton{
            id: action1Btn
            text: qsTr("Add new book")
            height: 50
            width: cartegoryContainer.btnWidth
            visible: !shortcutsContainer.visible
            anchors{
                top: allBooksBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                ComponentLoader.customCreateComponent(addNewBook, "AddBooks", mainContainer)
            }
        }

        CustomButton{
            id: advancedSearchBtn
            text: qsTr("Advanced Search")
            height: 50
            width: cartegoryContainer.btnWidth
            visible: !shortcutsContainer.visible
            anchors{
                top: action1Btn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{

            }
        }

        CustomButton{
            id: openSettingsBtn
            text: qsTr("Open Settings")
            height: 50
            width: cartegoryContainer.btnWidth
            visible: !shortcutsContainer.visible
            anchors{
                top: advancedSearchBtn.bottom
                left: parent.left
                leftMargin: 5
                topMargin: 5
            }

            onClicked:{
                ComponentLoader.customCreateComponent(settingsPage,"Settings/SettingsPage", page2)
            }
        }
    }


    Rectangle{
        id: pageTitleRect
        height: 40
        width: pageTitle.width
        color: "transparent"
        anchors{
            top: parent.top
            topMargin: 20
            left: cartegoryContainer.right
            leftMargin: 20
        }

        Text{
            id: pageTitle
            text: "All books"
            font.pointSize: 16
            font.bold: true
            color: "#878585"
            anchors{
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }
    }

    Searchbox{
        id: allBooksSearchBox
        width: 300
        height: 30
        border.color: "#E0E0E0"
        placeHolderText: "Search"
        anchors{
            right: parent.right
            rightMargin: 10
            verticalCenter: pageTitleRect.verticalCenter
        }
    }

    ListView {
        id: listView
        clip: true
        anchors{
            top: pageTitleRect.bottom
            topMargin: 10
            left: cartegoryContainer.right
            leftMargin: 20
            bottom: parent.bottom
            right: parent.right
        }

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AlwaysOn
        }

        model: AllBooksListModel{
            list: allBooksList
        }

        delegate: Item {
            width: listView.width
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
                        source: "assets/delegateBook.png"
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

                MouseArea{
                    id: delegateItemMA
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        delegateItemRect.color = "#F5F5F5"
                        deleteIconRect.visible = true
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                        deleteIconRect.visible = false
                    }
                }

                Rectangle{
                    id: deleteIconRect
                    visible: false
                    width: 20
                    height: 20
                    color: "transparent"
                    anchors{
                        right: parent.right
                        rightMargin: 50
                        verticalCenter: parent.verticalCenter
                    }

                    MouseArea{
                        id: deleteIconMA
                        anchors.fill: parent
                        hoverEnabled: true

                        Image{
                            id: deleteIcon
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            source: "assets/deleteClosed.png"
                        }

                        onEntered: {
                            deleteIcon.source = "assets/deleteOpen.png"
                        }

                        onExited: {
                            deleteIcon.source = "assets/deleteClosed.png"
                        }
                        onClicked: {
                            allBooksList.removeBook(model.callNumber)
                        }
                    }
                }
            }

            Rectangle {
                id: separator
                width: delegateItemRect.width* .95
                height: 1
                color: "#E0E0E0"
                anchors{
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
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


    function resetPagination() {
        currentPage = 1
        previousPage = 0
        nextPage = 2
    }

    function fetchCurrentPageData() {
        const offset = currentPage //* itemsPerPage
        //        allUsersList.fetchUsers(currentUserType, offset, itemsPerPage)
        allBooksList.fetchBooks(offset, itemsPerPage, category)
    }



    Component.onCompleted: {
        //        allBooksList.fetchBooks(1, 100)
        category = "all"
        resetPagination()
        fetchCurrentPageData()
        totalPages= Math.ceil(allBooksList.getTotalBooksCount(category)/itemsPerPage)
        console.log(totalPages)
    }
}
