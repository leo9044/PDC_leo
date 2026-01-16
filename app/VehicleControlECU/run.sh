#!/bin/bash

set -e

# Check for root privileges (required for GPIO access)
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  GPIO 접근을 위해 root 권한이 필요합니다."
    echo "   다시 실행: sudo ./run.sh"
    exit 1
fi

# Check if executable exists
if [ ! -f "build/VehicleControlECU" ]; then
    echo "❌ VehicleControlECU not found!"
    echo "   Build first with: ./build.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Starting VehicleControlECU - DEPLOYMENT MODE"
echo "ECU1 @ 192.168.1.100"
echo "═══════════════════════════════════════════════════════"
echo ""

# Set environment variables for DEPLOYMENT
export VSOMEIP_CONFIGURATION=$(pwd)/config/vsomeip_ecu1.json
export VSOMEIP_APPLICATION_NAME=VehicleControlECU
export COMMONAPI_CONFIG=$(pwd)/config/commonapi_ecu1.ini
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

echo "📋 Configuration:"
echo "   Mode: DEPLOYMENT (Raspberry Pi ECU1)"
echo "   Local IP: 192.168.1.100"
echo "   Role: Service Provider (routing manager)"
echo "   VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG=$COMMONAPI_CONFIG"
echo ""

echo "🔧 Hardware:"
echo "   - PiRacer motor controller"
echo "   - Gamepad input"
echo "   - Battery monitor"
echo ""

echo "Starting service..."
echo "═══════════════════════════════════════════════════════"
echo ""

# Run the application
cd build
exec ./VehicleControlECU
