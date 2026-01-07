# Yocto 이미지 빌드 시 고려사항

## 📋 목차
1. [개요](#개요)
2. [필수 포함 패키지](#필수-포함-패키지)
3. [네트워크 관리](#네트워크-관리)
4. [vsomeip 통신](#vsomeip-통신)
5. [Qt 및 GUI](#qt-및-gui)
6. [하드웨어 지원](#하드웨어-지원)
7. [개발 도구](#개발-도구)
8. [Yocto Layer 구성](#yocto-layer-구성)
9. [레시피 예시](#레시피-예시)

---

## 개요

DES Head-Unit 프로젝트를 위한 커스텀 Yocto 이미지 빌드 시 필요한 패키지, 설정, Layer 구성 정보를 정리합니다.

### 타겟 하드웨어
- **ECU1**: Raspberry Pi 4 (VehicleControlECU)
- **ECU2**: Raspberry Pi 4 (HU - GearApp, MediaApp, AmbientApp, IC_app)

### 프로젝트 아키텍처
```
ECU1 (Service Provider)         ECU2 (Service Consumer)
┌─────────────────────┐         ┌──────────────────────────┐
│ VehicleControlECU   │◄─vsomeip─►│ GearApp                  │
│ (Routing Manager)   │         │ AmbientApp               │
│                     │         │ MediaApp                 │
│ PiRacer 하드웨어    │         │ IC_app                   │
└─────────────────────┘         └──────────────────────────┘
```

---

## 필수 포함 패키지

### 1. 시스템 기본 패키지

#### Core Image Base
```bitbake
# conf/local.conf 또는 custom-image.bb
IMAGE_INSTALL:append = " \
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
    kernel-modules \
"
```

**포함 내용:**
- 부트로더, 커널
- 기본 파일시스템 유틸리티
- systemd (init system)

#### 빌드 도구
```bitbake
IMAGE_INSTALL:append = " \
    gcc \
    g++ \
    make \
    cmake \
    git \
    pkg-config \
"
```

---

## 네트워크 관리

### NetworkManager vs dhcpcd vs systemd-networkd

#### ⚠️ 중요: 네트워크 관리 도구 선택

현재 테스트 환경:
- **Raspberry Pi OS Desktop**: NetworkManager 사용
- **Raspberry Pi OS Lite**: dhcpcd 사용

Yocto 이미지에서 선택 가능한 옵션:

#### 옵션 A: NetworkManager (추천 - GUI 환경)

**장점:**
- GUI 네트워크 설정 도구 제공
- WiFi, Ethernet 통합 관리
- nmcli 명령어로 스크립팅 가능
- 동적 네트워크 변경에 강함

**단점:**
- 메모리 사용량 높음 (~20MB)
- 임베디드 시스템에 오버헤드

**Yocto 설정:**
```bitbake
# conf/local.conf
DISTRO_FEATURES:append = " wifi systemd"

# custom-image.bb
IMAGE_INSTALL:append = " \
    networkmanager \
    networkmanager-nmcli \
    networkmanager-nmtui \
"
```

**런타임 설정:**
```bash
# 고정 IP 설정 (ECU1)
nmcli connection add \
    type ethernet \
    con-name eth0-static \
    ifname eth0 \
    ipv4.method manual \
    ipv4.addresses 192.168.1.100/24

# 자동 시작
nmcli connection modify eth0-static connection.autoconnect yes
```

#### 옵션 B: systemd-networkd (추천 - 최소 시스템)

**장점:**
- systemd와 통합, 가벼움 (~2MB)
- 설정 파일 기반, 재현 가능
- 임베디드 환경에 최적

**단점:**
- GUI 없음
- WiFi 설정 복잡

**Yocto 설정:**
```bitbake
# conf/local.conf
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"

# custom-image.bb
IMAGE_INSTALL:append = " \
    systemd \
    systemd-networkd \
"
```

**런타임 설정:**
```bash
# /etc/systemd/network/10-eth0.network
[Match]
Name=eth0

[Network]
Address=192.168.1.100/24
```

```bash
# systemd-networkd 활성화
systemctl enable systemd-networkd
systemctl start systemd-networkd
```

#### 옵션 C: dhcpcd (경량, 단순)

**장점:**
- 매우 가벼움 (~1MB)
- Raspberry Pi OS 기본값

**단점:**
- 기능 제한적
- WiFi 관리 별도 필요

**Yocto 설정:**
```bitbake
# meta-raspberrypi에 포함됨
IMAGE_INSTALL:append = " dhcpcd5 "
```

**런타임 설정:**
```bash
# /etc/dhcpcd.conf
interface eth0
static ip_address=192.168.1.100/24
```

### 권장 사항

| 사용 케이스 | 네트워크 도구 | 이유 |
|------------|-------------|------|
| **GUI 있는 HU (ECU2)** | NetworkManager | 사용자 네트워크 설정 가능 |
| **Headless ECU (ECU1)** | systemd-networkd | 가볍고 안정적 |
| **최소 이미지** | dhcpcd | 메모리 절약 |

---

## vsomeip 통신

### vsomeip 3.5.8 포함

#### 레시피 생성 필요: `meta-headunit/recipes-middleware/vsomeip/vsomeip_3.5.8.bb`

```bitbake
SUMMARY = "SOME/IP implementation for COVESA"
HOMEPAGE = "https://github.com/COVESA/vsomeip"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=..."

DEPENDS = "boost"

SRC_URI = "git://github.com/COVESA/vsomeip.git;protocol=https;branch=master"
SRCREV = "3.5.8"

S = "${WORKDIR}/git"

inherit cmake

EXTRA_OECMAKE = " \
    -DENABLE_SIGNAL_HANDLING=1 \
    -DDIAGNOSIS_ADDRESS=0x10 \
"

FILES:${PN} += "${libdir}/*.so*"
```

#### 의존성 패키지
```bitbake
IMAGE_INSTALL:append = " \
    vsomeip \
    boost \
    boost-system \
    boost-thread \
    boost-filesystem \
    boost-log \
"
```

### CommonAPI C++ 3.2.4 포함

#### 레시피: `meta-headunit/recipes-middleware/commonapi/commonapi-core_3.2.4.bb`

```bitbake
SUMMARY = "CommonAPI C++ Core Runtime"
LICENSE = "MPL-2.0"

SRC_URI = "https://github.com/COVESA/capicxx-core-runtime/archive/3.2.4.tar.gz"

inherit cmake

FILES:${PN} += "${libdir}/*.so*"
```

#### 레시피: `meta-headunit/recipes-middleware/commonapi/commonapi-someip_3.2.4.bb`

```bitbake
SUMMARY = "CommonAPI C++ SOME/IP Runtime"
LICENSE = "MPL-2.0"

DEPENDS = "commonapi-core vsomeip"

SRC_URI = "https://github.com/COVESA/capicxx-someip-runtime/archive/3.2.4.tar.gz"

inherit cmake

FILES:${PN} += "${libdir}/*.so*"
```

#### 패키지 포함
```bitbake
IMAGE_INSTALL:append = " \
    commonapi-core \
    commonapi-someip \
"
```

---

## Qt 및 GUI

### Qt 5 포함

#### meta-qt5 Layer 추가
```bash
# conf/bblayers.conf
BBLAYERS += "/path/to/meta-qt5"
```

#### Qt 패키지
```bitbake
# ECU2 (HU) 전용
IMAGE_INSTALL:append = " \
    qtbase \
    qtdeclarative \
    qtquickcontrols \
    qtquickcontrols2 \
    qtgraphicaleffects \
    qtmultimedia \
"

# QML 모듈
IMAGE_INSTALL:append = " \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-window2 \
    qml-module-qtquick-layouts \
"
```

### Wayland Compositor (선택)

HU_MainApp을 Compositor로 사용할 경우:

```bitbake
DISTRO_FEATURES:append = " wayland"

IMAGE_INSTALL:append = " \
    wayland \
    weston \
    qtwayland \
"
```

---

## 하드웨어 지원

### PiRacer 하드웨어 (ECU1 전용)

#### I2C 지원
```bitbake
# conf/local.conf
ENABLE_I2C = "1"

# custom-image.bb
IMAGE_INSTALL:append = " \
    i2c-tools \
    libi2c-dev \
"

# 커널 모듈
KERNEL_MODULE_AUTOLOAD += "i2c-dev i2c-bcm2835"
```

#### GPIO 지원
```bitbake
IMAGE_INSTALL:append = " \
    python3-rpi-gpio \
    wiringpi \
"

# pigpio (PiRacer 필수)
IMAGE_INSTALL:append = " pigpio "
```

### 비디오 출력 (ECU2 - IC_app)

#### 듀얼 디스플레이 설정
```bash
# /boot/config.txt (런타임 설정)
# HDMI0: HU Display
# HDMI1: IC Display

hdmi_group:0=2
hdmi_mode:0=82   # 1920x1080 60Hz

hdmi_group:1=2
hdmi_mode:1=82
```

#### DRM/KMS 지원
```bitbake
DISTRO_FEATURES:append = " opengl"

IMAGE_INSTALL:append = " \
    mesa \
    libdrm \
"
```

---

## 개발 도구

### SSH 서버
```bitbake
IMAGE_INSTALL:append = " \
    openssh \
    openssh-sftp-server \
"

# 자동 시작
EXTRA_IMAGE_FEATURES += "ssh-server-openssh"
```

### 디버깅 도구
```bitbake
IMAGE_INSTALL:append = " \
    gdb \
    strace \
    tcpdump \
    htop \
    vim \
"
```

### 네트워크 진단
```bitbake
IMAGE_INSTALL:append = " \
    iproute2 \
    iputils \
    ethtool \
    net-tools \
"
```

---

## Yocto Layer 구성

### 프로젝트 Layer 생성

```bash
# Layer 생성
cd /path/to/yocto
bitbake-layers create-layer meta-headunit
```

### Layer 구조
```
meta-headunit/
├── conf/
│   └── layer.conf
├── recipes-middleware/
│   ├── vsomeip/
│   │   └── vsomeip_3.5.8.bb
│   └── commonapi/
│       ├── commonapi-core_3.2.4.bb
│       └── commonapi-someip_3.2.4.bb
├── recipes-apps/
│   ├── vehiclecontrol-ecu/
│   │   └── vehiclecontrol-ecu_1.0.bb
│   ├── gearapp/
│   │   └── gearapp_1.0.bb
│   ├── mediaapp/
│   │   └── mediaapp_1.0.bb
│   └── ambientapp/
│       └── ambientapp_1.0.bb
└── recipes-core/
    └── images/
        ├── headunit-image-ecu1.bb  # ECU1 전용 이미지
        └── headunit-image-ecu2.bb  # ECU2 전용 이미지
```

---

## 레시피 예시

### ECU1 이미지 (VehicleControlECU)

`meta-headunit/recipes-core/images/headunit-image-ecu1.bb`:

```bitbake
SUMMARY = "Head Unit ECU1 Image (VehicleControlECU)"
LICENSE = "MIT"

inherit core-image

# 기본 시스템
IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

# 네트워크 (systemd-networkd 사용)
IMAGE_INSTALL:append = " \
    systemd \
    systemd-networkd \
    iproute2 \
    iputils \
"

# vsomeip & CommonAPI
IMAGE_INSTALL:append = " \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    boost \
"

# PiRacer 하드웨어
IMAGE_INSTALL:append = " \
    i2c-tools \
    pigpio \
    python3-rpi-gpio \
"

# 애플리케이션
IMAGE_INSTALL:append = " \
    vehiclecontrol-ecu \
"

# 개발 도구
IMAGE_INSTALL:append = " \
    openssh \
    gdb \
    tcpdump \
"

# systemd 사용
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"

# I2C 활성화
ENABLE_I2C = "1"

# 루트 파일시스템 크기
IMAGE_ROOTFS_SIZE ?= "2097152"
```

### ECU2 이미지 (HU - GUI Apps)

`meta-headunit/recipes-core/images/headunit-image-ecu2.bb`:

```bitbake
SUMMARY = "Head Unit ECU2 Image (GUI Applications)"
LICENSE = "MIT"

inherit core-image

# 기본 시스템
IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

# 네트워크 (NetworkManager 사용)
IMAGE_INSTALL:append = " \
    networkmanager \
    networkmanager-nmcli \
"

# vsomeip & CommonAPI
IMAGE_INSTALL:append = " \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    boost \
"

# Qt 5 (GUI)
IMAGE_INSTALL:append = " \
    qtbase \
    qtdeclarative \
    qtquickcontrols2 \
    qtmultimedia \
    qtwayland \
"

# QML 모듈
IMAGE_INSTALL:append = " \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
"

# 애플리케이션
IMAGE_INSTALL:append = " \
    gearapp \
    mediaapp \
    ambientapp \
    ic-app \
"

# Wayland Compositor
IMAGE_INSTALL:append = " \
    wayland \
    weston \
"

# 개발 도구
IMAGE_INSTALL:append = " \
    openssh \
    gdb \
    tcpdump \
"

# systemd + Wayland
DISTRO_FEATURES:append = " systemd wayland"
VIRTUAL-RUNTIME_init_manager = "systemd"

# 듀얼 디스플레이 지원
DISTRO_FEATURES:append = " opengl"

# 루트 파일시스템 크기 (GUI 포함)
IMAGE_ROOTFS_SIZE ?= "4194304"
```

### VehicleControlECU 애플리케이션 레시피

`meta-headunit/recipes-apps/vehiclecontrol-ecu/vehiclecontrol-ecu_1.0.bb`:

```bitbake
SUMMARY = "VehicleControlECU Service Provider"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=..."

DEPENDS = "qtbase vsomeip commonapi-core commonapi-someip boost"

SRC_URI = "git://github.com/your-repo/DES_Head-Unit.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/app/VehicleControlECU"

inherit cmake_qt5

EXTRA_OECMAKE = " \
    -DCMAKE_PREFIX_PATH=${STAGING_DIR_TARGET}/usr \
    -DDEPLOY_PREFIX=${D}/usr \
"

do_install:append() {
    install -d ${D}/etc/vsomeip
    install -m 0644 ${S}/config/vsomeip_ecu1.json ${D}/etc/vsomeip/

    install -d ${D}/usr/bin
    install -m 0755 ${B}/VehicleControlECU ${D}/usr/bin/

    # systemd service
    install -d ${D}${systemd_system_unitdir}
    cat > ${D}${systemd_system_unitdir}/vehiclecontrol-ecu.service <<EOF
[Unit]
Description=VehicleControlECU Service
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/VehicleControlECU
Restart=always
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"

[Install]
WantedBy=multi-user.target
EOF
}

FILES:${PN} += " \
    /usr/bin/VehicleControlECU \
    /etc/vsomeip/vsomeip_ecu1.json \
    ${systemd_system_unitdir}/vehiclecontrol-ecu.service \
"

inherit systemd
SYSTEMD_SERVICE:${PN} = "vehiclecontrol-ecu.service"
SYSTEMD_AUTO_ENABLE = "enable"
```

---

## 빌드 실행

### 환경 설정
```bash
cd /path/to/yocto/poky
source oe-init-build-env build-headunit

# Layer 추가
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-qt5
bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-headunit
```

### conf/local.conf 설정
```bash
# 머신 선택
MACHINE = "raspberrypi4-64"

# systemd 사용
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"

# 네트워크 (ECU1: systemd-networkd, ECU2: NetworkManager)
# ECU1 빌드 시
# (systemd-networkd는 기본 포함)

# ECU2 빌드 시
DISTRO_FEATURES:append = " wifi"

# 병렬 빌드
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"
```

### 이미지 빌드
```bash
# ECU1 이미지
bitbake headunit-image-ecu1

# ECU2 이미지
bitbake headunit-image-ecu2
```

### SD 카드에 플래싱
```bash
# 빌드 결과 위치
ls tmp/deploy/images/raspberrypi4-64/

# 이미지 플래싱
sudo dd if=headunit-image-ecu1-raspberrypi4-64.wic of=/dev/sdX bs=4M status=progress
sync
```

---

## 최종 체크리스트

### Core 이미지 (양쪽 ECU 공통)
- [ ] systemd (init system)
- [ ] 네트워크 스택 (kernel networking)
- [ ] SSH 서버 (openssh)

### 네트워크 관리 (환경에 따라 선택)
- [ ] **ECU1**: systemd-networkd (추천) 또는 dhcpcd
- [ ] **ECU2**: NetworkManager (GUI) 또는 systemd-networkd

### vsomeip 통신 (양쪽 ECU 필수)
- [ ] vsomeip 3.5.8 (라이브러리 + 헤더)
- [ ] CommonAPI Core 3.2.4
- [ ] CommonAPI SOME/IP 3.2.4
- [ ] boost (system, thread, filesystem, log)

### Qt GUI (ECU2 전용)
- [ ] Qt 5 Base
- [ ] Qt Quick (QML)
- [ ] Qt Quick Controls 2
- [ ] Wayland 지원 (선택)

### 하드웨어 (ECU1 전용)
- [ ] I2C 커널 모듈 (i2c-dev)
- [ ] pigpio (PiRacer)
- [ ] GPIO 액세스

### 개발 도구 (선택)
- [ ] GDB (디버깅)
- [ ] tcpdump (네트워크 진단)
- [ ] strace (시스템 콜 추적)

---

## 참고 자료

- **Yocto Project**: https://www.yoctoproject.org/
- **meta-raspberrypi**: https://github.com/agherzan/meta-raspberrypi
- **meta-qt5**: https://github.com/meta-qt5/meta-qt5
- **vsomeip**: https://github.com/COVESA/vsomeip
- **CommonAPI**: https://github.com/COVESA/capicxx-core-tools

---

## 다음 단계

1. **Yocto 환경 구축**: Poky + Layer 추가
2. **vsomeip/CommonAPI 레시피 작성**: 빌드 테스트
3. **애플리케이션 레시피 작성**: CMake 통합
4. **이미지 빌드**: ECU1, ECU2 각각
5. **SD 카드 플래싱**: 하드웨어 테스트
6. **통합 테스트**: ECU1 ↔ ECU2 통신 검증

---

**작성일**: 2025년 10월 31일  
**작성자**: DES Head-Unit Team  
**버전**: 1.0
