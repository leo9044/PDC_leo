# ECU1 영구 수정 계획

**날짜:** 2025년 12월 5일 (내일)  
**목표:** ECU1 이미지에 `VSOMEIP_APPLICATION_NAME` 환경 변수를 영구적으로 추가

---

## 현재 상태

### 임시 수정 (현재)
- ECU1의 systemd 서비스 파일을 런타임에 수동 수정
- 재부팅 시 유지되지만, 새 이미지 플래싱 시 다시 수정 필요

### 영구 수정 (내일 할 일)
- Yocto 레시피 수정하여 이미지 빌드 시 자동 반영

---

## 수정할 파일

**파일 경로:**
```
/home/seame/ChangGit2/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/vehiclecontrol-ecu.service
```

**현재 내용:**
```ini
[Service]
Type=simple
User=root
WorkingDirectory=/usr/bin
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
Environment="LD_LIBRARY_PATH=/usr/lib"
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/VehicleControlECU
```

**수정 후:**
```ini
[Service]
Type=simple
User=root
WorkingDirectory=/usr/bin
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"  ← 이 줄 추가!
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
Environment="LD_LIBRARY_PATH=/usr/lib"
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/VehicleControlECU
```

---

## 작업 순서

### 1. 레시피 파일 수정

```bash
# 호스트 PC에서
cd /home/seame/ChangGit2/DES_Head-Unit

# 파일 편집
vi meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/vehiclecontrol-ecu.service

# Environment 줄 추가:
# Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"
```

### 2. 이미지 빌드

```bash
cd /home/seame/yocto
source poky/oe-init-build-env build-ecu1

# vehiclecontrol-ecu 레시피 클린
bitbake -c cleansstate vehiclecontrol-ecu

# 전체 이미지 빌드
bitbake vehiclecontrol-image
```

### 3. SD 카드 플래싱

```bash
# 결과 파일 확인
ls -lh /home/seame/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/*.rpi-sdimg

# SD 카드에 플래싱
sudo dd if=/home/seame/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/vehiclecontrol-image-raspberrypi4-64.rpi-sdimg \
    of=/dev/sdX \
    bs=4M \
    status=progress && sync
```

### 4. 검증

```bash
# ECU1 부팅 후 SSH 접속
ssh root@192.168.1.100

# systemd 서비스 파일 확인
cat /lib/systemd/system/vehiclecontrol-ecu.service | grep VSOMEIP_APPLICATION_NAME

# 예상 출력:
# Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"

# 서비스 로그 확인
journalctl -u vehiclecontrol-ecu.service -n 50 | grep "Host"

# 예상 출력:
# "Instantiating routing manager [Host]"
```

---

## 성공 기준

- [ ] `vehiclecontrol-ecu.service` 파일에 `VSOMEIP_APPLICATION_NAME` 환경 변수 포함
- [ ] 빌드 성공 (에러 없이 완료)
- [ ] 플래싱 성공
- [ ] ECU1 부팅 후 "Instantiating routing manager [Host]" 로그 확인
- [ ] ECU2와 통신 성공

---

## 백업 계획

만약 빌드 실패 시:

1. Git으로 변경 사항 되돌리기
```bash
cd /home/seame/ChangGit2/DES_Head-Unit
git checkout meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/vehiclecontrol-ecu.service
```

2. 임시 수정 방법 재사용
```bash
# ECU1에서
cat > /tmp/vehiclecontrol-ecu.service << 'EOF'
[Unit]
Description=VehicleControl ECU Service
After=network-online.target

[Service]
Type=simple
User=root
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="VSOMEIP_APPLICATION_NAME=VehicleControlECU"
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
ExecStart=/usr/bin/VehicleControlECU
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cp /tmp/vehiclecontrol-ecu.service /lib/systemd/system/vehiclecontrol-ecu.service
systemctl daemon-reload
systemctl restart vehiclecontrol-ecu.service
```

---

## 참고 사항

- 빌드 시간: 약 10-20분 (변경된 레시피만 재빌드)
- 전체 이미지 크기: 약 1.1GB
- SD 카드 플래싱 시간: 약 5-10분

---

**작성:** GitHub Copilot  
**확인:** 2025년 12월 4일
