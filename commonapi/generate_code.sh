#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "Generating CommonAPI Code from MediaControl.fidl"
echo "════════════════════════════════════════════════════════"

cd "$(dirname "$0")"

FIDL_DIR="fidl"
FDEPL_DIR="fidl"
OUTPUT_CORE="generated/core"
OUTPUT_SOMEIP="generated/someip"

# Clean previous generated code
echo "Cleaning previous generated code..."
rm -rf $OUTPUT_CORE/v1
rm -rf $OUTPUT_SOMEIP/v1

# Create output directories
mkdir -p $OUTPUT_CORE
mkdir -p $OUTPUT_SOMEIP

# Generate Core code
echo ""
echo "Generating Core code..."
/home/seam/DES_Head-Unit/deps/commonapi-generators/commonapi_core/commonapi-core-generator-linux-x86_64 \
    -sk \
    -d $OUTPUT_CORE \
    $FIDL_DIR/MediaControl.fidl

if [ $? -ne 0 ]; then
    echo "❌ Core code generation failed!"
    exit 1
fi

echo "✅ Core code generated in $OUTPUT_CORE"

# Generate SomeIP code
echo ""
echo "Generating SomeIP code..."
/home/seam/DES_Head-Unit/deps/commonapi-generators/commonapi_someip/commonapi-someip-generator-linux-x86_64 \
    -d $OUTPUT_SOMEIP \
    $FDEPL_DIR/MediaControl.fdepl

if [ $? -ne 0 ]; then
    echo "❌ SomeIP code generation failed!"
    exit 1
fi

echo "✅ SomeIP code generated in $OUTPUT_SOMEIP"

echo ""
echo "════════════════════════════════════════════════════════"
echo "Code generation completed successfully!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Generated files:"
ls -lh $OUTPUT_CORE/v1/mediacontrol/
echo ""
ls -lh $OUTPUT_SOMEIP/v1/mediacontrol/
