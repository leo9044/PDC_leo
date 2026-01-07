#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "Building MediaApp with vSOMEIP Integration"
echo "════════════════════════════════════════════════════════"

cd "$(dirname "$0")"

# Clean build
echo "Cleaning build directory..."
rm -rf build
mkdir -p build
cd build

# CMake
echo "Running CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Debug
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed!"
    exit 1
fi

# Build
echo "Building..."
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "To run MediaApp:"
echo "  cd build && ./run_mediaapp.sh"
echo "════════════════════════════════════════════════════════"
