var components = {};

function customCreateComponent(componentName, qmlFile, parent) {
    // Assign a default name if componentName is null or undefined
    var name = componentName || qmlFile;

    // Check if the component is already created
    if (components[name] === undefined) {
        var component = Qt.createComponent(qmlFile + ".qml");
        var newComponent = component.createObject(parent);

        if (newComponent !== null) {
            newComponent.anchors.centerIn = parent;
            components[name] = newComponent;  // store the created component in the dictionary

            newComponent.closeClicked.connect(function() {
                customDestroyComponent(name);
            });
        } else {
            console.error("Failed to create object from component " + name);
        }
    } else {
        console.log("Component " + name + " already exists.");
    }
}

function customDestroyComponent(componentName) {
    if (components[componentName] !== undefined) {
        components[componentName].destroy();
        delete components[componentName];  // remove the reference from the dictionary
    }
}

//This was a simpler implementation of the above function, been through a lot with it before I enhanced it

/***************************
var components = {}

function customCreateComponent(componentName, qmlFile, parent) {
    if (componentName === null) {
        var component = Qt.createComponent(qmlFile + ".qml");
        componentName = component.createObject(parent);
        if (componentName !== null) {
            componentName.anchors.centerIn = parent;
            componentName.closeClicked.connect(function() {
                customDestroyComponent(componentName);
            });
        }
    }
}

function customDestroyComponent(componentName) {
    if (componentName !== null) {
        componentName.destroy();
        componentName = null;
    }
}
******************************/
