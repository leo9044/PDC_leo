# ECU 간 vsomeip 통신 종합 트러블슈팅 가이드

## 📋 목차
1. [vsomeip 아키텍처 이해](#vsomeip-아키텍처-이해)
2. [7대 주요 오류 해결](#7대-주요-오류-해결)
3. [4단계 점검 가이드](#4단계-점검-가이드)
4. [실전 로그 분석](#실전-로그-분석)
5. [자동 복구 스크립트](#자동-복구-스크립트)
6. [빠른 진단 체크리스트](#빠른-진단-체크리스트)

---

## vsomeip 아키텍처 이해

### 🧠 핵심 개념

#### ❌ 잘못된 이해
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

#### ✅ 올바른 이해
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

### 📌 3대 핵심 원칙

**1. Routing Manager는 항상 로컬**
- vsomeip의 **routing manager**는 **각 ECU마다 독립적으로 실행**됩니다
- `/tmp/vsomeip-0` Unix socket은 **같은 머신 내의 애플리케이션만 연결** 가능
- **네트워크를 통한 routing manager 공유는 불가능**

**2. Service Discovery는 네트워크**
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

## 7대 주요 오류 해결

### 오류 1: "Couldn't connect to /tmp/vsomeip-0"

#### 📊 오류 로그
```
[warning] Couldn't connect to: /tmp/vsomeip-0 (No such file or directory)
[warning] on_disconnect: Resetting state to ST_DEREGISTERED
Connected: false
```

#### 🔍 원인 분석

**주요 원인 3가지:**

**1. `"routing"` 필드 누락**
- ECU2(GearApp)가 `vsomeip_ecu2.json`에 `"routing"` 필드 없이 실행됨
- vsomeip가 기본적으로 [Proxy] 모드로 실행되어 로컬 라우팅 매니저(`/tmp/vsomeip-0`)를 찾음
- ECU2는 독립적인 [Host] 라우팅 매니저를 실행해야 하는데 [Proxy]로 동작

**2. `"services"` vs `"clients"` 섹션 혼동**
```
"services": 서비스를 제공(OFFER)하는 경우 사용
"clients": 서비스를 사용(REQUEST)하는 경우 사용

GearApp은 VehicleControl 서비스의 클라이언트이므로 "clients" 사용해야 함
```

**3. `"netmask"` 누락**
```
멀티캐스트 라우팅이 제대로 작동하려면 netmask 필요
예: "netmask": "255.255.255.0"
```

#### ✅ 해결 방법

**1단계: 설정 파일 확인**
```bash
cd ~/SEA-ME/DES_Head-Unit/app/GearApp/config
cat vsomeip_ecu2.json
```

**2단계: "routing" 필드 및 필수 설정 추가**

파일: `/app/GearApp/config/vsomeip_ecu2.json`

```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",  // ← 추가 (멀티캐스트 라우팅 필수)
    "applications": [
        {
            "name": "client-sample",
            "id": "0x0100"
        }
    ],
    "routing": "client-sample",  // ← 추가 (자기 자신을 routing manager로 지정)
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    },
    "clients": [  // ← "services" 아님! 클라이언트는 "clients" 사용
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

**3단계: 재시작**
```bash
killall -9 GearApp
sudo rm -rf /tmp/vsomeip-*
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

#### 📈 결과
```
[info] Instantiating routing manager [Host]  // ✅ Proxy → Host 변경
[info] create_routing_root: Routing root @ /tmp/vsomeip-0  // ✅ 소켓 생성
```

---

### 오류 2: NO-CARRIER (케이블 미연결)

#### 📊 오류 로그
```bash
$ ip link show eth0
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN
```

#### 🔍 원인 분석
- 이더넷 케이블이 물리적으로 연결되지 않음
- ECU1과 ECU2 간 네트워크 통신 불가능
- Service Discovery 패킷 전송/수신 불가

#### ✅ 해결 방법

**1단계: 물리적 연결 확인**
```bash
# 케이블 상태 확인
ip link show eth0

# 예상 결과 (문제 상황)
# <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN  ← DOWN 상태
```

**2단계: 케이블 재연결**
1. ECU1의 이더넷 포트에서 케이블 제거 후 재연결
2. ECU2의 이더넷 포트에서 케이블 제거 후 재연결
3. 케이블이 불량하면 다른 케이블로 교체

**3단계: 연결 확인**
```bash
ip link show eth0

# 예상 결과 (정상)
# <BROADCAST,MULTICAST,UP,LOWER_UP> state UP  ← LOWER_UP 확인!
```

**4단계: IP 재설정**
```bash
# ECU1
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up

# ECU2
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
```

**5단계: 연결 테스트**
```bash
# ECU1에서 ECU2로 ping
ping -c 3 192.168.1.101

# 예상 결과
# 3 packets transmitted, 3 received, 0% packet loss  ✅
```

---

### 오류 3: Service Discovery 실패

#### 📊 오류 로그
```
# ECU2 로그
[info] REQUEST(0100): [1234.5678:1.4294967295]
[warning] Service [1234.5678] is not available.
Connected: false
```

#### 🔍 원인 분석
- ECU1은 OFFER 패킷을 멀티캐스트로 전송 중
- ECU2가 멀티캐스트 패킷을 수신하지 못함
- 멀티캐스트 라우팅 설정 누락

#### ✅ 해결 방법

**1단계: ECU1에서 패킷 전송 확인**
```bash
# ECU1에서 실행
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v

# 예상 출력
# 192.168.1.100.30490 > 224.244.224.245.30490: SOMEIP
```

**2단계: ECU2에서 패킷 수신 확인**
```bash
# ECU2에서 실행
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v

# 문제 상황: 아무것도 출력 안됨 ❌
```

**3단계: 멀티캐스트 라우팅 추가 (핵심!)**
```bash
# 두 ECU 모두 실행
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip route | grep 224

# 예상 출력
# 224.0.0.0/4 dev eth0 scope link  ✅
```

**4단계: 애플리케이션 재시작**
```bash
killall -9 GearApp
sudo rm -rf /tmp/vsomeip-*
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

**5단계: 멀티캐스트 그룹 가입 확인**
```bash
# 3-5초 대기 후
ip maddr show eth0 | grep 224.244.224.245

# 예상 출력 (성공)
# inet  224.244.224.245  ✅
```

#### 📈 결과
```
[info] Service [1234.5678] is available.  ✅
Connected: true  ✅
```

---

### 오류 4: [Proxy] 모드 실행

#### 📊 오류 로그
```
[info] Instantiating routing manager [Proxy]  ❌
[warning] Couldn't connect to: /tmp/vsomeip-0
```

#### 🔍 원인 분석
- `vsomeip_ecu2.json`에 `"routing"` 필드 없음
- vsomeip가 기본값으로 [Proxy] 모드 선택
- ECU2는 독립적인 [Host]로 실행되어야 함

#### ✅ 해결 방법

**routing 필드 추가**
```json
{
    "applications": [
        {
            "name": "client-sample",
            "id": "0x0100"
        }
    ],
    "routing": "client-sample",  // ← 추가
    "service-discovery": {
        "enable": "true"
    }
}
```

**재시작 및 확인**
```bash
killall -9 GearApp
sudo rm -rf /tmp/vsomeip-*
./run.sh

# 예상 로그
# [info] Instantiating routing manager [Host]  ✅
```

---

### 오류 5: "other routing manager present" ⭐ 가장 흔한 오류

#### 📊 오류 로그
```
[error] application: client-sample configured as routing but other routing manager present
[warning] Couldn't connect to: /tmp/vsomeip-0
```

#### 🔍 원인 분석
- 이전에 실행된 vsomeip 프로세스가 아직 살아있음
- `/tmp/vsomeip-0` 소켓이 이미 다른 프로세스에 의해 점유됨
- 새로운 라우팅 매니저가 시작되지 못함

#### ✅ 해결 방법 (가장 중요!)

**완전 클린업 3단 콤보**
```bash
# 1. 모든 vsomeip 관련 프로세스 강제 종료
killall -9 GearApp VehicleControlECU 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# 2. 프로세스 종료 확인
ps aux | grep -E "GearApp|vsomeip|client-sample" | grep -v grep
# 아무것도 출력되지 않아야 함 ✅

# 3. vsomeip 소켓 완전 삭제
sudo rm -rf /tmp/vsomeip-*
sudo rm -rf /var/run/vsomeip-*

# 삭제 확인
ls -la /tmp/vsomeip-* 2>/dev/null
# ls: cannot access '/tmp/vsomeip-*': No such file or directory  ✅
```

**3초 대기 후 재시작**
```bash
sleep 3
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

#### 📈 결과
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Service [1234.5678] is available.
Connected: true  ✅
```

### 💡 핵심 포인트
**이 오류의 해결책은 "완전한 클린업"입니다!**
```bash
# 이 3줄 명령어가 모든 문제의 90%를 해결
killall -9 GearApp 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*
```

---

### 오류 6: 멀티캐스트 그룹 미가입

#### 📊 오류 로그
```bash
# 멀티캐스트 그룹 확인
$ ip maddr show eth0 | grep 224.244.224.245
# (아무것도 출력 안됨)  ❌
```

#### 🔍 원인 분석
- ECU2가 [Proxy] 모드로 실행되어 Service Discovery 비활성화
- 멀티캐스트 그룹 224.244.224.245에 가입하지 않음
- ECU1의 OFFER 패킷을 수신할 수 없음

#### ✅ 해결 방법

**1단계: 현재 상태 확인**
```bash
ip maddr show eth0 | grep 224.244.224.245

# ECU1 (정상)
# inet  224.244.224.245  ✅

# ECU2 (문제)
# (아무것도 출력 안됨)  ❌
```

**2단계: 설정 파일 수정**
```json
{
    "routing": "client-sample",  // ← [Host] 모드 활성화
    "service-discovery": {
        "enable": "true",  // ← 확인
        "multicast": "224.244.224.245"
    }
}
```

**3단계: 완전 클린업 및 재시작**
```bash
killall -9 GearApp 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# 멀티캐스트 라우팅 확인
ip route | grep 224.0.0.0
# 없으면 추가
sudo ip route add 224.0.0.0/4 dev eth0

cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

**4단계: 멀티캐스트 그룹 가입 확인**
```bash
# 3-5초 대기 후
ip maddr show eth0 | grep 224.244.224.245

# 예상 출력 (성공)
# inet  224.244.224.245  ✅
```

---

### 오류 7: Connected: false (종합 문제)

#### 📊 오류 로그
```
# GearApp GUI
Connected: false  ❌

# ECU2 로그
[warning] Service [1234.5678] is not available.
```

#### 🔍 원인 분석
- 위의 모든 문제가 복합적으로 발생
- vsomeip 프로세스 클린업 누락 → [Proxy] 모드 → 멀티캐스트 미가입 → SD 실패

#### ✅ 해결 방법 (종합)

**1단계: 완전 클린업 (최우선!)**
```bash
# ECU2에서 실행
killall -9 GearApp 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# 확인
ps aux | grep -E "GearApp|vsomeip" | grep -v grep
# 아무것도 없어야 함 ✅
```

**2단계: 네트워크 확인**
```bash
# 케이블 연결
ip link show eth0
# <BROADCAST,MULTICAST,UP,LOWER_UP> state UP  ✅

# IP 설정
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up

# 멀티캐스트 라우팅
sudo ip route add 224.0.0.0/4 dev eth0

# ping 테스트
ping -c 3 192.168.1.100
# 0% packet loss  ✅
```

**3단계: 설정 파일 최종 확인**
```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",
    "applications": [
        {
            "name": "client-sample",
            "id": "0x0100"
        }
    ],
    "routing": "client-sample",  // ✅ 필수!
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    },
    "clients": [  // "services" 아님!
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

**4단계: 실행 순서**
```bash
# ECU1 먼저 시작
cd ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU
./run.sh

# 5초 대기
sleep 5

# ECU2 시작
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

#### 📈 결과
```
# GearApp GUI
Connected: true  ✅
Service Status: Available  ✅

# 기어 변경 테스트
[Button Click] P → D
✅ Gear change successful  ✅
```

---

## 4단계 점검 가이드

### 단계 1: RM Host/Proxy 역할 점검 (가장 유력한 문제)

| ECU | 점검 항목 | 조치 사항 |
|-----|----------|---------|
| **ECU1** | RM Host 로그 확인 | `Instantiating routing manager [Host]` 확인 |
| | UDS 파일 확인 | `ls -l /tmp/vsomeip-0` 존재 확인 |
| **ECU2** | JSON routing 설정 | `"routing": "client-sample"` 필드 존재 확인 |
| | RM Host 로그 확인 | `Instantiating routing manager [Host]` 확인 |
| **양쪽** | 잔여 소켓 정리 | `sudo rm -rf /tmp/vsomeip-*` |

### 단계 2: 네트워크/OS 레벨 멀티캐스트 설정

```bash
# 멀티캐스트 라우팅 추가 (양쪽 ECU)
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip route | grep 224.0.0.0

# 멀티캐스트 그룹 가입 확인
ip maddr show eth0 | grep 224.244.224.245
```

### 단계 3: SOME/IP ID 및 버전 점검

| 항목 | ECU1 | ECU2 | 상태 |
|------|------|------|------|
| Client ID | 0x1001 | 0x0100 | ✅ 고유 |
| Service ID | 0x1234 | 0x1234 | ✅ 일치 |
| Instance ID | 0x5678 | 0x5678 | ✅ 일치 |
| Port (UDP) | 30501 | 30501 | ✅ 일치 |

### 단계 4: 서비스 가용성 및 RPC 호출 확인

```bash
# SD 성공 확인 (ECU1)
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -c 5

# ECU2 로그에서 확인
# [info] Service [1234.5678] is available.  ✅

# RPC 호출 확인 (Wireshark)
# ECU2 → ECU1: UDP 30501
```

---

## 실전 로그 분석

### ✅ 정상 로그 (ECU1 - VehicleControlECU)

```
2025-11-01 16:50:37.812077 VehicleControlECU [info] Instantiating routing manager [Host].
2025-11-01 16:50:37.814142 VehicleControlECU [info] create_routing_root: Routing root @ /tmp/vsomeip-0
2025-11-01 16:50:37.814395 VehicleControlECU [info] Service Discovery enabled.
2025-11-01 16:50:37.829086 VehicleControlECU [info] Client [1001] routes unicast:192.168.1.100
2025-11-01 16:50:37.829663 VehicleControlECU [info] OFFER(1001): [1234.5678:1.0] (true)
✅ VehicleControl service registered
```

**✅ 확인 포인트:**
- `[Host]` 모드 실행
- `/tmp/vsomeip-0` 소켓 생성
- Service Discovery 활성화
- 유니캐스트 IP 192.168.1.100
- 서비스 OFFER 성공

---

### ✅ 정상 로그 (ECU2 - GearApp)

```
2025-11-01 17:51:00.366485 GearApp [info] Instantiating routing manager [Host].
2025-11-01 17:51:00.368467 GearApp [info] create_routing_root: Routing root @ /tmp/vsomeip-0
2025-11-01 17:51:00.368704 GearApp [info] Service Discovery enabled.
2025-11-01 17:51:00.383862 GearApp [info] Client [0100] routes unicast:192.168.1.101
2025-11-01 17:51:00.384020 GearApp [info] REQUEST(0100): [1234.5678:1.4294967295]
✅ Proxy created successfully
```

**✅ 확인 포인트:**
- `[Host]` 모드 실행 (Proxy 아님!)
- `/tmp/vsomeip-0` 소켓 생성
- Service Discovery 활성화
- 유니캐스트 IP 192.168.1.101
- 서비스 REQUEST 전송

---

### ❌ 문제 로그 (Service Not Available)

```
[warning] Service [1234.5678] is not available.
⚠️  VehicleControl service is not available
❌ Cannot request gear change: service not available
Connected: false  ❌
```

**❌ 문제 원인:**
1. 멀티캐스트 라우팅 누락 (`sudo ip route add 224.0.0.0/4 dev eth0`)
2. 멀티캐스트 그룹 미가입 (SD 비활성화)
3. ECU1이 실행되지 않음
4. 네트워크 케이블 미연결

**💡 해결:**
```bash
# 1. 멀티캐스트 라우팅
sudo ip route add 224.0.0.0/4 dev eth0

# 2. 클린업
killall -9 GearApp
sudo rm -rf /tmp/vsomeip-*

# 3. 재시작
./run.sh
```

---

## 자동 복구 스크립트

### ECU2 완전 복구 스크립트

**파일:** `~/fix_ecu2.sh`

```bash
#!/bin/bash

echo "=== ECU2 GearApp 완전 복구 ==="

# 1. 프로세스 클린업
echo "[1/5] vsomeip 프로세스 종료..."
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-* /var/run/vsomeip-*
echo "✅ 클린업 완료"

# 2. 프로세스 확인
echo "[2/5] 프로세스 확인..."
RUNNING=$(ps aux | grep -E "GearApp|vsomeip|client-sample" | grep -v grep)
if [ -z "$RUNNING" ]; then
    echo "✅ 모든 프로세스 종료됨"
else
    echo "❌ 아직 실행 중인 프로세스 있음:"
    echo "$RUNNING"
    exit 1
fi

# 3. 소켓 확인
echo "[3/5] 소켓 파일 확인..."
if ls /tmp/vsomeip-* 2>/dev/null; then
    echo "❌ 소켓 파일이 아직 남아있음"
    exit 1
else
    echo "✅ 소켓 파일 삭제됨"
fi

# 4. 네트워크 설정
echo "[4/5] 네트워크 설정..."
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
sudo ip route add 224.0.0.0/4 dev eth0 2>/dev/null
echo "✅ 네트워크 설정 완료"

# 5. 연결 테스트
echo "[5/5] ECU1 연결 테스트..."
if ping -c 1 -W 2 192.168.1.100 >/dev/null 2>&1; then
    echo "✅ ECU1 연결 성공"
else
    echo "❌ ECU1 연결 실패 - 케이블 확인 필요"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ 모든 준비 완료!"
echo "========================================="
echo ""
echo "다음 단계:"
echo "1. ECU1에서 VehicleControlECU 실행"
echo "2. 5초 대기"
echo "3. ECU2에서 ./run.sh 실행"
echo ""
```

**사용법:**
```bash
# 실행 권한 부여
chmod +x ~/fix_ecu2.sh

# 실행
~/fix_ecu2.sh

# 성공 후
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

---

### 🎯 7단계 빠른 진단

```bash
# ✅ 1. 케이블 연결
ip link show eth0 | grep LOWER_UP

# ✅ 2. IP 설정
ip addr show eth0 | grep "192.168.1.10"

# ✅ 3. 멀티캐스트 라우팅
ip route | grep "224.0.0.0/4"

# ✅ 4. 프로세스 클린 상태
ps aux | grep -E "vsomeip|GearApp" | grep -v grep
# (아무것도 없어야 함)

# ✅ 5. 소켓 파일 없음
ls /tmp/vsomeip-* 2>&1 | grep "No such file"

# ✅ 6. 설정 파일 "routing" 필드
grep -A 2 '"routing"' ~/SEA-ME/DES_Head-Unit/app/GearApp/config/vsomeip_ecu2.json

# ✅ 7. ECU1 연결
ping -c 1 192.168.1.100
```

**모든 항목이 ✅이면 100% 성공!**

---

## 📝 핵심 교훈 정리

### 1️⃣ vsomeip는 상태를 유지한다
- 프로세스 종료 후에도 소켓 파일이 남아있음
- 설정 변경 시 **반드시** 클린업 필요
- `killall + rm -rf`가 해결의 90%

### 2️⃣ 각 ECU는 독립적인 [Host]
- 라우팅 매니저는 네트워크로 공유 불가
- `"routing": "client-sample"` 필수
- [Proxy] 모드는 Service Discovery 비활성화

### 3️⃣ 클라이언트는 "clients" 사용
- ❌ `"services"`: 서비스 제공자용
- ✅ `"clients"`: 서비스 소비자용
- GearApp은 클라이언트이므로 "clients"

### 4️⃣ 물리 계층 먼저 확인
- LOWER_UP 상태 확인
- ping 테스트
- tcpdump로 패킷 확인

### 5️⃣ 실행 순서 중요
1. 네트워크 설정
2. 프로세스 클린업
3. ECU1 먼저 실행
4. 5초 대기
5. ECU2 실행

---

## 📚 관련 문서

- [MULTI_ECU_COMMUNICATION_TEST.md](./MULTI_ECU_COMMUNICATION_TEST.md) - 다중 ECU 통신 테스트
- [ECU_BOOT_TO_COMMUNICATION_GUIDE.md](./ECU_BOOT_TO_COMMUNICATION_GUIDE.md) - 부팅부터 통신까지
- [QUICK_FIX_AFTER_REBOOT.md](./QUICK_FIX_AFTER_REBOOT.md) - 재부팅 후 빠른 복구

---

**작성일:** 2025-11-03  
**최종 업데이트:** 2025-11-03  
**버전:** 2.0 - 3개 문서 통합판
