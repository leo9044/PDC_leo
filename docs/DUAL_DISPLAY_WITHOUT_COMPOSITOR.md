# Dual Display with Desktop-Shell - OTA-Safe Redundant Architecture

## Executive Summary

**검증된 Desktop-Shell 기반 단일 Weston Compositor 설계**

### 핵심 설계 원칙

1. **단일 Compositor**: Weston만 사용 (nested compositor 제거)
2. **독립 배치**: 각 앱이 자체 위치/크기 설정
3. **Redundancy**: 3개 앱에 모두 네비게이션 버튼 내장
4. **OTA-Safe**: 하나의 앱 업데이트 중에도 다른 앱으로 UI 제어 가능

---

## Architecture Overview

### Compositor Stack

```
기존 (Nested):
  Weston (wayland-0)
    └─ HU_MainApp_Compositor (wayland-1) ← 제거됨
         ├─ GearApp
         ├─ MediaApp
         └─ ...

신규 (Flat):
  Weston (desktop-shell) ← 유일한 Compositor
    ├─ GearApp (wayland-0)
    ├─ HomeScreenApp (wayland-0)
    ├─ MediaApp (wayland-0)
    └─ AmbientApp (wayland-0)
```

---

## Layout Design

### Display Layout (1920x1080)

```
┌─────────────────────────────────────────────┐
│ ┌─────┬──────────────────────────────────┐ │
│ │     │                                  │ │
│ │ G   │      Main Content Area          │ │
│ │ E   │      (HomeScreen/Media/Ambient) │ │
│ │ A   │      1790 x 920                 │ │
│ │ R   │                                  │ │
│ │     │                                  │ │
│ │ 130 ├──────────────────────────────────┤ │
│ │  x  │ Navigation Bar (80px)           │ │
│ │ 1000│ [Home] [Media] [Ambient]        │ │
│ └─────┴──────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Window Specifications

| App | X | Y | Width | Height | Z-Order | Notes |
|-----|---|---|-------|--------|---------|-------|
| GearApp | 0 | 0 | 130 | 1000 | Top | 항상 최상단 |
| HomeScreenApp | 130 | 0 | 1790 | 1000 | Normal | 버튼 포함 |
| MediaApp | 130 | 0 | 1790 | 1000 | Normal | 버튼 포함 |
| AmbientApp | 130 | 0 | 1790 | 1000 | Normal | 버튼 포함 |

---

## Redundancy Design (OTA-Safe)

### Problem: Single Point of Failure

기존 HU_MainApp_Compositor 방식:
- Compositor 앱 업데이트 시 전체 UI 제어 불가
- 단일 실패 지점

### Solution: Embedded Navigation in Each App

```
HomeScreenApp:
  ├─ Content (920px)
  └─ Nav Bar (80px): [Home*] [Media] [Ambient]

MediaApp:
  ├─ Content
  └─ Nav Bar: [Home] [Media*] [Ambient]

AmbientApp:
  ├─ Content
  └─ Nav Bar: [Home] [Media] [Ambient*]
```

### OTA Safety Matrix

| 업데이트 중 | 사용 가능 버튼 | 제어 가능? |
|-----------|--------------|----------|
| HomeScreenApp | MediaApp, AmbientApp | ✅ |
| MediaApp | HomeScreenApp, AmbientApp | ✅ |
| AmbientApp | HomeScreenApp, MediaApp | ✅ |
| GearApp | 모든 메인 앱 | ✅ |

**Result**: 최소 2개의 백업 제어 경로 항상 존재

---

## Why Desktop-Shell?

### Desktop-Shell vs IVI-Shell vs Kiosk-Shell

| Feature | Desktop-Shell | IVI-Shell | Kiosk-Shell |
|---------|--------------|-----------|-------------|
| **안정성** | ✅ NVIDIA 검증 | ❌ Weston 13 크래시 | ✅ 안정 |
| **레이아웃** | 앱별 자율 | 외부 Controller | 단일 앱만 |
| **OTA 안전성** | ✅ 독립 | ❌ Controller 의존 | N/A |
| **복잡도** | 낮음 | 높음 | 낮음 |
| **멀티 앱** | ✅ | ✅ | ❌ (1개만) |
| **듀얼 디스플레이** | ✅ | ✅ | ✅ |

### IVI-Shell 문제 (NVIDIA JetPack)

```bash
# IVI-Shell 시도
[core]
shell=ivi-shell.so
[ivi-shell]
ivi-module=ivi-controller.so  # ← Segmentation Fault

# 원인
Weston 13.0 (runtime) vs libweston-9 (ivi-controller built for)
→ ABI 불일치 → 크래시
```

**NVIDIA 입장**: Desktop-Shell 권장, IVI-Shell 미지원

### Kiosk-Shell 제약

- **단 하나의 fullscreen 앱만 허용**
- 우리는 4개 앱 필요 → 부적합

---

## Implementation

### 1. App Window Positioning

**GearApp (`app/GearApp/src/main.cpp`):**
```cpp
#include <QQuickWindow>

