# Raspberry Pi 배포 종합 가이드

> **통합 문서**: 이 가이드는 배포 절차, 리팩토링 계획, 트러블슈팅을 모두 포함합니다.

## 📋 목차
1. [시스템 아키텍처](#시스템-아키텍처)
2. [프로젝트 현황 및 리팩토링 계획](#프로젝트-현황-및-리팩토링-계획)
3. [배포 순서](#배포-순서)
4. [트러블슈팅](#트러블슈팅)
5. [systemd 서비스 등록](#systemd-서비스-등록)
6. [다음 단계](#다음-단계)

---

## 시스템 아키텍처

### ECU 구성
- **ECU1 (Raspberry Pi #1)**: VehicleControlECU (PiRacer 제어)
  - IP: `192.168.1.100`
  - 역할: Service Provider (vsomeip routing manager)
  - 서비스: VehicleControl (0x1234:0x5678)
  - RPC: changeGear
  - Events: gearChanged, vehicleStateChanged

- **ECU2 (Raspberry Pi #2)**: Head-Unit Applications
  - IP: `192.168.1.101`
  - 역할: Service Consumers
  - **HU 디스플레이:**
    - GearApp (VehicleControl 클라이언트)
    - AmbientApp (VehicleControl + MediaControl 클라이언트)
    - MediaApp (MediaControl 서비스 0x1235:0x5679)
    - (옵션) HU_MainApp (Wayland Compositor)
  - **IC 디스플레이 (별도 화면):**
    - IC_app (VehicleControl 클라이언트)

### 네트워크 설정
- 이더넷 직접 연결 또는 공유 스위치 사용
- 서브넷: 192.168.1.0/24
- vsomeip 멀티캐스트: 224.244.224.245:30490

### 통신 다이어그램
```
ECU1 (192.168.1.100)                ECU2 (192.168.1.101)
┌─────────────────────┐             ┌──────────────────────────────────┐
│ VehicleControlECU   │             │ HU Display                       │
│ (Routing Manager)   │◄────RPC─────│ - GearApp (VehicleCtrl Client)   │
│                     │─────Event───►│ - AmbientApp (VehicleCtrl Client)│
│                     │             │ - MediaApp (MediaCtrl Service)   │
│                     │             │ - HU_MainApp (Wayland Compositor)│
│                     │             └──────────────────────────────────┘
│                     │             
│                     │             ┌──────────────────────────────────┐
│                     │─────Event───►│ IC Display (별도 화면)            │
│                     │             │ - IC_app (VehicleCtrl Client)    │
└─────────────────────┘             └──────────────────────────────────┘
                                    
                    MediaApp ────Event────► AmbientApp
                             (볼륨 → 밝기)
```

---

## 프로젝트 현황 및 리팩토링 계획

### ✅ 완료된 앱
1. **VehicleControlECU** - vsomeip Service Provider (ECU1)
2. **GearApp** - vsomeip Client (ECU2)

### 🔄 수정 필요한 앱
3. **AmbientApp** - 부분 vsomeip 구현 (MediaControl 구독 중, VehicleControl 구독 필요)
4. **MediaApp** - vsomeip Service (완료), 불필요한 코드 정리 필요
5. **IC_app** - Instrument Cluster (vsomeip Client로 전환 필요)
6. **HU_MainApp** - 로컬 통합 앱, Wayland compositor 역할 재정의 필요

### 📝 리팩토링 작업 순서

#### Phase 1: 불필요한 코드 삭제 (안전한 작업부터)

**1. MediaApp 테스트 코드 삭제**
- 삭제할 코드 (`src/main.cpp`):
  ```cpp
  // Test Timer: Simulate volume changes every 5 seconds (100-109줄)
  ```

**2. GearApp IpcManager 삭제** (UDP → vsomeip 완료)
- 삭제할 파일:
  - `src/ipcmanager.h`
  - `src/ipcmanager.cpp`
- 삭제할 코드:
  - `src/gearmanager.h`: `#include <QUdpSocket>`, `QUdpSocket *m_socket;`
  - `src/gearmanager.cpp`: UDP 소켓 초기화 및 사용 코드
  - `src/main.cpp`: IpcManager 관련 코드
  - `CMakeLists.txt`: ipcmanager 제거

**3. AmbientApp UDP 코드 삭제** (IC 통신 제거)
- 삭제할 코드:
  - `src/ambientmanager.h`: `#include <QUdpSocket>`, `QUdpSocket *m_socket;`
  - `src/ambientmanager.cpp`: `sendAmbientStateToIC()` 함수 및 UDP 소켓 코드
  - `src/main.cpp`: 테스트 타이머 (기어 변경 시뮬레이션)

**4. IC_app UDP 코드 삭제** (IC 통신 제거)
- vsomeip Client로 전환 필요

#### Phase 2: vsomeip 통합

**1. AmbientApp - VehicleControlClient 추가**

필요한 이유: GearApp과 동일하게 VehicleControlECU의 기어 변경 이벤트를 vsomeip로 구독해야 함

작업:
- `VehicleControlClient.h/cpp` 파일 생성 (GearApp 것 복사 후 수정)
- `main.cpp`에서 VehicleControlClient 초기화
- `VehicleControlClient::currentGearChanged` → `AmbientManager::onGearPositionChanged` 연결
- 파일 생성: `src/VehicleControlClient.h`, `src/VehicleControlClient.cpp`
- 수정: `src/main.cpp`, `CMakeLists.txt`

**2. IC_app - VehicleControlClient 추가**

작업:
- VehicleControlClient 추가 (AmbientApp과 동일)
- vsomeip 설정 파일 생성

#### Phase 3: 배포 설정 파일 생성

**각 앱별 필요 파일:**
- `config/vsomeip_[app].json` - vsomeip 설정
- `config/commonapi_[app].ini` - CommonAPI 설정
- `build.sh` - 빌드 스크립트
- `run.sh` - 실행 스크립트

#### Phase 4: HU_MainApp 재정의

**옵션 A: Wayland Compositor Only (추천)**
- 역할: 각 독립 앱(GearApp, AmbientApp, MediaApp)을 Wayland 서버로 합성
- 앱 간 통신은 vsomeip로 처리 (HU_MainApp은 관여하지 않음)
- 단순히 화면 레이아웃만 관리

수정 내용:
1. Manager 클래스 모두 제거 (MediaManager, GearManager, AmbientManager)
2. vsomeip 통신 코드 모두 제거
3. Wayland compositor 기능만 유지
4. QML에서 각 앱의 Window를 합성하는 코드만 유지

**옵션 B: 제거 (고려 사항)**
- 각 앱이 이미 독립적으로 실행 가능
- Wayland compositor는 시스템 레벨에서 제공 (Weston, Mutter 등)
- 시스템 Wayland compositor 사용 + 각 앱을 독립 프로세스로 실행

### ⚠️ 주의사항

1. **백업**: 수정 전 현재 상태 커밋
2. **단계별 검증**: 각 Phase마다 빌드 및 기본 테스트 수행
3. **vsomeip 설정**: 각 앱의 application name이 고유해야 함
4. **IP 주소**: 배포 환경에 맞게 vsomeip 설정 파일 수정

---

## 배포 순서

### 1단계: 라즈베리파이 네트워크 설정

#### ECU1 (192.168.1.100)
```bash
# /etc/network/interfaces 또는 /etc/dhcpcd.conf 편집
sudo nano /etc/dhcpcd.conf

# 다음 추가:
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
```

#### ECU2 (192.168.1.101)
```bash
sudo nano /etc/dhcpcd.conf

# 다음 추가:
interface eth0
static ip_address=192.168.1.101/24
static routers=192.168.1.1
```

재부팅:
```bash
sudo reboot
```

네트워크 확인:
```bash
ip addr show eth0
ping 192.168.1.100  # ECU2에서 ECU1로
ping 192.168.1.101  # ECU1에서 ECU2로
```

---

### 2단계: 의존성 설치

두 ECU 모두에서 실행:

```bash
# Qt5 설치
sudo apt-get update
sudo apt-get install -y \
    qt5-default \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    qtquickcontrols2-5-dev

# 빌드 도구
sudo apt-get install -y \
    build-essential \
    cmake \
    git

# vsomeip 및 CommonAPI 라이브러리는 이미 /usr/local/lib에 설치되어 있어야 함
# (프로젝트의 install_folder에서 복사)
```

---

### 3단계: 프로젝트 파일 전송

개발 PC에서 각 ECU로 전송:

#### ECU1으로 전송
```bash
# 개발 PC에서
cd /home/leo/SEA-ME/DES_Head-Unit
rsync -avz --exclude='build*' --exclude='.git' \
    app/VehicleControlECU/ \
    commonapi/ \
    install_folder/ \
    pi@192.168.1.100:~/DES_Head-Unit/
```

#### ECU2로 전송
```bash
# 개발 PC에서
rsync -avz --exclude='build*' --exclude='.git' \
    app/GearApp/ \
    commonapi/ \
    install_folder/ \
    pi@192.168.1.101:~/DES_Head-Unit/
```

---

### 4단계: 라이브러리 설치

두 ECU 모두에서:

```bash
cd ~/DES_Head-Unit/install_folder

# 라이브러리 복사
sudo cp -r lib/* /usr/local/lib/
sudo cp -r include/* /usr/local/include/

# 라이브러리 캐시 업데이트
sudo ldconfig

# 확인
ldconfig -p | grep vsomeip
ldconfig -p | grep CommonAPI
```

---

### 5단계: 빌드

#### ECU1 (VehicleControlECU)
```bash
cd ~/DES_Head-Unit/app/VehicleControlECU
./build.sh
```

#### ECU2 (GearApp)
```bash
cd ~/DES_Head-Unit/app/GearApp
./build.sh
```

---

### 6단계: 실행

#### 실행 순서 (중요!)

**1. ECU1 먼저 실행 (VehicleControlECU)**
```bash
# ECU1 (192.168.1.100)에서
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh
```

출력 확인:
```
✅ VehicleControl service registered
📡 Broadcasting vehicle state at 10Hz...
Instantiating routing manager [Host]
```

**2. ECU2에서 GearApp 실행**
```bash
# ECU2 (192.168.1.101)에서
cd ~/DES_Head-Unit/app/GearApp
./run.sh
```

출력 확인:
```
✅ Connected to VehicleControl service
📡 Subscribing to VehicleControl events...
```

---

## 트러블슈팅

### � 상세 트러블슈팅 가이드
**전체 vsomeip 통신 문제 해결은 다음 문서를 참조하세요:**
- `/docs/ECU_COMMUNICATION_TROUBLESHOOTING_GUIDE.md` - 7대 주요 오류, 진단 가이드, 실전 로그 분석

### 빠른 진단

#### 연결 안 됨
```bash
# ECU1에서 vsomeip 로그 확인
tail -f /var/log/vsomeip_ecu1.log

# ECU2에서 vsomeip 로그 확인
tail -f /var/log/vsomeip_ecu2.log

# 네트워크 트래픽 확인
sudo tcpdump -i eth0 port 30490 or port 30501 or port 30502
```

### 방화벽 확인
```bash
# 두 ECU 모두에서
sudo iptables -L

# 필요시 vsomeip 포트 열기
sudo iptables -A INPUT -p udp --dport 30490 -j ACCEPT  # Service Discovery
sudo iptables -A INPUT -p udp --dport 30501 -j ACCEPT  # Unreliable
sudo iptables -A INPUT -p tcp --dport 30502 -j ACCEPT  # Reliable
```

### 멀티캐스트 라우팅
```bash
# 멀티캐스트 지원 확인
ip maddress show eth0

# 멀티캐스트 라우트 추가 (필수!)
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip route | grep 224

# 예상 출력
# 224.0.0.0/4 dev eth0 scope link
```

### 주요 오류 빠른 체크

**1. "Couldn't connect to /tmp/vsomeip-0"**
```bash
# 원인: routing manager 설정 누락
# 해결: vsomeip.json에 "routing": "본인_앱_이름" 추가
```

**2. NO-CARRIER**
```bash
# 원인: 이더넷 케이블 미연결
# 해결: 케이블 연결 확인
ip link show eth0  # LOWER_UP 상태 확인
```

**3. Service Discovery 실패**
```bash
# 원인: 멀티캐스트 라우팅 누락
# 해결: sudo ip route add 224.0.0.0/4 dev eth0
```

**4. [Proxy] 모드로 실행됨**
```bash
# 원인: "routing" 필드 누락
# 해결: vsomeip.json에 "routing": "본인_앱_이름" 추가
```

**5. "other routing manager present"** (가장 흔한 문제!)
```bash
# 원인: 이전 프로세스가 살아있음
# 해결:
killall -9 VehicleControlECU GearApp AmbientApp MediaApp IC_app
sudo rm -rf /tmp/vsomeip-*
```

---

## systemd 서비스 등록

### ECU1: VehicleControlECU 자동 시작

```bash
sudo nano /etc/systemd/system/vehiclecontrol.service
```

```ini
[Unit]
Description=VehicleControlECU Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/DES_Head-Unit/app/VehicleControlECU
Environment="VSOMEIP_CONFIGURATION=/home/pi/DES_Head-Unit/app/VehicleControlECU/config/vsomeip_ecu1.json"
Environment="COMMONAPI_CONFIG=/home/pi/DES_Head-Unit/app/VehicleControlECU/config/commonapi_ecu1.ini"
Environment="LD_LIBRARY_PATH=/usr/local/lib"
ExecStart=/home/pi/DES_Head-Unit/app/VehicleControlECU/build/VehicleControlECU
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

활성화:
```bash
sudo systemctl daemon-reload
sudo systemctl enable vehiclecontrol.service
sudo systemctl start vehiclecontrol.service
sudo systemctl status vehiclecontrol.service
```

### ECU2: GearApp 자동 시작

```bash
sudo nano /etc/systemd/system/gearapp.service
```

```ini
[Unit]
Description=GearApp Service
After=network.target
Requires=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/DES_Head-Unit/app/GearApp
Environment="VSOMEIP_CONFIGURATION=/home/pi/DES_Head-Unit/app/GearApp/config/vsomeip_ecu2.json"
Environment="COMMONAPI_CONFIG=/home/pi/DES_Head-Unit/app/GearApp/config/commonapi_ecu2.ini"
Environment="LD_LIBRARY_PATH=/usr/local/lib"
Environment="QT_QPA_PLATFORM=linuxfb"
ExecStart=/home/pi/DES_Head-Unit/app/GearApp/build/GearApp
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

활성화:
```bash
sudo systemctl daemon-reload
sudo systemctl enable gearapp.service
sudo systemctl start gearapp.service
sudo systemctl status gearapp.service
```

---

## 다음 단계

### 즉시 실행 가능
1. ✅ VehicleControlECU와 GearApp vsomeip 통신 테스트
2. 📊 기능 테스트:
   - Gear 변경 테스트: GearApp UI에서 P, R, N, D 버튼 클릭 → VehicleControlECU 로그에서 `setGearPosition called` 확인
   - Event 수신 테스트: VehicleControlECU에서 `vehicleStateChanged` 이벤트 발생 → GearApp UI 업데이트 확인
   - 재연결 테스트: VehicleControlECU 중지 후 재시작 → GearApp 자동 재연결 확인

### 리팩토링 필요
1. 🔄 AmbientApp VehicleControlClient 추가
2. 🔄 MediaApp 테스트 코드 삭제
3. 🔄 IC_app vsomeip Client로 전환
4. 🔄 HU_MainApp 역할 재정의 (Compositor Only vs 제거)
5. 🔄 불필요한 UDP/IpcManager 코드 삭제

### 추가 배포 작업
1. AmbientApp, MediaApp, IC_app 배포 설정 추가
2. Yocto 이미지 빌드 및 SD 카드 배포
3. 실제 PiRacer 하드웨어 통합 테스트

### 리팩토링 작업 선택지

**A. 단계별 진행 (안전)**
1. Phase 1부터 시작: 불필요한 코드 삭제
2. 각 단계마다 확인 후 다음 단계 진행

**B. 전체 자동화 (빠름)**
- 모든 수정 사항을 한 번에 적용
- 위험: 한 번에 많은 변경, 디버깅 어려움

**C. HU_MainApp 역할 결정 후 진행**
- 옵션 A (Compositor Only) vs 옵션 B (제거)
- 결정 후 나머지 작업 진행

---

## 📚 참고 자료

- [vsomeip Documentation](https://github.com/COVESA/vsomeip/wiki)
- [CommonAPI C++ Tutorial](https://github.com/COVESA/capicxx-core-tools/wiki)
- [Raspberry Pi Network Configuration](https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-networking)
