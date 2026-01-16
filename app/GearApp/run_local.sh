#!/bin/bash

set -e

echo "========================================="
echo "  Running GearApp (Local Mode)"
echo "========================================="

# Check if executable exists
if [ ! -f "build/GearApp" ]; then
    echo "❌ GearApp executable not found!"
    echo "   Build it first"
    exit 1
fi

# Set environment variables
export VSOMEIP_CONFIGURATION=$(pwd)/config/vsomeip_ecu2.json
export VSOMEIP_APPLICATION_NAME=GearApp
export COMMONAPI_CONFIG=$(pwd)/config/commonapi_ecu2.ini
export LD_LIBRARY_PATH=/home/seame/HU/chang_new/DES_Head-Unit/install_folder/lib:/usr/local/lib:$LD_LIBRARY_PATH

# Qt environment
export QT_PLUGIN_PATH=/home/seame/Qt/5.15.2/gcc_64/plugins
export QT_QPA_PLATFORM_PLUGIN_PATH=/home/seame/Qt/5.15.2/gcc_64/plugins/platforms
export DISPLAY=${DISPLAY:-:0}

echo "📋 Configuration:"
echo "   VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG=$COMMONAPI_CONFIG"
echo "   LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo ""

echo "⚠️  Note: VehicleControlECU must be running (on Raspberry Pi or mock)"
echo ""
echo "Starting GearApp..."
echo "========================================="
echo ""

# Run the application
cd build
./GearApp
