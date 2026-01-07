# ECU2 외부 통신 구현 가이드

**작성일:** 2025-12-04  
**대상 환경:** Yocto Kirkstone + Raspberry Pi 4  
**통신:** vsomeip 3.5.8 (Routing Manager 방식)

---

## 📋 개요

기본 Raspberry Pi OS에서 성공한 vsomeip 외부 통신을 Yocto 기반 ECU2 이미지에 구현했습니다.

### 아키텍처

```
ECU1 (192.168.1.100)                    ECU2 (192.168.1.101)
┌────────────────────┐                  ┌─────────────────────────┐
│ VehicleControlECU  │                  │  routingmanagerd        │
│ [Host] RM          │                  │  [Host] RM              │
│ Service Provider   │                  │  (systemd service)      │
│ /tmp/vsomeip-0     │                  │  /tmp/vsomeip-0         │
└──────────┬─────────┘                  └──────────┬──────────────┘
           │                                       │
           │        Service Discovery              │
           └──────── 224.244.224.245:30490 ────────┤
                                                   │
                                          ┌────────┼────────┬─────┐
                                          │        │        │     │
                                       ┌──▼──┐  ┌─▼───┐  ┌─▼─┐ ┌─▼──┐
                                       │Gear │  │Amb  │  │IC │ │Home│
                                       │[Px] │  │[Px] │  │[Px]│ │[Px]│
                                       └─────┘  └─────┘  └───┘ └────┘
```

---

## ✅ 구현 내용

### 1. 네트워크 자동 설정

**파일:** `meta/meta-headunit/recipes-core/systemd/`

- `systemd_%.bbappend`: systemd-networkd 설정 파일 설치
- `files/20-eth0.network`: eth0에 192.168.1.101/24 고정 IP + 멀티캐스트 라우트
- `files/10-wlan0.network`: wlan0 DHCP 설정

**적용:**
- 부팅 시 자동으로 네트워크 설정
- ECU1과 통신 가능 (ping 192.168.1.100)
- vsomeip Service Discovery용 멀티캐스트 라우팅

### 2. routingmanagerd systemd 서비스

**파일:** `meta/meta-middleware/recipes-comm/vsomeip-routingmanager/`

- `vsomeip-routingmanager_1.0.bb`: 레시피
- `files/vsomeip-routingmanager.service`: systemd unit 파일

**기능:**
- 부팅 시 자동으로 routingmanagerd 실행
- `/etc/vsomeip/routing_manager_ecu2.json` 사용
- 모든 앱이 연결할 `/tmp/vsomeip-0` 소켓 생성
- 실패 시 자동 재시작 (RestartSec=3)

### 3. vsomeip 설정 파일 관리

**파일:** `meta/meta-middleware/recipes-comm/vsomeip-config/vsomeip-config_1.0.bb`

**변경 사항:**
- `routing_manager_ecu2.json` 설치 추가
- GearApp 설정 경로 수정 (`config/vsomeip_ecu2.json`)
- 모든 앱의 설정 파일을 `/etc/vsomeip/`에 설치

**설치되는 파일:**
```
/etc/vsomeip/
├── routing_manager_ecu2.json    # routingmanagerd용
├── vsomeip_gear.json            # GearApp
├── vsomeip_media.json           # MediaApp
├── vsomeip_ambient.json         # AmbientApp
├── vsomeip_homescreen.json      # HomeScreenApp
└── vsomeip_ic.json              # IC_app
```

### 4. 앱 설정 수정

**변경된 파일:**
- `app/HomeScreenApp/vsomeip_homescreen.json`: unicast를 192.168.1.101로 변경

**확인된 설정:**
- ✅ GearApp: Proxy 모드 (routing 필드 없음)
- ✅ MediaApp: Proxy 모드
- ✅ AmbientApp: Proxy 모드
- ✅ IC_app: Proxy 모드
- ✅ HomeScreenApp: 외부 통신용 IP 설정

### 5. 이미지 통합

**파일:** `meta/meta-headunit/recipes-core/images/headunit-image.bb`

**추가된 패키지:**
- `vsomeip-routingmanager`: routingmanagerd systemd 서비스

