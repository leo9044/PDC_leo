# 프로젝트 리뷰 - DES Head Unit

**작성일:** 2025년 12월 5일  
**목적:** 프로젝트 전체 구조 이해 및 학습 정리

---

## 1. 프로젝트 개요

### 아키텍처
```
┌─────────────────────────────────────────────────────────────┐
│                         ECU1 (RPi4)                          │
│  IP: 192.168.1.100 (Ethernet)                                │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  VehicleControlECU (C++ Service)                       │  │
│  │  - CommonAPI Provider                                  │  │
│  │  - vsomeip Host Mode (routing manager)                 │  │
│  │  - CAN 통신 (MCP2518FD)                                │  │
│  │  - Service ID: 0x1234:0x5678                           │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ vsomeip (SOME/IP)
                            │ Ethernet 192.168.1.0/24
                            │
┌─────────────────────────────────────────────────────────────┐
│                         ECU2 (RPi4)                          │
│  IP: 192.168.1.101 (Ethernet)                                │
│  IP: 192.168.86.100 (WiFi - SSH)                             │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  routingmanagerd (vsomeip daemon)                      │  │
│  │  - Host Mode                                            │  │
│  │  - /tmp/vsomeip-0 routing endpoint                     │  │
│  └────────────────────────────────────────────────────────┘  │
│                            │                                  │
│                            │ UDS (Unix Domain Socket)         │
│                            │                                  │
│  ┌─────────────┬──────────┴──────────┬──────────────────┐   │
│  │             │                     │                   │   │
│  │ HU_MainApp  │  IC_app  │ GearApp │ MediaApp │ etc... │   │
│  │ (Compositor)│          │         │          │        │   │
│  │             │          │         │          │        │   │
│  │ - Wayland   │ - Qt5    │ - Qt5   │ - Qt5    │ - Qt5  │   │
│  │ - Qt5       │ - CAPI   │ - CAPI  │ - CAPI   │ - CAPI │   │
│  │ - Kiosk     │ - Proxy  │ - Proxy │ - Proxy  │ - Proxy│   │
│  └─────────────┴──────────┴──────────┴──────────────────┘   │
│                                                               │
│  HDMI-1 (1024x600)          HDMI-2 (1024x600)                │
│  [Head Unit Display]        [Instrument Cluster]             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 핵심 기술 스택

### 2.1 Middleware

#### CommonAPI (3.2.4)
**역할:** 언어 독립적인 IPC API

**구조:**
```cpp
// FIDL 정의 (commonapi/fidl/VehicleControl.fidl)
interface VehicleControl {
    attribute VehicleState state  // 차량 상태 (기어, 속도, 배터리)
    method setGear(Gear gear)     // 기어 변경
}

// 생성된 코드 (commonapi/generated/)
- VehicleControlStub.hpp         // Provider 인터페이스
- VehicleControlProxy.hpp        // Consumer 인터페이스
- VehicleControlTypes.hpp        // 데이터 타입
```

**장점:**
- Transport 독립적 (SOME/IP, D-Bus 등 교체 가능)
- 타입 안전성
- 자동 코드 생성

---

#### vsomeip (3.5.8)
**역할:** SOME/IP 프로토콜 구현

**주요 개념:**
1. **Routing Manager (Host Mode)**
   - 전체 vsomeip 통신의 중앙 관리자
   - `/tmp/vsomeip-0` Unix Domain Socket 생성
   - Service Discovery 멀티캐스트 관리
   - ECU1: VehicleControlECU가 Host
   - ECU2: routingmanagerd가 Host

2. **Application (Proxy Mode)**
   - Routing Manager에 연결하여 통신
   - 로컬 통신: UDS (Unix Domain Socket)
   - 외부 통신: Routing Manager를 통해 TCP/UDP

3. **Service Discovery**
   - 멀티캐스트 주소: 224.244.224.245:30490
   - Service 등록/탐색 자동화
   - OFFER/REQUEST 메커니즘

**설정 파일 구조:**
```json
{
  "unicast": "192.168.1.101",           // 자신의 IP
  "netmask": "255.255.255.0",
  "diagnosis": "0x6301",                 // 진단 주소
  
  "applications": [
    {
      "name": "GearApp",                 // VSOMEIP_APPLICATION_NAME과 매칭
      "id": "0x6301"                      // Application ID (유니크)
    }
  ],
  
  "routing": "routingmanagerd",          // Host 모드 활성화 (없으면 Proxy)
  
  "service-discovery": {
    "enable": true,
    "multicast": "224.244.224.245",
    "port": 30490,
    "protocol": "udp"
  },
  
  "services": [
    {
      "service": "0x1234",               // Service ID
      "instance": "0x5678",              // Instance ID
      "unreliable": "30509"              // UDP 포트
    }
  ]
}
```

**중요 발견:**
- systemd 환경에서 `VSOMEIP_APPLICATION_NAME` 환경 변수 **필수**
- 없으면 Host 모드 설정이 무시되고 Proxy 모드로 실행됨

---

### 2.2 Graphics Stack

#### Wayland + Weston
**역할:** Display Server (X11 대체)

**구조:**
```
┌─────────────────────────────────────────────┐
│  Weston (Wayland Compositor)                │
│  - DRM Backend (직접 GPU 제어)              │
│  - Kiosk Shell (전체화면 앱 관리)           │
│  - Multi-output (HDMI-1, HDMI-2)            │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼────────┐    ┌────────▼────────┐
│ HU_MainApp     │    │ IC_app          │
│ (Compositor)   │    │ (Wayland Client)│
│                │    │                 │
│ ┌────────────┐ │    │ - Qt5 Wayland  │
│ │ Wayland    │ │    │ - EGLFS-KMS    │
│ │ Server     │ │    │                 │
│ └────────────┘ │    └─────────────────┘
│       │        │
│   ┌───▼─────┐  │    HDMI-2
│   │ GearApp │  │    (1024x600)
│   │ MediaApp│  │
│   │ etc...  │  │
│   └─────────┘  │
│                │
│   HDMI-1       │
│   (1024x600)   │
└────────────────┘
```

**Kiosk Shell 설정 (`weston.ini`):**
```ini
[core]
shell=kiosk-shell.so           # 전체화면 전용
backend=drm-backend.so         # 하드웨어 가속

