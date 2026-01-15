# Kiosk Shell Migration Summary

## Overview
Successfully migrated from **IVI Shell** to **Kiosk Shell** for simpler dual-display management.

**Migration Date**: December 3, 2025  
**Branch**: Chang_wayland2

---

## What Changed

### **Architecture Change**

| Aspect | Before (IVI Shell) | After (Kiosk Shell) |
|--------|-------------------|---------------------|
| **Shell Type** | `ivi-shell.so` | `kiosk-shell.so` |
| **Routing Method** | IVI surface IDs + layers | Application name matching |
| **Configuration Files** | weston.ini + ivi-controller.conf | weston.ini only |
| **Complexity** | High (layer-based) | Low (direct app-to-display) |

---

## Files Modified

### 1. **weston.ini** ✅
**Path**: `/meta/meta-headunit/recipes-graphics/weston/weston-init/weston.ini`

**Changes**:
```ini
# BEFORE (IVI Shell)
[core]
shell=ivi-shell.so
modules=systemd-notify.so,ivi-controller.so

[ivi-shell]
ivi-module=ivi-controller.so
ivi-input-module=ivi-input-controller.so

[output]
name=HDMI-A-1
mode=1024x600
# No app routing here

[output]
name=DSI-1
mode=400x1280
# No app routing here
```

```ini
# AFTER (Kiosk Shell)
[core]
shell=kiosk-shell.so
backend=drm-backend.so
require-input=true
idle-time=0
modules=systemd-notify.so

[output]
name=HDMI-A-1
mode=1024x600@60
transform=normal
scale=1
app-ids=HeadUnitApp  # ← Routes HU app to HDMI
cursor-size=0

[output]
name=DSI-1
mode=400x1280@60
transform=normal
scale=1
app-ids=appIC  # ← Routes IC app to DSI
cursor-size=0

[shell]
panel-position=none
background-color=0xff000000
locking=false
```

**Key Changes**:
- ✅ Changed `shell=ivi-shell.so` → `shell=kiosk-shell.so`
- ✅ Removed `ivi-shell` section
- ✅ Added `app-ids=` to each output
- ✅ Added refresh rates (@60)
- ✅ Added `cursor-size=0` to hide cursor
- ✅ Added `[shell]` section for kiosk configuration

---

### 2. **weston-init.bbappend** ✅
**Path**: `/meta/meta-headunit/recipes-graphics/weston/weston-init.bbappend`

**Changes**:
```bitbake
# BEFORE
SRC_URI += "file://weston.ini \
            file://ivi-controller.conf"  # ← IVI controller config

do_install:append() {
    install -m 0644 ${WORKDIR}/weston.ini ${D}${sysconfdir}/xdg/weston/weston.ini
    install -m 0644 ${WORKDIR}/ivi-controller.conf ${D}${sysconfdir}/xdg/weston/ivi-controller.conf
}

FILES:${PN} += "${sysconfdir}/xdg/weston/weston.ini ${sysconfdir}/xdg/weston/ivi-controller.conf"
```

```bitbake
# AFTER
# Kiosk Shell configuration - removed IVI shell controller
SRC_URI += "file://weston.ini"  # ← Only weston.ini needed

do_install:append() {
    install -d ${D}${sysconfdir}/xdg/weston
    install -m 0644 ${WORKDIR}/weston.ini ${D}${sysconfdir}/xdg/weston/weston.ini
}

FILES:${PN} += "${sysconfdir}/xdg/weston/weston.ini"
```

**Key Changes**:
- ✅ Removed `ivi-controller.conf` from SRC_URI
- ✅ Removed ivi-controller.conf installation
- ✅ Removed ivi-controller.conf from FILES list

---

### 3. **IC_app/main.cpp** ✅
**Path**: `/app/IC_app/main.cpp`

**Changes**:
```cpp
// BEFORE (IVI Shell)
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("IC_app");
    // No routing info - relied on IVI surface ID
}
```

```cpp
// AFTER (Kiosk Shell)
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // ═══════════════════════════════════════════════════════
    // KIOSK SHELL: Set application name for display routing
    // ═══════════════════════════════════════════════════════
    // This name must match the app-ids in weston.ini
    app.setApplicationName("appIC");  // ← Routes to DSI-1 output
    app.setApplicationDisplayName("Instrument Cluster");
    
    qDebug() << "IC_app Starting (Kiosk Shell - DSI Display)";
    qDebug() << "App ID: appIC → DSI-1 (400x1280)";
}
```

