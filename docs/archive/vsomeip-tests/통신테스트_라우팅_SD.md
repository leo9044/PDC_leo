# ECU간 통신 실패 - 근본 원인 분석 및 해결

## 🔍 문제 증상

### ECU2 (GearApp) 로그:
```
[info] Instantiating routing manager [Proxy].
[info] Client [ffff] is connecting to [0] at /tmp/vsomeip-0 endpoint > 0x55b31c3660
[warning] local_client_endpoint::connect: Couldn't connect to: /tmp/vsomeip-0 (No such file or directory / 2)
[warning] cei::connect_cbk: restarting socket due to No such file or directory (2): endpoint > 0x55b31c3660 socket state > 1
[warning] on_disconnect: Resetting state to ST_DEREGISTERED
```

### ECU1 (VehicleControlECU) 로그:
```
[info] Instantiating routing manager [Host].
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] OFFER(1001): [1234.5678:1.0] (true)
✅ VehicleControl service registered
```

**현상:** ECU1은 정상 동작하지만, ECU2가 ECU1과 통신하지 못하고 로컬에서 `/tmp/vsomeip-0`를 찾으려 시도

---

## 🧠 근본 원인 (Root Cause)

### vsomeip 아키텍처 오해

**잘못된 이해:**
```
ECU1 (192.168.1.100)                    ECU2 (192.168.1.101)
┌────────────────────┐                  ┌────────────────────┐
│ VehicleControlECU  │                  │     GearApp        │
│ Routing Manager    │◄─────network─────│   routing:         │
│ /tmp/vsomeip-0     │                  │  "VehicleControlECU"│
└────────────────────┘                  └────────────────────┘
                                              ❌ ECU1의 
                                          routing manager에 
                                          네트워크로 연결?
```

**올바른 이해:**
```
ECU1 (192.168.1.100)                    ECU2 (192.168.1.101)
┌────────────────────┐                  ┌────────────────────┐
│ VehicleControlECU  │                  │     GearApp        │
│ [Routing Manager]  │                  │  [Routing Manager] │
│ /tmp/vsomeip-0     │                  │  /tmp/vsomeip-0    │
│ (Local apps only)  │                  │  (Local apps only) │
└──────────┬─────────┘                  └──────────┬─────────┘
           │                                        │
           └──────────── Service Discovery ─────────┘
                 (Multicast 224.244.224.245:30490)
                 SOME/IP Service Exchange (UDP)
```

### 핵심 개념

**1. Routing Manager는 항상 로컬**
- vsomeip의 **routing manager**는 **각 ECU마다 독립적으로 실행**됩니다
- `/tmp/vsomeip-0` Unix socket은 **같은 머신 내의 애플리케이션만 연결** 가능
- **네트워크를 통한 routing manager 공유는 불가능**

**2. 서비스 디스커버리는 네트워크**
- 각 ECU의 routing manager는 **Service Discovery**를 통해 네트워크상의 다른 서비스를 찾습니다
- Multicast (224.244.224.245:30490)를 사용하여 서비스 OFFER/REQUEST 교환
- 서비스 발견 후에는 **P2P(Point-to-Point) UDP/TCP로 직접 통신**

**3. ECU간 통신 시나리오**
```
1. ECU1 VehicleControlECU 시작
   - 로컬 routing manager [Host] 생성 → /tmp/vsomeip-0
   - Service 0x1234:0x5678 OFFER 멀티캐스트 전송
   
2. ECU2 GearApp 시작
   - 로컬 routing manager [Host] 생성 → /tmp/vsomeip-0
   - Service 0x1234:0x5678 REQUEST 멀티캐스트 전송
   
3. Service Discovery
   - ECU2가 ECU1의 OFFER 수신
   - ECU2가 ECU1의 IP:Port(192.168.1.100:30501) 기록
   
4. 서비스 통신
   - ECU2 → ECU1 RPC 호출 (UDP 30501)
   - ECU1 → ECU2 Event 브로드캐스트 (UDP)
```

---

## ❌ 문제의 설정 (Before)

### /app/GearApp/config/vsomeip_ecu2.json (잘못된 설정)

