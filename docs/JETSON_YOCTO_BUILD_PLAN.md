# Jetson Orin Nano Yocto Build Plan

**작성일**: 2026년 1월 13일  
**목표**: Jetson Orin Nano ECU2용 커스텀 Yocto 이미지 빌드  
**현재 상태**: Ubuntu 22.04 개발 환경 → Yocto 임베디드 이미지로 전환

---

## 📋 목차

1. [현재 상황 분석](#1-현재-상황-분석)
2. [Yocto 빌드 목표](#2-yocto-빌드-목표)
3. [Layer 구성 계획](#3-layer-구성-계획)
4. [필수 BSP 및 메타 레이어](#4-필수-bsp-및-메타-레이어)
5. [빌드 환경 설정](#5-빌드-환경-설정)
6. [Recipe 작성 계획](#6-recipe-작성-계획)
7. [Weston 설정](#7-weston-설정)
8. [빌드 실행 절차](#8-빌드-실행-절차)
9. [검증 및 배포](#9-검증-및-배포)
10. [문제 해결 가이드](#10-문제-해결-가이드)

---

## 1. 현재 상황 분석

### 1.1 현재 환경
- **하드웨어**: Jetson Orin Nano (ARM64)
- **OS**: Ubuntu 22.04 LTS (JetPack R36.4.4)
- **Display**: EliteDisplay E273m 27-inch @ 1920x1080 (DP-1)
- **Weston**: 13.0.0 (NVIDIA 커스텀 빌드: `nvidia-l4t-weston`)
- **실행 방식**: Desktop-Shell 기반 단일 Weston

### 1.2 실행 중인 앱
- **GearApp**: 130x1000 (왼쪽 패널)
- **HomeScreenApp**: 1790x1000 (메인 영역)
- **MediaApp**: 1790x1000 (메인 영역)
- **AmbientApp**: 1790x1000 (메인 영역)
- **LayoutManagerApp**: 1920x1080 (네비게이션 오버레이)
- **vsomeip Routing Manager**: 통신 인프라

### 1.3 아키텍처 옵션

**현재 (Plan A - Desktop-Shell)**: 직접 Weston 연결
```
Weston (desktop-shell) ← wayland-0
  ├─> GearApp
  ├─> MediaApp
  ├─> AmbientApp
  ├─> HomeScreenApp
  └─> LayoutManagerApp
```

**향후 전환 가능 (Plan B - Nested Compositor)**: HU_MainApp_Compositor 사용
```
Weston (fullscreen-shell) ← wayland-0
  └─> HU_MainApp_Compositor (fullscreen) ← wayland-1
        ├─> GearApp (layout 제어)
        ├─> MediaApp (layout 제어)
        ├─> AmbientApp (layout 제어)
        └─> HomeScreenApp (layout 제어)
```

**장점**:
- Plan A: 현재 검증된 상태, 개발 빠름
- Plan B: 완벽한 layout 제어, 성능 최적화 가능 (fullscreen-shell)

### 1.4 주요 의존성
```
Qt 5.15.3
├─ qtbase5-dev
├─ qtdeclarative5-dev
├─ qtquickcontrols2-5-dev
├─ libqt5waylandcompositor5-dev (HU_MainApp용)
├─ qtwayland5
└─ qml-module-* (GUI 렌더링)

vsomeip 3.5.8
├─ libboost-all-dev
└─ CommonAPI 3.2.4

Weston 13.0.0
├─ libwayland-server
├─ desktop-shell.so
└─ DRM backend (NVIDIA)
```

### 1.5 현재 문제점
1. **Desktop-Shell 한계**: 앱 위치 제어 불가 (Wayland 프로토콜 한계)
2. **개발 환경 오버헤드**: Ubuntu Desktop의 불필요한 패키지들
3. **OTA 업데이트 미비**: 패키지 관리 시스템 없음
4. **재현성 부족**: 수동 설치로 인한 환경 차이

---

## 2. Yocto 빌드 목표

### 2.1 목표 이미지 특성
```
jetson-headunit-image
├─ 최소 루트파일시스템 (core-image-minimal 기반)
├─ Weston + Desktop-Shell (NVIDIA 최적화)
├─ Qt 5.15.x + Wayland 지원
├─ vsomeip + CommonAPI 런타임
├─ 5개 HU 앱 (GearApp, MediaApp, AmbientApp, HomeScreen, LayoutManager)
├─ systemd init system
├─ Read-only rootfs (OTA-safe)
└─ 타겟 사이즈: ~500MB (압축 이미지)
```

### 2.2 핵심 요구사항

#### 기능 요구사항
- ✅ Weston 13.0.0 Desktop-Shell 지원
- ✅ Qt Wayland 클라이언트 실행
- ✅ vsomeip 외부 통신 (multicast routing)
- ✅ DP-1 (DisplayPort) 1920x1080@60Hz 출력
- ✅ systemd 기반 서비스 관리
- ✅ 앱 자동 시작 (systemd units)

#### 성능 요구사항
- GPU 하드웨어 가속 (NVIDIA DRM)
- Qt Software Rendering (nested compositor 이슈 회피)
- vsomeip shared memory 통신
- 부팅 시간: 15초 이하 (Weston → 앱 실행)

#### 유지보수 요구사항
- OTA 업데이트 가능한 파티션 구조
- 개별 앱 업데이트 (독립 프로세스)
- 로그 수집 (journald)
- SSH 원격 접근

---

## 3. Layer 구성 계획

### 3.1 기존 meta-headunit 재활용

**현재 상태**:
```
/home/jetson/leo/DES_Head-Unit/meta/
├── meta-middleware/        # vsomeip, CommonAPI
├── meta-headunit/          # HU 앱들 (Raspberry Pi 타겟)
└── meta-instrumentcluster/ # IC 앱
```

**문제점**: 
- Raspberry Pi 4 (BCM2711) 타겟으로 작성됨
- NVIDIA Jetson BSP 미포함

### 3.2 새 레이어 생성: meta-jetson-headunit

```
meta-jetson-headunit/
├── conf/
│   ├── layer.conf
│   └── machine/
│       └── jetson-orin-nano-headunit.conf    # 커스텀 머신 설정
├── recipes-apps/
│   ├── hu-mainapp-compositor/              # NEW: Nested compositor
│   │   ├── hu-mainapp-compositor_2.0.bb
│   │   └── files/
│   │       ├── hu-mainapp-compositor.service
│   │       └── run_compositor.sh
│   ├── gearapp/
│   │   ├── gearapp_1.0.bb
│   │   └── files/
│   │       ├── gearapp.service
│   │       └── run_wayland0.sh
│   ├── mediaapp/
│   │   └── mediaapp_1.0.bb
│   ├── ambientapp/
│   │   └── ambientapp_1.0.bb
│   ├── homescreenapp/
│   │   └── homescreenapp_1.0.bb
│   └── layoutmanagerapp/
│       └── layoutmanagerapp_1.0.bb
├── recipes-core/
│   ├── images/
│   │   └── jetson-headunit-image.bb
│   └── systemd/
│       └── hu-services/
│           ├── hu-services_1.0.bb            # systemd unit 모음 + 모드 선택
│           └── files/
│               ├── hu-apps-desktop.target      # Desktop-Shell 모드
│               └── hu-apps-compositor.target  # Compositor 모드
├── recipes-graphics/
│   ├── vulkan/                               # NEW: Vulkan Wayland 지원
│   │   └── vulkan-loader_%.bbappend
│   └── weston/
│       ├── weston_13.0.bbappend
│       └── files/
│           ├── weston-jetson.ini             # Desktop-Shell (기본)
│           └── weston-jetson-fullscreen.ini # Fullscreen-Shell (선택)
├── recipes-connectivity/
│   └── vsomeip-config/
│       └── vsomeip-config_1.0.bb
└── README.md
```

### 3.3 Layer 의존성

```
meta-jetson-headunit
    ├── meta-tegra (NVIDIA BSP)
    ├── meta-middleware (vsomeip, CommonAPI)
    ├── meta-qt5 (Qt framework)
    ├── meta-openembedded/meta-oe (utilities)
    └── poky/meta (core)
```

---

## 4. 필수 BSP 및 메타 레이어

### 4.1 meta-tegra (NVIDIA Jetson Support)

**소스**: https://github.com/OE4T/meta-tegra

**역할**:
- Jetson Orin Nano BSP 제공
- NVIDIA L4T (Linux for Tegra) 통합
- CUDA, cuDNN 지원 (선택)
- Weston DRM backend (NVIDIA 최적화)
- DP-1 DisplayPort 지원

**버전 선택**:
```bash
# Yocto Kirkstone (LTS) + JetPack 6.0 (R36.x)
git clone https://github.com/OE4T/meta-tegra.git -b kirkstone-l4t-r36.4
```

**중요 설정**:
```bitbake
# conf/local.conf
MACHINE = "jetson-orin-nano-devkit"
L4T_VERSION = "36.4.4"  # JetPack R36.4.4
```

### 4.2 meta-qt5

**소스**: https://github.com/meta-qt5/meta-qt5

**역할**:
- Qt 5.15.x 빌드 레시피
- Qt Wayland 플러그인
- QML 모듈들

**버전**:
```bash
git clone https://github.com/meta-qt5/meta-qt5.git -b kirkstone
```

### 4.3 meta-openembedded

**소스**: https://github.com/openembedded/meta-openembedded

**필요 서브레이어**:
- `meta-oe`: 유틸리티 (htop, tmux 등)
- `meta-python`: Python 런타임
- `meta-networking`: 네트워크 도구

```bash
git clone https://github.com/openembedded/meta-openembedded.git -b kirkstone
```

### 4.4 poky (Yocto Reference Distribution)

**소스**: https://git.yoctoproject.org/poky

```bash
git clone https://git.yoctoproject.org/poky -b kirkstone
```

---

## 5. 빌드 환경 설정

### 5.1 호스트 PC 요구사항

**최소 사양**:
- CPU: 4코어 이상 (빌드 시간 단축)
- RAM: 16GB 이상 (32GB 권장)
- 디스크: 100GB 여유공간 (SSD 권장)
- OS: Ubuntu 22.04 LTS (검증된 환경)

**필수 패키지**:
```bash
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool
```

### 5.2 디렉토리 구조

```
/home/jetson/yocto-jetson/
├── poky/                               # Yocto 기본 레이어
├── meta-tegra/                         # NVIDIA BSP
├── meta-qt5/                           # Qt framework
├── meta-openembedded/                  # 유틸리티
│   ├── meta-oe/
│   ├── meta-python/
│   └── meta-networking/
├── meta-middleware/                    # vsomeip (재사용)
│   └── (DES_Head-Unit/meta/meta-middleware/ 복사)
└── meta-jetson-headunit/               # 새 레이어
    └── (신규 작성)
```

### 5.3 소스 다운로드

```bash
#!/bin/bash
# setup-yocto-jetson.sh

YOCTO_DIR="/home/jetson/yocto-jetson"
mkdir -p $YOCTO_DIR
cd $YOCTO_DIR

# 1. Poky (Yocto reference)
echo "Cloning poky (kirkstone)..."
git clone https://git.yoctoproject.org/poky -b kirkstone

# 2. meta-tegra (NVIDIA BSP)
echo "Cloning meta-tegra (kirkstone-l4t-r36.4)..."
git clone https://github.com/OE4T/meta-tegra.git -b kirkstone-l4t-r36.4

# 3. meta-qt5
echo "Cloning meta-qt5 (kirkstone)..."
git clone https://github.com/meta-qt5/meta-qt5.git -b kirkstone

# 4. meta-openembedded
echo "Cloning meta-openembedded (kirkstone)..."
git clone https://github.com/openembedded/meta-openembedded.git -b kirkstone

# 5. 기존 meta-middleware 복사
echo "Copying meta-middleware..."
cp -r /home/jetson/leo/DES_Head-Unit/meta/meta-middleware .

# 6. meta-jetson-headunit 생성
echo "Creating meta-jetson-headunit..."
mkdir -p meta-jetson-headunit
cd meta-jetson-headunit
# (아래 섹션에서 내용 작성)

echo "✓ Source download complete!"
echo "Next: cd poky && source oe-init-build-env build-jetson"
```

### 5.4 빌드 환경 초기화

```bash
cd /home/jetson/yocto-jetson/poky
source oe-init-build-env build-jetson
```

자동으로 `build-jetson/conf/` 디렉토리 생성:
- `local.conf`: 빌드 설정
- `bblayers.conf`: 레이어 경로

---

## 6. Recipe 작성 계획

### 6.1 이미지 레시피: jetson-headunit-image.bb

**위치**: `meta-jetson-headunit/recipes-core/images/jetson-headunit-image.bb`

```bitbake
SUMMARY = "Jetson Orin Nano Head Unit Image"
DESCRIPTION = "Minimal Wayland/Weston image with Qt HU apps"
LICENSE = "MIT"

# 베이스 이미지
require recipes-core/images/core-image-minimal.bb

# systemd 사용
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""

# Wayland 활성화 (X11 제거)
DISTRO_FEATURES:remove = "x11"
DISTRO_FEATURES:append = " wayland"

# 필수 패키지 그룹
IMAGE_INSTALL:append = " \
    packagegroup-core-boot \
    packagegroup-core-full-cmdline \
"

# Weston (NVIDIA 최적화)
IMAGE_INSTALL:append = " \
    weston \
    weston-init \
    weston-examples \
"

# Qt 5.15
IMAGE_INSTALL:append = " \
    qtbase \
    qtdeclarative \
    qtquickcontrols2 \
    qtwayland \
    qtgraphicaleffects \
    qtmultimedia \
    qtmultimedia-plugins \
    qml-module-qtquick2 \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    qml-module-qtquick-window2 \
    qml-module-qtgraphicaleffects \
    qml-module-qtmultimedia \
"

# vsomeip & CommonAPI
IMAGE_INSTALL:append = " \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    vsomeip-config \
"

# HU Applications
IMAGE_INSTALL:append = " \
    gearapp \
    mediaapp \
    ambientapp \
    homescreenapp \
    layoutmanagerapp \
    hu-mainapp-compositor \
    hu-services \
"

# 기본 실행 모드 선택
# PACKAGECONFIG:pn-hu-services = "desktop-shell"  # 기본값 (현재)
# PACKAGECONFIG:pn-hu-services = "compositor"     # HU_MainApp_Compositor 사용

# 네트워크 (systemd-networkd)
IMAGE_INSTALL:append = " \
    systemd-networkd \
    iproute2 \
    iputils \
"

# 개발 도구 (선택)
IMAGE_INSTALL:append = " \
    openssh \
    htop \
    procps \
    util-linux \
    nano \
"

# 루트파일시스템 크기
IMAGE_ROOTFS_SIZE ?= "2097152"  # 2GB

# 타겟 포맷
IMAGE_FSTYPES = "tegraflash"  # Jetson 플래시 이미지
```

### 6.2 HU_MainApp_Compositor Recipe

**위치**: `meta-jetson-headunit/recipes-apps/hu-mainapp-compositor/hu-mainapp-compositor_2.0.bb`

```bitbake
SUMMARY = "Head Unit Main App - Wayland Compositor"
DESCRIPTION = "Nested Wayland compositor for HU app window management"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtwayland"
RDEPENDS:${PN} = "qtwayland qtgraphicaleffects qml-module-qtquick-controls2 qml-module-qtwayland-compositor"

SRC_URI = " \
    file://CMakeLists.txt \
    file://src/ \
    file://qml/ \
    file://qml_compositor.qrc \
    file://run_compositor.sh \
    file://hu-mainapp-compositor.service \
"

S = "${WORKDIR}"

inherit cmake_qt5 systemd

EXTRA_OECMAKE = " \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_QMAKE_EXECUTABLE=${OE_QMAKE_PATH_EXTERNAL_HOST_BINS}/qmake \
"

# systemd 서비스 (기본적으로 비활성화)
SYSTEMD_SERVICE:${PN} = "hu-mainapp-compositor.service"
SYSTEMD_AUTO_ENABLE = "disable"  # 수동 활성화 (Desktop-Shell이 기본)

do_install:append() {
    # 실행 스크립트
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/run_compositor.sh ${D}${bindir}/hu-mainapp-compositor-run

    # systemd unit
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/hu-mainapp-compositor.service ${D}${systemd_unitdir}/system/

    # QML 리소스
    install -d ${D}${datadir}/hu-mainapp/qml
    cp -r ${WORKDIR}/qml/* ${D}${datadir}/hu-mainapp/qml/
}

FILES:${PN} += " \
    ${bindir}/HU_MainApp_Compositor \
    ${bindir}/hu-mainapp-compositor-run \
    ${datadir}/hu-mainapp/ \
"
```

**systemd unit 파일** (`hu-mainapp-compositor.service`):
```ini
[Unit]
Description=HU MainApp Nested Wayland Compositor
Requires=weston.service
After=weston.service
# Conflicts with desktop-shell apps (if enabled, disable gearapp/mediaapp/etc)
Conflicts=gearapp.service mediaapp.service ambientapp.service homescreenapp.service layoutmanagerapp.service

[Service]
Type=simple
User=weston
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="QT_QPA_PLATFORM=wayland"
Environment="QT_WAYLAND_DISABLE_WINDOWDECORATION=1"
ExecStart=/usr/bin/HU_MainApp_Compositor
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
```

**주의사항**:
- HU_MainApp_Compositor를 사용할 경우:
  1. Weston을 `fullscreen-shell.so`로 변경
  2. 개별 앱들을 `WAYLAND_DISPLAY=wayland-1`로 연결
  3. 개별 앱 systemd units를 `After=hu-mainapp-compositor.service`로 변경
- 기본적으로 비활성화 상태로 빌드 (Desktop-Shell이 기본)

### 6.3 GearApp Recipe

**위치**: `meta-jetson-headunit/recipes-apps/gearapp/gearapp_1.0.bb`

```bitbake
SUMMARY = "Head Unit Gear Selection App"
DESCRIPTION = "Qt/QML gear selector UI for Jetson HU"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2 vsomeip commonapi-core commonapi-someip"
RDEPENDS:${PN} = "qtwayland qtgraphicaleffects qml-module-qtquick-controls2"

SRC_URI = " \
    file://CMakeLists.txt \
    file://src/ \
    file://qml/ \
    file://qml.qrc \
    file://run_wayland0.sh \
    file://gearapp.service \
"

S = "${WORKDIR}"

inherit cmake_qt5 systemd

# vsomeip 경로 설정
EXTRA_OECMAKE = " \
    -DDEPLOY_PREFIX=${STAGING_DIR_HOST}${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
"

# systemd 서비스 활성화
SYSTEMD_SERVICE:${PN} = "gearapp.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install:append() {
    # 실행 스크립트
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/run_wayland0.sh ${D}${bindir}/gearapp-run

    # systemd unit
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/gearapp.service ${D}${systemd_unitdir}/system/

    # QML 리소스
    install -d ${D}${datadir}/gearapp/qml
    cp -r ${WORKDIR}/qml/* ${D}${datadir}/gearapp/qml/
}

FILES:${PN} += " \
    ${bindir}/GearApp \
    ${bindir}/gearapp-run \
    ${datadir}/gearapp/ \
"
```

**systemd unit 파일** (`gearapp.service`):
```ini
[Unit]
Description=Gear Selection App
Requires=weston.service vsomeip-routing.service
After=weston.service vsomeip-routing.service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=weston
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="QT_QPA_PLATFORM=wayland"
Environment="DEPLOY_PREFIX=/usr"
Environment="LD_LIBRARY_PATH=/usr/lib"
ExecStart=/usr/bin/GearApp
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 6.4 vsomeip-config Recipe

**위치**: `meta-jetson-headunit/recipes-connectivity/vsomeip-config/vsomeip-config_1.0.bb`

```bitbake
SUMMARY = "vsomeip Configuration Files"
DESCRIPTION = "Routing manager configuration for ECU2"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://routing_manager_ecu2.json \
    file://vsomeip-routing.service \
    file://10-multicast.network \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "vsomeip-routing.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # vsomeip 설정
    install -d ${D}${sysconfdir}/vsomeip
    install -m 0644 ${WORKDIR}/routing_manager_ecu2.json ${D}${sysconfdir}/vsomeip/

    # systemd unit
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/vsomeip-routing.service ${D}${systemd_unitdir}/system/

    # systemd-networkd: multicast 라우팅
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/10-multicast.network ${D}${sysconfdir}/systemd/network/
}

FILES:${PN} = " \
    ${sysconfdir}/vsomeip/ \
    ${sysconfdir}/systemd/network/ \
"
```

**multicast routing** (`10-multicast.network`):
```ini
[Match]
Name=enP8p1s0

[Network]
Address=192.168.1.101/24
Gateway=192.168.1.1
DNS=8.8.8.8

[Route]
Destination=224.0.0.0/4
Type=multicast
```

### 6.5 Weston 설정 Append (Desktop-Shell 모드)

**위치**: `meta-jetson-headunit/recipes-graphics/weston/weston_13.0.bbappend`

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://weston-jetson.ini \
"

do_install:append() {
    # Jetson 전용 설정 파일
    install -d ${D}${sysconfdir}/xdg/weston-13.0
    install -m 0644 ${WORKDIR}/weston-jetson.ini ${D}${sysconfdir}/xdg/weston-13.0/weston.ini
}
```

**weston-jetson.ini** (Desktop-Shell 모드 - 기본):
```ini
[core]
backend=drm-backend.so
shell=desktop-shell.so
require-input=false
gbm-format=rgb565

[output]
name=DP-1
mode=1920x1080@60
transform=normal

[shell]
panel-position=none
locking=false
background-image=/usr/share/weston/background.png
background-type=scale-crop

[keyboard]
keymap_layout=us

[launcher]
icon=/usr/share/weston/terminal.png
path=/usr/bin/weston-terminal
```

### 6.6 Weston 설정 (Fullscreen-Shell 모드 - 선택)

**위치**: `meta-jetson-headunit/recipes-graphics/weston/files/weston-jetson-fullscreen.ini`

```ini
# Fullscreen-Shell Mode (HU_MainApp_Compositor 사용 시)
[core]
backend=drm-backend.so
shell=fullscreen-shell.so  # ← Passthrough 모드
require-input=false
gbm-format=rgb565

[output]
name=DP-1
mode=1920x1080@60
transform=normal

[keyboard]
keymap_layout=us
```

**사용법**:
```bash
# HU_MainApp_Compositor 모드로 전환 시
cp /etc/xdg/weston-13.0/weston-jetson-fullscreen.ini /etc/xdg/weston-13.0/weston.ini
systemctl restart weston
systemctl enable hu-mainapp-compositor
systemctl disable gearapp mediaapp ambientapp homescreenapp layoutmanagerapp
```

### 6.7 Vulkan Loader Wayland 지원 (Jetson 전용)

**위치**: `meta-jetson-headunit/recipes-graphics/vulkan/vulkan-loader_%.bbappend`

**문제**: meta-tegra는 Vulkan을 X11 전용으로 강제 설정
```bitbake
# meta-tegra/recipes-graphics/vulkan/vulkan-loader_1.3.%.bbappend
REQUIRED_DISTRO_FEATURES:append:tegra = " x11"  # ← X11 강제!
PACKAGECONFIG:remove:tegra = "wayland"          # ← Wayland 제거!
```

**해결**: Layer priority(15 vs 5)를 이용해 override

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# meta-tegra의 x11 강제를 무력화
REQUIRED_DISTRO_FEATURES:remove:tegra = "x11"

# Wayland 지원 복원
PACKAGECONFIG:append:tegra = " wayland"
PACKAGECONFIG:remove:tegra = "x11"
```

**설명**:
- **Vulkan**: 크로스 플랫폼 3D 그래픽스 API (OpenGL 후속)
- **우리 프로젝트에서**: Qt는 주로 OpenGL ES 사용, Vulkan은 선택적 백엔드
- **필요성**: 직접 사용하지 않지만 NVIDIA가 제공하므로 Wayland 호환성 확보
- **Raspberry Pi와 차이**: 라즈베리파이는 Mesa 기반, Jetson은 NVIDIA 독점 드라이버

**중요**: 이 bbappend는 **Jetson 전용**이며 Raspberry Pi 빌드에는 불필요

---

## 7. Weston 설정

### 7.1 Desktop-Shell vs Fullscreen-Shell

**현재 선택**: Desktop-Shell (NVIDIA 검증 완료)

**이유**:
- IVI-Shell: Weston 13 호환 이슈
- Kiosk-Shell: 단일 앱만 지원
- Fullscreen-Shell: HU_MainApp_Compositor 사용 시 고려 (미래)

**현재 한계**:
- Desktop-Shell은 앱 위치 제어 불가
- 각 앱이 자체적으로 fullscreen/maximized 모드 사용
- Z-order는 실행 순서로 제어 시도 (불확실)

### 7.2 NVIDIA DRM Backend

**커널 모듈**: `nvidia_drm`

**systemd 자동 로드**:
```bash
# /etc/modules-load.d/nvidia.conf
nvidia_drm
```

**modprobe 옵션**:
```bash
# /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1
```

### 7.3 Weston Systemd Service

**파일**: `weston.service` (meta-tegra 제공)

**커스터마이징** (bbappend):
```ini
[Unit]
Description=Weston Wayland Compositor
Requires=multi-user.target
After=multi-user.target

[Service]
Type=notify
User=weston
Group=weston
Environment="XDG_RUNTIME_DIR=/run/user/1000"
Environment="WAYLAND_DISPLAY=wayland-0"
ExecStartPre=/bin/mkdir -p /run/user/1000
ExecStartPre=/bin/chown weston:weston /run/user/1000
ExecStart=/usr/bin/weston --config=/etc/xdg/weston-13.0/weston.ini
Restart=on-failure
RestartSec=10

[Install]
WantedBy=graphical.target
```

---

## 8. 빌드 실행 절차

### 8.1 bblayers.conf 설정

**파일**: `build-jetson/conf/bblayers.conf`

```bash
BBLAYERS ?= " \
  /home/jetson/yocto-jetson/poky/meta \
  /home/jetson/yocto-jetson/poky/meta-poky \
  /home/jetson/yocto-jetson/meta-tegra \
  /home/jetson/yocto-jetson/meta-openembedded/meta-oe \
  /home/jetson/yocto-jetson/meta-openembedded/meta-python \
  /home/jetson/yocto-jetson/meta-openembedded/meta-networking \
  /home/jetson/yocto-jetson/meta-qt5 \
  /home/jetson/yocto-jetson/meta-middleware \
  /home/jetson/yocto-jetson/meta-jetson-headunit \
"
```

### 8.2 local.conf 설정

**파일**: `build-jetson/conf/local.conf`

```bash
# Machine 설정
MACHINE = "jetson-orin-nano-devkit"

# L4T 버전
L4T_VERSION = "36.4.4"

# Distro features
DISTRO_FEATURES:append = " systemd wayland"
DISTRO_FEATURES:remove = "x11"

# systemd
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = ""

# 병렬 빌드
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# 다운로드/캐시 디렉토리
DL_DIR = "/home/jetson/yocto-jetson/downloads"
SSTATE_DIR = "/home/jetson/yocto-jetson/sstate-cache"

# 디스크 모니터 (빌드 중 용량 부족 방지)
BB_DISKMON_DIRS = "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K \
    ABORT,${TMPDIR},100M,1K \
    ABORT,${DL_DIR},100M,1K \
    ABORT,${SSTATE_DIR},100M,1K"

# 패키지 관리
PACKAGE_CLASSES = "package_deb"

# SDK 생성 (크로스 컴파일 도구)
EXTRA_IMAGE_FEATURES = "debug-tweaks tools-sdk dev-pkgs"

# 라이센스 허용 (CUDA 등)
LICENSE_FLAGS_ACCEPTED = "commercial"

# Qt 설정
QT_SELECTION = "qt5"
PACKAGECONFIG:append:pn-qtbase = " gles2 eglfs"

# 네트워크 (systemd-networkd)
PACKAGECONFIG:append:pn-systemd = " networkd resolved"

# 추가 이미지 포맷
IMAGE_FSTYPES:append = " tar.gz"
```

### 8.3 빌드 실행

```bash
cd /home/jetson/yocto-jetson/poky
source oe-init-build-env build-jetson

# 의존성 체크
bitbake-layers show-layers

# 빌드 시작 (약 6-12시간)
bitbake jetson-headunit-image
```

**빌드 산출물**:
```
build-jetson/tmp/deploy/images/jetson-orin-nano-devkit/
├── jetson-headunit-image-jetson-orin-nano-devkit.tegraflash.tar.gz
├── jetson-headunit-image-jetson-orin-nano-devkit.tar.gz
└── README_<timestamp>.txt
```

### 8.4 SDK 생성 (선택)

```bash
bitbake jetson-headunit-image -c populate_sdk
```

크로스 컴파일 SDK:
```
build-jetson/tmp/deploy/sdk/
└── poky-glibc-x86_64-jetson-headunit-image-aarch64-jetson-orin-nano-devkit-toolchain-*.sh
```

---

## 9. 검증 및 배포

### 9.1 이미지 플래시

**NVIDIA SDK Manager 사용**:
```bash
# 1. tegraflash 이미지 압축 해제
cd build-jetson/tmp/deploy/images/jetson-orin-nano-devkit/
tar -xzf jetson-headunit-image-jetson-orin-nano-devkit.tegraflash.tar.gz

# 2. Jetson을 Recovery Mode로 진입
# 3. SDK Manager 또는 flash.sh 사용
sudo ./flash.sh jetson-orin-nano-devkit mmcblk0p1
```

**USB 플래시 (간단)**:
```bash
# Recovery Mode 진입 후
sudo ./flash.sh jetson-orin-nano-devkit mmcblk0p1
```

### 9.2 부팅 검증

**시리얼 콘솔 확인**:
```bash
sudo screen /dev/ttyUSB0 115200
```

**부팅 로그 체크리스트**:
- [ ] Kernel 부팅 완료
- [ ] systemd 시작
- [ ] Weston 시작 (wayland-0 생성)
- [ ] vsomeip Routing Manager 시작
- [ ] 앱들 자동 시작 (systemd units)

### 9.3 기능 검증

**SSH 접속 후**:
```bash
# 1. Weston 실행 확인
ps aux | grep weston

# 2. wayland-0 소켓 확인
ls -la /run/user/1000/wayland-0

# 3. 앱 프로세스 확인
ps aux | grep -E "GearApp|MediaApp|AmbientApp|HomeScreen|LayoutManager"

# 4. vsomeip 소켓 확인
ls -la /tmp/vsomeip-0

# 5. 디스플레이 출력 확인
WAYLAND_DISPLAY=wayland-0 weston-simple-egl

# 6. systemd 서비스 상태
systemctl status weston
systemctl status vsomeip-routing
systemctl status gearapp
systemctl status mediaapp
```

### 9.4 성능 측정

```bash
# CPU 사용률
top -b -n 1 | head -20

# 메모리 사용량
free -h

# GPU 활용도 (NVIDIA)
sudo tegrastats

# Weston 프레임레이트
weston-debug gpu-stats
```

---

## 10. 문제 해결 가이드

### 10.1 Weston이 시작하지 않음

**증상**: `weston.service` failed

**확인 사항**:
```bash
# 1. DRM 드라이버 로드 확인
lsmod | grep nvidia_drm

# 2. DP-1 연결 확인
cat /sys/class/drm/card0/card0-DP-1/status  # connected

# 3. 권한 확인
ls -la /run/user/1000

# 4. Weston 로그
journalctl -u weston -f
```

**해결**:
```bash
# nvidia_drm 강제 로드
sudo modprobe nvidia_drm modeset=1

# XDG_RUNTIME_DIR 생성
mkdir -p /run/user/1000
chown weston:weston /run/user/1000
```

### 10.2 앱이 표시되지 않음

**증상**: 앱 프로세스는 실행 중이나 화면 없음

**확인**:
```bash
# 1. WAYLAND_DISPLAY 환경변수
echo $WAYLAND_DISPLAY  # wayland-0

# 2. Qt 플랫폼 플러그인
export QT_DEBUG_PLUGINS=1
./GearApp

# 3. Qt Wayland 플러그인 설치 확인
ls /usr/lib/qt5/plugins/platforms/libqwayland-*.so
```

**해결**:
```bash
# Wayland 플러그인 강제 지정
export QT_QPA_PLATFORM=wayland
```

### 10.3 vsomeip 통신 실패

**증상**: `vsomeip application isn't valid utility`

**확인**:
```bash
# 1. Routing Manager 실행 확인
ps aux | grep routingmanagerd

# 2. vsomeip 소켓 확인
ls -la /tmp/vsomeip-*

# 3. 멀티캐스트 라우팅
ip route | grep 224.0.0.0
```

**해결**:
```bash
# 멀티캐스트 라우트 추가
sudo ip route add 224.0.0.0/4 dev enP8p1s0
```

### 10.4 빌드 에러

#### 에러: `meta-tegra layer not compatible`

**해결**:
```bash
# Yocto 버전 일치 확인
cd meta-tegra && git branch -a
git checkout kirkstone-l4t-r36.4
```

#### 에러: `vulkan-loader requires distro feature 'x11'`

**원인**: meta-tegra가 Vulkan을 X11 전용으로 강제 설정

**해결**:
```bitbake
# meta-jetson-headunit/recipes-graphics/vulkan/vulkan-loader_%.bbappend 생성
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
REQUIRED_DISTRO_FEATURES:remove:tegra = "x11"
PACKAGECONFIG:append:tegra = " wayland"
PACKAGECONFIG:remove:tegra = "x11"
```

그 후 캐시 정리:
```bash
rm -rf tmp/cache
bitbake jetson-headunit-image
```

#### 에러: `Qt WebEngine not found`

**해결**:
```bitbake
# local.conf에서 제거
IMAGE_INSTALL:remove = "qtwebengine"
```

#### 에러: `CUDA not found (CUDA not supported)`

**해결**:
```bitbake
# CUDA 비활성화 (HU 앱에 불필요)
CUDA_VERSION = ""
CUDA_NVCC_EXTRA_ARGS = ""
```

---

## 11. 다음 단계

### 11.1 OTA 업데이트 통합

**고려 방안**:
- **SWUpdate**: A/B 파티션 업데이트
- **OSTree**: 원자적 업데이트
- **Mender**: 클라우드 기반 OTA

**구현 우선순위**:
1. 개별 앱 패키지 업데이트 (apt/deb)
2. 전체 이미지 OTA (SWUpdate)

### 11.2 듀얼 디스플레이 추가

**MST Hub 도착 후**:
- WJESOG Active MST Hub 사용 (DP 1.2 → Dual HDMI)
- Weston 설정에 두 번째 output 추가
- IC_app을 두 번째 디스플레이에 할당

```ini
[output]
name=DP-1-1
mode=1920x1080@60

[output]
name=DP-1-2
mode=1920x1080@60  # 또는 800x480 (IC 화면)
```

**참고 문서**: `/home/jetson/leo/DES_Head-Unit/docs/JETSON_ORIN_NANO_DP_MST_ANALYSIS.md`
- NVIDIA 공식 확인: 최대 2개 디스플레이 지원
- WJESOG 1x2 MST Hub 추천 ($30-40)
- xrandr/Weston으로 MST 제어 가능

### 11.3 성능 최적화

**Fullscreen-Shell 전환**:
- Weston을 passthrough 모드로 변경
- HU_MainApp_Compositor에서 모든 렌더링 수행
- GPU compositing 1회로 감소

---

## 12. 참고 자료

### 12.1 공식 문서
- **NVIDIA Jetson Weston/Wayland**: https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/SD/WindowingSystems/WestonWayland.html
- **meta-tegra GitHub**: https://github.com/OE4T/meta-tegra
- **Yocto Mega-Manual**: https://docs.yoctoproject.org/

### 12.2 프로젝트 문서
- `/home/jetson/leo/DES_Head-Unit/docs/JETSON_ORIN_NANO_ECU2_SETUP.md`
- `/home/jetson/leo/DES_Head-Unit/docs/DUAL_DISPLAY_WITHOUT_COMPOSITOR.md`
- `/home/jetson/leo/DES_Head-Unit/docs/YOCTO_BUILD_CONSIDERATIONS.md`

### 12.3 기존 Layer
- `/home/jetson/leo/DES_Head-Unit/meta/meta-middleware/`
- `/home/jetson/leo/DES_Head-Unit/meta/meta-headunit/` (Raspberry Pi용)

---

## 요약

### ✅ 수행할 작업
1. **meta-tegra 추가**: Jetson Orin Nano BSP 통합
2. **meta-jetson-headunit 생성**: 기존 meta-headunit을 Jetson용으로 수정
3. **Recipe 작성**: 6개 앱 (5개 + HU_MainApp_Compositor) + vsomeip + Weston 설정
4. **Dual Mode 지원**: Desktop-Shell(기본) / Compositor(선택) 모드
5. **systemd unit 작성**: 자동 시작 서비스 (모드별)
6. **Yocto 빌드**: `bitbake jetson-headunit-image`
7. **이미지 플래시**: Jetson에 배포
8. **검증**: 기능/성능 테스트

### ⏱️ 예상 소요 시간
- Layer 구성: 1일
- Recipe 작성: 2-3일
- 첫 빌드: 6-12시간 (이후 증분 빌드: 30분~2시간)
- 디버깅 & 검증: 2-3일
- **총합**: 약 1주일

### 🎯 성공 기준
- ✅ Jetson Orin Nano에서 부팅
- ✅ Weston Desktop-Shell 실행 (기본 모드)
- ✅ 5개 HU 앱 자동 시작 (Desktop-Shell 모드)
- ✅ HU_MainApp_Compositor 빌드 포함 (향후 전환 준비)
- ✅ 모드 전환 가능: Desktop-Shell ↔ Compositor
- ✅ vsomeip 통신 정상
- ✅ DP-1 @ 1920x1080 디스플레이 출력
- ✅ 개별 앱 업데이트 가능 (OTA 준비)
