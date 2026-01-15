# x86-64 Build and Run Guide

This guide explains how to build and run all Head Unit applications on your local x86-64 laptop.

## Build Status

All applications have been successfully built for x86-64:

- ✅ VehicleControlMock
- ✅ HU_MainApp_Compositor (Wayland Compositor)
- ✅ GearApp
- ✅ MediaApp
- ✅ AmbientApp
- ✅ HomeScreenApp

## Directory Structure

Each app has its own `build-x86` folder:

```
DES_Head-Unit/
├── app/
│   ├── VehicleControlMock/build-x86/    → VehicleControlMock executable
│   ├── HU_MainApp/build-x86/            → HU_MainApp_Compositor executable
│   ├── GearApp/build-x86/               → GearApp executable
│   ├── MediaApp/build-x86/              → MediaApp executable
│   ├── AmbientApp/build-x86/            → AmbientApp executable
│   └── HomeScreenApp/build-x86/         → HomeScreenApp executable
├── run-x86-all.sh                       → Launch all apps with vSOME/IP
└── run-x86-simple.sh                    → Launch all apps (UI only)
```

---

## Quick Start

### Option 1: Simple Mode (UI Only - Recommended for first run)

This mode launches the compositor and all apps without vSOME/IP communication:

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit
./run-x86-simple.sh
```

This will open 5 terminal windows:
1. HU_MainApp_Compositor (Wayland compositor)
2. GearApp
3. MediaApp
4. AmbientApp
5. HomeScreenApp

### Option 2: Full Mode (With vSOME/IP)

This mode includes VehicleControlMock and enables inter-process communication:

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit
./run-x86-all.sh
```

This will open 6 terminal windows:
1. VehicleControlMock (Service provider)
2. HU_MainApp_Compositor (Wayland compositor)
3. GearApp
4. MediaApp
5. AmbientApp
6. HomeScreenApp

---

## Manual Build Instructions

If you need to rebuild any app:

### VehicleControlMock
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/VehicleControlMock/build-x86
cmake .. -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_PREFIX_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder \
    -DCOMMONAPI_GEN_DIR=/home/seame/HU/chang_new/DES_Head-Unit/commonapi/generated
make -j$(nproc)
```

### HU_MainApp Compositor
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build-x86
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)
```

### GearApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build-x86
cmake .. -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_PREFIX_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder \
    -DCOMMONAPI_GEN_DIR=/home/seame/HU/chang_new/DES_Head-Unit/commonapi/generated
make -j$(nproc)
```

### MediaApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build-x86
cmake .. -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_PREFIX_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder \
    -DCOMMONAPI_GEN_DIR=/home/seame/HU/chang_new/DES_Head-Unit/commonapi/generated
make -j$(nproc)
```

### AmbientApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build-x86
cmake .. -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_PREFIX_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder \
    -DCOMMONAPI_GEN_DIR=/home/seame/HU/chang_new/DES_Head-Unit/commonapi/generated
make -j$(nproc)
```

### HomeScreenApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HomeScreenApp/build-x86
cmake .. -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_PREFIX_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder \
    -DCOMMONAPI_GEN_DIR=/home/seame/HU/chang_new/DES_Head-Unit/commonapi/generated
make -j$(nproc)
```

---

## Manual Run Instructions

### Simple Mode (UI Only)

#### Terminal 1: Compositor
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build-x86
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
```

Wait 2-3 seconds, then launch apps:

#### Terminal 2: GearApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./GearApp
```

#### Terminal 3: MediaApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./MediaApp
```

#### Terminal 4: AmbientApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./AmbientApp
```

#### Terminal 5: HomeScreenApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HomeScreenApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./HomeScreenApp
```

---

### Full Mode (With vSOME/IP)

#### Terminal 1: VehicleControlMock
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/VehicleControlMock/build-x86
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH
export VSOMEIP_CONFIGURATION=../config/vsomeip_ecu1.json
export COMMONAPI_CONFIG=../config/commonapi_ecu1.ini
./VehicleControlMock
```

#### Terminal 2: Compositor
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build-x86
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
```

Wait 2-3 seconds, then launch apps:

#### Terminal 3: GearApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=../config/commonapi_ecu2.ini
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH
./GearApp
```

#### Terminal 4: MediaApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_mediaapp.json
export COMMONAPI_CONFIG=../config/commonapi_mediaapp.ini
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH
./MediaApp
```

#### Terminal 5: AmbientApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_ambientapp.json
export COMMONAPI_CONFIG=../config/commonapi_ambientapp.ini
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH
./AmbientApp
```

#### Terminal 6: HomeScreenApp
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HomeScreenApp/build-x86
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_homescreen.json
export COMMONAPI_CONFIG=../config/commonapi_homescreen.ini
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH
./HomeScreenApp
```

---

## Stopping All Apps

To stop all running processes:

```bash
pkill -9 VehicleControlMock
pkill -9 HU_MainApp_Compositor
pkill -9 GearApp
pkill -9 MediaApp
pkill -9 AmbientApp
pkill -9 HomeScreenApp
```

---

## Compositor Layout

```
┌──────────┬─────────────────────────────────────────┐
│ LEFT     │  MAIN DISPLAY AREA                      │
│ PANEL    │                                          │
│ (100px)  │  Page 0: HOME (vehicle + now playing)   │
│          │  Page 1: MEDIA (MediaApp)               │
│ ┌──────┐ │  Page 2: AMBIENT (AmbientApp)           │
│ │ GEAR │ │                                          │
│ │ APP  │ │  [Home] [Media] [Ambient] buttons       │
│ └──────┘ │                                          │
│          │                                          │
│ Status   │                                          │
└──────────┴─────────────────────────────────────────┘
```

- **GearApp**: Appears in the left panel (100px width)
- **MediaApp**: Click [Media] button to show in main area
- **AmbientApp**: Click [Ambient] button to show in main area
- **HomeScreenApp**: Displays on home page

---

## Troubleshooting

### Compositor window doesn't open
- Check that Qt5 Wayland packages are installed
- Verify QML2_IMPORT_PATH is set correctly
- Try running: `sudo apt install qtwayland5 qt5-wayland`

### Apps don't appear in compositor
- Ensure compositor starts FIRST
- Wait 2-3 seconds after compositor starts
- Verify WAYLAND_DISPLAY=wayland-1

### vSOME/IP connection errors
- Start VehicleControlMock first
- Check that config files exist in each app's config directory
- Verify LD_LIBRARY_PATH includes install_folder/lib

### "Cannot find QML module" errors
- Set QML2_IMPORT_PATH: `export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml`
- Install Qt Quick modules: `sudo apt install qml-module-qtquick*`

---

## System Requirements

- Ubuntu 22.04 x86-64
- Qt 5.15.3 with Wayland support
- CommonAPI 3.2.4
- vsomeip3
- Boost 1.74+

---

**Last Updated:** November 25, 2024
**Platform:** x86-64 Ubuntu 22.04
**Build Type:** Debug
