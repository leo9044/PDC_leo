# VehicleControlECU - Yocto Build Information

## 프로젝트 개요
- **애플리케이션 이름**: VehicleControlECU
- **버전**: 1.0
- **타겟 플랫폼**: Raspberry Pi (ARM64)
- **역할**: vsomeip 서비스 제공자 (Service Provider / Routing Manager)
- **통신**: vsomeip 3.5.8 + CommonAPI 3.2.4

---

## 빌드 의존성 (Build Dependencies)

### 시스템 라이브러리
```
build-essential
cmake (>= 3.16)
git
pkg-config
```

### Qt5 라이브러리
```
qtbase5-dev
qtdeclarative5-dev
qtquickcontrols2-5-dev
libqt5core5a
libqt5qml5
libqt5quick5
```

### 하드웨어 라이브러리
```
pigpio
libpigpio-dev
i2c-tools
libi2c-dev
```

### 통신 미들웨어
```
vsomeip (3.5.8)
  - 소스: https://github.com/COVESA/vsomeip.git
  - 브랜치/태그: 3.5.8
  - 설치 경로: /usr/local

CommonAPI Core (3.2.4)
  - 소스: https://github.com/COVESA/capicxx-core-runtime.git
  - 브랜치/태그: 3.2.4
  - 설치 경로: /usr/local

CommonAPI SomeIP (3.2.4)
  - 소스: https://github.com/COVESA/capicxx-someip-runtime.git
  - 브랜치/태그: 3.2.4
  - 설치 경로: /usr/local

Boost (>= 1.74)
  - libboost-system-dev
  - libboost-thread-dev
  - libboost-filesystem-dev
  - libboost-log-dev
```

---

## 런타임 의존성 (Runtime Dependencies)

### 필수 라이브러리
```
libqt5core5a
libqt5qml5
libqt5quick5
libpigpio1
libi2c0
libboost-system
libboost-thread
libboost-filesystem
libboost-log
libvsomeip3
libCommonAPI
libCommonAPI-SomeIP
```

### 필수 서비스
- I2C 활성화 (`dtparam=i2c_arm=on` in /boot/config.txt)
- GPIO 접근 권한 (root 또는 gpio 그룹)

---

## 빌드 설정

### CMake 옵션
```bash
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCOMMONAPI_GEN_DIR=/usr/local/share/commonapi/generated
```

### 필요한 파일 경로
```
소스 코드: app/VehicleControlECU/src/
CMake 설정: app/VehicleControlECU/CMakeLists.txt
CommonAPI 생성 코드: commonapi/generated/
vsomeip 설정: app/VehicleControlECU/config/vsomeip_ecu1.json
CommonAPI 설정: app/VehicleControlECU/config/commonapi_ecu1.ini
```

---

## 설치 경로 (Install Paths)

### 바이너리
```
/usr/local/bin/VehicleControlECU
```

### 설정 파일
```
/etc/vsomeip/vsomeip_ecu1.json
/etc/commonapi/commonapi_ecu1.ini
```

### CommonAPI 생성 코드
```
/usr/local/share/commonapi/generated/core/
/usr/local/share/commonapi/generated/someip/
```

### 로그 파일
```
/var/log/vsomeip_ecu1.log
```

---

## 환경 변수

### 실행 시 필요한 환경 변수
```bash
export VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json
export VSOMEIP_APPLICATION_NAME=VehicleControlECU
export COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

---

## 네트워크 설정

### vsomeip 통신
```
프로토콜: UDP/TCP
Unicast IP: 192.168.1.100
Netmask: 255.255.255.0
Service Discovery Multicast: 224.224.224.245:30490

서비스:
  - Service ID: 0x1234
  - Instance ID: 0x5678
  - Unreliable Port: 30501
  - Reliable Port: 30502
```

### Routing Manager
```
역할: Routing Manager (Host)
Socket: /tmp/vsomeip-0
애플리케이션 ID: 0x1001
```

---

## 하드웨어 요구사항

### PiRacer 하드웨어
```
I2C 장치:
  - Steering Controller: 0x40
  - Throttle Controller: 0x60
  - Battery Monitor (INA219): 기본 주소

