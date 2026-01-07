#!/bin/sh

BASE_DIR="/usr/bin"

echo "════════════════════════════════════════════════════════"
echo "Launching Head Unit System on Raspberry Pi (ARM)"
echo "════════════════════════════════════════════════════════"
echo ""

# Start HU_MainApp Compositor on EGLFS (direct to framebuffer)
echo "Starting Compositor on EGLFS..."
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
export QT_WAYLAND_SHELL_INTEGRATION=xdg-shell
${BASE_DIR}/HU_MainApp_Compositor &
COMPOSITOR_PID=$!

echo "Waiting for compositor to initialize..."
sleep 3

# Client apps connect via Wayland
export XDG_RUNTIME_DIR=/run/user/0
export QML2_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt5/qml
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

echo "Starting GearApp..."
${BASE_DIR}/GearApp &
sleep 1

echo "Starting MediaApp..."
${BASE_DIR}/MediaApp &
sleep 1

echo "Starting AmbientApp..."
${BASE_DIR}/AmbientApp &
sleep 1

echo "Starting HomeScreenApp..."
${BASE_DIR}/HomeScreenApp &

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ All apps launched successfully!"
echo "Compositor PID: $COMPOSITOR_PID"
echo "════════════════════════════════════════════════════════"