#!/bin/bash

# Stop all Head Unit applications on x86-64
# This script terminates all running Head Unit processes

echo "════════════════════════════════════════════════════════"
echo "Stopping Head Unit System on x86-64"
echo "════════════════════════════════════════════════════════"
echo ""

# Function to kill process if it exists
kill_process() {
    local process_name=$1
    if pgrep -x "$process_name" > /dev/null; then
        echo "Stopping $process_name..."
        pkill -9 "$process_name"
        sleep 0.5
        if pgrep -x "$process_name" > /dev/null; then
            echo "  ⚠️  $process_name still running, force killing..."
            pkill -9 -f "$process_name"
        else
            echo "  ✅ $process_name stopped"
        fi
    else
        echo "  ℹ️  $process_name not running"
    fi
}

# Stop all applications in reverse order
kill_process "HomeScreenApp"
kill_process "AmbientApp"
kill_process "MediaApp"
kill_process "GearApp"
kill_process "HU_MainApp_Compositor"
kill_process "VehicleControlMock"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ All Head Unit processes stopped"
echo "════════════════════════════════════════════════════════"

# Verify all processes are stopped
echo ""
echo "Verification:"
remaining=$(pgrep -f "VehicleControlMock|HU_MainApp_Compositor|GearApp|MediaApp|AmbientApp|HomeScreenApp" | wc -l)
if [ "$remaining" -eq 0 ]; then
    echo "  ✅ All processes successfully terminated"
else
    echo "  ⚠️  Warning: $remaining process(es) still running"
    echo ""
    echo "Remaining processes:"
    ps aux | grep -E "VehicleControlMock|HU_MainApp_Compositor|GearApp|MediaApp|AmbientApp|HomeScreenApp" | grep -v grep
fi
