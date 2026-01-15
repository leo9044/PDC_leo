# 2025년 12월 4일 - vsomeip 외부 통신 구현 변경 사항

**작업 날짜:** 2025년 12월 4일  
**목표:** ECU1-ECU2 간 vsomeip 외부 통신 구현  
**결과:** ✅ 성공 - 모든 앱 정상 작동 확인

---

## 📝 수정 파일 목록

### 1. ECU2 네트워크 설정

#### 1-1. systemd-networkd bbappend 파일
**파일:** `meta/meta-headunit/recipes-core/systemd/systemd_%.bbappend`

**수정 내용:**
- 네트워크 설정 파일 2개 추가 (WiFi, Ethernet)

**수정 이유:**
- ECU2가 WiFi(SSH)와 Ethernet(vsomeip) 동시 사용 필요
- systemd-networkd로 자동 네트워크 설정

**변경 사항:**
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

---

#### 1-2. WiFi 네트워크 설정 파일 (신규 생성)
**파일:** `meta/meta-headunit/recipes-core/systemd/files/20-wired-static.network`

**목적:**
- wlan0에 고정 IP 할당 (192.168.86.100/24)
- SSH 접속용 WiFi 인터페이스

**내용:**
```ini
[Match]
Name=wlan0

[Network]
Address=192.168.86.100/24
Gateway=192.168.86.1
DNS=8.8.8.8
```

---

#### 1-3. Ethernet 네트워크 설정 파일 (신규 생성)
**파일:** `meta/meta-headunit/recipes-core/systemd/files/20-eth0.network`

**목적:**
- eth0에 고정 IP 할당 (192.168.1.101/24)
- vsomeip 통신용 + 멀티캐스트 라우팅

**내용:**
```ini
[Match]
Name=eth0

[Network]
Address=192.168.1.101/24

[Route]
Destination=224.0.0.0/4
Scope=link
```

**핵심:**
- `[Route]` 섹션으로 멀티캐스트 라우트 자동 설정
- Service Discovery 멀티캐스트(224.244.224.245) 지원

---

#### 1-4. WiFi 인증 정보
**파일:** `/home/seame/yocto/build-headunit/conf/local.conf`

**추가 내용:**
```bash
WIFI_SSID = "SEA:ME WiFi Access"
WIFI_PASSWORD = "1fy0u534m3"
```

**수정 이유:**
- wpa_supplicant 자동 설정
- 부팅 시 WiFi 자동 연결

---

### 2. ECU2 vsomeip 설정

#### 2-1. vsomeip 레시피 수정
**파일:** `meta/meta-middleware/recipes-comm/vsomeip/vsomeip_3.5.8.bb`

**핵심 변경:**
```bash
# BEFORE
EXTRA_OECMAKE = "-DENABLE_SIGNAL_HANDLING=1"

# AFTER
EXTRA_OECMAKE = "-DENABLE_SIGNAL_HANDLING=1 -DBUILD_EXAMPLES=ON"

do_install:append() {
    install -d ${D}${bindir}
    if [ -f ${B}/examples/routingmanagerd/routingmanagerd ]; then
        install -m 0755 ${B}/examples/routingmanagerd/routingmanagerd ${D}${bindir}/
    fi
}

FILES:${PN} += "${bindir}/routingmanagerd"
```

**수정 이유:**
- **vsomeip는 기본적으로 routingmanagerd를 설치하지 않음**
- examples/ 디렉토리에만 소스 존재
- `BUILD_EXAMPLES=ON`으로 빌드 후 수동 설치 필요

**발견 과정:**
1. 처음에 vsomeipd 실행 → 바이너리 없음
2. routingmanagerd 실행 → 바이너리 없음
3. `find` 명령으로 검색 → `build/examples/routingmanagerd/` 발견
4. 빌드 옵션 활성화 + 수동 설치로 해결

---

#### 2-2. routingmanagerd 서비스 레시피 (신규 생성)
**파일:** `meta/meta-middleware/recipes-comm/vsomeip-routingmanager/vsomeip-routingmanager_1.0.bb`

**목적:**
- routingmanagerd를 systemd 서비스로 실행

