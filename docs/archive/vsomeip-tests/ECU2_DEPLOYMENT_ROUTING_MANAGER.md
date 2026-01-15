# ECU2 전체 시스템 배포 및 테스트 가이드

## 📋 시스템 아키텍처 (전용 라우팅 매니저 방식)

### 새로운 구조
```
ECU2 (192.168.1.101)
┌─────────────────────────────────────────────────────┐
│  Routing Manager Daemon (routingmanagerd)           │
│  - Application ID: 0xFFFF                           │
│  - Socket: /tmp/vsomeip-0                           │
│  - Role: [Host] - 모든 앱의 중앙 라우팅 관리        │
└────────────┬────────────────────────────────────────┘
             │ (Unix Socket)
    ┌────────┼────────┬─────────┬──────────┐
    │        │        │         │          │
┌───▼──┐ ┌──▼───┐ ┌──▼────┐ ┌──▼─────┐  │
│Gear  │ │Ambient│ │IC_app │ │Media   │  │
│App   │ │App    │ │       │ │App     │  │
│0x0100│ │0x0200 │ │0x0300 │ │0x1236  │  │
└──────┘ └───────┘ └───────┘ └────────┘  │
                                          │
All apps connect to shared routing manager
No "routing" field in their config files
```

### 기존 구조 (방법 1)와의 차이

**기존 (방법 1):**
- GearApp이 라우팅 매니저 역할
- 다른 앱들이 GearApp에 의존
- GearApp 종료 시 모든 통신 중단

**새로운 (방법 2):**
- 전용 라우팅 매니저 데몬 (독립 프로세스)
- 모든 앱이 동등하게 연결
- 앱 재시작 시에도 라우팅 매니저 유지
- 더 안정적이고 확장 가능

## 🚀 배포 절차

### 사전 준비

#### 1. 파일 구조 확인
```
DES_Head-Unit/
├── app/
│   ├── config/
│   │   ├── routing_manager_ecu2.json  ← 새로 생성됨
│   │   ├── start_routing_manager_ecu2.sh  ← 새로 생성됨
│   │   ├── start_all_ecu2.sh  ← 새로 생성됨
│   │   └── start_ecu1.sh  ← 새로 생성됨
│   ├── VehicleControlECU/
│   │   └── config/vsomeip_ecu1.json
│   ├── GearApp/
│   │   └── config/vsomeip_ecu2.json  ← 수정됨 (routing 필드 제거)
│   ├── AmbientApp/
│   │   └── vsomeip_ambient.json  ← 이미 OK
│   ├── IC_app/
│   │   └── vsomeip_ic.json  ← 이미 OK
│   └── MediaApp/
│       └── vsomeip.json  ← 수정됨 (routing 필드 제거)
```

#### 2. 주요 변경 사항

**GearApp/config/vsomeip_ecu2.json:**
```diff
  "applications": [
      {
-         "name": "client-sample",
-         "id": "0xFFFF"
+         "name": "GearApp",
+         "id": "0x0100"
      }
  ],
- "routing": "client-sample",
  "service-discovery": {
```

**MediaApp/vsomeip.json:**
```diff
- "unicast": "127.0.0.1",
+ "unicast": "192.168.1.101",
+ "netmask": "255.255.255.0",
  "applications": [
      {
          "name": "MediaApp",
-         "id": "0x1234"
+         "id": "0x1236"
      }
  ],
- "routing": "MediaApp",
  "service-discovery": {
      "enable": "true",
-     "multicast": "224.0.0.1",
+     "multicast": "224.244.224.245",
```

### ECU1 배포

#### 1단계: 프로젝트 파일 전송
```bash
# 개발 PC에서
cd /home/leo/SEA-ME/DES_Head-Unit
rsync -avz --exclude='build*' --exclude='.git' \
    app/VehicleControlECU/ \
    app/config/start_ecu1.sh \
    commonapi/ \
    install_folder/ \
    pi@192.168.1.100:~/DES_Head-Unit/
```

#### 2단계: ECU1에서 빌드 (필요시)
```bash
# ECU1 (192.168.1.100)
ssh pi@192.168.1.100

cd ~/DES_Head-Unit/app/VehicleControlECU
./build.sh
```

