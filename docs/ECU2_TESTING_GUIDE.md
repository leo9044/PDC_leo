# ECU2 vsomeip 외부 통신 구현 및 테스트 가이드

**작성일:** 2025년 12월 4일  
**최종 업데이트:** 2025년 12월 4일 (통신 성공 확인)  
**대상:** ECU2 (Head Unit) Yocto 이미지  
**목표:** ECU1 (VehicleControlECU)과의 vsomeip 외부 통신 검증

---

## 📖 구현 개요

이 가이드는 **Yocto 환경에서 vsomeip 외부 통신**을 구현하는 전체 과정을 다룹니다.

### 핵심 개념

**아키텍처:**
```
ECU1 (192.168.1.100)                    ECU2 (192.168.1.101)
┌────────────────────┐                  ┌────────────────────┐
│ VehicleControlECU  │                  │ routingmanagerd    │
│ [Host 모드]        │◄────Ethernet────►│ [Host 모드]        │
│ /tmp/vsomeip-0     │                  │ /tmp/vsomeip-0     │
│ Service Provider   │                  │ ┌─────┬─────┬───┐ │
│ 0x1234:0x5678      │                  │ │Gear │IC   │... │ │
└────────────────────┘                  │ │[Px] │[Px] │[Px]│ │
                                        │ └─────┴─────┴───┘ │
                                        └────────────────────┘
```

**3대 핵심 작업:**
1. **ECU2 네트워크 설정** - WiFi(SSH) + Ethernet(vsomeip) 듀얼 인터페이스
2. **ECU2 routingmanagerd** - 독립 Routing Manager 데몬
3. **ECU1 Host 모드** - `VSOMEIP_APPLICATION_NAME` 환경 변수 필수

---

## ✅ 구현 완료 사항

### 1. ECU2 네트워크 설정
- **WiFi (wlan0):** 192.168.86.100/24 - SSH 접속용
- **Ethernet (eth0):** 192.168.1.101/24 - vsomeip 통신용
- **멀티캐스트 라우팅:** 224.0.0.0/4 dev eth0

### 2. ECU2 Yocto 이미지
- systemd-networkd: 네트워크 자동 설정
- wpa_supplicant: WiFi 자동 연결
- vsomeip-routingmanager: 독립 Routing Manager 서비스
- 모든 앱 Proxy 모드로 빌드 성공

### 3. ECU1 VehicleControlECU
- **Host 모드 설정 완료**
- `VSOMEIP_APPLICATION_NAME=VehicleControlECU` 환경 변수 추가
- Service 0x1234:0x5678 OFFER 성공

### 4. 통신 검증 완료
- ✅ Service Discovery 성공
- ✅ 속도 데이터 수신
- ✅ 모든 앱 정상 작동

---

## 🛠️ 구현 단계 (처음부터 다시 할 때)

### Phase 1: ECU2 네트워크 설정

#### 1-1. systemd-networkd 설정 파일 추가

**파일:** `/home/seame/ChangGit2/DES_Head-Unit/meta/meta-headunit/recipes-core/systemd/systemd_%.bbappend`

```bash
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://20-wired-static.network \
    file://20-eth0.network \
"

do_install:append() {
    install -d ${D}${systemd_unitdir}/network
    install -m 0644 ${WORKDIR}/20-wired-static.network ${D}${systemd_unitdir}/network/
    install -m 0644 ${WORKDIR}/20-eth0.network ${D}${systemd_unitdir}/network/
}
```

#### 1-2. WiFi 설정 파일

**파일:** `meta/meta-headunit/recipes-core/systemd/files/20-wired-static.network`

```ini
[Match]
Name=wlan0

[Network]
Address=192.168.86.100/24
Gateway=192.168.86.1
DNS=8.8.8.8
```

#### 1-3. Ethernet 설정 파일

**파일:** `meta/meta-headunit/recipes-core/systemd/files/20-eth0.network`

```ini
[Match]
Name=eth0

[Network]
Address=192.168.1.101/24

[Route]
Destination=224.0.0.0/4
Scope=link
```

#### 1-4. WiFi 인증 정보 추가

**파일:** `/home/seame/yocto/build-headunit/conf/local.conf`

```bash
# WiFi 설정 추가
WIFI_SSID = "SEA:ME WiFi Access"
WIFI_PASSWORD = "1fy0u534m3"
```

---

### Phase 2: ECU2 routingmanagerd 설정