**Key Changes**:
- ✅ Changed app name from `"IC_app"` → `"appIC"` (matches weston.ini)
- ✅ Added comments explaining Kiosk Shell routing
- ✅ Updated debug messages to indicate Kiosk Shell mode
- ❌ **Removed**: `qputenv("QT_IVI_SURFACE_ID", "2000")` (no longer needed)

---

### 4. **HU_MainApp/src/main_compositor.cpp** ✅
**Path**: `/app/HU_MainApp/src/main_compositor.cpp`

**Changes**:
```cpp
// BEFORE (IVI Shell)
int main(int argc, char *argv[])
{
    qputenv("QT_IVI_SURFACE_ID", "1000");  // IVI routing
    
    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnit-Compositor");
}
```

```cpp
// AFTER (Kiosk Shell)
int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // KIOSK SHELL: Set application name for display routing
    // ═══════════════════════════════════════════════════════
    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnitApp");  // ← Routes to HDMI-A-1
    app.setApplicationVersion("2.0-Kiosk");
    
    qDebug() << "HU_MainApp - Nested Wayland Compositor (Kiosk Shell)";
    qDebug() << "App ID: HeadUnitApp → HDMI-A-1 (1024x600)";
}
```

**Key Changes**:
- ✅ Changed app name from `"HeadUnit-Compositor"` → `"HeadUnitApp"` (matches weston.ini)
- ✅ Added comments explaining Kiosk Shell routing
- ✅ Updated version to "2.0-Kiosk"
- ✅ Updated debug messages
- ❌ **Removed**: `qputenv("QT_IVI_SURFACE_ID", "1000")` (no longer needed)

---

## Files Removed

### **ivi-controller.conf** 🗑️
**Path**: `/meta/meta-headunit/recipes-graphics/weston/weston-init/ivi-controller.conf`

**Status**: No longer needed with Kiosk Shell

**Previous Content**:
```properties
# Layer-based IVI surface routing
layer.1000.surface=1000
layer.1000.output=HDMI-A-1
layer.2000.surface=2000
layer.2000.output=DSI-1
```

**Why Removed**: Kiosk Shell uses direct app-id matching instead of layer-based routing.

---

## Display Routing

### How It Works Now

```
┌────────────────────────────────────────────┐
│         Weston (Kiosk Shell)               │
│                                            │
│  ┌─────────────────────────────────────┐  │
│  │  App Name Matching                  │  │
│  │                                     │  │
│  │  "HeadUnitApp" → HDMI-A-1          │  │
│  │  "appIC"       → DSI-1             │  │
│  └─────────────────────────────────────┘  │
│                                            │
│  [HDMI-A-1]           [DSI-1]             │
│  1024x600             400x1280            │
│  ┌──────────┐         ┌──────────┐       │
│  │ HU_MainApp│         │  IC_app  │       │
│  │          │         │          │       │
│  │HeadUnitApp│         │  appIC   │       │
│  └──────────┘         └──────────┘       │
└────────────────────────────────────────────┘
```

**Before (IVI Shell)**:
1. App sets `QT_IVI_SURFACE_ID` (e.g., 1000)
2. IVI Controller routes surface to layer
3. Layer maps to output

**After (Kiosk Shell)**:
1. App sets `setApplicationName()` (e.g., "HeadUnitApp")
2. Kiosk Shell matches app-id to output
3. Direct routing to display

---

## Application Name Mapping

| Application | Code (setApplicationName) | weston.ini (app-ids) | Display |
|-------------|--------------------------|---------------------|---------|
| **HU_MainApp** | `"HeadUnitApp"` | `app-ids=HeadUnitApp` | HDMI-A-1 (1024x600) |
| **IC_app** | `"appIC"` | `app-ids=appIC` | DSI-1 (400x1280) |

⚠️ **IMPORTANT**: Application names MUST match exactly!

---

## Testing Checklist

After migration, verify:

- [ ] **Build System**: Rebuild Yocto image
  ```bash
  bitbake headunit-image -c cleanall
  bitbake headunit-image
  ```

