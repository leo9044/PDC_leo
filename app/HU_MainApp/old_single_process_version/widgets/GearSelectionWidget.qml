import QtQuick 2.12
import QtQuick.Controls 2.12
// HeadUnit 모듈 제거: C++ backend는 contextProperty로 노출됨

// 재사용 가능한 기어 선택 위젯 컴포넌트
Column {
    id: root

    property string currentGear: gearManager.gearPosition
    property bool compactMode: true  // 컴팩트 모드 (홈화면용)

    spacing: compactMode ? 10 : 12

    // 기어 선택 버튼들
    Repeater {
        model: ["P", "R", "N", "D"]

        Rectangle {
            width: root.compactMode ? 80 : 80
            height: root.compactMode ? 80 : 70
            color: {
                if (root.currentGear === modelData) {
                    switch(modelData) {
                        case "P": return "#3498db"  // 파란색 (Park)
                        case "R": return "#e74c3c"  // 빨간색 (Reverse)
                        case "N": return "#f39c12"  // 노란색 (Neutral)
                        case "D": return "#27ae60"  // 녹색 (Drive)
                    }
                }
                return "#7f8c8d"  // 비활성 회색
            }
            radius: root.compactMode ? 10 : 10
            border.color: {
                if (root.currentGear === modelData) {
                    switch(modelData) {
                        case "P": return "#2980b9"  // 진한 파란색
                        case "R": return "#c0392b"  // 진한 빨간색
                        case "N": return "#e67e22"  // 진한 노란색
                        case "D": return "#229954"  // 진한 녹색
                    }
                }
                return "#95a5a6"
            }
            border.width: 3

            // 글로우 효과 (선택된 기어용)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6
                height: parent.height + 6
                color: "transparent"
                radius: parent.radius + 3
                border.color: parent.color
                border.width: 2
                opacity: root.currentGear === modelData ? 0.6 : 0
                visible: root.currentGear === modelData

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            Text {
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: root.compactMode ? 48 : 32
                font.bold: true
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    gearManager.gearPosition = modelData
                    console.log("Gear changed to:", modelData)
                }
                
                // 터치 피드백 효과
                onPressed: {
                    parent.scale = 0.95
                    parent.opacity = 0.8
                }
                onReleased: {
                    parent.scale = 1.0
                    parent.opacity = 1.0
                }
            }
            
            // 애니메이션 효과
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
            
            Behavior on scale {
                NumberAnimation { duration: 100 }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }
    }
    
    // 현재 기어 라벨 (컴팩트 모드가 아닐 때만 표시)
    Text {
        visible: !root.compactMode
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            switch(root.currentGear) {
                case "P": return "PARK"
                case "R": return "REVERSE"
                case "N": return "NEUTRAL"
                case "D": return "DRIVE"
                default: return ""
            }
        }
        font.pixelSize: 12
        font.bold: true
        color: "#bdc3c7"
        horizontalAlignment: Text.AlignHCenter
    }
}
