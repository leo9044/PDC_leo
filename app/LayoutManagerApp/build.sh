#!/bin/bash

# ═══════════════════════════════════════════════════════
# LayoutManagerApp Build Script
# ═══════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo " Building LayoutManagerApp"
echo "========================================="

# Create build directory
mkdir -p build
cd build

# Configure and build
echo "[1/2] Configuring CMake..."
cmake ..

if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed!"
    exit 1
fi

echo "[2/2] Building..."
make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build complete!"
echo "Executable: $SCRIPT_DIR/build/LayoutManagerApp"