---

## 🚀 빌드 및 배포

### 빌드

```bash
cd ~/yocto/poky-kirkstone
source oe-init-build-env build-headunit

# bblayers.conf에 레이어 추가 확인
bitbake-layers show-layers | grep -E "meta-middleware|meta-headunit"

# 이미지 빌드
bitbake headunit-image
```

### SD 카드 플래싱

```bash
cd tmp/deploy/images/raspberrypi4-64/

# SD 카드 확인
lsblk

# 플래싱 (⚠️ /dev/sdX를 실제 SD 카드로 변경!)
sudo dd if=headunit-image-raspberrypi4-64.rootfs.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress conv=fsync && sync
```

---

## 🔍 부팅 후 확인 절차

### 1. 네트워크 확인

```bash
# SSH 로그인
ssh root@192.168.1.101

# IP 주소 확인
ip addr show eth0
# 예상 출력: inet 192.168.1.101/24

# 멀티캐스트 라우트 확인
ip route | grep 224.0.0.0
# 예상 출력: 224.0.0.0/4 dev eth0 scope link

# ECU1 연결 확인
ping -c 3 192.168.1.100
```

### 2. routingmanagerd 서비스 확인

```bash
# 서비스 상태
systemctl status vsomeip-routingmanager.service

# 예상 출력:
# ● vsomeip-routingmanager.service - vsomeip Routing Manager Daemon for ECU2
#    Loaded: loaded
#    Active: active (running)

# 로그 확인
journalctl -u vsomeip-routingmanager.service -f

# 소켓 파일 확인
ls -la /tmp/vsomeip-0
# 예상: srwxr-xr-x 1 root root ... /tmp/vsomeip-0
```

### 3. vsomeip 설정 파일 확인

```bash
# 설정 파일 확인
ls -la /etc/vsomeip/

# routing_manager_ecu2.json 내용 확인
cat /etc/vsomeip/routing_manager_ecu2.json | grep unicast
# 예상: "unicast": "192.168.1.101"
```

### 4. 애플리케이션 통신 테스트

```bash
# ECU1에서 VehicleControlECU 실행 (먼저 시작)
# ECU1: cd ~/DES_Head-Unit/app/VehicleControlECU
# ECU1: ./run.sh

# ECU2에서 앱 로그 확인 (예: IC_app)
journalctl -u ic-app.service -f

# 예상 성공 로그:
# [info] Instantiating routing manager [Proxy]
# [info] Connecting to [Host] routing manager @ /tmp/vsomeip-0
# [info] Client [0300] is connected
# [info] ON_AVAILABLE(0300): [1234.5678]
# Connected: true
```

---

## 🐛 트러블슈팅

### 문제 1: routingmanagerd 서비스 시작 실패

**증상:**
```bash
systemctl status vsomeip-routingmanager.service
# Active: failed
```

**원인:**
- vsomeipd 바이너리 없음
- 설정 파일 경로 오류

**해결:**
```bash
# vsomeipd 확인
which vsomeipd

# 없으면 vsomeip 패키지 확인
opkg list-installed | grep vsomeip

# 설정 파일 확인
cat /etc/vsomeip/routing_manager_ecu2.json
```

### 문제 2: 앱이 routing manager에 연결 못함

**증상:**
```
[warning] Couldn't connect to: /tmp/vsomeip-0
```

**원인:**
- routingmanagerd 미실행
- 권한 문제

**해결:**
```bash
# routingmanagerd 프로세스 확인
ps aux | grep vsomeipd

# 소켓 파일 확인
ls -la /tmp/vsomeip-0

# 서비스 재시작
systemctl restart vsomeip-routingmanager.service
```

### 문제 3: ECU1과 통신 안 됨

**증상:**
```
ping 192.168.1.100
# Network unreachable
```

**원인:**
- 네트워크 설정 미적용
- 케이블 미연결

**해결:**
```bash
# 네트워크 재시작
systemctl restart systemd-networkd

# eth0 상태 확인
ip link show eth0
# UP 확인

# 케이블 연결 확인
dmesg | grep eth0
```

### 문제 4: Service Discovery 안 됨

