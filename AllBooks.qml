import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DynamicComponentLoader.js" as ComponentLoader
import com.allbookslistmodel 1.0
import com.categorylist 1.0
import com.libro.settings 1.0

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

    // Search state properties
    property bool isSearchActive: false
    property int searchResultCount: 0

    // Book details dialog properties
    property string selectedTitle: ""
    property string selectedAuthor: ""
    property string selectedCallNumber: ""
    property string selectedPublisher: ""
    property string selectedIsbn: ""
    property string selectedBarcode: ""
    property string selectedYearPublished: ""
    property string selectedShelfNumber: ""
    property string selectedDescription: ""
    property string selectedLanguage: ""
    property string selectedSubject: ""
    property string selectedGenre: ""
    property int selectedValue: 0
    property string selectedMethod: ""
    property string selectedDateAdded: ""
    property string selectedAvailability: ""
    property int selectedTimesBorrowed: 0
    property string selectedCondition: ""

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
                            advancedSearchDialog.open()
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
                advancedSearchDialog.open()
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

    // Searchbox{
    //     id: allBooksSearchBox
    //     width: 300
    //     height: 30
    //     border.color: "#E0E0E0"
    //     placeHolderText: "Search title, author, call number, ISBN, publisher..."
    //     anchors{
    //         right: clearSearchBtn.visible ? clearSearchBtn.left : parent.right
    //         rightMargin: 10
    //         verticalCenter: pageTitleRect.verticalCenter
    //     }

    //     onTextChanged: function(text) {
    //         searchDebounceTimer.restart()
    //     }
    // }

    Rectangle{
        id: allBooksSearchBox
        width: allBooks.width < 680 ? 400* (parent.width/1080) : 400
        height: 40
        radius: 4
        color: "transparent"
        border.color: "#E0E0E0"
        visible: allBooks.width > 325
        anchors{
            right: clearSearchBtn.visible ? clearSearchBtn.left : parent.right
            rightMargin: 10
            verticalCenter: pageTitleRect.verticalCenter
        }

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

            MouseArea{
                id: searchMA
                anchors.fill: parent
                cursorShape: "PointingHandCursor"
                enabled: navigationTextInput.text !== ""
                onClicked: {

                }
            }
        }

        Text{
            id: searchBoxPlaceHolder
            visible: navigationTextInput.text === ""
            color: "#585757"
            text: "Search title, author, call number, ISBN, publisher..."
            anchors{
                left: searchIcon.right
                verticalCenter: parent.verticalCenter
                leftMargin: 20
            }
            elide: Text.ElideRight
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
                }

                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 11

                // Real-time search as user types
                onTextChanged: function(text) {
                    searchDebounceTimer.restart()
                }
            }

            // Debounce timer for search
            Timer {
                id: searchDebounceTimer
                interval: 400
                repeat: false
                onTriggered: {
                    if (navigationTextInput.text.trim().length > 0) {
                        allBooksList.searchBooks(navigationTextInput.text.trim())
                        isSearchActive = true
                    } else {
                        isSearchActive = false
                        resetPagination()
                        fetchCurrentPageData()
                    }
                }
            }
        }
    }

    // Clear search button
    Rectangle {
        id: clearSearchBtn
        width: 80
        height: 30
        radius: 4
        color: clearSearchMA.containsMouse ? "#E74C3C" : "#C0392B"
        visible: isSearchActive
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: pageTitleRect.verticalCenter
        }

        Text {
            text: "Clear"
            color: "white"
            font.pixelSize: 12
            font.bold: true
            anchors.centerIn: parent
        }

        MouseArea {
            id: clearSearchMA
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                navigationTextInput.text = ""
                isSearchActive = false
                searchResultCount = 0
                resetPagination()
                fetchCurrentPageData()
            }
        }
    }

    // Search result count display
    Rectangle {
        id: searchResultsLabel
        width: resultsText.width + 20
        height: 24
        radius: 4
        color: "#3498DB"
        visible: isSearchActive && searchResultCount > 0
        anchors {
            left: pageTitleRect.right
            leftMargin: 15
            verticalCenter: pageTitleRect.verticalCenter
        }

        Text {
            id: resultsText
            text: searchResultCount + " result" + (searchResultCount !== 1 ? "s" : "") + " found"
            color: "white"
            font.pixelSize: 11
            font.bold: true
            anchors.centerIn: parent
        }
    }

    // Connection for search results
    Connections {
        target: allBooksList
        function onSearchCompleted(resultCount) {
            searchResultCount = resultCount
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
                    // cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        delegateItemRect.color = "#F5F5F5"
                        deleteIconRect.visible = true
                    }

                    onExited: {
                        delegateItemRect.color = "transparent"
                        deleteIconRect.visible = false
                    }

                    onClicked: {
                        // Populate dialog with book data
                        selectedTitle = model.title
                        selectedAuthor = model.author
                        selectedCallNumber = model.callNumber
                        selectedPublisher = model.publisher
                        selectedIsbn = model.isbn
                        selectedBarcode = model.barcode
                        selectedYearPublished = model.yearPublished
                        selectedShelfNumber = model.shelfNumber
                        selectedDescription = model.description
                        selectedLanguage = model.language
                        selectedSubject = model.subject
                        selectedGenre = model.genre
                        selectedValue = model.value
                        selectedMethod = model.method
                        selectedDateAdded = model.dateAdded
                        selectedAvailability = model.availability
                        selectedTimesBorrowed = model.timesBorrowed
                        selectedCondition = model.condition
                        bookDetailsDialog.open()
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

    // =====================================================
    // ADVANCED SEARCH DIALOG
    // =====================================================
    Dialog {
        id: advancedSearchDialog
        title: "Advanced Book Search"
        modal: true
        width: Math.min(700, allBooks.width * 0.85)
        height: Math.min(650, allBooks.height * 0.9)
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        // Load dropdown data when opened
        onOpened: {
            subjectCombo.model = allBooksList.getDistinctSubjects()
            genreCombo.model = allBooksList.getDistinctGenres()
            languageCombo.model = allBooksList.getDistinctLanguages()
            availabilityCombo.model = allBooksList.getDistinctAvailability()
            conditionCombo.model = allBooksList.getDistinctConditions()
            methodCombo.model = allBooksList.getDistinctMethods()
        }

        // background: Rectangle {
        //     color: "#FFFFFF"
        //     radius: 12
        //     border.color: "#E0E0E0"
        //     border.width: 1

        //     // Shadow effect
        //     layer.enabled: true
        //     layer.effect: Item {
        //         Rectangle {
        //             anchors.fill: parent
        //             anchors.margins: -8
        //             color: "#20000000"
        //             radius: 16
        //             z: -1
        //         }
        //     }
        // }

        header: Rectangle {
            width: parent.width
            height: 60
            color: "#2C3E50"
            radius: 12

            // Fix bottom corners
            Rectangle {
                width: parent.width
                height: 12
                color: "#2C3E50"
                anchors.bottom: parent.bottom
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                Image {
                    source: "assets/advancedSearch.png"
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: "Advanced Book Search"
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Close button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeDialogMA.containsMouse ? "#E74C3C" : "transparent"
                anchors {
                    right: parent.right
                    rightMargin: 15
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "✕"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: closeDialogMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: advancedSearchDialog.close()
                }
            }
        }

        contentItem: ScrollView {
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: advancedSearchDialog.width - 40
                spacing: 16
                padding: 20

                // Search info text
                Text {
                    text: "Fill in one or more fields below. Results will match ANY of the criteria (OR search)."
                    font.pixelSize: 12
                    color: "#7F8C8D"
                    wrapMode: Text.WordWrap
                    width: parent.width - 40
                }

                // === TEXT SEARCH FIELDS ===
                Rectangle {
                    width: parent.width - 40
                    height: textFieldsColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"

                    Column {
                        id: textFieldsColumn
                        width: parent.width - 30
                        spacing: 12
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Text Search Fields"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        // Row 1: Title and Author
                        Row {
                            width: parent.width
                            spacing: 15

                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 4

                                Text { text: "Title"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advTitleField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "Enter title..."
                                    font.pixelSize: 12
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advTitleField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advTitleField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }

                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 4

                                Text { text: "Author"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advAuthorField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "Enter author..."
                                    font.pixelSize: 12
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advAuthorField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advAuthorField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }
                        }

                        // Row 2: Call Number and ISBN
                        Row {
                            width: parent.width
                            spacing: 15

                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 4

                                Text { text: "Call Number"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advCallNumberField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "Enter call number..."
                                    font.pixelSize: 12
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advCallNumberField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advCallNumberField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }

                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 4

                                Text { text: "ISBN"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advIsbnField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "Enter ISBN..."
                                    font.pixelSize: 12
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advIsbnField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advIsbnField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }
                        }

                        // Row 3: Publisher and Shelf Number
                        Row {
                            width: parent.width
                            spacing: 15

                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 4

                                Text { text: "Publisher"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advPublisherField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "Enter publisher..."
                                    font.pixelSize: 12
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advPublisherField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advPublisherField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }

                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 4

                                Text { text: "Shelf Number"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advShelfNumberField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "Enter shelf number..."
                                    font.pixelSize: 12
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advShelfNumberField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advShelfNumberField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }
                        }
                    }
                }

                // === YEAR RANGE ===
                Rectangle {
                    width: parent.width - 40
                    height: yearRangeColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"

                    Column {
                        id: yearRangeColumn
                        width: parent.width - 30
                        spacing: 12
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Year Published Range"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        Row {
                            width: parent.width
                            spacing: 15

                            Column {
                                width: (parent.width - 30) / 2
                                spacing: 4

                                Text { text: "From Year"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advYearFromField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "e.g., 1990"
                                    font.pixelSize: 12
                                    validator: IntValidator { bottom: 1000; top: 9999 }
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advYearFromField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advYearFromField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }

                            Text {
                                text: "—"
                                font.pixelSize: 16
                                color: "#7F8C8D"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: (parent.width - 30) / 2
                                spacing: 4

                                Text { text: "To Year"; font.pixelSize: 11; color: "#5D6D7E" }
                                TextField {
                                    id: advYearToField
                                    width: parent.width
                                    height: 36
                                    placeholderText: "e.g., 2024"
                                    font.pixelSize: 12
                                    validator: IntValidator { bottom: 1000; top: 9999 }
                                    // background: Rectangle {
                                    //     color: "white"
                                    //     border.color: advYearToField.focus ? "#3498DB" : "#DEE2E6"
                                    //     border.width: advYearToField.focus ? 2 : 1
                                    //     radius: 4
                                    // }
                                }
                            }
                        }
                    }
                }

                // === DROPDOWN FILTERS ===
                Rectangle {
                    width: parent.width - 40
                    height: dropdownColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"

                    Column {
                        id: dropdownColumn
                        width: parent.width - 30
                        spacing: 12
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Category Filters"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        // Row 1: Subject, Genre, Language
                        Row {
                            width: parent.width
                            spacing: 10

                            Column {
                                width: (parent.width - 20) / 3
                                spacing: 4

                                Text { text: "Subject"; font.pixelSize: 11; color: "#5D6D7E" }
                                ComboBox {
                                    id: subjectCombo
                                    width: parent.width
                                    height: 36
                                    font.pixelSize: 12
                                    model: ["All"]
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#DEE2E6"
                                        radius: 4
                                    }
                                }
                            }

                            Column {
                                width: (parent.width - 20) / 3
                                spacing: 4

                                Text { text: "Genre"; font.pixelSize: 11; color: "#5D6D7E" }
                                ComboBox {
                                    id: genreCombo
                                    width: parent.width
                                    height: 36
                                    font.pixelSize: 12
                                    model: ["All"]
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#DEE2E6"
                                        radius: 4
                                    }
                                }
                            }

                            Column {
                                width: (parent.width - 20) / 3
                                spacing: 4

                                Text { text: "Language"; font.pixelSize: 11; color: "#5D6D7E" }
                                ComboBox {
                                    id: languageCombo
                                    width: parent.width
                                    height: 36
                                    font.pixelSize: 12
                                    model: ["All"]
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#DEE2E6"
                                        radius: 4
                                    }
                                }
                            }
                        }

                        // Row 2: Availability, Condition, Method
                        Row {
                            width: parent.width
                            spacing: 10

                            Column {
                                width: (parent.width - 20) / 3
                                spacing: 4

                                Text { text: "Availability"; font.pixelSize: 11; color: "#5D6D7E" }
                                ComboBox {
                                    id: availabilityCombo
                                    width: parent.width
                                    height: 36
                                    font.pixelSize: 12
                                    model: ["All"]
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#DEE2E6"
                                        radius: 4
                                    }
                                }
                            }

                            Column {
                                width: (parent.width - 20) / 3
                                spacing: 4

                                Text { text: "Condition"; font.pixelSize: 11; color: "#5D6D7E" }
                                ComboBox {
                                    id: conditionCombo
                                    width: parent.width
                                    height: 36
                                    font.pixelSize: 12
                                    model: ["All"]
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#DEE2E6"
                                        radius: 4
                                    }
                                }
                            }

                            Column {
                                width: (parent.width - 20) / 3
                                spacing: 4

                                Text { text: "Acquisition Method"; font.pixelSize: 11; color: "#5D6D7E" }
                                ComboBox {
                                    id: methodCombo
                                    width: parent.width
                                    height: 36
                                    font.pixelSize: 12
                                    model: ["All"]
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#DEE2E6"
                                        radius: 4
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        footer: Rectangle {
            width: parent.width
            height: 70
            color: "#F8F9FA"
            radius: 12

            // Fix top corners
            Rectangle {
                width: parent.width
                height: 12
                color: "#F8F9FA"
                anchors.top: parent.top
            }

            // Separator line
            Rectangle {
                width: parent.width
                height: 1
                color: "#E9ECEF"
                anchors.top: parent.top
            }

            Row {
                anchors.centerIn: parent
                spacing: 15

                // Clear All button
                Rectangle {
                    width: 120
                    height: 40
                    radius: 6
                    color: clearAllMA.containsMouse ? "#F5F5F5" : "white"
                    border.color: "#DEE2E6"
                    border.width: 1

                    Text {
                        text: "Clear All"
                        color: "#5D6D7E"
                        font.pixelSize: 13
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: clearAllMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Clear all fields
                            advTitleField.text = ""
                            advAuthorField.text = ""
                            advCallNumberField.text = ""
                            advIsbnField.text = ""
                            advPublisherField.text = ""
                            advShelfNumberField.text = ""
                            advYearFromField.text = ""
                            advYearToField.text = ""
                            subjectCombo.currentIndex = 0
                            genreCombo.currentIndex = 0
                            languageCombo.currentIndex = 0
                            availabilityCombo.currentIndex = 0
                            conditionCombo.currentIndex = 0
                            methodCombo.currentIndex = 0
                        }
                    }
                }

                // Search button
                Rectangle {
                    width: 150
                    height: 40
                    radius: 6
                    color: searchBtnMA.containsMouse ? "#2980B9" : "#3498DB"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            source: "assets/advancedSearch.png"
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                        }

                        Text {
                            text: "Search"
                            color: "white"
                            font.pixelSize: 13
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: searchBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Perform advanced search
                            allBooksList.advancedSearchBooks(
                                advTitleField.text,
                                advAuthorField.text,
                                advCallNumberField.text,
                                advIsbnField.text,
                                advPublisherField.text,
                                advYearFromField.text,
                                advYearToField.text,
                                subjectCombo.currentText,
                                genreCombo.currentText,
                                languageCombo.currentText,
                                advShelfNumberField.text,
                                availabilityCombo.currentText,
                                conditionCombo.currentText,
                                methodCombo.currentText
                            )
                            isSearchActive = true
                            navigationTextInput.text = ""  // Clear basic search
                            advancedSearchDialog.close()
                        }
                    }
                }
            }
        }
    }

    // =====================================================
    // BOOK DETAILS DIALOG
    // =====================================================
    Dialog {
        id: bookDetailsDialog
        title: "Book Details"
        modal: true
        width: Math.min(650, allBooks.width * 0.85)
        height: Math.min(620, allBooks.height * 0.9)
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#FFFFFF"
            radius: 12
            border.color: "#E0E0E0"
            border.width: 1
        }

        header: Rectangle {
            width: parent.width
            height: 70
            color: "#1ABC9C"
            radius: 12

            Rectangle {
                width: parent.width
                height: 12
                color: "#1ABC9C"
                anchors.bottom: parent.bottom
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 60
                spacing: 15

                Image {
                    source: "assets/delegateBook.png"
                    width: 40
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter
                    fillMode: Image.PreserveAspectFit
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - 70

                    Text {
                        text: selectedTitle
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: "by " + selectedAuthor
                        font.pixelSize: 12
                        color: "#E8F6F3"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeDetailsMA.containsMouse ? "#E74C3C" : "transparent"
                anchors {
                    right: parent.right
                    rightMargin: 15
                    verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "✕"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: closeDetailsMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bookDetailsDialog.close()
                }
            }
        }

        contentItem: ScrollView {
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: bookDetailsDialog.width - 40
                spacing: 16
                padding: 20

                // === BASIC INFO SECTION ===
                Rectangle {
                    width: parent.width - 40
                    height: basicInfoColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"

                    Column {
                        id: basicInfoColumn
                        width: parent.width - 30
                        spacing: 10
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Basic Information"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        Grid {
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 8
                            width: parent.width

                            // Call Number
                            Text { text: "Call Number:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedCallNumber || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // ISBN
                            Text { text: "ISBN:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedIsbn || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Barcode
                            Text { text: "Barcode:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedBarcode || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Publisher
                            Text { text: "Publisher:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedPublisher || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Year Published
                            Text { text: "Year Published:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedYearPublished || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }
                        }
                    }
                }

                // === CLASSIFICATION SECTION ===
                Rectangle {
                    width: parent.width - 40
                    height: classificationColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"

                    Column {
                        id: classificationColumn
                        width: parent.width - 30
                        spacing: 10
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Classification"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        Grid {
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 8
                            width: parent.width

                            // Subject
                            Text { text: "Subject:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedSubject || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Genre
                            Text { text: "Genre:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedGenre || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Language
                            Text { text: "Language:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedLanguage || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Shelf Number
                            Text { text: "Shelf Number:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedShelfNumber || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }
                        }
                    }
                }

                // === STATUS & VALUE SECTION ===
                Rectangle {
                    width: parent.width - 40
                    height: statusColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"

                    Column {
                        id: statusColumn
                        width: parent.width - 30
                        spacing: 10
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Status & Value"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        Row {
                            spacing: 15
                            width: parent.width

                            // Availability badge
                            Rectangle {
                                width: availabilityText.width + 20
                                height: 26
                                radius: 13
                                color: selectedAvailability === "Available" ? "#27AE60" :
                                       selectedAvailability === "Borrowed" ? "#E67E22" : "#95A5A6"

                                Text {
                                    id: availabilityText
                                    text: selectedAvailability || "Unknown"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "white"
                                    anchors.centerIn: parent
                                }
                            }

                            // Condition badge
                            Rectangle {
                                width: conditionText.width + 20
                                height: 26
                                radius: 13
                                color: selectedCondition === "Good" || selectedCondition === "Excellent" ? "#3498DB" :
                                       selectedCondition === "Fair" ? "#F39C12" : "#E74C3C"

                                Text {
                                    id: conditionText
                                    text: selectedCondition || "Unknown"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "white"
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        Grid {
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 8
                            width: parent.width

                            // Value
                            Text { text: "Value:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: SettingsManager.currencySymbol + " " + selectedValue.toLocaleString(); font.pixelSize: 11; color: "#27AE60"; font.bold: true; width: parent.width - 140 }

                            // Times Borrowed
                            Text { text: "Times Borrowed:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedTimesBorrowed.toString(); font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140 }

                            // Acquisition Method
                            Text { text: "Acquired Via:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedMethod || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }

                            // Date Added
                            Text { text: "Date Added:"; font.pixelSize: 11; font.bold: true; color: "#5D6D7E"; width: 120 }
                            Text { text: selectedDateAdded || "N/A"; font.pixelSize: 11; color: "#2C3E50"; width: parent.width - 140; wrapMode: Text.Wrap }
                        }
                    }
                }

                // === DESCRIPTION SECTION ===
                Rectangle {
                    width: parent.width - 40
                    height: descriptionColumn.height + 30
                    color: "#F8F9FA"
                    radius: 8
                    border.color: "#E9ECEF"
                    visible: selectedDescription && selectedDescription.length > 0

                    Column {
                        id: descriptionColumn
                        width: parent.width - 30
                        spacing: 10
                        anchors {
                            top: parent.top
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Description"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#2C3E50"
                        }

                        Text {
                            text: selectedDescription || "No description available."
                            font.pixelSize: 11
                            color: "#5D6D7E"
                            wrapMode: Text.Wrap
                            width: parent.width
                            lineHeight: 1.4
                        }
                    }
                }
            }
        }

        footer: Rectangle {
            width: parent.width
            height: 60
            color: "#F8F9FA"
            radius: 12

            Rectangle {
                width: parent.width
                height: 12
                color: "#F8F9FA"
                anchors.top: parent.top
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#E9ECEF"
                anchors.top: parent.top
            }

            Row {
                anchors{
                    right:parent.right
                    rightMargin: 20
                    verticalCenter: parent.verticalCenter
                }

                spacing: 15

                // // Close button
                // Rectangle {
                //     width: 100
                //     height: 36
                //     radius: 6
                //     color: closeFooterMA.containsMouse ? "#2C3E50" : "#34495E"

                //     Text {
                //         text: "Close"
                //         color: "white"
                //         font.pixelSize: 12
                //         font.bold: true
                //         anchors.centerIn: parent
                //     }

                //     MouseArea {
                //         id: closeFooterMA
                //         anchors.fill: parent
                //         hoverEnabled: true
                //         cursorShape: Qt.PointingHandCursor
                //         onClicked: bookDetailsDialog.close()
                //     }
                // }

                Button{
                    text: "Close"
                    onClicked: {
                        bookDetailsDialog.close()
                    }
                }
            }
        }
    }
}
