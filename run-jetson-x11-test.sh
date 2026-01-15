#!/bin/bash

# ════════════════════════════════════════════════════════
# Jetson X11 GUI 테스트 스크립트
# 각 앱을 X11 창으로 실행하여 GUI 확인
# ════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "Jetson Orin Nano - X11 GUI Test"
echo "════════════════════════════════════════════════════════"

# 환경변수 설정
export DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM=xcb  # X11 사용
export DISPLAY=:0

echo "Environment:"
echo "  DISPLAY: ${DISPLAY}"
echo "  QT_QPA_PLATFORM: ${QT_QPA_PLATFORM}"
echo ""

# X11 접근 권한 설정
xhost +local: 2>/dev/null

# 기존 프로세스 종료
echo "[1/4] Cleaning up old processes..."
killall -9 GearApp AmbientApp MediaApp 2>/dev/null
sleep 1
echo ""

# 각 앱을 독립 창으로 실행 (위치 지정)
echo "[2/4] Starting GearApp (Left panel)..."
cd "${PROJECT_ROOT}/app/GearApp"
./build/GearApp > /tmp/gearapp_x11.log 2>&1 &
GEAR_PID=$!
echo "✓ GearApp started (PID: ${GEAR_PID})"
sleep 2
echo ""

echo "[3/4] Starting AmbientApp (Main area)..."
cd "${PROJECT_ROOT}/app/AmbientApp"
./build/AmbientApp > /tmp/ambientapp_x11.log 2>&1 &
AMBIENT_PID=$!
echo "✓ AmbientApp started (PID: ${AMBIENT_PID})"
sleep 2
echo ""

echo "[4/4] Starting MediaApp..."
cd "${PROJECT_ROOT}/app/MediaApp"
./build/MediaApp > /tmp/mediaapp_x11.log 2>&1 &
MEDIA_PID=$!
echo "✓ MediaApp started (PID: ${MEDIA_PID})"
sleep 2
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ All apps started in X11 window mode!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Check:"
echo "  - 3개의 독립 창이 열렸나요?"
echo "  - 창 테두리/타이틀바가 보이나요?"
echo "  - 각 창을 자유롭게 이동/크기조절 가능한가요?"
echo ""
echo "📋 Logs:"
echo "  GearApp:    tail -f /tmp/gearapp_x11.log"
echo "  AmbientApp: tail -f /tmp/ambientapp_x11.log"
echo "  MediaApp:   tail -f /tmp/mediaapp_x11.log"
echo ""
echo "🛑 To stop all:"
echo "  killall -9 GearApp AmbientApp MediaApp"
echo ""
echo "Press Ctrl+C to exit..."
echo ""

# 프로세스 모니터링
while true; do
    sleep 5
    ps -p ${GEAR_PID} > /dev/null || echo "⚠️  GearApp stopped"
    ps -p ${AMBIENT_PID} > /dev/null || echo "⚠️  AmbientApp stopped"
    ps -p ${MEDIA_PID} > /dev/null || echo "⚠️  MediaApp stopped"
done