[output]
name=HDMI-A-1
app-ids=HU_MainApp_Compositor  # 실행 파일 이름과 매칭 필수!

[output]
name=HDMI-A-2
app-ids=IC_app
```

**주요 이슈:**
- `app-ids`가 실제 실행 파일 이름과 정확히 일치해야 함
- Qt 앱의 app-id는 QGuiApplication::applicationName() 또는 실행 파일명

---

### 2.3 Build System - Yocto

#### Layer 구조
```
meta/
├── meta-headunit/              # ECU2 전용
│   ├── recipes-apps/           # Qt 앱들
│   ├── recipes-core/
│   │   ├── images/
│   │   │   └── headunit-image.bb
│   │   └── systemd/
│   │       └── files/
│   │           ├── 20-wired-static.network  # WiFi
│   │           └── 20-eth0.network          # Ethernet
│   └── recipes-graphics/
│       └── weston/
│           └── weston-init/
│               └── weston.ini
│
├── meta-middleware/            # 공통 미들웨어
│   └── recipes-comm/
│       ├── commonapi/
│       ├── vsomeip/
│       └── vsomeip-routingmanager/
│
└── meta-vehiclecontrol/        # ECU1 전용
    └── recipes-vehiclecontrol/
        └── vehiclecontrol-ecu/
```

#### 핵심 레시피 패턴

**1. EXTERNALSRC 사용 (로컬 개발)**
```bash
EXTERNALSRC = "/home/seame/ChangGit2/DES_Head-Unit/app/GearApp"
EXTERNALSRC_BUILD = "${EXTERNALSRC}/build-x86"

inherit externalsrc
```
- 소스 수정 시 자동 재빌드
- Git 의존성 없음

**2. systemd 서비스 통합**
```bash
inherit systemd

SYSTEMD_SERVICE:${PN} = "gearapp.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/gearapp.service ${D}${systemd_system_unitdir}/
}
```

**3. 네트워크 설정 통합**
```bash
# systemd_%.bbappend
do_install:append() {
    install -d ${D}${systemd_unitdir}/network
    install -m 0644 ${WORKDIR}/20-eth0.network ${D}${systemd_unitdir}/network/
}
```

---

## 3. 통신 흐름 분석

### 3.1 Service Discovery
```
ECU1 (VehicleControlECU)                ECU2 (Apps)
     │                                       │
     │  1. OFFER (0x1234:0x5678)             │
     ├──────────────────────────────────────>│
     │  Multicast: 224.244.224.245:30490     │
     │                                       │
     │  2. Service Available 이벤트          │
     │<──────────────────────────────────────┤
     │                                       │
     │  3. TCP Connection (30509)            │
     │<─────────────────────────────────────>│
     │                                       │