```json
{
    "unicast": "192.168.1.101",
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "routing": "VehicleControlECU",  // ❌ 잘못됨!
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245"
    },
    "services": [  // ❌ 클라이언트는 "clients" 사용해야 함
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

### 문제점 분석

**1. `"routing": "VehicleControlECU"` - 잘못된 설정**
```
GearApp이 시작하면:
  1. "VehicleControlECU"라는 이름의 routing manager를 찾음
  2. /tmp/vsomeip-0 소켓을 열려고 시도
  3. "VehicleControlECU"는 ECU1에 있으므로 ECU2에는 존재하지 않음
  4. "No such file or directory" 에러 발생
  5. GearApp은 로컬에 routing manager가 없다고 판단
  6. 네트워크로 연결할 방법이 없어서 무한 재시도
```

**2. `"services"` 섹션 - 잘못된 용도**
```
"services": 서비스를 제공(OFFER)하는 경우 사용
"clients": 서비스를 사용(REQUEST)하는 경우 사용

GearApp은 VehicleControl 서비스의 클라이언트이므로 "clients" 사용해야 함
```

**3. `"netmask"` 누락**
```
멀티캐스트 라우팅이 제대로 작동하려면 netmask 필요
```

---

## ✅ 해결 방법 (After)

### /app/GearApp/config/vsomeip_ecu2.json (올바른 설정)

```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",
    "logging": {
        "level": "info",
        "console": "true",
        "file": {
            "enable": "false"
        },
        "dlt": "false"
    },
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "routing": "client-sample",  // ✅ 자기 자신을 routing manager로 지정
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp",
        "initial_delay_min": "10",
        "initial_delay_max": "100",
        "repetitions_base_delay": "200",
        "repetitions_max": "3",
        "ttl": "3",
        "cyclic_offer_delay": "2000",
        "request_response_delay": "1500"
    },
    "clients": [  // ✅ "clients" 섹션으로 변경
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

### 주요 변경사항

**1. `"routing": "client-sample"` ✅**
```
이제 GearApp이:
  1. 자기 자신("client-sample")을 routing manager로 지정
  2. ECU2에 /tmp/vsomeip-0 소켓 생성
  3. 로컬 routing manager [Host] 역할 수행
  4. 네트워크상의 다른 서비스는 Service Discovery로 찾음
```

**2. `"clients"` 섹션 추가 ✅**
```json
"clients": [
    {
        "service": "0x1234",     // VehicleControl 서비스
        "instance": "0x5678",
        "unreliable": "30501"    // ECU1의 서비스 포트
    }
]
```

이제 GearApp은:
- 서비스 0x1234:0x5678을 **사용**하는 클라이언트임을 명시
- Service Discovery를 통해 ECU1의 서비스 찾음
- 발견 후 192.168.1.100:30501로 직접 통신

**3. `"netmask": "255.255.255.0"` 추가 ✅**
- 멀티캐스트 패킷이 올바른 인터페이스로 전송되도록 보장

---

### /app/GearApp/config/commonapi_ecu2.ini (개선된 설정)

```ini
[logging]
console = true
file =
dlt = false
level = info

[default]
binding = someip
default-folder = /usr/local/lib/commonapi

[local:vehiclecontrol.VehicleControl]
binding = someip
instance = vehiclecontrol.VehicleControl
```

**추가사항:**
- `default-folder`: CommonAPI 라이브러리 경로 명시
- `[local:vehiclecontrol.VehicleControl]` 섹션으로 서비스 인스턴스 정의

---

## 📊 Before vs After 비교

### Before (잘못된 동작)

```
ECU2 GearApp 시작:
  [info] Initializing vsomeip application "client-sample"
  [info] Instantiating routing manager [Proxy]  // ❌ Proxy 모드
  [info] Client is connecting to /tmp/vsomeip-0  // ❌ 로컬 소켓
  [warning] Couldn't connect to: /tmp/vsomeip-0 (No such file or directory)
  [warning] on_disconnect: Resetting state to ST_DEREGISTERED
  ↓
  무한 재시도, 서비스 사용 불가
```

### After (올바른 동작)

```
ECU2 GearApp 시작:
  [info] Initializing vsomeip application "client-sample"
  [info] Instantiating routing manager [Host]  // ✅ Host 모드
  [info] create_routing_root: /tmp/vsomeip-0  // ✅ 로컬 소켓 생성
  [info] Service Discovery enabled
  [info] Sending FIND_SERVICE for 0x1234:0x5678
  [info] Service 0x1234:0x5678 is available @ 192.168.1.100:30501
  ✅ Connected to VehicleControl service
```

---

## 🧪 테스트 시나리오

### 1. ECU1 VehicleControlECU 시작

```bash
# ECU1 (192.168.1.100)
cd ~/VehicleControlECU
sudo ./run.sh
```

**기대 출력:**
```
[info] Instantiating routing manager [Host].
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] OFFER(1001): [1234.5678:1.0] (true)
[info] vSomeIP 3.5.8 | (default)
```

---

### 2. ECU2 GearApp 시작

```bash
# ECU2 (192.168.1.101)
cd ~/GearApp
./run.sh
```

**기대 출력:**
```
[info] Initializing vsomeip application "client-sample"
[info] Instantiating routing manager [Host].  // ✅ Host (Proxy 아님!)
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Service Discovery enabled
[info] Sending REQUEST for service [1234.5678]
[info] Service [1234.5678] is available.
✅ Connected to VehicleControl service
```

---

### 3. 네트워크 패킷 확인

```bash
# ECU1에서 Service Discovery 패킷 모니터링
sudo tcpdump -i eth0 -n 'udp and port 30490' -v

# 출력:
# OFFER_SERVICE: 0x1234:0x5678 @ 192.168.1.100:30501
# FIND_SERVICE: 0x1234:0x5678 from 192.168.1.101
# SUBSCRIBE: 0x1234:0x5678 from 192.168.1.101
```

---

### 4. RPC 통신 테스트

```bash
# ECU2 GUI에서 기어 변경 (P → D)
```

**ECU1 로그:**
```
[VehicleControlStubImpl] RPC received: setGearPosition("D")
[VehicleControlStubImpl] Gear changed to: D
```

**ECU2 로그:**
```
[GearManager] Requesting gear change: D
[VehicleControlClient] RPC call success
[VehicleControlClient] Event received: gearChanged(D)
```

---

## 🎯 핵심 교훈

### 1. vsomeip 멀티 ECU 아키텍처
- **각 ECU는 독립적인 routing manager를 가져야 함**
- routing manager는 네트워크를 통해 공유되지 않음
- Service Discovery가 ECU간 서비스 발견을 담당

### 2. 설정 파일 역할
```json
"routing": "본인_애플리케이션_이름"  // 자기 자신을 routing manager로
"clients": [...]  // 사용할 서비스 (네트워크상에서 찾을 서비스)
"services": [...]  // 제공할 서비스 (다른 ECU에 OFFER)
```

### 3. 디버깅 핵심 메시지
```
✅ "Instantiating routing manager [Host]" → 정상
❌ "Instantiating routing manager [Proxy]" → 문제 (다른 routing manager를 찾음)
❌ "Couldn't connect to /tmp/vsomeip-0" → routing manager 설정 오류
```

---

## 📝 관련 파일

**수정된 파일:**
- `/app/GearApp/config/vsomeip_ecu2.json` - vsomeip 클라이언트 설정
- `/app/GearApp/config/commonapi_ecu2.ini` - CommonAPI 설정

**참고 파일:**
- `/app/VehicleControlECU/config/vsomeip_ecu1.json` - 서비스 제공자 설정
- `/docs/VSOMEIP_COMMUNICATION_ANALYSIS.md` - 전체 통신 분석
- `/docs/ECU_COMMUNICATION_TEST_GUIDE.md` - 테스트 가이드

---

## 🔧 다음 단계

1. **ECU2에서 설정 파일 업데이트**
   ```bash
   # 개발 PC에서 ECU2로 전송
   scp ~/SEA-ME/DES_Head-Unit/app/GearApp/config/*.json \
       seame2025@192.168.1.101:~/GearApp/config/
   scp ~/SEA-ME/DES_Head-Unit/app/GearApp/config/*.ini \
       seame2025@192.168.1.101:~/GearApp/config/
   ```

2. **GearApp 재시작**
   ```bash
   # ECU2에서
   cd ~/GearApp
   ./run.sh
   ```

3. **로그 확인**
   - "Instantiating routing manager [Host]" 확인
   - "Service [1234.5678] is available" 확인
   - GUI에서 기어 변경 테스트

---

## ✅ 성공 기준

- [ ] ECU2 로그에 "routing manager [Host]" 출력
- [ ] ECU2 로그에 "/tmp/vsomeip-0 생성" 출력
- [ ] ECU2 로그에 "Service 0x1234 is available" 출력
- [ ] GUI 기어 변경 시 ECU1 로그에 RPC 수신 확인
- [ ] ECU1 이벤트가 ECU2 GUI에 반영됨

---

**작성일:** 2025-10-31  
**작성자:** GitHub Copilot  
**버전:** 1.0 - 근본 원인 분석 및 완전한 해결책
