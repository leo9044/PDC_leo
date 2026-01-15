# meta-headunit

Yocto/OpenEmbedded layer for Head Unit applications running on ECU2 main display.

## Description

This layer provides the main head unit system for the ECU2 dual-display setup:
- **HU_MainApp**: Wayland compositor managing the main display
- **GearApp**: Gear selection UI (Wayland client)
- **MediaApp**: Media player UI (Wayland client)
- **AmbientApp**: Ambient lighting control UI (Wayland client)
- **HomeScreenApp**: Main launcher/home screen UI (Wayland client)

## Architecture

```
┌─────────────────────────────────────┐
│         Raspberry Pi 4 (ECU2)       │
│                                     │
│  ┌───────────────────────────────┐ │
│  │     HU_MainApp                │ │
│  │  (Wayland Compositor)         │ │
│  │                               │ │
│  │  ┌──────┐  ┌──────┐  ┌─────┐ │ │
│  │  │ Gear │  │Media │  │Ambi │ │ │  ──► HDMI-1
│  │  └──────┘  └──────┘  └─────┘ │ │     (Touchscreen)
│  │  ┌──────────────────────────┐│ │
│  │  │    HomeScreenApp         ││ │
│  │  └──────────────────────────┘│ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Layer Contents

- `recipes-apps/` - Head unit application recipes
  - `hu-mainapp/` - Wayland compositor
  - `gearapp/` - Gear selection app
  - `mediaapp/` - Media player app
  - `ambientapp/` - Ambient lighting app
  - `homescreenapp/` - Home screen launcher
- `recipes-core/images/` - Headunit image recipe
- `recipes-bsp/` - Raspberry Pi BSP configurations
- `recipes-multimedia/` - PulseAudio configurations
- `classes/headunit-image.bbclass` - Common image configuration

## Dependencies

- meta (OE-Core)
- meta-middleware (vsomeip, CommonAPI)
- meta-qt5 (Qt5 framework)
- meta-raspberrypi (hardware support)
- meta-openembedded (additional utilities)

## Display Configuration

All applications run on HDMI-1 (main touchscreen) via HU_MainApp Wayland compositor.
Each client app connects to the compositor via Wayland protocol.

## Usage

Add this layer to your `bblayers.conf`:

```
BBLAYERS += "/path/to/DES_Head-Unit/meta/meta-headunit"
```

Build the headunit image:

```
bitbake headunit-image
```

## Compatibility

- Yocto: kirkstone, langdale, mickledore, nanbield, scarthgap
- Target: ARM64 (Raspberry Pi 4)
- Display: HDMI-1 (main touchscreen)
