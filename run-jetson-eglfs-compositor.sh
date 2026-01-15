#!/bin/bash

# ════════════════════════════════════════════════════════
# Jetson ECU2 - EGLFS Direct Rendering (라즈베리파이 방식)
# Compositor를 EGLFS로 직접 실행하여 Weston 오버헤드 제거
# ════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "Jetson ECU2 - EGLFS Mode (Direct GPU Rendering)"
echo "════════════════════════════════════════════════════════"

# 1. Cleanup
echo "[1/7] Cleanup..."
sudo pkill -9 weston HU_MainApp_Compositor GearApp AmbientApp MediaApp HomeScreenApp routingmanagerd 2>/dev/null
sleep 1

# 2. Stop X server
echo "[2/7] Stop X server..."
sudo systemctl stop gdm3 2>/dev/null || sudo systemctl stop lightdm 2>/dev/null || true
sleep 1

# 3. Load NVIDIA DRM driver
echo "[3/7] Load nvidia_drm driver..."
sudo modprobe nvidia-drm modeset=1

# 4. Network setup
echo "[4/7] Network setup..."
IFACE="enP8p1s0"
sudo ip route add 224.0.0.0/4 dev ${IFACE} 2>/dev/null || echo "   Multicast route already exists"

# 5. Start Routing Manager
echo "[5/7] Starting Routing Manager..."
export VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/config/routing_manager_ecu2.json"
export VSOMEIP_APPLICATION_NAME="routingmanagerd"
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

routingmanagerd &> /tmp/routing_manager.log &
RM_PID=$!
sleep 3
echo "   Routing Manager PID: ${RM_PID}"

# 6. Start Compositor on EGLFS (Direct GPU)
echo "[6/7] Starting Compositor on EGLFS..."
cd "${PROJECT_ROOT}/app/HU_MainApp"

export XDG_RUNTIME_DIR=/tmp/xdg
sudo mkdir -p /tmp/xdg
sudo chmod 700 /tmp/xdg

export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
export QT_QPA_EGLFS_KMS_CONFIG="${PROJECT_ROOT}/app/HU_MainApp/eglfs_kms_config.json"
export QT_WAYLAND_SHELL_INTEGRATION=xdg-shell
export QSG_RENDER_LOOP=threaded
export QT_QUICK_BACKEND=opengl
export LIBGL_ALWAYS_SOFTWARE=0

sudo -E ./build_compositor/HU_MainApp_Compositor > /tmp/compositor.log 2>&1 &
COMP_PID=$!
sleep 5
echo "   Compositor PID: ${COMP_PID}"

# 7. Start apps
echo "[7/7] Starting apps..."

export XDG_RUNTIME_DIR=/tmp/xdg
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export QSG_RENDER_LOOP=threaded
export QT_QUICK_BACKEND=opengl
export QSG_NO_VSYNC=1
export LIBGL_ALWAYS_SOFTWARE=0
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

# GearApp
cd "${PROJECT_ROOT}/app/GearApp"
sudo -E VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/GearApp/config/vsomeip_ecu2.json" \
  ./build/GearApp > /tmp/gearapp.log 2>&1 &
GEAR_PID=$!

# AmbientApp
cd "${PROJECT_ROOT}/app/AmbientApp"
sudo -E VSOMEIP_APPLICATION_NAME=AmbientApp \
  VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/AmbientApp/vsomeip_ambient.json" \
  ./build/AmbientApp > /tmp/ambientapp.log 2>&1 &
AMBIENT_PID=$!

# MediaApp
cd "${PROJECT_ROOT}/app/MediaApp"
sudo -E VSOMEIP_APPLICATION_NAME=MediaApp \
  VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/MediaApp/vsomeip.json" \
  ./build/MediaApp > /tmp/mediaapp.log 2>&1 &
MEDIA_PID=$!

# HomeScreenApp
cd "${PROJECT_ROOT}/app/HomeScreenApp"
sudo -E VSOMEIP_APPLICATION_NAME=HomeScreenApp \
  VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/HomeScreenApp/vsomeip_homescreen.json" \
  ./build/HomeScreenApp > /tmp/homescreen.log 2>&1 &
HOME_PID=$!

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ EGLFS Mode Started!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "PIDs:"
echo "  Routing Manager: ${RM_PID}"
echo "  Compositor:      ${COMP_PID}"
echo "  GearApp:         ${GEAR_PID}"
echo "  AmbientApp:      ${AMBIENT_PID}"
echo "  MediaApp:        ${MEDIA_PID}"
echo "  HomeScreenApp:   ${HOME_PID}"
echo ""
echo "📋 Logs:"
echo "  Compositor: tail -f /tmp/compositor.log"
echo "  GearApp:    tail -f /tmp/gearapp.log"
echo ""
echo "⚠️  No Weston = No extra layer = Faster rendering!"
echo ""
