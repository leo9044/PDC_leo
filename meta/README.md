# ECU2 Yocto Layers - Overview

## Layer Structure

```
meta/
├── meta-middleware/              # Communication middleware
│   ├── conf/
│   │   └── layer.conf
│   ├── recipes-comm/
│   │   ├── vsomeip/             # SOME/IP v3.5.8
│   │   ├── commonapi-core/      # CommonAPI v3.2.4
│   │   ├── commonapi-someip/    # CommonAPI SOME/IP runtime
│   │   └── vsomeip-config/      # Configuration files
│   └── README.md
│
├── meta-headunit/               # Main display (HDMI-1)
│   ├── conf/
│   │   └── layer.conf
│   ├── classes/
│   │   └── headunit-image.bbclass
│   ├── recipes-apps/
│   │   ├── hu-mainapp/          # Wayland compositor
│   │   ├── gearapp/             # Gear selection UI
│   │   ├── mediaapp/            # Media player UI
│   │   ├── ambientapp/          # Ambient lighting UI
│   │   └── homescreenapp/       # Home screen launcher
│   ├── recipes-core/
│   │   └── images/
│   │       └── headunit-image.bb
│   ├── recipes-bsp/             # Raspberry Pi configs
│   ├── recipes-multimedia/      # Audio configs
│   └── README.md
│
├── meta-instrumentcluster/      # IC display (HDMI-2)
│   ├── conf/
│   │   └── layer.conf
│   ├── recipes-apps/
│   │   └── ic-app/              # Instrument cluster UI
│   ├── recipes-core/
│   │   └── images/
│   │       └── ic-image.bb      # (Optional test image)
│   └── README.md
│
├── LAYER_MIGRATION_GUIDE.md     # Migration documentation
└── README.md                     # This file
```

## Quick Start

### 1. Layer Dependencies

```
meta-instrumentcluster
    ↓
meta-middleware ← meta-headunit
    ↓
  core (OE)
```

### 2. Build Configuration

Add to `bblayers.conf`:
```bitbake
BBLAYERS += " \
  ${TOPDIR}/../../DES_Head-Unit/meta/meta-middleware \
  ${TOPDIR}/../../DES_Head-Unit/meta/meta-headunit \
  ${TOPDIR}/../../DES_Head-Unit/meta/meta-instrumentcluster \
"
```

### 3. Build Image

```bash
cd /home/seame/HU/chang_new/poky-kirkstone
source oe-init-build-env build-headunit
bitbake headunit-image
```

## Layer Purposes

### meta-middleware
- **Role**: Shared communication infrastructure
- **Provides**: vsomeip, CommonAPI-Core, CommonAPI-SomeIP
- **Used by**: All ECU2 applications
- **Priority**: 10

### meta-headunit
- **Role**: Main touchscreen display system
- **Provides**: HU_MainApp compositor + 4 client apps
- **Display**: HDMI-1 (1024x600 touchscreen)
- **Priority**: 15

### meta-instrumentcluster
- **Role**: Instrument cluster display
- **Provides**: IC_app standalone application
- **Display**: HDMI-2 (800x480 IC screen)
- **Priority**: 12

## Image Recipes

### headunit-image.bb (Production)
**Use this for ECU2 dual-display system**

Includes all applications:
- HU_MainApp (compositor)
- GearApp, MediaApp, AmbientApp, HomeScreenApp (clients)
- IC_app (standalone)

Output: Single SD card image for Raspberry Pi

### ic-image.bb (Testing Only)
**Optional: For standalone IC testing**

Includes only IC_app for isolated testing.

## Display Architecture

```
┌─────────────────────────────────────────┐
│         Raspberry Pi 4 (ECU2)           │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │       HU_MainApp                  │ │
│  │    (Wayland Compositor)           │ │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌────┐ │ │
│  │  │Gear │ │Media│ │Ambi │ │Home│ │ │  → HDMI-1
│  │  └─────┘ └─────┘ └─────┘ └────┘ │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │         IC_app                    │ │  → HDMI-2
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Application Details

| Application | Type | Display | Communication |
|-------------|------|---------|---------------|
| HU_MainApp | Compositor | HDMI-1 | Wayland server |
| GearApp | Client | HDMI-1 | Wayland + SOME/IP |
| MediaApp | Client | HDMI-1 | Wayland + SOME/IP |
| AmbientApp | Client | HDMI-1 | Wayland + SOME/IP |
| HomeScreenApp | Client | HDMI-1 | Wayland + SOME/IP |
| IC_app | Standalone | HDMI-2 | SOME/IP only |

## Build System

### Technology Stack
- **Build System**: Yocto Project (Kirkstone)
- **BSP**: meta-raspberrypi
- **GUI**: Qt5 + Wayland
- **Middleware**: vsomeip + CommonAPI
- **Init**: systemd

### Image Outputs
- **Format**: .rpi-sdimg, .ext4, .tar.bz2
- **Size**: ~1GB rootfs
- **Target**: Raspberry Pi 4 (ARM64)

## Documentation

- [Layer Migration Guide](LAYER_MIGRATION_GUIDE.md) - Detailed migration documentation
- [meta-middleware/README.md](meta-middleware/README.md) - Middleware layer details
- [meta-headunit/README.md](meta-headunit/README.md) - Head unit layer details
- [meta-instrumentcluster/README.md](meta-instrumentcluster/README.md) - IC layer details

## Version Information

- **Yocto**: Kirkstone (4.0 LTS)
- **vsomeip**: 3.5.8
- **CommonAPI**: 3.2.4
- **Qt**: 5.15.x
- **Target**: Raspberry Pi 4 Model B

## Compatibility

All layers compatible with:
- kirkstone
- langdale
- mickledore
- nanbield
- scarthgap

## Support

For issues or questions:
1. Check [LAYER_MIGRATION_GUIDE.md](LAYER_MIGRATION_GUIDE.md)
2. Review layer-specific README files
3. Check build logs in `tmp/work/`

## License

MIT License - See individual recipe files for details
