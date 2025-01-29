import QtQuick
import QtQuick.Controls
import QtCharts

Item {
    id: reportsOverview
    anchors.fill: parent
    property double calCulatedHeight: 0
    property double overviewFlowHeight: overviewFlowItem.calculateFlowHeight()

    Flow{
        id: overviewFlowItem
        anchors.fill: parent
        spacing: 20

        function calculateFlowHeight() {
            let currentWidth = 0;
            let rowHeight = 0;
            let totalHeight = 0;
            let spacing = overviewFlowItem.spacing;

            for (let i = 0; i < children.length; i++) {
                let item = children[i];
                if (!item.visible) continue;

                if (currentWidth + item.width > overviewFlowItem.width) {
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
            title: "Last week activity"

            BarSeries{
                id: barSeries
                axisX: BarCategoryAxis{categories: ["Mon", "Tue", "Wed", "Thur", "Fri"]}
                BarSet{
                    label: "Form 1"; values: [32, 43, 20, 60, 50]
                }
                BarSet{
                    label: "Form 2"; values: [22, 28, 46, 50, 34]
                }
                BarSet{
                    label: "Form 3"; values: [38, 56, 42, 69, 71]
                }
                BarSet{
                    label: "Form 4"; values: [45, 65, 78, 59, 66]
                }
            }
        }

        Item {
            id: mostBooks
            width: 400
            height: 400

            ChartView{
                id: myChart
                title: "Top five most borrowed books"
                anchors.fill: parent
                antialiasing: true
                legend.alignment: Qt.AlignLeft
//                backgroundColor: "transparent"

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

        Rectangle{
            id: lineChartRect
            width: 600
            height: 400
            radius: 8
            border.color: "lightgray"

            ChartView{
                id: usageChart
                anchors.fill: parent
                title: "Usage over the past six months"
                LineSeries{
                    name: "Students"
                    color: "red"
                    XYPoint { x: 0; y: 0 }
                    XYPoint { x: 1.1; y: 2.1 }
                    XYPoint { x: 1.9; y: 3.3 }
                    XYPoint { x: 2.1; y: 2.1 }
                    XYPoint { x: 2.9; y: 4.9 }
                    XYPoint { x: 3.4; y: 3.0 }
                    XYPoint { x: 4.1; y: 4.0 }
                }

                LineSeries{
                    name: "Staff"
//                    color: "red"
                    XYPoint { x: 0; y: 0 }
                    XYPoint { x: 1.0; y: 2.7 }
                    XYPoint { x: 1.4; y: 1.9 }
                    XYPoint { x: 2.1; y: 2.6 }
                    XYPoint { x: 2.9; y: 4.0 }
                    XYPoint { x: 3.2; y: 3.8 }
                    XYPoint { x: 4.1; y: 3.4 }
                }

                LineSeries{
                    name: "Other users"
                    color: "blue"
                    XYPoint { x: 0; y: 0 }
                    XYPoint { x: 0.5; y: 1.0 }
                    XYPoint { x: 1.2; y: 3.0 }
                    XYPoint { x: 2.5; y: 1.2 }
                    XYPoint { x: 3.1; y: 2.5 }
                    XYPoint { x: 3.3; y: 2.0 }
                    XYPoint { x: 4.1; y: 0.7 }
                }
            }
        }
    }
}






