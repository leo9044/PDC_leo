#!/bin/bash

# ════════════════════════════════════════════════════════════
# Single Weston Compositor - All Apps Runner
# No HU_MainApp_Compositor - Direct to Weston (wayland-0)
# Auto-setup: Stops GDM3, sets up environment, runs everything
# ════════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "Single Weston Architecture - All HU Apps"
echo "Direct to wayland-0 (No Nested Compositor)"
echo "════════════════════════════════════════════════════════════"
echo "Project Root: ${PROJECT_ROOT}"
echo ""

# ════════════════════════════════════════════════════════════
# Environment Setup
# ════════════════════════════════════════════════════════════

# XDG Runtime Directory 설정
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "$XDG_RUNTIME_DIR"
    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
    sudo chmod 700 "$XDG_RUNTIME_DIR"
fi

# Wayland Display 설정
export WAYLAND_DISPLAY=wayland-0

# vsomeip 환경변수
export DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"

echo "Environment:"
echo "  XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "  WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"
echo "  DEPLOY_PREFIX: ${DEPLOY_PREFIX}"
echo ""

# ════════════════════════════════════════════════════════════
# Stop GDM3 (Ubuntu Desktop)
# ════════════════════════════════════════════════════════════
echo "[0/8] Stopping Ubuntu Desktop (GDM3)..."
if systemctl is-active --quiet gdm3; then
    sudo systemctl stop gdm3
    sleep 2
    echo "✓ GDM3 stopped"
else
    echo "✓ GDM3 already stopped"
fi
echo ""

# ════════════════════════════════════════════════════════════
# Cleanup Old Processes
# ════════════════════════════════════════════════════════════
echo "[1/8] Cleaning up old processes..."
killall -9 weston LayoutManagerApp GearApp MediaApp AmbientApp HomeScreenApp routingmanagerd 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
rm -rf /tmp/vsomeip-* 2>/dev/null
sleep 2
echo "✓ Cleanup complete"
echo ""

# ════════════════════════════════════════════════════════════
# Start Weston (Desktop-Shell)
# ════════════════════════════════════════════════════════════
echo "[2/8] Starting Weston..."
weston --config=/etc/xdg/weston-13.0/weston.ini > /tmp/weston.log 2>&1 &
sleep 5  # Desktop-shell 초기화 시간
echo "✓ Weston started"
echo ""

# wayland-0 소켓 확인 (최대 10초 대기)
echo "[3/8] Waiting for wayland-0 socket..."
for i in {1..10}; do
    if [ -S "$XDG_RUNTIME_DIR/wayland-0" ]; then
        echo "✓ wayland-0 socket exists: $XDG_RUNTIME_DIR/wayland-0"
        break
    fi
    echo "   Attempt $i/10..."
    sleep 1
done

if [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ]; then
    echo "❌ Error: wayland-0 socket not found after 10 seconds!"
    echo "   Check: ls -la $XDG_RUNTIME_DIR/wayland-*"
    echo "   Weston log: tail /tmp/weston.log"
    exit 1
fi
echo ""

# Multicast 라우팅 설정 (vsomeip 외부 통신 필수)
echo "[4/8] Setup multicast routing..."
MULTICAST_ROUTE=$(ip route | grep "224.0.0.0/4")
if [ -z "$MULTICAST_ROUTE" ]; then
    echo "   Adding multicast route for enP8p1s0..."
    sudo ip route add 224.0.0.0/4 dev enP8p1s0 2>/dev/null && echo "   ✓ Multicast route added" || echo "   ⚠ Route may already exist"
else
    echo "   ✓ Multicast route already configured"
fi
echo ""

# vsomeip Routing Manager 시작
echo "[5/8] Starting vsomeip Routing Manager..."
export VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/config/routing_manager_ecu2.json"
export VSOMEIP_APPLICATION_NAME="routingmanagerd"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

