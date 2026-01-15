# VehicleControlECU - Yocto Layer 구조

## Layer 구조

Yocto 프로젝트에서 이 애플리케이션을 빌드하려면 다음 구조로 meta-layer를 생성하세요:

```
meta-vehiclecontrol/
├── conf/
│   └── layer.conf
├── recipes-vehiclecontrol/
│   └── vehiclecontrol-ecu/
│       ├── vehiclecontrol-ecu_1.0.bb
│       └── files/
│           ├── src/
│           ├── CMakeLists.txt
│           ├── config/
│           │   ├── vsomeip_ecu1.json
│           │   └── commonapi_ecu1.ini
│           └── vehiclecontrol-ecu.service
├── recipes-vsomeip/
│   └── vsomeip/
│       └── vsomeip_3.5.8.bb
├── recipes-commonapi/
│   ├── commonapi-core/
│   │   └── commonapi-core_3.2.4.bb
│   └── commonapi-someip/
│       └── commonapi-someip_3.2.4.bb
└── recipes-commonapi-generated/
    └── commonapi-vehiclecontrol/
        ├── commonapi-vehiclecontrol_1.0.bb
        └── files/
            └── generated/
                ├── core/
                └── someip/
```

## layer.conf 예제

```bash
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "vehiclecontrol"
BBFILE_PATTERN_vehiclecontrol = "^${LAYERDIR}/"
BBFILE_PRIORITY_vehiclecontrol = "10"

LAYERDEPENDS_vehiclecontrol = "core qt5-layer"
LAYERSERIES_COMPAT_vehiclecontrol = "kirkstone"
```

## local.conf에 추가할 내용

```bash
# VehicleControlECU 이미지에 포함
IMAGE_INSTALL:append = " vehiclecontrol-ecu"

# I2C 활성화
ENABLE_I2C = "1"
KERNEL_MODULE_AUTOLOAD += "i2c-dev"

# systemd 사용
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"

# Qt5 지원
PACKAGECONFIG:append:pn-qtbase = " eglfs"

# 네트워크 설정
ENABLE_UART = "1"
```

## bblayers.conf에 추가할 내용

```bash
BBLAYERS ?= " \
  /path/to/poky/meta \
  /path/to/poky/meta-poky \
  /path/to/poky/meta-yocto-bsp \
  /path/to/meta-openembedded/meta-oe \
  /path/to/meta-openembedded/meta-python \
  /path/to/meta-openembedded/meta-networking \
  /path/to/meta-qt5 \
  /path/to/meta-raspberrypi \
  /path/to/meta-vehiclecontrol \
"
```

## 빌드 명령어

```bash
# 환경 설정
source poky/oe-init-build-env

# 이미지 빌드
bitbake core-image-minimal

# 또는 커스텀 이미지
bitbake vehiclecontrol-image
```

## 커스텀 이미지 레시피 (vehiclecontrol-image.bb)

```bash
require recipes-core/images/core-image-minimal.bb

DESCRIPTION = "VehicleControl ECU Image for Raspberry Pi"

IMAGE_INSTALL:append = " \
    vehiclecontrol-ecu \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    i2c-tools \
    qtbase \
    qtdeclarative \
    qtquickcontrols2 \
    pigpio \
"

# systemd 서비스 자동 시작
SYSTEMD_AUTO_ENABLE:pn-vehiclecontrol-ecu = "enable"

# 개발 도구 포함 (선택사항)
IMAGE_INSTALL:append = " \
    packagegroup-core-buildessential \
    cmake \
    git \
"

# 추가 공간 확보
IMAGE_ROOTFS_EXTRA_SPACE = "524288"
```

## 의존성 패키지

### pigpio 레시피 (recipes-support/pigpio/pigpio_git.bb)

```bash
SUMMARY = "Raspberry Pi GPIO library"
HOMEPAGE = "http://abyz.me.uk/rpi/pigpio/"
LICENSE = "Unlicense"
LIC_FILES_CHKSUM = "file://UNLICENCE;md5=4ae2d3867794c10f65dc475418d03c20"

SRC_URI = "git://github.com/joan2937/pigpio.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake DESTDIR=${D} prefix=${prefix} install
}

FILES:${PN} += "${libdir}/libpigpio.so.* ${bindir}/pigpiod"
FILES:${PN}-dev += "${includedir}/pigpio.h"
```

## 네트워크 설정 (recipes-connectivity/network/)

### 고정 IP 설정 파일

```bash
# /etc/systemd/network/eth0.network
[Match]
Name=eth0

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1
DNS=8.8.8.8
```

## 부트 설정 (config.txt 수정)

```bash
# recipes-bsp/bootfiles/rpi-config_git.bbappend

do_deploy:append() {
    # I2C 활성화
    echo "dtparam=i2c_arm=on" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
    
    # 추가 메모리 할당
    echo "gpu_mem=128" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
}
```

## SDK 생성

애플리케이션 개발을 위한 SDK 생성:

```bash
bitbake -c populate_sdk vehiclecontrol-image
```

생성된 SDK 설치:

```bash
./tmp/deploy/sdk/poky-glibc-x86_64-vehiclecontrol-image-cortexa72-raspberrypi4-64-toolchain-*.sh
```

## 참고사항

1. **Kirkstone (4.0)** 이상 버전 권장
2. **meta-raspberrypi** layer 필수
3. **meta-qt5** layer 필수 (Qt5 지원)
4. **meta-openembedded** layer 필수 (추가 패키지)
5. ARM64 타겟 설정: `MACHINE = "raspberrypi4-64"`
