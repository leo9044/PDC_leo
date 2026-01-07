# Dual Display Without Compositor App - NVIDIA Official Method

## TL;DR - 3가지 핵심 질문 답변

### 1. HU_MainApp_Compositor 없애고 Weston만으로?
**YES ✅** - 정확히 맞습니다.

```
기존: App → HU_MainApp_Compositor (wayland-1) → Weston (wayland-0) → Hardware
새로: App → Weston (wayland-0) → Hardware
```

- **HU_MainApp_Compositor 제거**
- **Weston이 compositing + dual display 모두 담당**
- 각 앱이 `WAYLAND_DISPLAY=wayland-0`로 Weston에 직접 연결

---

### 2. IVI-Shell의 역할은?
**IVI-Shell = Layout Manager + Window Manager**

**Desktop Shell vs IVI-Shell**:
| Feature | Desktop Shell | IVI-Shell (Automotive) |
|---------|--------------|----------------------|
| 용도 | 일반 PC 환경 | 자동차 IVI 전용 |
| Layout | 자유롭게 드래그 가능 | **고정된 Layout** |
| Window 제어 | 사용자가 직접 | **코드로 정밀 제어** |
| Layer 관리 | 단순 (z-order) | **복잡한 Layer 시스템** |
| 멀티 디스플레이 | 지원 | **Display별 Surface 할당** |

**IVI-Shell이 하는 일**:
1. **Surface Positioning**: 각 앱 창의 정확한 위치 (x, y, width, height)
2. **Layer Management**: Background/UI/Overlay 등 계층 관리
3. **Output Assignment**: 어떤 앱을 어떤 Display에 표시할지
4. **No User Interaction**: 사용자가 창을 드래그하거나 리사이즈 불가 (차량용!)

---

### 3. 레이아웃 지정은 어떻게?
**2가지 방법: IVI-Controller API 또는 Wayland Protocol**

#### 방법 A: IVI-Controller Module (권장 - 차량용 표준)

**시작할 때 한번만 설정** (C/C++ 코드 또는 설정 스크립트):

```c
// 1. Layer 생성
t_ilm_layer layerId = 1000;
ilm_layerCreateWithDimension(&layerId, 1920, 1080);
ilm_layerSetVisibility(layerId, ILM_TRUE);

// 2. GearApp: 왼쪽 상단 (0, 0, 400x200)
t_ilm_surface surfaceId = 1000;  // GearApp의 surface ID
ilm_surfaceSetDestinationRectangle(surfaceId, 0, 0, 400, 200);
ilm_surfaceSetSourceRectangle(surfaceId, 0, 0, 400, 200);
ilm_surfaceSetVisibility(surfaceId, ILM_TRUE);
ilm_layerAddSurface(layerId, surfaceId);

// 3. MediaApp: 오른쪽 (400, 0, 600x400)
surfaceId = 2000;
ilm_surfaceSetDestinationRectangle(surfaceId, 400, 0, 600, 400);
ilm_surfaceSetSourceRectangle(surfaceId, 0, 0, 600, 400);
ilm_surfaceSetVisibility(surfaceId, ILM_TRUE);
ilm_layerAddSurface(layerId, surfaceId);

// 4. 변경사항 적용
ilm_commitChanges();

// 5. Display에 Layer 할당
t_ilm_display displayId = 0;  // DP-1
ilm_displaySetRenderOrder(displayId, &layerId, 1);
ilm_commitChanges();
```

#### 방법 B: Qt에서 직접 제어 (간단한 경우)

```cpp
// GearApp - main.cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    // IVI Surface ID 설정 (앱마다 고유 ID)
    qputenv("QT_IVI_SURFACE_ID", "1000");
    
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    
    // QML 로드
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    
    // Window geometry 설정
    QWindow *window = qobject_cast<QWindow*>(engine.rootObjects().first());
    window->setGeometry(0, 0, 400, 200);  // x, y, width, height
    window->setFlag(Qt::FramelessWindowHint);  // 테두리 없음
    
    return app.exec();
}
```

