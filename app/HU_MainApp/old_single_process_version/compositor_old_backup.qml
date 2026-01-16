import QtQuick 2.15
import QtQuick.Window 2.15

/*
 * Wayland Compositor QML
 * 
 * 이 파일은 독립적인 앱들의 창을 배치하고 합성하는 역할만 수행합니다.
 * 실제 비즈니스 로직은 각 앱(GearApp, MediaApp, AmbientApp)에 있습니다.
 * 
 * 배포 환경:
 * - GearApp: vsomeip VehicleControl 클라이언트
 * - MediaApp: vsomeip MediaControl 서비스
 * - AmbientApp: vsomeip VehicleControl + MediaControl 클라이언트
 * 
 * 앱 간 통신은 vsomeip를 통해 이루어지며, 이 Compositor는 관여하지 않습니다.
 */

Window {
    id: root
    visible: true
    width: 1280
    height: 720
    title: "Head Unit - Wayland Compositor"
    color: "#000000"

    // ═══════════════════════════════════════════════════════
    // 레이아웃 정의
    // 각 앱의 창을 배치할 영역
    // ═══════════════════════════════════════════════════════

    Text {
        anchors.centerIn: parent
        text: "HU Wayland Compositor\n\n" +
              "Waiting for app windows:\n" +
              "• GearApp\n" +
              "• MediaApp\n" +
              "• AmbientApp\n\n" +
              "(Windows will appear here when apps start)"
        color: "#888888"
        font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
    }

    // ═══════════════════════════════════════════════════════
    // TODO: Wayland Window Composition
    // ═══════════════════════════════════════════════════════
    // 실제 Wayland compositor 구현은 QtWayland Compositor를 사용해야 합니다.
    // 이는 프로토타입이며, 실제 구현을 위해서는:
    // 1. Qt Wayland Compositor 모듈 사용
    // 2. 각 앱을 Wayland 클라이언트로 실행
    // 3. 이 Compositor에서 각 앱의 Surface를 배치
    //
    // 현재는 각 앱을 독립적으로 실행하는 것으로 대체 가능합니다.
    // ═══════════════════════════════════════════════════════

    Component.onCompleted: {
        console.log("═══════════════════════════════════════════════════════")
        console.log("Compositor Ready")
        console.log("Start independent apps to see their windows:")
        console.log("  $ cd app/GearApp && ./run.sh")
        console.log("  $ cd app/MediaApp && ./run.sh")
        console.log("  $ cd app/AmbientApp && ./run.sh")
        console.log("═══════════════════════════════════════════════════════")
    }
}
