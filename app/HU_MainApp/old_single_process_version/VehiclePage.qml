import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import "components"

// Vehicle control page - Gear selection
Rectangle {
    id: root
    color: "transparent"

    property string currentGear: gearManager.gearPosition

    // Center vehicle visualization
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30
        width: 600
        height: 380

        // Vehicle image
        Image {
            id: carImage
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 450
            height: 300
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

        // Gear selection panel below vehicle
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 500
            height: 150
            radius: 15
            color: "#2c3e50"
            opacity: 0.95

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "GEAR SELECTION"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#95a5a6"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    spacing: 25
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Park
                    GearButton {
                        gear: "P"
                        gearName: "PARK"
                        active: root.currentGear === "P"
                        activeColor: "#e74c3c"
                        onClicked: gearManager.setGearPosition("P")
                    }

                    // Reverse
                    GearButton {
                        gear: "R"
                        gearName: "REVERSE"
                        active: root.currentGear === "R"
                        activeColor: "#e67e22"
                        onClicked: gearManager.setGearPosition("R")
                    }

                    // Neutral
                    GearButton {
                        gear: "N"
                        gearName: "NEUTRAL"
                        active: root.currentGear === "N"
                        activeColor: "#f39c12"
                        onClicked: gearManager.setGearPosition("N")
                    }

                    // Drive
                    GearButton {
                        gear: "D"
                        gearName: "DRIVE"
                        active: root.currentGear === "D"
                        activeColor: "#27ae60"
                        onClicked: gearManager.setGearPosition("D")
                    }
                }
            }
        }
    }

    // Status information panels
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 15
        spacing: 30

        // IC Connection status
        InfoPanel {
            title: "IC Connection"
            value: ipcManager.isConnected ? "CONNECTED" : "DISCONNECTED"
            valueColor: ipcManager.isConnected ? "#27ae60" : "#e74c3c"
            icon: "qrc:/images/car.svg"
        }

        // Current gear display
        InfoPanel {
            title: "Current Gear"
            value: {
                switch(root.currentGear) {
                    case "P": return "PARK"
                    case "R": return "REVERSE"
                    case "N": return "NEUTRAL"
                    case "D": return "DRIVE"
                    default: return "UNKNOWN"
                }
            }
            valueColor: {
                switch(root.currentGear) {
                    case "P": return "#e74c3c"
                    case "R": return "#e67e22"
                    case "N": return "#f39c12"
                    case "D": return "#27ae60"
                    default: return "#7f8c8d"
                }
            }
            icon: "qrc:/images/car.svg"
        }

        // Ambient light sync
        InfoPanel {
            title: "Ambient Sync"
            value: ambientManager.ambientLightEnabled ? "ENABLED" : "DISABLED"
            valueColor: ambientManager.ambientLightEnabled ? "#3498db" : "#7f8c8d"
            icon: "qrc:/images/ambient_light.svg"
        }
    }
}
