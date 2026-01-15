#!/bin/bash

# ═══════════════════════════════════════════════════════
# LayoutManagerApp Run Script (wayland-0)
# ═══════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Environment variables
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY=wayland-0
export QT_WAYLAND_SHELL_INTEGRATION=xdg-shell
export QT_QUICK_BACKEND=software
export QT_LOGGING_RULES="qt.qpa.*=false"

# Check if executable exists
if [ ! -f "build/LayoutManagerApp" ]; then
    echo "❌ LayoutManagerApp not built! Run ./build.sh first"
    exit 1
fi

echo "========================================="
echo " Starting LayoutManagerApp on wayland-0"
echo "========================================="
echo "Wayland Display: $WAYLAND_DISPLAY"

# Run
exec ./build/LayoutManagerApp
