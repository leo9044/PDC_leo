#!/bin/bash

# ════════════════════════════════════════════════════════
# Jetson Weston + HU Apps 실행 스크립트
# 젯슨 오린 나노에서 Wayland로 모든 앱 실행
# ════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "Jetson Orin Nano - Weston + HU Apps"
echo "════════════════════════════════════════════════════════"

# 환경변수 설정
export DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR

echo "Environment:"
echo "  DEPLOY_PREFIX: ${DEPLOY_PREFIX}"
echo "  XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo ""

# 기존 프로세스 정리
echo "[1/6] Cleaning up old processes..."
killall -9 weston GearApp AmbientApp MediaApp HU_MainApp_Compositor 2>/dev/null
rm -f ${XDG_RUNTIME_DIR}/wayland-* 2>/dev/null
sleep 2
echo "✓ Cleanup complete"
echo ""

# Weston 실행 (X11 위에서 nested)
echo "[2/6] Starting Weston (nested in X11)..."
export DISPLAY=:0
weston --width=1920 --height=1080 > /tmp/weston.log 2>&1 &
WESTON_PID=$!
echo "✓ Weston started (PID: ${WESTON_PID})"
sleep 3

# Wayland 소켓 확인
if [ ! -e "${XDG_RUNTIME_DIR}/wayland-0" ]; then
    echo "✗ Weston failed to start!"
    echo "Check log: tail /tmp/weston.log"
    exit 1
fi
echo "✓ Wayland socket ready: wayland-0"
echo ""

# HU_MainApp Compositor 실행 (optional - 레이아웃 관리용)
echo "[3/6] Starting HU_MainApp Compositor..."
cd "${PROJECT_ROOT}/app/HU_MainApp"
export WAYLAND_DISPLAY=wayland-0
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
./build_compositor/HU_MainApp_Compositor > /tmp/compositor.log 2>&1 &
COMP_PID=$!
echo "✓ Compositor started (PID: ${COMP_PID})"
sleep 3

# Compositor의 wayland-1 소켓 확인
if [ -e "${XDG_RUNTIME_DIR}/wayland-1" ]; then
    echo "✓ Compositor socket ready: wayland-1"
    APP_WAYLAND_DISPLAY=wayland-1
else
    echo "⚠️  Compositor socket not found, using wayland-0"
    APP_WAYLAND_DISPLAY=wayland-0
fi
echo ""

# 각 앱 실행
export WAYLAND_DISPLAY=${APP_WAYLAND_DISPLAY}
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

echo "[4/6] Starting GearApp..."
cd "${PROJECT_ROOT}/app/GearApp"
./build/GearApp > /tmp/gearapp_wayland.log 2>&1 &
GEAR_PID=$!
echo "✓ GearApp started (PID: ${GEAR_PID})"
sleep 2
echo ""

echo "[5/6] Starting AmbientApp..."
cd "${PROJECT_ROOT}/app/AmbientApp"
./build/AmbientApp > /tmp/ambientapp_wayland.log 2>&1 &
AMBIENT_PID=$!
echo "✓ AmbientApp started (PID: ${AMBIENT_PID})"
sleep 2
echo ""

echo "[6/6] Starting MediaApp..."
cd "${PROJECT_ROOT}/app/MediaApp"
./build/MediaApp > /tmp/mediaapp_wayland.log 2>&1 &
MEDIA_PID=$!
echo "✓ MediaApp started (PID: ${MEDIA_PID})"
sleep 2
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ All apps started on Wayland!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Process Status:"
ps -p ${WESTON_PID} > /dev/null && echo "  ✓ Weston: Running" || echo "  ✗ Weston: Stopped"
ps -p ${COMP_PID} > /dev/null && echo "  ✓ Compositor: Running" || echo "  ✗ Compositor: Stopped"
ps -p ${GEAR_PID} > /dev/null && echo "  ✓ GearApp: Running" || echo "  ✗ GearApp: Stopped"
ps -p ${AMBIENT_PID} > /dev/null && echo "  ✓ AmbientApp: Running" || echo "  ✗ AmbientApp: Stopped"
ps -p ${MEDIA_PID} > /dev/null && echo "  ✓ MediaApp: Running" || echo "  ✗ MediaApp: Stopped"
echo ""
echo "📋 Logs:"
echo "  Weston:     tail -f /tmp/weston.log"
echo "  Compositor: tail -f /tmp/compositor.log"
echo "  GearApp:    tail -f /tmp/gearapp_wayland.log"
echo "  AmbientApp: tail -f /tmp/ambientapp_wayland.log"
echo "  MediaApp:   tail -f /tmp/mediaapp_wayland.log"
echo ""
echo "🛑 To stop all:"
echo "  killall -9 weston GearApp AmbientApp MediaApp HU_MainApp_Compositor"
echo ""
echo "👀 Weston 창을 확인하세요!"
echo "   - Weston 창 안에 각 앱의 UI가 표시됩니다"
echo ""
echo "Press Ctrl+C to stop monitoring..."
echo ""

# 로그 모니터링
tail -f /tmp/weston.log /tmp/compositor.log /tmp/gearapp_wayland.log /tmp/ambientapp_wayland.log /tmp/mediaapp_wayland.log
