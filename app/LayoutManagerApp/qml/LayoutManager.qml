import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

// LayoutManagerApp - Fullscreen Overlay with Navigation Bar
// Provides bottom navigation for all HU apps
Window {
    id: window
    width: 1920
    height: 1080
    visible: true
    visibility: Window.FullScreen
    title: "LayoutManager"
    color: "transparent"
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint

    // ═══════════════════════════════════════════════════════
    // Bottom Navigation Bar
    // ═══════════════════════════════════════════════════════
    Rectangle {
        id: navigationBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: "#2d2d2d"

        Row {
            anchors.centerIn: parent
            spacing: 20

            // Home Button (car icon)
            Button {
                id: homeButton
                width: 80
                height: 60
                
                property bool isActive: true  // Start with Home active

                background: Rectangle {
                    color: parent.isActive ? "#27ae60" : "#444444"
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                contentItem: Item {
                    Image {
                        id: carIcon
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: "qrc:/asset/car.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: carIcon
                        source: carIcon
                        color: "white"
                    }
                }
                
                onClicked: {
                    console.log("Home button clicked")
                    homeButton.isActive = true
                    mediaButton.isActive = false
                    ambientButton.isActive = false
                    // TODO: Raise HomeScreenApp window
                }
            }

            // Media Button (mp3 icon)
            Button {
                id: mediaButton
                width: 80
                height: 60
                
                property bool isActive: false

                background: Rectangle {
                    color: parent.isActive ? "#2196F3" : "#444444"
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                contentItem: Item {
                    Image {
                        id: mp3Icon
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: "qrc:/asset/mp3.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: mp3Icon
                        source: mp3Icon
                        color: "white"
                    }
                }
                
                onClicked: {
                    console.log("Media button clicked")
                    homeButton.isActive = false
                    mediaButton.isActive = true
                    ambientButton.isActive = false
                    // TODO: Raise MediaApp window
                }
            }

            // Ambient Button (ambient_light icon)
            Button {
                id: ambientButton
                width: 80
                height: 60
                
                property bool isActive: false

                background: Rectangle {
                    color: parent.isActive ? "#FF9800" : "#444444"
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                contentItem: Item {
                    Image {
                        id: ambientIcon
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: "qrc:/asset/ambient_light.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: ambientIcon
                        source: ambientIcon
                        color: "white"
                    }
                }
                
                onClicked: {
                    console.log("Ambient button clicked")
                    homeButton.isActive = false
                    mediaButton.isActive = false
                    ambientButton.isActive = true
                    // TODO: Raise AmbientApp window
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("LayoutManagerApp started (Fullscreen Overlay)")
        console.log("Window: " + window.width + "x" + window.height)
        console.log("Navigation bar: " + (window.width) + "x80 at bottom")
    }
}
