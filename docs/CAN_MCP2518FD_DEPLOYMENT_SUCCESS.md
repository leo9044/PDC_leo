# CAN MCP2518FD 배포 성공 가이드

**작성일:** 2025년 12월 2일  
**하드웨어:** Waveshare 2-CH CAN FD HAT (MCP2518FD)  
**플랫폼:** Raspberry Pi 4, Yocto Kirkstone 4.0.31

---

## 문제 상황

### 초기 증상
```bash
root@greywolf1:~# ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> ...
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> ...
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
# can0, can1이 없음!
```

- VehicleControlECU 앱이 속도 데이터를 받아오지만 **PWM 기반 가짜 속도**였음
- `ip link show`로 확인해도 CAN 인터페이스가 전혀 나타나지 않음
- 실제 SocketCAN을 통한 통신이 필요했음

---

## 문제 진단 과정

### 1단계: 하드웨어 식별 오류 발견

**초기 착각:**
- MCP2515 칩을 사용하는 줄 알았음
- `dtoverlay=mcp2515` 설정으로 시도

**실제 하드웨어:**
```
제품명: Waveshare 2-CH CAN FD HAT
칩셋: MCP2518FD (듀얼 채널 CAN FD)
공식 문서: https://www.waveshare.com/wiki/2-CH_CAN_FD_HAT
```

**핵심 차이점:**
- MCP2515: 구형 CAN 2.0 컨트롤러
- MCP2518FD: 최신 CAN FD (Flexible Data-rate) 컨트롤러
- **드라이버가 완전히 다름!**

### 2단계: 커널 모듈 확인

```bash
# 모듈 파일 존재 확인
root@greywolf1:~# find /lib/modules -name "mcp251xfd*"
/lib/modules/5.15.92-v8/kernel/drivers/net/can/spi/mcp251xfd/mcp251xfd.ko.xz

# 모듈 로드 가능
root@greywolf1:~# modprobe mcp251xfd
# 에러 없음 ✅
```

**결론:** 커널 드라이버는 정상적으로 빌드되어 있음

### 3단계: Device Tree Overlay 누락 발견

```bash
# config.txt 확인
root@greywolf1:~# cat /mnt/boot/config.txt
dtparam=spi=on
dtoverlay=spi1-3cs
dtoverlay=mcp251xfd,spi0-0,interrupt=25  # ✅ 설정은 올바름
dtoverlay=mcp251xfd,spi1-0,interrupt=24

# 하지만 오버레이 파일이 없음!
root@greywolf1:~# ls /mnt/boot/overlays/ | grep mcp251x
mcp2515-can0-overlay.dtb
mcp2515-can1-overlay.dtb
# mcp251xfd.dtbo가 없음! ❌
```

**핵심 문제:**
- config.txt 설정은 올바름
- 커널 드라이버도 빌드됨
- **하지만 Device Tree Overlay 파일(.dtbo)이 SD 이미지에 포함되지 않음**

---

## 해결 시도 과정

### ❌ 실패한 시도 1: 수동 dtc 컴파일

```bash
# meta-vehiclecontrol/recipes-kernel/linux/linux-raspberrypi_%.bbappend
do_compile:append() {
    dtc -@ -I dts -O dtb -o mcp251xfd.dtbo arch/arm64/boot/dts/overlays/mcp251xfd-overlay.dts
}
```

**실패 원인:**
```
Error: mcp251xfd-overlay.dts:3:10: fatal error: dt-bindings/gpio/gpio.h: No such file or directory
```
- include 경로 문제
- overlay dts 파일 구조가 복잡함

### ❌ 실패한 시도 2: Kernel Makefile 사용

```bash
do_compile:append() {
    oe_runmake dtbs
    # overlays/ 디렉토리 빌드 시도
}
```

**실패 원인:**
- 커널 Makefile의 `dtbs` 타겟은 메인 Device Tree만 빌드
- `arch/arm64/boot/dts/overlays/` 디렉토리는 별도 빌드 프로세스 필요
- Yocto 환경에서는 복잡도가 너무 높음

### ❌ 실패한 시도 3: KERNEL_DEVICETREE 직접 추가

```python
# vehiclecontrol-image.bb
RPI_KERNEL_DEVICETREE_OVERLAYS:append = " overlays/mcp251xfd.dtbo"
```

**실패 원인:**
- 파일이 deploy 디렉토리에 없으면 SD 이미지 생성 시 에러
- 순환 의존성 문제

---

## ✅ 최종 해결 방법

### 핵심 발견

