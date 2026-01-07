# VehicleControlECU 라즈베리파이 배포 가이드 (빠른 테스트용)

## 🎯 목적
PiRacer + Raspberry Pi 환경에서 VehicleControlECU가 정상 작동하는지 테스트

---

## 📋 사전 준비

### 하드웨어
- ✅ Raspberry Pi 4 (또는 3B+)
- ✅ PiRacer 하드웨어 (모터 컨트롤러, 서보, 배터리 모니터)
- ✅ 이더넷 케이블 (개발 PC ↔ 라즈베리파이 연결)

### 네트워크 설정
라즈베리파이에 고정 IP 설정:
```bash
# 라즈베리파이에서
sudo nano /etc/dhcpcd.conf

# 다음 추가:
interface eth0
static ip_address=192.168.1.100/24

# 재부팅
sudo reboot
```

---

## 🚀 배포 순서 (3단계)

### **1단계: 개발 PC에서 파일 전송**

```bash
cd /home/leo/SEA-ME/DES_Head-Unit/app/VehicleControlECU

# deploy_to_rpi.sh 스크립트 실행 전에 IP 확인/수정
nano deploy_to_rpi.sh
# RPI_IP="192.168.1.100" 확인

# 파일 전송 (자동)
./deploy_to_rpi.sh
```

**전송되는 파일:**
- `app/VehicleControlECU/` - 앱 소스코드 및 설정
- `commonapi/generated/` - CommonAPI 생성 코드
- `install_folder/` - vsomeip, CommonAPI 라이브러리

---

### **2단계: 라즈베리파이에서 의존성 설치**

```bash
# SSH 접속
ssh pi@192.168.1.100

# 의존성 설치 (자동)
cd ~/DES_Head-Unit/app/VehicleControlECU
sudo ./install_dependencies.sh
```

**설치되는 항목:**
- 빌드 도구 (gcc, cmake, git)
- Qt5 라이브러리
- I2C 도구 (PiRacer 하드웨어 통신용)
- vsomeip & CommonAPI 라이브러리

⏱️ **소요 시간:** 약 5-10분

---

### **3단계: 빌드 및 실행**

```bash
# 라즈베리파이에서
cd ~/DES_Head-Unit/app/VehicleControlECU

# 빌드
./build.sh

# 실행
./run.sh
```

---

## ✅ 정상 작동 확인

실행 후 다음 메시지가 보이면 성공:

```
✅ VehicleControl service registered
   Domain: local
   Instance: vehiclecontrol.VehicleControl

🚀 VehicleControlECU Service is now running!
📡 Broadcasting vehicle state at 10Hz...
```

---

## 🔍 문제 해결

### 1. "vsomeip를 찾을 수 없습니다"
```bash
# 라이브러리 경로 확인
ldconfig -p | grep vsomeip

# 없으면 다시 설치
cd ~/DES_Head-Unit/install_folder
sudo cp -r lib/* /usr/local/lib/
sudo ldconfig
```

### 2. "I2C 장치를 찾을 수 없습니다"
```bash
# I2C 활성화 확인
ls /dev/i2c-*

# PiRacer 하드웨어 연결 확인
sudo i2cdetect -y 1
# PCA9685 (0x40), INA219 (0x42) 확인
```

### 3. "Qt 라이브러리 오류"
```bash
# Qt 버전 확인
qmake -version

# Qt5 재설치
sudo apt-get install --reinstall qt5-default qtbase5-dev
```

### 4. 빌드 오류
```bash
# CommonAPI 생성 코드 확인
ls ~/DES_Head-Unit/commonapi/generated/core/v1/vehiclecontrol/

# 없으면 개발 PC에서 다시 전송
# (개발 PC에서)
./deploy_to_rpi.sh
```

---

## 📊 테스트 체크리스트

- [ ] 라즈베리파이 네트워크 설정 (192.168.1.100)
- [ ] 파일 전송 완료 (`deploy_to_rpi.sh`)
- [ ] 의존성 설치 완료 (`install_dependencies.sh`)
- [ ] 빌드 성공 (`build.sh`)
- [ ] 서비스 시작 (`run.sh`)
- [ ] vsomeip routing manager 활성화 확인
- [ ] PiRacer 하드웨어 통신 확인 (I2C)
- [ ] 배터리 상태 읽기 테스트
- [ ] 게임패드 입력 테스트 (연결된 경우)

---

## 🎯 다음 단계

VehicleControlECU가 정상 작동하면:
1. GearApp 배포 (ECU2)
2. vsomeip 네트워크 통신 테스트
3. 전체 시스템 통합 테스트

---

**작성일:** 2025-10-30  
**테스트 환경:** Raspberry Pi 4, PiRacer, Ubuntu 개발 PC
