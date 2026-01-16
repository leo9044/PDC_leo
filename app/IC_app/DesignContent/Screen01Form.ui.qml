import QtQuick 2.15
import QtQuick.Controls 2.15
import Design 1.0

Rectangle {
    id: rectangle
    width: Constants.width
    height: Constants.height
    color: "#000000"

    property int speed: 0
    property string gear: "P"

    Component.onCompleted: {
        // Initialize with current values from vehicleClient
        gear = vehicleClient.currentGear
        console.log("🎬 IC_app initialized - Gear:", gear, "Battery:", vehicleClient.batteryLevel)
    }

    Connections {
        target: vehicleClient
        function onCurrentGearChanged() {
            console.log("📡 Gear changed:", vehicleClient.currentGear)
            gear = vehicleClient.currentGear
        }
        function onBatteryLevelChanged() {
            console.log("📡 Battery changed:", vehicleClient.batteryLevel)
        }
        function onCurrentSpeedChanged() {
            console.log("📡 Speed changed:", vehicleClient.currentSpeed, "km/h")
            speed = vehicleClient.currentSpeed  // ← vsomeip 속도를 speed property에 연결!
        }
    }

    Connections {
        target: canInterface
        // Receive only cm/s value and directly reflect it to speed property
        onSpeedDataReceived: {
            console.log("🏎️  CAN Speed:", speedCms, "cm/s")
            speed = Math.round(speedCms);
        }
    }

    // 속도 변화 감지해서 바늘 회전
    onSpeedChanged: {
        var angle = -45 + (speed * 1.125)
        console.log("📊 Needle angle:", angle, "for speed:", speed)
        needleRotation.angle = angle
    }

    // --- Battery UI ---
    Rectangle {
        id: battery_fill
        width: 70
        height: 116 * vehicleClient.batteryLevel / 100
        x: 1045

        // [Modified] Dynamically calculate y coordinate with height
        // This keeps the bottom of the bar fixed at y=261
        y: 261 - height

        border.color: "#ffffff"
        z: battery_outline_icon.z

        // [Deleted] This property is no longer needed
        // anchors.bottomMargin: 15

        color: vehicleClient.batteryLevel <= 20 ? "#ff4444"
             : vehicleClient.batteryLevel <= 60 ? "#ffaa33"
                                                    : "#57e389"
    }

    Image {
        id: battery_outline_icon
        x: 1024
        y: 80
        width: 120
        source: "images/battery_outline_icon.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: bolt_icon
        x: 1050
        y: 140
        width: 60
        source: "images/bolt_icon.png"
        fillMode: Image.PreserveAspectFit
        visible: false  // ← 충전 표시 제거
    }

    Text {
        id: battery_text
        anchors.centerIn: battery_outline_icon
        font.pixelSize: 25
        font.bold: true
        color: "white"
        text: vehicleClient.batteryLevel + "%"
        visible: true  // ← 항상 표시
    }

    // --- Gauge UI ---
    Image {
        id: gauge_Speed
        x: 453
        y: 0
        width: 400
        height: 400
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        source: "images/Gauge_Speed.png"
        anchors.horizontalCenterOffset: 0
        rotation: 45
        anchors.horizontalCenter: parent.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks2
        x: 511
        y: 61
        width: 259
        height: 278
        anchors.verticalCenter: parent.verticalCenter
        source: "images/GaugeSpeedometer_Ticks2.png"
        anchors.verticalCenterOffset: 0
        anchors.horizontalCenterOffset: -1
        anchors.horizontalCenter: parent.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeNeedleBig
        x: 560
        y: 168
        width: 160
        height: 66
        source: "images/gaugeNeedleBig.png"
        anchors.horizontalCenterOffset: -49
        anchors.horizontalCenter: gauge_Speed.horizontalCenter
        fillMode: Image.PreserveAspectFit
        
        transform: Rotation {
            id: needleRotation
            origin.x: 130
            origin.y: 33
            angle: -45
            
            Behavior on angle {
                NumberAnimation {
                    duration: 100  // ← 부드러운 애니메이션 (100ms)
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // --- Bottom Panel UI ---
    Image {
        id: bottomPanel
        x: 291
        y: 209
        width: 697
        height: 298
        anchors.right: parent.right
        anchors.rightMargin: 292
        anchors.topMargin: 125
        source: "images/BottomPanel.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks3
        x: 60
        y: 50
        width: 280
        height: 280
        anchors.verticalCenter: parent.verticalCenter
        source: "images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks4
        x: 940
        y: 60
        height: 280
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: gaugeSpeedometer_Ticks3.top
        anchors.bottom: gaugeSpeedometer_Ticks3.bottom
        source: "images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: gaugeSpeedometer_Ticks1
        x: 27
        y: 24
        anchors.verticalCenter: parent.verticalCenter
        source: "images/GaugeSpeedometer_Ticks1.png"
        anchors.horizontalCenter: gaugeSpeedometer_Ticks3.horizontalCenter
        fillMode: Image.PreserveAspectFit

        TextInput {
            id: textInput
            x: 134
            y: 265
            width: 195
            height: 49
            color: "#730000"
            text: qsTr("Gear")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TextInput {
            id: textInput2
            x: 134
            y: 265
            width: 195
            height: 49
            color: "#730000"
            text: qsTr("Battery")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenterOffset: 881
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Image {
        id: gaugeSpeedometer_Ticks5
        x: 907
        y: 24
        anchors.verticalCenter: parent.verticalCenter
        anchors.top: gaugeSpeedometer_Ticks1.top
        anchors.bottom: gaugeSpeedometer_Ticks1.bottom
        source: "images/GaugeSpeedometer_Ticks1.png"
        anchors.horizontalCenter: gaugeSpeedometer_Ticks4.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }

    // --- Text Displays ---
    TextInput {
        id: textInput3
        x: 546
        y: 332
        width: 188
        height: 81
        color: "#ffffff"
        font.pixelSize: 30
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        readOnly: true
        // Display speed value as string
        text: speed.toString()
    }

    TextInput {
        id: textInput4
        x: 125
        y: 125
        width: 150
        height: 150
        color: "#ffffff"
        font.pixelSize: 100
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        readOnly: true
        text: gear
    }
}