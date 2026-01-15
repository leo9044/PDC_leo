# vsomeip 기본 Raspberry Pi OS 구현 가이드

**작성일:** 2025년 12월 3일  
**대상 환경:** 기본 Raspberry Pi OS (Bullseye/Bookworm)  
**통신 미들웨어:** vsomeip 3.5.8 + CommonAPI 3.2.4

---

## 📋 목차

### Part 1: Routing Manager 아키텍처
- [1.1 vsomeip 아키텍처 이해](#11-vsomeip-아키텍처-이해)
- [1.2 독립 Routing Manager 방식 (routingmanagerd)](#12-독립-routing-manager-방식-routingmanagerd)
- [1.3 Central Routing Manager 방식](#13-central-routing-manager-방식)
- [1.4 Hybrid 방식 (실제 채택)](#14-hybrid-방식-실제-채택)

### Part 2: 네트워크 설정
- [2.1 하드웨어 연결](#21-하드웨어-연결)
- [2.2 Ethernet 수동 IP 설정](#22-ethernet-수동-ip-설정)
- [2.3 멀티캐스트 라우팅](#23-멀티캐스트-라우팅)
- [2.4 Service Discovery 설정](#24-service-discovery-설정)

### Part 3: 디버깅 가이드
- [3.1 7대 주요 오류 해결](#31-7대-주요-오류-해결)
- [3.2 디버깅 명령어](#32-디버깅-명령어)
- [3.3 로그 분석](#33-로그-분석)

### Part 4: 실전 운용
- [4.1 부팅부터 통신까지 절차](#41-부팅부터-통신까지-절차)
- [4.2 통신 테스트](#42-통신-테스트)
- [4.3 자동화 스크립트](#43-자동화-스크립트)

---

# Part 1: Routing Manager 아키텍처

## 1.1 vsomeip 아키텍처 이해

### 핵심 개념: Routing Manager란?

vsomeip는 **Routing Manager**를 통해 같은 머신 내의 모든 vsomeip 애플리케이션을 중재합니다.

#### ❌ 흔한 오해
```
ECU1 (192.168.1.100)                    ECU2 (192.168.1.101)
┌────────────────────┐                  ┌────────────────────┐
│ VehicleControlECU  │                  │     GearApp        │
│ Routing Manager    │◄─────network─────│   routing:         │
│ /tmp/vsomeip-0     │                  │  "VehicleControlECU"│
└────────────────────┘                  └────────────────────┘
                  ❌ 네트워크를 통해 ECU1의 RM에 연결?
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
                 SOME/IP Service Exchange (UDP/TCP)
```

### 3대 핵심 원칙

#### 1. Routing Manager는 항상 로컬
- `/tmp/vsomeip-0` Unix 소켓은 **같은 머신 내의 애플리케이션만 연결**
- 네트워크를 통한 routing manager 공유는 **불가능**
- 각 ECU는 **독립적인 routing manager** 필요

#### 2. Service Discovery는 네트워크
- 각 ECU의 routing manager는 **Service Discovery**를 통해 네트워크상의 서비스 발견
- Multicast (224.244.224.245:30490)로 OFFER/FIND 메시지 교환
- 발견 후에는 **P2P UDP/TCP** 직접 통신

#### 3. 통신 흐름
```
1. ECU1 VehicleControlECU 시작
   → 로컬 RM [Host] 생성 (/tmp/vsomeip-0)
   → Service 0x1234:0x5678 OFFER 멀티캐스트
   
2. ECU2 GearApp 시작
   → 로컬 RM [Host] 생성 (/tmp/vsomeip-0)
   → Service 0x1234:0x5678 FIND 멀티캐스트
   
3. Service Discovery
   → ECU2가 ECU1의 OFFER 수신
   → ECU2가 ECU1 IP:Port 기록 (192.168.1.100:30501)
   
4. 서비스 통신
   → RPC: ECU2 → ECU1 (UDP 30501)
   → Event: ECU1 → ECU2 (UDP)
```

---

## 1.2 독립 Routing Manager 방식 (routingmanagerd)

### 개념

각 ECU에서 **독립적인 routingmanagerd 데몬**을 실행하고, 모든 애플리케이션은 [Proxy] 모드로 동작합니다.

```
ECU2 (192.168.1.101)
┌───────────────────────────────────────────┐
│  routingmanagerd [Host]                   │
│  /tmp/vsomeip-0                           │
└───────────┬───────────────────────────────┘
            │ Unix Socket
   ┌────────┼────────┬──────────┐
   │        │        │          │
┌──▼──┐  ┌─▼───┐  ┌─▼───┐  ┌──▼──┐
│Gear │  │Amb  │  │Media│  │IC   │
│[Px] │  │[Px] │  │[Px] │  │[Px] │
└─────┘  └─────┘  └─────┘  └─────┘
```

### 설정 예시

#### routingmanagerd 설정
**파일:** `app/config/routing_manager_ecu2.json`
```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",
    "logging": {
        "level": "info",
        "console": "true"
    },
    "applications": [
        {
            "name": "routingmanagerd",
            "id": "0xFFFF"
        }
    ],
    "routing": "routingmanagerd",
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp"
    }
}
```

#### 애플리케이션 설정 (GearApp)
**파일:** `app/GearApp/config/vsomeip_ecu2.json`
```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",
    "applications": [
        {
            "name": "GearApp",
            "id": "0x0100"
        }
    ],
    // ⚠️ "routing" 필드 없음 → [Proxy] 모드
    "service-discovery": { "enable": "true" },
    "clients": [
        {
            "service": "0x1234",
            "instance": "0x5678"
        }
    ]
}
```

### 실행 방법

```bash
# 1. routingmanagerd 먼저 시작
export VSOMEIP_CONFIGURATION=./routing_manager_ecu2.json
routingmanagerd &

# 2. 애플리케이션들 시작
./GearApp &
./AmbientApp &
./MediaApp &
```

### 겪었던 문제

#### 문제 1: routingmanagerd 찾을 수 없음
```
bash: routingmanagerd: command not found
```

**원인:** vsomeip 빌드 시 routingmanagerd가 설치 안 됨

**해결:**
```bash
# vsomeip 소스에서 빌드
cd ~/vsomeip/build
sudo cmake --build . --target install

# 또는 vsomeipd 사용
vsomeipd &
```

#### 문제 2: "other routing manager present"
```
[error] Application  acts as routing manager but other routing manager present
```

**원인:** 이전 routingmanagerd 프로세스가 남아있음

**해결:**
```bash
killall -9 routingmanagerd
sudo rm -rf /tmp/vsomeip-*
```

### 로그 예시 (성공)

**routingmanagerd:**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Service Discovery enabled. Joining multicast group 224.244.224.245:30490
[info] SOME/IP routing manager started
```

**GearApp:**
```
[info] Instantiating routing manager [Proxy]
[info] Connecting to [Host] routing manager @ /tmp/vsomeip-0
[info] Client [0100] is connected
[info] REQUEST(0100): [1234.5678:0.0]
```

---

## 1.3 Central Routing Manager 방식

### 개념

**하나의 애플리케이션(VehicleControlECU)**이 Routing Manager 역할을 하고, 다른 앱들은 [Proxy]로 연결합니다.

```
ECU2 (192.168.1.101)
┌───────────────────────────────────────────┐
│  VehicleControlECU [Host]                 │
│  (Service + Routing Manager)              │
│  /tmp/vsomeip-0                           │
└───────────┬───────────────────────────────┘
            │ Unix Socket
   ┌────────┼────────┐
   │        │        │
┌──▼──┐  ┌─▼───┐  ┌─▼───┐
│Gear │  │Amb  │  │Media│
│[Px] │  │[Px] │  │[Px] │
└─────┘  └─────┘  └─────┘
```

### 설정 예시

#### VehicleControlECU (Central RM)
**파일:** `app/VehicleControlECU/config/vsomeip_ecu1.json`
```json
{
    "unicast": "192.168.1.100",
    "netmask": "255.255.255.0",
    "applications": [
        {
            "name": "VehicleControlECU",
            "id": "0x1001"
        }
    ],
    "routing": "VehicleControlECU",  // ✅ 자기 자신이 RM
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    },
    "services": [
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501",
            "reliable": { "port": "30502" }
        }
    ]
}
```

#### GearApp (Proxy)
**파일:** `app/GearApp/config/vsomeip_proxy.json`
```json
{
    "unicast": "192.168.1.101",
    "applications": [
        {
            "name": "GearApp",
            "id": "0x0100"
        }
    ],
    // ⚠️ "routing" 없음 → [Proxy] 모드
    "service-discovery": { "enable": "true" },
    "clients": [...]
}
```

### 장단점

#### 장점
- ✅ 설정 간단 (독립 데몬 불필요)
- ✅ 리소스 절약 (프로세스 1개 감소)
- ✅ VehicleControlECU가 항상 먼저 시작됨 보장

#### 단점
- ❌ VehicleControlECU 종료 시 모든 통신 중단
- ❌ HU 앱들이 VehicleControlECU에 의존
- ❌ VehicleControlECU 재시작 시 모든 앱 재시작 필요

### 겪었던 문제

#### 문제 1: GearApp이 "Couldn't connect to /tmp/vsomeip-0"
```
[warning] Couldn't connect to: /tmp/vsomeip-0 (No such file or directory)
```

**원인:** VehicleControlECU가 시작되지 않았거나 종료됨

**해결:**
```bash
# VehicleControlECU 먼저 시작
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh

# 로그 확인: [Host] routing manager 생성 확인
# [info] Instantiating routing manager [Host]

# 그 다음 GearApp 시작
cd ~/DES_Head-Unit/app/GearApp
./run.sh
```

#### 문제 2: ECU2에서도 Central RM 시도
```
[error] Application [0100] acts as routing manager but other routing manager present
```

**원인:** ECU2 앱(GearApp)의 vsomeip.json에 `"routing": "GearApp"` 설정

**해결:**
- ECU1(VehicleControlECU)만 `"routing"` 필드 가짐
- ECU2 모든 앱은 `"routing"` 필드 **제거**

---

## 1.4 Hybrid 방식 (실제 채택)

### 개념

**각 ECU가 독립적인 Routing Manager**를 가지되, **역할에 따라 Host 결정**:

```
┌─────────────────────────────────────────────────────────────┐
│              vsomeip Network (Service Discovery)             │
│                224.244.224.245:30490                         │
└──────────────┬──────────────────────────────────┬───────────┘
               │                                   │
    ┌──────────▼────────┐              ┌──────────▼────────┐
    │  ECU1 (192.168    │              │  ECU2 (192.168    │
    │  .1.100)          │              │  .1.101)          │
    ├───────────────────┤              ├───────────────────┤
    │ VehicleControlECU │              │ routingmanagerd   │
    │ [Host] RM         │              │ [Host] RM         │
    │ /tmp/vsomeip-0    │              │ /tmp/vsomeip-0    │
    │                   │              │                   │
    │ (Service Provider)│              │ ┌─────┬─────┬───┐ │
    └───────────────────┘              │ │Gear │Amb  │IC │ │
                                       │ │[Px] │[Px] │[Px] │
                                       │ └─────┴─────┴───┘ │
                                       └───────────────────┘
```

### 설정 전략

#### ECU1: VehicleControlECU가 자체 RM
- **이유:** 단일 애플리케이션, 별도 데몬 불필요
- **설정:** `"routing": "VehicleControlECU"`

#### ECU2: routingmanagerd 독립 데몬
- **이유:** 다수 애플리케이션(GearApp, AmbientApp, MediaApp, IC_app)
- **설정:** routingmanagerd 실행, 모든 앱은 [Proxy]

### 실행 순서

```bash
# ECU1
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh

# ECU2
cd ~/DES_Head-Unit/app/config
./start_all_ecu2.sh
# 내부적으로:
#   1. routingmanagerd 시작
#   2. GearApp, AmbientApp, MediaApp, IC_app 시작
```

### 채택 이유

1. ✅ **ECU 독립성:** 각 ECU가 자율적으로 작동
2. ✅ **확장성:** ECU2에 새 앱 추가 시 재설정 불필요
3. ✅ **안정성:** VehicleControlECU 재시작 시 ECU2 영향 없음
4. ✅ **표준 준수:** AUTOSAR SOME/IP 표준 아키텍처

### 디버깅 로그

**ECU1 (VehicleControlECU):**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] OFFER(1001): [1234.5678:0.0] (0)
[info] SD: OFFER service [1234.5678] instance [5678] to 224.244.224.245:30490
```

**ECU2 (routingmanagerd):**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] SD: FIND service [1234.5678] to 224.244.224.245:30490
[info] ON_OFFER(0100): [1234.5678:192.168.1.100:30501]
```

**ECU2 (GearApp - Proxy):**
```
[info] Instantiating routing manager [Proxy]
[info] Connecting to [Host] routing manager @ /tmp/vsomeip-0
[info] Client [0100] is connected
[info] REQUEST(0100): [1234.5678:0.0]
```

---

# Part 2: 네트워크 설정

## 2.1 하드웨어 연결

### 물리적 연결

```
┌─────────────┐         이더넷 케이블        ┌─────────────┐
│   ECU1      │◄──────────────────────────►│   ECU2      │
│ (RPi 1)     │    Cat5e/Cat6 (직접 연결)   │ (RPi 2)     │
│ eth0        │                              │ eth0        │
└─────────────┘                              └─────────────┘
```

**케이블:** Cat5e 이상 (크로스오버 불필요, Auto-MDIX 지원)

### 연결 상태 확인

```bash
# 인터페이스 확인
ip link show eth0

# ✅ 정상: state UP
# ❌ 비정상: state DOWN 또는 NO-CARRIER
```

**출력 예시 (정상):**
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether dc:a6:32:xx:xx:xx brd ff:ff:ff:ff:ff:ff
```

**문제 해결:**
```bash
# 인터페이스 활성화
sudo ip link set eth0 up

# 케이블 재연결
# 양쪽 모두 LOWER_UP 상태 확인
```

---

## 2.2 Ethernet 수동 IP 설정

### 왜 수동 설정이 필요한가?

기본 Raspberry Pi OS는 DHCP를 사용하지만:
- ❌ 두 라즈베리파이를 **직접 연결** (스위치/라우터 없음)
- ❌ DHCP 서버 없음
- ✅ **고정 IP 수동 할당 필요**

### 네트워크 관리 도구 확인

```bash
systemctl list-units | grep -E "network|Network"
```

**NetworkManager 사용 시:**
```
NetworkManager.service    loaded active running   Network Manager
```

**dhcpcd 사용 시:**
```
dhcpcd.service            loaded active running   DHCP Client Daemon
```

### 방법 1: 임시 설정 (테스트용, 빠름)

**특징:**
- ⚡ 즉시 적용
- ⚠️ 재부팅 시 초기화

#### ECU1 (192.168.1.100)
```bash
# 기존 IP 제거
sudo ip addr flush dev eth0

# IP 할당
sudo ip addr add 192.168.1.100/24 dev eth0

# 인터페이스 활성화
sudo ip link set eth0 up

# 확인
ip addr show eth0 | grep inet
# 출력: inet 192.168.1.100/24 scope global eth0
```

#### ECU2 (192.168.1.101)
```bash
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
```

### 방법 2: 영구 설정 (NetworkManager)

#### nmcli 사용

```bash
# 현재 연결 확인
nmcli connection show

# 방법 A: 기존 연결 수정
sudo nmcli connection modify "Wired connection 1" \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    connection.autoconnect yes

# 방법 B: 새 연결 생성
sudo nmcli connection add \
    type ethernet \
    con-name eth0-static \
    ifname eth0 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    connection.autoconnect yes

# 연결 활성화
sudo nmcli connection up eth0-static
```

### 방법 3: 영구 설정 (dhcpcd)

**파일:** `/etc/dhcpcd.conf`
```bash
# eth0 고정 IP 설정
interface eth0
static ip_address=192.168.1.100/24
```

```bash
# 적용
sudo systemctl restart dhcpcd
```

### 연결 테스트

```bash
# ECU1에서 ECU2로 ping
ping -c 3 192.168.1.101

# ECU2에서 ECU1로 ping
ping -c 3 192.168.1.100
```

**✅ 성공:**
```
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.123/0.156/0.189/0.027 ms
```

---

## 2.3 멀티캐스트 라우팅

### 왜 필요한가?

vsomeip Service Discovery는 **멀티캐스트 UDP**를 사용:
- 주소: `224.244.224.245:30490`
- 목적: OFFER/FIND 메시지 교환

멀티캐스트 라우팅이 없으면:
- ❌ SD 메시지 전달 안 됨
- ❌ 서비스 발견 실패
- ❌ "Service not available" 에러

### 설정 방법 (매 부팅 시 필요)

#### ECU1 & ECU2 공통
```bash
# 멀티캐스트 라우트 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip route | grep 224
```

**출력:**
```
224.0.0.0/4 dev eth0 scope link
```

### 자동화 (systemd 서비스)

**파일:** `/etc/systemd/system/multicast-route.service`
```ini
[Unit]
Description=Add multicast route for eth0
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip route add 224.0.0.0/4 dev eth0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable multicast-route.service
sudo systemctl start multicast-route.service
```

### 디버깅

```bash
# 멀티캐스트 패킷 캡처
sudo tcpdump -i eth0 -n udp port 30490

# ✅ 정상: OFFER/FIND 메시지 보임
# ❌ 비정상: 아무 패킷도 없음 → 라우트 확인
```

**정상 출력 예시:**
```
12:34:56.123456 IP 192.168.1.100.30490 > 224.244.224.245.30490: UDP, length 123
12:34:57.234567 IP 192.168.1.101.30490 > 224.244.224.245.30490: UDP, length 98
```

---

## 2.4 Service Discovery 설정

### vsomeip.json 필수 항목

```json
{
    "unicast": "192.168.1.100",      // ✅ 자신의 IP
    "netmask": "255.255.255.0",      // ✅ 서브넷 마스크 (필수!)
    "service-discovery": {
        "enable": "true",             // ✅ SD 활성화
        "multicast": "224.244.224.245",  // ✅ 멀티캐스트 주소
        "port": "30490",              // ✅ SD 포트
        "protocol": "udp",            // ✅ UDP 사용
        "cyclic_offer_delay": "2000", // 2초마다 OFFER 재전송
        "ttl": "3"                    // Time-To-Live
    }
}
```

### 겪었던 문제

#### 문제 1: "netmask" 누락

**증상:**
```
[warning] Failed to join multicast group 224.244.224.245:30490
```

**원인:** `"netmask"` 필드 없으면 멀티캐스트 라우팅 실패

**해결:**
```json
"netmask": "255.255.255.0"  // 추가!
```

#### 문제 2: Service Discovery 타임아웃

**로그:**
```
[info] REQUEST(0100): [1234.5678:0.0]
[warning] vSomeIP 0100 Requested service [1234.5678] not available
```

**디버깅:**
```bash
# ECU1에서 OFFER 전송 확인
sudo tcpdump -i eth0 -n udp port 30490 | grep 192.168.1.100

# ECU2에서 FIND 전송 확인
sudo tcpdump -i eth0 -n udp port 30490 | grep 192.168.1.101

# 멀티캐스트 그룹 가입 확인
netstat -g | grep 224.244.224.245
```

**해결 방법:**
1. 멀티캐스트 라우트 확인 (`ip route | grep 224`)
2. 방화벽 확인 (`sudo iptables -L`)
3. vsomeip 로그 레벨 debug로 변경 (`"level": "debug"`)

#### 문제 3: 방화벽이 UDP 차단

**확인:**
```bash
sudo iptables -L -n -v | grep 30490
```

**해결:**
```bash
# UDP 30490 허용
sudo iptables -A INPUT -p udp --dport 30490 -j ACCEPT
sudo iptables -A OUTPUT -p udp --sport 30490 -j ACCEPT

# 또는 방화벽 임시 비활성화 (테스트용)
sudo iptables -F
```

### SD 타이밍 파라미터

```json
"service-discovery": {
    "initial_delay_min": "10",        // 첫 OFFER 전 최소 대기 (ms)
    "initial_delay_max": "100",       // 첫 OFFER 전 최대 대기 (ms)
    "repetitions_base_delay": "200",  // OFFER 재전송 기본 딜레이
    "repetitions_max": "3",           // 초기 OFFER 반복 횟수
    "cyclic_offer_delay": "2000",     // 주기적 OFFER 간격 (ms)
    "request_response_delay": "1500"  // REQUEST 응답 대기 시간
}
```

**권장 설정 (빠른 발견):**
```json
{
    "initial_delay_min": "10",
    "initial_delay_max": "50",
    "cyclic_offer_delay": "1000",  // 1초마다 OFFER
    "ttl": "5"                     // 5홉까지 전달
}
```

---

# Part 3: 디버깅 가이드

## 3.1 7대 주요 오류 해결

### 오류 1: "Couldn't connect to /tmp/vsomeip-0"

#### 로그
```
[warning] Couldn't connect to: /tmp/vsomeip-0 (No such file or directory)
[warning] on_disconnect: Resetting state to ST_DEREGISTERED
Connected: false
```

#### 원인 분석

1. **`"routing"` 필드 누락**
   - 앱이 [Proxy] 모드로 실행
   - 로컬 routing manager 찾음
   - 하지만 RM이 실행 안 됨

2. **RM이 실행 안 됨**
   - Central RM 방식: VehicleControlECU 미실행
   - routingmanagerd 방식: routingmanagerd 미실행

3. **이전 소켓 파일 남음**
   ```bash
   ls -la /tmp/vsomeip-*
   # 오래된 파일 존재 → 프로세스는 종료됨
   ```

#### 해결 방법

```bash
# 1. vsomeip 프로세스 완전 종료
killall -9 VehicleControlECU GearApp routingmanagerd 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# 2. 소켓 파일 삭제
sudo rm -rf /tmp/vsomeip-*

# 3. RM 먼저 시작
# Central RM 방식:
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh

# routingmanagerd 방식:
export VSOMEIP_CONFIGURATION=./routing_manager_ecu2.json
routingmanagerd &

# 4. 앱 시작
cd ~/DES_Head-Unit/app/GearApp
./run.sh
```

---

### 오류 2: "other routing manager present"

#### 로그
```
[error] Application [0100] acts as routing manager but other routing manager present
[info] Stopping local routing manager due to presence of another one
```

#### 원인

두 개의 routing manager가 동시 실행 시도:
- 기존 RM 프로세스가 `/tmp/vsomeip-0` 소유
- 새 앱이 `"routing": "자기이름"` 설정으로 시작

#### 해결

```bash
# 1. 실행 중인 RM 확인
ps aux | grep -E "VehicleControlECU|routingmanagerd|vsomeipd"

# 2. 불필요한 RM 종료
killall -9 routingmanagerd

# 3. vsomeip.json 확인
# 하나의 앱만 "routing" 필드 가져야 함
```

**설정 수정 예시:**
```json
// ❌ 잘못된 예: 두 앱 모두 RM
// VehicleControlECU: "routing": "VehicleControlECU"
// GearApp:           "routing": "GearApp"  ← 문제!

// ✅ 올바른 예: 하나만 RM
// VehicleControlECU: "routing": "VehicleControlECU"
// GearApp:           (routing 필드 없음)  ← Proxy 모드
```

---

### 오류 3: Service Discovery 실패

#### 로그
```
[info] REQUEST(0100): [1234.5678:0.0]
[warning] vSomeIP 0100 Requested service [1234.5678] not available
```

#### 원인 체크리스트

1. **멀티캐스트 라우트 없음**
   ```bash
   ip route | grep 224.0.0.0
   # 출력 없음 → 문제!
   ```

2. **네트워크 연결 끊김**
   ```bash
   ping -c 1 192.168.1.100
   # 실패 → 네트워크 문제
   ```

3. **Service Provider 미실행**
   ```bash
   # ECU1에서 OFFER 전송 확인
   sudo tcpdump -i eth0 udp port 30490
   # OFFER 메시지 없음 → ECU1 문제
   ```

4. **방화벽 차단**
   ```bash
   sudo iptables -L | grep 30490
   # DROP 규칙 존재 → 방화벽 문제
   ```

#### 해결

```bash
# 1. 멀티캐스트 라우트 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 2. 네트워크 확인
ping -c 3 192.168.1.100

# 3. ECU1 재시작 (Service Provider)
cd ~/DES_Head-Unit/app/VehicleControlECU
killall -9 VehicleControlECU
sudo rm -rf /tmp/vsomeip-*
./run.sh

# 4. 방화벽 임시 비활성화 (테스트)
sudo iptables -F
```

---

## 3.2 디버깅 명령어

### 프로세스 확인

```bash
# vsomeip 관련 프로세스 전체
ps aux | grep -E "vsomeip|VehicleControlECU|GearApp|routingmanagerd"

# Routing Manager 확인
ps aux | grep -E "routing" | grep -v grep

# 소켓 파일 확인
ls -la /tmp/vsomeip-*
```

### 네트워크 확인

```bash
# IP 주소 확인
ip addr show eth0 | grep inet

# 라우트 테이블
ip route

# 멀티캐스트 라우트
ip route | grep 224.0.0.0

# 연결 테스트
ping -c 3 192.168.1.100
ping -c 3 192.168.1.101

# 멀티캐스트 그룹 가입 확인
netstat -g | grep 224.244.224.245
```

### 패킷 캡처

```bash
# Service Discovery 메시지
sudo tcpdump -i eth0 -n udp port 30490 -v

# 특정 IP에서 오는 SD 메시지
sudo tcpdump -i eth0 src 192.168.1.100 and udp port 30490

# Service 통신 (unreliable)
sudo tcpdump -i eth0 -n udp port 30501 -X

# 모든 vsomeip 트래픽
sudo tcpdump -i eth0 'udp and (port 30490 or port 30501 or port 30502)'
```

### vsomeip 로그 레벨 변경

**파일:** `vsomeip.json`
```json
"logging": {
    "level": "debug",  // info → debug
    "console": "true",
    "file": {
        "enable": "true",
        "path": "/tmp/vsomeip.log"
    }
}
```

**로그 파일 모니터링:**
```bash
tail -f /tmp/vsomeip.log | grep -E "OFFER|FIND|SUBSCRIBE|REQUEST"
```

---

## 3.3 로그 분석

### 정상 로그 패턴

#### Service Provider (ECU1 - VehicleControlECU)

**시작 시:**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Service Discovery enabled. Joining multicast group 224.244.224.245:30490
[info] OFFER(1001): [1234.5678:0.0] (0)
[info] SD: OFFER service [1234.5678] instance [5678] to 224.244.224.245:30490
```

**Service 등록:**
```
[info] REGISTER SERVICE(1001): [1234.5678.ffff]
[info] Service [1234.5678] is available.
```

**Client 연결 시:**
```
[info] SUBSCRIBE(1001): [1234.5678.0001.0000.0000]  # Event 구독
[info] Sending event [1234.5678.0001] to [192.168.1.101]
```

#### Service Consumer (ECU2 - GearApp)

**Proxy 모드 연결:**
```
[info] Instantiating routing manager [Proxy]
[info] Connecting to [Host] routing manager @ /tmp/vsomeip-0
[info] Client [0100] is connected
```

**Service 요청:**
```
[info] REQUEST(0100): [1234.5678:0.0]
[info] SD: FIND service [1234.5678] to 224.244.224.245:30490
```

**Service 발견:**
```
[info] ON_AVAILABLE(0100): [1234.5678:192.168.1.100]
[info] Service [1234.5678] is available
[info] SUBSCRIBE(0100): [1234.5678.0001]  # Event 구독
```

**Event 수신:**
```
[info] Received event [1234.5678.0001] from [192.168.1.100]
```

### 에러 로그 패턴

#### "Couldn't connect"
```
[warning] Couldn't connect to: /tmp/vsomeip-0 (No such file or directory)
```
**의미:** Routing Manager 미실행  
**해결:** RM 먼저 시작

#### "other routing manager present"
```
[error] Application [0100] acts as routing manager but other routing manager present
```
**의미:** RM 중복  
**해결:** 하나만 [Host], 나머지 [Proxy]

#### "Service not available"
```
[warning] vSomeIP 0100 Requested service [1234.5678] not available
```
**의미:** Service Discovery 실패  
**해결:** 네트워크/멀티캐스트 확인

#### "Multicast join failed"
```
[warning] Failed to join multicast group 224.244.224.245:30490
```
**의미:** 멀티캐스트 라우트 없음  
**해결:** `sudo ip route add 224.0.0.0/4 dev eth0`

---

# Part 4: 실전 운용

## 4.1 부팅부터 통신까지 절차

### 시나리오: VehicleControlECU ↔ GearApp 통신

**아키텍처:**
- **ECU1:** VehicleControlECU (Service Provider + Central RM)
- **ECU2:** GearApp (Service Consumer + Proxy)

### Step 1: 하드웨어 준비

```bash
# 1. 이더넷 케이블로 ECU1 ↔ ECU2 직접 연결
# 2. 양쪽 라즈베리파이 부팅
# 3. SSH 연결 (wlan0 사용)

# ECU1 SSH
ssh pi@192.168.0.100  # wlan0 IP

# ECU2 SSH
ssh pi@192.168.0.101  # wlan0 IP
```

### Step 2: 네트워크 설정 (ECU1 & ECU2)

```bash
# eth0 IP 할당
# ECU1:
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up

# ECU2:
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up

# 멀티캐스트 라우트 추가 (양쪽)
sudo ip route add 224.0.0.0/4 dev eth0

# 연결 확인
ping -c 3 192.168.1.101  # ECU1에서
ping -c 3 192.168.1.100  # ECU2에서
```

### Step 3: 클린업 (ECU1 & ECU2)

```bash
# 이전 vsomeip 프로세스 종료
killall -9 VehicleControlECU GearApp routingmanagerd 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# 소켓 파일 삭제
sudo rm -rf /tmp/vsomeip-*

# 로그 파일 삭제 (선택)
sudo rm -f /tmp/vsomeip.log
```

### Step 4: Service Provider 시작 (ECU1)

```bash
cd ~/DES_Head-Unit/app/VehicleControlECU
export LD_LIBRARY_PATH=~/install_folder/lib:$LD_LIBRARY_PATH
./VehicleControlECU
```

**확인할 로그:**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Service Discovery enabled. Joining multicast group 224.244.224.245:30490
[info] OFFER(1001): [1234.5678:0.0]
```

### Step 5: Service Consumer 시작 (ECU2)

```bash
cd ~/DES_Head-Unit/app/GearApp
export LD_LIBRARY_PATH=~/install_folder/lib:$LD_LIBRARY_PATH
./GearApp
```

**확인할 로그:**
```
[info] Instantiating routing manager [Proxy]
[info] Connecting to [Host] routing manager @ /tmp/vsomeip-0
Connected: false  # 초기 상태
[info] REQUEST(0100): [1234.5678:0.0]
[info] ON_AVAILABLE(0100): [1234.5678]
Connected: true   # ✅ 연결 성공!
```

### Step 6: 통신 테스트

**GearApp에서 속도 변경:**
```
# 터미널에서 버튼 시뮬레이션
# → QML UI에서 Up 버튼 클릭
```

**VehicleControlECU 로그 확인:**
```
[info] Received REQUEST for method [1234.5678.8001]
[info] Changing speed: 10 -> 20
[info] Sending event [1234.5678.0001] (speed: 20)
```

**GearApp 로그 확인:**
```
[info] Received event [1234.5678.0001]
Speed updated: 20
```

---

## 4.2 자동화 스크립트

### 네트워크 설정 자동화

**파일:** `~/setup_network.sh`
```bash
#!/bin/bash

# 컬러 출력
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ECU 번호 입력
if [ "$1" == "1" ]; then
    IP="192.168.1.100"
    ECU_NAME="ECU1"
elif [ "$1" == "2" ]; then
    IP="192.168.1.101"
    ECU_NAME="ECU2"
else
    echo "Usage: $0 <1|2>"
    echo "  1: ECU1 (192.168.1.100)"
    echo "  2: ECU2 (192.168.1.101)"
    exit 1
fi

echo -e "${GREEN}[$ECU_NAME] Network Setup${NC}"

# IP 설정
echo "Setting eth0 IP to $IP/24..."
sudo ip addr flush dev eth0
sudo ip addr add $IP/24 dev eth0
sudo ip link set eth0 up

# 멀티캐스트 라우트
echo "Adding multicast route..."
sudo ip route add 224.0.0.0/4 dev eth0 2>/dev/null || echo "Route already exists"

# 확인
echo -e "\n${GREEN}[IP Address]${NC}"
ip addr show eth0 | grep inet

echo -e "\n${GREEN}[Routes]${NC}"
ip route | grep -E "eth0|224.0.0.0"

# 연결 테스트
if [ "$1" == "1" ]; then
    TARGET="192.168.1.101"
else
    TARGET="192.168.1.100"
fi

echo -e "\n${GREEN}[Ping Test]${NC}"
if ping -c 1 -W 2 $TARGET &>/dev/null; then
    echo -e "${GREEN}✓${NC} Connected to $TARGET"
else
    echo -e "${RED}✗${NC} Cannot reach $TARGET"
fi
```

**사용법:**
```bash
chmod +x ~/setup_network.sh

# ECU1에서
./setup_network.sh 1

# ECU2에서
./setup_network.sh 2
```

### vsomeip 클린업 자동화

**파일:** `~/cleanup_vsomeip.sh`
```bash
#!/bin/bash

echo "Cleaning up vsomeip processes and files..."

# 프로세스 종료
killall -9 VehicleControlECU GearApp AmbientApp MediaApp IC_app routingmanagerd 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# 소켓 파일 삭제
sudo rm -rf /tmp/vsomeip-*

# 로그 파일 정리 (선택)
read -p "Delete log files? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo rm -f /tmp/vsomeip*.log
fi

echo "✓ Cleanup complete"
echo ""
echo "Remaining vsomeip processes:"
ps aux | grep -E "vsomeip|VehicleControlECU|GearApp" | grep -v grep || echo "  (none)"
```

### 전체 시작 스크립트 (ECU2)

**파일:** `~/DES_Head-Unit/app/config/start_all_ecu2.sh`
```bash
#!/bin/bash

# ECU2 전체 앱 시작 스크립트
# VehicleControlECU가 ECU1에서 실행 중이어야 함

BASE_DIR="$HOME/DES_Head-Unit/app"
export LD_LIBRARY_PATH="$HOME/install_folder/lib:$LD_LIBRARY_PATH"

# 클린업
echo "Cleaning up..."
killall -9 GearApp AmbientApp MediaApp IC_app 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# 앱 시작
echo "Starting GearApp..."
cd $BASE_DIR/GearApp
./run.sh &
sleep 2

echo "Starting AmbientApp..."
cd $BASE_DIR/AmbientApp
./run.sh &
sleep 2

echo "Starting MediaApp..."
cd $BASE_DIR/MediaApp
./run.sh &
sleep 2

echo "Starting IC_app..."
cd $BASE_DIR/IC_app
./run.sh &

echo ""
echo "✓ All apps started"
echo ""
echo "Check processes:"
ps aux | grep -E "GearApp|AmbientApp|MediaApp|IC_app" | grep -v grep
```

---

## 4.3 트러블슈팅 체크리스트

### 통신이 안 될 때

#### 1단계: 하드웨어 확인

```bash
# ✅ 체크리스트
□ 이더넷 케이블 연결됨
□ eth0 LED 깜빡임 (활동 중)
□ ip link show eth0 → state UP
```

```bash
# 인터페이스 상태 확인
ip link show eth0 | grep -E "state|LOWER_UP"

# ✅ 정상: state UP mode DEFAULT
# ❌ 비정상: state DOWN 또는 NO-CARRIER
```

#### 2단계: 네트워크 레이어 확인

```bash
# ✅ 체크리스트
□ eth0에 IP 할당됨 (192.168.1.100 또는 .101)
□ 멀티캐스트 라우트 존재 (224.0.0.0/4)
□ ping 성공
```

```bash
# IP 확인
ip addr show eth0 | grep "inet "

# 라우트 확인
ip route | grep 224.0.0.0

# Ping 테스트
ping -c 3 192.168.1.100
```

#### 3단계: vsomeip 프로세스 확인

```bash
# ✅ 체크리스트
□ VehicleControlECU 실행 중 (ECU1)
□ GearApp 실행 중 (ECU2)
□ /tmp/vsomeip-0 존재
□ "other routing manager" 에러 없음
```

```bash
# 프로세스 확인
ps aux | grep -E "VehicleControlECU|GearApp" | grep -v grep

# 소켓 파일 확인
ls -la /tmp/vsomeip-*

# 로그 확인
tail -f /tmp/vsomeip.log | grep -E "error|warning"
```

#### 4단계: Service Discovery 확인

```bash
# ✅ 체크리스트
□ OFFER 메시지 전송됨 (ECU1)
□ FIND 메시지 전송됨 (ECU2)
□ 멀티캐스트 그룹 가입됨
```

```bash
# ECU1에서 OFFER 확인
sudo tcpdump -i eth0 -c 5 udp port 30490 | grep OFFER

# ECU2에서 FIND 확인
sudo tcpdump -i eth0 -c 5 udp port 30490 | grep FIND

# 멀티캐스트 그룹 확인
netstat -g | grep 224.244.224.245
```

### 빠른 진단 스크립트

**파일:** `~/diagnose_vsomeip.sh`
```bash
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
    if eval "$2" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

echo "=== vsomeip Diagnostics ==="
echo ""

# 네트워크
echo "[ Network ]"
check "eth0 is UP" "ip link show eth0 | grep -q 'state UP'"
check "eth0 has IP" "ip addr show eth0 | grep -q 'inet '"
check "Multicast route exists" "ip route | grep -q '224.0.0.0/4'"
check "Can ping other ECU" "ping -c 1 -W 2 192.168.1.100 || ping -c 1 -W 2 192.168.1.101"

echo ""
echo "[ Processes ]"
check "VehicleControlECU running" "pgrep -x VehicleControlECU"
check "GearApp running" "pgrep -x GearApp"
check "/tmp/vsomeip-0 exists" "test -e /tmp/vsomeip-0"

echo ""
echo "[ Service Discovery ]"
echo -e "${YELLOW}Capturing 5 packets on UDP 30490...${NC}"
PACKETS=$(timeout 5 sudo tcpdump -i eth0 -c 5 -q udp port 30490 2>/dev/null | wc -l)
if [ "$PACKETS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} SD packets detected ($PACKETS)"
else
    echo -e "${RED}✗${NC} No SD packets"
fi

echo ""
echo "[ Recent Errors ]"
if [ -f /tmp/vsomeip.log ]; then
    ERRORS=$(grep -c "error" /tmp/vsomeip.log)
    WARNINGS=$(grep -c "warning" /tmp/vsomeip.log)
    echo "  Errors: $ERRORS"
    echo "  Warnings: $WARNINGS"
    
    if [ "$ERRORS" -gt 0 ]; then
        echo ""
        echo "Last 3 errors:"
        grep "error" /tmp/vsomeip.log | tail -3
    fi
else
    echo "  (no log file)"
fi
```

**사용법:**
```bash
chmod +x ~/diagnose_vsomeip.sh
./diagnose_vsomeip.sh
```

---

## 4.4 성능 최적화

### Service Discovery 최적화

**빠른 발견 (개발용):**
```json
"service-discovery": {
    "initial_delay_min": "10",
    "initial_delay_max": "50",
    "cyclic_offer_delay": "1000",  // 1초
    "ttl": "5"
}
```

**안정적 운용 (프로덕션):**
```json
"service-discovery": {
    "initial_delay_min": "100",
    "initial_delay_max": "500",
    "cyclic_offer_delay": "5000",  // 5초
    "ttl": "3"
}
```

### 로그 레벨 설정

**개발 중:**
```json
"logging": {
    "level": "debug",
    "console": "true"
}
```

**프로덕션:**
```json
"logging": {
    "level": "warning",  // error만 기록
    "console": "false",
    "file": {
        "enable": "true",
        "path": "/var/log/vsomeip.log"
    }
}
```

### 메모리 사용량 확인

```bash
# vsomeip 프로세스 메모리 사용량
ps aux | grep -E "VehicleControlECU|GearApp" | awk '{print $2, $4, $11}'

# 상세 메모리 정보
top -p $(pgrep VehicleControlECU)
```

---

## 부록: 참고 자료

### vsomeip 공식 문서
- GitHub: https://github.com/COVESA/vsomeip
- Wiki: https://github.com/COVESA/vsomeip/wiki

### 이 프로젝트의 아카이브 문서
- `docs/archive/vsomeip-tests/전체통신테스트.md` - 초기 통신 테스트 기록
- `docs/archive/vsomeip-tests/ECU_COMMUNICATION_TROUBLESHOOTING_GUIDE.md` - 상세 에러 분석
- `docs/archive/vsomeip-tests/ECU_BOOT_TO_COMMUNICATION_GUIDE.md` - 부팅 절차

### 네트워크 설정 참고
- systemd-networkd: `man systemd.network`
- NetworkManager: `man nmcli`
- 멀티캐스트: RFC 1112

---

**작성일:** 2025-01-15  
**프로젝트:** DES_Head-Unit  
**vsomeip 버전:** 3.5.8  
**대상 플랫폼:** Raspberry Pi OS (Bookworm)

