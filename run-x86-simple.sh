#!/bin/bash

# Run Head Unit apps (Simple mode - UI only, no vSOME/IP)
# This script is for testing the UI without inter-process communication

BASE_DIR="/home/seame/HU/chang_new/DES_Head-Unit"

echo "════════════════════════════════════════════════════════"
echo "Launching Head Unit System (Simple Mode - UI Only)"
echo "════════════════════════════════════════════════════════"
echo ""

# Terminal 1: HU_MainApp Compositor
echo "Starting Wayland Compositor..."
gnome-terminal --title="HU_MainApp Compositor" -- bash -c "
cd ${BASE_DIR}/app/HU_MainApp/build-x86
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
exec bash"

echo "Waiting for compositor to initialize..."
sleep 3

# Terminal 2: GearApp
echo "Starting GearApp..."
gnome-terminal --title="GearApp" -- bash -c "
cd ${BASE_DIR}/app/GearApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./GearApp
exec bash"

sleep 1

# Terminal 3: MediaApp
echo "Starting MediaApp..."
gnome-terminal --title="MediaApp" -- bash -c "
cd ${BASE_DIR}/app/MediaApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./MediaApp
exec bash"

sleep 1

# Terminal 4: AmbientApp
echo "Starting AmbientApp..."
gnome-terminal --title="AmbientApp" -- bash -c "
cd ${BASE_DIR}/app/AmbientApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./AmbientApp
exec bash"

sleep 1

# Terminal 5: HomeScreenApp
echo "Starting HomeScreenApp..."
gnome-terminal --title="HomeScreenApp" -- bash -c "
cd ${BASE_DIR}/app/HomeScreenApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./HomeScreenApp
exec bash"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ All apps launched successfully (Simple Mode)!"
echo ""
echo "Note: Apps are running without vSOME/IP communication"
echo ""
echo "To stop all processes, run:"
echo "  pkill -9 HU_MainApp_Compositor && pkill -9 GearApp && pkill -9 MediaApp && pkill -9 AmbientApp && pkill -9 HomeScreenApp"
echo "════════════════════════════════════════════════════════"