**내용:**
```bash
DESCRIPTION = "vsomeip Routing Manager Service"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MPL-2.0;md5=815ca599c9df247a0c7f619bab123dad"

inherit systemd

DEPENDS = "vsomeip"
RDEPENDS:${PN} = "vsomeip"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://vsomeip-routingmanager.service"

SYSTEMD_SERVICE:${PN} = "vsomeip-routingmanager.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/vsomeip-routingmanager.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${systemd_system_unitdir}/vsomeip-routingmanager.service"
```

---

#### 2-3. routingmanagerd systemd 서비스 파일 (신규 생성)
**파일:** `meta/meta-middleware/recipes-comm/vsomeip-routingmanager/files/vsomeip-routingmanager.service`

**내용:**
```ini
[Unit]
Description=vsomeip Routing Manager
Documentation=https://github.com/COVESA/vsomeip
After=network-online.target systemd-networkd-wait-online.service
Wants=network-online.target
Requires=systemd-networkd.service

[Service]
Type=simple
User=root
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/routing_manager_ecu2.json"
ExecStart=/usr/bin/routingmanagerd
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**핵심:**
- `Environment="VSOMEIP_CONFIGURATION=..."` - 설정 파일 경로 지정
- `Restart=on-failure` - 자동 재시작
- 네트워크 준비 후 시작

---

#### 2-4. ECU2 앱 vsomeip 설정 수정
**파일들:**
- `app/HomeScreenApp/vsomeip_homescreen.json`
- `app/GearApp/config/vsomeip_gearapp.json`
- `app/MediaApp/config/vsomeip_mediaapp.json`
- `app/AmbientApp/config/vsomeip_ambientapp.json`
- `app/IC_app/config/vsomeip_ic.json`

**변경 사항:**
```json
// BEFORE
{
    "unicast": "127.0.0.1",  // 로컬 주소
    ...
}

// AFTER
{
    "unicast": "192.168.1.101",  // ECU2 Ethernet IP
    ...
    // "routing" 필드 제거 → Proxy 모드
}
```

**수정 이유:**
- 외부 통신을 위해 Ethernet IP 사용
- routingmanagerd에 연결하기 위해 Proxy 모드로 설정

---

### 3. ECU1 설정

#### 3-1. systemd 서비스 파일 수정
**파일:** `meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/vehiclecontrol-ecu.service`

**핵심 변경:**
```ini
# BEFORE
[Service]
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"

# AFTER
[Service]
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"  ← 추가!
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
```

**수정 이유:**
- **가장 중요한 수정!**
- `VSOMEIP_APPLICATION_NAME` 환경 변수 누락 시 Proxy 모드로 실행됨
- vsomeip가 설정 파일의 어떤 application을 사용할지 알려주는 필수 변수

**문제 발생 과정:**
1. ECU1 부팅 → VehicleControlECU 실행
2. 로그: `Couldn't connect to: /tmp/vsomeip-0` (Proxy 모드로 실행)
3. 수동 실행 시 `export VSOMEIP_APPLICATION_NAME=VehicleControlECU` → 정상 작동
4. systemd 서비스에 환경 변수 추가로 해결

**임시 vs 영구:**
- **임시 (오늘 적용):** ECU1에서 `/lib/systemd/system/vehiclecontrol-ecu.service` 직접 수정
- **영구 (내일 할 일):** Yocto 레시피 수정 후 이미지 재빌드

---

### 4. 기타 수정

#### 4-1. EXTERNALSRC 경로 수정 (13개 파일)
**파일들:** 모든 앱 레시피 (gearapp, mediaapp, ambientapp, etc.)

**변경:**
```bash
# BEFORE
EXTERNALSRC = "/home/seame/HU/chang_new/DES_Head-Unit/app/GearApp"

# AFTER
EXTERNALSRC = "/home/seame/ChangGit2/DES_Head-Unit/app/GearApp"
```

**수정 이유:**
- 프로젝트 디렉토리 변경에 따른 경로 업데이트

---

#### 4-2. IC_app main.cpp 수정
**파일:** `app/IC_app/main.cpp`

**변경:**
```cpp
// BEFORE
// #include "caninterface.h"  // 주석 처리됨

// AFTER
#include "caninterface.h"  // 주석 해제

// main()에 추가:
CanInterface canInterface;
```

**수정 이유:**
- IC_app 빌드 에러 수정
- CAN 인터페이스 기능 활성화

---

