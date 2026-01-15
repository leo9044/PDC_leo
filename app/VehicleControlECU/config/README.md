# VehicleControlECU Configuration Files

이 디렉토리는 VehicleControlECU의 vsomeip 및 CommonAPI 설정 파일을 포함합니다.

## 📁 파일 구성

### 🔧 로컬 개발 환경용
- `vsomeip_local.json` - 로컬 개발용 vsomeip 설정 (127.0.0.1)
- `commonapi_local.ini` - 로컬 개발용 CommonAPI 설정

### 🚀 배포 환경용 (Yocto on Raspberry Pi)
- `vsomeip_ecu1.json` - ECU1 배포용 vsomeip 설정 (192.168.1.100)
- `commonapi4someip_ecu1.ini` - ECU1 배포용 CommonAPI 설정

## 🎯 사용 방법

### 로컬 개발 시
```bash
export VSOMEIP_CONFIGURATION=$(pwd)/config/vsomeip_local.json
export COMMONAPI_CONFIG=$(pwd)/config/commonapi_local.ini
./build/VehicleControlECU
```

### 실제 배포 시 (Raspberry Pi ECU1)
```bash
export VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json
export COMMONAPI_CONFIG=/etc/commonapi/commonapi4someip_ecu1.ini
./VehicleControlECU
```

## 📊 네트워크 구성

### 로컬 개발
- IP: 127.0.0.1 (localhost)
- 통신: IPC (Inter-Process Communication)
- 모든 앱이 동일한 머신에서 실행

### 실제 배포
- ECU1 IP: 192.168.1.100 (VehicleControlECU)
- ECU2 IP: 192.168.1.101 (HU Apps, IC App)
- 통신: TCP/UDP over Ethernet
- 2개의 Raspberry Pi로 물리적 분리

## 🔌 서비스 정보

### VehicleControl Service
- Service ID: 0x1234 (4660)
- Instance ID: 0x5678 (22136)
- Port (Unreliable): 30501 (UDP)
- Port (Reliable): 30502 (TCP)
- Multicast Port: 30490

### 제공 기능
- **RPC Method**: setGearPosition (기어 변경 명령)
- **Event**: vehicleStateChanged (배터리, 속도, 기어 상태)
- **Event**: gearChanged (기어 변경 이벤트)
