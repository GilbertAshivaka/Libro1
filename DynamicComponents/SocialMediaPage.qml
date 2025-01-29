import QtQuick 2.15
import QtQuick.Controls

Item {
    id: socialMedia
    width: parent.width
    height: parent.height

    Text {
        id: contactTitle
        text: qsTr("Contact Us:")
        anchors{
            top: parent.top
            topMargin: 15
            left: parent.left
            leftMargin: 10
            right: parent.right
            rightMargin: 10
        }
        width: parent.width
        wrapMode: Text.WordWrap
        font.pixelSize: 14
    }

    Text {
        id: emailContact
        text: qsTr("• Send feedback via ")
        anchors{
            top: contactTitle.bottom
            topMargin: 10
            left: parent.left
            leftMargin: 20
        }
        wrapMode: Text.WordWrap
        color: "#393939"
        font.pixelSize: 14
    }

    Text {
        id: emailBtn
        text: "Email"
        font.pixelSize: 12
        color: "#0078D4"
        anchors{
            verticalCenter: emailContact.verticalCenter
            left: emailContact.right
            leftMargin: 0
        }

        Rectangle {
            id: underline
            visible: false
            width: emailBtn.width + 5  // some extra width for spacing
            height: 1
            color: "#0078D4"
            anchors.top: emailBtn.bottom
            anchors.horizontalCenter: emailBtn.horizontalCenter
            anchors.topMargin: 0  // spacing between text and underline
        }

        MouseArea{
            id: emailBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: {
                underline.visible = true
            }
            onExited: {
                underline.visible = false
            }

            onClicked:{

            }
            onPressed: {
                emailBtn.color = "darkblue"
                underline.color = "darkblue"
            }
            onReleased: {
                emailBtn.color = "#0078D4"
                underline.color = "#0078D4"
            }
        }
    }

    Text {
        id: websiteContact
        text: qsTr("• Visit our ")
        anchors{
            top: emailContact.bottom
            topMargin: 10
            left: parent.left
            leftMargin: 20
        }
        wrapMode: Text.WordWrap
        color: "#393939"
        font.pixelSize: 14
    }

    Text {
        id: websiteBtn
        text: "Website"
        font.pixelSize: 12
        color: "#0078D4"
        anchors{
            verticalCenter: websiteContact.verticalCenter
            left: websiteContact.right
            leftMargin: 0
        }

        Rectangle {
            id: underline2
            visible: false
            width: websiteBtn.width + 5  // some extra width for spacing
            height: 1
            color: "#0078D4"
            anchors.top: websiteBtn.bottom
            anchors.horizontalCenter: websiteBtn.horizontalCenter
            anchors.topMargin: 0  // spacing between text and underline
        }

        MouseArea{
            id: websiteBtnMA
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: {
                underline2.visible = true
            }
            onExited: {
                underline2.visible = false
            }

            onClicked:{

            }
            onPressed: {
                websiteBtn.color = "darkblue"
                underline2.color = "darkblue"
            }
            onReleased: {
                websiteBtn.color = "#0078D4"
                underline2.color = "#0078D4"
            }
        }
    }

    Text {
        id: socialTitle
        text: qsTr("• Follow our social media pages:")
        anchors{
            top: websiteContact.bottom
            topMargin: 10
            left: parent.left
            leftMargin: 20
            right: parent.right
            rightMargin: 10
        }
        width: parent.width
        wrapMode: Text.WordWrap
        color: "#393939"
//        color: "#0078D4"
        font.pixelSize: 14
    }

    Image {
        id: twitterIcon
        width: 32
        height: width
        source: "icons/twitter.svg"
        anchors{
            top: socialTitle.bottom
            left: parent.left
            leftMargin: 20
            topMargin: 10
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                x.color = "blue"
            }
            onExited: {
                x.color = "#878585"
            }
            onClicked: {
//                console.log(dynamicBox.width, dynamicBox.height)
            }
        }
    }

    Text {
        id: x
        text: qsTr("X/Twitter")
        anchors{
            top: twitterIcon.bottom
            topMargin: 5
            left: twitterIcon.left
        }
        font.pixelSize: 12
        color: "#878585"

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                x.color = "blue"
            }
            onExited: {
                x.color = "#878585"
            }
            onClicked: {

            }
        }
    }

    Image {
        id: facebookIcon
        source: "icons/facebook.svg"
        width: 32
        height: width
        anchors{
            top: twitterIcon.top
            left: twitterIcon.right
            leftMargin: 30
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                facebook.color = "blue"
            }
            onExited: {
                facebook.color = "#878585"
            }
            onClicked: {

            }
        }
    }

    Text {
        id: facebook
        text: qsTr("Facebook")
        anchors{
            verticalCenter: x.verticalCenter
            left: facebookIcon.left
        }
        font.pixelSize: 12
        color: "#878585"

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                facebook.color = "blue"
            }
            onExited: {
                facebook.color = "#878585"
            }
            onClicked: {

            }
        }
    }

    Image {
        id: linkedInIcon
        source: "icons/linkedin.svg"
        width: 32
        height: width
        anchors{
            top: facebookIcon.top
            left: facebookIcon.right
            leftMargin: 30
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                linkedIn.color = "blue"
            }
            onExited: {
                linkedIn.color = "#878585"
            }
            onClicked: {

            }
        }
    }

    Text {
        id: linkedIn
        text: qsTr("LinkedIn")
        anchors{
            verticalCenter: facebook.verticalCenter
            left: linkedInIcon.left
        }
        font.pixelSize: 12
        color: "#878585"

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                linkedIn.color = "blue"
            }
            onExited: {
                linkedIn.color = "#878585"
            }
            onClicked: {

            }
        }
    }

    Image {
        id: youtubeIcon
        source: "icons/youtube.svg"
        width: 32
        height: width
        visible: dynamicBox.width >257 && dynamicBox.height > 214
        anchors{
            top: linkedInIcon.top
            left: linkedInIcon.right
            leftMargin: 30
        }

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                youtube.color = "blue"
            }
            onExited: {
                youtube.color = "#878585"
            }
            onClicked: {

            }
        }
    }

    Text {
        id: youtube
        text: qsTr("YouTube")
        anchors{
            verticalCenter: facebook.verticalCenter
            left: youtubeIcon.left
        }
        font.pixelSize: 12
        color: "#878585"
        visible: dynamicBox.width >257 && dynamicBox.height > 214

        MouseArea{
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: "PointingHandCursor"
            onEntered: {
                youtube.color = "blue"
            }
            onExited: {
                youtube.color = "#878585"
            }
            onClicked: {

            }
        }
    }
}
