#### 4-3. headunit-image.bb 수정
**파일:** `meta/meta-headunit/recipes-core/images/headunit-image.bb`

**변경:**
```bash
# BEFORE
IMAGE_INSTALL += "vehiclecontrolmock"

# AFTER  
# IMAGE_INSTALL += "vehiclecontrolmock"  // 제거
IMAGE_INSTALL += "vsomeip-routingmanager"  // 추가
```

**수정 이유:**
- vehiclecontrolmock는 ECU2에 불필요 (ECU1에만 필요)
- routingmanagerd 서비스 추가

---

#### 4-4. local.conf PAM 추가
**파일:** `/home/seame/yocto/build-headunit/conf/local.conf`

**변경:**
```bash
# BEFORE
DISTRO_FEATURES:append = " wayland opengl"

# AFTER
DISTRO_FEATURES:append = " wayland pam opengl"
```

**수정 이유:**
- Weston (Wayland compositor) 빌드 에러 해결
- 팀원의 듀얼 디스플레이 설정에 PAM 필요

---

## 🔍 핵심 문제 및 해결

### 문제 1: routingmanagerd 바이너리 없음

**증상:**
```bash
/usr/bin/routingmanagerd: No such file or directory
```

**원인:**
- vsomeip 기본 빌드는 examples를 포함하지 않음
- routingmanagerd는 examples/ 디렉토리에만 존재

**해결:**
1. `BUILD_EXAMPLES=ON` cmake 옵션 추가
2. `do_install:append()`에서 수동으로 바이너리 복사
3. `FILES:${PN}` 에 경로 추가

---

### 문제 2: ECU1이 Proxy 모드로 실행

**증상:**
```bash
[warning] local_client_endpoint::connect: Couldn't connect to: /tmp/vsomeip-0
```

**원인:**
- `VSOMEIP_APPLICATION_NAME` 환경 변수 누락
- vsomeip가 설정 파일의 `"routing": "VehicleControlECU"` 무시

**해결:**
- systemd 서비스에 `Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"` 추가

**발견 과정:**
1. 수동 실행: `export VSOMEIP_APPLICATION_NAME=VehicleControlECU && /usr/bin/VehicleControlECU` → 성공
2. 로그에 "Instantiating routing manager [Host]" 확인
3. systemd 서비스에 환경 변수 추가

---

### 문제 3: WiFi 자동 연결

**증상:**
- SSH 접속 불가 (WiFi 미연결)

**해결:**
1. `local.conf`에 `WIFI_SSID`, `WIFI_PASSWORD` 추가
2. Yocto의 wpa_supplicant 자동 설정 기능 활용
3. systemd-networkd로 고정 IP 할당

---

## 📊 변경 사항 요약

| 분류 | 파일 수 | 핵심 변경 |
|------|---------|----------|
| ECU2 네트워크 | 4개 | WiFi + Ethernet 듀얼 인터페이스 |
| ECU2 vsomeip | 7개 | routingmanagerd 서비스 추가 |
| ECU1 설정 | 1개 | VSOMEIP_APPLICATION_NAME 환경 변수 |
| 앱 설정 | 5개 | unicast IP 변경 (127.0.0.1 → 192.168.1.101) |
| 경로 수정 | 13개 | EXTERNALSRC 경로 업데이트 |
| 기타 | 3개 | IC_app, headunit-image, local.conf |

**총 33개 파일 수정/생성**

---

## ✅ 테스트 결과

**성공:**
- ✅ ECU1 Host 모드 작동
- ✅ ECU2 routingmanagerd 작동
- ✅ Service Discovery 성공
- ✅ 모든 앱 통신 정상
- ✅ 속도 데이터 수신 확인

---

## 📌 다음 단계 (내일)

1. **ECU1 영구 수정**
   - `vehiclecontrol-ecu.service` 레시피 파일 수정
   - 이미지 재빌드 및 재플래싱

2. **Git 커밋**
   - 변경 사항 커밋 및 푸시
   - 커밋 메시지: "feat: ECU1-ECU2 vsomeip external communication implementation"

3. **문서 정리**
   - README 업데이트
   - 아키텍처 다이어그램 추가

---

**작성자:** GitHub Copilot  
**작성일:** 2025년 12월 4일  
**상태:** 완료 (통신 성공 확인)
