# ECU 부팅부터 통신까지 완전 가이드

## 📋 목차
1. [하드웨어 연결 확인](#1-하드웨어-연결-확인)
2. [네트워크 설정 (부팅 후 매번)](#2-네트워크-설정-부팅-후-매번)
3. [vsomeip 프로세스 클린업](#3-vsomeip-프로세스-클린업)
4. [애플리케이션 실행](#4-애플리케이션-실행)
5. [통신 확인](#5-통신-확인)
6. [문제 발생시 디버깅](#6-문제-발생시-디버깅)

---

## 1. 하드웨어 연결 확인

### 물리적 연결
```bash
# 두 라즈베리파이를 이더넷 케이블로 직접 연결
ECU1 (eth0) ←→ 이더넷 케이블 ←→ ECU2 (eth0)
```

### 연결 상태 확인
```bash
# 케이블 연결 확인
ip link show eth0

# ✅ 정상: <BROADCAST,MULTICAST,UP,LOWER_UP> state UP
# ❌ 비정상: <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN
```

**문제 발생 시:**
- 케이블 양쪽 끝 다시 연결
- 다른 케이블로 교체 시도
- 두 ECU 모두 LOWER_UP 상태 확인

---

## 2. 네트워크 설정 (부팅 후 매번)

### ECU1 (VehicleControlECU) - 192.168.1.100
```bash
# IP 주소 설정
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up

# 멀티캐스트 라우팅 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip addr show eth0
ip route | grep 224
```

**예상 출력:**
```
inet 192.168.1.100/24 scope global eth0
224.0.0.0/4 dev eth0 scope link
```

### ECU2 (GearApp) - 192.168.1.101
```bash
# IP 주소 설정
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up

# 멀티캐스트 라우팅 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip addr show eth0
ip route | grep 224
```

**예상 출력:**
```
inet 192.168.1.101/24 scope global eth0
224.0.0.0/4 dev eth0 scope link
```

### 연결 테스트
```bash
# ECU1에서 ECU2로 ping
ping -c 3 192.168.1.101

# ECU2에서 ECU1로 ping
ping -c 3 192.168.1.100
```

**✅ 성공: 3 packets transmitted, 3 received, 0% packet loss**

---

## 3. vsomeip 프로세스 클린업

### 🚨 중요: 애플리케이션 실행 전 항상 수행!

**이 단계를 건너뛰면 발생하는 문제:**
- ❌ "other routing manager present" 에러
- ❌ [Proxy] 모드로 실행 (정상은 [Host])
- ❌ "/tmp/vsomeip-0 연결 실패"
- ❌ 멀티캐스트 그룹 가입 실패

### ECU1 클린업 스크립트
```bash
# 모든 vsomeip 관련 프로세스 강제 종료
killall -9 VehicleControlECU 2>/dev/null
killall -9 vsomeipd 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# vsomeip 소켓 완전 삭제
sudo rm -rf /tmp/vsomeip-*
sudo rm -rf /var/run/vsomeip-*

# 확인 (아무것도 출력되지 않아야 함)
ps aux | grep -E "VehicleControlECU|vsomeip"
ls -la /tmp/vsomeip-* 2>/dev/null
```

### ECU2 클린업 스크립트
```bash
# 모든 vsomeip 관련 프로세스 강제 종료
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# vsomeip 소켓 완전 삭제
sudo rm -rf /tmp/vsomeip-*
sudo rm -rf /var/run/vsomeip-*

# 확인 (아무것도 출력되지 않아야 함)
ps aux | grep -E "GearApp|vsomeip|client-sample"
ls -la /tmp/vsomeip-* 2>/dev/null
```

---

## 4. 애플리케이션 실행

### 실행 순서 (중요!)

#### 1️⃣ ECU1 먼저 실행
```bash
cd ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU
./run.sh
```

**예상 로그 (성공):**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Application(VehicleControlECU, 1001) is initialized
[info] OFFER(1001): [1234.5678:1.0]
[info] vSomeIP 3.5.8 | (default)
```

**✅ 확인 포인트:**
- `[Host]` 모드 (Proxy 아님!)
- `/tmp/vsomeip-0` 생성
- `OFFER [1234.5678]` 메시지

#### 2️⃣ ECU2 실행 (5초 후)
```bash
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

**예상 로그 (성공):**
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Client [0100] routes unicast:192.168.1.101
[info] REQUEST(0100): [1234.5678:1.4294967295]
[info] Service [1234.5678] is available.
Connected: true  ← 🎯 핵심 성공 메시지!
```

**✅ 확인 포인트:**
- `[Host]` 모드 (Proxy 아님!)
- `Service [1234.5678] is available`
- `Connected: true`

---

## 5. 통신 확인

### 5.1 Service Discovery 확인

#### ECU1에서 패킷 전송 확인
```bash
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v
```

**예상 출력:**
```
192.168.1.100.30490 > 224.244.224.245.30490: SOMEIP, service 65535, event 256, msgtype NOTIFICATION
```

#### ECU2에서 패킷 수신 확인
```bash
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v
```

**예상 출력:**
```
192.168.1.100.30490 > 224.244.224.245.30490: SOMEIP, service 65535, event 256, msgtype NOTIFICATION
```

### 5.2 멀티캐스트 그룹 확인
```bash
# 두 ECU 모두 실행
ip maddr show eth0 | grep 224.244.224.245
```

**예상 출력 (양쪽 모두):**
```
inet  224.244.224.245
```

### 5.3 기능 테스트

#### RPC 테스트 (ECU2 → ECU1)
1. GearApp GUI에서 기어 변경 버튼 클릭
2. **ECU2 로그 확인:**
   ```
   ✅ Gear change successful
   ```
3. **ECU1 로그 확인:**
   ```
   [info] RPC received: setGearPosition(D)
   ```

#### Event 테스트 (ECU1 → ECU2)
1. **ECU1 로그:**
   ```
   [info] Broadcasting event: VehicleSpeed = 50
   ```
2. **ECU2 로그:**
   ```
   [info] Event received: VehicleSpeed = 50
   ```

---

## 6. 문제 발생시 디버깅

### 문제 1: "Connected: false" / "service not available"

**원인:**
- vsomeip 프로세스 클린업 안함
- 네트워크 설정 누락
- 케이블 연결 불량

**해결:**
```bash
# 1. 클린업 다시 수행 (3단계)
killall -9 GearApp VehicleControlECU 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# 2. 네트워크 재설정 (2단계)
sudo ip addr add 192.168.1.10X/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0

# 3. 애플리케이션 재시작 (4단계)
```

### 문제 2: "[Proxy] 모드로 실행"

**증상:**
```
[info] Instantiating routing manager [Proxy]
[warning] Couldn't connect to: /tmp/vsomeip-0
```

**원인:** 클린업 안됨

**해결:**
```bash
# 강제 클린업
sudo pkill -9 -f vsomeip
sudo rm -rf /tmp/vsomeip-* /var/run/vsomeip-*

# 확인
ps aux | grep vsomeip  # 아무것도 없어야 함
ls /tmp/vsomeip-*      # "No such file" 나와야 함
```

### 문제 3: "other routing manager present"

**증상:**
```
[error] client-sample configured as routing but other routing manager present
```

**원인:** 이전 vsomeip 프로세스가 아직 살아있음

**해결:**
```bash
# 모든 프로세스 확인
ps aux | grep -E "vsomeip|GearApp|VehicleControlECU|client-sample"

# PID 확인 후 강제 종료
sudo kill -9 <PID>

# 또는 시스템 재부팅
sudo reboot
```

### 문제 4: 멀티캐스트 그룹 미가입

**확인:**
```bash
ip maddr show eth0 | grep 224.244.224.245
# 아무것도 안나오면 문제!
```

**원인:** [Proxy] 모드 또는 라우팅 설정 누락

**해결:**
```bash
# 멀티캐스트 라우팅 확인
ip route | grep 224.0.0.0

# 없으면 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 애플리케이션 재시작
```

### 문제 5: NO-CARRIER (케이블 연결 안됨)

**증상:**
```bash
ip link show eth0
# <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN
```

**해결:**
1. 이더넷 케이블 양쪽 재연결
2. 다른 케이블로 교체
3. 두 ECU 모두 확인
4. LOWER_UP 상태 확인

---

## 7. 완전 체크리스트 (부팅부터 통신까지)

### ECU1 체크리스트
```bash
# ✅ 1. 네트워크 설정
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up
sudo ip route add 224.0.0.0/4 dev eth0

# ✅ 2. 클린업
killall -9 VehicleControlECU 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# ✅ 3. 실행
cd ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU
./run.sh

# ✅ 4. 확인
# 로그에서 "[Host]" 확인
# 로그에서 "OFFER [1234.5678]" 확인
```

### ECU2 체크리스트
```bash
# ✅ 1. 네트워크 설정
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
sudo ip route add 224.0.0.0/4 dev eth0

# ✅ 2. 클린업
killall -9 GearApp 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# ✅ 3. 실행 (ECU1 실행 5초 후)
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh

# ✅ 4. 확인
# 로그에서 "[Host]" 확인
# 로그에서 "Service [1234.5678] is available" 확인
# 로그에서 "Connected: true" 확인
```

### 통신 성공 확인
```bash
# ✅ 1. 멀티캐스트 그룹 (양쪽 ECU)
ip maddr show eth0 | grep 224.244.224.245
# → inet 224.244.224.245 나와야 함

# ✅ 2. 패킷 수신 확인 (ECU2)
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -c 5
# → 192.168.1.100 → 224.244.224.245 패킷 보여야 함

# ✅ 3. 기능 테스트
# GearApp에서 기어 변경 → "✅ Gear change successful"
```

---

## 8. 발견된 주요 문제 요약

### 문제 1: vsomeip 라우팅 매니저 오해
**잘못된 이해:**
```json
// ❌ ECU2가 ECU1의 라우팅 매니저 사용 시도
"routing": "VehicleControlECU"
```

**올바른 이해:**
- vsomeip 라우팅 매니저는 **로컬 Unix 소켓** (`/tmp/vsomeip-0`)
- **네트워크로 공유 불가능**
- **각 ECU마다 독립적인 [Host] 라우팅 매니저 필요**

**해결:**
```json
// ✅ ECU2 자체 라우팅 매니저
"routing": "client-sample"
```

### 문제 2: 클라이언트 설정 오류
**잘못된 설정:**
```json
// ❌ 클라이언트 앱에 "services" 사용
"services": [...]
```

**올바른 설정:**
```json
// ✅ 클라이언트 앱은 "clients" 사용
"clients": [
    {
        "service": "0x1234",
        "instance": "0x5678",
        "unreliable": "30501"
    }
]
```

### 문제 3: 프로세스 클린업 누락
**증상:**
- "other routing manager present" 에러
- [Proxy] 모드로 실행
- 멀티캐스트 그룹 미가입

**원인:** 이전 vsomeip 프로세스가 소켓 파일 점유

**해결:** 매번 실행 전 클린업
```bash
killall -9 GearApp VehicleControlECU 2>/dev/null
sudo rm -rf /tmp/vsomeip-*
```

### 문제 4: 물리적 케이블 연결
**증상:**
```
NO-CARRIER state DOWN
```

**원인:** 이더넷 케이블 미연결 또는 불량

**해결:** 케이블 재연결, LOWER_UP 확인

### 문제 5: 멀티캐스트 라우팅 누락
**증상:** Service Discovery 실패

**원인:** 멀티캐스트 패킷 라우팅 설정 없음

**해결:**
```bash
sudo ip route add 224.0.0.0/4 dev eth0
```

### 문제 6: Application ID 충돌
**증상:** "other routing manager present"

**원인:** 0xFFFF는 예약되었거나 충돌 가능성

**해결:** 고유 ID 사용
```json
"id": "0x0100"  // 0xFFFF 대신
```

---

## 9. 핵심 성공 요소

### ✅ 네트워크 레이어
1. **물리 계층:** LOWER_UP 상태 (케이블 연결)
2. **네트워크 계층:** IP 주소 설정 (192.168.1.10X/24)
3. **라우팅:** 멀티캐스트 라우팅 (224.0.0.0/4)

### ✅ vsomeip 설정
1. **라우팅 매니저:** 각 ECU 독립적인 [Host]
2. **클라이언트 설정:** "clients" 섹션 사용
3. **Application ID:** 고유 ID (0x0100)

### ✅ 프로세스 관리
1. **클린업:** 매번 실행 전 vsomeip 프로세스 종료
2. **소켓 삭제:** /tmp/vsomeip-* 삭제
3. **실행 순서:** ECU1 먼저, ECU2 나중

### ✅ Service Discovery
1. **멀티캐스트 그룹:** 224.244.224.245 가입
2. **포트:** 30490 UDP
3. **패킷 전송:** 2초마다 OFFER 메시지

---

## 10. 자동화 스크립트

### ECU1 부팅 스크립트 (`~/start_ecu1.sh`)
```bash
#!/bin/bash

echo "=== ECU1 VehicleControlECU 시작 ==="

# 1. 네트워크 설정
echo "[1/4] 네트워크 설정..."
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up
sudo ip route add 224.0.0.0/4 dev eth0 2>/dev/null

# 2. 클린업
echo "[2/4] vsomeip 클린업..."
killall -9 VehicleControlECU 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-* /var/run/vsomeip-*

# 3. 대기
echo "[3/4] 3초 대기..."
sleep 3

# 4. 실행
echo "[4/4] VehicleControlECU 실행..."
cd ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU
./run.sh
```

### ECU2 부팅 스크립트 (`~/start_ecu2.sh`)
```bash
#!/bin/bash

echo "=== ECU2 GearApp 시작 ==="

# 1. 네트워크 설정
echo "[1/4] 네트워크 설정..."
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
sudo ip route add 224.0.0.0/4 dev eth0 2>/dev/null

# 2. 클린업
echo "[2/4] vsomeip 클린업..."
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-* /var/run/vsomeip-*

# 3. 대기
echo "[3/4] 5초 대기 (ECU1 준비 시간)..."
sleep 5

# 4. 실행
echo "[4/4] GearApp 실행..."
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

**사용법:**
```bash
# 실행 권한 부여 (최초 1회)
chmod +x ~/start_ecu1.sh
chmod +x ~/start_ecu2.sh

# 사용
~/start_ecu1.sh  # ECU1에서
~/start_ecu2.sh  # ECU2에서
```

---

## 📚 참고 문서
- [ECU_COMMUNICATION_FIX.md](./ECU_COMMUNICATION_FIX.md) - vsomeip 라우팅 매니저 아키텍처
- [COMMUNICATION_DEBUG_SOLUTION.md](./COMMUNICATION_DEBUG_SOLUTION.md) - 물리 네트워크 디버깅
- [vsomeip외부통신.md](./vsomeip외부통신.md) - 초기 트러블슈팅 로그

---

## 🎯 결론

**성공적인 ECU 간 통신을 위한 3가지 핵심:**

1. **네트워크 기본:** 케이블 연결 → IP 설정 → 멀티캐스트 라우팅
2. **vsomeip 설정:** 각 ECU 독립 [Host] → clients 섹션 → 고유 ID
3. **프로세스 관리:** 매번 클린업 → ECU1 먼저 → ECU2 나중

**이 3가지만 지키면 100% 성공!** 🚀
