import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects


Rectangle{
    id: topButtons
    radius: 8
    color: "#ffffff"
//    color: "#40E0D0"
//    width: parent.width* 0.5
//    height: parent.height* .3
//        anchors{
//            top: parent.top
//            left: buttonsRect.right
//            leftMargin: 20
//            topMargin: 20* (parent.height/1080)
//        }


    property var addUser: null

    function createAddUserPage(){
        if (addUser == null){
            var component = Qt.createComponent("AddUser.qml")
            addUser = component.createObject(centralRect)
            if (addUser !==null){
                addUser.anchors.centerIn = centralRect
                addUser.closeClicked.connect(destroyAddUserPage)
            }
        }
    }

    function destroyAddUserPage(){
        if (addUser !== null){
            addUser.destroy()
            addUser = null
        }
    }


    RoundButton{
        id: addStudentBtn
        height: parent.height* .85
        width: parent.width* .29
        radius: 10
        anchors{
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            topMargin: 17
            leftMargin: 10
            bottomMargin: 17
        }

        text: "Add student to the library"
        font.italic: true

        Image{
            id: addStudentImg
            width: parent.width* 1/5
            height: parent.height* 1/4
            anchors{
                right: parent.right
                top: parent.top
            }

            source:"qrc:Libro1/buttonImages/icons8-add-user-group-man-man-skin-type-7-48.png"
            fillMode: Image.PreserveAspectFit
        }

        onClicked: {
            createAddUserPage()
        }

        Component.onCompleted: console.log(width)
    }

    RoundButton{
        id: issuedBooksBtn
        height: parent.height* .85
        width: addStudentBtn.width
        radius: 10
        anchors{
            left: addStudentBtn.right
            top: parent.top
            bottom: parent.bottom
            topMargin: 17
            leftMargin: 20
            bottomMargin: 17
        }

        text: "Show issued books"
        font.italic: true

        Image{
            id: issuedBooksImg
            width: parent.width* 1/5
            height: parent.height* 1/4
            anchors{
                right: parent.right
                top: parent.top
            }

            source:"qrc:Libro1/buttonImages/icons8-folder-48.png"
            fillMode: Image.PreserveAspectFit
        }
        Component.onCompleted: console.log(width)
    }

    RoundButton{
        id: borrowBtn
        height: parent.height* .85
        width: addStudentBtn.width
        radius: 10
        anchors{
            left: issuedBooksBtn.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: 17
            leftMargin: 20
            bottomMargin: 17
            rightMargin: 10
        }

        text: "Return/Issue book"
        font.italic: true

        onClicked: {
//            testRect.visible = !testRect.visible
        }

        Image{
            id: borrowImg
            width: parent.width* 1/5
            height: parent.height* 1/4
            anchors{
                right: parent.right
                top: parent.top
            }

            source:"qrc:Libro1/buttonImages/icons8-info-48.png"
            fillMode: Image.PreserveAspectFit
        }

        Component.onCompleted: console.log(width)
    }

//    TestRect{
//        id: testRect
//        visible: false
//        anchors{
//            left: borrowBtn.horizontalCenter
//            top: borrowBtn.verticalCenter
//        }
//    }
}

















