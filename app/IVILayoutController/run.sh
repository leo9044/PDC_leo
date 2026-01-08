#!/bin/bash

# ════════════════════════════════════════════════════════════
# IVI Layout Controller - Run Script
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXEC_PATH="${SCRIPT_DIR}/build/ivi-layout-controller"

echo "════════════════════════════════════════════════════════════"
echo "Running IVI Layout Controller"
echo "════════════════════════════════════════════════════════════"

# Check if executable exists
if [ ! -f "${EXEC_PATH}" ]; then
    echo "❌ Error: ${EXEC_PATH} not found!"
    echo "   Build first with: ./build.sh"
    exit 1
fi

# Check if Weston is running with IVI-Shell
if ! pgrep -x weston > /dev/null; then
    echo "⚠️  Warning: Weston is not running!"
    echo "   Start Weston first with IVI-Shell enabled"
    exit 1
fi

# Check if IVI-Shell is active (wayland-0 must exist)
if [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ]; then
    echo "❌ Error: wayland-0 socket not found!"
    echo "   Ensure Weston is running with IVI-Shell"
    exit 1
fi

echo "✓ Weston is running"
echo "✓ wayland-0 socket exists"
echo ""
echo "Starting IVI Layout Controller..."
echo "This will manage surface layout for all HU apps"
echo ""

# Run controller
exec "${EXEC_PATH}"
