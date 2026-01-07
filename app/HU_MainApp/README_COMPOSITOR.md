# HU_MainApp - Wayland Compositor

## 📋 개요

HU_MainApp은 **Wayland Compositor**로 재정의되었습니다.

### 역할 변경

#### Before (Phase 1-3 이전)
- ❌ 모든 Manager를 직접 생성 (MediaManager, GearManager, AmbientManager)
- ❌ vsomeip Service/Client 모두 포함
- ❌ 단일 프로세스에서 모든 것 실행
- ❌ 앱 간 통신 중개

#### After (Phase 4 완료)
- ✅ **Wayland Compositor 역할만 수행**
- ✅ 각 앱의 창을 합성하고 배치
- ✅ 비즈니스 로직 없음
- ✅ vsomeip 통신 관여 안 함

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│               HU_MainApp (Compositor)                    │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │  GearApp   │  │ MediaApp   │  │ AmbientApp │        │
│  │  Window    │  │  Window    │  │  Window    │        │
│  └────────────┘  └────────────┘  └────────────┘        │
│                                                          │
│  역할: 창 배치 및 합성만 담당                              │
└─────────────────────────────────────────────────────────┘
         ↑                 ↑                 ↑
         │                 │                 │
    독립 프로세스      독립 프로세스       독립 프로세스
         │                 │                 │
         └─────── vsomeip 통신 ────────────┘
```

## 🚀 사용 방법

### 빌드

```bash
./build_compositor.sh
```

### 실행

```bash
# 1. Compositor 시작
./run_compositor.sh

# 2. 각 앱을 별도 터미널에서 실행
cd ../GearApp && ./run.sh
cd ../MediaApp && ./run.sh
cd ../AmbientApp && ./run.sh
```

## 📦 파일 구조

```
HU_MainApp/
├── src/
│   ├── main_compositor.cpp      # Compositor 전용 main
│   ├── main.cpp                 # (구버전 - 사용 안 함)
│   ├── MediaControlStubImpl.*   # (구버전 - 삭제 예정)
│   └── MediaControlClient.*     # (구버전 - 삭제 예정)
├── qml/
│   ├── compositor.qml           # Compositor UI (NEW)
│   └── main.qml                 # (구버전 - 사용 안 함)
├── CMakeLists_compositor.txt    # Compositor 전용 빌드 (NEW)
├── CMakeLists.txt               # (구버전 - 사용 안 함)
├── build_compositor.sh          # Compositor 빌드 스크립트
└── run_compositor.sh            # Compositor 실행 스크립트
```

## ⚠️ 중요 사항

### 통신 방식
- **HU_MainApp은 앱 간 통신에 관여하지 않습니다**
- 모든 통신은 vsomeip를 통해 이루어집니다:
  - GearApp ↔ VehicleControlECU (기어 변경)
  - MediaApp → AmbientApp (볼륨 → 밝기)
  - VehicleControlECU → AmbientApp (기어 → 색상)

### 배포 환경
- ECU2에서 실행
- 각 앱은 독립 프로세스로 실행
- Compositor는 단순히 화면 레이아웃만 관리

## 🔄 마이그레이션 노트

Phase 1-3에서 사용하던 통합 모드(`main.cpp`)는 더 이상 사용하지 않습니다.

**변경 사항:**
1. ✅ Manager 의존성 제거
2. ✅ vsomeip 코드 제거
3. ✅ 단순 Compositor로 전환
4. ✅ 각 앱 독립 프로세스화

**다음 단계:**
- 구버전 파일 정리 (main.cpp, MediaControlStubImpl 등)
- 실제 Wayland Compositor 구현 (Qt Wayland Compositor 모듈 사용)