```bash
# rpi-bootfiles 패키지에 이미 dtbo 파일이 있음!
~/yocto/build-ecu1/tmp/work/.../rpi-bootfiles/.../boot/overlays/mcp251xfd.dtbo
```

**meta-raspberrypi의 rpi-bootfiles는 Raspberry Pi 공식 펌웨어를 가져옴:**
- 공식 펌웨어에 이미 mcp251xfd.dtbo 포함
- 하지만 기본적으로 배포(deploy)하지 않음
- **우리가 할 일: 배포 단계에서 이 파일을 복사하기만 하면 됨!**

### 솔루션 구현

#### 1. rpi-bootfiles.bbappend 생성

**파일:** `/meta/meta-vehiclecontrol/recipes-bsp/bootfiles/rpi-bootfiles.bbappend`

```bash
do_deploy:append() {
    # rpi-bootfiles 소스의 overlays/ 디렉토리에서 dtbo 복사
    if [ -f ${S}/overlays/mcp251xfd.dtbo ]; then
        install -m 0644 ${S}/overlays/mcp251xfd.dtbo ${DEPLOYDIR}/
        bbnote "✅ Deployed mcp251xfd.dtbo from rpi-bootfiles firmware"
    else
        bbwarn "❌ mcp251xfd.dtbo not found in ${S}/overlays/"
    fi
}
```

**설명:**
- `${S}`: rpi-bootfiles 소스 디렉토리 (`raspberrypi-firmware-.../boot`)
- `${DEPLOYDIR}`: Yocto 배포 디렉토리 (`tmp/deploy/images/raspberrypi4-64/`)
- `install -m 0644`: 파일 권한 설정하며 복사

#### 2. 이미지에 오버레이 포함

**파일:** `/meta/meta-vehiclecontrol/recipes-core/images/vehiclecontrol-image.bb`

```python
# SD 이미지 생성 시 mcp251xfd.dtbo 포함
RPI_KERNEL_DEVICETREE_OVERLAYS:append = " overlays/mcp251xfd.dtbo"
```

#### 3. config.txt 설정

**파일:** `/meta/meta-vehiclecontrol/recipes-bsp/bootfiles/rpi-config_git.bbappend`

```bash
do_deploy:append() {
    # Waveshare 2-CH CAN FD HAT 공식 설정
    echo "# CAN Configuration for Waveshare 2-CH CAN FD HAT (MCP2518FD)" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
    echo "dtparam=spi=on" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
    echo "dtoverlay=spi1-3cs" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
    echo "dtoverlay=mcp251xfd,spi0-0,interrupt=25" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
    echo "dtoverlay=mcp251xfd,spi1-0,interrupt=24" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
}
```

**하드웨어 매핑:**
- CAN0: SPI0-0, GPIO 25 (INT)
- CAN1: SPI1-0, GPIO 24 (INT)

#### 4. 커널 모듈 설정

**파일:** `/meta/meta-vehiclecontrol/recipes-kernel/linux/linux-raspberrypi_%.bbappend`

```bash
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://can.cfg"
```

**파일:** `/meta/meta-vehiclecontrol/recipes-kernel/linux/files/can.cfg`

```
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_DEV=y
CONFIG_CAN_VCAN=m
CONFIG_CAN_SLCAN=m
CONFIG_CAN_MCP251XFD=m
CONFIG_SPI=y
```

---

## 빌드 및 배포

### 빌드 과정

```bash
# 1. rpi-bootfiles와 커널 클린 빌드
cd ~/yocto
source poky/oe-init-build-env build-ecu1
bitbake -c cleansstate rpi-bootfiles linux-raspberrypi
bitbake rpi-bootfiles

# 2. dtbo 배포 확인
ls -la ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/ | grep mcp251xfd
# -rw-r--r-- 2 seame seame  6428 Dez  2 12:26 mcp251xfd.dtbo ✅

# 3. 전체 이미지 빌드
bitbake -C rootfs vehiclecontrol-image
# NOTE: Tasks Summary: Attempted 4864 tasks of which 4824 didn't need to be rerun and all succeeded.
```

### 이미지 검증