ROUTING_MGR="${PROJECT_ROOT}/deps/vsomeip/build/examples/routingmanagerd/routingmanagerd"
if [ -x "$ROUTING_MGR" ]; then
    $ROUTING_MGR > /tmp/routing_manager.log 2>&1 &
    RM_PID=$!
    echo "✓ Routing Manager started (PID: ${RM_PID})"
    sleep 3
    
    if [ ! -e /tmp/vsomeip-0 ]; then
        echo "❌ Error: Routing Manager failed to create socket!"
        echo "   Check: tail /tmp/routing_manager.log"
        exit 1
    fi
    echo "✓ vsomeip socket ready: /tmp/vsomeip-0"
else
    echo "❌ Error: routingmanagerd not found at: $ROUTING_MGR"
    exit 1
fi
echo ""

# 각 앱 실행 (순차적으로, 2초 간격)
echo "[6/8] Starting apps..."

# Content apps 먼저 실행 (background layer)
cd "${PROJECT_ROOT}/app/HomeScreenApp"
./run_wayland0.sh > /tmp/homescreen-wayland0.log 2>&1 &
HOMESCREEN_PID=$!
echo "✓ HomeScreenApp started (PID: ${HOMESCREEN_PID})"
sleep 2

cd "${PROJECT_ROOT}/app/MediaApp"
./run_wayland0.sh > /tmp/mediaapp-wayland0.log 2>&1 &
MEDIA_PID=$!
echo "✓ MediaApp started (PID: ${MEDIA_PID})"
sleep 2

cd "${PROJECT_ROOT}/app/AmbientApp"
./run_wayland0.sh > /tmp/ambientapp-wayland0.log 2>&1 &
AMBIENT_PID=$!
echo "✓ AmbientApp started (PID: ${AMBIENT_PID})"
sleep 2

# GearApp 다음 실행 (foreground left panel)
cd "${PROJECT_ROOT}/app/GearApp"
./run_wayland0.sh > /tmp/gearapp-wayland0.log 2>&1 &
GEAR_PID=$!
echo "✓ GearApp started (PID: ${GEAR_PID})"
sleep 2

# LayoutManagerApp 마지막 실행 (top overlay with navigation)
cd "${PROJECT_ROOT}/app/LayoutManagerApp"
./run_wayland0.sh > /tmp/layoutmanager-wayland0.log 2>&1 &
LAYOUT_PID=$!
echo "✓ LayoutManagerApp started (PID: ${LAYOUT_PID})"
sleep 2

echo ""
echo "════════════════════════════════════════════════════════════"
echo "[7/8] Process Status Check..."
echo "════════════════════════════════════════════════════════════"
pgrep -x weston > /dev/null && echo "✓ Weston: Running" || echo "✗ Weston: Stopped"
pgrep -x routingmanagerd > /dev/null && echo "✓ Routing Manager: Running" || echo "✗ Routing Manager: Stopped"
ps -p ${LAYOUT_PID} > /dev/null && echo "✓ LayoutManagerApp (${LAYOUT_PID}): Running" || echo "✗ LayoutManagerApp: Stopped"
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
echo "  Weston (wayland-0) - desktop-shell"
echo "  ├─> vsomeip Routing Manager"
echo "  ├─> LayoutManagerApp (UI Frame + Navigation)"
echo "  ├─> GearApp"
echo "  ├─> MediaApp"
echo "  ├─> AmbientApp"
echo "  └─> HomeScreenApp"
echo "📋 Logs:"
echo "  Weston:           tail -f /tmp/weston.log"
echo "  Routing Manager:  tail -f /tmp/routing_manager.log"
echo "  LayoutManager:    tail -f /tmp/layoutmanager-wayland0.log"
echo "  GearApp:          tail -f /tmp/gearapp-wayland0.log"
echo "  MediaApp:         tail -f /tmp/mediaapp-wayland0.log"
echo "  AmbientApp:       tail -f /tmp/ambientapp-wayland0.log"
echo "  HomeScreenApp:    tail -f /tmp/homescreen-wayland0.log"
echo ""
echo "🛑 To stop all:"
echo "  ./stop-jetson-single-weston.sh"
echo ""
echo "🔍 Check vsomeip:"
echo "  ls -la /tmp/vsomeip-*"
echo ""
