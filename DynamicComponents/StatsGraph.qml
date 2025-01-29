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
//                leftMargin: 10
//            }
//            font.bold: true
//            font.pixelSize: 14
//            font.underline: true
//        }

////        Rectangle{
////            id: graphRect
////            color: "transparent"
////            height: parent.height/2
////            width: parent.width* .75
////            anchors{
////                top: statsTitle.bottom
////                topMargin: 10
////                left: parent.left
////                leftMargin: 10
////            }

////            Image {
////                id: dailyGraph
////                source: "icons/barGraph.png"
////                anchors.fill: parent
////                fillMode: Image.PreserveAspectFit
////            }
////        }

//        Image {
//            id: dailyGraph
//            source: "icons/barGraph.png"
////            anchors.fill: parent
////            fillMode: Image.PreserveAspectFit
//            height: parent.height/2
//            width: parent.width* .5
//            anchors{
//                top: statsTitle.bottom
//                topMargin: 10
//                left: parent.left
//                leftMargin: 10
//            }
//        }

//        Text {
//            id: dailyGraphTxt
//            text: qsTr("Daily activity")
//            anchors{
//                top: dailyGraph.bottom
//                topMargin: 10
//                left: statsTitle.left
//            }
//            font.italic: true
//        }

//        Text {
//            id: moreBtn
//            text: "Show more..."
//            font.pixelSize: 12
//            color: "#0078D4"
//            anchors{
//                verticalCenter: dailyGraphTxt.verticalCenter
//                right: parent.right
//                rightMargin: 20
//            }

//            Rectangle {
//                id: underline
//                visible: false
//                width: moreBtn.width + 5  // some extra width for spacing
//                height: 1
//                color: "#0078D4"
//                anchors.top: moreBtn.bottom
//                anchors.horizontalCenter: moreBtn.horizontalCenter
//                anchors.topMargin: 0  // spacing between text and underline
//            }

//            MouseArea{
//                id: moreBtnMA
//                anchors.fill: parent
//                cursorShape: Qt.PointingHandCursor
//                hoverEnabled: true
//                onEntered: {
//                    underline.visible = true
//                }
//                onExited: {
//                    underline.visible = false
//                }

//                onClicked:{

//                }
//                onPressed: {
//                    moreBtn.color = "darkblue"
//                    underline.color = "darkblue"
//                }
//                onReleased: {
//                    moreBtn.color = "#0078D4"
//                    underline.color = "#0078D4"
//                }
//            }
//        }
//    }
//}




import QtQuick
import QtCharts

Item {
    ChartView{
        id: barChart
        anchors.fill: parent
        legend.alignment: Qt.AlignBottom
        antialiasing: true
        backgroundColor: "transparent"

        BarSeries{
            id: myBarSeries
            axisX: BarCategoryAxis{categories:["2018", "2019", "2020", "2021", "2022", "2023", "2024"] }
            BarSet{
                label: "Gilbert"; values: [2,2,3,4,5,6,8]
            }
            BarSet{
                label: "Susan"; values: [5,1,2,4,1,7,4]
            }
            BarSet{
                label: "John"; values: [3,5,8,13,5,8,9]
            }
        }
    }
}