**증상:**
```
[info] REQUEST(0100): [1234.5678:0.0]
# ON_AVAILABLE 메시지 없음
```

**원인:**
- 멀티캐스트 라우트 없음
- 방화벽 차단

**해결:**
```bash
# 멀티캐스트 라우트 확인
ip route | grep 224.0.0.0

# 수동 추가 (임시)
sudo ip route add 224.0.0.0/4 dev eth0

# tcpdump로 패킷 확인
tcpdump -i eth0 udp port 30490 -n
```

---

## 📊 구현 전후 비교

### 기본 Raspberry Pi OS (수동)

```bash
# 매번 부팅 후 수동 실행
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0
cd ~/app/config
./start_routing_manager_ecu2.sh
cd ~/app/GearApp && ./run.sh &
cd ~/app/AmbientApp && ./run.sh &
# ... 각 앱 수동 실행
```

### Yocto 이미지 (자동)

```bash
# 부팅만 하면 모든 설정 완료
# - 네트워크: systemd-networkd가 자동 설정
# - routingmanagerd: systemd 서비스로 자동 시작
# - 앱들: 각자 systemd 서비스로 자동 시작
# - 모든 것이 자동화됨!
```

---

## 📁 생성/수정된 파일 목록

### 새로 생성된 파일

```
meta/meta-headunit/recipes-core/systemd/
├── systemd_%.bbappend
└── files/
    ├── 20-eth0.network
    └── 10-wlan0.network

meta/meta-middleware/recipes-comm/vsomeip-routingmanager/
├── vsomeip-routingmanager_1.0.bb
└── files/
    └── vsomeip-routingmanager.service
```

### 수정된 파일

```
app/HomeScreenApp/vsomeip_homescreen.json
  - unicast: 127.0.0.1 → 192.168.1.101

meta/meta-middleware/recipes-comm/vsomeip-config/vsomeip-config_1.0.bb
  - routingmanagerd 설정 파일 설치 추가
  - GearApp 경로 수정

meta/meta-headunit/recipes-core/images/headunit-image.bb
  - vsomeip-routingmanager 패키지 추가
```

---

## 🎯 핵심 포인트

### ✅ 성공 요인

1. **ECU1 참조**: meta-vehiclecontrol의 네트워크 설정 방식 그대로 적용
2. **Routing Manager 분리**: routingmanagerd를 독립 systemd 서비스로 실행
3. **자동화**: 모든 설정이 이미지에 포함되어 부팅만 하면 작동
4. **설정 파일 통합**: /etc/vsomeip/에 모든 설정 파일 중앙화

### 🔑 설계 원칙

- **각 ECU는 독립적인 Routing Manager 보유**
- **네트워크를 통한 RM 공유 불가** (Unix 소켓은 로컬만)
- **Service Discovery로 서비스 발견** (멀티캐스트)
- **발견 후 P2P 직접 통신** (UDP/TCP)

---

## 🚀 다음 단계

### 테스트 시나리오

1. **기본 통신 테스트**: ECU1 ↔ ECU2 연결 확인
2. **앱별 기능 테스트**: Gear, Ambient, IC 개별 동작 확인
3. **재시작 테스트**: routingmanagerd 재시작 시 앱 자동 재연결
4. **부하 테스트**: 모든 앱 동시 실행 안정성

### 추가 개선 사항

- **로그 관리**: journald 로그 로테이션 설정
- **모니터링**: watchdog 타이머 추가
- **보안**: vsomeip 통신 암호화 검토
- **성능**: Routing Manager 메모리/CPU 사용량 모니터링

---

## 📚 참고 문서

- `docs/VSOMEIP_RASPIOS_IMPLEMENTATION_GUIDE.md`: 기본 OS 구현 가이드
- `meta/meta-vehiclecontrol/README.md`: ECU1 Yocto 레이어 가이드
- `meta/README.md`: ECU2 레이어 구조 설명
- `app/config/start_all_ecu2.sh`: 기본 OS 자동화 스크립트 (참고용)

---

**작성자:** GitHub Copilot  
**검토:** 팀원  
**상태:** ✅ 구현 완료 - 테스트 대기