```

### 3.2 데이터 전송
```
CAN Bus                ECU1                    ECU2
   │                    │                       │
   │  1. CAN Frame      │                       │
   ├───────────────────>│                       │
   │  (속도 데이터)     │                       │
   │                    │                       │
   │                    │  2. CommonAPI Event   │
   │                    │  (vehicleStateChanged)│
   │                    ├──────────────────────>│
   │                    │  vsomeip SOME/IP      │
   │                    │                       │
   │                    │  3. Qt Signal         │
   │                    │                       │<─ QML 업데이트
   │                    │                       │
```

---

## 4. 주요 트러블슈팅 사례

### 4.1 VSOMEIP_APPLICATION_NAME 환경 변수

**문제:**
- ECU1이 Proxy 모드로 실행됨
- 로그: `Couldn't connect to: /tmp/vsomeip-0`

**원인:**
- systemd 서비스에서 환경 변수 누락
- 설정 파일의 `"routing": "VehicleControlECU"` 무시됨

**해결:**
```ini
# vehiclecontrol-ecu.service
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"
```

**교훈:**
- vsomeip는 설정 파일만으로 충분하지 않음
- 환경 변수로 명시적 지정 필요

---

### 4.2 routingmanagerd 바이너리 없음

**문제:**
- vsomeip 패키지 설치 후 `routingmanagerd` 실행 불가

**원인:**
- vsomeip 기본 빌드는 examples 포함 안 함
- routingmanagerd는 examples/routingmanagerd/에만 존재

**해결:**
```bash
# vsomeip_3.5.8.bb
EXTRA_OECMAKE += "-DBUILD_EXAMPLES=ON"

do_install:append() {
    install -m 0755 ${B}/examples/routingmanagerd/routingmanagerd ${D}${bindir}/
}
```

---

### 4.3 Weston Kiosk Shell 앱 실행 안됨

**문제:**
- 부팅 시 터미널 창만 뜸

**원인:**
- `weston.ini`의 `app-ids`가 실행 파일 이름과 불일치

**해결:**
```ini
# 실행 파일: HU_MainApp_Compositor
app-ids=HU_MainApp_Compositor  # (X) HeadUnitApp
```

---

## 5. 성능 및 리소스

### 빌드 시간
- 전체 이미지 (초기): ~2-3시간
- 증분 빌드: ~5-15분
- 단일 레시피 재빌드: ~1-3분

### 이미지 크기
- vehiclecontrol-image: ~1.1GB
- headunit-image: ~1.3GB

### 런타임 메모리 (ECU2)
```
VehicleControlECU:    ~15MB
routingmanagerd:      ~8MB
HU_MainApp_Compositor: ~45MB
IC_app:               ~35MB
GearApp:              ~25MB
각 앱:                ~20-30MB
```

---

## 6. 학습 포인트

### 6.1 미들웨어 아키텍처
- **Service-Oriented Architecture (SOA)**: 기능을 서비스 단위로 분리
- **IPC 추상화**: CommonAPI로 transport 독립성 확보
- **Service Discovery**: 동적 서비스 탐색으로 유연성

### 6.2 임베디드 리눅스
- **Yocto Layer**: 관심사 분리 (앱/미들웨어/BSP)
- **systemd**: 서비스 의존성 관리
- **systemd-networkd**: 선언적 네트워크 설정

### 6.3 Wayland 생태계
- **Client-Server 분리**: 보안 및 안정성
- **Multi-output**: 독립적인 디스플레이 제어
- **Kiosk Mode**: 자동차 특화 UI

---

## 7. 개선 가능 영역

### 7.1 보안
- [ ] vsomeip 인증 추가 (credential passing)
- [ ] TLS/DTLS 암호화
- [ ] Wayland 샌드박싱

### 7.2 성능
- [ ] Zero-copy IPC (shared memory)
- [ ] vsomeip 스레드 풀 튜닝
- [ ] Qt QML 컴파일 캐싱

### 7.3 안정성
- [ ] Watchdog 통합
- [ ] 자동 로그 로테이션
- [ ] OTA 업데이트 지원

---

## 8. 참고 자료

### 공식 문서
- [vsomeip Documentation](https://github.com/COVESA/vsomeip/wiki)
- [CommonAPI Documentation](https://covesa.github.io/capicxx-core-tools/)
- [Yocto Project](https://docs.yoctoproject.org/)
- [Wayland Protocol](https://wayland.freedesktop.org/docs/html/)

### 프로젝트 문서
- `docs/ECU2_TESTING_GUIDE.md`: 구현 상세 가이드
- `docs/CHANGELOG_20251204_VSOMEIP_EXTERNAL_COMM.md`: 변경 사항 상세
- `docs/VSOMEIP_RASPIOS_IMPLEMENTATION_GUIDE.md`: vsomeip 초기 구현

---

**다음 단계:**
1. 불필요한 파일 정리
2. GitHub README 작성
3. 발표 자료 준비
