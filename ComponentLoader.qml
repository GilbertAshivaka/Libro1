import QtQuick

Item {

    function customCreateComponent(componentName, qmlFile, parent) {
        if (componentName === null) {
            var component = Qt.createComponent(qmlFile + ".qml");
            componentName = component.createObject(parent);
            if (componentName !== null) {
                componentName.anchors.centerIn = parent;
                componentName.closeClicked.connect(customDestroyComponent(componentName));
            }
        }
    }

    function customDestroyComponent(componentName) {
        if (componentName !== null) {
            componentName.destroy();
            componentName = null;
        }
    }

}
