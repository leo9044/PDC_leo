import QtQuick 2.12
import QtQuick.Controls 2.12

// Gear selection button component
Rectangle {
    id: root
    width: 90
    height: 90
    radius: 10
    color: active ? activeColor : "#34495e"
    border.color: active ? Qt.darker(activeColor, 1.3) : "#7f8c8d"
    border.width: 3

    property string gear: "P"
    property string gearName: "PARK"
    property bool active: false
    property color activeColor: "#e74c3c"

    signal clicked()

    // Glow effect for active gear
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 6
        height: parent.height + 6
        radius: parent.radius + 3
        color: "transparent"
        border.color: root.activeColor
        border.width: 2
        opacity: root.active ? 0.5 : 0
        visible: root.active

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.gear
            font.pixelSize: 32
            font.bold: true
            color: "#ecf0f1"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.gearName
            font.pixelSize: 10
            font.bold: true
            color: root.active ? "#ecf0f1" : "#95a5a6"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.clicked()
            console.log("Gear changed to:", root.gear)
        }
        onPressed: {
            parent.scale = 0.95
        }
        onReleased: {
            parent.scale = 1.0
        }
    }

    Behavior on color {
        ColorAnimation { duration: 300 }
    }

    Behavior on scale {
        NumberAnimation { duration: 100 }
    }
}
