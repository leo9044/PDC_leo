#!/bin/bash

# ════════════════════════════════════════════════════════════
# Stop Script for Single Weston Architecture
# ════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════"
echo "Stopping All HU Apps (Single Weston Architecture)"
echo "════════════════════════════════════════════════════════════"

# Stop all HU apps
echo "Stopping applications..."
killall -9 GearApp MediaApp AmbientApp HomeScreenApp 2>/dev/null

# Stop HU_MainApp_Compositor (if still running from old architecture)
killall -9 HU_MainApp_Compositor 2>/dev/null

# Clean up vsomeip
echo "Cleaning vsomeip resources..."
pkill -9 -f vsomeip 2>/dev/null
rm -rf /tmp/vsomeip-* 2>/dev/null

sleep 1

echo ""
echo "✅ All apps stopped"
echo ""
echo "Note: Weston is still running. To stop Weston:"
echo "  killall -9 weston"
echo "════════════════════════════════════════════════════════════"
