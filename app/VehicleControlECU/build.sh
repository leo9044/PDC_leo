#!/bin/bash

set -e

echo "========================================="
echo "  VehicleControlECU - DEPLOYMENT BUILD"
echo "  (Raspberry Pi - ECU1 @ 192.168.1.100)"
echo "========================================="
echo ""

# Clean previous build
if [ -d "build" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf build
fi

mkdir -p build
cd build

echo "🔧 Running CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc \
    -DCOMMONAPI_GEN_DIR=$HOME/commonapi/generated

echo ""
echo "🔨 Building..."
make -j$(nproc)

echo ""
echo "========================================="
echo "✅ Build Successful!"
echo "========================================="
echo "Executable: build/VehicleControlECU"
echo ""
echo "To run: ./run.sh"
echo "========================================="
