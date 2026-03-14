import QtQuick 2.15
import QtQuick.Controls

Item {
    id: userTips

    // ── tips ──────────────────────────────────
    property var tipsPool: [
        "Use the searchbar at the top of this page to quickly find tools.",
        "Click \"Show more\" on the Stats page in this box to see more statistics on library usage.",
        "Adjust circulation configuration in settings e.g. maximum number of loan days.",
        "Configure\/change the backup interval days in settings, under \"System Settings\" ",
        "You can change book condition during check in for accurate iventory tracking.",
        "Order books online easily from the Online Bookshops tool.",
        "Storage Manager helps you know how much space you need for the system to run smoothly and how much the application occupies on your computer.",
        "Use Digital Material tool to manage library items that aren't books.",
        "You can easily open pdf documents using the PDF Reader tool on Tools Page.",
        "Use Libro AI to get directions on Library system usage and help.",
        "Track the number of books, available, checked out, overdue and missing on the Inventory Tracking Tracking module.",
        "Check how many books each shelf has in the Inventory Tracking module, under Physical Tracking.",
        "Use Activity Logger tool to go through logs to identify\/audit issues.",
        "Opac Configuratin tool lets you connect to an OPAC so the public can see what you have in your library.",
        "Generate barcode in bulk using the Barcode Writer tool.",
        "System Management tool let's you add new admins and track the license status of the system.",
        "Pending Requests button on the home page takes you to Reserved books.",
        "View day's activity chart on the drawer(opened by clicking on the profile at the top right corner of the app).",
        "In case of any issues with the user interface, e.g. freezing of a section, try logging out and log back in or restarting the application.",
        "Reports and Analytics tool helps you get more insight about library usage."
    ]

    property int currentTip1Index: 0
    property int currentTip2Index: 1

    function pickRandomTips() {
        if (tipsPool.length < 2) return
        var i = Math.floor(Math.random() * tipsPool.length)
        var j
        do { j = Math.floor(Math.random() * tipsPool.length) } while (j === i)
        currentTip1Index = i
        currentTip2Index = j
    }

    Component.onCompleted: pickRandomTips()

    // Rotate every 12 seconds
    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: userTips.pickRandomTips()
    }

    Rectangle {
        id: tipsRect
        radius: 8
        anchors.fill: parent
        color: "transparent"

        Row {
            id: tipTitleRow
            spacing: 8
            anchors {
                top: parent.top
                topMargin: 20
                left: parent.left
                leftMargin: 20
            }
            Image {
                id: ideaIcon
                height: 16
                width: 16
                fillMode: Image.PreserveAspectFit
                source: "../assets/idea.png"
            }
            Text {
                id: tipTitle
                text: qsTr("Tips")
                font.bold: true
                font.pixelSize: 15
                color: "#3B82F6"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            id: tip1
            anchors {
                top: tipTitleRow.bottom
                topMargin: 20
                left: tipTitleRow.left
                right: parent.right
                rightMargin: 10
                // bottom is constrained by separator so it never overflows down
            }
            text: tipsPool[currentTip1Index] ?? ""
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: tip1; property: "opacity"; to: 0; duration: 200 }
                    PropertyAction  { target: tip1; property: "text" }
                    NumberAnimation { target: tip1; property: "opacity"; to: 1; duration: 200 }
                }
            }
        }

        Rectangle {
            id: separator
            width: parent.width * .78
            height: 2
            anchors {
                horizontalCenter: parent.horizontalCenter
                // pin separator to the vertical midpoint so both tips have equal room
                verticalCenter: parent.verticalCenter
            }
            color: "gray"
        }

        Text {
            id: dot1
            anchors {
                right: separator.left
                rightMargin: 5
                verticalCenter: separator.verticalCenter
            }
            text: qsTr("•")
            color: "gray"
        }

        Text {
            id: dot2
            anchors {
                left: separator.right
                leftMargin: 5
                verticalCenter: separator.verticalCenter
            }
            text: qsTr("•")
            color: "gray"
        }

        Text {
            id: tip2
            anchors {
                top: separator.bottom
                topMargin: 16
                left: tipTitleRow.left
                right: parent.right
                rightMargin: 10
                bottom: parent.bottom   // keeps it from growing past the card edge
                bottomMargin: 16
            }
            text: tipsPool[currentTip2Index] ?? ""
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: tip2; property: "opacity"; to: 0; duration: 200 }
                    PropertyAction  { target: tip2; property: "text" }
                    NumberAnimation { target: tip2; property: "opacity"; to: 1; duration: 200 }
                }
            }
        }
    }
}
