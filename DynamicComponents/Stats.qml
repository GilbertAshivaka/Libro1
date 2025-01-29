//import QtQuick 2.15
//import QtQuick.Controls

//Item {
//    Rectangle{
//        id:statsRect
//        radius: 8
//        anchors.fill: parent
//        color: "transparent"

//        Text {
//            id: statsTitle
//            text: qsTr("Stats")
//            color: "blue"
//            anchors{
//                top: parent.top
//                topMargin: 20
//                left: parent.left
//                leftMargin: 20
//            }
//            font.bold: true
//            font.pixelSize: 14
//            font.underline: true
//        }

//        Text {
//            id: mostBorrowed
//            anchors{
//                top: statsTitle.bottom
//                topMargin: 20
//                left: statsTitle.left
//            }
//            width: parent.width
//            text: qsTr("Most borrowed book: ")
//            wrapMode: Text.WordWrap
//            font.bold: true
//        }
//        Text {
//            id: _mostBorrowed
//            anchors{
//                top: mostBorrowed.bottom
//                topMargin: 10
//                left: statsTitle.left
//            }
//            width: parent.width
//            text: qsTr("Government of Owls" +"") //plus the number of books borrowed to be added later
//            wrapMode: Text.WordWrap
//        }

//        Text {
//            id: mostActive
//            anchors{
//                top: _mostBorrowed.bottom
//                topMargin: 10
//                left: statsTitle.left
//            }
//            width: parent.width
//            text: qsTr("Most active category: ")
//            wrapMode: Text.WordWrap
//            font.bold: true
//        }

//        Text {
//            id: _mostActive
//            anchors{
//                top: mostActive.bottom
//                topMargin: 10
//                left: statsTitle.left
//            }
//            width: parent.width
//            text: qsTr("Form IV East")
//            wrapMode: Text.WordWrap
//        }

//        Rectangle{
//            id: moreBtn
//            width: 80
//            height: 32
//            color: "lightgray"
//            border.width: 2
//            border.color: "transparent"
//            anchors{
//                top: _mostActive.bottom
//                topMargin: 10
//                right: parent.right
//                rightMargin: 10
//            }

//            Text{
//                id: moreBtnText
//                text: "See more" //textUtils.truncateText("See more", textUtils.calculateMaxLength(parent.width, requestBtnText.font.pixelSize))
//                anchors.centerIn: parent
//            }

//            MouseArea{
//                anchors.fill: parent
//                hoverEnabled: true
//                onEntered: {
//                    moreBtn.border.color = "gray"
//                }
//                onExited: {
//                    moreBtn.border.color = "transparent"
//                }
//                onPressed: {
//                    moreBtn.color = "gray"
//                    moreBtn.width = 78
//                    moreBtn.height = 30
//                }
//                onReleased: {
//                    moreBtn.color = "lightgray"
//                    moreBtn.width = 80
//                    moreBtn.height = 32
//                }
//            }
//        }
//    }
//}

import QtQuick
import QtCharts

Item {
    id: mostBooks

    ChartView{
        id: myChart
        title: "Top five most borrowed books"
        anchors.fill: parent
        antialiasing: true
        legend.alignment: Qt.AlignRight
        backgroundColor: "transparent"

        property var otherSlice: null

        PieSeries {
            id: pieSeries
            PieSlice { label: "Kidagaa"; value: 13.5 }
            PieSlice { label: "Government of Owls"; value: 10.9 }
            PieSlice { label: "Space Odessy"; value: 8.6 }
            PieSlice { label: "Foundation"; value: 8.2 }
            PieSlice { label: "Harry Potter"; value: 6.8 }
        }

        Component.onCompleted: {
            pieSeries.append("Others", 52);
            pieSeries.find("Kidagaa").exploded = true;
        }

    }
}




















