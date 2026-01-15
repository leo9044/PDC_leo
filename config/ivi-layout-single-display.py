#!/usr/bin/env python3

"""
IVI Layout Controller for Single Display (1920x1080)
Simple 4-app layout manager using Qt Window Geometry

Layout Plan (Single DP-1):
┌─────────────────────────────────────────────────┐
│  GearApp (1000)     │  MediaApp (2000)          │
│  400x300            │  600x300                  │
├─────────────────────┴───────────────────────────┤
│  AmbientApp (3000)                              │
│  1920x200                                       │
├─────────────────────────────────────────────────┤
│  HomeScreenApp (4000)                           │
│  1920x580                                       │
└─────────────────────────────────────────────────┘

Note: This is a reference layout. Actual positioning is done by:
1. Qt Wayland Shell Integration (automatic, preferred)
2. QT_IVI_SURFACE_ID environment variable (already set in run scripts)
3. IVI-Shell configuration (weston.ini)

This script is for documentation and future manual control if needed.
"""

DISPLAY_WIDTH = 1920
DISPLAY_HEIGHT = 1080

LAYOUT = {
    "GearApp": {
        "surface_id": 1000,
        "x": 0,
        "y": 0,
        "width": 400,
        "height": 300,
        "layer": 1000,
        "z_order": 100
    },
    "MediaApp": {
        "surface_id": 2000,
        "x": 400,
        "y": 0,
        "width": 600,
        "height": 300,
        "layer": 1000,
        "z_order": 100
    },
    "AmbientApp": {
        "surface_id": 3000,
        "x": 0,
        "y": 300,
        "width": 1920,
        "height": 200,
        "layer": 2000,
        "z_order": 200
    },
    "HomeScreenApp": {
        "surface_id": 4000,
        "x": 0,
        "y": 500,
        "width": 1920,
        "height": 580,
        "layer": 2000,
        "z_order": 200
    }
}

def print_layout():
    print("════════════════════════════════════════════════════════════")
    print("IVI Layout Configuration - Single Display (DP-1)")
    print("════════════════════════════════════════════════════════════")
    print(f"Display: {DISPLAY_WIDTH}x{DISPLAY_HEIGHT}")
    print("")
    
    for app_name, config in LAYOUT.items():
        print(f"{app_name}:")
        print(f"  Surface ID: {config['surface_id']}")
        print(f"  Position: ({config['x']}, {config['y']})")
        print(f"  Size: {config['width']}x{config['height']}")
        print(f"  Layer: {config['layer']} (z-order: {config['z_order']})")
        print("")
    
    print("════════════════════════════════════════════════════════════")
    print("How Layout is Applied:")
    print("════════════════════════════════════════════════════════════")
    print("1. Environment Variables (in run_wayland0.sh scripts):")
    print("   export QT_IVI_SURFACE_ID=<surface_id>")
    print("")
    print("2. Qt Automatic Geometry (in each app's main.cpp):")
    print("   QWindow *window = ...;")
    print("   window->setGeometry(x, y, width, height);")
    print("")
    print("3. IVI-Shell (weston.ini):")
    print("   [ivi-shell]")
    print("   ivi-module=ivi-controller.so")
    print("")
    print("Current Status: Layout defined in run scripts ✅")
    print("Manual control: Not needed (Qt handles automatically)")
    print("════════════════════════════════════════════════════════════")

if __name__ == "__main__":
    print_layout()
