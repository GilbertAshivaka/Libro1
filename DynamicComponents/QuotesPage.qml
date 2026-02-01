// import QtQuick 2.15
// import QtQuick.Controls

// Item {
//     id: quotesItem

//     Rectangle{
//         id:quotesRect
//         radius: 8
//         anchors.fill: parent
//         color: "transparent"

//         Text {
//             id: quoteTitle
//             text: qsTr("Quote of the day")
//             color: "blue"
//             anchors{
//                 top: parent.top
//                 topMargin: 20
//                 left: parent.left
//                 leftMargin: 20
//             }
//             font.bold: true
//             font.pixelSize: 14
//         }

//         Text {
//             id: quote
//             anchors{
//                 top: quoteTitle.bottom
//                 topMargin: 20
//                 left: quoteTitle.left
//                 right: parent.right
//                 rightMargin: 10
//             }
//             width: parent.width
//             text: qsTr("Every generation has it's purpose, ours is to reveal and spread the truth and reverse the brainwashing.")
//             wrapMode: Text.WordWrap
//             font.italic: true
//         }

//         Text {
//             id: quoteAuthor
//             text: qsTr("Kentah Gwanjes")
//             anchors{
//                 top: quote.bottom
//                 topMargin:10
//                 left: quote.left
//             }
//             font.bold: true
//             font.pixelSize: 14
//             font.italic: true
//         }
//     }
// }


import QtQuick 2.15
import QtQuick.Controls
import QtWebView
import Qt.labs.platform 1.1 as Platform

Item {
    id: announcementsItem

    Rectangle {
        id: announcementsRect
        radius: 8
        anchors.fill: parent
        color: "white"
        border.color: "#E2E8F0"
        border.width: 1
        clip: true

        WebView {
            id: webView
            anchors {
                fill: parent
            }

            // For testing - loads a simple page
            url: "http://localhost:5173/embed/announcements" //"https://example.com"

            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebView.LoadFailedStatus) {
                    console.log("Failed to load page:", loadRequest.errorString)
                    errorText.visible = true
                } else if (loadRequest.status === WebView.LoadSucceededStatus) {
                    console.log("Page loaded successfully")
                    errorText.visible = false
                }
            }
        }

        // Error message overlay
        Rectangle {
            id: errorOverlay
            anchors {
                fill: parent
                bottomMargin: 50
            }
            color: "#F8FAFC"
            visible: errorText.visible

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    id: errorText
                    text: "⚠️ Failed to load announcements"
                    font.pixelSize: 16
                    color: "#64748B"
                    visible: false
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Please check your internet connection"
                    font.pixelSize: 12
                    color: "#94A3B8"
                    visible: errorText.visible
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Fallback for when WebView is not available
        Text {
            id: fallbackText
            visible: !webView.enabled
            anchors.centerIn: parent
            text: "WebView is not available on this platform"
            font.pixelSize: 14
            color: "#64748B"
            wrapMode: Text.WordWrap
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
        }

        // Bottom button bar
        // Rectangle {
        //     id: buttonBar
        //     width: parent.width
        //     height: 50
        //     anchors.bottom: parent.bottom
        //     color: "#F8FAFC"
        //     border.color: "#E2E8F0"
        //     border.width: 1

        //     Button {
        //         id: openBrowserButton
        //         text: "Open in Browser"
        //         anchors.centerIn: parent
        //         width: parent.width - 40
        //         height: 36

        //         contentItem: Text {
        //             text: openBrowserButton.text
        //             font.pixelSize: 13
        //             color: "#FFFFFF"
        //             horizontalAlignment: Text.AlignHCenter
        //             verticalAlignment: Text.AlignVCenter
        //         }

        //         background: Rectangle {
        //             color: openBrowserButton.hovered ? "#2563EB" : "#3B82F6"
        //             radius: 6
        //             border.color: openBrowserButton.pressed ? "#1E40AF" : "transparent"
        //             border.width: 1

        //             Behavior on color {
        //                 ColorAnimation { duration: 150 }
        //             }
        //         }

        //         onClicked: {
        //             Qt.openUrlExternally(webView.url)
        //             console.log("Opening in browser:", webView.url)
        //         }

        //         MouseArea {
        //             anchors.fill: parent
        //             cursorShape: Qt.PointingHandCursor
        //             onPressed: mouse.accepted = false
        //         }
        //     }
        // }

        Rectangle {
            id: openBtn
            width: buttonText.width + 20
            height: 32
            radius: 25
            border.color: "#878585"
            border.width: 2
            clip: true
            z: 3
            opacity: 0.5
            anchors {
                bottom: parent.bottom
                bottomMargin: 4
                left: parent.left
                leftMargin: 5
            }

            Text {
                id: buttonText
                anchors.centerIn: parent
                text: "Open in Browser"
                font.pixelSize: 8
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onEntered: {
                    openBtn.color = "#878585"
                    openBtn.opacity = 1.0
                    parent.children[0].color = "white"
                }
                onExited: {
                    openBtn.color = "white"
                    openBtn.opacity = 0.5
                    parent.children[0].color = "#878585"
                }
                onClicked: {
                    Qt.openUrlExternally(webView.url)
                    console.log("Opening in browser:", webView.url)
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("Announcements page loaded")
        console.log("Loading URL:", webView.url)
    }
}
