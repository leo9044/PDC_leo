# Jetson Orin Nano 통합 계획서

**작성일:** 2025년 12월 30일  
**목적:** 분리된 2개의 ECU를 Jetson Orin Nano 단일 플랫폼으로 통합하며, PDC System과 OTA 기능을 염두한 확장 가능한 아키텍처 설계

---

## 📋 목차
1. [현재 시스템 분석](#1-현재-시스템-분석)
2. [통합 목표 및 전략](#2-통합-목표-및-전략)
3. [Jetson Orin Nano 통합 아키텍처](#3-jetson-orin-nano-통합-아키텍처)
4. [PDC System 통합 계획](#4-pdc-system-통합-계획)
5. [OTA 업데이트 시스템 설계](#5-ota-업데이트-시스템-설계)
6. [구현 로드맵](#6-구현-로드맵)
7. [리스크 및 해결 방안](#7-리스크-및-해결-방안)

---

## 1. 현재 시스템 분석

### 1.1 기존 2-ECU 아키텍처

```
ECU1 (RPi4 - 192.168.1.100)          ECU2 (RPi4 - 192.168.1.101)
┌──────────────────────────┐         ┌──────────────────────────┐
│ VehicleControlECU        │◄────────┤ HU_MainApp (Compositor)  │
│ - CommonAPI Provider     │ vsomeip │ - Wayland Kiosk          │
│ - vsomeip Host (Routing) │  over   │ - Qt5 Multi-Display      │
│ - CAN (MCP2518FD)        │ Ethernet├─────────────────────────┤
│ - Service 0x1234:0x5678  │         │ IC_app                   │
│ - PiRacer 제어           │         │ - CommonAPI Proxy        │
└──────────────────────────┘         ├─────────────────────────┤
                                      │ GearApp                  │
                                      ├─────────────────────────┤
                                      │ MediaApp                 │
                                      ├─────────────────────────┤
                                      │ AmbientApp               │
                                      └──────────────────────────┘
```

### 1.2 현재 시스템 특징

**강점:**
- ✅ 명확한 책임 분리 (차량 제어 vs UI)
- ✅ vsomeip 기반 네트워크 IPC로 물리적 분리 가능
- ✅ CommonAPI로 확장 가능한 서비스 구조

**약점:**
- ❌ Ethernet 네트워크 레이턴시 (UI 반응성 저하 가능)
- ❌ 두 개의 Raspberry Pi 필요 (비용, 전력 소모)
- ❌ 네트워크 불안정 시 전체 시스템 장애
- ❌ vsomeip Host 모드 충돌 관리 복잡

---

## 2. 통합 목표 및 전략

### 2.1 통합 목표

#### 주요 목표
1. **단일 하드웨어 플랫폼**: Jetson Orin Nano로 통합하여 비용/전력 절감
2. **성능 향상**: Ethernet 대신 로컬 IPC (UDS) 사용으로 레이턴시 감소
3. **확장성 확보**: PDC System, OTA 기능 추가를 위한 모듈화 아키텍처
4. **유지보수성**: 단일 플랫폼으로 디버깅 및 업데이트 간소화

#### 부차적 목표
- Jetson의 GPU 활용 (ML 기반 PDC 데이터 처리 가능)
- Docker/Container 기반 서비스 격리 (OTA 안정성)
- 실시간성 요구사항 충족 (CAN 통신)

### 2.2 통합 전략

#### 접근 방식: **논리적 분리 유지 + 물리적 통합**

```
기존: 물리적 분리 (2개 RPi) + 논리적 분리 (vsomeip over Ethernet)
         ↓
통합: 물리적 통합 (1개 Jetson) + 논리적 분리 (vsomeip over UDS + Process 격리)
```

**핵심 결정:**
1. **vsomeip 유지**: 기존 CommonAPI 코드 재사용
2. **Transport 변경**: Ethernet TCP → Unix Domain Socket
3. **Process 분리**: 각 ECU 기능을 별도 프로세스로 실행
4. **Systemd 기반 관리**: 서비스 간 의존성 및 재시작 정책

---

## 3. Jetson Orin Nano 통합 아키텍처

### 3.1 목표 시스템 구조

```
┌─────────────────────────────────────────────────────────────────────────┐
│              Jetson Orin Nano (Yocto Linux - meta-tegra)                 │
│              Kernel: Linux 5.10 (L4T), Init: systemd                     │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │               Routing Manager (routingmanagerd)                  │    │
│  │               - vsomeip Host Mode                                │    │
│  │               - /tmp/vsomeip-0 (UDS Endpoint)                    │    │
│  │               - Service Discovery 관리                           │    │
│  └───────┬───────────────────────────────────────────────────────┬──┘    │
│          │ UDS                                                    │ UDS   │
│  ┌───────▼──────────────────┐                    ┌────────────────▼────┐ │
│  │  VehicleControlService   │                    │  UI Applications    │ │
│  │  (Process 1)             │                    │  (Process 2-N)      │ │
│  │  ┌────────────────────┐  │                    │  ┌──────────────┐   │ │
│  │  │ CommonAPI Provider │  │                    │  │ HU_MainApp   │   │ │
│  │  │ - Service 0x1234   │  │                    │  │ (Wayland)    │   │ │
│  │  ├────────────────────┤  │                    │  ├──────────────┤   │ │
│  │  │ CAN Interface      │  │                    │  │ IC_app       │   │ │
│  │  │ - Jetson CAN0/1 or │  │                    │  ├──────────────┤   │ │
│  │  │ - MCP2518FD (SPI)  │  │                    │  │ GearApp      │   │ │
│  │  ├────────────────────┤  │                    │  ├──────────────┤   │ │
│  │  │ GPIO Control       │  │                    │  │ MediaApp     │   │ │
│  │  │ - Motor, Servo     │  │                    │  ├──────────────┤   │ │
│  │  ├────────────────────┤  │                    │  │ PDCApp       │   │ │
│  │  │ PDC Interface      │◄─┼────────────────────┼──┤ (NEW)        │   │ │
│  │  │ - Service 0x2345   │  │                    │  └──────────────┘   │ │
│  │  └────────────────────┘  │                    └─────────────────────┘ │
│  └──────────────────────────┘                    │ HDMI 1/2 (DP alt)    │
│          │ CAN Bus                                        │              │
│  ┌───────▼──────────────────┐                    ┌───────▼──────────────┐ │
│  │  Jetson Native CAN       │                    │  Dual Display Output │ │
│  │  (CAN0: /dev/can0)       │                    │  - HU: 1024x600      │ │
│  │  or MCP2518FD (SPI0)     │                    │  - IC: 1024x600      │ │
│  └──────────────────────────┘                    └──────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                   OTA Update Service (Systemd)                       │ │
│  │                   - MQTT Client (Subscriber)                         │ │
│  │                   - Image Verification (Hash/Signature)              │ │
│  │                   - A/B Partition Update (eMMC p2/p3)                │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                    │ WiFi/Ethernet                        │
│  ┌─────────────────────────────────▼───────────────────────────────────┐ │
│  │                        OTA Server (External)                         │ │
│  │                        - MQTT Broker (Mosquitto)                     │ │
│  │                        - Web Server (Update Images)                  │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  📦 Yocto Layers:                                                        │
│     - meta-tegra (Jetson BSP)                                            │
│     - meta-headunit (기존 레시피)                                         │
│     - meta-middleware (vsomeip, CommonAPI)                               │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 주요 설계 결정

#### 3.2.1 IPC 메커니즘 변경

| 항목 | 기존 (2-ECU) | 통합 (Jetson) |
|------|--------------|---------------|
| **Transport** | TCP (Ethernet) | UDS (Unix Domain Socket) |
| **vsomeip Config** | `"unicast": "192.168.1.101"` | `"local": { "enabled": true }` |
| **Routing Manager** | ECU2의 routingmanagerd | 단일 routingmanagerd |
| **레이턴시** | ~1-5ms | ~0.1ms |
| **대역폭** | 1Gbps (제한) | 무제한 (메모리 복사) |

#### 3.2.2 프로세스 분리 전략

**핵심 설계 철학: OTA를 위한 독립 업데이트 가능 단위**

프로세스 분리의 주요 목적:
1. **OTA 선택적 업데이트**: 특정 앱만 업데이트 가능 (전체 시스템 재부팅 불필요)
2. **격리된 크래시 처리**: 한 앱의 장애가 다른 앱에 영향 없음
3. **독립적인 버전 관리**: 각 앱이 별도의 버전 번호 유지

**총 프로세스 개수: 9개**

| # | 프로세스명 | 역할 | OTA 업데이트 단위 | 우선순위 |
|---|-----------|------|------------------|---------|
| 1 | `routingmanagerd` | vsomeip 라우팅 매니저 | ❌ (시스템 레벨) | Critical |
| 2 | `vehicle-control-service` | CAN, GPIO, 차량 제어 | ✅ 독립 업데이트 | Critical |
| 3 | `hu-compositor` | Wayland Compositor | ✅ 독립 업데이트 | High |
| 4 | `ic-app` | Instrument Cluster UI | ✅ 독립 업데이트 | High |
| 5 | `gear-app` | Gear Control UI | ✅ 독립 업데이트 | Medium |
| 6 | `media-app` | Media Player | ✅ 독립 업데이트 | Medium |
| 7 | `ambient-app` | Ambient Lighting | ✅ 독립 업데이트 | Low |
| 8 | `pdc-app` | Park Distance Control UI | ✅ 독립 업데이트 | High |
| 9 | `ota-client` | OTA 업데이트 클라이언트 | ❌ (부트로더 레벨) | Critical |

**선택지 분석:**

| 방식 | 장점 | 단점 | 선택 |
|------|------|------|------|
| **단일 프로세스** | 빠른 통신, 간단한 구조 | 격리 불가, 크래시 시 전체 다운, OTA 불가능 | ❌ |
| **멀티 프로세스 + vsomeip** | 논리적 분리 유지, 기존 코드 재사용, **OTA 선택적 업데이트** | vsomeip 오버헤드 | ✅ **채택** |
| **Docker 컨테이너** | 완벽한 격리, OTA 매우 용이 | 복잡도 증가, 리소스 오버헤드 | 🔶 차후 고려 |

**채택 이유:**
- 기존 CommonAPI/vsomeip 코드 최대한 재사용
- ECU1/ECU2 로직을 각각 독립 프로세스로 실행
- **OTA 시나리오 지원**: 예를 들어 `media-app`만 v1.2 → v1.3 업데이트 가능
- 향후 Docker 전환 용이 (vsomeip over UDS는 동일)

#### 3.2.3 Systemd 서비스 구조 및 OTA 전략

**시스템 시작 순서 (부팅 시):**

```
systemd
├── 1. vsomeip-routing.service     ⚙️ (최우선 시작)
│   └── routingmanagerd
│   └── PID: ~500, RAM: ~50MB
│
├── 2. vehicle-control.service      🚗 (routing 후 시작)
│   ├── Requires: vsomeip-routing.service
│   └── vehicle-control-service
│   └── PID: ~600, RAM: ~100MB
│
├── 3. headunit-compositor.service  🖥️ (vehicle-control 후 시작)
│   ├── Requires: vehicle-control.service
│   └── hu-compositor (Wayland)
│   └── PID: ~700, RAM: ~200MB
│
├── 4. headunit-apps.target         📱 (모든 UI 앱 그룹)
│   ├── ic-app.service              (PID: ~800, RAM: ~80MB)
│   ├── gear-app.service            (PID: ~900, RAM: ~50MB)
│   ├── media-app.service           (PID: ~1000, RAM: ~120MB)
│   ├── ambient-app.service         (PID: ~1100, RAM: ~40MB)
│   └── pdc-app.service             (PID: ~1200, RAM: ~60MB) ⭐ NEW
│
└── 5. ota-client.service           🔄 (백그라운드 데몬)
    └── ota-client --daemon
    └── PID: ~1300, RAM: ~30MB
    └── 역할: MQTT 구독, 업데이트 체크, 다운로드, 설치

총 메모리 사용량: ~730MB (Jetson 8GB 중 9%)
```

**OTA 업데이트 시나리오 예시:**

**시나리오 1: Media App만 업데이트 (v1.1 → v1.2)**
```bash
# OTA 서버에서 MQTT 메시지 발행
Topic: vehicle/updates/app/media-app
Payload: {
  "app": "media-app",
  "version": "1.2.0",
  "url": "https://ota.server/apps/media-app-1.2.0.tar.gz",
  "sha256": "abc123...",
  "restart_required": true
}

# Jetson에서 자동 처리
1. ota-client가 메시지 수신
2. /opt/apps/media-app-1.2.0.tar.gz 다운로드
3. 서명 검증 통과
4. systemctl stop media-app.service
5. 기존 바이너리 백업: /opt/apps/media-app.bak
6. 새 바이너리 설치: /opt/apps/media-app
7. systemctl start media-app.service
8. 30초 Health Check
   - 성공: 백업 삭제, 상태 보고
   - 실패: 롤백 (백업 복원 → 재시작)

⏱️ 총 소요 시간: ~2분 (다운로드 1분 + 설치 30초 + 검증 30초)
🔄 재부팅 필요 없음!
```

**시나리오 2: 시스템 전체 업데이트 (Full Image)**
```bash
Topic: vehicle/updates/system/full
Payload: {
  "type": "full",
  "version": "2.0.0",
  "url": "https://ota.server/images/jetson-headunit-2.0.0.img",
  "size": 4294967296,  # 4GB
  "sha256": "def456...",
  "target_slot": "B"
}

# A/B 파티션 업데이트
1. 현재 Slot A에서 실행 중
2. Slot B (/dev/mmcblk0p3)에 새 이미지 다운로드
3. 검증 후 부트플래그 변경
4. 재부팅 → Slot B로 부팅
5. Health Check (60초)
   - 성공: Slot B를 stable로 마킹
   - 실패: 자동 재부팅 → Slot A로 복귀

⏱️ 총 소요 시간: ~10분 (다운로드 5분 + 쓰기 3분 + 재부팅 2분)
🔄 재부팅 필요!
```

**프로세스별 업데이트 가능 여부:**

| 프로세스 | 개별 업데이트 | 재부팅 필요 | 다운타임 | OTA 패키지 크기 |
|---------|-------------|----------|---------|---------------|
| `routingmanagerd` | ❌ (시스템 이미지에 포함) | ✅ | ~2분 | - |
| `vehicle-control-service` | ✅ | ❌ | ~30초 | ~20MB |
| `hu-compositor` | ✅ | ❌ | ~1분* | ~50MB |
| `ic-app` | ✅ | ❌ | 0초 | ~30MB |
| `gear-app` | ✅ | ❌ | 0초 | ~15MB |
| `media-app` | ✅ | ❌ | 0초 | ~40MB |
| `ambient-app` | ✅ | ❌ | 0초 | ~10MB |
| `pdc-app` | ✅ | ❌ | 0초 | ~25MB |
| `ota-client` | ❌ (A/B 업데이트로만 가능) | ✅ | ~2분 | - |

*Compositor 재시작 시 모든 Wayland 클라이언트가 재연결 필요 (1초 내 자동 복구)

---

## 4. PDC System 통합 계획

### 4.1 PDC 요구사항 (프로젝트 명세 기반)

**기능 요구사항:**
- 초음파 센서로 장애물 거리 측정
- 거리에 따른 청각 피드백 (비프음 주기)
- Head Unit UI에 시각적 표시
- CAN 버스를 통한 센서 데이터 수신

**기술 요구사항:**
- Raspberry Pi (Jetson Orin Nano로 대체)
- CAN 인터페이스 (MCP2518FD 또는 Native CAN)
- Yocto 이미지 통합

### 4.2 PDC 시스템 아키텍처

```
┌────────────────────────────────────────────────────────────────┐
│                    PDC Data Flow                                │
└────────────────────────────────────────────────────────────────┘

  Ultrasonic           CAN Bus          VehicleControlService
    Sensors        ──────────►        (CommonAPI Provider)
     (MCU)           0x200-0x203            │
                                            │ FIDL: PDCService
                                            │ Service ID: 0x2345
                                            │
                                            ├─► PDCApp (UI)
                                            │   - 거리 시각화
                                            │   - 비프음 제어
                                            │
                                            └─► IC_app
                                                - 경고 표시
```

### 4.3 FIDL 인터페이스 정의

**신규 파일: `commonapi/fidl/PDCControl.fidl`**

```fidl
package vehicle.pdc

interface PDCControl {
    version {
        major 1
        minor 0
    }
    
    // 센서 데이터 구조체
    struct SensorData {
        Float front_left      // 전방 좌측 (cm)
        Float front_center
        Float front_right
        Float rear_left       // 후방 좌측
        Float rear_center
        Float rear_right
        UInt32 timestamp      // ms
    }
    
    // 경고 레벨
    enumeration WarningLevel {
        SAFE = 0x00           // > 100cm (녹색)
        CAUTION = 0x01        // 50-100cm (노란색)
        WARNING = 0x02        // 20-50cm (주황색)
        DANGER = 0x03         // < 20cm (빨간색)
    }
    
    // 브로드캐스트: 센서 데이터 업데이트 (10Hz)
    broadcast sensorDataChanged {
        out {
            SensorData data
        }
    }
    
    // 브로드캐스트: 경고 레벨 변경
    broadcast warningLevelChanged {
        out {
            WarningLevel level
        }
    }
    
    // 메서드: PDC 활성화/비활성화
    method setPDCEnabled {
        in {
            Boolean enabled
        }
        out {
            Boolean success
        }
    }
    
    // 속성: 현재 활성화 상태
    attribute Boolean isEnabled readonly
}
```

### 4.4 CAN 프레임 정의

| CAN ID | 데이터 | 주기 | 설명 |
|--------|--------|------|------|
| 0x200 | [FL, FC, FR, 0x00] | 100ms | 전방 센서 (cm, uint8) |
| 0x201 | [RL, RC, RR, 0x00] | 100ms | 후방 센서 (cm, uint8) |
| 0x202 | [WARNING_LEVEL, 0x00, ...] | 이벤트 | 경고 레벨 변경 |

**예시:**
```
CAN Frame: 0x200  [50, 45, 55, 00, 00, 00, 00, 00]
→ Front Left: 50cm, Front Center: 45cm, Front Right: 55cm
```

### 4.5 구현 세부사항

#### 4.5.1 VehicleControlService 확장

**파일: `app/VehicleControlECU/src/PDCControlStubImpl.cpp`** (신규)

```cpp
class PDCControlStubImpl : public PDCControlStub {
private:
    CANInterface& can_interface_;
    std::thread update_thread_;
    std::atomic<bool> enabled_{false};

public:
    void setPDCEnabled(bool enabled, bool& success) override {
        enabled_ = enabled;
        success = true;
        
        // CAN 필터 활성화/비활성화
        if (enabled) {
            can_interface_.addFilter(0x200, 0x7F0);  // 0x200-0x20F
        }
    }
    
    void processPDCData() {
        while (enabled_) {
            auto frame = can_interface_.read();
            
            if (frame.can_id == 0x200) {
                SensorData data;
                data.setFront_left(frame.data[0]);
                data.setFront_center(frame.data[1]);
                data.setFront_right(frame.data[2]);
                data.setTimestamp(getCurrentTime());
                
                // 브로드캐스트 발생
                fireSensorDataChangedEvent(data);
                
                // 경고 레벨 계산
                auto level = calculateWarningLevel(data);
                fireWarningLevelChangedEvent(level);
            }
            
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
    
    WarningLevel calculateWarningLevel(const SensorData& data) {
        float min_distance = std::min({
            data.getFront_left(), data.getFront_center(), 
            data.getFront_right()
        });
        
        if (min_distance < 20) return WarningLevel::DANGER;
        if (min_distance < 50) return WarningLevel::WARNING;
        if (min_distance < 100) return WarningLevel::CAUTION;
        return WarningLevel::SAFE;
    }
};
```

#### 4.5.2 PDCApp UI (QML)

**파일: `app/PDCApp/qml/PDCView.qml`** (신규)

```qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 1024
    height: 600
    color: "#1a1a1a"
    
    // CommonAPI Proxy (C++ Backend)
    property var pdcProxy: pdcManager.proxy
    
    // 센서 데이터
    property real frontLeft: 0
    property real frontCenter: 0
    property real frontRight: 0
    property int warningLevel: 0  // 0=SAFE, 1=CAUTION, 2=WARNING, 3=DANGER
    
    // 색상 매핑
    property var warningColors: ["#00FF00", "#FFFF00", "#FF8800", "#FF0000"]
    
    // 차량 윤곽 (Top View)
    Rectangle {
        id: vehicle
        width: 200
        height: 400
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        color: "#444444"
        border.color: "#FFFFFF"
        border.width: 2
        radius: 10
    }
    
    // 전방 센서 시각화
    Repeater {
        model: [
            {x: vehicle.x - 80, y: vehicle.y - 50, distance: frontLeft},
            {x: vehicle.x + vehicle.width/2 - 20, y: vehicle.y - 50, distance: frontCenter},
            {x: vehicle.x + vehicle.width + 20, y: vehicle.y - 50, distance: frontRight}
        ]
        
        Rectangle {
            x: modelData.x
            y: modelData.y
            width: 60
            height: 40
            color: warningColors[warningLevel]
            opacity: 0.7
            radius: 5
            
            Text {
                anchors.centerIn: parent
                text: modelData.distance.toFixed(0) + " cm"
                color: "#000000"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
    
    // 경고 텍스트
    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        text: {
            switch(warningLevel) {
                case 3: return "⚠️ DANGER - TOO CLOSE!"
                case 2: return "⚠️ WARNING - Slow Down"
                case 1: return "⚡ CAUTION"
                default: return "✓ Safe Distance"
            }
        }
        color: warningColors[warningLevel]
        font.pixelSize: 36
        font.bold: true
    }
    
    // Audio 피드백
    Timer {
        id: beepTimer
        interval: {
            switch(warningLevel) {
                case 3: return 200  // 빠른 비프
                case 2: return 500
                case 1: return 1000
                default: return 0
            }
        }
        running: warningLevel > 0
        repeat: true
        onTriggered: {
            audioPlayer.play("qrc:/sounds/beep.wav")
        }
    }
    
    // CommonAPI 연결
    Connections {
        target: pdcProxy
        
        function onSensorDataChanged(data) {
            frontLeft = data.front_left
            frontCenter = data.front_center
            frontRight = data.front_right
        }
        
        function onWarningLevelChanged(level) {
            warningLevel = level
        }
    }
}
```

### 4.6 Yocto 레시피 추가

**파일: `meta/meta-headunit/recipes-pdc/pdc-app/pdc-app_1.0.bb`**

```bitbake
SUMMARY = "Park Distance Control Application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=..."

DEPENDS = "qtbase qtdeclarative commonapi vsomeip"

SRC_URI = "file://src \
           file://qml \
           file://CMakeLists.txt"

S = "${WORKDIR}"

inherit cmake_qt5

FILES_${PN} += "${bindir}/pdc-app"

do_install_append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/pdc-app.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE_${PN} = "pdc-app.service"
```

---

## 5. OTA 업데이트 시스템 설계

### 5.1 OTA 요구사항 (프로젝트 명세 기반)

**기능 요구사항:**
- MQTT 기반 업데이트 알림 수신
- 전체 이미지 및 차등(delta) 업데이트 지원
- 업데이트 중 안전성 보장 (A/B 파티션)
- 업데이트 실패 시 롤백

**보안 요구사항:**
- 이미지 서명 검증 (RSA/ECDSA)
- 암호화된 전송 (TLS 1.3)
- 버전 다운그레이드 방지

### 5.2 A/B 파티션 전략

```
┌─────────────────────────────────────────────────────────────┐
│                 Jetson Orin Nano Storage                     │
├─────────────────────────────────────────────────────────────┤
│  /dev/mmcblk0p1  │  Boot Partition (U-Boot)                 │
│  /dev/mmcblk0p2  │  Slot A (Active) - rootfs_a              │
│  /dev/mmcblk0p3  │  Slot B (Inactive) - rootfs_b            │
│  /dev/mmcblk0p4  │  Data Partition (persistent, /data)      │
│  /dev/mmcblk0p5  │  OTA Cache (/opt/ota/cache)              │
└─────────────────────────────────────────────────────────────┘

Update Flow:
1. Boot from Slot A (current version 1.0)
2. Download new image (version 1.1) → write to Slot B
3. Verify Slot B integrity (hash + signature)
4. Update boot flag → set Slot B as active
5. Reboot → boot from Slot B
6. Health check (30 sec timeout)
   - Success: Mark Slot B as stable
   - Fail: Auto revert to Slot A
```

### 5.3 MQTT 토픽 구조

```
vehicle/
├── updates/
│   ├── available                  (Publish from Server)
│   │   └── Payload: {
│   │         "version": "1.2.0",
│   │         "type": "full|delta",
│   │         "url": "https://ota.example.com/images/v1.2.0.img",
│   │         "size": 512000000,
│   │         "sha256": "abc123...",
│   │         "signature": "..."
│   │       }
│   │
│   ├── status/<device_id>         (Subscribe from Server)
│   │   └── Payload: {
│   │         "state": "downloading|verifying|installing|success|failed",
│   │         "progress": 75,
│   │         "current_version": "1.1.0"
│   │       }
│   │
│   └── command/<device_id>        (Publish from Server)
│       └── Payload: {"cmd": "start_update|abort|rollback"}
│
└── telemetry/<device_id>          (Device → Server)
    └── Payload: {"cpu": 45, "mem": 60, "uptime": 3600}
```

### 5.4 OTA 클라이언트 구현

**파일: `app/OTAService/src/ota_client.cpp`** (신규)

```cpp
#include <mqtt/async_client.h>
#include <openssl/sha.h>
#include <openssl/rsa.h>
#include <systemd/sd-journal.h>

class OTAClient {
private:
    mqtt::async_client mqtt_client_;
    std::string device_id_;
    std::string current_version_;
    std::atomic<OTAState> state_{OTAState::IDLE};
    
public:
    OTAClient(const std::string& broker_url, const std::string& device_id)
        : mqtt_client_(broker_url, device_id),
          device_id_(device_id),
          current_version_(getSystemVersion()) {
        
        mqtt_client_.set_callback(*this);
        connectToBroker();
    }
    
    void connectToBroker() {
        auto connOpts = mqtt::connect_options_builder()
            .clean_session(true)
            .keep_alive_interval(std::chrono::seconds(30))
            .automatic_reconnect(true)
            .finalize();
        
        mqtt_client_.connect(connOpts)->wait();
        
        // 업데이트 알림 구독
        mqtt_client_.subscribe("vehicle/updates/available", 1);
        mqtt_client_.subscribe("vehicle/updates/command/" + device_id_, 1);
        
        sd_journal_print(LOG_INFO, "OTA Client connected to broker");
    }
    
    void message_arrived(mqtt::const_message_ptr msg) override {
        auto topic = msg->get_topic();
        auto payload = msg->to_string();
        
        if (topic == "vehicle/updates/available") {
            handleUpdateAvailable(payload);
        } else if (topic.find("command") != std::string::npos) {
            handleCommand(payload);
        }
    }
    
    void handleUpdateAvailable(const std::string& json_payload) {
        // JSON 파싱
        auto update_info = parseUpdateInfo(json_payload);
        
        // 버전 비교
        if (compareVersion(update_info.version, current_version_) <= 0) {
            sd_journal_print(LOG_INFO, "Update skipped: version not newer");
            return;
        }
        
        // 다운로드 시작
        state_ = OTAState::DOWNLOADING;
        publishStatus("downloading", 0);
        
        if (!downloadImage(update_info.url, "/opt/ota/cache/update.img")) {
            publishStatus("failed", 0, "Download failed");
            return;
        }
        
        // 검증
        state_ = OTAState::VERIFYING;
        publishStatus("verifying", 50);
        
        if (!verifyImage("/opt/ota/cache/update.img", 
                         update_info.sha256, 
                         update_info.signature)) {
            publishStatus("failed", 50, "Verification failed");
            return;
        }
        
        // 설치
        state_ = OTAState::INSTALLING;
        publishStatus("installing", 75);
        
        if (!installUpdate("/opt/ota/cache/update.img")) {
            publishStatus("failed", 75, "Installation failed");
            return;
        }
        
        publishStatus("success", 100);
        
        // 재부팅 예약
        scheduleReboot(30);  // 30초 후
    }
    
    bool verifyImage(const std::string& image_path,
                     const std::string& expected_hash,
                     const std::string& signature) {
        // SHA256 해시 계산
        unsigned char hash[SHA256_DIGEST_LENGTH];
        SHA256_File(image_path.c_str(), hash);
        
        std::string computed_hash = hexEncode(hash, SHA256_DIGEST_LENGTH);
        if (computed_hash != expected_hash) {
            sd_journal_print(LOG_ERR, "Hash mismatch: expected %s, got %s",
                           expected_hash.c_str(), computed_hash.c_str());
            return false;
        }
        
        // RSA 서명 검증
        auto public_key = loadPublicKey("/etc/ota/public_key.pem");
        return RSA_verify(hash, SHA256_DIGEST_LENGTH, 
                          signature.c_str(), signature.size(), 
                          public_key);
    }
    
    bool installUpdate(const std::string& image_path) {
        // 비활성 슬롯 결정 (A/B 파티션)
        auto inactive_slot = getInactiveSlot();  // /dev/mmcblk0p3
        
        // 이미지 쓰기 (dd 대신 직접 쓰기)
        std::ifstream src(image_path, std::ios::binary);
        std::ofstream dst(inactive_slot, std::ios::binary);
        
        dst << src.rdbuf();
        dst.flush();
        fsync(fileno(dst));
        
        // 부트 플래그 업데이트
        updateBootFlag(inactive_slot);
        
        return true;
    }
    
    void publishStatus(const std::string& state, int progress,
                      const std::string& error = "") {
        nlohmann::json status = {
            {"state", state},
            {"progress", progress},
            {"current_version", current_version_},
            {"device_id", device_id_},
            {"timestamp", std::time(nullptr)}
        };
        
        if (!error.empty()) {
            status["error"] = error;
        }
        
        mqtt_client_.publish(
            "vehicle/updates/status/" + device_id_,
            status.dump(),
            1,  // QoS 1
            false
        );
    }
};
```

### 5.5 OTA 서버 (Python/Flask)

**파일: `ota-server/server.py`** (신규 저장소)

```python
from flask import Flask, request, send_file, jsonify
import paho.mqtt.client as mqtt
import hashlib
import os
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding

app = Flask(__name__)
mqtt_client = mqtt.Client()

# MQTT 브로커 연결
mqtt_client.connect("localhost", 1883, 60)
mqtt_client.loop_start()

# 이미지 저장 디렉토리
IMAGE_DIR = "/var/ota/images"
PRIVATE_KEY_PATH = "/etc/ota/private_key.pem"

@app.route('/upload', methods=['POST'])
def upload_image():
    """새 업데이트 이미지 업로드 (웹 UI에서 호출)"""
    file = request.files['image']
    version = request.form['version']
    update_type = request.form['type']  # full or delta
    
    # 파일 저장
    image_path = os.path.join(IMAGE_DIR, f"{version}.img")
    file.save(image_path)
    
    # 해시 계산
    sha256_hash = calculate_sha256(image_path)
    
    # 서명 생성
    signature = sign_image(image_path, PRIVATE_KEY_PATH)
    
    # MQTT로 업데이트 알림 브로드캐스트
    payload = {
        "version": version,
        "type": update_type,
        "url": f"https://ota.example.com/images/{version}.img",
        "size": os.path.getsize(image_path),
        "sha256": sha256_hash,
        "signature": signature.hex()
    }
    
    mqtt_client.publish("vehicle/updates/available", 
                       json.dumps(payload), 
                       qos=2)  # QoS 2 (Exactly once)
    
    return jsonify({"status": "success", "version": version})

@app.route('/images/<version>', methods=['GET'])
def download_image(version):
    """클라이언트가 이미지 다운로드"""
    image_path = os.path.join(IMAGE_DIR, f"{version}.img")
    return send_file(image_path, as_attachment=True)

@app.route('/status', methods=['GET'])
def get_device_status():
    """모든 디바이스 상태 조회"""
    # Redis/DB에서 마지막 상태 조회
    devices = get_all_device_status()
    return jsonify(devices)

def calculate_sha256(file_path):
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            sha256.update(chunk)
    return sha256.hexdigest()

def sign_image(image_path, private_key_path):
    with open(private_key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    
    with open(image_path, 'rb') as f:
        image_data = f.read()
    
    signature = private_key.sign(
        image_data,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    
    return signature

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, ssl_context='adhoc')
```

### 5.6 웹 UI (관리자 페이지)

**파일: `ota-server/templates/index.html`**

```html
<!DOCTYPE html>
<html>
<head>
    <title>OTA Management Console</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .upload-form { border: 1px solid #ccc; padding: 20px; margin-bottom: 20px; }
        .device-list { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }
        .device-card { border: 1px solid #ddd; padding: 10px; border-radius: 5px; }
        .device-card.success { background-color: #d4edda; }
        .device-card.failed { background-color: #f8d7da; }
        .device-card.downloading { background-color: #fff3cd; }
    </style>
</head>
<body>
    <h1>🚗 Vehicle OTA Management</h1>
    
    <!-- 업데이트 업로드 -->
    <div class="upload-form">
        <h2>Upload New Update</h2>
        <form id="uploadForm" enctype="multipart/form-data">
            <label>Version: <input type="text" name="version" placeholder="1.2.0" required></label><br>
            <label>Type: 
                <select name="type">
                    <option value="full">Full Image</option>
                    <option value="delta">Delta Update</option>
                </select>
            </label><br>
            <label>Image File: <input type="file" name="image" accept=".img,.tar.gz" required></label><br>
            <button type="submit">Upload & Broadcast</button>
        </form>
    </div>
    
    <!-- 디바이스 상태 -->
    <h2>Connected Devices</h2>
    <div class="device-list" id="deviceList">
        <!-- 동적으로 생성 -->
    </div>
    
    <script>
        // 업로드 폼 제출
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            
            const response = await fetch('/upload', {
                method: 'POST',
                body: formData
            });
            
            const result = await response.json();
            alert(`Update ${result.version} broadcasted!`);
            loadDeviceStatus();
        });
        
        // 디바이스 상태 로드
        async function loadDeviceStatus() {
            const response = await fetch('/status');
            const devices = await response.json();
            
            const deviceList = document.getElementById('deviceList');
            deviceList.innerHTML = '';
            
            devices.forEach(device => {
                const card = document.createElement('div');
                card.className = `device-card ${device.state}`;
                card.innerHTML = `
                    <h3>${device.device_id}</h3>
                    <p>Version: ${device.current_version}</p>
                    <p>State: ${device.state}</p>
                    <p>Progress: ${device.progress}%</p>
                    <progress value="${device.progress}" max="100"></progress>
                `;
                deviceList.appendChild(card);
            });
        }
        
        // 5초마다 상태 업데이트
        setInterval(loadDeviceStatus, 5000);
        loadDeviceStatus();
    </script>
</body>
</html>
```

---

## 6. 구현 로드맵

### 🔧 OS 선택: Yocto vs Ubuntu 비교

| 항목 | Yocto (권장 ✅) | Ubuntu 22.04 + JetPack |
|------|----------------|------------------------|
| **장점** | • 기존 프로젝트와 일관성 유지<br>• 최소 크기 (불필요한 패키지 제외)<br>• 완전한 커스터마이징<br>• OTA 이미지 크기 최소화 (1-2GB)<br>• 보안 강화 (최소 attack surface) | • NVIDIA 공식 지원<br>• 빠른 초기 개발<br>• 많은 패키지 사용 가능<br>• CUDA 자동 설정 |
| **단점** | • 초기 빌드 시간 김 (4-8시간)<br>• Jetson BSP 통합 복잡<br>• 디버깅 어려움 | • 이미지 크기 큼 (8-10GB)<br>• 불필요한 패키지 많음<br>• 기존 Yocto 레시피 재작성 필요 |
| **이미지 크기** | 1-2GB | 8-10GB |
| **부팅 시간** | 15-20초 | 30-40초 |
| **OTA 다운로드** | 1-2분 (1GB @ 100Mbps) | 8-10분 (8GB @ 100Mbps) |
| **적합성** | ✅ 프로덕션, 임베디드 | 🔶 프로토타이핑, 개발 |

**최종 권장: Yocto 사용**

이유:
1. 기존 `meta-headunit`, `meta-instrumentcluster` 레이어 재사용
2. OTA 업데이트 시 이미지 크기가 중요 (네트워크 대역폭)
3. 프로덕션 환경에 적합

**하지만 단계적 접근 추천:**

```
Step 1 (개발): Ubuntu 22.04로 기능 검증 (2주)
              ↓ 모든 기능 동작 확인
Step 2 (마이그레이션): Yocto로 포팅 (1-2주)
              ↓ 레시피 작성 및 이미지 최적화
Step 3 (프로덕션): Yocto 이미지 배포
```

---

### Phase 0: Jetson Yocto 환경 구축 (1-2주) ⭐ 신규

#### Option A: NVIDIA JetPack + Yocto (하이브리드 - 추천)

**전략:** NVIDIA의 공식 L4T (Linux for Tegra) 베이스에 Yocto 레이어 추가

```bash
# 1. meta-tegra 레이어 사용 (NVIDIA Jetson용 Yocto BSP)
git clone https://github.com/OE4T/meta-tegra.git
cd meta-tegra
git checkout kirkstone  # Yocto 4.0 LTS

# 2. 기존 레이어 통합
mkdir -p jetson-headunit-build
cd jetson-headunit-build

# 3. bblayers.conf 설정
BBLAYERS ?= " \
  /path/to/poky/meta \
  /path/to/poky/meta-poky \
  /path/to/poky/meta-yocto-bsp \
  /path/to/meta-openembedded/meta-oe \
  /path/to/meta-openembedded/meta-python \
  /path/to/meta-qt5 \
  /path/to/meta-tegra \              # Jetson BSP
  /path/to/DES_Head-Unit/meta/meta-headunit \
  /path/to/DES_Head-Unit/meta/meta-middleware \
"

# 4. local.conf 설정
MACHINE = "jetson-orin-nano-devkit"
DISTRO = "poky"
INIT_MANAGER = "systemd"

# Jetson 특화 설정
PREFERRED_PROVIDER_virtual/kernel = "linux-tegra"
PREFERRED_PROVIDER_virtual/bootloader = "u-boot-tegra"

# GPU 지원 (선택적)
DISTRO_FEATURES_append = " x11 opengl vulkan"
PACKAGECONFIG_pn-qtbase = "eglfs gles2 kms"

# 5. 이미지 빌드
bitbake headunit-image
```

**예상 산출물:**
- `headunit-image-jetson-orin-nano.wic` (1.5GB)
- `headunit-image-jetson-orin-nano.tegraflash.tar.gz` (플래싱 패키지)

**장점:**
- ✅ NVIDIA 하드웨어 가속 지원 (GPU, VIC, NVENC)
- ✅ 기존 Yocto 레시피 재사용
- ✅ 공식 지원 (meta-tegra는 OE4T에서 유지보수)

**단점:**
- ⚠️ 초기 빌드 시간 길음 (4-8시간, 첫 빌드만)
- ⚠️ BSP 버전 호환성 확인 필요

#### Option B: 순수 Yocto (meta-tegra 없이)

**전략:** 처음부터 커스텀 커널 및 부트로더 빌드

- **난이도**: 매우 높음 ⚠️⚠️⚠️
- **시간**: 4-6주
- **권장 여부**: ❌ (시간 대비 효율 낮음)

#### Option C: Ubuntu 22.04 프로토타이핑 → Yocto 마이그레이션 (현실적 추천) ⭐

**전략: "빠른 검증 → 안정화 → 프로덕션 전환"**

이 접근법은 **디버깅 효율성**과 **개발 속도**를 최우선으로 합니다.

```
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1-2: Ubuntu 22.04 개발 환경 (Week 1-4)                     │
├─────────────────────────────────────────────────────────────────┤
│ 목표: 기능 검증 및 앱 개발                                        │
│                                                                   │
│ Week 1-2: 2-ECU → 1-ECU 통합                                     │
│   • JetPack 6.0 설치 (NVIDIA SDK Manager)                       │
│   • VehicleControlService + 기존 UI 앱 포팅                      │
│   • vsomeip UDS 통신 검증                                        │
│   • Dual HDMI 출력 확인                                          │
│   ✅ 결과: 기존 앱들이 Jetson에서 정상 동작                       │
│                                                                   │
│ Week 3-4: PDC 앱 개발 (Ubuntu 환경에서)                          │
│   • PDCControl.fidl 인터페이스 정의                              │
│   • VehicleControlService에 PDC Provider 추가                    │
│   • PDCApp UI 개발 (QML + CommonAPI Proxy)                       │
│   • CAN 시뮬레이터로 센서 데이터 테스트                           │
│   ✅ 결과: PDC 기능 완전히 검증됨                                 │
│                                                                   │
│ 💡 장점:                                                         │
│   - apt-get으로 빠른 패키지 설치                                 │
│   - GDB, Valgrind 등 디버깅 도구 즉시 사용                       │
│   - Qt Creator IDE 사용 가능                                     │
│   - 빠른 빌드 (증분 빌드 5-10초)                                 │
└─────────────────────────────────────────────────────────────────┘
           ↓ 모든 기능 검증 완료
┌─────────────────────────────────────────────────────────────────┐
│ Phase 3: Yocto 환경 구축 (Week 5-6, 병행 작업 가능)              │
├─────────────────────────────────────────────────────────────────┤
│ Week 5: Yocto 레시피 작성                                        │
│   • meta-tegra 레이어 클론 및 설정                               │
│   • 기존 meta-headunit 레시피를 Jetson용으로 수정                │
│   • PDCApp 레시피 추가 (recipes-pdc/pdc-app/)                    │
│   • 첫 Yocto 이미지 빌드 (4-8시간)                               │
│                                                                   │
│ Week 6: Ubuntu → Yocto 마이그레이션                              │
│   • Ubuntu에서 검증된 바이너리를 Yocto 이미지로 이전             │
│   • Systemd 서비스 파일 포팅                                     │
│   • vsomeip 설정 파일 복사                                       │
│   • 통합 테스트 (Yocto 이미지 부팅 → 모든 앱 동작 확인)          │
│   ✅ 결과: 프로덕션용 Yocto 이미지 완성                           │
│                                                                   │
│ 💡 장점:                                                         │
│   - 이미 검증된 코드를 포팅 (위험 최소화)                        │
│   - 최소 크기 이미지 (1-2GB)                                     │
│   - OTA 업데이트 효율적                                          │
└─────────────────────────────────────────────────────────────────┘
```

**왜 이 방법이 효율적인가?**

| 시나리오 | Ubuntu 먼저 | Yocto 바로 시작 |
|---------|-------------|----------------|
| **PDC 앱 버그 발견** | GDB로 즉시 디버깅 (5분) | 재빌드 → 플래싱 → 테스트 (1시간) |
| **Qt 라이브러리 문제** | apt-get install → 즉시 해결 | 레시피 수정 → 4시간 재빌드 |
| **CAN 드라이버 이슈** | dmesg, lsmod로 즉시 확인 | 커널 재빌드 (2시간) |
| **vsomeip 설정 오류** | 실시간 로그 확인 | 이미지 재생성 필요 |

**구체적 예시: PDC 앱 개발 시나리오**

```bash
# Ubuntu 환경에서 (빠른 반복 개발)
$ cd app/PDCApp
$ cmake -B build && cmake --build build
$ ./build/pdc-app
# 버그 발견 → 코드 수정 → 5초 후 재실행

# Yocto 환경에서 (시간 소요)
$ bitbake pdc-app          # 5-10분
$ dd if=tmp/deploy/images/jetson-orin-nano/headunit-image.wic of=/dev/sdX  # 3분
$ # SD 카드 교체 → 부팅 (30초) → 테스트
# 버그 발견 → 레시피 수정 → 10분 후 재빌드...
```

**마이그레이션 체크리스트:**

| 항목 | Ubuntu에서 확인할 것 | Yocto로 이전 시 필요한 것 |
|------|---------------------|-------------------------|
| **vsomeip** | UDS 통신 동작 여부 | `.json` 설정 파일 복사 |
| **Qt5 앱** | QML UI 렌더링 정상 | `.qrc`, `.qml` 파일 레시피에 추가 |
| **CAN 드라이버** | `/dev/can0` 접근 가능 | 커널 CONFIG 확인 |
| **Systemd** | 서비스 시작 순서 확인 | `.service` 파일 레시피에 포함 |
| **라이브러리** | ldd로 의존성 확인 | `DEPENDS` 항목에 추가 |

**최종 권장: Option C (Ubuntu 프로토타이핑 → Yocto 마이그레이션)**

**이유:**
1. ✅ **디버깅 효율성**: Ubuntu의 풍부한 도구 활용
2. ✅ **개발 속도**: 빠른 빌드-테스트 사이클
3. ✅ **위험 감소**: 기능 검증 후 Yocto 전환으로 실패 확률 낮춤
4. ✅ **학습 곡선**: Yocto를 나중에 배워도 늦지 않음

---

### Phase 1: 2-ECU 통합 및 기본 검증 (Week 1-2) - Ubuntu 환경

**목표: 현재 2개의 Raspberry Pi ECU를 Jetson Orin Nano 1대로 통합**

#### 1.1 하드웨어 준비
- [x] 현재 시스템 분석 완료
- [ ] **Jetson Orin Nano DevKit 구매 및 초기 설정**
  - [ ] 8GB RAM 모델 확인
  - [ ] 듀얼 HDMI 케이블 준비 (또는 HDMI + DisplayPort)
  - [ ] 전원 어댑터 (DC 19V 4.74A 또는 USB-C PD 15W)
  - [ ] microSD 카드 (64GB 이상, UHS-I Class 3)
  - [ ] 개발용 PC (Ubuntu 20.04/22.04 권장)

#### 1.2 Ubuntu 22.04 개발 환경 구축
- [ ] **JetPack 6.0 설치 (NVIDIA 공식 이미지)**
  ```bash
  # NVIDIA SDK Manager 다운로드
  # https://developer.nvidia.com/sdk-manager
  
  # 또는 직접 이미지 플래싱
  wget https://developer.nvidia.com/downloads/jetpack-60-dp
  sudo dd if=jetpack-6.0-image.img of=/dev/sdX bs=4M status=progress
  ```
  - [ ] 첫 부팅 후 네트워크 설정 (WiFi or Ethernet)
  - [ ] SSH 활성화 (`sudo systemctl enable ssh`)
  - [ ] 원격 접속 확인

- [ ] **개발 도구 설치**
  ```bash
  # 시스템 업데이트
  sudo apt update && sudo apt upgrade -y
  
  # 빌드 도구
  sudo apt install -y build-essential cmake git pkg-config
  
  # Qt5 개발 환경
  sudo apt install -y qtbase5-dev qtdeclarative5-dev \
                      qtquickcontrols2-5-dev qml-module-qtquick2 \
                      qml-module-qtquick-controls2
  
  # vsomeip 의존성
  sudo apt install -y libboost-all-dev libssl-dev
  
  # CommonAPI 도구
  # (기존 빌드된 라이브러리 사용 또는 소스 빌드)
  ```

#### 1.3 vsomeip 로컬 통신 전환 (Ethernet → UDS)

**기존 (2-ECU):**
```json
// ECU1: vsomeip_vehicle.json
{
  "unicast": "192.168.1.100",
  "routing": "vsomeipd",
  "applications": [
    { "name": "VehicleControl", "id": "0x1234" }
  ]
}
```

**통합 후 (Jetson):**
```json
// /etc/vsomeip/vsomeip-routing.json
{
  "unicast": "127.0.0.1",
  "diagnosis": "0x01",
  "diagnosis_mask": "0xFF",
  "routing": "routingmanagerd",
  "local": {
    "enabled": true,
    "unix_path": "/tmp/vsomeip-0"
  },
  "applications": [
    { "name": "VehicleControl", "id": "0x1234" },
    { "name": "IC_app", "id": "0x5001" },
    { "name": "GearApp", "id": "0x5002" },
    { "name": "MediaApp", "id": "0x5003" },
    { "name": "AmbientApp", "id": "0x5004" }
  ]
}
```

- [ ] vsomeip 설정 파일 수정 (기존 코드에서 복사 후 수정)
- [ ] Routing Manager 서비스 생성
  ```bash
  # /etc/systemd/system/vsomeip-routing.service
  [Unit]
  Description=vsomeip Routing Manager
  After=network.target
  
  [Service]
  Type=simple
  ExecStart=/usr/bin/routingmanagerd
  Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip-routing.json"
  Restart=always
  
  [Install]
  WantedBy=multi-user.target
  ```
- [ ] 서비스 활성화 및 시작
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable vsomeip-routing.service
  sudo systemctl start vsomeip-routing.service
  ```

#### 1.4 기존 앱들을 Jetson에 포팅 및 프로세스 분리

- [ ] **VehicleControlService 빌드 (Process 1)**
  ```bash
  cd app/VehicleControlECU
  mkdir build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release ..
  make -j$(nproc)
  sudo cp vehicle-control-service /usr/local/bin/
  ```
  - [ ] CAN 인터페이스 설정 (Jetson native CAN 또는 MCP2518FD)
  - [ ] GPIO 핀 매핑 확인
  - [ ] 서비스 파일 생성 (`vehicle-control.service`)

- [ ] **UI 애플리케이션 빌드 (Process 2-N)**
  ```bash
  # HU_MainApp (Compositor)
  cd app/HU_MainApp
  mkdir build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release ..
  make -j$(nproc)
  
  # 각 앱 동일하게 빌드
  # IC_app, GearApp, MediaApp, AmbientApp
  ```
  - [ ] 각 앱의 systemd 서비스 생성
  - [ ] 의존성 설정 (Requires, After)

#### 1.5 Dual HDMI 출력 검증
- [ ] **Wayland Compositor 듀얼 디스플레이 설정**
  ```bash
  # /etc/weston.ini (또는 HU_MainApp 내 설정)
  [core]
  modules=xwayland.so
  
  [output]
  name=HDMI-A-1
  mode=1024x600@60
  
  [output]
  name=HDMI-A-2
  mode=1024x600@60
  transform=normal
  ```
- [ ] 각 디스플레이에 앱 할당 확인
  - HDMI-1: HU_MainApp, GearApp, MediaApp
  - HDMI-2: IC_app
- [ ] 해상도 및 주사율 확인

#### 1.6 통합 테스트
- [ ] **모든 프로세스 시작 확인**
  ```bash
  systemctl status vsomeip-routing.service
  systemctl status vehicle-control.service
  systemctl status hu-compositor.service
  systemctl status ic-app.service
  # ...
  ```
- [ ] **vsomeip 통신 검증**
  - Gear 변경 시 VehicleControl 서비스 호출 확인
  - IC_app에서 속도 데이터 수신 확인
- [ ] **메모리 사용량 체크**
  ```bash
  free -h
  ps aux | grep -E 'vehicle|ic-app|gear'
  ```

✅ **Phase 1 완료 조건**: 기존 2-ECU 기능이 Jetson 1대에서 모두 정상 동작

---

### Phase 2: PDC 시스템 개발 (Week 3-4) - Ubuntu 환경에서 앱 개발

**목표: Ubuntu 환경에서 PDC 기능 완전히 개발 및 검증**

**💡 핵심 전략: Yocto로 가기 전에 Ubuntu에서 완벽하게 디버깅**

#### 2.1 PDC FIDL 인터페이스 정의
- [ ] **`commonapi/fidl/PDCControl.fidl` 작성**
  ```fidl
  package vehicle.pdc
  interface PDCControl {
      version { major 1 minor 0 }
      
      struct SensorData {
          Float front_left
          Float front_center
          Float front_right
          UInt32 timestamp
      }
      
      enumeration WarningLevel {
          SAFE = 0x00
          CAUTION = 0x01
          WARNING = 0x02
          DANGER = 0x03
      }
      
      broadcast sensorDataChanged {
          out { SensorData data }
      }
      
      method setPDCEnabled {
          in { Boolean enabled }
          out { Boolean success }
      }
  }
  ```
- [ ] **CommonAPI 코드 생성**
  ```bash
  cd commonapi
  ./generate_code.sh fidl/PDCControl.fidl
  # 생성: generated/v1/vehicle/pdc/PDCControl*.hpp
  ```

#### 2.2 VehicleControlService에 PDC Provider 구현
- [ ] **`app/VehicleControlECU/src/PDCControlStubImpl.cpp` 작성**
  - CAN 프레임 파싱 (0x200: 전방 센서, 0x201: 후방 센서)
  - 센서 데이터 브로드캐스트 (10Hz)
  - 경고 레벨 계산 로직
- [ ] **VehicleControlService에 통합**
  ```cpp
  // main.cpp
  auto pdcStub = std::make_shared<PDCControlStubImpl>(canInterface);
  runtime->registerService("local", "vehicle.pdc", pdcStub);
  ```
- [ ] **CAN 시뮬레이터로 테스트**
  ```bash
  # 가상 CAN 인터페이스 생성
  sudo ip link add dev vcan0 type vcan
  sudo ip link set up vcan0
  
  # 센서 데이터 송신 (테스트용)
  cansend vcan0 200#32282D00  # 50cm, 40cm, 45cm
  ```
- [ ] Ubuntu 환경에서 즉시 디버깅
  ```bash
  # GDB로 실시간 디버깅
  gdb --args ./vehicle-control-service
  (gdb) break PDCControlStubImpl::processPDCData
  (gdb) run
  ```

#### 2.3 PDCApp UI 구현 (QML + Qt5)
- [ ] **`app/PDCApp/` 디렉토리 생성**
- [ ] **`qml/PDCView.qml` 작성**
  - 차량 윤곽 (Top View)
  - 센서 거리 표시 (실시간 업데이트)
  - 경고 색상 변경 (SAFE → DANGER)
  - 비프음 효과
- [ ] **`src/main.cpp` - CommonAPI Proxy 연동**
  ```cpp
  auto proxy = runtime->buildProxy<PDCControlProxy>("local", "vehicle.pdc");
  proxy->getSensorDataChangedEvent().subscribe([](const SensorData& data) {
      qDebug() << "Front Left:" << data.getFront_left() << "cm";
      // QML로 데이터 전달
  });
  ```
- [ ] **Ubuntu에서 빠른 반복 개발**
  ```bash
  cd app/PDCApp
  cmake -B build && cmake --build build
  ./build/pdc-app  # 즉시 실행 및 테스트
  # 수정 → 재빌드 (5초) → 재실행
  ```

#### 2.4 오디오 피드백 구현
- [ ] Qt Multimedia로 비프음 재생
  ```qml
  import QtMultimedia 5.15
  
  Audio {
      id: beepSound
      source: "qrc:/sounds/beep.wav"
  }
  
  Timer {
      interval: warningLevel == 3 ? 200 : 1000
      running: warningLevel > 0
      repeat: true
      onTriggered: beepSound.play()
  }
  ```

#### 2.5 통합 테스트 (Ubuntu 환경)
- [ ] **CAN 시뮬레이터로 시나리오 테스트**
  ```bash
  # 시나리오 1: 안전 거리 → 경고
  while true; do
    cansend vcan0 200#64646400  # 100cm (SAFE)
    sleep 1
    cansend vcan0 200#32323200  # 50cm (CAUTION)
    sleep 1
    cansend vcan0 200#14141400  # 20cm (WARNING)
    sleep 1
    cansend vcan0 200#0A0A0A00  # 10cm (DANGER)
    sleep 2
  done
  ```
- [ ] UI 반응 확인 (색상 변화, 비프음)
- [ ] 메모리 누수 체크 (`valgrind --leak-check=full ./pdc-app`)

✅ **Phase 2 완료 조건**: PDC 앱이 Ubuntu에서 완벽하게 동작, 모든 버그 수정 완료

---

### Phase 3: Yocto 마이그레이션 (Week 5-6) - 프로덕션 이미지 생성

### Phase 3: Yocto 마이그레이션 (Week 5-6) - 프로덕션 이미지 생성

**목표: Ubuntu에서 검증된 모든 코드를 Yocto 이미지로 이식**

**💡 핵심: 이미 동작하는 코드를 포팅하므로 디버깅 최소화**

#### 3.1 Yocto 빌드 환경 구축
- [ ] **meta-tegra 레이어 클론**
  ```bash
  mkdir ~/jetson-yocto && cd ~/jetson-yocto
  git clone git://git.yoctoproject.org/poky.git -b kirkstone
  git clone https://github.com/openembedded/meta-openembedded.git -b kirkstone
  git clone https://github.com/meta-qt5/meta-qt5.git -b kirkstone
  git clone https://github.com/OE4T/meta-tegra.git -b kirkstone
  
  # 기존 레이어 링크
  ln -s /path/to/DES_Head-Unit/meta/meta-headunit .
  ln -s /path/to/DES_Head-Unit/meta/meta-middleware .
  ```

- [ ] **bblayers.conf 설정**
  ```bash
  cd poky
  source oe-init-build-env build-jetson
  
  # conf/bblayers.conf 편집
  BBLAYERS ?= " \
    ${TOPDIR}/../poky/meta \
    ${TOPDIR}/../poky/meta-poky \
    ${TOPDIR}/../meta-openembedded/meta-oe \
    ${TOPDIR}/../meta-openembedded/meta-python \
    ${TOPDIR}/../meta-qt5 \
    ${TOPDIR}/../meta-tegra \
    ${TOPDIR}/../meta-headunit \
    ${TOPDIR}/../meta-middleware \
  "
  ```

- [ ] **local.conf 설정**
  ```bash
  # conf/local.conf
  MACHINE = "jetson-orin-nano-devkit"
  DISTRO = "poky"
  INIT_MANAGER = "systemd"
  
  # Jetson 특화
  PREFERRED_PROVIDER_virtual/kernel = "linux-tegra"
  
  # Qt5 EGLFS 백엔드 (Wayland 대신 사용 가능)
  PACKAGECONFIG_pn-qtbase = "eglfs gles2 kms"
  
  # 개발 도구 포함 (디버깅용)
  EXTRA_IMAGE_FEATURES = "debug-tweaks tools-debug ssh-server-openssh"
  ```

#### 3.2 PDCApp Yocto 레시피 작성
- [ ] **`meta-headunit/recipes-pdc/pdc-app/pdc-app_1.0.bb`**
  ```bitbake
  SUMMARY = "Park Distance Control Application"
  LICENSE = "MIT"
  LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
  
  DEPENDS = "qtbase qtdeclarative qtmultimedia vsomeip commonapi-core commonapi-someip"
  
  SRC_URI = "file://src \
             file://qml \
             file://sounds \
             file://CMakeLists.txt \
             file://pdc-app.service"
  
  S = "${WORKDIR}"
  
  inherit cmake_qt5 systemd
  
  SYSTEMD_SERVICE_${PN} = "pdc-app.service"
  
  do_install_append() {
      install -d ${D}${systemd_system_unitdir}
      install -m 0644 ${WORKDIR}/pdc-app.service ${D}${systemd_system_unitdir}
      
      # 사운드 파일 설치
      install -d ${D}${datadir}/pdc-app/sounds
      install -m 0644 ${WORKDIR}/sounds/*.wav ${D}${datadir}/pdc-app/sounds/
  }
  
  FILES_${PN} += "${bindir}/pdc-app ${datadir}/pdc-app/*"
  ```

- [ ] **Ubuntu에서 검증된 소스 복사**
  ```bash
  mkdir -p meta-headunit/recipes-pdc/pdc-app/files
  cp -r ~/app/PDCApp/src meta-headunit/recipes-pdc/pdc-app/files/
  cp -r ~/app/PDCApp/qml meta-headunit/recipes-pdc/pdc-app/files/
  cp ~/app/PDCApp/CMakeLists.txt meta-headunit/recipes-pdc/pdc-app/files/
  ```

#### 3.3 기존 앱 레시피 Jetson용 수정
- [ ] **VehicleControl 레시피 업데이트**
  ```bitbake
  # meta-middleware/recipes-vehicle/vehicle-control/vehicle-control_1.0.bb
  
  # Jetson CAN 드라이버 추가
  DEPENDS_append = " linux-tegra"
  RDEPENDS_${PN}_append = " kernel-module-mcp251xfd"  # MCP2518FD 사용 시
  ```

- [ ] **모든 UI 앱 레시피 확인**
  - IC_app, GearApp, MediaApp, AmbientApp
  - Ubuntu에서 동작하는 버전과 동일한 소스 사용

#### 3.4 Yocto 이미지 빌드
- [ ] **첫 빌드 실행 (시간 소요)**
  ```bash
  bitbake headunit-image
  
  # 예상 시간: 4-8시간 (첫 빌드)
  # 증분 빌드: 5-30분 (소스 수정 후)
  ```

- [ ] **빌드 산출물 확인**
  ```bash
  ls tmp/deploy/images/jetson-orin-nano-devkit/
  # headunit-image-jetson-orin-nano-devkit.wic
  # headunit-image-jetson-orin-nano-devkit.tegraflash.tar.gz
  ```

#### 3.5 Yocto 이미지 플래싱 및 테스트
- [ ] **SD 카드에 플래싱**
  ```bash
  sudo dd if=tmp/deploy/images/jetson-orin-nano-devkit/headunit-image.wic \
          of=/dev/sdX \
          bs=4M \
          status=progress \
          conv=fsync
  ```

- [ ] **첫 부팅 및 검증**
  ```bash
  # SSH 접속
  ssh root@jetson-orin-nano.local
  
  # 서비스 상태 확인
  systemctl status vsomeip-routing
  systemctl status vehicle-control
  systemctl status pdc-app
  
  # 로그 확인
  journalctl -u pdc-app -f
  ```

- [ ] **기능 테스트**
  - [ ] 2-ECU 통합 기능 모두 동작 확인
  - [ ] PDC 앱 정상 동작 (CAN 시뮬레이터로 테스트)
  - [ ] Dual HDMI 출력 확인

#### 3.6 이미지 최적화
- [ ] **불필요한 패키지 제거**
  ```bitbake
  # local.conf
  IMAGE_INSTALL_remove = "packagegroup-core-x11 packagegroup-core-full-cmdline"
  ```
- [ ] **이미지 크기 확인**
  ```bash
  ls -lh tmp/deploy/images/jetson-orin-nano-devkit/*.wic
  # 목표: 1.5GB 이하
  ```

✅ **Phase 3 완료 조건**: Yocto 이미지에서 모든 기능이 Ubuntu와 동일하게 동작

---

### Phase 4: OTA 시스템 구현 (Week 7-9)

**목표: 안전하고 신뢰성 있는 OTA 업데이트 시스템 완성**

#### 4.1 A/B 파티션 구성
- [ ] **eMMC 파티셔닝 (Slot A, Slot B, Data)**
  ```bash
  # Jetson eMMC 구조
  /dev/mmcblk0p1  - Boot (U-Boot)
  /dev/mmcblk0p2  - Slot A (rootfs, 4GB)
  /dev/mmcblk0p3  - Slot B (rootfs, 4GB)
  /dev/mmcblk0p4  - Data (persistent, 나머지)
  ```
- [ ] **U-Boot 설정 수정 (boot flag 처리)**
  - Active slot 정보 저장 (U-Boot environment)
  - Health check 실패 시 롤백 로직

#### 4.2 OTA 클라이언트 개발
- [ ] MQTT 클라이언트 구현 (C++ or Python)
- [ ] 이미지 다운로드 + SHA256 검증
- [ ] A/B 업데이트 로직 (비활성 슬롯에 쓰기)
- [ ] 재부팅 후 Health Check (30초 타임아웃)

#### 4.3 OTA 서버 구축
- [ ] Flask 웹 서버 + MQTT 브로커 (Mosquitto)
- [ ] 관리자 웹 UI (업로드, 브로드캐스트)
- [ ] 이미지 서명 생성 (RSA 2048)

#### 4.4 보안 구현
- [ ] RSA 키 페어 생성 (public key를 Yocto 이미지에 포함)
- [ ] TLS 1.3 인증서 설정

#### 4.5 업데이트 시나리오 테스트
- [ ] 정상 업데이트 → 재부팅 → 검증
- [ ] 실패 업데이트 → 자동 롤백
- [ ] 앱 단위 업데이트 (재부팅 없이)

---

### Phase 5: 최적화 및 문서화 (Week 10)

**목표: 시스템 안정화 및 문서 완성**

#### 5.1 성능 프로파일링
- [ ] vsomeip UDS 레이턴시 측정
  - 목표: 0.5ms 이하
- [ ] CPU/메모리 사용량 모니터링
  - 전체 메모리 사용량 < 1GB (Jetson 8GB 중 12.5%)

#### 5.2 Systemd 서비스 안정화
- [ ] 자동 재시작 정책 (`Restart=on-failure`)
- [ ] Watchdog 타이머 설정 (30초)
- [ ] 서비스 의존성 순서 재검증

#### 5.3 문서 작성
- [ ] **배포 가이드**: Jetson 설정, Yocto 빌드, 플래싱
- [ ] **개발자 가이드**: 앱 추가 방법, 레시피 작성
- [ ] **OTA 사용 매뉴얼**: 서버 운영, 업데이트 절차
- [ ] **트러블슈팅 가이드**: 일반적인 문제 해결

---

## 7. 구현 요약: 3가지 핵심 요구사항 검증 ✅

### ✅ 1. 2-ECU → Jetson Orin Nano 통합

**포함 여부: YES**

- **Phase 1 (Week 1-2)**: 2개의 Raspberry Pi를 Jetson 1대로 통합
  - VehicleControlService (기존 ECU1)
  - 모든 UI 앱들 (기존 ECU2)
- **통신 방식 변경**: Ethernet TCP → Unix Domain Socket (UDS)
- **프로세스 분리**: 9개 독립 프로세스로 실행
  - OTA 선택적 업데이트를 위한 격리

**검증 방법:**
```bash
# 기존 (2-ECU)
RPi1: vehicle-control-service (192.168.1.100)
RPi2: ic-app, gear-app, media-app (192.168.1.101)

# 통합 후 (Jetson)
Jetson: 모든 프로세스가 /tmp/vsomeip-0 UDS로 통신
```

---

### ✅ 2. Yocto OS 사용

**포함 여부: YES**

- **Phase 0**: Yocto vs Ubuntu 비교 분석
  - Yocto 사용 권장 (이미지 크기 1-2GB, OTA 효율)
- **Phase 3 (Week 5-6)**: Yocto 이미지 빌드
  - meta-tegra (Jetson BSP)
  - meta-headunit (기존 레시피 재사용)
  - meta-middleware (vsomeip, CommonAPI)
- **빌드 설정 명시**:
  ```bash
  MACHINE = "jetson-orin-nano-devkit"
  bitbake headunit-image
  ```

**산출물:**
- `headunit-image-jetson-orin-nano.wic` (1.5GB)
- OTA 업데이트 이미지

---

### ✅ 3. Ubuntu 먼저 → Yocto 나중 (디버깅 효율)

**포함 여부: YES - 가장 강조됨!**

**Option C: Ubuntu 프로토타이핑 → Yocto 마이그레이션** (권장 접근법)

#### 구체적 일정:
```
Week 1-2 (Phase 1): Ubuntu 22.04 환경에서 2-ECU 통합
  - JetPack 6.0 설치
  - 기존 앱 포팅 및 검증
  - vsomeip UDS 통신 테스트
  ✅ 결과: 기존 기능 모두 동작

Week 3-4 (Phase 2): Ubuntu 환경에서 PDC 앱 개발
  - PDCControl.fidl 정의
  - VehicleControlService 확장
  - PDCApp UI 개발
  - GDB, Valgrind로 디버깅
  - 빠른 빌드-테스트 사이클 (5초)
  ✅ 결과: PDC 기능 완전 검증

Week 5-6 (Phase 3): Yocto 마이그레이션
  - meta-tegra 설정
  - 검증된 코드 레시피 작성
  - Yocto 이미지 빌드 (4-8시간)
  ✅ 결과: 프로덕션 이미지 완성
```

#### 디버깅 효율성 비교표:

| 작업 | Ubuntu 환경 | Yocto 직접 시작 | 시간 절감 |
|------|-------------|----------------|----------|
| PDC 버그 수정 | GDB로 5분 | 재빌드 1시간 | **92% 절감** |
| CAN 드라이버 테스트 | dmesg 즉시 | 커널 재빌드 2시간 | **99% 절감** |
| Qt QML 수정 | 5초 재컴파일 | 10분 재빌드 | **98% 절감** |

#### 마이그레이션 체크리스트 제공:

| 항목 | Ubuntu에서 확인 | Yocto 이전 시 |
|------|----------------|--------------|
| vsomeip | UDS 통신 OK | .json 복사 |
| Qt5 앱 | UI 렌더링 OK | .qml 레시피 추가 |
| CAN | /dev/can0 OK | CONFIG 확인 |

---

## 최종 확인 ✅✅✅

| # | 요구사항 | 문서 반영 | 위치 |
|---|---------|----------|------|
| 1️⃣ | **2-ECU → Jetson 통합** | ✅ YES | Phase 1 (Week 1-2) |
| 2️⃣ | **Yocto OS 사용** | ✅ YES | Phase 0 비교, Phase 3 빌드 |
| 3️⃣ | **Ubuntu 먼저 → Yocto 나중** | ✅ YES | Option C (강력 권장) |

**추가 강점:**
- PDC 앱 개발이 **Ubuntu 환경에서 먼저 이루어짐** (Phase 2)
- 디버깅 효율성을 **구체적 예시와 시간 비교**로 설명
- 마이그레이션 체크리스트로 **실무적 가이드** 제공
  - [ ] 자동 재시작 정책
  - [ ] Watchdog 타이머 설정
- [ ] 문서 작성
  - [ ] 배포 가이드 (Jetson 설정, 빌드, 실행)
  - [ ] OTA 사용 매뉴얼
  - [ ] 트러블슈팅 가이드

---

## 7. 리스크 및 해결 방안

### 7.1 기술적 리스크

| 리스크 | 확률 | 영향 | 완화 방안 |
|--------|------|------|----------|
| **vsomeip UDS 성능 저하** | 낮음 | 중간 | - UDS는 Ethernet보다 빠름<br>- 벤치마크 테스트 선행 |
| **Jetson GPU 드라이버 호환성** | 중간 | 높음 | - NVIDIA JetPack SDK 사용<br>- Qt5 EGLFS 백엔드 검증 |
| **OTA 업데이트 중 전원 손실** | 중간 | 매우 높음 | - A/B 파티션으로 안전성 보장<br>- Atomic write + fsync |
| **CAN 인터페이스 변경** | 높음 | 중간 | - MCP2518FD 드라이버 포팅<br>- 또는 Jetson Native CAN 사용 |
| **메모리 부족 (8GB)** | 낮음 | 중간 | - Swap 파일 구성 (4GB)<br>- 프로세스별 메모리 제한 |

### 7.2 프로젝트 리스크

| 리스크 | 완화 방안 |
|--------|----------|
| **개발 일정 지연** | - Phase별 마일스톤 설정<br>- 매주 진행 상황 체크 |
| **하드웨어 수급 문제** | - Jetson 대체 옵션 준비 (RPi5 또는 Xavier NX) |
| **OTA 보안 취약점** | - 코드 리뷰 + 침투 테스트<br>- OWASP IoT Top 10 준수 |

### 7.3 마이그레이션 리스크

**기존 코드 재사용률 목표: 90%**

| 변경 항목 | 재사용 가능 | 수정 필요 |
|-----------|-------------|----------|
| **CommonAPI FIDL** | ✅ 100% | - |
| **Qt5 QML UI** | ✅ 100% | 화면 해상도 조정 가능 |
| **VehicleControlECU 로직** | ✅ 95% | CAN 드라이버만 변경 |
| **vsomeip 설정** | ⚠️ 50% | Ethernet → UDS 전환 |
| **빌드 시스템** | ⚠️ 70% | Yocto → Native CMake |

---

## 8. 예상 시스템 성능

### 8.1 Jetson Orin Nano 사양

| 항목 | 사양 | 비고 |
|------|------|------|
| **CPU** | 6-core Arm Cortex-A78AE | RPi4 (4-core A72) 대비 50% 향상 |
| **GPU** | 1024-core NVIDIA Ampere | CUDA 가능 (PDC ML 처리) |
| **RAM** | 8GB LPDDR5 | RPi4 (4GB LPDDR4) 대비 2배 |
| **Storage** | 64GB eMMC | A/B 파티션 충분 |
| **Network** | GbE + WiFi 6 | OTA 다운로드 속도 향상 |
| **Display** | 2x HDMI 2.1 | 4K 지원 (현재 1024x600) |

### 8.2 성능 예측

| 메트릭 | 기존 (2-ECU) | 통합 (Jetson) | 개선율 |
|--------|--------------|---------------|--------|
| **IPC 레이턴시** | 1-5ms (TCP) | 0.1-0.5ms (UDS) | **90% 감소** |
| **기어 변경 응답** | 50-100ms | 10-20ms | **80% 감소** |
| **PDC 업데이트 주기** | 100ms (제약) | 10ms (가능) | **10배 향상** |
| **전력 소모** | 15W (2x RPi4) | 10W (Jetson) | **33% 감소** |
| **OTA 다운로드** | 100Mbps (Ethernet) | 1.2Gbps (WiFi 6) | **12배 향상** |

---

## 9. 결론 및 권장사항

### 9.1 핵심 요약

1. **기술적 타당성**: ✅ 매우 높음
   - vsomeip의 UDS 지원으로 코드 재사용 극대화
   - Jetson의 높은 성능으로 실시간성 개선

2. **비용 효율성**: ✅ 우수
   - 하드웨어 비용 50% 절감 (2x RPi4 → 1x Jetson)
   - 개발 비용 절감 (기존 코드 90% 재사용)

3. **확장성**: ✅ 뛰어남
   - PDC, OTA 외 추가 기능 통합 용이
   - GPU 활용 가능 (ADAS, 음성인식 등)

### 9.2 권장 접근법

**단계적 마이그레이션 (Incremental Migration)**

```
Week 1-2:  기본 통합 (VehicleControl + UI만)
              ↓
Week 3-4:  PDC 시스템 추가
              ↓
Week 5-7:  OTA 시스템 구현
              ↓
Week 8:    최적화 및 문서화
```

**대안 접근법: Docker 기반 (차후 고려)**

```
Jetson Orin Nano
├── docker-compose.yml
├── vsomeip-routing (Container 1)
├── vehicle-control (Container 2)
├── ui-compositor (Container 3)
└── ota-agent (Container 4)
```

- **장점**: 완벽한 격리, OTA 업데이트 간소화
- **단점**: 오버헤드 증가, vsomeip 네트워크 설정 복잡
- **권장 시점**: Phase 4 이후 리팩토링

### 9.3 추가 고려사항

1. **실시간성 요구사항**
   - CAN 통신 우선순위 높임 (`chrt` 명령으로 실시간 스케줄링)
   - VehicleControlService를 SCHED_FIFO로 실행

2. **전원 관리**
   - Jetson의 전력 모드 최적화 (5W, 10W, 15W 모드)
   - 차량 배터리 전압 모니터링 (저전압 시 안전 종료)

3. **네트워크 보안**
   - OTA MQTT 연결에 TLS 1.3 필수
   - 방화벽 설정 (iptables/nftables)

4. **백업 및 복구**
   - 공장 초기화 파티션 (/dev/mmcblk0p6)
   - 시리얼 콘솔 접근 유지 (UART)

---

## 10. 다음 단계

### 즉시 시작 가능한 작업
1. ✅ **이 문서 검토 및 승인**
2. [ ] Jetson Orin Nano 하드웨어 확보
3. [ ] 개발 환경 구축 (Ubuntu 22.04 + JetPack)
4. [ ] Git 브랜치 전략 수립 (`feature/jetson-integration`)

### 첫 번째 마일스톤 (2주 내)
- [ ] vsomeip UDS 통신 PoC (Proof of Concept)
- [ ] VehicleControlService 단독 실행 확인
- [ ] 간단한 Qt5 앱에서 Proxy 호출 성공

**질문이나 추가 논의 사항이 있으면 언제든 말씀해주세요!** 🚀
