import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: suggestionsAdminPage
    anchors.fill: parent
    color: "#FBFBFB"

    // Current filter states
    property string currentTypeFilter: "all"
    property string currentStatusFilter: "all"

    signal closeClicked()

    //fix to prevent mouse clicks to leack to components underneath
    MouseArea{
        anchors.fill: parent
    }

    Rectangle {
        id: titleRect
        width: parent.width
        height: 50
        anchors {
            top: parent.top
            left: parent.left
        }

        Text {
            id: pageTitle
            anchors {
                left: parent.left
                leftMargin: 20
                verticalCenter: parent.verticalCenter
            }
            text: "Suggestions & Feedback"
            font.pointSize: 12
            color: "#878585"
        }
    }

    Rectangle {
        id: closeBtn
        width: 30
        height: 30
        radius: 4
        anchors {
            top: parent.top
            topMargin: 10
            right: parent.right
            rightMargin: 20
        }

        Image {
            id: closeIcon
            width: 15
            height: 15
            anchors.centerIn: parent
            source: "assets/close.png"
            fillMode: Image.PreserveAspectFit
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: closeBtn.color = "#E8E3E4"
            onExited: closeBtn.color = "white"
            onClicked: suggestionsAdminPage.closeClicked()
        }
    }

    // Filter Row - Type Filters
    Row {
        id: typeFilterRow
        spacing: 10
        anchors {
            top: titleRect.bottom
            topMargin: 10
            left: parent.left
            leftMargin: 20
        }

        Text {
            text: "Type:"
            font.pointSize: 10
            color: "#878585"
            anchors.verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: [
                { label: "All", value: "all" },
                { label: "Suggestions", value: "suggestion" },
                { label: "Feedback", value: "feedback" }
            ]

            Rectangle {
                width: 100
                height: 32
                radius: 16
                color: currentTypeFilter === modelData.value ? "#399ED9" : "white"
                border.color: currentTypeFilter === modelData.value ? "#399ED9" : "#E0E0E0"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: currentTypeFilter === modelData.value ? "white" : "#606060"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentTypeFilter = modelData.value
                        suggestionsManager.fetchAllSuggestions(currentTypeFilter, currentStatusFilter)
                    }
                }
            }
        }
    }

    // Filter Row - Status Filters
    Row {
        id: statusFilterRow
        spacing: 10
        anchors {
            top: typeFilterRow.bottom
            topMargin: 10
            left: parent.left
            leftMargin: 20
        }

        Text {
            text: "Status:"
            font.pointSize: 10
            color: "#878585"
            anchors.verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: [
                { label: "All", value: "all" },
                { label: "Pending", value: "pending" },
                { label: "Reviewed", value: "reviewed" },
                { label: "Addressed", value: "addressed" }
            ]

            Rectangle {
                width: 90
                height: 32
                radius: 16
                color: currentStatusFilter === modelData.value ? "#399ED9" : "white"
                border.color: currentStatusFilter === modelData.value ? "#399ED9" : "#E0E0E0"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: currentStatusFilter === modelData.value ? "white" : "#606060"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentStatusFilter = modelData.value
                        suggestionsManager.fetchAllSuggestions(currentTypeFilter, currentStatusFilter)
                    }
                }
            }
        }
    }

    // Count display
    Text {
        id: countText
        anchors {
            top: statusFilterRow.bottom
            topMargin: 15
            left: parent.left
            leftMargin: 20
        }
        text: "Showing " + suggestionsListView.count + " item(s)"
        font.pixelSize: 12
        color: "#878585"
    }

    // Refresh button
    Rectangle {
        id: refreshBtn
        width: 100
        height: 32
        radius: 4
        border.color: "#E0E0E0"
        anchors {
            top: statusFilterRow.bottom
            topMargin: 10
            right: parent.right
            rightMargin: 20
        }

        Row {
            anchors.centerIn: parent
            spacing: 5

            Image {
                width: 16
                height: 16
                source: "assets/reload.png"
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "Refresh"
                font.pixelSize: 12
                color: "#606060"
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: refreshBtn.color = "#F5F5F5"
            onExited: refreshBtn.color = "white"
            onClicked: suggestionsManager.fetchAllSuggestions(currentTypeFilter, currentStatusFilter)
        }
    }

    // Main ListView
    ListView {
        boundsBehavior: Flickable.StopAtBounds
        id: suggestionsListView
        clip: true
        anchors {
            top: countText.bottom
            topMargin: 15
            left: parent.left
            leftMargin: 10
            right: parent.right
            rightMargin: 10
            bottom: parent.bottom
            bottomMargin: 10
        }

        model: suggestionsManager.model

        ScrollBar.vertical: ScrollBar {
            id: vbar
            active: true
            policy: ScrollBar.AsNeeded
            width: 8

            contentItem: Rectangle {
                implicitWidth: 8
                radius: width / 2
                color: vbar.pressed ? "#818181" : "#c2c2c2"
            }
        }

        delegate: Rectangle {
            id: delegateRect
            width: suggestionsListView.width - 20
            height: 120
            color: "white"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter

            // Type badge
            Rectangle {
                id: typeBadge
                width: typeText.width + 16
                height: 22
                radius: 11
                color: model.type === "suggestion" ? "#E3F2FD" : "#FFF3E0"
                anchors {
                    top: parent.top
                    topMargin: 10
                    left: parent.left
                    leftMargin: 15
                }

                Text {
                    id: typeText
                    anchors.centerIn: parent
                    text: model.type === "suggestion" ? "Suggestion" : "Feedback"
                    font.pixelSize: 10
                    color: model.type === "suggestion" ? "#1976D2" : "#F57C00"
                }
            }

            // Status badge
            Rectangle {
                id: statusBadge
                width: statusText.width + 16
                height: 22
                radius: 11
                color: model.status === "pending" ? "#FFF9C4" :
                       model.status === "reviewed" ? "#E8F5E9" : "#E0E0E0"
                anchors {
                    top: parent.top
                    topMargin: 10
                    right: parent.right
                    rightMargin: 15
                }

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: model.status.toUpperCase()
                    font.pixelSize: 10
                    font.bold: true
                    color: model.status === "pending" ? "#F9A825" :
                           model.status === "reviewed" ? "#388E3C" : "#616161"
                }
            }

            // User name
            Text {
                id: userName
                anchors {
                    top: typeBadge.bottom
                    topMargin: 8
                    left: parent.left
                    leftMargin: 15
                }
                text: model.userName
                font.pixelSize: 14
                font.bold: true
                color: "#333333"
            }

            // User role & number (if not anonymous)
            Text {
                id: userDetails
                anchors {
                    top: userName.bottom
                    topMargin: 2
                    left: parent.left
                    leftMargin: 15
                }
                text: model.userRole && model.userNumber ? model.userRole + " • " + model.userNumber : ""
                font.pixelSize: 11
                color: "#999999"
                visible: text.length > 0
            }

            // Content preview
            Text {
                id: contentPreview
                anchors {
                    top: userDetails.visible ? userDetails.bottom : userName.bottom
                    topMargin: 5
                    left: parent.left
                    leftMargin: 15
                    right: parent.right
                    rightMargin: 15
                }
                text: model.preview
                font.pixelSize: 12
                color: "#606060"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            // Date
            Text {
                id: dateText
                anchors {
                    bottom: actionRow.top
                    bottomMargin: 5
                    left: parent.left
                    leftMargin: 15
                }
                text: model.createdAt
                font.pixelSize: 10
                color: "#AAAAAA"
            }

            // Action buttons row
            Row {
                id: actionRow
                spacing: 10
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 10
                    left: parent.left
                    leftMargin: 15
                }

                // View Details button
                Text {
                    text: "View Details"
                    font.pixelSize: 12
                    color: "#399ED9"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            detailPopup.suggestionData = suggestionsManager.getSuggestionById(model.suggestionId)
                            detailPopup.open()
                        }
                    }
                }

                Text {
                    text: "|"
                    color: "#E0E0E0"
                }

                // Mark Reviewed (only if pending)
                Text {
                    text: "Mark Reviewed"
                    font.pixelSize: 12
                    color: model.status === "pending" ? "#4CAF50" : "#CCCCCC"
                    visible: model.status === "pending"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: model.status === "pending" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: model.status === "pending"
                        onClicked: {
                            suggestionsManager.updateStatus(model.suggestionId, "reviewed")
                            suggestionsManager.fetchAllSuggestions(currentTypeFilter, currentStatusFilter)
                        }
                    }
                }

                Text {
                    text: "|"
                    color: "#E0E0E0"
                    visible: model.status === "pending"
                }

                // Mark Addressed (only if pending or reviewed)
                Text {
                    text: "Mark Addressed"
                    font.pixelSize: 12
                    color: model.status !== "addressed" ? "#FF9800" : "#CCCCCC"
                    visible: model.status !== "addressed"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: model.status !== "addressed" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: model.status !== "addressed"
                        onClicked: {
                            suggestionsManager.updateStatus(model.suggestionId, "addressed")
                            suggestionsManager.fetchAllSuggestions(currentTypeFilter, currentStatusFilter)
                        }
                    }
                }

                Text {
                    text: "|"
                    color: "#E0E0E0"
                    visible: model.status !== "addressed"
                }

                // Delete button
                Text {
                    text: "Delete"
                    font.pixelSize: 12
                    color: "#F44336"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            deleteConfirmDialog.suggestionId = model.suggestionId
                            deleteConfirmDialog.open()
                        }
                    }
                }
            }
        }

        // Spacing between items
        spacing: 10

        // Empty state
        Rectangle {
            anchors.centerIn: parent
            width: 300
            height: 150
            color: "transparent"
            visible: suggestionsListView.count === 0

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📭"
                    font.pixelSize: 48
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No items found"
                    font.pixelSize: 16
                    color: "#878585"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Try changing the filters or check back later"
                    font.pixelSize: 12
                    color: "#AAAAAA"
                }
            }
        }
    }

    // Detail Popup
    Popup {
        id: detailPopup
        width: parent.width * 0.6
        height: parent.height * 0.7
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var suggestionData: ({})

        background: Rectangle {
            color: "white"
            radius: 8
            border.color: "#E0E0E0"
        }

        contentItem: Rectangle {
            color: "white"
            radius: 8

            // Header
            Rectangle {
                id: popupHeader
                width: parent.width
                height: 50
                color: "#F5F5F5"
                radius: 8

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 20
                        verticalCenter: parent.verticalCenter
                    }
                    text: detailPopup.suggestionData.type === "suggestion" ? "Suggestion Details" : "Feedback Details"
                    font.pointSize: 14
                    font.bold: true
                    color: "#333333"
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 4
                    color: "transparent"
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    Image {
                        width: 15
                        height: 15
                        anchors.centerIn: parent
                        source: "assets/close.png"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: parent.color = "#E8E3E4"
                        onExited: parent.color = "transparent"
                        onClicked: detailPopup.close()
                    }
                }
            }

            // Content
            Flickable {
                boundsBehavior: Flickable.StopAtBounds
                id: contentFlickable
                anchors {
                    top: popupHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 20
                }
                contentHeight: contentColumn.height
                clip: true

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: 15

                    // From
                    Column {
                        spacing: 5
                        Text {
                            text: "From"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#878585"
                        }
                        Text {
                            text: detailPopup.suggestionData.user_name || "Unknown"
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }

                    // User details (if not anonymous)
                    Column {
                        spacing: 5
                        visible: detailPopup.suggestionData.user_role && detailPopup.suggestionData.user_number

                        Text {
                            text: "User Details"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#878585"
                        }
                        Text {
                            text: (detailPopup.suggestionData.user_role || "") + " - " + (detailPopup.suggestionData.user_number || "")
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }

                    // Date
                    Column {
                        spacing: 5
                        Text {
                            text: "Submitted On"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#878585"
                        }
                        Text {
                            text: detailPopup.suggestionData.created_at || ""
                            font.pixelSize: 14
                            color: "#333333"
                        }
                    }

                    // Status
                    Column {
                        spacing: 5
                        Text {
                            text: "Status"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#878585"
                        }
                        Rectangle {
                            width: statusDetailText.width + 16
                            height: 24
                            radius: 12
                            color: detailPopup.suggestionData.status === "pending" ? "#FFF9C4" :
                                   detailPopup.suggestionData.status === "reviewed" ? "#E8F5E9" : "#E0E0E0"

                            Text {
                                id: statusDetailText
                                anchors.centerIn: parent
                                text: (detailPopup.suggestionData.status || "").toUpperCase()
                                font.pixelSize: 12
                                font.bold: true
                                color: detailPopup.suggestionData.status === "pending" ? "#F9A825" :
                                       detailPopup.suggestionData.status === "reviewed" ? "#388E3C" : "#616161"
                            }
                        }
                    }

                    // Content
                    Column {
                        spacing: 5
                        width: parent.width

                        Text {
                            text: "Message"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#878585"
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.max(100, messageText.height + 20)
                            color: "#F9F9F9"
                            radius: 4
                            border.color: "#E0E0E0"

                            Text {
                                id: messageText
                                anchors {
                                    fill: parent
                                    margins: 10
                                }
                                text: detailPopup.suggestionData.content || ""
                                font.pixelSize: 14
                                color: "#333333"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    // Delete confirmation dialog
    Dialog {
        id: deleteConfirmDialog
        title: "Confirm Delete"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Yes | Dialog.No

        property int suggestionId: 0

        Label {
            text: "Are you sure you want to delete this item?\nThis action cannot be undone."
            wrapMode: Text.WordWrap
        }

        onAccepted: {
            suggestionsManager.deleteSuggestion(deleteConfirmDialog.suggestionId)
            suggestionsManager.fetchAllSuggestions(currentTypeFilter, currentStatusFilter)
        }
    }

    // Result dialog
    Dialog {
        id: resultDialog
        title: "Message"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok

        property string message: ""

        Label {
            text: resultDialog.message
            wrapMode: Text.WordWrap
        }
    }

    Connections {
        target: suggestionsManager
        function onOperationSuccess(message) {
            resultDialog.title = "Success"
            resultDialog.message = message
            resultDialog.open()
        }
        function onOperationError(errorMessage) {
            resultDialog.title = "Error"
            resultDialog.message = errorMessage
            resultDialog.open()
        }
    }

    Component.onCompleted: {
        suggestionsManager.fetchAllSuggestions("all", "all")
    }
}
