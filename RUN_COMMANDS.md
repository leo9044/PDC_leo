# 🚀 Run Commands - Wayland Compositor & Apps

## Quick Reference Guide

---

## 🎯 **Scenario A: Run Apps in Wayland Compositor (Multi-Process)**

### **Terminal 1: Launch Wayland Compositor**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
```

**Expected:** Window opens (1280×720) showing HomePage with vehicle image

---

### **Terminal 2: Launch GearApp**

**Option 2A: With Wayland (appears in compositor)**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./GearApp
```

**Expected:** Appears in LEFT PANEL of compositor (100px width)

---

### **Terminal 3: Launch MediaApp**

**Option 3A: With Wayland (appears in compositor)**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./MediaApp
```

**Expected:** Click [Media] button, appears in MAIN AREA

---

### **Terminal 4: Launch AmbientApp**

**Option 4A: With Wayland (appears in compositor)**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./AmbientApp
```

**Expected:** Click [Ambient] button, appears in MAIN AREA

---

## 🖥️ **Scenario B: Run Apps Standalone (Separate Windows)**

Useful for testing individual app UI without compositor.

### **GearApp Standalone**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build
./GearApp
```

**Result:** Opens in separate window (default 400×600)

---

### **MediaApp Standalone**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build
./MediaApp
```

**Result:** Opens in separate window (1024×600)

---

### **AmbientApp Standalone**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build
./AmbientApp
```

**Result:** Opens in separate window (800×600)

---

## 🔧 **Scenario C: Run Apps with vSOME/IP (Full Communication)**

### **Terminal 1: Compositor (Same as Scenario A)**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
```

---

### **Terminal 2: GearApp with vSOME/IP**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build

# Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1

# vSOME/IP configuration
export VSOMEIP_CONFIGURATION="../config/vsomeip_ecu2.json"
export COMMONAPI_CONFIG="../config/commonapi_ecu2.ini"

# Add library path
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH

./GearApp
```

**What it does:**
- ✅ Appears in compositor (left panel)
- ✅ Connects to vSOME/IP as VehicleControl client
- ✅ Can send gear changes to other apps

---

### **Terminal 3: MediaApp with vSOME/IP**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build

# Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1

# vSOME/IP configuration
export VSOMEIP_CONFIGURATION="../config/vsomeip_mediaapp.json"
export COMMONAPI_CONFIG="../config/commonapi_mediaapp.ini"

# Add library path
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH

./MediaApp
```

**What it does:**
- ✅ Appears in compositor (media page)
- ✅ Provides MediaControl service via vSOME/IP
- ✅ Other apps can subscribe to media events

---

### **Terminal 4: AmbientApp with vSOME/IP**

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build

# Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1

# vSOME/IP configuration
export VSOMEIP_CONFIGURATION="../config/vsomeip_ambientapp.json"
export COMMONAPI_CONFIG="../config/commonapi_ambientapp.ini"

# Add library path
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:$LD_LIBRARY_PATH

./AmbientApp
```

**What it does:**
- ✅ Appears in compositor (ambient page)
- ✅ Subscribes to VehicleControl (gear changes → color)
- ✅ Subscribes to MediaControl (volume → brightness)

---

## 📋 **Environment Variables Explained**

### **Wayland Variables (Required for Compositor Integration)**

| Variable | Purpose | Value |
|----------|---------|-------|
| `QT_QPA_PLATFORM` | Tells Qt to use Wayland | `wayland` |
| `QT_WAYLAND_DISABLE_WINDOWDECORATION` | Removes title bars | `1` |
| `WAYLAND_DISPLAY` | Compositor socket name | `wayland-1` |
| `QML2_IMPORT_PATH` | QML modules location | `/usr/lib/x86_64-linux-gnu/qt5/qml` |

### **vSOME/IP Variables (Optional - for Inter-App Communication)**

| Variable | Purpose | Example |
|----------|---------|---------|
| `VSOMEIP_CONFIGURATION` | vSOME/IP config file | `../config/vsomeip_ecu2.json` |
| `COMMONAPI_CONFIG` | CommonAPI config file | `../config/commonapi_ecu2.ini` |
| `LD_LIBRARY_PATH` | Library search path | `/path/to/install_folder/lib` |

---

## 🎛️ **Quick Launch Scripts (All-in-One)**

### **Option 1: Compositor + Apps WITHOUT vSOME/IP**

Save as `run_compositor_simple.sh`:

```bash
#!/bin/bash

# Terminal 1: Compositor
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
exec bash"

sleep 2

# Terminal 2: GearApp
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./GearApp
exec bash"

# Terminal 3: MediaApp
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./MediaApp
exec bash"

# Terminal 4: AmbientApp
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
./AmbientApp
exec bash"
```

**Run:** `chmod +x run_compositor_simple.sh && ./run_compositor_simple.sh`

---

### **Option 2: Compositor + Apps WITH vSOME/IP**

Save as `run_compositor_full.sh`:

```bash
#!/bin/bash

INSTALL_DIR=/home/seame/HU/chang_new/DES_Head-Unit/install_folder

# Terminal 1: Compositor
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
exec bash"

sleep 2

# Terminal 2: GearApp
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=../config/commonapi_ecu2.ini
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH
./GearApp
exec bash"

# Terminal 3: MediaApp
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_mediaapp.json
export COMMONAPI_CONFIG=../config/commonapi_mediaapp.ini
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH
./MediaApp
exec bash"

# Terminal 4: AmbientApp
gnome-terminal -- bash -c "
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=../config/vsomeip_ambientapp.json
export COMMONAPI_CONFIG=../config/commonapi_ambientapp.ini
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH
./AmbientApp
exec bash"
```

**Run:** `chmod +x run_compositor_full.sh && ./run_compositor_full.sh`

---

## 🛑 **Stop All Processes**

```bash
pkill -9 HU_MainApp_Compositor
pkill -9 GearApp
pkill -9 MediaApp
pkill -9 AmbientApp
```

---

## 📊 **Visual Reference**

### **Compositor Layout:**

```
┌─────────┬────────────────────────────────────────────┐
│ LEFT    │  MAIN AREA                                 │
│ PANEL   │                                            │
│ (100px) │  [Active Page]                             │
│         │                                            │
│ ┌─────┐ │  Page 0: HOME (vehicle + now playing)     │
│ │GEAR │ │  Page 1: MEDIA (MediaApp window)          │
│ │APP  │ │  Page 2: AMBIENT (AmbientApp window)      │
│ │     │ │                                            │
│ └─────┘ │                                            │
│         │                                            │
│ Status  │  [Home] [Media] [Ambient]                 │
└─────────┴────────────────────────────────────────────┘
```

---

## 🎯 **Common Use Cases**

### **Use Case 1: UI Testing Only**
→ Use **Scenario A** (Wayland without vSOME/IP)

### **Use Case 2: Test Individual App UI**
→ Use **Scenario B** (Standalone)

### **Use Case 3: Full System Testing**
→ Use **Scenario C** (Wayland with vSOME/IP)

### **Use Case 4: Debug Single App**
→ Run app standalone, check logs

---

## 📝 **Notes**

- **Compositor must start FIRST** before launching apps
- **Wait ~2 seconds** after compositor starts before launching apps
- **WAYLAND_DISPLAY=wayland-1** matches compositor's `socketName`
- Apps will show warnings if vSOME/IP services unavailable (normal if not running full system)
- Touch/mouse events work in compositor window

---

**Created:** November 16, 2024
**Platform:** Ubuntu 22.04
**Qt Version:** 5.15.3
