#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "Building IC_app with vSOMEIP Integration"
echo "════════════════════════════════════════════════════════"

# 환경변수 DEPLOY_PREFIX 설정 (없으면 기본값)
if [ -z "$DEPLOY_PREFIX" ]; then
    export DEPLOY_PREFIX="${HOME}/DES_Head-Unit/install_folder"
fi

echo "DEPLOY_PREFIX: ${DEPLOY_PREFIX}"
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
echo "To run IC_app:"
echo "  ./run.sh"
echo "════════════════════════════════════════════════════════"