#### 2-1. vsomeip 빌드 옵션 수정

**파일:** `meta/meta-middleware/recipes-comm/vsomeip/vsomeip_3.5.8.bb`

**핵심 변경:**
```bash
# routingmanagerd 빌드 활성화
EXTRA_OECMAKE += "-DBUILD_EXAMPLES=ON"

# routingmanagerd 설치
do_install:append() {
    install -d ${D}${bindir}
    if [ -f ${B}/examples/routingmanagerd/routingmanagerd ]; then
        install -m 0755 ${B}/examples/routingmanagerd/routingmanagerd ${D}${bindir}/
    fi
}

FILES:${PN} += "${bindir}/routingmanagerd"
```

**이유:** vsomeip는 기본적으로 routingmanagerd를 설치하지 않음. examples/ 디렉토리에만 존재.

#### 2-2. routingmanagerd systemd 서비스 생성

**파일:** `meta/meta-middleware/recipes-comm/vsomeip-routingmanager/vsomeip-routingmanager_1.0.bb`

```bash
DESCRIPTION = "vsomeip Routing Manager Service"
LICENSE = "MPL-2.0"

inherit systemd

DEPENDS = "vsomeip"
RDEPENDS:${PN} = "vsomeip"

SRC_URI = "file://vsomeip-routingmanager.service"

SYSTEMD_SERVICE:${PN} = "vsomeip-routingmanager.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/vsomeip-routingmanager.service ${D}${systemd_system_unitdir}/
}
```

**서비스 파일:** `files/vsomeip-routingmanager.service`

