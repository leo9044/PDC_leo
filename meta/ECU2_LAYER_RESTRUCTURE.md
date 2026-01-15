# ECU2 Yocto Layer Restructure - Complete Guide

**Date**: 2025-11-19
**Status**: ✅ Implementation Complete (Ready for Testing)

---

## Table of Contents
1. [Overview](#overview)
2. [What Changed](#what-changed)
3. [Final Layer Structure](#final-layer-structure)
4. [Layer Details](#layer-details)
5. [Build Configuration](#build-configuration)
6. [Display Architecture](#display-architecture)
7. [Next Steps](#next-steps)

---

## Overview

Successfully restructured ECU2 Yocto layers from monolithic single-layer to clean **3-layer architecture** following automotive industry standards for dual-display system (Head Unit + Instrument Cluster).

### Why This Change?
- ✅ **Separation of Concerns**: Middleware, Head Unit, and IC clearly separated
- ✅ **Reusability**: Middleware can be used across multiple ECU projects
- ✅ **Independent Development**: Test IC without headunit apps
- ✅ **Industry Standard**: Follows automotive best practices (AGL, GENIVI)
- ✅ **Scalability**: Easy to add new apps or features
- ✅ **Maintainability**: Clear ownership per layer

---

## What Changed

### Before (Single Layer)
```
meta/
└── meta-headunit/
    ├── recipes-comm/          # Middleware (vsomeip, CommonAPI)
    ├── recipes-module/        # ALL apps (HU + IC)
    └── recipes-core/images/
```

### After (3-Layer Architecture)
```
meta/
├── meta-middleware/           ✅ NEW
│   └── recipes-comm/          # vsomeip, CommonAPI
│
├── meta-headunit/             ✅ UPDATED
│   └── recipes-apps/          # HU apps only (renamed from recipes-module)
│
└── meta-instrumentcluster/    ✅ NEW
    └── recipes-apps/          # IC app only
```

---

## Final Layer Structure

```
DES_Head-Unit/meta/
│
├── meta-middleware/                    ✅ NEW LAYER
│   ├── conf/
│   │   └── layer.conf                 # Priority: 10, Depends: core
│   ├── recipes-comm/
│   │   ├── vsomeip/                   # SOME/IP v3.5.8
│   │   ├── commonapi-core/            # CommonAPI v3.2.4
│   │   ├── commonapi-someip/          # CommonAPI SOME/IP runtime
│   │   └── vsomeip-config/            # Configuration files
│   └── README.md
│
├── meta-headunit/                      ✅ UPDATED LAYER
│   ├── conf/
│   │   └── layer.conf                 # Priority: 15, Depends: core + meta-middleware
│   ├── classes/
│   │   └── headunit-image.bbclass     # Common image configuration
│   ├── recipes-apps/                  # RENAMED from recipes-module
│   │   ├── hu-mainapp/                # Wayland compositor
│   │   ├── gearapp/                   # Gear UI (Wayland client)
│   │   ├── mediaapp/                  # Media UI (Wayland client)
│   │   ├── ambientapp/                # Ambient UI (Wayland client)
│   │   └── homescreenapp/             ✅ NEW (Wayland client)
│   ├── recipes-core/
│   │   └── images/
│   │       └── headunit-image.bb      # Production image (both displays)
│   ├── recipes-bsp/                   # Raspberry Pi configs
│   ├── recipes-multimedia/            # PulseAudio configs
│   └── README.md                      ✅ UPDATED
│
├── meta-instrumentcluster/             ✅ NEW LAYER
│   ├── conf/
│   │   └── layer.conf                 # Priority: 12, Depends: core + meta-middleware
│   ├── recipes-apps/
│   │   └── ic-app/                    # Instrument cluster app
│   ├── recipes-core/
│   │   └── images/
│   │       └── ic-image.bb            # Optional: IC-only test image
│   └── README.md
│
└── README.md                           ✅ UPDATED
```

---

## Layer Details

### 1. meta-middleware
**Purpose**: Shared communication infrastructure

| Component | Version | Description |
|-----------|---------|-------------|
| vsomeip | 3.5.8 | SOME/IP implementation |
| CommonAPI-Core | 3.2.4 | Middleware abstraction API |
| CommonAPI-SomeIP | 3.2.4 | SOME/IP binding for CommonAPI |
| vsomeip-config | 1.0 | Configuration files |

**Used by**: Both meta-headunit and meta-instrumentcluster

**Benefits**:
- Reusable across ECU1, ECU2, ECU3 projects
- Independent versioning and updates
- Clear separation from application logic

---

### 2. meta-headunit
**Purpose**: Main touchscreen display system (HDMI-1)

| Application | Type | Description |
|-------------|------|-------------|
| HU_MainApp | Compositor | Wayland compositor managing display |
| GearApp | Client | Gear selection UI |
| MediaApp | Client | Media player UI |
| AmbientApp | Client | Ambient lighting control UI |
| HomeScreenApp | Client | Main launcher/home screen ✅ NEW |

**Display**: HDMI-1 (1024x600 touchscreen)

**Architecture**: Compositor-client model
- HU_MainApp runs Wayland compositor
- All other apps connect as Wayland clients
- Each app embedded in specific compositor section

---

### 3. meta-instrumentcluster
**Purpose**: Instrument cluster display (HDMI-2)

| Application | Type | Description |
|-------------|------|-------------|
| IC_app | Standalone | Instrument cluster UI |

**Display**: HDMI-2 (800x480 IC screen)

**Independence**: Runs standalone, can be tested separately

---

## Build Configuration

### Layer Dependencies

```
┌─────────────────────────┐
│  meta-instrumentcluster │
└──────────┬──────────────┘
           │ depends on
           ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   meta-middleware       │ ◄───┤   meta-headunit         │
└──────────┬──────────────┘     └─────────────────────────┘
           │ depends on              │ depends on
           ▼                          ▼
┌────────────────────────────────────┐
│          core (OE-Core)            │
└────────────────────────────────────┘
```

### Updated bblayers.conf

**File**: `/home/seame/HU/chang_new/poky-kirkstone/build-headunit/conf/bblayers.conf`

```bitbake
BBLAYERS ?= " \
  ${TOPDIR}/../meta \
  ${TOPDIR}/../meta-poky \
  ${TOPDIR}/../meta-yocto-bsp \
  ${TOPDIR}/../../meta-raspberrypi \
  ${TOPDIR}/../../meta-openembedded/meta-oe \
  ${TOPDIR}/../../meta-openembedded/meta-python \
  ${TOPDIR}/../../meta-openembedded/meta-multimedia \
  ${TOPDIR}/../../meta-openembedded/meta-networking \
  ${TOPDIR}/../../meta-qt5 \
  ${TOPDIR}/../../DES_Head-Unit/meta/meta-middleware \         ✅ NEW
  ${TOPDIR}/../../DES_Head-Unit/meta/meta-headunit \
  ${TOPDIR}/../../DES_Head-Unit/meta/meta-instrumentcluster \  ✅ NEW
"
```

### Image Recipes

#### headunit-image.bb (Production - Use This)
**File**: `meta-headunit/recipes-core/images/headunit-image.bb`

```bitbake
SUMMARY = "Head Unit Linux Image"
DESCRIPTION = "Custom Linux image for Raspberry Pi with dual-display support"

inherit headunit-image

# ECU2 Applications for dual-display setup
IMAGE_INSTALL:append = " \
    hu-mainapp \        # HDMI-1 compositor
    ambientapp \        # HDMI-1 client
    gearapp \           # HDMI-1 client
    mediaapp \          # HDMI-1 client
    homescreenapp \     # HDMI-1 client ✅ NEW
    ic-app \            # HDMI-2 standalone
    vsomeip-config \
"
```

**Output**: Single SD card image running both displays

#### ic-image.bb (Testing Only - Optional)
**File**: `meta-instrumentcluster/recipes-core/images/ic-image.bb`

```bitbake
SUMMARY = "Instrument Cluster Test Image"
DESCRIPTION = "Minimal image for testing IC_app standalone"

inherit headunit-image

IMAGE_INSTALL:append = " \
    ic-app \
    vsomeip-config \
"
```

**Use**: Only for standalone IC testing without headunit

---

## Display Architecture

### ECU2 Dual-Display System

```
┌─────────────────────────────────────────────────────────────┐
│              Raspberry Pi 4 (ECU2)                          │
│           Single SD Card / Single OS Image                  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              HU_MainApp                               │ │
│  │          (Wayland Compositor)                         │ │
│  │                                                       │ │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │ │
│  │  │  GearApp   │  │  MediaApp  │  │ AmbientApp │     │ │
│  │  │ (Client)   │  │ (Client)   │  │  (Client)  │     │ │
│  │  └────────────┘  └────────────┘  └────────────┘     │ │
│  │  ┌──────────────────────────────────────────────┐   │ │  → HDMI-1
│  │  │         HomeScreenApp (Client)              │   │ │    Main Display
│  │  │          Main Launcher UI                    │   │ │    1024x600
│  │  └──────────────────────────────────────────────┘   │ │    Touchscreen
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                   IC_app                              │ │  → HDMI-2
│  │              (Standalone App)                         │ │    IC Display
│  │    Speed, RPM, Gear, Temperature, etc.               │ │    800x480
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Communication Flow

```
┌─────────────┐                           ┌─────────────┐
│  GearApp    │◄─── Wayland Protocol ────►│ HU_MainApp  │
└──────┬──────┘                           └──────┬──────┘
       │                                         │
       │         ┌─────────────────────┐         │
       └────────►│   vsomeip/SOME/IP   │◄────────┘
                 │   (Service Bus)     │
       ┌────────►│                     │◄────────┐
       │         └─────────────────────┘         │
┌──────┴──────┐                           ┌──────┴──────┐
│  MediaApp   │                           │   IC_app    │
└─────────────┘                           └─────────────┘
```

### Systemd Services

```
multi-user.target
├── hu-mainapp.service         → Launch HU_MainApp on HDMI-1
├── gearapp.service            → Launch GearApp (waits for compositor)
├── mediaapp.service           → Launch MediaApp (waits for compositor)
├── ambientapp.service         → Launch AmbientApp (waits for compositor)
├── homescreenapp.service      → Launch HomeScreenApp (waits for compositor)
└── ic-display.service         → Launch IC_app on HDMI-2
```

---

## Application Mapping

| Application | Layer | Display | Type | Protocol | Status |
|-------------|-------|---------|------|----------|--------|
| HU_MainApp | meta-headunit | HDMI-1 | Compositor | Wayland server + SOME/IP | Existing |
| GearApp | meta-headunit | HDMI-1 | Client | Wayland + SOME/IP | Existing |
| MediaApp | meta-headunit | HDMI-1 | Client | Wayland + SOME/IP | Existing |
| AmbientApp | meta-headunit | HDMI-1 | Client | Wayland + SOME/IP | Existing |
| HomeScreenApp | meta-headunit | HDMI-1 | Client | Wayland + SOME/IP | ✅ NEW |
| IC_app | meta-instrumentcluster | HDMI-2 | Standalone | SOME/IP only | Existing |

---

## Changes Summary

### Files Created

| File | Description |
|------|-------------|
| `meta/meta-middleware/conf/layer.conf` | Middleware layer config |
| `meta/meta-middleware/README.md` | Middleware documentation |
| `meta/meta-instrumentcluster/conf/layer.conf` | IC layer config |
| `meta/meta-instrumentcluster/README.md` | IC documentation |
| `meta/meta-instrumentcluster/recipes-core/images/ic-image.bb` | IC test image |
| `meta/meta-headunit/recipes-apps/homescreenapp/homescreenapp_1.0.bb` | HomeScreen recipe ✅ NEW |
| `meta/meta-headunit/recipes-apps/homescreenapp/files/homescreenapp.service` | Systemd service |
| `meta/README.md` | Main layer overview |
| `ECU2_LAYER_RESTRUCTURE.md` | This document |

### Files Modified

| File | Change |
|------|--------|
| `meta/meta-headunit/conf/layer.conf` | Added meta-middleware dependency |
| `meta/meta-headunit/README.md` | Updated documentation |
| `meta/meta-headunit/recipes-core/images/headunit-image.bb` | Added homescreenapp + ic-app |
| `poky-kirkstone/build-headunit/conf/bblayers.conf` | Added new layers |

### Moved/Renamed

| From | To |
|------|-----|
| `meta-headunit/recipes-comm/` | `meta-middleware/recipes-comm/` |
| `meta-headunit/recipes-module/ic-app/` | `meta-instrumentcluster/recipes-apps/ic-app/` |
| `meta-headunit/recipes-module/` | `meta-headunit/recipes-apps/` |

---

## Next Steps

### 1. Verify Layer Configuration
```bash
cd /home/seame/HU/chang_new/poky-kirkstone
source oe-init-build-env build-headunit
bitbake-layers show-layers
```

**Expected output**: Should show meta-middleware, meta-headunit, meta-instrumentcluster

### 2. Verify Recipe Parsing
```bash
bitbake -p
```

**Expected**: All recipes parse without errors

### 3. Build Production Image
```bash
bitbake headunit-image
```

**Expected**: Successful build with all 6 applications

### 4. Check Dependencies
```bash
bitbake -g headunit-image
dot -Tpng task-depends.dot -o deps.png
```

### 5. Flash and Test
```bash
# Flash SD card
sudo dd if=tmp/deploy/images/raspberrypi4-64/headunit-image-raspberrypi4-64.rpi-sdimg of=/dev/sdX bs=4M status=progress

# Boot Raspberry Pi
# Verify HDMI-1: HU_MainApp with 4 client apps
# Verify HDMI-2: IC_app running standalone
```

---

## Build Commands Reference

### Production Build (Dual-Display)
```bash
cd /home/seame/HU/chang_new/poky-kirkstone
source oe-init-build-env build-headunit
bitbake headunit-image
```

### IC Test Build (Optional)
```bash
bitbake ic-image
```

### Clean Specific App
```bash
bitbake -c cleanall homescreenapp
bitbake homescreenapp
```

### Clean All and Rebuild
```bash
bitbake -c cleanall headunit-image
bitbake headunit-image
```

### Check Recipe Dependencies
```bash
bitbake -e homescreenapp | grep "^DEPENDS="
```

---

## Troubleshooting

### Issue: "Nothing PROVIDES 'vsomeip'"
**Cause**: meta-middleware not in bblayers.conf or wrong order

**Solution**:
```bash
bitbake-layers show-layers | grep middleware
# If not shown, add to bblayers.conf
# Ensure meta-middleware comes BEFORE meta-headunit
```

### Issue: "Layer 'meta-middleware' not found"
**Cause**: Incorrect path in bblayers.conf

**Solution**: Check path matches actual location:
```bash
ls ${TOPDIR}/../../DES_Head-Unit/meta/meta-middleware
```

### Issue: HomeScreenApp recipe not found
**Cause**: Recipe directory structure issue

**Solution**:
```bash
ls -la /home/seame/HU/chang_new/DES_Head-Unit/meta/meta-headunit/recipes-apps/homescreenapp/
# Should show homescreenapp_1.0.bb
```

### Issue: Build fails for homescreenapp
**Cause**: HomeScreenApp source not built or CMakeLists.txt issues

**Solution**:
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HomeScreenApp
mkdir -p build && cd build
cmake ..
make
```

### Issue: Dependency cycle detected
**Cause**: Circular dependencies between layers

**Solution**: Check LAYERDEPENDS in each layer.conf:
- meta-middleware depends on: core
- meta-headunit depends on: core, meta-middleware
- meta-instrumentcluster depends on: core, meta-middleware

---

## Benefits Achieved

| Aspect | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Layer Organization** | 1 monolithic | 3 specialized | Clear separation |
| **Middleware Reuse** | Locked in headunit | Independent layer | Multi-ECU reuse |
| **IC Development** | Mixed with HU | Separate layer | Independent testing |
| **Recipe Organization** | recipes-module | recipes-apps | Industry standard |
| **Scalability** | Hard to extend | Easy to add apps | Better architecture |
| **Maintainability** | Complex dependencies | Clear ownership | Easier updates |
| **Industry Alignment** | Custom | AGL/GENIVI pattern | Standard practice |

---

## Layer Priorities

```
meta-headunit          : 15 (highest - overrides Qt5, OE packages)
meta-instrumentcluster : 12 (medium)
meta-middleware        : 10 (standard)
core layers            : 5-7 (base)
```

**Why**: Ensures project recipes take precedence over upstream layers

---

## Technology Stack

- **Build System**: Yocto Project (Kirkstone 4.0 LTS)
- **BSP**: meta-raspberrypi
- **UI Framework**: Qt5 (5.15.x)
- **Display Protocol**: Wayland
- **Middleware**: vsomeip 3.5.8 + CommonAPI 3.2.4
- **Init System**: systemd
- **Target**: Raspberry Pi 4 Model B (ARM64)

---

## Project Status

| Task | Status |
|------|--------|
| Create meta-middleware layer | ✅ Complete |
| Extract middleware recipes | ✅ Complete |
| Create meta-instrumentcluster layer | ✅ Complete |
| Move IC_app to meta-instrumentcluster | ✅ Complete |
| Rename recipes-module → recipes-apps | ✅ Complete |
| Add HomeScreenApp recipe | ✅ Complete |
| Update layer.conf dependencies | ✅ Complete |
| Update bblayers.conf | ✅ Complete |
| Update image recipes | ✅ Complete |
| Create documentation | ✅ Complete |
| **Test build** | ⏳ **Next Step** |
| **Hardware testing** | ⏳ **Next Step** |

---

## Conclusion

The ECU2 layer restructure implements a **clean 3-layer architecture** following automotive industry standards:

1. **meta-middleware** - Reusable communication infrastructure
2. **meta-headunit** - Main display system (HDMI-1)
3. **meta-instrumentcluster** - IC display system (HDMI-2)

This structure provides:
- Clear separation of concerns
- Independent layer development
- Industry-standard organization
- Scalable architecture for future growth

**Ready for testing**: Build configuration complete. Next step is to run `bitbake headunit-image` and verify successful build.

---

**For questions or issues**: Check layer-specific README files in `meta/meta-*/README.md` or review build logs in `tmp/work/`.
