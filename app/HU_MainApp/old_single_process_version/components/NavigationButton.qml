import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

// Navigation button component for bottom tab bar
Item {
    id: root
    width: 100
    height: 70

    property string icon: ""
    property string label: ""
    property bool active: false

    signal clicked()

    Column {
        anchors.centerIn: parent
        spacing: 5

        // Icon
        Item {
            width: 40
            height: 40
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: iconImage
                anchors.centerIn: parent
                source: root.icon
                sourceSize.width: 36
                sourceSize.height: 36
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            ColorOverlay {
                anchors.fill: iconImage
                source: iconImage
                color: root.active ? "#3498db" : "#95a5a6"

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
        }

        // Label
        Text {
            text: root.label
            font.pixelSize: 12
            font.bold: root.active
            color: root.active ? "#3498db" : "#95a5a6"
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }

    // Active indicator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 50
        height: 3
        radius: 1.5
        color: "#3498db"
        opacity: root.active ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.clicked()
        }
        onPressed: {
            parent.scale = 0.95
        }
        onReleased: {
            parent.scale = 1.0
        }
    }

    Behavior on scale {
        NumberAnimation { duration: 100 }
    }
}
