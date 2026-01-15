import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

// Import components
import "components"
import "widgets"

ApplicationWindow {
    id: window
    width: 1024
    height: 600
    visible: true
    title: qsTr("Head Unit - Vehicle Infotainment System")

    // Current page: 0=Home, 1=Media, 2=Ambient (Vehicle tab removed - gear is always visible on left)
    property int currentPage: 0

    // Status properties
    property bool isConnected: ipcManager ? ipcManager.isConnected : false
    property string currentGear: gearManager ? gearManager.gearPosition : "P"
    property color ambientColor: ambientManager ? ambientManager.ambientColor : "#34495e"
    property real ambientBrightness: ambientManager ? ambientManager.brightness : 1.0

    // Background with ambient color gradient and brightness
    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"  // Dark background

        // Gradient layer with brightness control
        Rectangle {
            id: backgroundGradient
            anchors.fill: parent

            property color brightColor: Qt.rgba(
                window.ambientColor.r * window.ambientBrightness,
                window.ambientColor.g * window.ambientBrightness,
                window.ambientColor.b * window.ambientBrightness,
                1.0
            )

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(backgroundGradient.brightColor, 1.5)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.lighter(backgroundGradient.brightColor, 1.2)
                }
                GradientStop {
                    position: 1.0
                    color: "#2c3e50"
                }
            }

            Behavior on brightColor {
                ColorAnimation { duration: 300; easing.type: Easing.OutQuad }
            }
        }
    }

    // Watch for ambient color and brightness changes
    Connections {
        target: ambientManager
        function onAmbientColorChanged() {
            if (ambientManager.ambientLightEnabled) {
                window.ambientColor = ambientManager.ambientColor
            }
        }
        function onBrightnessChanged() {
            window.ambientBrightness = ambientManager.brightness
        }
        function onAmbientLightEnabledChanged() {
            window.ambientColor = ambientManager.ambientLightEnabled ?
                                   ambientManager.ambientColor : "#34495e"
        }
    }

    // Top Status Bar
    Rectangle {
        id: statusBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "#1a1a1a"
        opacity: 0.9
        z: 100

        // Center - Date and Time
        Column {
            anchors.centerIn: parent
            spacing: 2

            // Date
            Text {
                id: dateText
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 14
                font.bold: false
                color: "#95a5a6"
            }

            // Time
            Text {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 22
                font.bold: true
                color: "#ecf0f1"

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        var date = new Date()
                        clockText.text = Qt.formatTime(date, "hh:mm:ss")
                        dateText.text = Qt.formatDate(date, "dddd, MMMM d, yyyy")
                    }
                    Component.onCompleted: triggered()
                }
            }
        }
    }

    // Permanent Left Side Gear Selection Panel
    Rectangle {
        id: leftGearPanel
        anchors.top: statusBar.bottom
        anchors.left: parent.left
        anchors.bottom: navigationBar.top
        width: 100
        color: "#1a1a1a"
        opacity: 0.95
        z: 90

        GearSelectionWidget {
            id: gearWidget
            anchors.centerIn: parent
            compactMode: true
        }
    }

    // Main Content Area (adjusted for left panel)
    Item {
        id: contentArea
        anchors.top: statusBar.bottom
        anchors.left: leftGearPanel.right
        anchors.right: parent.right
        anchors.bottom: navigationBar.top
        anchors.margins: 0

        // Home Page
        HomePage {
            id: homePage
            visible: window.currentPage === 0
            anchors.fill: parent
        }

        // Media Page
        MediaPage {
            id: mediaPage
            visible: window.currentPage === 1
            anchors.fill: parent
        }

        // Ambient Lighting Page
        AmbientPage {
            id: ambientPage
            visible: window.currentPage === 2
            anchors.fill: parent
        }
    }

    // Bottom Navigation Bar
    Rectangle {
        id: navigationBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: "#1a1a1a"
        opacity: 0.95
        z: 100

        Row {
            anchors.centerIn: parent
            spacing: 40

            // Home Button
            NavigationButton {
                icon: "qrc:/images/car.svg"
                label: "Home"
                active: window.currentPage === 0
                onClicked: window.currentPage = 0
            }

            // Media Button
            NavigationButton {
                icon: "qrc:/images/mp3.svg"
                label: "Media"
                active: window.currentPage === 1
                onClicked: window.currentPage = 1
            }

            // Ambient Button
            NavigationButton {
                icon: "qrc:/images/ambient_light.svg"
                label: "Ambient"
                active: window.currentPage === 2
                onClicked: window.currentPage = 2
            }
        }
    }
}
