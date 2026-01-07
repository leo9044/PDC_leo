import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
// HeadUnit 모듈 제거: C++ backend는 contextProperty로 노출됨

Rectangle {
    id: root
    
    signal backClicked()
    
    // Color wheel properties
    property color selectedColor: colorWheel.color
    
    // Ambient light 색상을 배경 그라데이션으로 표시 (ambientManager 사용)
    gradient: Gradient {
        GradientStop { 
            position: 0.0
            color: Qt.lighter(selectedColor, 1.3)
        }
        GradientStop { 
            position: 0.5
            color: selectedColor
        }
        GradientStop { 
            position: 1.0
            color: Qt.darker(selectedColor, 2.0)
        }
    }
    
    // 그라데이션 색상 변경 애니메이션
    Behavior on selectedColor {
        ColorAnimation { duration: 300; easing.type: Easing.OutQuad }
    }
    
    // Update ambient manager when color changes
    function updateAmbientColor() {
        // Only update if the color actually changed from user interaction
        if (ambientManager.ambientColor.toString() !== selectedColor.toString()) {
            console.log("Ambient color changed to:", selectedColor.toString())
            ambientManager.ambientColor = selectedColor.toString()
        }
    }

    // Watch for color changes
    onSelectedColorChanged: {
        // Only call update if we're not in initialization
        if (root.visible) {
            updateAmbientColor()
        }
    }

    // 초기 색상을 color wheel에서 ambientManager로 설정
    Component.onCompleted: {
        // Set the initial color from color wheel to backend
        console.log("Setting initial color from color wheel:", selectedColor.toString())
        ambientManager.ambientColor = selectedColor.toString()
    }
    
    // Back Arrow Button (왼쪽 상단)
    Rectangle {
        id: backButton
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.topMargin: 20
        width: 50
        height: 50
        color: "transparent"
        z: 100  // 다른 요소들 위에 표시
        
        Image {
            id: backArrowIcon
            anchors.centerIn: parent
            source: "qrc:/images/arrow.svg"
            sourceSize.width: 50
            sourceSize.height: 50
            fillMode: Image.PreserveAspectFit
        }
        
        ColorOverlay {
            anchors.fill: backArrowIcon
            source: backArrowIcon
            color: "#ecf0f1"
        }
        
        MouseArea {
            id: backMouseArea
            anchors.fill: parent
            onClicked: root.backClicked()
            
            onPressed: parent.scale = 0.9
            onReleased: parent.scale = 1.0
        }
        
        Behavior on scale {
            NumberAnimation { duration: 100 }
        }
    }
    
    // 왼쪽 기어 선택 영역 (MainMenu와 동일)
    Rectangle {
        id: leftGearPanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 120
        color: "transparent"
        
        GearSelectionWidget {
            id: gearWidget
            compactMode: true
            anchors.centerIn: parent
        }
    }
    
    // 중앙 색상 휠 컨트롤
    Rectangle {
        anchors.centerIn: parent
        width: 350
        height: 350
        color: "transparent"
            
        Control {
            id: colorWheel
            anchors.centerIn: parent
            property real ringWidth: 30
            property real hsvValue: 1.0
            property real hsvSaturation: 1.0

            readonly property color color: Qt.hsva(mousearea.angle, 1.0, 1.0, 1.0)

            contentItem: Item {
                implicitWidth: 350
                implicitHeight: width

                ShaderEffect {
                    id: shadereffect
                    width: parent.width
                    height: parent.height
                    readonly property real ringWidth: colorWheel.ringWidth / width / 2
                    readonly property real s: colorWheel.hsvSaturation
                    readonly property real v: colorWheel.hsvValue

                    vertexShader: "
                        attribute vec4 qt_Vertex;
                        attribute vec2 qt_MultiTexCoord0;
                        varying vec2 qt_TexCoord0;
                        uniform mat4 qt_Matrix;

                        void main() {
                            gl_Position = qt_Matrix * qt_Vertex;
                            qt_TexCoord0 = qt_MultiTexCoord0;
                        }"

                    fragmentShader: "
                        varying vec2 qt_TexCoord0;
                        uniform float qt_Opacity;
                        uniform float ringWidth;
                        uniform float s;
                        uniform float v;

                        vec3 hsv2rgb(vec3 c) {
                            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
                        }

                        void main() {
                            vec2 coord = qt_TexCoord0 - vec2(0.5);
                            float ring = smoothstep(0.0, 0.01, -abs(length(coord) - 0.5 + ringWidth) + ringWidth);
                            gl_FragColor = vec4(hsv2rgb(vec3((atan(coord.y, coord.x) + 3.1415 + 3.1415 / 2.0) / 6.2831 + 0.5, s, v)), 1.0);
                            gl_FragColor *= ring;
                        }"
                }

                Rectangle {
                    id: indicator
                    x: (parent.width - width)/2
                    y: colorWheel.ringWidth * 0.1

                    width: colorWheel.ringWidth * 0.8; height: width
                    radius: width/2

                    color: 'white'
                    border {
                        width: mousearea.containsPress ? 3 : 1
                        color: Qt.lighter(colorWheel.color)
                        Behavior on width { NumberAnimation { duration: 50 } }
                    }

                    transform: Rotation {
                        angle: mousearea.angle * 360
                        origin.x: indicator.width/2
                        origin.y: colorWheel.availableHeight/2 - indicator.y
                    }
                }

                MouseArea {
                    id: mousearea
                    anchors.fill: parent
                    property real angle: Math.atan2(width/2 - mouseX, mouseY - height/2) / 3.14 / 2 + 0.5
                }
            }
        }
        
        // 중앙 차량 이미지 (색상 원 안) - 색상 고정
        Item {
            anchors.centerIn: parent
            width: 140
            height: 95
            
            // 차량 이미지
            Image {
                id: carImageAmbient
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                source: "qrc:/images/car.svg"
                fillMode: Image.PreserveAspectFit
                opacity: 0.9
            }
            
            // 차량은 흰색/회색 고정 (ambient 색상 적용 안 함)
            ColorOverlay {
                anchors.fill: carImageAmbient
                source: carImageAmbient
                color: "#ecf0f1"  // 밝은 회색으로 고정
                opacity: 0.8
            }
        }
    }
}
