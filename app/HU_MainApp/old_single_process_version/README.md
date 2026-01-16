# Old Single-Process Version (Archived)

**Date Archived**: November 15, 2024

## Purpose

This directory contains the old single-process implementation of HU_MainApp, where all functionality (GearApp, MediaApp, AmbientApp) was integrated into one monolithic application.

## Why Archived?

The project has been **migrated to a multi-process Wayland compositor architecture**:

### Old Architecture (This Directory):
- ❌ Single process running all apps together
- ❌ Tight coupling between components
- ❌ All managers (MediaManager, GearManager, AmbientManager) in one executable
- ❌ Direct function calls between components

### New Architecture (Current Implementation):
- ✅ Wayland compositor managing separate app windows
- ✅ Each app runs as independent process
- ✅ Apps communicate via vSOME/IP
- ✅ Better separation of concerns
- ✅ HomePage built into compositor

## Files in This Archive

### Build System:
- `CMakeLists.txt` - Old single-process build configuration
- `build.sh` - Old build script
- `run.sh` - Old run script
- `qml.qrc` - Old QML resource file

### Source Code:
- `main.cpp` - Old single-process main entry point

### QML UI Components (Old):
- `main.qml` - Old main UI with integrated pages
- `HomePage.qml` - Dashboard (now built into compositor)
- `MediaPage.qml` - Media UI (now in MediaApp)
- `AmbientPage.qml` - Ambient UI (now in AmbientApp)
- `VehiclePage.qml` - Vehicle UI (now in GearApp)
- `components/` - Shared UI components
- `widgets/` - Widget components
- `compositor_old_backup.qml` - Previous compositor attempt

### Configuration:
- `commonapi.ini` - CommonAPI config (not needed by compositor)
- `vsomeip.json` - vSOME/IP config (not needed by compositor)

## Current Active Files (Not in Archive)

The current Wayland compositor uses:
- `CMakeLists_compositor.txt` - Compositor build config
- `src/main_compositor.cpp` - Compositor entry point
- `qml/compositor.qml` - Compositor UI with HomePage
- `qml_compositor.qrc` - Compositor resources
- `build_compositor.sh` - Build script
- `run_compositor.sh` - Run script
- `asset/car.svg` - Vehicle image for HomePage

## Reference

Keep this directory for:
- Understanding the evolution of the architecture
- Referencing old UI designs
- Comparing single-process vs multi-process approaches
- Historical documentation

## Do NOT Use These Files

These files are **outdated** and **not compatible** with the current multi-process architecture. Use the active Wayland compositor implementation instead.

---

**Migration Complete**: Phase 4 ✅
**New Architecture**: Multi-process Wayland compositor with independent apps