GPIO:
  - pigpio 라이브러리 필요
  - root 권한 또는 gpio 그룹 필요
```

### 게임패드
```
입력 장치: /dev/input/js0
지원 컨트롤:
  - A 버튼: Drive (D)
  - B 버튼: Park (P)
  - X 버튼: Neutral (N)
  - Y 버튼: Reverse (R)
  - Left Analog Stick: Steering
  - Right Analog Stick Y: Throttle
```

---

## systemd 서비스 설정 (권장)

### 서비스 파일: /etc/systemd/system/vehiclecontrol.service
```ini
[Unit]
Description=VehicleControl ECU Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
Environment="LD_LIBRARY_PATH=/usr/local/lib"
ExecStart=/usr/local/bin/VehicleControlECU
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

---

## 빌드 순서

### 1. vsomeip 빌드
```bash
git clone https://github.com/COVESA/vsomeip.git
cd vsomeip
git checkout 3.5.8
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)
make install
ldconfig
```

### 2. CommonAPI Core 빌드
```bash
git clone https://github.com/COVESA/capicxx-core-runtime.git
cd capicxx-core-runtime
git checkout 3.2.4
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)
make install
ldconfig
```

### 3. CommonAPI SomeIP 빌드
```bash
git clone https://github.com/COVESA/capicxx-someip-runtime.git
cd capicxx-someip-runtime
git checkout 3.2.4
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DUSE_INSTALLED_COMMONAPI=ON ..
make -j$(nproc)
make install
ldconfig
```

### 4. CommonAPI 코드 생성
```bash
# 코드는 이미 생성되어 있음 (commonapi/generated/)
# 필요 시 재생성:
# ./commonapi/generate_code.sh
```

### 5. VehicleControlECU 빌드
```bash
cd app/VehicleControlECU
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCOMMONAPI_GEN_DIR=/usr/local/share/commonapi/generated ..
make -j$(nproc)
make install
```

---

## 테스트 방법

### 1. 단독 실행 테스트
```bash
sudo /usr/local/bin/VehicleControlECU
```

### 2. 로그 확인
```bash
tail -f /var/log/vsomeip_ecu1.log
journalctl -u vehiclecontrol -f
```

### 3. vsomeip 통신 확인
```bash
# 다른 터미널에서
netstat -an | grep 30501  # Unreliable port
netstat -an | grep 30502  # Reliable port
```

---

## 주의사항

1. **ARM64 아키텍처**: 반드시 Raspberry Pi (ARM64)에서 빌드해야 함
2. **root 권한**: GPIO 접근을 위해 root 권한 필요
3. **I2C 활성화**: /boot/config.txt에서 I2C 활성화 필수
4. **네트워크 설정**: 고정 IP 192.168.1.100 설정 권장
5. **vsomeip Routing Manager**: 이 앱이 Routing Manager 역할을 하므로 단일 인스턴스만 실행

---

## 문제 해결

### vsomeip 연결 실패
- VSOMEIP_APPLICATION_NAME 환경 변수 확인
- vsomeip_ecu1.json 경로 확인
- /tmp/vsomeip-0 소켓 파일 확인

### GPIO 초기화 실패
- root 권한으로 실행 확인
- pigpio 라이브러리 설치 확인

### I2C 장치 없음
- I2C 활성화 확인: `i2cdetect -y 1`
- PiRacer 하드웨어 연결 확인

---

## 라이선스 및 출처

### 사용된 오픈소스
- vsomeip: MPL-2.0 (COVESA)
- CommonAPI: MPL-2.0 (COVESA)
- Qt5: LGPL-3.0
- pigpio: Unlicense
- Boost: Boost Software License 1.0

---

## 참고 문서
- vsomeip 문서: https://github.com/COVESA/vsomeip/wiki
- CommonAPI 문서: https://github.com/COVESA/capicxx-core-tools/wiki
- PiRacer 문서: https://www.waveshare.com/wiki/PiRacer_AI_Kit
