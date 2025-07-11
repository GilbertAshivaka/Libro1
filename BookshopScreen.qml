import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import com.bookshopManager

Rectangle {
    id: bookshopScreen
    anchors.fill: parent
    color: "#F5F5F5"

    signal closeClicked()

    property alias bookshopManager: bookshopManager

    // Back button
    Rectangle {
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        anchors {
            left: parent.left
            leftMargin: 10
            top: parent.top
            topMargin: 10
        }
        Rectangle {
            id: backBtnRect
            width: 20
            height: 20
            radius: 4
            anchors.centerIn: parent
            color: "transparent"
            Image {
                id: back
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "assets/backArrow.png"
            }
        }
        MouseArea {
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
                bookshopScreen.closeClicked()
            }
        }
    }

    // Title
    Text {
        id: titleText
        text: "Online Bookshops"
        font.family: "Arial"
        font.pixelSize: 28
        font.bold: true
        color: "#2C3E50"
        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
    }

    // Add Bookshop Button
    Rectangle {
        id: addBookshopBtn
        width: 160
        height: 40
        radius: 8
        color: "#3498DB"
        anchors {
            top: titleText.bottom
            topMargin: 20
            right: parent.right
            rightMargin: 40
        }

        // Shadow effect
        DropShadow {
            anchors.fill: addBookshopBtn
            source: addBookshopBtn
            horizontalOffset: 0
            verticalOffset: 2
            radius: 4
            samples: 9
            color: "#40000000"
        }

        Text {
            text: "Add Bookshop"
            color: "white"
            font.pixelSize: 14
            font.bold: true
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = "#2980B9"
            onExited: parent.color = "#3498DB"
            onClicked: addBookshopDialog.open()
        }
    }

    // Bookshops Grid
    ScrollView {
        id: scrollView
        anchors {
            top: addBookshopBtn.bottom
            topMargin: 30
            left: parent.left
            leftMargin: 40
            right: parent.right
            rightMargin: 40
            bottom: parent.bottom
            bottomMargin: 40
        }
        clip: true

        GridLayout {
            id: bookshopsGrid
            columns: 3
            columnSpacing: 20
            rowSpacing: 20
            width: scrollView.width

            Repeater {
                model: bookshopManager.bookshopsModel

                Rectangle {
                    id: bookshopCard
                    width: (bookshopsGrid.width - 80) / 3
                    height: 180
                    radius: 12
                    color: "#FFFFFF"
                    border.color: "#E0E0E0"
                    border.width: 1

                    // // Shadow effect
                    // DropShadow {
                    //     anchors.fill: bookshopCard
                    //     source: bookshopCard
                    //     horizontalOffset: 0
                    //     verticalOffset: 4
                    //     radius: 8
                    //     samples: 17
                    //     color: "#20000000"
                    // }

                    // Bookshop Icon
                    Rectangle {
                        id: iconRect
                        width: 60
                        height: 60
                        radius: 30
                        color: "#3498DB"
                        anchors {
                            top: parent.top
                            topMargin: 20
                            horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: model.name.charAt(0).toUpperCase()
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            anchors.centerIn: parent
                        }
                    }

                    // Bookshop Name
                    Text {
                        id: nameText
                        text: model.name
                        font.pixelSize: 16
                        font.bold: true
                        color: "#2C3E50"
                        anchors {
                            top: iconRect.bottom
                            topMargin: 15
                            horizontalCenter: parent.horizontalCenter
                        }
                        elide: Text.ElideRight
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // URL Preview
                    Text {
                        id: urlText
                        text: model.url
                        font.pixelSize: 12
                        color: "#7F8C8D"
                        anchors {
                            top: nameText.bottom
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                        elide: Text.ElideRight
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Card Click Area
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            bookshopCard.color = "#F8F9FA"
                            bookshopCard.border.color = "#3498DB"
                            deleteBtn.visible = true
                        }
                        onExited: {
                            bookshopCard.color = "#FFFFFF"
                            bookshopCard.border.color = "#E0E0E0"
                            deleteBtn.visible = false
                        }
                        onClicked: {
                            bookshopManager.openBookshop(model.url)
                        }
                    }

                    // Delete Button
                    Rectangle {
                        id: deleteBtn
                        width: 24
                        height: 24
                        radius: 12
                        color: "#E74C3C"
                        anchors {
                            top: parent.top
                            topMargin: 10
                            right: parent.right
                            rightMargin: 10
                        }
                        visible: false //deleteBtnMA.containsMouse

                        Text {
                            text: "×"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: deleteBtnMA
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                deleteConfirmDialog.bookshopId = model.id
                                deleteConfirmDialog.bookshopName = model.name
                                deleteConfirmDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    // Add Bookshop Dialog
    Dialog {
        id: addBookshopDialog
        title: "Add New Bookshop"
        width: 400
        height: 300
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true

        background: Rectangle {
            color: "#FFFFFF"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Text {
                text: "Bookshop Details"
                font.pixelSize: 18
                font.bold: true
                color: "#2C3E50"
            }

            CustomTextField {
                id: bookshopNameField
                width: parent.width
                placeholderText: "Bookshop name"
            }

            CustomTextField {
                id: bookshopUrlField
                width: parent.width
                placeholderText: "Bookshop URL (e.g., https://www.example.com)"
            }

            Text {
                id: errorText
                text: ""
                color: "#E74C3C"
                font.pixelSize: 12
                visible: text !== ""
            }

            Row {
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: 80
                    height: 35
                    radius: 6
                    color: "#95A5A6"
                    Text {
                        text: "Cancel"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#7F8C8D"
                        onExited: parent.color = "#95A5A6"
                        onClicked: {
                            addBookshopDialog.close()
                            bookshopNameField.text = ""
                            bookshopUrlField.text = ""
                            errorText.text = ""
                        }
                    }
                }

                Rectangle {
                    width: 80
                    height: 35
                    radius: 6
                    color: "#27AE60"
                    Text {
                        text: "Add"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#229954"
                        onExited: parent.color = "#27AE60"
                        onClicked: {
                            var name = bookshopNameField.text.trim()
                            var url = bookshopUrlField.text.trim()

                            if (name === "") {
                                errorText.text = "Please enter a bookshop name"
                                return
                            }

                            if (url === "") {
                                errorText.text = "Please enter a URL"
                                return
                            }

                            if (!bookshopManager.isValidUrl(url)) {
                                errorText.text = "Please enter a valid URL"
                                return
                            }

                            if (bookshopManager.addBookshop(name, url)) {
                                addBookshopDialog.close()
                                bookshopNameField.text = ""
                                bookshopUrlField.text = ""
                                errorText.text = ""
                            } else {
                                errorText.text = "Failed to add bookshop"
                            }
                        }
                    }
                }
            }
        }
    }

    // Delete Confirmation Dialog
    Dialog {
        id: deleteConfirmDialog
        title: "Delete Bookshop"
        width: 350
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true

        property int bookshopId: -1
        property string bookshopName: ""

        background: Rectangle {
            color: "#FFFFFF"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 1
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Text {
                text: "Are you sure you want to delete '" + deleteConfirmDialog.bookshopName + "'?"
                font.pixelSize: 14
                color: "#2C3E50"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: 80
                    height: 35
                    radius: 6
                    color: "#95A5A6"
                    Text {
                        text: "Cancel"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#7F8C8D"
                        onExited: parent.color = "#95A5A6"
                        onClicked: deleteConfirmDialog.close()
                    }
                }

                Rectangle {
                    width: 80
                    height: 35
                    radius: 6
                    color: "#E74C3C"
                    Text {
                        text: "Delete"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#C0392B"
                        onExited: parent.color = "#E74C3C"
                        onClicked: {
                            if (bookshopManager.deleteBookshop(deleteConfirmDialog.bookshopId)) {
                                deleteConfirmDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // Empty State
    Rectangle {
        id: emptyState
        anchors.centerIn: scrollView
        width: 300
        height: 200
        color: "transparent"
        visible: bookshopManager.bookshopsModel.count === 0

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "📚"
                font.pixelSize: 48
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "No bookshops added yet"
                font.pixelSize: 18
                color: "#7F8C8D"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Click 'Add Bookshop' to get started"
                font.pixelSize: 14
                color: "#95A5A6"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // BookshopManager instance
    BookshopManager {
        id: bookshopManager
        Component.onCompleted: {
            loadBookshops()
        }
    }
}
