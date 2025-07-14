import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import com.storageManager

Rectangle {
    id: storageManagerScreen
    color: "#f5f5f5"
    anchors.fill: parent

    property alias storageManager: storageManager

    signal closeClicked()

    //MouseArea to prevent mouse actions from leaking to the screens under this
    MouseArea{
        id: storageManagerMA
        anchors.fill: parent
    }

    StorageManager {
        id: storageManager
        onErrorOccured: (error) =>{
                            errorDialog.title = "Attention!"
                            errorDialog.text = error
                            errorDialog.open()
                        }
    }

    // Back button
    Rectangle {
        id: backRect
        width: 40
        height: 40
        radius: 4
        color: "#DDDDDD"
        z: 3 //high z to avoid editing the anchors of the column ( lazy :)
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
                storageManagerScreen.closeClicked()
            }
        }
    }


    RowLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 40

        // Left side - Storage Ring
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                id: ringContainer
                width: Math.min(parent.width, parent.height) * 0.8
                height: width
                anchors.centerIn: parent
                color: "transparent"

                // Background circle
                Rectangle {
                    id: backgroundRing
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "transparent"
                    border.width: 20
                    border.color: "#e0e0e0"
                }

                // Progress ring
                Canvas {
                    id: progressRing
                    width: parent.width
                    height: parent.height

                    property real progress: storageManager.storagePercentage
                    property color ringColor: progress > 70 ? "#e74c3c" : "#3498db"

                    onProgressChanged: requestPaint()
                    onRingColorChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var centerX = width / 2
                        var centerY = height / 2
                        var radius = (width - 20) / 2
                        var startAngle = -Math.PI / 2
                        var endAngle = startAngle + (progress / 100) * 2 * Math.PI

                        ctx.beginPath()
                        ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                        ctx.lineWidth = 20
                        ctx.strokeStyle = ringColor
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                }

                // Center content
                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: storageManager.appSizeFormatted
                        font.pixelSize: 32
                        font.weight: Font.Bold
                        color: "#2c3e50"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "of " + storageManager.deviceSizeFormatted
                        font.pixelSize: 16
                        color: "#7f8c8d"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: storageManager.storagePercentage.toFixed(1) + "%"
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        color: storageManager.storagePercentage > 70 ? "#e74c3c" : "#3498db"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Used Storage"
                        font.pixelSize: 14
                        color: "#95a5a6"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // Right side - Info Panel
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 12
            border.width: 1
            border.color: "#e0e0e0"

            Column {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 30

                // Title
                Text {
                    text: "Storage Information"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: "#2c3e50"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Database Size
                Rectangle {
                    width: parent.width
                    height: Math.min(80, 80 * (parent.height/505))//divide with 505 to maintain a ratio when resized the max height is 80
                    color: "#f8f9fa"
                    radius: 8
                    border.width: 1
                    border.color: "#e9ecef"

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "Database Size"
                            font.pixelSize: 14
                            color: "#6c757d"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: storageManager.databaseSizeFormatted
                            font.pixelSize: 18
                            font.weight: Font.Medium
                            color: "#495057"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Recommended Storage
                Rectangle {
                    width: parent.width
                    height: Math.min(80, 80 * (parent.height/505))
                    color: "#f8f9fa"
                    radius: 8
                    border.width: 1
                    border.color: "#e9ecef"

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "Recommended Storage"
                            font.pixelSize: 14
                            color: "#6c757d"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: storageManager.recommendedSizeFormatted + " +"
                            font.pixelSize: 18
                            font.weight: Font.Medium
                            color: "#28a745"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Storage Status
                Rectangle {
                    width: parent.width
                    height: Math.min(60, 60 * (parent.height/505))
                    color: storageManager.storagePercentage > 70 ? "#fff5f5" : "#f0f8ff"
                    radius: 8
                    border.width: 1
                    border.color: storageManager.storagePercentage > 70 ? "#fed7d7" : "#bee5eb"

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: storageManager.storagePercentage > 70 ? "#e74c3c" : "#17a2b8"
                        }

                        Text {
                            text: storageManager.storagePercentage > 70 ? "High Usage" : "Normal Usage"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: storageManager.storagePercentage > 70 ? "#721c24" : "#0c5460"
                        }
                    }
                }

                CustomButton{
                    id: refreshBtn
                    width: parent.width
                    height:  Math.min(60, 60 * (parent.height/505))
                    // radius: 6

                    text: "Refresh"
                    defaultColor: "#399ED9"
                    hoveredColor: "#399ED9"

                    contentItem: Text {
                        text: refreshBtn.text
                        font: refreshBtn.font
                        opacity: enabled ? 1.0 : 0.5
                        color: refreshBtn.down ? "#585757" : "black"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }


                    onClicked: {
                        storageManager.fetchStorageInfo()
                    }
                }

                Component.onCompleted: {
                    console.log("Storage info rect height: ", height)
                }
            }
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

    Component.onCompleted: {
        storageManager.fetchStorageInfo()
    }
}















