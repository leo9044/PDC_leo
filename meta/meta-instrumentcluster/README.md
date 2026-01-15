# meta-instrumentcluster

Yocto/OpenEmbedded layer for Instrument Cluster application running on ECU2 secondary display.

## Description

This layer provides the instrument cluster application for the ECU2 dual-display system:
- **IC_app**: Standalone instrument cluster application (Qt5/QML)
- Displays vehicle information (speed, RPM, gear, etc.)
- Runs on HDMI-2 (secondary display)
- Independent from main head unit compositor

## Layer Contents

- `recipes-apps/ic-app/` - Instrument cluster application
- `recipes-core/images/ic-image.bb` - IC-specific image recipe (optional)

## Architecture

```
┌─────────────────────────────┐
│    Raspberry Pi 4 (ECU2)    │
│                             │
│    IC_app (Standalone)      │ ──► HDMI-2 (IC Display)
│    - Direct rendering       │
│    - Qt5/Wayland or EGL     │
└─────────────────────────────┘
```

## Dependencies

- meta (OE-Core)
- meta-middleware (vsomeip, CommonAPI)
- meta-qt5 (Qt5 framework)
- meta-raspberrypi (hardware support)

## Display Configuration

The IC application is configured to run on HDMI-2 via systemd service.
See `recipes-apps/ic-app/files/ic-display.service` for display setup.

## Usage

Add this layer to your `bblayers.conf`:

```
BBLAYERS += "/path/to/DES_Head-Unit/meta/meta-instrumentcluster"
```

Add IC_app to your image:

```
IMAGE_INSTALL:append = " ic-app"
```

## Compatibility

- Yocto: kirkstone, langdale, mickledore, nanbield, scarthgap
- Target: ARM64 (Raspberry Pi 4)
- Display: HDMI-2
