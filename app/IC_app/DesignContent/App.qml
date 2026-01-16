import QtQuick 2.15
import Design 1.0
import QtQuick.Window 2.15

Window {
    id: mainWindow
    width: 1024  // HDMI display width
    height: 600  // HDMI display height
    visible: true
    visibility: "FullScreen"      // fullscreen
    flags: Qt.FramelessWindowHint // fullscreen
    title: "Design"
    color: "#000000"  // Black background for unused space

    Component.onCompleted: Qt.inputMethod.hide()

    // Container with scaling to fit 1280x400 design into 1024x600 display
    Item {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        Screen01Form {
            id: mainScreen
            anchors.centerIn: parent
            // Scale down to fit: 1024/1280 = 0.8
            scale: 0.8
            transformOrigin: Item.Center
        }
    }
}