QQuickWindow *window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
if (window) {
    window->setGeometry(0, 0, 130, 1000);  // Left panel
    window->setFlags(Qt::Window | Qt::WindowStaysOnTopHint);  // Always on top
}
```

**HomeScreenApp/MediaApp/AmbientApp:**
```cpp
window->setGeometry(130, 0, 1790, 1000);  // Main area
```

### 2. Navigation Bar (QML)

**HomeScreenApp (`qml/HomeScreen.qml`):**
```qml
Window {
    width: 1790; height: 1000
    
    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 80  // Space for nav
        // Main content
    }
    
    Rectangle {
        id: navigationBar
        anchors.bottom: parent.bottom
        height: 80
        
        Row {
            Button { text: "Home"; enabled: false } // Current
            Button { text: "Media"; onClicked: { /* raise MediaApp */ } }
            Button { text: "Ambient"; onClicked: { /* raise AmbientApp */ } }
        }
    }
}
```

### 3. Weston Configuration

**`/etc/xdg/weston-13.0/weston.ini`:**
```ini
[core]
backend=drm-backend.so
shell=desktop-shell.so  # Stable
gbm-format=rgb565       # Bandwidth fix

[shell]
panel-position=none     # No system panel

[output]
name=DP-1
mode=1920x1080@60

# Future: Dual display with MST hub
# [output]
# name=DP-1-1
# mode=800x480@60
```

### 4. Startup Script

```bash
#!/bin/bash

# 1. Start Weston
weston --config=/etc/xdg/weston-13.0/weston.ini &
sleep 3

# 2. Start vsomeip routing
routingmanagerd &
sleep 2

# 3. Multicast route
sudo ip route add 224.0.0.0/4 dev enP8p1s0

# 4. Start apps
export WAYLAND_DISPLAY=wayland-0

cd app/HomeScreenApp && ./run_wayland0.sh &
sleep 1
cd app/MediaApp && ./run_wayland0.sh &
sleep 1
cd app/AmbientApp && ./run_wayland0.sh &
sleep 1
cd app/GearApp && ./run_wayland0.sh &  # Top layer last

echo "✅ All apps started"
```

---

## Dual Display (Future)

### Current: Single Display

```
DP-1 (1920x1080)
  ├─ GearApp (0,0, 130x1000)
  └─ MainApps (130,0, 1790x1000)
```

### Future: MST Hub Dual 7-inch

```
DP-1-1 (800x480) Left
  └─ GearApp fullscreen

DP-1-2 (800x480) Right
  └─ HomeScreen/Media/Ambient
```

**weston.ini (Future):**
```ini
[output]
name=DP-1-1
mode=800x480@60

[output]
name=DP-1-2
mode=800x480@60
```

**App Assignment:**
```cpp
// GearApp → DP-1-1
window->setScreen(QGuiApplication::screens()[0]);
window->setGeometry(0, 0, 800, 480);

// HomeScreenApp → DP-1-2
window->setScreen(QGuiApplication::screens()[1]);
```

---

## Advantages

### 1. OTA Resilience ✅
- 각 앱 독립 업데이트
- 3개 백업 제어 경로
- No single point of failure

### 2. Simplicity ✅
- Nested compositor 제거
- IVI-Shell 복잡도 제거
- 명확한 책임 분리

### 3. Stability ✅
- Desktop-Shell: NVIDIA 검증
- ivi-controller.so 크래시 회피
- 즉시 배포 가능

### 4. Scalability ✅
- 듀얼 디스플레이 준비
- 앱 추가/제거 용이
- vsomeip 느슨한 결합

---

## Migration from IVI-Shell

### Removed
1. IVILayoutController app
2. IVI-Shell weston.ini
3. QT_IVI_SURFACE_ID env vars
4. ivi-controller.so references

### Changed
1. App main.cpp: `setGeometry()` 추가
2. App QML: 네비게이션 바 추가
3. weston.ini: `shell=desktop-shell.so`
4. Startup: IVILayoutController 제거

---

## Testing Checklist

- [ ] Weston 시작 (desktop-shell)
- [ ] GearApp 왼쪽 패널 (최상단)
- [ ] HomeScreenApp 메인 영역 (버튼 포함)
- [ ] MediaApp 전환 가능
- [ ] AmbientApp 전환 가능
- [ ] vsomeip 내부 통신
- [ ] vsomeip 외부 통신 (ECU1)
- [ ] 개별 앱 재시작 시 다른 앱으로 제어 가능

---

## References

- Weston Desktop-Shell: https://wayland.pages.freedesktop.org/weston/
- NVIDIA JetPack: `/usr/share/doc/nvidia-l4t-weston/`
- Qt Wayland: https://doc.qt.io/qt-5/qtwaylandcompositor-index.html
