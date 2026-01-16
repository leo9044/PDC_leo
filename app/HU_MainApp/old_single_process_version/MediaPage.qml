import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import "components"

// Media player page
Rectangle {
    id: root
    color: "transparent"

    // Use actual media manager properties
    property bool isPlaying: mediaManager.isPlaying
    property string currentSong: mediaManager.currentFile
    property int currentIndex: mediaManager.currentIndex
    property var mediaFiles: mediaManager.mediaFiles

    // Function to get just the filename from full path
    function getFileName(filePath) {
        if (!filePath || filePath === "") return "No song selected"
        var parts = filePath.split('/')
        return parts[parts.length - 1]
    }

    // Auto-scan media on load
    Component.onCompleted: {
        console.log("MediaPage: Starting auto scan...")
        autoScanTimer.start()
    }

    Timer {
        id: autoScanTimer
        interval: 500
        onTriggered: {
            var files = mediaManager.scanAllUsbMounts()
            console.log("Auto scan completed. Found", files.length, "media files")
        }
    }

    // Main content layout
    Row {
        anchors.fill: parent
        anchors.topMargin: 30
        anchors.bottomMargin: 20
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 20

        // Left panel - Media library
        Rectangle {
            width: parent.width * 0.55
            height: parent.height
            radius: 15
            color: "#2c3e50"
            opacity: 0.95

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // Header with USB controls
                Row {
                    width: parent.width
                    spacing: 15

                    Text {
                        text: "Media Library"
                        font.pixelSize: 22
                        font.bold: true
                        color: "#ecf0f1"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: parent.width - 400 }

                    // USB mount selector
                    ComboBox {
                        id: mountBox
                        width: 200
                        model: mediaManager.usbMounts
                        displayText: currentText || "No USB Device"
                        anchors.verticalCenter: parent.verticalCenter

                        background: Rectangle {
                            color: "#34495e"
                            radius: 5
                            border.color: "#3498db"
                            border.width: 1
                        }

                        contentItem: Text {
                            text: mountBox.displayText
                            color: "#ecf0f1"
                            font.pixelSize: 13
                            leftPadding: 10
                            rightPadding: 10
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        delegate: ItemDelegate {
                            width: mountBox.width
                            contentItem: Text {
                                text: modelData
                                color: "#ecf0f1"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            highlighted: mountBox.highlightedIndex === index
                            background: Rectangle {
                                color: highlighted ? "#3498db" : "#34495e"
                            }
                        }
                    }

                    // Refresh button
                    Button {
                        width: 45
                        height: 45
                        anchors.verticalCenter: parent.verticalCenter

                        background: Rectangle {
                            radius: 5
                            color: parent.pressed ? "#2980b9" : "#3498db"
                            border.color: "#2980b9"
                            border.width: 1

                            Item {
                                anchors.centerIn: parent
                                width: 28
                                height: 28

                                Image {
                                    id: refreshIcon
                                    anchors.centerIn: parent
                                    source: "qrc:/images/refresh.svg"
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                    fillMode: Image.PreserveAspectFit
                                }

                                ColorOverlay {
                                    anchors.fill: refreshIcon
                                    source: refreshIcon
                                    color: "#ecf0f1"
                                }
                            }
                        }

                        onClicked: {
                            console.log("Refreshing USB mounts...")
                            mediaManager.refreshUsbMounts()
                            refreshScanTimer.start()
                        }

                        Timer {
                            id: refreshScanTimer
                            interval: 500
                            onTriggered: {
                                var files = mediaManager.scanAllUsbMounts()
                                console.log("Refresh scan completed. Found", files.length, "media files")
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#34495e"
                }

                // Media files list
                ListView {
                    width: parent.width
                    height: parent.height - 100
                    model: root.mediaFiles
                    clip: true
                    spacing: 2

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 50
                        radius: 5
                        color: root.currentIndex === index ? "#3498db" : "#34495e"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // Play indicator
                            Rectangle {
                                width: 6
                                height: parent.height
                                radius: 3
                                color: "#27ae60"
                                visible: root.currentIndex === index && root.isPlaying

                                SequentialAnimation on opacity {
                                    running: visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 600 }
                                    NumberAnimation { to: 1.0; duration: 600 }
                                }
                            }

                            // Filename
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.getFileName(modelData)
                                color: "#ecf0f1"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                width: parent.width - 30
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mediaManager.playFile(index)
                                console.log("Playing:", modelData)
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }

        // Right panel - Player controls
        Rectangle {
            width: parent.width * 0.42
            height: parent.height
            radius: 15
            color: "#2c3e50"
            opacity: 0.95

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                // Now playing header
                Text {
                    text: "Now Playing"
                    font.pixelSize: 20
                    font.bold: true
                    color: "#ecf0f1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Album art placeholder
                Rectangle {
                    width: 100
                    height: 100
                    radius: 10
                    color: "#34495e"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Item {
                        anchors.centerIn: parent
                        width: 80
                        height: 80

                        Image {
                            id: musicIcon
                            anchors.centerIn: parent
                            source: "qrc:/images/mp3.svg"
                            sourceSize.width: 60
                            sourceSize.height: 60
                            fillMode: Image.PreserveAspectFit
                        }

                        ColorOverlay {
                            anchors.fill: musicIcon
                            source: musicIcon
                            color: "#7f8c8d"
                        }
                    }
                }

                // Song title
                Rectangle {
                    width: parent.width
                    height: 60
                    color: "#34495e"
                    radius: 8

                    Text {
                        anchors.centerIn: parent
                        text: root.getFileName(root.currentSong)
                        color: "#ecf0f1"
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 20
                    }
                }

                // Spacer
                Item { height: 5 }

                // Playback controls
                Row {
                    spacing: 15
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Previous button
                    MediaButton {
                        icon: "qrc:/images/backward.svg"
                        size: 45
                        onClicked: mediaManager.previous()
                    }

                    // Play/Pause button
                    MediaButton {
                        icon: root.isPlaying ? "qrc:/images/pause.svg" : "qrc:/images/start.svg"
                        size: 60
                        primary: true
                        onClicked: {
                            if (root.isPlaying) {
                                mediaManager.pause()
                            } else {
                                mediaManager.play()
                            }
                        }
                    }

                    // Next button
                    MediaButton {
                        icon: "qrc:/images/forward.svg"
                        size: 45
                        onClicked: mediaManager.next()
                    }
                }

                // Spacer
                Item { height: 10 }

                // Volume control
                Column {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Volume: " + Math.round(mediaManager.volume * 100) + "%"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#ecf0f1"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Slider {
                        width: parent.width
                        height: 40
                        from: 0
                        to: 100
                        value: mediaManager.volume * 100
                        stepSize: 1

                        onMoved: {
                            mediaManager.setVolume(value / 100.0)
                        }

                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: parent.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: "#34495e"

                            Rectangle {
                                width: parent.width * (mediaManager.volume)
                                height: parent.height
                                radius: parent.radius
                                color: "#3498db"
                            }
                        }

                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: "#3498db"
                            border.color: "#2980b9"
                            border.width: 2
                        }
                    }
                }
            }
        }
    }
}
