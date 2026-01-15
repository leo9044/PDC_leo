# Single Weston Compositor Architecture - Migration Complete

## ✅ What Changed

### Architecture Transformation

**Before (Nested Compositor)**:
```
Weston (wayland-0)
└─> HU_MainApp_Compositor (wayland-1)
    ├─> GearApp
    ├─> MediaApp
    ├─> AmbientApp
    └─> HomeScreenApp
```

**After (Single Weston with IVI-Shell + GENIVI Layer Manager)**:
```
Weston with IVI-Shell (wayland-0)
├─> IVI Layout Controller (GENIVI ilmControl API)
│   └─> Manages layers and surface positioning
├─> GearApp (IVI Surface 1000)
├─> MediaApp (IVI Surface 2000)
├─> AmbientApp (IVI Surface 3000)
└─> HomeScreenApp (IVI Surface 4000)
```

---

## 🎯 Benefits

1. **No Compositor App** ❌ HU_MainApp_Compositor removed
2. **Individual App OTA** ✅ Each app can be updated independently
3. **Simplified Dependencies** ✅ App → Weston (2 levels, not 3)
4. **Better Stability** ✅ No single point of failure
5. **Standards Compliant** ✅ GENIVI IVI-Shell architecture

---

## 📁 New Files Created

### Configuration
- `config/weston-single-dp-ivi.ini` - Weston IVI-Shell config for single DP-1 display
  - **Installed to**: `/etc/xdg/weston-13.0/weston.ini`
  - **Backup**: `/etc/xdg/weston-13.0/weston.ini.backup`

### App Launch Scripts (wayland-0 Direct Connection)
- `app/GearApp/run_wayland0.sh` - Surface ID 1000
- `app/MediaApp/run_wayland0.sh` - Surface ID 2000
- `app/AmbientApp/run_wayland0.sh` - Surface ID 3000
- `app/HomeScreenApp/run_wayland0.sh` - Surface ID 4000

### Unified Launcher
- `run-jetson-single-weston.sh` - Start all apps with single Weston + IVI Controller
- `stop-jetson-single-weston.sh` - Stop all apps

### IVI Layout Controller (GENIVI Standard)
- `app/IVILayoutController/` - C++ controller using ilmControl API
  - Built from wayland-ivi-extension headers
  - Links against NVIDIA's ILM libraries
  - Manages layer creation and surface positioning
  - Automotive industry standard (GENIVI)

### Layout Reference
- `config/ivi-layout-single-display.py` - Layout visualization and documentation

---

## 🚀 How to Run

### Step 1: Start Weston (if not already running)
```bash
weston --config=/etc/xdg/weston-13.0/weston.ini > /tmp/weston.log 2>&1 &
```

### Step 2: Run All Apps
```bash
cd /home/jetson/leo/DES_Head-Unit
./run-jetson-single-weston.sh
```

### Step 3: Monitor Logs
```bash
# All logs
tail -f /tmp/gearapp-wayland0.log
tail -f /tmp/mediaapp-wayland0.log
tail -f /tmp/ambientapp-wayland0.log
tail -f /tmp/homescreen-wayland0.log
tail -f /tmp/weston.log

# Or use multitail
multitail /tmp/*-wayland0.log /tmp/weston.log
```

### Step 4: Stop All Apps
```bash
./stop-jetson-single-weston.sh
```

---

## 🔧 Key Configuration Changes

### Environment Variables (in each run_wayland0.sh)

| Variable | Old Value | New Value | Purpose |
|----------|-----------|-----------|---------|
| `WAYLAND_DISPLAY` | `wayland-1` | `wayland-0` | Connect to Weston directly |
| `QT_IVI_SURFACE_ID` | Not set | `1000/2000/3000/4000` | IVI-Shell surface identification |
| `QT_QUICK_BACKEND` | `opengl` | `software` | Performance fix for Jetson |
| `QT_QPA_PLATFORM` | `wayland` | `wayland` | Unchanged |

### IVI Surface ID Assignment

| App | Surface ID | Position | Size |
|-----|-----------|----------|------|
| GearApp | 1000 | (0, 0) | 400x300 |
| MediaApp | 2000 | (400, 0) | 600x300 |
| AmbientApp | 3000 | (0, 300) | 1920x200 |
| HomeScreenApp | 4000 | (0, 500) | 1920x580 |

---

## 🧪 Testing Guide

### 1. Verify Weston is Running with IVI-Shell
```bash
ps aux | grep weston
# Should show: weston --config=/etc/xdg/weston-13.0/weston.ini

cat /etc/xdg/weston-13.0/weston.ini | grep -A 5 "\[ivi-shell\]"
# Should show: ivi-module=ivi-controller.so
```