- [ ] **Weston Service**: Check Weston starts with kiosk-shell
  ```bash
  journalctl -u weston -f
  # Look for: "using kiosk-shell.so"
  ```

- [ ] **IC_app Display**: Verify IC_app appears on DSI screen
  ```bash
  journalctl -u ic-app -f
  # Look for: "App ID: appIC → DSI-1"
  ```

- [ ] **HU_MainApp Display**: Verify HU_MainApp appears on HDMI
  ```bash
  journalctl -u hu-mainapp-compositor -f
  # Look for: "App ID: HeadUnitApp → HDMI-A-1"
  ```

- [ ] **Display Assignment**: Both apps on correct screens
  - HDMI shows Head Unit UI (1024x600)
  - DSI shows Instrument Cluster (400x1280)

---

## Advantages of Kiosk Shell

✅ **Simpler Configuration**
- Single weston.ini file (no ivi-controller.conf)
- Direct app-to-display mapping
- Easier to understand and debug

✅ **Less Code Complexity**
- No IVI surface ID management
- No layer configuration
- Standard Wayland app names

✅ **Faster Routing**
- Direct app-id matching
- No layer indirection
- Reduced compositor overhead

---

## Disadvantages (Trade-offs)

❌ **Less Flexible**
- Can't dynamically reassign apps to displays
- No multi-layer composition
- Fixed app-to-display binding

❌ **Not Automotive Standard**
- IVI shell is GENIVI/COVESA standard
- Kiosk shell is simpler, general-purpose
- Less suited for complex automotive systems

❌ **Limited Window Management**
- Fullscreen only (kiosk mode)
- No window positioning control
- Less suitable for complex layouts

---

## When to Use Each Shell

### Use Kiosk Shell When:
- ✅ Simple dual-display setup
- ✅ Fixed app-to-display mapping
- ✅ Full-screen applications
- ✅ Prototyping/development

### Use IVI Shell When:
- ✅ Complex multi-display systems
- ✅ Dynamic display routing needed
- ✅ Layer-based composition
- ✅ Automotive industry compliance
- ✅ Advanced window management

---

## Rollback Instructions

If you need to revert to IVI Shell:

1. **Restore weston.ini**:
   ```bash
   git checkout HEAD~1 -- meta/meta-headunit/recipes-graphics/weston/weston-init/weston.ini
   ```

2. **Restore weston-init.bbappend**:
   ```bash
   git checkout HEAD~1 -- meta/meta-headunit/recipes-graphics/weston/weston-init.bbappend
   ```

3. **Restore ivi-controller.conf**:
   ```bash
   git checkout HEAD~1 -- meta/meta-headunit/recipes-graphics/weston/weston-init/ivi-controller.conf
   ```

4. **Update application code**:
   - IC_app: Restore `QT_IVI_SURFACE_ID` = "2000"
   - HU_MainApp: Restore `QT_IVI_SURFACE_ID` = "1000"

5. **Rebuild**:
   ```bash
   bitbake headunit-image -c cleanall
   bitbake headunit-image
   ```

---

## References

- **Weston Kiosk Shell**: https://wayland.pages.freedesktop.org/weston/toc/kiosk-shell.html
- **Weston IVI Shell**: https://github.com/GENIVI/wayland-ivi-extension
- **Qt Wayland Compositor**: https://doc.qt.io/qt-5/qtwaylandcompositor-index.html

---

## Summary

### Modified Files (4):
1. ✅ `meta/meta-headunit/recipes-graphics/weston/weston-init/weston.ini`
2. ✅ `meta/meta-headunit/recipes-graphics/weston/weston-init.bbappend`
3. ✅ `app/IC_app/main.cpp`
4. ✅ `app/HU_MainApp/src/main_compositor.cpp`

### Removed Files (1):
1. 🗑️ `meta/meta-headunit/recipes-graphics/weston/weston-init/ivi-controller.conf`

### Key Changes:
- Switched from **IVI Shell** to **Kiosk Shell**
- Simplified display routing (app-id matching)
- Removed layer-based configuration
- Updated application names to match weston.ini

**Migration Status**: ✅ **COMPLETE**

---

*Document generated: December 3, 2025*  
*Repository: DES_Head-Unit*  
*Branch: Chang_wayland2*
