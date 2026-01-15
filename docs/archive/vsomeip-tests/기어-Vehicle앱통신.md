# ECU간 통신 테스트 가이드 (라즈베리파이 2대)

## 📋 목차
1. [테스트 환경 개요](#테스트-환경-개요)
2. [하드웨어 준비](#하드웨어-준비)
3. [네트워크 설정](#네트워크-설정)
4. [ECU1 설정 (VehicleControlECU)](#ecu1-설정-vehiclecontrolecu)
5. [ECU2 설정 (GearApp)](#ecu2-설정-gearapp)
6. [통신 테스트](#통신-테스트)
7. [문제 해결](#문제-해결)

---

## 테스트 환경 개요

### 아키텍처
```
┌─────────────────────────────────────────────────────────────┐
│              vsomeip Network (SOME/IP Protocol)              │
└─────────────────────────────────────────────────────────────┘
           ↑                                    ↑
           │                                    │
    ┌──────┴────────┐                   ┌──────┴────────┐
    │   ECU1 (RPi1) │                   │   ECU2 (RPi2) │
    │ 192.168.1.100 │◄──── Ethernet ────│ 192.168.1.101 │
    └───────────────┘                   └───────────────┘
    │                                    │
    │ VehicleControlECU                  │ GearApp
    │ - Routing Manager                  │ - Client
    │ - Service Provider                 │ - GUI
    │ - PiRacer 하드웨어                 │ - RPC Caller
    └───────────────┘                   └───────────────┘
```

### 역할 분담

| ECU | 역할 | IP 주소 | 애플리케이션 | vsomeip 역할 |
|-----|------|---------|-------------|-------------|
| ECU1 | Service Provider | 192.168.1.100 | VehicleControlECU | Routing Manager |
| ECU2 | Service Consumer | 192.168.1.101 | GearApp | Client |

---

## 하드웨어 준비

### 필요한 장비
- ✅ 라즈베리파이 2대 (라즈베리파이 OS 설치됨)
- ✅ Ethernet 케이블 1개 (직접 연결용)
- ✅ 전원 어댑터 2개
- ✅ (선택) PiRacer 하드웨어 (ECU1에 연결)
- ✅ (선택) 모니터, 키보드 (초기 설정용)

### 물리적 연결
```
RPi1 (ECU1) ◄────── Ethernet Cable ──────► RPi2 (ECU2)
    ↑                                           ↑
 PiRacer                                    Monitor/KB
(선택사항)                                  (GUI 확인)
```

---

## 네트워크 설정

### ECU1 (라즈베리파이 1) - 192.168.1.100

#### 1. SSH 접속 (또는 직접 연결)
```bash
# 다른 PC에서 SSH 접속하거나
ssh pi@raspberrypi1.local

# 또는 직접 모니터/키보드 연결
```

#### 2. Ethernet 인터페이스 확인
```bash
ip link show
# eth0 또는 enp... 형태의 이름 확인
```

#### 3. 네트워크 관리 도구 확인

먼저 시스템이 사용 중인 네트워크 관리 도구를 확인합니다:

```bash
systemctl list-units | grep -E "network|Network"
```

**출력 예시 - NetworkManager 사용 시 (Ubuntu Desktop, Raspberry Pi OS Desktop):**
```
NetworkManager.service                    loaded active running   Network Manager
NetworkManager-wait-online.service        loaded active exited    Network Manager Wait Online
```

**출력 예시 - dhcpcd 사용 시 (Raspberry Pi OS Lite):**
```
dhcpcd.service                            loaded active running   DHCP Client Daemon
```

위 출력에서 `NetworkManager.service`가 보이면 **NetworkManager**를 사용 중입니다.  
`dhcpcd.service`가 보이면 **dhcpcd**를 사용 중입니다.

#### 4. 고정 IP 설정 (NetworkManager 사용)

**⚠️ 주의: NetworkManager 연결 생성 시 오류가 발생하는 경우**

일부 Raspberry Pi OS에서 `nmcli connection add` 또는 `nmcli connection up` 실행 시 다음 오류가 발생할 수 있습니다:
```
Error: Connection activation failed: No suitable device found for this connection
```

**해결 방법: 수동 IP 설정 사용 (임시, 빠른 테스트용)**

```bash
# 1. eth0 인터페이스 활성화
sudo ip link set eth0 up

# 2. IP 주소 할당 (즉시 적용됨)
sudo ip addr add 192.168.1.100/24 dev eth0

# 3. IP 확인
ip addr show eth0
# inet 192.168.1.100/24 가 보여야 함
```

**⚠️ 이 방법은 재부팅 시 초기화됩니다!** 통신 테스트 완료 후 영구 설정이 필요합니다 (하단 참조).

---

**방법 1: nmcli 명령어 사용 (영구 설정)**

```bash
# 현재 연결 확인
nmcli connection show

# 방법 A: 기존 연결 수정 (Wired connection 1이 있는 경우)
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

**방법 2: GUI 사용 (데스크톱 환경)**

1. 우측 상단 네트워크 아이콘 클릭
2. "네트워크 설정" 또는 "Edit Connections" 선택
3. "Wired connection 1" 선택 → "Edit"
4. "IPv4 Settings" 탭:
   - Method: `Manual`
   - Address: `192.168.1.100`
   - Netmask: `24` (또는 255.255.255.0)
5. "Save" → "Close"

#### 5. 설정 적용

**NetworkManager 재시작:**
```bash
sudo systemctl restart NetworkManager
```

**또는 인터페이스만 재시작:**
```bash
sudo nmcli connection down eth0-static
sudo nmcli connection up eth0-static
```

**또는 재부팅 (안전):**
```bash
sudo reboot
```

#### 6. IP 확인
```bash
ip addr show eth0
# 192.168.1.100/24가 설정되었는지 확인
```

**✅ 성공 시 출력 예시:**
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d8:3a:dd:a9:d6:ce brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 scope global eth0
       valid_lft forever preferred_lft forever
```

---

### ECU2 (라즈베리파이 2) - 192.168.1.101

위의 ECU1 설정과 동일하되 IP 주소만 변경:

#### NetworkManager 설정 (ECU2)

**빠른 테스트용 (수동 IP 설정):**

```bash
# 1. eth0 활성화
sudo ip link set eth0 up

# 2. IP 주소 할당
sudo ip addr add 192.168.1.101/24 dev eth0

# 3. IP 확인
ip addr show eth0
```

**영구 설정 (nmcli 사용):**

```bash
# 방법 A: 기존 연결 수정
sudo nmcli connection modify "Wired connection 1" \
    ipv4.method manual \
    ipv4.addresses 192.168.1.101/24 \
    connection.autoconnect yes

# 방법 B: 새 연결 생성
sudo nmcli connection add \
    type ethernet \
    con-name eth0-static \
    ifname eth0 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.101/24 \
    connection.autoconnect yes

# 연결 활성화
sudo nmcli connection up eth0-static
```

설정 적용:
```bash
sudo systemctl restart NetworkManager
# 또는
sudo reboot
```

IP 확인:
```bash
ip addr show eth0
# 192.168.1.101/24가 설정되었는지 확인
```

---

### 네트워크 연결 테스트

#### ECU1에서 ECU2로 ping
```bash
ping -c 4 192.168.1.101
```

#### ECU2에서 ECU1로 ping
```bash
ping -c 4 192.168.1.100
```

**✅ 성공 예시:**
```
PING 192.168.1.101 (192.168.1.101) 56(84) bytes of data.
64 bytes from 192.168.1.101: icmp_seq=1 ttl=64 time=0.234 ms
64 bytes from 192.168.1.101: icmp_seq=2 ttl=64 time=0.187 ms
64 bytes from 192.168.1.101: icmp_seq=3 ttl=64 time=0.192 ms
64 bytes from 192.168.1.101: icmp_seq=4 ttl=64 time=0.205 ms

--- 192.168.1.101 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3058ms
rtt min/avg/max/mdev = 0.187/0.204/0.234/0.018 ms
```

**❌ 실패 시:**

아래 내용은 **"문제 해결" 섹션의 "문제 7: Ping 실패"**를 참조하세요.

주요 원인:
- 라우팅 테이블에 네트워크 경로가 없음
- 방화벽 또는 인터페이스 상태 문제

빠른 해결 방법:
```bash
# IP 재설정으로 라우트 자동 생성
sudo ip addr del 192.168.1.100/24 dev eth0
sudo ip addr add 192.168.1.100/24 dev eth0
ip route show  # 192.168.1.0/24 dev eth0 확인
ping -c 4 192.168.1.101
```

**기타 문제 해결:**
- Ethernet 케이블 연결 확인
- IP 설정 재확인: `ip addr show eth0`
- 인터페이스 상태 확인: `ip link show eth0` (LOWER_UP 확인)
- 방화벽 확인: `sudo ufw status`

---

## ECU1 설정 (VehicleControlECU)

### 1. 필요한 파일 전송

**⚠️ 전제조건:** 개발 PC에서 프로젝트 파일을 ECU1(라즈베리파이)로 전송해야 합니다.

#### 옵션 A: 기존 WiFi 네트워크 통해 전송 (추천)

```bash
# 개발 PC에서 실행
# ECU1이 WiFi로 연결되어 있다면 (예: 192.168.86.x)

# VehicleControlECU 전송
scp -r ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU team06@<ECU1_WIFI_IP>:~/

# CommonAPI generated code 전송
scp -r ~/SEA-ME/DES_Head-Unit/commonapi/generated team06@<ECU1_WIFI_IP>:~/commonapi/

# 예시:
# scp -r ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU team06@192.168.86.50:~/
```

#### 옵션 B: USB 메모리 사용

```bash
# 개발 PC에서 USB 마운트
sudo mount /dev/sdb1 /mnt
sudo cp -r ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU /mnt/
sudo cp -r ~/SEA-ME/DES_Head-Unit/commonapi/generated /mnt/commonapi/
sudo umount /mnt

# ECU1에 USB 연결 후
sudo mount /dev/sda1 /mnt
cp -r /mnt/VehicleControlECU ~/
cp -r /mnt/commonapi ~/
sudo umount /mnt
```

#### 옵션 C: Git clone (프로젝트가 GitHub에 있는 경우)

```bash
# ECU1에서 직접 실행
cd ~
git clone https://github.com/Changseok-Oh29/DES_Head-Unit.git
cd DES_Head-Unit
```

### 2. ECU1 SSH 접속

**⚠️ 주의:** 파일 전송은 WiFi 네트워크를 통해 했지만, 이후 작업은 Ethernet 네트워크(192.168.1.100)를 사용합니다.

#### 옵션 1: Ethernet 직접 연결 후 접속 (추천)

```bash
# ECU1의 eth0에 192.168.1.100 설정 완료 후
ssh team06@192.168.1.100
```

#### 옵션 2: WiFi 통해 접속 (Ethernet 설정 전)

```bash
# ECU1의 WiFi IP로 접속 (예: 192.168.86.50)
ssh team06@<ECU1_WIFI_IP>

# 또는 hostname 사용
ssh team06@raspberrypi1.local
```

접속 후 Ethernet 설정:
```bash
# ECU1에서 eth0 설정
sudo ip link set eth0 up
sudo ip addr add 192.168.1.100/24 dev eth0
ip addr show eth0
```

### 3. 의존성 설치
```bash
cd ~/VehicleControlECU

# 스크립트 실행 권한 부여
chmod +x install_dependencies.sh
chmod +x build_vsomeip_rpi.sh
chmod +x cleanup_x86_libs.sh
chmod +x build.sh
chmod +x run.sh

# 시스템 패키지 설치
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-log-dev \
    libi2c-dev \
    i2c-tools

# PiRacer 하드웨어 사용 시
sudo apt install -y pigpio
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```

### 4. vsomeip & CommonAPI 빌드 (ARM64용)

**⚠️ 중요:** 라즈베리파이에서 네이티브 빌드를 수행합니다. 크로스 컴파일이 아닙니다!

```bash
cd ~/VehicleControlECU

# x86_64 라이브러리가 있다면 제거 (개발 PC에서 빌드한 것)
./cleanup_x86_libs.sh

# vsomeip 및 CommonAPI ARM64 네이티브 빌드 (15-20분 소요)
./build_vsomeip_rpi.sh
```

**⏰ 빌드 시간:** 라즈베리파이 4 기준 약 15-20분 소요

**빌드 과정:**
1. vsomeip 3.5.8 소스 다운로드 및 컴파일
2. CommonAPI Core 3.2.4 컴파일
3. CommonAPI SOME/IP 3.2.4 컴파일
4. `/usr/local/lib` 및 `/usr/local/include`에 설치

**✅ 빌드 성공 시 출력:**
```
-- Installing: /usr/local/lib/libvsomeip3.so.3.5.8
-- Installing: /usr/local/lib/libCommonAPI.so.3.2.4
-- Installing: /usr/local/lib/libCommonAPI-SomeIP.so.3.2.4
Build completed successfully!
```

**❌ 빌드 실패 시:**
- 의존성 패키지 누락 확인: `sudo apt install build-essential cmake libboost-all-dev`
- 디스크 공간 확인: `df -h`
- 메모리 부족 시 swap 증가 필요

### 5. VehicleControlECU 빌드
```bash
cd ~/VehicleControlECU

# CommonAPI generated code 경로 설정
export COMMONAPI_GEN_DIR=~/commonapi/generated

# 빌드
./build.sh
```

### 6. 설정 파일 확인
```bash
# vsomeip 설정 확인
cat ~/VehicleControlECU/config/vsomeip_ecu1.json
```

주요 설정 확인:
- `"unicast": "192.168.1.100"` ✅
- `"routing": "VehicleControlECU"` ✅
- `"service-discovery": { "enable": "true" }` ✅

### 7. VehicleControlECU 실행
```bash
cd ~/VehicleControlECU

# PiRacer 하드웨어 사용 시 sudo 필요
sudo ./run.sh

# 또는 하드웨어 없이 테스트
./run.sh
```

**✅ 성공 시 출력 예시:**
```
═══════════════════════════════════════════════════════
Starting VehicleControlECU - vsomeip Service
ECU1 @ 192.168.1.100
═══════════════════════════════════════════════════════

[info] Initializing vsomeip application "VehicleControlECU"
[info] Instantiating routing manager [Host].
[info] Service VehicleControl registered
[info] Application(VehicleControlECU) is initialized
```

---

## ECU2 설정 (GearApp)

### 1. 필요한 파일 전송

개발 PC에서 ECU2로 파일 전송:

```bash
# 개발 PC에서 실행
cd ~/SEA-ME/DES_Head-Unit/app/GearApp

# ECU2로 전송
scp -r ~/SEA-ME/DES_Head-Unit/app/GearApp seame2025@192.168.86.75:~/
scp -r ~/SEA-ME/DES_Head-Unit/commonapi/generated seame2025@192.168.86.75:~/commonapi/
```

### 2. ECU2 SSH 접속
```bash
ssh pi@192.168.1.101
```

### 3. 의존성 설치
```bash
cd ~/GearApp

# 스크립트 실행 권한 부여
chmod +x build.sh
chmod +x run.sh

# 시스템 패키지 설치
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-log-dev
```

### 4. vsomeip & CommonAPI 빌드 (ARM64용)

**중요: ECU1에서 이미 빌드했다면, 빌드된 라이브러리를 복사하는 것이 더 빠릅니다.**

#### 옵션 A: ECU1에서 복사 (추천)

**⚠️ 주의: 먼저 ECU2가 ECU1에 접근 가능한지 확인하세요!**

ECU2는 현재 192.168.1.101로 설정되어 있지만, SSH는 기본 네트워크(예: wlan0)를 사용할 수 있습니다.

**사전 확인:**
```bash
# ECU2에서 실행
# 1. ECU1으로 ping 확인
ping -c 4 192.168.1.100

# 2. SSH 접속 확인
ssh team06@192.168.1.100 "echo 'Connection OK'"
```

**ping은 되지만 SSH가 "No route to host" 오류가 발생하는 경우:**

**원인:** SSH는 기본 게이트웨이를 통해 라우팅을 시도하지만, 192.168.1.0/24 네트워크로의 직접 경로가 없음

**해결 방법:**

**옵션 1: SSH 대신 rsync 또는 직접 빌드 사용 (추천)**
```bash
# ECU2에서 직접 빌드 (옵션 B 참조)
# 또는 USB 메모리로 파일 전송
```

**옵션 2: 임시 기본 게이트웨이 추가**
```bash
# ECU2에서 실행
# 현재 라우팅 테이블 백업
ip route show > ~/route_backup.txt

# 192.168.1.0 네트워크를 eth0로 명시적으로 라우팅
sudo ip route add 192.168.1.0/24 dev eth0 src 192.168.1.101

# SSH 접속 재시도
ssh team06@192.168.1.100

# 파일 복사 (성공하면)
sudo scp -r team06@192.168.1.100:/usr/local/lib/libvsomeip* /tmp/
sudo scp -r team06@192.168.1.100:/usr/local/lib/libCommonAPI* /tmp/
sudo scp -r team06@192.168.1.100:/usr/local/include/vsomeip /tmp/
sudo scp -r team06@192.168.1.100:/usr/local/include/CommonAPI* /tmp/
sudo scp -r team06@192.168.1.100:/usr/local/lib/cmake/vsomeip3 /tmp/
sudo scp -r team06@192.168.1.100:/usr/local/lib/cmake/CommonAPI* /tmp/

# /tmp에서 /usr/local로 복사
sudo cp -r /tmp/libvsomeip* /usr/local/lib/
sudo cp -r /tmp/libCommonAPI* /usr/local/lib/
sudo cp -r /tmp/vsomeip /usr/local/include/
sudo cp -r /tmp/CommonAPI* /usr/local/include/
sudo cp -r /tmp/vsomeip3 /usr/local/lib/cmake/
sudo cp -r /tmp/CommonAPI* /usr/local/lib/cmake/

sudo ldconfig
```

**옵션 3: 역방향 복사 (ECU1에서 ECU2로 push) ⭐ 추천**
```bash
# ECU1에서 실행 (192.168.1.100)
# 사용자 홈 디렉토리로 전송 (권한 문제 없음)
scp -r /usr/local/lib/libvsomeip* seame2025@192.168.1.101:~/vsomeip_libs/
scp -r /usr/local/lib/libCommonAPI* seame2025@192.168.1.101:~/vsomeip_libs/
scp -r /usr/local/include/vsomeip seame2025@192.168.1.101:~/vsomeip_libs/include/
scp -r /usr/local/include/CommonAPI* seame2025@192.168.1.101:~/vsomeip_libs/include/
scp -r /usr/local/lib/cmake/vsomeip3 seame2025@192.168.1.101:~/vsomeip_libs/cmake/
scp -r /usr/local/lib/cmake/CommonAPI* seame2025@192.168.1.101:~/vsomeip_libs/cmake/

# ECU2에서 실행
# 홈 디렉토리에서 시스템 디렉토리로 복사
sudo cp -r ~/vsomeip_libs/libvsomeip* /usr/local/lib/
sudo cp -r ~/vsomeip_libs/libCommonAPI* /usr/local/lib/
sudo cp -r ~/vsomeip_libs/include/vsomeip /usr/local/include/
sudo cp -r ~/vsomeip_libs/include/CommonAPI* /usr/local/include/
sudo mkdir -p /usr/local/lib/cmake
sudo cp -r ~/vsomeip_libs/cmake/vsomeip3 /usr/local/lib/cmake/
sudo cp -r ~/vsomeip_libs/cmake/CommonAPI* /usr/local/lib/cmake/

# 라이브러리 캐시 업데이트
sudo ldconfig

# (선택) 임시 디렉토리 삭제
rm -rf ~/vsomeip_libs
```

**옵션 4: USB 메모리 사용 (네트워크 문제 시)**
```bash
# ECU1에서 USB 마운트 후
sudo mount /dev/sda1 /mnt
sudo cp -r /usr/local/lib/libvsomeip* /mnt/
sudo cp -r /usr/local/lib/libCommonAPI* /mnt/
sudo cp -r /usr/local/include/vsomeip /mnt/
sudo cp -r /usr/local/include/CommonAPI* /mnt/
sudo cp -r /usr/local/lib/cmake/vsomeip3 /mnt/
sudo cp -r /usr/local/lib/cmake/CommonAPI* /mnt/
sudo umount /mnt

# USB를 ECU2로 옮긴 후
sudo mount /dev/sda1 /mnt
sudo cp -r /mnt/libvsomeip* /usr/local/lib/
sudo cp -r /mnt/libCommonAPI* /usr/local/lib/
sudo cp -r /mnt/vsomeip /usr/local/include/
sudo cp -r /mnt/CommonAPI* /usr/local/include/
sudo mkdir -p /usr/local/lib/cmake
sudo cp -r /mnt/vsomeip3 /usr/local/lib/cmake/
sudo cp -r /mnt/CommonAPI* /usr/local/lib/cmake/
sudo umount /mnt

sudo ldconfig
```

#### 옵션 B: 직접 빌드
```bash
# VehicleControlECU의 빌드 스크립트 복사
scp team06@192.168.1.100:~/VehicleControlECU/build_vsomeip_rpi.sh ~/

chmod +x build_vsomeip_rpi.sh
./build_vsomeip_rpi.sh
```

### 5. GearApp 빌드

**⚠️ 주의:** 먼저 CommonAPI generated 파일이 있는지 확인하세요!

```bash
cd ~/GearApp

# 1. CommonAPI generated 파일 확인
ls -la ~/commonapi/generated/someip/v1/vehiclecontrol/

# 파일이 없다면 전송 필요 (개발 PC 또는 ECU1에서)
```

**CommonAPI 파일이 없는 경우:**

```bash
# 옵션 A: 개발 PC에서 WiFi로 전송
# 개발 PC에서 실행
scp -r ~/SEA-ME/DES_Head-Unit/commonapi/generated seame2025@<ECU2_WIFI_IP>:~/commonapi/

# 옵션 B: ECU1에서 Ethernet으로 전송 (라우트 설정 완료 후)
# ECU1에서 실행
scp -r ~/commonapi/generated seame2025@192.168.1.101:~/commonapi/
```

**빌드:**

```bash
cd ~/GearApp

# CommonAPI generated code 경로 설정 (절대 경로 사용!)
export COMMONAPI_GEN_DIR=/home/seame2025/commonapi/generated

# 이전 빌드 정리
rm -rf build

# 빌드
./build.sh
```

**✅ 빌드 성공 시 출력:**
```
🔨 Building...
[ 10%] Building CXX object CMakeFiles/GearApp.dir/src/main.cpp.o
...
[100%] Built target GearApp
✅ Build completed successfully!
Executable: /home/seame2025/GearApp/build/GearApp
```

### 6. 설정 파일 확인
```bash
# vsomeip 설정 확인
cat ~/GearApp/config/vsomeip_ecu2.json
```

주요 설정 확인:
- `"unicast": "192.168.1.101"` ✅
- `"routing": "VehicleControlECU"` ✅
- `"routing-manager": { "host": "192.168.1.100" }` ✅

### 7. GearApp 실행

**X11 디스플레이 설정 (GUI 표시용):**

```bash
# 로컬 모니터에 표시
export DISPLAY=:0

# 또는 SSH X11 포워딩 사용 (개발 PC에서 SSH 접속 시)
ssh -X pi@192.168.1.101
```

**애플리케이션 실행:**
```bash
cd ~/GearApp
./run.sh
```

**✅ 성공 시 출력 예시:**
```
═══════════════════════════════════════════════════════
Starting GearApp - vsomeip Client
ECU2 @ 192.168.1.101
═══════════════════════════════════════════════════════

[info] Initializing vsomeip application "GearApp"
[info] Instantiating routing manager [Proxy].
[info] Client is connecting to routing manager at 192.168.1.100
✅ Proxy created successfully
✅ Connected to VehicleControl service
GearApp is running...
```

---

## 통신 테스트

### ⚠️ 중요: 실행 순서

vsomeip 통신을 위해서는 **반드시 다음 순서**를 따라야 합니다:

1. **먼저 ECU1 (VehicleControlECU) 시작** → Routing Manager 역할
2. **그 다음 ECU2 (GearApp) 시작** → Client 역할

잘못된 순서로 실행하면 `/tmp/vsomeip-0 (No such file or directory)` 에러가 발생합니다.

---

### 1. ECU1 (VehicleControlECU) 시작

**터미널 1 - ECU1 접속:**
```bash
# ECU1 접속
ssh team06@192.168.1.100

# VehicleControlECU 실행
cd ~/VehicleControlECU
sudo ./run.sh  # PiRacer 하드웨어 사용 시
# 또는
./run.sh  # Mock 모드
```

**✅ 성공 시 출력 (ECU1):**
```
═══════════════════════════════════════════════════════
Starting VehicleControlECU - vsomeip Service
ECU1 @ 192.168.1.100
═══════════════════════════════════════════════════════

[info] Initializing vsomeip application "VehicleControlECU"
[info] Instantiating routing manager [Host].
[info] Service VehicleControl registered
[info] OFFER(1234): [1234.5678:0.0]
[info] Application(VehicleControlECU) is initialized
```

**핵심 확인 포인트:**
- ✅ `Instantiating routing manager [Host]` → ECU1이 Routing Manager로 동작
- ✅ `OFFER(1234): [1234.5678:0.0]` → VehicleControl 서비스 제공 시작

---

### 2. ECU2 (GearApp) 시작

**ECU1이 정상적으로 실행된 후**, 별도 터미널에서 ECU2 실행:

**터미널 2 - ECU2 접속:**
```bash
# ECU2 접속
ssh seame2025@192.168.1.101

# X11 디스플레이 설정 (GUI 표시용)
export DISPLAY=:0

# GearApp 실행
cd ~/GearApp
./run.sh
```

**✅ 성공 시 출력 (ECU2):**
```
═══════════════════════════════════════════════════════
Starting GearApp - vsomeip Client
ECU2 @ 192.168.1.101
═══════════════════════════════════════════════════════

[info] Initializing vsomeip application "client-sample"
[info] Instantiating routing manager [Proxy].
[info] Client [ffff] is connecting to [0] at /tmp/vsomeip-0
[info] REGISTERED to routing manager
✅ Proxy created successfully
✅ Connected to VehicleControl service
   Domain: "local"
   Instance: "vehiclecontrol.VehicleControl"
GearApp is running...
```

**핵심 확인 포인트:**
- ✅ `Instantiating routing manager [Proxy]` → ECU2가 Client로 동작
- ✅ `REGISTERED to routing manager` → ECU1 Routing Manager에 연결 성공
- ✅ `Connected to VehicleControl service` → 서비스 사용 가능

---

### 3. 서비스 디스커버리 확인

**ECU1 로그 (VehicleControlECU):**
```
[info] OFFER(1234): [1234.5678:0.0]
[info] Service Discovery: Offering service 0x1234
[info] Registering client 0xffff  ← ECU2 연결됨
[info] REQUEST(1234): [1234.5678:0.0] from Client 0xffff
```

**ECU2 로그 (GearApp):**
```
[info] REQUEST(1234): [1234.5678:0.0]
[info] Service 0x1234 is available
✅ Connected to VehicleControl service
```

---

### 4. RPC 호출 테스트

**ECU2 (GearApp)에서:**
- GUI에서 기어 버튼 클릭 (P → D)

**ECU1 로그:**
```
[VehicleControlStubImpl] Gear change requested: D
[VehicleControlStubImpl] Gear changed to: D
```

**ECU2 로그:**
```
[GearManager → vsomeip] Requesting gear change: "D"
✅ Gear change successful
[vsomeip → GearManager] Gear changed to: D
```

### 3. Event 브로드캐스트 테스트

**ECU1에서 PiRacer 조작 (또는 코드에서 이벤트 발생):**

**ECU1 로그:**
```
[VehicleControlStubImpl] Broadcasting vehicle state: Speed=15, Battery=85%
```

**ECU2 로그:**
```
[VehicleControlClient] Event received: Speed=15, Battery=85%
UI updated: Speed 15 km/h, Battery 85%
```

---

### 5. 양방향 통신 시나리오

**전체 통신 플로우:**

1. **ECU2**: 사용자가 GUI에서 "D" 버튼 클릭
2. **ECU2**: `requestGearChange("D")` RPC 호출
3. **Network**: SOME/IP 메시지 전송 (192.168.1.101 → 192.168.1.100)
4. **ECU1**: RPC 수신, 기어 변경 로직 실행
5. **ECU1**: 기어 변경 완료, RPC 응답 전송
6. **ECU1**: `GearChanged` 이벤트 브로드캐스트
7. **Network**: SOME/IP 이벤트 전송 (192.168.1.100 → 192.168.1.101)
8. **ECU2**: 이벤트 수신, UI 업데이트

---

## 문제 해결

### 문제 1: "Couldn't connect to routing manager"

**증상:**
```
[warning] local_client_endpoint::connect: Couldn't connect
[error] Routing manager not reachable
```

**해결:**
```bash
# ECU1에서 VehicleControlECU가 실행 중인지 확인
ps aux | grep VehicleControlECU

# 네트워크 연결 확인
ping 192.168.1.100

# ECU1의 vsomeip 로그 확인
# "Instantiating routing manager [Host]" 메시지가 있어야 함
```

### 문제 2: "Service not available"

**증상:**
```
⚠️  VehicleControl service is not available
```

**해결:**
```bash
# 1. 서비스 디스커버리 패킷 확인 (ECU1에서)
sudo tcpdump -i eth0 port 30490

# 2. 멀티캐스트 확인
ip maddr show eth0
# 224.244.224.245가 있어야 함

# 3. 방화벽 확인
sudo ufw status
# 비활성화 또는 포트 30490, 30509 열기
sudo ufw allow 30490/udp
sudo ufw allow 30509/udp
```

### 문제 3: 빌드 에러 "cannot find -lvsomeip3"

**증상:**
```
/usr/bin/ld: cannot find -lvsomeip3
```

**해결:**
```bash
# vsomeip 라이브러리 확인
ls -la /usr/local/lib/libvsomeip*

# 라이브러리 캐시 업데이트
sudo ldconfig

# CMake 캐시 삭제 후 재빌드
rm -rf build
./build.sh
```

### 문제 4: Qt GUI가 표시되지 않음

**증상:**
```
Could not find the Qt platform plugin "wayland"
```

**해결:**
```bash
# X11 디스플레이 설정
export DISPLAY=:0
export QT_QPA_PLATFORM=xcb

# 또는 SSH X11 포워딩 사용
ssh -X pi@192.168.1.101

# Qt 플랫폼 플러그인 설치
sudo apt install -y \
    libqt5gui5 \
    qt5-gtk-platformtheme \
    qml-module-qtquick-window2
```

### 문제 5: 권한 에러 (PiRacer 하드웨어)

**증상:**
```
Permission denied: /dev/i2c-1
```

**해결:**
```bash
# i2c 그룹에 사용자 추가
sudo usermod -a -G i2c,gpio pi
sudo reboot

# 또는 sudo로 실행
sudo ./run.sh
```

### 문제 6: IP 주소가 할당되지 않음

**증상:**
```
eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN
# IP 주소 없음, NO-CARRIER (케이블 연결 안 됨)
```

**원인:** Ethernet 케이블이 물리적으로 연결되지 않았거나, 상대방 장치가 꺼져있음

**해결:**

**1. 물리적 연결 확인:**
```bash
# 케이블 연결 상태 확인
ip link show eth0

# NO-CARRIER가 보이면 → 케이블 연결 안 됨
# LOWER_UP이 보이면 → 케이블 정상 연결됨
```

**체크리스트:**
- [ ] Ethernet 케이블이 양쪽 RPi에 제대로 꽂혀있는지 확인
- [ ] 케이블 LED 램프가 켜져있는지 확인 (링크 표시등)
- [ ] 상대방 RPi의 전원이 켜져있는지 확인
- [ ] 케이블이 손상되지 않았는지 확인 (다른 케이블로 테스트)

**2. 케이블 연결 후 상태 재확인:**
```bash
# 케이블 연결 후 다시 확인
ip link show eth0

# 정상 연결 시 출력:
# eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#        ^^^^^^^^^^^^^^^^^^^^^ LOWER_UP이 있어야 함

# 연결 활성화
sudo nmcli connection up eth0-static
```

**3. 두 RPi를 직접 연결하는 경우:**

최신 RPi는 Auto MDI-X 기능이 있어 크로스 케이블 없이 일반 케이블로 직접 연결 가능합니다.
- ✅ **일반 Ethernet 케이블** 사용 가능 (Cat5e, Cat6)
- ❌ **크로스 케이블** 필요 없음 (오래된 장비에서만 필요)

**4. NetworkManager 설정 확인:**
```bash
# 현재 연결 상태 확인
nmcli connection show

# 연결 상세 정보
nmcli connection show "Wired connection 1"

# NetworkManager 재시작
sudo systemctl restart NetworkManager

# NetworkManager 상태 확인
sudo systemctl status NetworkManager
```

**5. 수동 IP 설정 (임시, 재부팅 시 초기화됨):**
```bash
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up
```

**6. 영구 설정 (nmcli 사용):**
```bash
sudo nmcli connection modify "Wired connection 1" \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24

sudo nmcli connection up "Wired connection 1"
```

---

### 문제 7: Ping 실패 - "Destination Host Unreachable"

**증상:**
```
PING 192.168.1.101 (192.168.1.101) 56(84) bytes of data.
From 192.168.1.100 icmp_seq=1 Destination Host Unreachable
From 192.168.1.100 icmp_seq=2 Destination Host Unreachable
```

**원인:** IP는 설정되었지만 라우팅 테이블에 해당 네트워크 경로가 없음

**진단:**
```bash
# 1. IP 주소 확인 (설정되어 있는지)
ip addr show eth0
# inet 192.168.1.100/24 가 보여야 함

# 2. 라우팅 테이블 확인 (핵심!)
ip route show

# ❌ 문제: eth0 관련 경로가 없음
# 예: default via 192.168.86.1 dev wlan0 ... (wlan0만 있음)

# ✅ 정상: eth0 경로가 있어야 함
# 예: 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100

# 3. 인터페이스 상태 확인
ip link show eth0
# <BROADCAST,MULTICAST,UP,LOWER_UP> 확인 (LOWER_UP 중요)

# 4. 방화벽 확인
sudo ufw status
# inactive 또는 ICMP 허용 확인
```

**해결 방법:**

**옵션 A: IP 주소 재설정 (라우트 자동 생성, 추천):**
```bash
# 1. 기존 IP 삭제
sudo ip addr del 192.168.1.100/24 dev eth0

# 2. IP 재설정 (커널이 자동으로 라우트 생성)
sudo ip addr add 192.168.1.100/24 dev eth0

# 3. 라우팅 테이블 확인
ip route show
# "192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100" 확인

# 4. Ping 테스트
ping -c 4 192.168.1.101
```

**옵션 B: 수동으로 라우트 추가:**
```bash
# IP 주소가 이미 설정된 경우
sudo ip route add 192.168.1.0/24 dev eth0

# 확인
ip route show

# Ping 테스트
ping -c 4 192.168.1.101
```

**양방향 테스트:**
```bash
# ECU1 (192.168.1.100)에서
ping -c 4 192.168.1.101

# ECU2 (192.168.1.101)에서
ping -c 4 192.168.1.100
```

**✅ 성공 시 출력:**
```
PING 192.168.1.101 (192.168.1.101) 56(84) bytes of data.
64 bytes from 192.168.1.101: icmp_seq=1 ttl=64 time=0.234 ms
64 bytes from 192.168.1.101: icmp_seq=2 ttl=64 time=0.187 ms
64 bytes from 192.168.1.101: icmp_seq=3 ttl=64 time=0.192 ms
64 bytes from 192.168.1.101: icmp_seq=4 ttl=64 time=0.205 ms

--- 192.168.1.101 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3058ms
rtt min/avg/max/mdev = 0.187/0.204/0.234/0.018 ms
```

**⚠️ 주의:** 이 방법은 재부팅 시 초기화됩니다. 통신 테스트 완료 후 반드시 영구 설정을 적용하세요 (하단 "다음 단계" 참조).

---

### 문제 8: "Couldn't connect to /tmp/vsomeip-0" (GearApp 실행 시)

**증상:**
```
2025-10-31 14:16:50.472623 GearApp [warning] local_client_endpoint::connect: Couldn't connect to: /tmp/vsomeip-0 (No such file or directory / 2)
2025-10-31 14:16:50.472669 GearApp [info] Application(client-sample, ffff) is initialized (11, 100).
⚠️  VehicleControl service is not available
2025-10-31 14:16:50.475178 GearApp [warning] on_disconnect: Resetting state to ST_DEREGISTERED
```

**원인:**
- VehicleControlECU (ECU1)가 실행되지 않음
- Routing Manager가 시작되지 않아 `/tmp/vsomeip-0` Unix socket이 생성되지 않음
- ECU2는 ECU1의 Routing Manager에 연결하려고 시도하지만 실패

**vsomeip 통신 순서:**
1. ✅ **먼저 ECU1 (VehicleControlECU) 실행** → Routing Manager 시작 → `/tmp/vsomeip-0` 생성
2. ✅ **그 다음 ECU2 (GearApp) 실행** → Routing Manager에 연결 → Service Discovery 시작

**해결:**

**1. ECU1에서 VehicleControlECU 시작:**
```bash
# ECU1 (192.168.1.100)에서
ssh team06@192.168.1.100

cd ~/VehicleControlECU
sudo ./run.sh  # PiRacer 하드웨어 사용 시
# 또는
./run.sh  # Mock 모드

# ✅ 성공 시 출력:
# [info] Initializing vsomeip application "VehicleControlECU"
# [info] Instantiating routing manager [Host].
# [info] OFFER(1234): [1234.5678:0.0]
```

**2. ECU2에서 GearApp 시작:**
```bash
# ECU2 (192.168.1.101)에서
cd ~/GearApp
./run.sh

# ✅ 성공 시 출력:
# [info] Client [ffff] is connecting to [0] at /tmp/vsomeip-0
# [info] Service 0x1234 is available
# ✅ Connected to VehicleControl service
```

**3. 연결 확인:**

**ECU1 로그에서 확인:**
```
[info] Registering client 0xffff
[info] REQUEST(1234): [1234.5678:0.0] from Client 0xffff
```

**ECU2 로그에서 확인:**
```
[info] REGISTERED to routing manager at /tmp/vsomeip-0
✅ Connected to VehicleControl service
   Domain: "local"
   Instance: "vehiclecontrol.VehicleControl"
```

**문제 해결 체크리스트:**
- [ ] ECU1이 켜져 있는지 확인
- [ ] ECU1에서 `ps aux | grep VehicleControlECU` 실행하여 프로세스 확인
- [ ] ECU1과 ECU2 간 네트워크 연결 확인: `ping 192.168.1.100`
- [ ] ECU1을 먼저 시작했는지 확인 (순서 중요!)
- [ ] vsomeip 설정 파일 경로가 올바른지 확인

**⚠️ 주의사항:**
- **반드시 ECU1을 먼저 실행**해야 합니다 (Routing Manager 역할)
- ECU1이 종료되면 ECU2도 연결이 끊어집니다
- 재시작 시 ECU1 → ECU2 순서로 다시 실행

---

### 문제 9: SSH "No route to host" (ping은 성공하지만 SSH 실패)

**증상:**
```bash
# ECU2에서 실행
ping -c 4 192.168.1.100
# ✅ 성공: 64 bytes from 192.168.1.100...

ssh team06@192.168.1.100
# ❌ 실패: ssh: connect to host 192.168.1.100 port 22: No route to host
```

**원인:** 
- ping은 ICMP 프로토콜로 직접 전송되지만, SSH는 TCP 연결이 필요
- 라우팅 테이블에서 192.168.1.0/24 네트워크로의 명시적 경로가 없거나 우선순위가 낮음
- 기본 게이트웨이(wlan0)를 통해 라우팅을 시도하지만 실패

**진단:**
```bash
# 1. 라우팅 테이블 확인
ip route show

# ✅ 정상: 아래 경로가 있어야 함
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.101

# ❌ 문제: 위 경로가 없거나, wlan0 경로만 있음
# default via 192.168.86.1 dev wlan0 ...

# 2. 특정 IP로의 라우팅 경로 확인
ip route get 192.168.1.100

# ✅ 정상: 192.168.1.100 dev eth0 src 192.168.1.101 ...
# ❌ 문제: ... dev wlan0 ... (wlan0로 라우팅됨)
```

**해결 방법:**

**방법 1: 명시적 라우트 추가 (추천)**
```bash
# ECU2에서 실행
# 192.168.1.0 네트워크는 eth0를 통해 직접 연결
sudo ip route add 192.168.1.0/24 dev eth0 src 192.168.1.101

# 확인
ip route get 192.168.1.100
# 192.168.1.100 dev eth0 src 192.168.1.101 확인

# SSH 재시도
ssh team06@192.168.1.100
```

**방법 2: IP 재설정 (라우트 자동 생성)**
```bash
# 기존 IP 삭제 후 재설정
sudo ip addr del 192.168.1.101/24 dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0

# 자동으로 라우트 생성됨
ip route show
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.101 확인

# SSH 재시도
ssh team06@192.168.1.100
```

**방법 3: 역방향 전송 사용 (ECU1 → ECU2)**
```bash
# ECU1에서 실행 (ECU2로 파일 push)
scp -r /usr/local/lib/libvsomeip* seame2025@192.168.1.101:/tmp/
scp -r /usr/local/lib/libCommonAPI* seame2025@192.168.1.101:/tmp/

# ECU2에서 파일 이동
sudo mv /tmp/libvsomeip* /usr/local/lib/
sudo mv /tmp/libCommonAPI* /usr/local/lib/
sudo ldconfig
```

**방법 4: 직접 빌드 (네트워크 문제 회피)**
```bash
# ECU2에서 ECU1의 빌드 스크립트만 복사
# (작은 파일이므로 복사 가능할 수 있음)

# 또는 USB 메모리로 스크립트 전송 후 직접 빌드
./build_vsomeip_rpi.sh
```

**영구 해결 (재부팅 후에도 유지):**
```bash
# NetworkManager 사용 시
sudo nmcli connection modify eth0-static \
    ipv4.routes "192.168.1.0/24"

# 또는 /etc/network/interfaces 사용 시 (Debian 계열)
sudo nano /etc/network/interfaces
# 추가:
# auto eth0
# iface eth0 inet static
#     address 192.168.1.101
#     netmask 255.255.255.0
#     post-up ip route add 192.168.1.0/24 dev eth0
```

---

## 디버깅 팁

### 1. vsomeip 로그 레벨 증가
```json
// vsomeip_ecu1.json 또는 vsomeip_ecu2.json
{
  "logging": {
    "level": "debug",  // info → debug로 변경
    "console": "true"
  }
}
```

### 2. 네트워크 패킷 모니터링
```bash
# ECU1에서 SOME/IP 트래픽 확인
sudo tcpdump -i eth0 -n 'udp and (port 30490 or port 30509)'

# 또는 Wireshark 사용
sudo apt install wireshark
sudo wireshark &
# Filter: someip || udp.port == 30490
```

### 3. 실시간 로그 확인
```bash
# 터미널 분할 (tmux 사용)
sudo apt install tmux

tmux
# Ctrl+B, % : 화면 세로 분할
# Ctrl+B, " : 화면 가로 분할
# Ctrl+B, 방향키 : 창 이동

# 한쪽에서 ECU1 로그, 다른 쪽에서 ECU2 로그 동시 확인
```

### 4. 서비스 상태 확인 스크립트

**ECU1에서 실행:**
```bash
cat > check_service.sh << 'EOF'
#!/bin/bash
echo "=== VehicleControlECU Status ==="
echo "Process: $(ps aux | grep VehicleControlECU | grep -v grep)"
echo "IP: $(ip addr show eth0 | grep 'inet ')"
echo "Multicast: $(ip maddr show eth0 | grep 224.244.224.245)"
echo "Ports: $(sudo netstat -unlp | grep -E '30490|30509')"
EOF

chmod +x check_service.sh
./check_service.sh
```

**ECU2에서 실행:**
```bash
cat > check_client.sh << 'EOF'
#!/bin/bash
echo "=== GearApp Status ==="
echo "Process: $(ps aux | grep GearApp | grep -v grep)"
echo "IP: $(ip addr show eth0 | grep 'inet ')"
echo "Routing Manager reachable: $(ping -c 1 192.168.1.100 > /dev/null && echo 'YES' || echo 'NO')"
EOF

chmod +x check_client.sh
./check_client.sh
```

---

## 성공 체크리스트

### Phase 5.1: 네트워크 설정 (기본 테스트)
- [ ] 라즈베리파이 2대 Ethernet 케이블로 연결됨
- [ ] ECU1 IP: 192.168.1.100 설정 완료 (수동 설정)
- [ ] ECU2 IP: 192.168.1.101 설정 완료 (수동 설정)
- [ ] 라우팅 테이블 확인 (양쪽 모두 `192.168.1.0/24 dev eth0` 경로 존재)
- [ ] ECU1 → ECU2 ping 성공 (0% packet loss)
- [ ] ECU2 → ECU1 ping 성공 (0% packet loss)

### Phase 5.2: 빌드 및 실행
- [ ] ECU1: vsomeip & CommonAPI 빌드 완료
- [ ] ECU2: vsomeip & CommonAPI 빌드 완료
- [ ] ECU1: VehicleControlECU 빌드 완료
- [ ] ECU2: GearApp 빌드 완료
- [ ] ECU1: VehicleControlECU 실행 중 (Routing Manager 로그 확인)
- [ ] ECU2: GearApp 실행 중 (Service available 로그 확인)

### Phase 5.3: 통신 검증
- [ ] RPC 호출 성공 (기어 변경 동작 확인)
- [ ] Event 수신 성공 (속도/배터리 정보 표시 확인)

### Phase 5.4: 영구 설정 (테스트 완료 후)
- [ ] ECU1: NetworkManager 영구 IP 설정 완료
- [ ] ECU2: NetworkManager 영구 IP 설정 완료
- [ ] 재부팅 후 IP 유지 확인

---

## 다음 단계

### 즉시 수행: 영구 네트워크 설정

**⚠️ 중요:** 현재 수동으로 설정한 IP는 재부팅 시 사라집니다!

통신 테스트가 성공적으로 완료되면 **반드시** 영구 설정을 적용하세요:

**ECU1에서:**
```bash
# NetworkManager 영구 설정
sudo nmcli connection add \
    type ethernet \
    con-name eth0-static \
    ifname eth0 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24 \
    connection.autoconnect yes

# 재부팅 후 확인
sudo reboot
# ... 재부팅 후 ...
ip addr show eth0
```

**ECU2에서:**
```bash
# NetworkManager 영구 설정
sudo nmcli connection add \
    type ethernet \
    con-name eth0-static \
    ifname eth0 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.101/24 \
    connection.autoconnect yes

# 재부팅 후 확인
sudo reboot
# ... 재부팅 후 ...
ip addr show eth0
```

---

### 추가 개발 단계

성공적으로 통신이 확인되면:

1. **영구 네트워크 설정 완료** (위 참조) ✅
2. **성능 측정**: RPC 호출 지연시간, 이벤트 전송 주기 측정
3. **안정성 테스트**: 장시간 실행, 네트워크 단절/복구 시나리오
4. **추가 ECU 연결**: 다른 애플리케이션 (MediaApp, AmbientApp, IC_app) 추가
5. **Yocto 이미지 빌드**: 최종 배포용 커스텀 이미지 생성
6. **실제 차량 통합**: CAN 통신 추가, 차량 시그널 연동

---

## 참고 자료

- vsomeip 공식 문서: https://github.com/COVESA/vsomeip
- CommonAPI 가이드: https://github.com/COVESA/capicxx-core-tools
- SOME/IP 프로토콜: https://www.autosar.org/
- 프로젝트 문서: `/docs` 폴더의 다른 가이드 참조
