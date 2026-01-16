import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import "components"

// Home page - Dashboard view
Rectangle {
    id: root
    color: "transparent"

    // Center vehicle visualization
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30
        width: 500
        height: 330

        // Vehicle image
        Image {
            id: carImage
            anchors.centerIn: parent
            width: 400
            height: 280
            source: "qrc:/images/car.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        ColorOverlay {
            anchors.fill: carImage
            source: carImage
            color: "#ecf0f1"
            opacity: 0.9
        }

    }

    // Now Playing card only
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 15
        width: 280
        height: 85
        radius: 15
        color: "#2c3e50"
        opacity: 0.95

        Column {
            anchors.centerIn: parent
            spacing: 8

            // Now Playing title
            Text {
                text: "Now Playing"
                font.pixelSize: 12
                color: "#95a5a6"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Song name
            Text {
                text: getFileName(mediaManager.currentFile)
                font.pixelSize: 16
                font.bold: true
                color: "#ecf0f1"
                anchors.horizontalCenter: parent.horizontalCenter
                width: 250
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            // Status
            Text {
                text: mediaManager.isPlaying ? "Playing" : "Paused"
                font.pixelSize: 13
                color: mediaManager.isPlaying ? "#27ae60" : "#7f8c8d"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Helper function to extract filename
    function getFileName(filePath) {
        if (!filePath || filePath === "") return "No song"
        var parts = filePath.split('/')
        var filename = parts[parts.length - 1]
        // Truncate if too long
        if (filename.length > 25) {
            return filename.substring(0, 22) + "..."
        }
        return filename
    }
}
