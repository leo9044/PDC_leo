#!/bin/bash

# ════════════════════════════════════════════════════════
# Jetson Orin Nano ECU2 통합 실행 스크립트
# - offscreen 모드로 모든 앱 실행 (UI 없이 로직만)
# - vsomeip 통신 테스트용
# ════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "Jetson Orin Nano ECU2 - All Apps"
echo "════════════════════════════════════════════════════════"
echo "Project Root: ${PROJECT_ROOT}"
echo ""

# 환경변수 설정
export DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM=offscreen  # UI 없이 실행

echo "Environment:"
echo "  DEPLOY_PREFIX: ${DEPLOY_PREFIX}"
echo "  LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
echo "  QT_QPA_PLATFORM: ${QT_QPA_PLATFORM}"
echo ""

# 기존 프로세스 종료
echo "[1/5] Cleaning up old processes..."
killall -9 GearApp AmbientApp MediaApp 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
rm -rf /tmp/vsomeip-* 2>/dev/null
sleep 1
echo "✓ Cleanup complete"
echo ""

# 각 앱 실행 (백그라운드)
echo "[2/5] Starting AmbientApp..."
cd "${PROJECT_ROOT}/app/AmbientApp"
./build/AmbientApp > /tmp/ambientapp.log 2>&1 &
AMBIENT_PID=$!
echo "✓ AmbientApp started (PID: ${AMBIENT_PID})"
sleep 2
echo ""

echo "[3/5] Starting GearApp..."
cd "${PROJECT_ROOT}/app/GearApp"
./build/GearApp > /tmp/gearapp.log 2>&1 &
GEAR_PID=$!
echo "✓ GearApp started (PID: ${GEAR_PID})"
sleep 2
echo ""

echo "[4/5] Starting MediaApp..."
cd "${PROJECT_ROOT}/app/MediaApp"
./build/MediaApp > /tmp/mediaapp.log 2>&1 &
MEDIA_PID=$!
echo "✓ MediaApp started (PID: ${MEDIA_PID})"
sleep 2
echo ""

echo "[5/5] Process Status Check..."
ps -p ${AMBIENT_PID} > /dev/null && echo "✓ AmbientApp: Running" || echo "✗ AmbientApp: Stopped"
ps -p ${GEAR_PID} > /dev/null && echo "✓ GearApp: Running" || echo "✗ GearApp: Stopped"
ps -p ${MEDIA_PID} > /dev/null && echo "✓ MediaApp: Running" || echo "✗ MediaApp: Stopped"
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ All apps started!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Logs:"
echo "  AmbientApp: tail -f /tmp/ambientapp.log"
echo "  GearApp:    tail -f /tmp/gearapp.log"
echo "  MediaApp:   tail -f /tmp/mediaapp.log"
echo ""
echo "🛑 To stop all:"
echo "  killall -9 GearApp AmbientApp MediaApp"
echo ""
echo "Press Ctrl+C to stop monitoring..."
echo ""

# 로그 모니터링
tail -f /tmp/ambientapp.log /tmp/gearapp.log /tmp/mediaapp.log