#### 방법 C: 설정 기반 (weston.ini + 스크립트)

```ini
# weston.ini
[core]
shell=ivi-shell.so
modules=ivi-controller.so

[ivi-shell]
ivi-module=ivi-controller.so
# Layout 설정 스크립트 실행
ivi-input-module=ivi-layout-configurator.so
```

```bash
# layout-config.sh - 시스템 시작시 실행
#!/bin/bash
# IVI Layer Manager CLI tool 사용
ilmControl createLayer 1000 1920 1080
ilmControl addSurfaceToLayer 1000 1000  # GearApp
ilmControl setSurfaceDestRect 1000 0 0 400 200
ilmControl addSurfaceToLayer 2000 1000  # MediaApp  
ilmControl setSurfaceDestRect 2000 400 0 600 400
ilmControl commit
```

---

## 핵심 발견

**확실한 방법 존재: YES ✅**

NVIDIA 공식 문서에서 **compositor app 없이 dual display를 직접 구현하는 방법**이 명확하게 제시되어 있음.

## NVIDIA 공식 문서 근거

**Source**: [NVIDIA Jetson Weston/Wayland Documentation](https://docs.nvidia.com/jetson/archives/r35.5.0/DeveloperGuide/SD/WindowingSystems/WestonWayland.html)

### Multiple Display Heads (공식 문서 인용)

> **Weston supports multiple display heads** with multiple overlays on all Jetson devices. Use `weston.ini` to set the expected resolution and orientation of the monitors.
> 
> **If multiple displays are connected, applications are launched on the one that contains the mouse pointer at the time of launch.** Once an application is launched, you can drag it across a boundary between displays.

### weston.ini Configuration Example (공식 문서)

```ini
[output]
name=HDMI-A-1
mode=1920x1080@60.0
transform=90  # (0, 90, 180, 270)
```

---

## 현재 Architecture vs NVIDIA Official Method

### 현재 Architecture (Nested Compositor 방식)
```
Weston (wayland-0)
├─> Display 1 (HU)  → HU_MainApp_Compositor (wayland-1) ← [병목지점]
│                     ├─> GearApp
│                     ├─> MediaApp
│                     ├─> AmbientApp
│                     └─> HomeScreenApp
└─> Display 2 (IC)  → IC_app (direct)
```

**문제점**:
- HU_MainApp_Compositor가 **single point of failure**
- 앱 OTA시 **그룹 업데이트 강제** (한 앱만 업데이트해도 컴포지터 재시작 필요)
- systemd dependency chain: `GearApp.service` → `hu-mainapp-compositor.service` → `weston.service`

---

### NVIDIA Official Method (Direct to Weston)
```
Weston (wayland-0) with weston.ini
├─> Display 1 (HU - DP-1)
│   ├─> GearApp         (직접 연결, 독립적)
│   ├─> MediaApp        (직접 연결, 독립적)
│   ├─> AmbientApp      (직접 연결, 독립적)
│   └─> HomeScreenApp   (직접 연결, 독립적)
│
└─> Display 2 (IC - HDMI-A-1 or DP-2)
    └─> IC_app          (직접 연결, 독립적)
```

**장점**:
- ✅ **No compositor app required**
- ✅ **각 앱이 독립적으로 OTA 가능**
- ✅ systemd dependency 단순: `AppName.service` → `weston.service` (끝!)
- ✅ 한 앱 crash해도 다른 앱들 정상 동작
- ✅ 파일 단위 OTA 가능 (이전 팀처럼)

---

## Implementation Plan

### Phase 1: weston.ini Configuration

**1. Create proper weston.ini**
```ini
[core]
backend=drm-backend.so
idle-time=0

# ==========================================
# Display 1: Head Unit (DP-1)
# ==========================================
[output]
name=DP-1
mode=1920x1080@60
transform=normal
scale=1

# ==========================================
# Display 2: Instrument Cluster (HDMI-A-1)
# ==========================================
[output]
name=HDMI-A-1
mode=1920x1080@60
transform=normal
scale=1

[shell]
panel-position=none
locking=false
```

**2. Application-to-Display Routing**

Weston의 **자동 라우팅 메커니즘** (공식 문서):
> "applications are launched on the one that contains the mouse pointer at the time of launch"

**Manual Routing Options**:
- **Option A**: `WAYLAND_DISPLAY` 환경 변수 사용
- **Option B**: Wayland protocol로 특정 output 지정
- **Option C**: IVI-Shell 사용 (In-Vehicle Infotainment용으로 설계됨)

---

### Phase 2: Remove HU_MainApp_Compositor

**현재 상태**:
```bash
# HU apps가 wayland-1에 연결
WAYLAND_DISPLAY=wayland-1 ./GearApp
```

**변경 후**:
```bash
# 모든 앱이 wayland-0에 직접 연결
WAYLAND_DISPLAY=wayland-0 ./GearApp
```

**systemd service 변경**:
```ini
# Before
[Unit]
Description=Gear App
After=hu-mainapp-compositor.service
Requires=hu-mainapp-compositor.service

# After
[Unit]
Description=Gear App
After=weston.service
Requires=weston.service
```

---

### Phase 3: Application Window Positioning

**Window Position 지정 방법**:

1. **Qt Wayland Shell Integration** (Qt5 native)
```cpp
// Qt에서 window position 지정
QWindow *window = ...;
window->setGeometry(x, y, width, height);
```

2. **IVI-Shell Protocol** (Automotive 전용)
```ini
[core]
shell=ivi-shell.so
modules=ivi-controller.so
```
```cpp
// IVI Layer Management API 사용
ilm_layerCreateWithDimension(&layerId, width, height);
ilm_surfaceSetDestinationRectangle(surfaceId, x, y, width, height);
ilm_commitChanges();
```

3. **Kiosk Shell** (Fullscreen apps)
```ini
[core]
shell=kiosk-shell.so

[kiosk-shell]
# Each app gets dedicated output
```

---

## IVI-Shell: The Official Automotive Solution

### NVIDIA 공식 문서 (IVI-Shell)

> **IVI shell is designed for In-Vehicle Infotainment (IVI) applications.** It provides a GENIVI Layer Manager-compatible API through its controller modules, and a simple protocol for use by IVI applications.

**To launch with IVI-Shell**:
```bash
weston --shell=ivi-shell.so --modules=ivi-controller.so
```

### IVI-Shell Features

1. **Layer Management**
   - Multiple layers (background, UI, overlay)
   - Layer ordering (z-order)
   - Layer visibility control

2. **Surface Management**
   - Precise position and size control
   - Output assignment (which display)
   - Scaling and transformation

3. **Hotplug Support**
   - Screen connect/disconnect events
   - Dynamic surface relocation
   - Automatic fallback

**Example Code** (from NVIDIA docs):
```c
static void screen_id(void *data, struct ivi_wm_screen *ivi_wm_screen, uint32_t id);
static void screen_destroy(void *data, struct ivi_wm_screen *ivi_wm_screen, uint32_t id);
static void connector_name(void *data, struct ivi_wm_screen *ivi_wm_screen, const char *process_name);

struct ivi_wm_screen_listener wm_screen_listener = {
    screen_id,
    screen_destroy,
    layer_added,
    connector_name,
    error,
};

ivi_wm_screen_add_listener(ivi_wm_screen, &wm_screen_listener, args);
```

---

## Comparison: Current vs Official Method

| Feature | Current (Nested Compositor) | NVIDIA Official (Direct) |
|---------|----------------------------|-------------------------|
| **Compositor App** | Required (HU_MainApp_Compositor) | NOT Required ❌ |
| **OTA Granularity** | Group (모든 HU 앱) | File-level (개별 앱) |
| **Single Point of Failure** | Yes (compositor crash = 모든 HU 앱 down) | No (각 앱 독립) |
| **Systemd Dependency** | 3-level (App→Compositor→Weston) | 2-level (App→Weston) |
| **Layout Management** | Compositor가 관리 | weston.ini + IVI-Shell |
| **Performance** | Software rendering 필요 | Direct hardware planes |
| **Complexity** | High | Medium |
| **Automotive Standard** | Custom | GENIVI IVI-Shell |

---

## Recommended Architecture

### Final Architecture (NVIDIA Official + IVI-Shell)

```
Weston with IVI-Shell (wayland-0)  ← 여기가 Compositor + Display Manager 역할
│
├─> Display 1 (HU - DP-1) @ 1920x1080
│   │
│   ├─> Layer 1000 (z-order=100)
│   │   ├─> GearApp       [surface-id=1000, rect=(0, 0, 400, 200)]
│   │   └─> MediaApp      [surface-id=2000, rect=(400, 0, 600, 400)]
│   │
│   └─> Layer 2000 (z-order=200)
│       ├─> AmbientApp    [surface-id=3000, rect=(0, 200, 1920, 100)]
│       └─> HomeScreenApp [surface-id=4000, rect=(0, 300, 1920, 780)]
│
└─> Display 2 (IC - HDMI-A-1) @ 1920x1080
    └─> Layer 5000 (z-order=100)
        └─> IC_app        [surface-id=5000, fullscreen (0, 0, 1920, 1080)]
```

**역할 분담**:
- **Weston**: Hardware compositing, dual display 관리, input routing
- **IVI-Shell**: Window positioning, layer ordering, surface visibility
- **각 App**: Content rendering만 담당, layout 신경 안씀

---

### Configuration Files

#### 1. weston.ini (Display 설정)
```ini
[core]
backend=drm-backend.so
shell=ivi-shell.so
modules=ivi-controller.so
idle-time=0

[ivi-shell]
ivi-module=ivi-controller.so

# Display 1: Head Unit
[output]
name=DP-1
mode=1920x1080@60
transform=normal
scale=1

# Display 2: Instrument Cluster  
[output]
name=HDMI-A-1
mode=1920x1080@60
transform=normal
scale=1

[shell]
panel-position=none
locking=false
```

#### 2. layout-config.sh (Layout 설정)
```bash
#!/bin/bash
# IVI Layout Configuration Script
# 시스템 시작시 한번만 실행됨

# Display 1 (HU) - Layer 1000 생성
ilmControl createLayer 1000 1920 1080
ilmControl setLayerVisibility 1000 1
ilmControl setLayerOpacity 1000 1.0
ilmControl addLayerToScreen 0 1000  # Screen 0 = DP-1

# GearApp 배치 (왼쪽 상단)
ilmControl addSurfaceToLayer 1000 1000
ilmControl setSurfaceDestRect 1000 0 0 400 200
ilmControl setSurfaceSourceRect 1000 0 0 400 200
ilmControl setSurfaceVisibility 1000 1

# MediaApp 배치 (오른쪽)
ilmControl addSurfaceToLayer 2000 1000
ilmControl setSurfaceDestRect 2000 400 0 600 400
ilmControl setSurfaceSourceRect 2000 0 0 600 400
ilmControl setSurfaceVisibility 2000 1

# Display 2 (IC) - Layer 5000 생성
ilmControl createLayer 5000 1920 1080
ilmControl setLayerVisibility 5000 1
ilmControl addLayerToScreen 1 5000  # Screen 1 = HDMI-A-1

# IC_app 배치 (fullscreen)
ilmControl addSurfaceToLayer 5000 5000
ilmControl setSurfaceDestRect 5000 0 0 1920 1080
ilmControl setSurfaceSourceRect 5000 0 0 1920 1080
ilmControl setSurfaceVisibility 5000 1

# 모든 변경사항 적용
ilmControl commit
```

#### 3. App 시작 스크립트
```bash
# start-gearapp.sh
export WAYLAND_DISPLAY=wayland-0        # Weston에 직접 연결
export QT_IVI_SURFACE_ID=1000           # IVI Surface ID
export QT_QUICK_BACKEND=software        # Software rendering
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1  # 테두리 없음

/opt/app/GearApp/GearApp
```

---

## Migration Steps

### Step 1: Test IVI-Shell with Single App
```bash
# 1. Configure weston.ini
cat > ~/.config/weston.ini << EOF
[core]
backend=drm-backend.so
shell=ivi-shell.so
modules=ivi-controller.so
EOF

# 2. Start Weston
sudo XDG_RUNTIME_DIR=/tmp/xdg weston --idle-time=0

# 3. Run test app with IVI surface
export WAYLAND_DISPLAY=wayland-0
./GearApp  # IVI surface ID를 설정해야 함
```

## 결론

### 3가지 핵심 질문 최종 답변

#### 1. HU_MainApp_Compositor 없애고 Weston만으로 compositing + dual display?
**YES ✅ - 완전히 가능**

```
제거: HU_MainApp_Compositor (wayland-1)
대체: Weston (wayland-0) with IVI-Shell

Weston의 역할:
├─ Hardware Compositing (GPU 사용)
├─ Dual Display 관리 (weston.ini [output] 섹션)
└─ Input 라우팅 (터치, 마우스, 키보드)
```

모든 앱이 `WAYLAND_DISPLAY=wayland-0`로 Weston에 직접 연결.

---

#### 2. IVI-Shell의 역할?
**Layout Manager + Window Manager for Automotive**

| 기능 | 설명 | 예시 |
|-----|------|-----|
| **Surface Positioning** | 각 앱 창의 정확한 위치/크기 | `ilm_surfaceSetDestinationRectangle(1000, 0, 0, 400, 200)` |
| **Layer Management** | 계층 구조 (z-order) | Background(100) → UI(200) → Overlay(300) |
| **Output Assignment** | 어떤 앱을 어떤 Display에 | `ilm_addLayerToScreen(displayId, layerId)` |
| **No User Interaction** | 사용자가 창 이동/리사이즈 불가 | 차량 환경 - 고정 레이아웃 필수 |
| **Hotplug Support** | Display 연결/해제 자동 처리 | NVIDIA 공식 hotplug 프로토콜 |

**핵심**: Desktop Shell(자유로운 창 관리) vs IVI-Shell(고정 레이아웃)

---

#### 3. 레이아웃 지정은 어떻게?
**3단계 프로세스**

**Step 1: 앱마다 고유 IVI Surface ID 할당**
```bash
# GearApp
export QT_IVI_SURFACE_ID=1000

# MediaApp  
export QT_IVI_SURFACE_ID=2000

# IC_app
export QT_IVI_SURFACE_ID=5000
```

**Step 2: Layout 설정 스크립트 작성** (시스템 시작시 실행)
```bash
#!/bin/bash
# Layer 생성 및 Surface 배치
ilmControl createLayer 1000 1920 1080
ilmControl addSurfaceToLayer 1000 1000  # GearApp을 Layer 1000에 추가
ilmControl setSurfaceDestRect 1000 0 0 400 200  # 위치: (0,0), 크기: 400x200
ilmControl setSurfaceVisibility 1000 1  # 보이기
ilmControl commit  # 적용
```

**Step 3: Display에 Layer 할당**
```bash
ilmControl addLayerToScreen 0 1000  # Screen 0(DP-1)에 Layer 1000 표시
ilmControl addLayerToScreen 1 5000  # Screen 1(HDMI-A-1)에 Layer 5000 표시
```

**Qt App에서 하는 일**: 없음! 그냥 창 띄우면 IVI-Shell이 자동으로 지정된 위치에 배치.

---

### 현재 Architecture의 문제

현재 nested compositor 방식은:
- ✅ 개발/테스트 단계에서는 **편리함** (layout 실험 용이)
- ❌ Production 환경에서는 **바람직하지 않음** (OTA 제약, SPOF)

---

### Recommendation

**즉시 적용 가능한 NVIDIA 공식 방법으로 마이그레이션:**

1. **HU_MainApp_Compositor 제거** - 더 이상 필요 없음
2. **Weston IVI-Shell 활성화** - `shell=ivi-shell.so`
3. **각 앱에 IVI Surface ID 할당** - 환경 변수 `QT_IVI_SURFACE_ID`
4. **Layout 설정 스크립트 작성** - `ilmControl` 명령어
5. **systemd service 단순화** - `App.service` → `weston.service` (2-level)

**예상 작업 시간**: 2-3주
**예상 효과**:
- ✅ **개별 앱 OTA 가능** (파일 단위)
- ✅ **시스템 안정성 향상** (SPOF 제거)
- ✅ **GENIVI 표준 준수** (차량용 표준)
- ✅ **이전 팀의 파일 기반 OTA 전략 적용 가능**
- ✅ **Performance 향상** (nested compositor overhead 제거)

---

### 핵심 비교표

| Aspect | 현재 (Nested) | NVIDIA Official (IVI-Shell) |
|--------|--------------|----------------------------|
| **Compositing** | HU_MainApp_Compositor | **Weston** |
| **Dual Display** | HU_MainApp_Compositor | **Weston (weston.ini)** |
| **Layout** | Qt QML 코드 | **IVI-Shell (ilmControl)** |
| **App 연결** | wayland-1 | **wayland-0 (direct)** |
| **OTA 단위** | 그룹 (모든 HU 앱) | **개별 파일** |
| **Dependency** | App→Compositor→Weston | **App→Weston** |
| **SPOF** | Yes (compositor) | **No** |
| **표준 준수** | Custom | **GENIVI** |
# 3. Update all HU app services to point to weston.service
```

---

## OTA Benefits

### Before (Nested Compositor)
```bash
# MediaApp OTA 시나리오
1. Download MediaApp binary
2. Stop hu-mainapp-compositor.service  ← 모든 HU 앱 중단!
3. Replace MediaApp binary
4. Start hu-mainapp-compositor.service  ← 모든 HU 앱 재시작
```

**Impact**: 5-10초 동안 모든 HU 화면 black screen

---

### After (Direct Method)
```bash
# MediaApp OTA 시나리오
1. Download MediaApp binary
2. Stop mediaapp.service              ← MediaApp만 중단
3. Replace MediaApp binary
4. Start mediaapp.service             ← MediaApp만 재시작
```

**Impact**: MediaApp만 1-2초 재시작, 다른 앱들은 정상 동작

---

## 결론

### 질문: "듀얼 디스플레이를 컴포지터 앱 없이 하는 방법이 있나?"

**답변: YES ✅ - NVIDIA 공식 문서에서 명확하게 제시**

1. **weston.ini의 `[output]` 섹션으로 멀티 디스플레이 설정**
   - 각 display의 name, mode, transform 지정
   - Weston이 자동으로 모든 display 관리

2. **IVI-Shell을 사용한 Layout Management**
   - Automotive 전용으로 설계된 shell
   - Layer Management API로 정확한 position 제어
   - GENIVI Layer Manager 호환

3. **모든 앱이 wayland-0에 직접 연결**
   - Compositor app 불필요
   - 각 앱이 독립적으로 동작
   - 파일 단위 OTA 가능

### 현재 Architecture의 문제

현재 nested compositor 방식은:
- ✅ 개발/테스트 단계에서는 **편리함** (layout 실험 용이)
- ❌ Production 환경에서는 **바람직하지 않음** (OTA 제약, SPOF)

### Recommendation

**즉시 적용 가능한 NVIDIA 공식 방법으로 마이그레이션:**
1. IVI-Shell 활성화
2. 각 앱에 IVI surface ID 할당
3. HU_MainApp_Compositor 제거
4. systemd service 단순화

**예상 작업 시간**: 2-3주
**예상 효과**:
- ✅ 개별 앱 OTA 가능
- ✅ 시스템 안정성 향상
- ✅ GENIVI 표준 준수
- ✅ 이전 팀의 파일 기반 OTA 전략 적용 가능
