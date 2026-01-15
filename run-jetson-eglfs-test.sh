#!/bin/bash

# ════════════════════════════════════════════════════════
# Jetson EGLFS 테스트 - GPU 직접 렌더링
# X11 없이 Qt가 GPU로 직접 그리기
# ════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "Jetson Orin Nano - EGLFS (Direct GPU) Test"
echo "════════════════════════════════════════════════════════"

# 환경변수 설정
export DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM=eglfs  # GPU 직접 사용
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms  # DRM/KMS 사용

echo "Environment:"
echo "  QT_QPA_PLATFORM: ${QT_QPA_PLATFORM}"
echo "  QT_QPA_EGLFS_INTEGRATION: ${QT_QPA_EGLFS_INTEGRATION}"
echo ""
echo "⚠️  EGLFS는 한 번에 하나의 앱만 실행 가능합니다"
echo "   (Fullscreen 모드로 GPU 독점)"
echo ""

# 기존 프로세스 종료
killall -9 GearApp AmbientApp MediaApp 2>/dev/null

echo "Testing GearApp with EGLFS..."
echo ""

cd "${PROJECT_ROOT}/app/GearApp"
timeout 10 ./build/GearApp 2>&1 | head -50
