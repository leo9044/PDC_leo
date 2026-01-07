import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

// Quick info card component for dashboard
Rectangle {
    id: root
    width: 200
    height: 120
    radius: 10
    color: "#2c3e50"
    opacity: 0.9
    border.color: "#34495e"
    border.width: 1

    property string icon: ""
    property string title: ""
    property string value: ""
    property string subtitle: ""

    Column {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 8

        // Header row with icon and title
        Row {
            width: parent.width
            spacing: 8

            Item {
                width: 24
                height: 24

                Image {
                    id: iconImage
                    anchors.centerIn: parent
                    source: root.icon
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                ColorOverlay {
                    anchors.fill: iconImage
                    source: iconImage
                    color: "#3498db"
                }
            }

            Text {
                text: root.title
                font.pixelSize: 12
                font.bold: true
                color: "#95a5a6"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Value
        Text {
            width: parent.width
            text: root.value
            font.pixelSize: 18
            font.bold: true
            color: "#ecf0f1"
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
        }

        // Subtitle
        Text {
            text: root.subtitle
            font.pixelSize: 11
            color: "#7f8c8d"
        }
    }
}
