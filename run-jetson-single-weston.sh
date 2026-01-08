#!/bin/bash

# ════════════════════════════════════════════════════════════
# Single Weston Compositor - All Apps Runner
# No HU_MainApp_Compositor - Direct to Weston (wayland-0)
# ════════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "Single Weston Architecture - All HU Apps"
echo "Direct to wayland-0 (No Nested Compositor)"
echo "════════════════════════════════════════════════════════════"
echo "Project Root: ${PROJECT_ROOT}"
echo ""

# 환경변수 설정
export DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"

echo "Environment:"
echo "  DEPLOY_PREFIX: ${DEPLOY_PREFIX}"
echo "  LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
echo ""

# 기존 프로세스 정리
echo "[0/5] Cleaning up old processes..."
killall -9 GearApp MediaApp AmbientApp HomeScreenApp HU_MainApp_Compositor 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
rm -rf /tmp/vsomeip-* 2>/dev/null
sleep 2
echo "✓ Cleanup complete"
echo ""

# Weston 실행 확인
echo "[1/5] Checking Weston..."
if ! pgrep -x weston > /dev/null; then
    echo "⚠️  Weston is not running!"
    echo "Starting Weston with IVI-Shell..."
    weston --config=/etc/xdg/weston-13.0/weston.ini > /tmp/weston.log 2>&1 &
    sleep 3
    echo "✓ Weston started"
else
    echo "✓ Weston already running"
fi
echo ""

# wayland-0 소켓 확인
if [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ]; then
    echo "❌ Error: wayland-0 socket not found!"
    echo "   Check: ls -la $XDG_RUNTIME_DIR/wayland-*"
    exit 1
fi
echo "✓ wayland-0 socket exists: $XDG_RUNTIME_DIR/wayland-0"
echo ""

# IVI Layout Controller 시작 (백그라운드)
echo "[2/6] Starting IVI Layout Controller..."
cd "${PROJECT_ROOT}/app/IVILayoutController"
./run.sh > /tmp/ivi-controller.log 2>&1 &
IVI_CONTROLLER_PID=$!
echo "✓ IVI Layout Controller started (PID: ${IVI_CONTROLLER_PID})"
sleep 3  # Controller가 layer 생성할 시간

# 각 앱 실행 (순차적으로, 2초 간격)
echo "[3/6] Starting GearApp (IVI Surface 1000)..."
cd "${PROJECT_ROOT}/app/GearApp"
./run_wayland0.sh > /tmp/gearapp-wayland0.log 2>&1 &
GEAR_PID=$!
echo "✓ GearApp started (PID: ${GEAR_PID})"
sleep 2

echo "[4/6] Starting MediaApp (IVI Surface 2000)..."
cd "${PROJECT_ROOT}/app/MediaApp"
./run_wayland0.sh > /tmp/mediaapp-wayland0.log 2>&1 &
MEDIA_PID=$!
echo "✓ MediaApp started (PID: ${MEDIA_PID})"
sleep 2

echo "[5/6] Starting AmbientApp (IVI Surface 3000)..."
cd "${PROJECT_ROOT}/app/AmbientApp"
./run_wayland0.sh > /tmp/ambientapp-wayland0.log 2>&1 &
AMBIENT_PID=$!
echo "✓ AmbientApp started (PID: ${AMBIENT_PID})"
sleep 2

echo "[6/6] Starting HomeScreenApp (IVI Surface 4000)..."
cd "${PROJECT_ROOT}/app/HomeScreenApp"
./run_wayland0.sh > /tmp/homescreen-wayland0.log 2>&1 &
HOMESCREEN_PID=$!
echo "✓ HomeScreenApp started (PID: ${HOMESCREEN_PID})"
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Process Status Check..."
echo "════════════════════════════════════════════════════════════"
ps -p ${IVI_CONTROLLER_PID} > /dev/null && echo "✓ IVI Controller (${IVI_CONTROLLER_PID}): Running" || echo "✗ IVI Controller: Stopped"
ps -p ${GEAR_PID} > /dev/null && echo "✓ GearApp (${GEAR_PID}): Running" || echo "✗ GearApp: Stopped"
ps -p ${MEDIA_PID} > /dev/null && echo "✓ MediaApp (${MEDIA_PID}): Running" || echo "✗ MediaApp: Stopped"
ps -p ${AMBIENT_PID} > /dev/null && echo "✓ AmbientApp (${AMBIENT_PID}): Running" || echo "✗ AmbientApp: Stopped"
ps -p ${HOMESCREEN_PID} > /dev/null && echo "✓ HomeScreenApp (${HOMESCREEN_PID}): Running" || echo "✗ HomeScreenApp: Stopped"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ All apps started in Single Weston Architecture!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Architecture:"
echo "  Weston (wayland-0)"
echo "  ├─> IVI Layout Controller (GENIVI Layer Manager)"
echo "  ├─> GearApp (IVI Surface 1000)"
echo "  ├─> MediaApp (IVI Surface 2000)"
echo "  ├─> AmbientApp (IVI Surface 3000)"
echo "  └─> HomeScreenApp (IVI Surface 4000)"
echo "📋 Logs:"
echo "  Weston:       tail -f /tmp/weston.log"
echo "  IVI Controller: tail -f /tmp/ivi-controller.log"
echo "  GearApp:      tail -f /tmp/gearapp-wayland0.log"
echo "  GearApp:      tail -f /tmp/gearapp-wayland0.log"
echo "  MediaApp:     tail -f /tmp/mediaapp-wayland0.log"
echo "  AmbientApp:   tail -f /tmp/ambientapp-wayland0.log"
echo "  HomeScreenApp: tail -f /tmp/homescreen-wayland0.log"
echo ""
echo "🛑 To stop all:"
echo "  killall -9 GearApp MediaApp AmbientApp HomeScreenApp"
echo ""
echo "🔍 Check Wayland surfaces:"
echo "  ls -la \$XDG_RUNTIME_DIR/wayland-*"
echo ""
