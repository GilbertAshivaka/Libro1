import QtQuick
import QtQuick.Controls
import QtCharts

Item {
    id: reportsActivity
    anchors.fill: parent
    property double calCulatedHeight: 0
    property double activityFlowHeight: activityFlowItem.calculateFlowHeight()

    Flow{
        id: activityFlowItem
        anchors.fill: parent
        spacing: 20

        function calculateFlowHeight() {
            let currentWidth = 0;
            let rowHeight = 0;
            let totalHeight = 0;
            let spacing = activityFlowItem.spacing;

            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (!item.visible) continue;

                if (currentWidth + item.width > activityFlowItem.width) {
                    totalHeight += rowHeight + spacing;
                    currentWidth = 0;
                    rowHeight = 0;
                }

                currentWidth += item.width + spacing;
                rowHeight = Math.max(rowHeight, item.height);
            }

            totalHeight += rowHeight; // Add the last row's height
//            calculatedHeight = totalHeight;
//            console.log("Calculated Height: ", totalHeight);
            return totalHeight;
        }

        //Signal to calculate the height when items change
        onChildrenChanged: calculateFlowHeight()

        Component.onCompleted: calculateFlowHeight()


        ChartView{
            id: barChart
            width: 600
            height: 400
            legend.alignment: Qt.AlignBottom
            antialiasing: true
            title: "Daily activity summary"

            BarSeries{
                id: barSeries
                axisX: BarCategoryAxis{categories: ["Mon", "Tue", "Wed", "Thur", "Fri"]}
                BarSet{
                    label: "Issuing"; values: [32, 43, 20, 60, 50]
                }
                BarSet{
                    label: "Return"; values: [22, 28, 46, 50, 34]
                }
                BarSet{
                    label: "Reservations"; values: [38, 56, 42, 69, 71]
                }
                BarSet{
                    label: "Renewals"; values: [45, 65, 78, 59, 66]
                }
            }
        }

        Item {
            id: mostBooks
            width: 400
            height: 400

            ChartView{
                id: myChart
                title: "Transaction propotions"
                anchors.fill: parent
                antialiasing: true
                legend.alignment: Qt.AlignLeft
//                backgroundColor: "transparent"

                property var otherSlice: null

                PieSeries {
                    id: pieSeries
                    PieSlice { label: "Issuing"; value: 13.5 }
                    PieSlice { label: "Return"; value: 10.9 }
                    PieSlice { label: "Reservations"; value: 8.6 }
                    PieSlice { label: "Renewals"; value: 8.2 }
                }

                Component.onCompleted: {
                    pieSeries.find("Issuing").exploded = true;
                }

            }
        }

        Rectangle{
            id: lineChartRect
            width: 600
            height: 400
            radius: 8
            border.color: "lightgray"

            ChartView{
                id: usageChart
                anchors.fill: parent
                title: "Total transactions over the past week"
                LineSeries{
                    name: "Transactions"
                    color: "red"
                    XYPoint { x: 0; y: 0 }
                    XYPoint { x: 1.1; y: 2.1 }
                    XYPoint { x: 1.9; y: 3.3 }
                    XYPoint { x: 2.1; y: 2.1 }
                    XYPoint { x: 2.9; y: 4.9 }
                    XYPoint { x: 3.4; y: 3.0 }
                    XYPoint { x: 4.1; y: 3.3 }
                }
            }
        }
    }
}