#### 3단계: ECU1 실행
```bash
# ECU1 (192.168.1.100)
cd ~/DES_Head-Unit/app/config
./start_ecu1.sh

# 또는 직접:
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh
```

**예상 출력:**
```
==========================================
ECU1 VehicleControlECU 시작
==========================================
[1/4] Cleaning up processes...
✓ Cleanup complete

[2/4] Checking network configuration...
✓ IP Address: 192.168.1.100
✓ Multicast route: OK
⏳ Checking connection to ECU2 (192.168.1.101)... ✓ Connected

[3/4] Checking VehicleControlECU build...
✓ Build found

[4/4] Starting VehicleControlECU...
[info] Routing Manager [VehicleControlECU] running as [Host]
[info] OFFER(1234.5678): [192.168.1.100:30501]
✅ VehicleControl service registered
```

### ECU2 배포

#### 1단계: 프로젝트 파일 전송
```bash
# 개발 PC에서
cd /home/leo/SEA-ME/DES_Head-Unit
rsync -avz --exclude='build*' --exclude='.git' \
    app/GearApp/ \
    app/AmbientApp/ \
    app/IC_app/ \
    app/MediaApp/ \
    app/config/ \
    commonapi/ \
    install_folder/ \
    pi@192.168.1.101:~/DES_Head-Unit/
```

#### 2단계: ECU2에서 빌드 (필요시)
```bash
# ECU2 (192.168.1.101)
ssh pi@192.168.1.101

# GearApp 빌드
cd ~/DES_Head-Unit/app/GearApp
./build.sh

# AmbientApp 빌드
cd ~/DES_Head-Unit/app/AmbientApp
./build.sh

# IC_app 빌드
cd ~/DES_Head-Unit/app/IC_app
./build.sh
```

#### 3단계: ECU2 전체 시스템 실행
```bash
# ECU2 (192.168.1.101)
cd ~/DES_Head-Unit/app/config
./start_all_ecu2.sh
```

**예상 출력:**
```
==========================================
ECU2 전체 시스템 시작
==========================================
[1/6] Cleaning up all processes...
✓ Cleanup complete

[2/6] Checking network configuration...
✓ IP Address: 192.168.1.101
✓ Multicast route: OK
⏳ Checking connection to ECU1 (192.168.1.100)... ✓ Connected

[3/6] Starting Routing Manager...
✓ Routing Manager started (PID: 1234)
✓ Routing Manager ready (/tmp/vsomeip-0)

[4/6] Starting GearApp...
✓ GearApp started (PID: 1235)

[5/6] Starting AmbientApp...
✓ AmbientApp started (PID: 1236)

[6/6] Starting IC_app...
✓ IC_app started (PID: 1237)

==========================================
✅ ECU2 시스템 시작 완료!
==========================================

실행 중인 프로세스:
  - Routing Manager: PID 1234
  - GearApp:         PID 1235
  - AmbientApp:      PID 1236
  - IC_app:          PID 1237

로그 파일:
  - Routing Manager: /tmp/routing_manager.log
  - GearApp:         /tmp/gearapp.log
  - AmbientApp:      /tmp/ambientapp.log
  - IC_app:          /tmp/ic_app.log

실시간 로그 확인:
  tail -f /tmp/gearapp.log
  tail -f /tmp/ambientapp.log
```

## 🧪 테스트 시나리오

### 테스트 1: 서비스 발견 확인

```bash
# ECU2에서 로그 확인
tail -f /tmp/gearapp.log

# 예상 로그:
# [info] Application(GearApp, 100) is registered.
# [info] ON_AVAILABLE(1234.5678)  ← VehicleControl 서비스 발견
# [info] Client [100] is connecting to [ffff] at /tmp/vsomeip-0  ← 라우팅 매니저 연결
```

```bash
# ECU2에서 AmbientApp 로그 확인
tail -f /tmp/ambientapp.log

# 예상 로그:
# [info] Application(AmbientApp, 200) is registered.
# [info] ON_AVAILABLE(1234.5678)  ← VehicleControl 서비스 발견
# [info] ON_AVAILABLE(1235.5679)  ← MediaApp 서비스 발견 (나중에)
```

### 테스트 2: 기어 변경 이벤트 전파