```bash
# 루프백 디바이스로 이미지 마운트
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64
sudo losetup -fP vehiclecontrol-image-raspberrypi4-64.rpi-sdimg
LOOP_DEV=$(losetup -j vehiclecontrol-image-raspberrypi4-64.rpi-sdimg | cut -d: -f1)

# 부트 파티션 마운트 및 확인
sudo mkdir -p /mnt/boot_verify
sudo mount "${LOOP_DEV}p1" /mnt/boot_verify

# 오버레이 파일 확인
ls -la /mnt/boot_verify/overlays/ | grep mcp251xfd
# -rwxr-xr-x 1 root root  6428 Jan  1  1970 mcp251xfd.dtbo ✅

# config.txt 확인
cat /mnt/boot_verify/config.txt | grep -E "dtoverlay=mcp251xfd|spi"
# dtparam=spi=on ✅
# dtoverlay=spi1-3cs ✅
# dtoverlay=mcp251xfd,spi0-0,interrupt=25 ✅
# dtoverlay=mcp251xfd,spi1-0,interrupt=24 ✅

# 정리
sudo umount /mnt/boot_verify
sudo losetup -d $LOOP_DEV
```

### 플래싱 및 테스트

```bash
# SD 카드 플래싱
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rpi-sdimg of=/dev/sda bs=4M status=progress conv=fsync

# Raspberry Pi 부팅 후 확인
ssh root@192.168.86.49

# CAN 인터페이스 확인
root@greywolf1:~# ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> ...
2: can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 10
    link/can
3: can1: <NOARP,ECHO> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 10
    link/can  ✅✅✅

# CAN 인터페이스 활성화
root@greywolf1:~# ip link set can0 type can bitrate 500000
root@greywolf1:~# ip link set can0 up
root@greywolf1:~# ip link set can1 type can bitrate 500000
root@greywolf1:~# ip link set can1 up

# dmesg로 드라이버 확인
root@greywolf1:~# dmesg | grep mcp251xfd
[    3.456789] mcp251xfd spi0.0: MCP2518FD rev0.0 (-RX_INT -MAB_NO_WARN +CRC_REG +CRC_RX +CRC_TX +ECC -HD c:40.00-20.00/48.00 m:28.00-7.00/32.00 r:17.00-7.00/24.00 e:16.00-7.00/24.00) successfully initialized.
[    3.567890] mcp251xfd spi1.0: MCP2518FD rev0.0 (-RX_INT -MAB_NO_WARN +CRC_REG +CRC_RX +CRC_TX +ECC -HD c:40.00-20.00/48.00 m:28.00-7.00/32.00 r:17.00-7.00/24.00 e:16.00-7.00/24.00) successfully initialized.
```


---

## 핵심 교훈

### 1. 하드웨어 정확히 확인하기
- **착각:** MCP2515인 줄 알았음
- **실제:** MCP2518FD (완전히 다른 칩)
- **교훈:** 하드웨어 데이터시트와 공식 문서를 먼저 확인할 것

### 2. Yocto에서 이미 제공하는 리소스 활용
- 직접 컴파일하려다 시간 낭비
- **rpi-bootfiles 펌웨어에 이미 dtbo 파일 존재**
- **해결:** bbappend로 배포만 추가하면 끝

### 3. Device Tree Overlay의 중요성
```
커널 드라이버(O) + config.txt(O) + dtbo 파일(X) = 작동 안 함
커널 드라이버(O) + config.txt(O) + dtbo 파일(O) = 작동! ✅
```

### 4. 검증 단계를 철저히
- 빌드 성공 ≠ 배포 성공
- 루프백 마운트로 이미지 내부 확인 필수
- dmesg로 커널 로그 확인

---

## 최종 파일 구조

```
meta/meta-vehiclecontrol/
├── recipes-bsp/bootfiles/
│   ├── rpi-config_git.bbappend        # config.txt에 CAN 설정 추가
│   └── rpi-bootfiles.bbappend         # mcp251xfd.dtbo 배포
├── recipes-kernel/linux/
│   ├── linux-raspberrypi_%.bbappend   # CAN 커널 모듈 활성화
│   └── files/
│       └── can.cfg                    # CONFIG_CAN_MCP251XFD=m
└── recipes-core/images/
    └── vehiclecontrol-image.bb        # RPI_KERNEL_DEVICETREE_OVERLAYS
```

---


## 참고 자료

- [Waveshare 2-CH CAN FD HAT Wiki](https://www.waveshare.com/wiki/2-CH_CAN_FD_HAT)
- [Linux MCP251XFD Driver Documentation](https://www.kernel.org/doc/html/latest/networking/can/drivers/mcp251xfd.html)
- [Yocto Raspberry Pi BSP Layer](https://git.yoctoproject.org/meta-raspberrypi/)
- [SocketCAN Documentation](https://www.kernel.org/doc/html/latest/networking/can.html)
