import QtQuick
import QtQuick.Controls

Item {
    id: reportsBooksContainer
    ScrollView{
        id: booksSV
        anchors.fill: parent
        contentHeight: reportsBooks.booksFlowHeight + 50

        ReportsBooks{
            id: reportsBooks
            width: booksSV.width
            height: booksFlowHeight + 50
        }
    }
}