### 2. Check wayland-0 Socket
```bash
ls -la $XDG_RUNTIME_DIR/wayland-*
# Should show: wayland-0 (NOT wayland-1)
```

### 3. Verify Apps Connect to wayland-0
```bash
# After running apps, check environment
ps aux | grep GearApp
cat /proc/<PID>/environ | tr '\0' '\n' | grep WAYLAND_DISPLAY
# Should output: WAYLAND_DISPLAY=wayland-0
```

### 4. Monitor App Startup
```bash
# GearApp log should show:
tail -f /tmp/gearapp-wayland0.log
# Look for:
#   WAYLAND_DISPLAY: wayland-0
#   QT_IVI_SURFACE_ID: 1000
```

### 5. Check All Apps are Running
```bash
ps aux | grep -E "(GearApp|MediaApp|AmbientApp|HomeScreenApp)" | grep -v grep
# Should show 4 processes
```

### 6. Verify No Compositor App Running
```bash
ps aux | grep HU_MainApp_Compositor
# Should return nothing (or only grep itself)
```

---

## 🐛 Troubleshooting

### Problem: Apps don't start
**Check**:
```bash
# 1. Is Weston running?
pgrep -x weston

# 2. Does wayland-0 socket exist?
ls -la $XDG_RUNTIME_DIR/wayland-0

# 3. Check app logs
tail -50 /tmp/gearapp-wayland0.log
```

### Problem: Apps crash immediately
**Common causes**:
1. Missing vsomeip configuration
2. Wrong library paths
3. Display connection failure

**Fix**:
```bash
# Check library loading
export LD_DEBUG=libs
./app/GearApp/run_wayland0.sh

# Check vsomeip
tail -f /tmp/gearapp-wayland0.log | grep -i vsomeip
```

### Problem: Black screen (apps running but not visible)
**Check**:
1. IVI-Shell configuration in weston.ini
2. QT_IVI_SURFACE_ID environment variable
3. Weston output configuration (DP-1)

```bash
# Verify weston.ini has IVI-Shell
grep -A 10 "\[ivi-shell\]" /etc/xdg/weston-13.0/weston.ini

# Verify DP-1 output
grep -A 5 "\[output\]" /etc/xdg/weston-13.0/weston.ini
```

---

## 🔄 Rollback to Old Architecture

If you need to go back to HU_MainApp_Compositor:

```bash
# 1. Restore old weston.ini
sudo cp /etc/xdg/weston-13.0/weston.ini.backup /etc/xdg/weston-13.0/weston.ini

# 2. Use old run scripts
cd app/GearApp && ./run.sh  # (uses wayland-1)

# 3. Start compositor
cd app/HU_MainApp && ./run_compositor.sh
```

---

## 📊 Performance Comparison

| Metric | Old (Nested) | New (Single) |
|--------|-------------|--------------|
| Compositor Overhead | 2 layers | 1 layer |
| Rendering Pipeline | App→Compositor→Weston→GPU | App→Weston→GPU |
| Memory Usage | Higher (2 compositors) | Lower (1 compositor) |
| CPU Usage | Higher (double composition) | Lower (single composition) |
| OTA Granularity | Group (all HU apps) | Individual app |

---

## 📝 Next Steps (When MST Hub Arrives)

1. **Add Second Display Output** to `weston.ini`:
```ini
[output]
name=DP-1
mode=1920x1080@60

[output]
name=DP-2  # (or DP-1-1, DP-1-2 for MST)
mode=1920x1080@60
```

2. **Assign Apps to Displays**:
   - DP-1 (HU): GearApp, MediaApp, AmbientApp, HomeScreenApp
   - DP-2 (IC): IC_app

3. **Update Layout Script** to handle dual displays

---

## ✅ Validation Checklist

- [x] weston.ini configured with IVI-Shell
- [x] Single DP-1 output defined
- [x] All apps have run_wayland0.sh scripts
- [x] IVI Surface IDs assigned (1000, 2000, 3000, 4000)
- [x] WAYLAND_DISPLAY=wayland-0 in all scripts
- [x] QT_QUICK_BACKEND=software for performance
- [x] Unified launcher script created
- [x] Stop script created
- [x] Layout documentation created
- [x] **IVI Layout Controller built (GENIVI ilmControl API)** ✅
- [x] **Integrated into run script** ✅
- [ ] **Weston restart and app test** (Ready to execute!)

---

## 📞 Support

If apps don't appear on screen:
1. Check `/tmp/*-wayland0.log` for errors
2. Verify Weston IVI-Shell is active
3. Confirm DP-1 is connected and configured
4. Test with single app first (GearApp)

**Architecture is ready! Now test by running:**
```bash
./run-jetson-single-weston.sh
```
