import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

// Information panel component
Rectangle {
    id: root
    width: 180
    height: 100
    radius: 10
    color: "#2c3e50"
    opacity: 0.95
    border.color: "#34495e"
    border.width: 1

    property string title: ""
    property string value: ""
    property color valueColor: "#ecf0f1"
    property string icon: ""

    Column {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 8

        // Header with icon
        Row {
            width: parent.width
            spacing: 8

            Item {
                width: 20
                height: 20

                Image {
                    id: iconImage
                    anchors.centerIn: parent
                    source: root.icon
                    sourceSize.width: 16
                    sourceSize.height: 16
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                ColorOverlay {
                    anchors.fill: iconImage
                    source: iconImage
                    color: "#95a5a6"
                }
            }

            Text {
                text: root.title
                font.pixelSize: 11
                font.bold: true
                color: "#95a5a6"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Value
        Text {
            width: parent.width
            text: root.value
            font.pixelSize: 16
            font.bold: true
            color: root.valueColor
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }
    }
}
