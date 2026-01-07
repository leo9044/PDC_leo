#!/bin/bash

# Run all Head Unit apps on x86-64 local environment
# This script launches all apps in separate terminal windows

BASE_DIR="/home/seame/HU/chang_new/DES_Head-Unit"
INSTALL_DIR="${BASE_DIR}/install_folder"

echo "════════════════════════════════════════════════════════"
echo "Launching Head Unit System on x86-64"
echo "════════════════════════════════════════════════════════"
echo ""

# Terminal 1: VehicleControlMock (Service Provider)
echo "Starting VehicleControlMock..."
gnome-terminal --title="VehicleControlMock" -- bash -c "
cd ${BASE_DIR}/app/VehicleControlMock/build-x86
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
export VSOMEIP_CONFIGURATION=../config/vsomeip_ecu1.json
export COMMONAPI_CONFIG=../config/commonapi_ecu1.ini
./VehicleControlMock &
exec bash"

sleep 1

# Terminal 2: HU_MainApp Compositor
echo "Starting Wayland Compositor..."
gnome-terminal --title="HU_MainApp Compositor" -- bash -c "
cd ${BASE_DIR}/app/HU_MainApp/build-x86
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
exec bash"

echo "Waiting for compositor to initialize..."
sleep 3

# Terminal 3: GearApp
echo "Starting GearApp..."
gnome-terminal --title="GearApp" -- bash -c "
cd ${BASE_DIR}/app/GearApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=../config/commonapi_ecu2.ini
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./GearApp
exec bash"

sleep 1

# Terminal 4: MediaApp
echo "Starting MediaApp..."
gnome-terminal --title="MediaApp" -- bash -c "
cd ${BASE_DIR}/app/MediaApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_mediaapp.json
export COMMONAPI_CONFIG=../config/commonapi_mediaapp.ini
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./MediaApp
exec bash"

sleep 1

# Terminal 5: AmbientApp
echo "Starting AmbientApp..."
gnome-terminal --title="AmbientApp" -- bash -c "
cd ${BASE_DIR}/app/AmbientApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_ambientapp.json
export COMMONAPI_CONFIG=../config/commonapi_ambientapp.ini
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./AmbientApp
exec bash"

sleep 1

# Terminal 6: HomeScreenApp
echo "Starting HomeScreenApp..."
gnome-terminal --title="HomeScreenApp" -- bash -c "
cd ${BASE_DIR}/app/HomeScreenApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_homescreen.json
export COMMONAPI_CONFIG=../config/commonapi_homescreen.ini
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./HomeScreenApp
exec bash"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ All apps launched successfully!"
echo ""
echo "To stop all processes, run:"
echo "  pkill -9 VehicleControlMock && pkill -9 HU_MainApp_Compositor && pkill -9 GearApp && pkill -9 MediaApp && pkill -9 AmbientApp && pkill -9 HomeScreenApp"
echo "════════════════════════════════════════════════════════"