```bash
# GearApp GUI에서 P → D 변경

# ECU1 로그:
[VehicleControlStubImpl] RPC: setGearPosition(D)
[VehicleControlStubImpl] Broadcasting gearChanged: D

# ECU2 GearApp 로그:
[GearManager] Received gearChanged event: D

# ECU2 AmbientApp 로그:
[AmbientManager] Received gearChanged event: D
[AmbientManager] Changing ambient color: BLUE → GREEN
```

### 테스트 3: 앱 재시작 테스트

```bash
# ECU2에서 GearApp만 재시작
killall GearApp

cd ~/DES_Head-Unit/app/GearApp
./run.sh &> /tmp/gearapp.log &

# 예상 결과:
# - Routing Manager는 계속 실행 중
# - GearApp이 자동으로 라우팅 매니저에 재연결
# - VehicleControl 서비스 자동 재발견
# - AmbientApp, IC_app는 영향 없음
```

## 🔍 트러블슈팅

### 문제 1: "routingmanagerd: command not found"

**증상:**
```
✗ Error: routingmanagerd or vsomeipd not found!
```

**해결:**
```bash
# vsomeip 설치 확인
ldconfig -p | grep vsomeip

# vsomeipd 사용 (대안)
# start_routing_manager_ecu2.sh가 자동으로 vsomeipd로 fallback
```

### 문제 2: 라우팅 매니저가 시작되지 않음

**증상:**
```
✗ Routing Manager failed to start!
```

**해결:**
```bash
# 로그 확인
tail /tmp/routing_manager.log

# 완전 클린업 후 재시도
killall -9 routingmanagerd vsomeipd 2>/dev/null
sudo rm -rf /tmp/vsomeip-*
./start_routing_manager_ecu2.sh
```

### 문제 3: 앱이 라우팅 매니저를 찾지 못함

**증상:**
```
[error] Routing info for client 0x0100 not found
```

**해결:**
```bash
# 1. 라우팅 매니저 실행 확인
ls -la /tmp/vsomeip-0

# 2. 앱 설정에서 routing 필드 제거 확인
cat ~/DES_Head-Unit/app/GearApp/config/vsomeip_ecu2.json | grep routing
# 출력 없어야 함 (routing 필드가 없어야 함)

# 3. 순서대로 재시작
killall -9 GearApp AmbientApp IC_app
sleep 2
./start_all_ecu2.sh
```

### 문제 4: Service Discovery 실패

**증상:**
```
[warning] Service [1234.5678] is not available
```

**해결:**
```bash
# 멀티캐스트 라우팅 확인
ip route | grep 224.0.0.0

# 없으면 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 멀티캐스트 패킷 확인
sudo tcpdump -i eth0 -n 'udp and port 30490'
# ECU1의 OFFER 패킷이 보여야 함
```

## 📊 로그 분석

### 정상 동작 로그 패턴

**Routing Manager:**
```
[info] Routing Manager [routingmanagerd] is running
[info] create_routing_root: /tmp/vsomeip-0
```

**GearApp:**
```
[info] Application(GearApp, 100) is registered.
[info] Client [100] is connecting to [ffff]  ← 라우팅 매니저 연결
[info] ON_AVAILABLE(1234.5678)  ← 서비스 발견
```

**AmbientApp:**
```
[info] Application(AmbientApp, 200) is registered.
[info] Client [200] is connecting to [ffff]
[info] ON_AVAILABLE(1234.5678)
[info] Subscribed to gearChanged event
```

## 🎯 다음 단계

1. ✅ ECU1 VehicleControlECU 실행
2. ✅ ECU2 라우팅 매니저 + 앱들 실행
3. ✅ 서비스 발견 확인
4. ✅ 기어 변경 테스트
5. ✅ 이벤트 전파 확인
6. 🔄 MediaApp 추가 (선택)
7. 🔄 전체 시스템 안정성 테스트

## 📝 참고 자료

- **상세 트러블슈팅:** `/docs/ECU_COMMUNICATION_TROUBLESHOOTING_GUIDE.md`
- **통신 테스트:** `/docs/전체통신테스트.md`
- **배포 가이드:** `/DEPLOYMENT_GUIDE.md`
