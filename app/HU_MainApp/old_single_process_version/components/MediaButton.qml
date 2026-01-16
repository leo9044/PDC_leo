import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

// Media control button component
Rectangle {
    id: root
    width: size
    height: size
    radius: size / 2
    color: pressed ? (primary ? "#2980b9" : "#34495e") : (primary ? "#3498db" : "transparent")
    border.color: primary ? "#2980b9" : "#7f8c8d"
    border.width: primary ? 0 : 2

    property string icon: ""
    property int size: 50
    property bool primary: false
    property bool pressed: false

    signal clicked()

    Item {
        anchors.centerIn: parent
        width: root.size * 0.5
        height: root.size * 0.5

        Image {
            id: buttonIcon
            anchors.centerIn: parent
            source: root.icon
            sourceSize.width: parent.width
            sourceSize.height: parent.height
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        ColorOverlay {
            anchors.fill: buttonIcon
            source: buttonIcon
            color: "#ecf0f1"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
        onPressed: {
            root.pressed = true
            root.scale = 0.95
        }
        onReleased: {
            root.pressed = false
            root.scale = 1.0
        }
    }

    Behavior on scale {
        NumberAnimation { duration: 100 }
    }

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