```ini
[Unit]
Description=vsomeip Routing Manager
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/routing_manager_ecu2.json"
ExecStart=/usr/bin/routingmanagerd
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

#### 2-3. ECU2 vsomeip 설정 파일

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
            "id": "0x1111"
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

**모든 앱 설정 파일 (예: vsomeip_homescreen.json):**

```json
{
    "unicast": "192.168.1.101",
    "applications": [
        {
            "name": "HomeScreenApp",
            "id": "0x1236"
        }
    ],
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    }
}
```

**⚠️ 중요:** `"routing"` 필드 **제거** → Proxy 모드

---

### Phase 3: ECU1 Host 모드 설정

#### 3-1. systemd 서비스 파일 수정

**파일:** `meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/vehiclecontrol-ecu.service`

**핵심 변경:**
```ini
[Service]
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"  ← 이 줄 추가!
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
ExecStart=/usr/bin/VehicleControlECU
```

**⚠️ 핵심:** `VSOMEIP_APPLICATION_NAME=VehicleControlECU` 환경 변수 **필수!**
- 이 변수가 없으면 vsomeip가 설정 파일의 어떤 application을 사용할지 모름
- Proxy 모드로 실행되어 `/tmp/vsomeip-0`을 찾으려 함

#### 3-2. ECU1 vsomeip 설정 파일 확인

**파일:** `meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/config/vsomeip_ecu1.json`

```json
{
    "unicast": "192.168.1.100",
    "applications": [
        {
            "name": "VehicleControlECU",
            "id": "0x1001"
        }
    ],
    "routing": "VehicleControlECU",  ← Host 모드 설정
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    },
    "services": [
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

---

### Phase 4: 빌드 및 배포

#### 4-1. ECU2 이미지 빌드

```bash
cd /home/seame/yocto
source poky/oe-init-build-env build-headunit

# 변경된 레시피 클린
bitbake -c cleansstate vsomeip vsomeip-routingmanager systemd

# 전체 이미지 빌드
bitbake headunit-image

# 결과 확인
ls tmp/deploy/images/raspberrypi4-64/*.rpi-sdimg
```

#### 4-2. ECU1 이미지 빌드

```bash
cd /home/seame/yocto
source poky/oe-init-build-env build-ecu1

# 변경된 레시피 클린
bitbake -c cleansstate vehiclecontrol-ecu

# 전체 이미지 빌드
bitbake vehiclecontrol-image
```

#### 4-3. SD 카드 플래싱

```bash
# ECU2
sudo dd if=/home/seame/yocto/build-headunit/tmp/deploy/images/raspberrypi4-64/headunit-image-raspberrypi4-64.rpi-sdimg of=/dev/sdX bs=4M status=progress && sync

# ECU1
sudo dd if=/home/seame/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/vehiclecontrol-image-raspberrypi4-64.rpi-sdimg of=/dev/sdY bs=4M status=progress && sync
```

---

## 📋 테스트 체크리스트

### Step 1: SSH 접속 확인 ✅

```bash
# 로컬 PC에서
ssh root@192.168.86.100
```

**성공 조건:**
- 비밀번호 없이 SSH 접속 성공

---

### Step 2: 네트워크 인터페이스 확인 ⏭️

```bash
# ECU2 라즈베리파이에서
ip addr show

# 예상 결과:
# wlan0: inet 192.168.86.100/24 ... state UP
# eth0: inet 192.168.1.101/24 ... (state UP 또는 NO-CARRIER)
```

**확인 사항:**
- [ ] wlan0가 192.168.86.100으로 설정되어 있는가?
- [ ] eth0가 존재하는가?
- [ ] eth0가 192.168.1.101로 설정되어 있는가?

**이더넷 케이블 연결 전에는 eth0가 NO-CARRIER 상태일 수 있음 (정상)**

---

### Step 3: 멀티캐스트 라우팅 확인 ⏭️

```bash
# ECU2에서
ip route | grep 224.0.0.0

# 예상 결과:
# 224.0.0.0/4 dev eth0 scope link
```

**확인 사항:**
- [ ] 멀티캐스트 라우트가 eth0에 설정되어 있는가?

**문제 발생 시:**
```bash
# 수동으로 멀티캐스트 라우트 추가
sudo ip route add 224.0.0.0/4 dev eth0
```

---

### Step 4: ECU1과 물리적 연결 ⏭️

**하드웨어 연결:**
1. 이더넷 케이블로 ECU1(192.168.1.100)과 ECU2(192.168.1.101) 연결
2. 스위치 사용 또는 직접 연결 (Auto-MDIX 지원 포트)

**테스트:**
```bash
# ECU2에서 ECU1 ping 테스트
ping -c 5 192.168.1.100

# 예상 결과:
# 5 packets transmitted, 5 received, 0% packet loss, time 4005ms
# rtt min/avg/max/mdev = 0.XXX/0.XXX/0.XXX/0.XXX ms
```

**확인 사항:**
- [ ] ping 응답이 정상인가? (0% packet loss)
- [ ] RTT가 1ms 미만인가?

**문제 발생 시:**

| 증상 | 원인 | 해결 |
|------|------|------|
| `Network is unreachable` | eth0 IP 미설정 | `ip addr show eth0` 확인 |
| `Destination Host Unreachable` | ECU1 미부팅 또는 IP 오류 | ECU1 확인, 케이블 확인 |
| `100% packet loss` | 케이블 불량, 스위치 문제 | 하드웨어 점검 |

---

### Step 5: vsomeip Routing Manager 서비스 확인 ⏭️

```bash
# ECU2에서
systemctl status vsomeip-routingmanager.service

# 예상 결과:
# ● vsomeip-routingmanager.service - vsomeip Routing Manager
#    Loaded: loaded (/lib/systemd/system/vsomeip-routingmanager.service; enabled)
#    Active: active (running) since ...
```

**로그 확인:**
```bash
journalctl -u vsomeip-routingmanager.service -n 50

# 확인할 메시지:
# - "Routing manager started"
# - "Service discovery enabled"
# - 에러 메시지가 없어야 함
```

**Unix 소켓 확인:**
```bash
ls -la /tmp/vsomeip-*

# 예상 결과:
# srwxr-xr-x 1 root root 0 Dec  4 16:00 /tmp/vsomeip-0
```

**확인 사항:**
- [ ] 서비스가 `active (running)` 상태인가?
- [ ] /tmp/vsomeip-0 소켓 파일이 존재하는가?
- [ ] 에러 로그가 없는가?

**문제 발생 시:**
```bash
# 서비스 재시작
systemctl restart vsomeip-routingmanager.service

# 상세 로그 확인
journalctl -u vsomeip-routingmanager.service -xe

# 설정 파일 확인
cat /etc/vsomeip/routing_manager_ecu2.json

# 수동 실행 테스트
VSOMEIP_CONFIGURATION=/etc/vsomeip/routing_manager_ecu2.json routingmanagerd
```

---

### Step 6: ECU1 VehicleControlECU 서비스 확인 ⏭️

```bash
# ECU1에서 (다른 터미널 또는 SSH)
ssh root@192.168.1.100
systemctl status vehiclecontrol-ecu.service

# 예상 결과:
# Active: active (running)
```

**로그 확인:**
```bash
# ECU1에서
journalctl -u vehiclecontrol-ecu.service -n 100 | grep -E "Host|OFFER|vsomeip-0"

# 예상 메시지 (반드시 확인!):
# "Instantiating routing manager [Host]"  ← 핵심!
# "create_routing_root: Routing root @ /tmp/vsomeip-0"
# "OFFER(1001): [1234.5678:1.0]"
# "join 224.244.224.245 successful"
```

**Unix 소켓 확인:**
```bash
ls -la /tmp/vsomeip-*

# 예상 결과:
# srwxr-xr-x 1 root root 0 Dec  4 18:03 /tmp/vsomeip-0
# srwxr-xr-x 1 root root 0 Dec  4 18:03 /tmp/vsomeip-1001
```

**확인 사항:**
- [ ] "Instantiating routing manager [Host]" 메시지가 있는가? (필수!)
- [ ] /tmp/vsomeip-0 소켓이 생성되었는가?
- [ ] OFFER(1001): [1234.5678:1.0] 메시지가 있는가?

**⚠️ 문제 발생 시:**

만약 다음과 같은 에러가 보인다면:
```
[warning] local_client_endpoint::connect: Couldn't connect to: /tmp/vsomeip-0
```

**원인:** `VSOMEIP_APPLICATION_NAME` 환경 변수 누락으로 Proxy 모드로 실행됨

**임시 해결:**
```bash
# ECU1에서 systemd 서비스 수정
cat > /tmp/vehiclecontrol-ecu.service << 'EOF'
[Unit]
Description=VehicleControl ECU Service
After=network-online.target

[Service]
Type=simple
User=root
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
ExecStart=/usr/bin/VehicleControlECU
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cp /tmp/vehiclecontrol-ecu.service /lib/systemd/system/vehiclecontrol-ecu.service
systemctl daemon-reload
systemctl restart vehiclecontrol-ecu.service

# 확인
journalctl -u vehiclecontrol-ecu.service -n 50 | grep "Host"
# "Instantiating routing manager [Host]" 메시지 확인!
```

**영구 해결:**
- Yocto 레시피 `vehiclecontrol-ecu.service` 파일 수정
- `Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"` 추가
- 이미지 재빌드 및 재플래싱

---

### Step 7: ECU2 앱 실행 및 통신 테스트 ⏭️

#### 방법 1: systemd 서비스로 실행 (추천)

```bash
# ECU2에서
systemctl start ic-app.service
systemctl start gearapp.service
systemctl start mediaapp.service
systemctl start ambientapp.service
systemctl start homescreenapp.service

# 서비스 상태 확인
systemctl status ic-app.service
```

#### 방법 2: 수동 실행 (디버깅용)

```bash
# ECU2에서
cd /usr/bin
VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_homescreen.json /usr/bin/HomeScreenApp
```

**로그 모니터링:**
```bash
# IC_app 로그 실시간 확인
journalctl -f -u ic-app.service | grep -E "0x1234|SUBSCRIBE|AVAILABLE"

# 예상 메시지:
# "Service [0x1234.0x5678] is AVAILABLE"
# "Subscribing to service [0x1234.0x5678]"
# "Received speed update: XXX km/h"
```

**확인 사항:**
- [ ] 앱이 정상 시작되었는가?
- [ ] "Service AVAILABLE" 메시지가 보이는가?
- [ ] SUBSCRIBE 성공 메시지가 있는가?

---

### Step 8: 네트워크 트래픽 캡처 (디버깅용) 🔍

```bash
# ECU2에서 vsomeip 트래픽 모니터링
tcpdump -i eth0 -n port 30490 or port 30501 or port 30502

# 또는 멀티캐스트만
tcpdump -i eth0 -n dst 224.244.224.245

# 예상 트래픽:
# - 224.244.224.245:30490 (Service Discovery)
# - 192.168.1.100:30501 (Unreliable 데이터)
# - 192.168.1.100:30502 (Reliable 데이터)
```

**확인 사항:**
- [ ] Service Discovery 멀티캐스트 패킷이 보이는가?
- [ ] ECU1에서 ECU2로 데이터 패킷이 전송되는가?

---

### Step 9: 속도 데이터 수신 확인 ⏭️

```bash
# ECU2의 GearApp 로그 확인
---

## 🔧 주요 트러블슈팅 (실제 경험)

### 핵심 문제: ECU1이 Proxy 모드로 실행

**증상:**
```
[warning] local_client_endpoint::connect: Couldn't connect to: /tmp/vsomeip-0
[error] local_client_endpoint::max_allowed_reconnects_reached: /tmp/vsomeip-0
```

**원인:**
- `VSOMEIP_APPLICATION_NAME` 환경 변수 누락
- vsomeip가 어떤 application 설정을 사용할지 몰라 기본값(Proxy) 사용
- Host 모드 설정(`"routing": "VehicleControlECU"`)이 무시됨

**해결:**
1. systemd 서비스 파일에 `Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"` 추가
2. 서비스 재시작 후 `journalctl`에서 **"Instantiating routing manager [Host]"** 확인

**교훈:**
- Yocto 환경에서는 환경 변수 전달이 명시적이어야 함
- 기본 Raspberry Pi OS에서는 `export`로 설정했지만, Yocto systemd는 별도 설정 필요

---

## 🐛 문제 해결 가이드

### 문제 1: "Service not available" 에러
# "Current speed: 0 km/h"
# "Speed updated: 45 km/h"
# "Speed updated: 60 km/h"
```

**GUI 확인 (모니터 연결된 경우):**
- GearApp 화면에 속도가 표시되는가?
- IC_app에 속도가 표시되는가?

**확인 사항:**
- [ ] 속도 데이터가 수신되는가?
- [ ] GUI에 숫자가 표시되는가?

---

### Step 10: CAN 시뮬레이터로 속도 변경 테스트 ⏭️

```bash
# ECU1에서 CAN 메시지 전송 (속도 변경)
cansend can0 123#0000000000003C00  # 60 km/h 설정
cansend can0 123#0000000000005000  # 80 km/h 설정
cansend can0 123#0000000000000000  # 0 km/h 설정

# ECU2 로그에서 변경 확인
journalctl -f -u gearapp.service
```

**확인 사항:**
- [ ] CAN 메시지 전송 시 ECU2에서 실시간으로 속도가 변경되는가?
- [ ] GUI가 즉시 업데이트되는가?

---

### Step 11: 통신 안정성 테스트 ⏭️

```bash
# 5분 이상 지속적인 모니터링
journalctl -f -u ic-app.service -u gearapp.service

# 동시에 시스템 리소스 모니터링
top
```

**확인 사항:**
- [ ] 데이터가 지속적으로 수신되는가? (5분 이상)
- [ ] 연결이 끊어지지 않는가?
- [ ] 에러 메시지가 반복되지 않는가?
- [ ] CPU 사용량이 과도하지 않은가? (<50%)
- [ ] 메모리 누수가 없는가?

---

## 🐛 문제 해결 가이드

### 문제 1: "Service not available" 에러

**증상:** ECU2 앱에서 ECU1 서비스를 찾지 못함

**디버깅 단계:**

1. **멀티캐스트 트래픽 확인**
   ```bash
   tcpdump -i eth0 dst 224.244.224.245
   # OFFER 메시지가 보여야 함
   ```

2. **ECU1 OFFER 메시지 확인**
   ```bash
   # ECU1에서
   journalctl -u vehiclecontrol-ecu | grep OFFER
   # "Offering service [0x1234.0x5678]" 확인
   ```

3. **vsomeip 설정 파일 확인**
   ```bash
   # ECU2에서
   cat /etc/vsomeip/routing_manager_ecu2.json
   
   # 필수 항목 확인:
   # - "unicast": "192.168.1.101"
   # - "multicast": "224.244.224.245"
   # - "port": "30490"
   ```

**해결 방법:**
- 멀티캐스트 라우트 재설정: `sudo ip route add 224.0.0.0/4 dev eth0`
- 방화벽 확인: `iptables -L -n` (비어 있어야 함)
- 서비스 재시작: `systemctl restart vsomeip-routingmanager.service`

---

### 문제 2: routingmanagerd 시작 실패

**증상:** `systemctl status vsomeip-routingmanager` = failed

**디버깅:**
```bash
# 상세 에러 로그
journalctl -u vsomeip-routingmanager.service -xe

# JSON 구문 검증
cat /etc/vsomeip/routing_manager_ecu2.json | python3 -m json.tool
```

**일반적인 원인:**
- JSON 구문 오류 (쉼표, 괄호 누락)
- 파일 권한 문제
- 포트 충돌

**해결:**
```bash
# 파일 권한 수정
chmod 644 /etc/vsomeip/routing_manager_ecu2.json

# 포트 사용 확인
netstat -tulpn | grep 30490

# 수동 실행 테스트
VSOMEIP_CONFIGURATION=/etc/vsomeip/routing_manager_ecu2.json routingmanagerd
```

---

### 문제 3: 앱이 routingmanagerd에 연결 실패

**증상:** "Could not connect to routing manager" 에러

**디버깅:**
```bash
# Unix 소켓 확인
ls -la /tmp/vsomeip-*
# srwxrwxrwx ... /tmp/vsomeip-0 존재해야 함

# 앱 설정 확인
cat /etc/vsomeip/vsomeip_homescreen.json

# 필수 확인:
# - "unicast": "192.168.1.101" (ECU2 IP)
# - "routing" 항목이 없어야 함 (Proxy 모드)
```

**해결:**
```bash
# 소켓 파일 권한
chmod 777 /tmp/vsomeip-0

# routingmanagerd 재시작
systemctl restart vsomeip-routingmanager.service
sleep 2

# 앱 재시작
systemctl restart ic-app.service
```

---

### 문제 4: ping은 되지만 vsomeip 통신 안 됨

**증상:** `ping 192.168.1.100` 성공하지만 Service Discovery 실패

**원인:**
- 멀티캐스트 라우팅 문제
- 스위치가 멀티캐스트 차단
- vsomeip 포트 충돌

**해결:**
```bash
# 1. 멀티캐스트 라우트 확인 및 재설정
ip route del 224.0.0.0/4 dev eth0
ip route add 224.0.0.0/4 dev eth0

# 2. 포트 사용 확인
netstat -tulpn | grep -E "30490|30501|30502"

# 3. 직접 연결 테스트 (스위치 우회)
# 두 라즈베리파이를 이더넷 케이블로 직접 연결

# 4. vsomeip 로그 레벨 올리기
# /etc/vsomeip/routing_manager_ecu2.json 수정
# "logging": { "level": "debug" }
```

---

## 📊 최종 성공 기준

모든 항목이 ✅ 이면 구현 완료:

### 네트워크
- [ ] ECU2 → ECU1 ping 성공 (0% packet loss)
- [ ] 멀티캐스트 라우트 설정됨 (224.0.0.0/4 dev eth0)
- [ ] WiFi SSH 접속 가능 (192.168.86.100)

### vsomeip 서비스
- [ ] ECU1: vehiclecontrol-ecu.service = active (running)
- [ ] ECU2: vsomeip-routingmanager.service = active (running)
- [ ] ECU2: /tmp/vsomeip-0 소켓 존재

### Service Discovery
- [ ] ECU1에서 OFFER 메시지 전송 (journalctl로 확인)
- [ ] ECU2에서 "Service AVAILABLE" 로그 확인
- [ ] 멀티캐스트 트래픽 캡처됨 (tcpdump)

### 데이터 통신
- [ ] ECU2 앱에서 서비스 구독 성공
- [ ] 속도 데이터 수신 확인 (journalctl)
- [ ] CAN 메시지 변경 시 실시간 업데이트
- [ ] GUI에 속도 표시 정상

### 안정성
- [ ] 5분 이상 끊김 없이 통신 유지
- [ ] 재부팅 후 자동 연결
- [ ] 에러 로그 없음
- [ ] CPU/메모리 사용량 정상

---

## 🎉 테스트 완료 후

모든 테스트가 성공하면:

1. **결과 문서화**
   - 스크린샷 캡처 (GUI, 로그)
   - 테스트 날짜/시간 기록
   - 이슈 및 해결 방법 정리

2. **코드 커밋**
   ```bash
   cd /home/seame/ChangGit2/DES_Head-Unit
   git add meta/
   git commit -m "feat: ECU2 vsomeip external communication implementation"
   git push origin Chang_wayland1
   ```

3. **팀원과 공유**
   - 테스트 결과 보고
   - 이미지 파일 공유 (필요 시)
   - 문서 업데이트

---

## 📚 참고 자료

- vsomeip 공식 문서: https://github.com/COVESA/vsomeip
- systemd-networkd 설정: https://www.freedesktop.org/software/systemd/man/systemd.network.html
- Yocto Project 가이드: https://docs.yoctoproject.org/

---

**문서 버전:** 1.0  
**마지막 업데이트:** 2025년 12월 4일  
**작성자:** GitHub Copilot
