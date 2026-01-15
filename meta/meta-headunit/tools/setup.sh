#!/bin/bash
# Setup script for meta-headunit layer
# This script validates the build environment and provides helpful information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if we're in the right directory
print_header "meta-headunit Setup Script"

if [ ! -f "conf/layer.conf" ]; then
    print_error "This script must be run from the meta-headunit directory"
    echo "Usage: cd meta-headunit && bash tools/setup.sh"
    exit 1
fi

print_success "meta-headunit directory detected"

# Check build environment variables
print_header "Checking Build Environment"

if [ -z "$BITBAKE_ENV_HASH" ]; then
    print_warning "BitBake environment not detected"
    echo "Please source oe-init-build-env from poky directory:"
    echo "  cd poky"
    echo "  source oe-init-build-env build-headunit"
    exit 1
fi

print_success "BitBake environment loaded"

# Check if bblayers.conf exists
if [ ! -f "$BUILDDIR/conf/bblayers.conf" ]; then
    print_error "bblayers.conf not found in build directory: $BUILDDIR"
    exit 1
fi

print_success "bblayers.conf found in $BUILDDIR"

# Verify meta-headunit is in bblayers.conf
if ! grep -q "meta-headunit" "$BUILDDIR/conf/bblayers.conf"; then
    print_warning "meta-headunit not found in bblayers.conf"
    echo "Add the following to $BUILDDIR/conf/bblayers.conf:"
    echo ""
    echo "BBLAYERS += \" \\"
    echo "    \${TOPDIR}/../meta-headunit \\"
    echo "\""
    echo ""
fi

# Check layer structure
print_header "Verifying Layer Structure"

REQUIRED_DIRS=(
    "conf"
    "classes"
    "recipes-comm"
    "recipes-core"
    "recipes-module"
    "tools"
)

FOUND_COUNT=0
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Found: $dir/"
        ((FOUND_COUNT++))
    else
        print_error "Missing: $dir/"
    fi
done

echo "Directories: $FOUND_COUNT/${#REQUIRED_DIRS[@]} found"

# Check critical files
print_header "Checking Critical Files"

REQUIRED_FILES=(
    "conf/layer.conf"
    "classes/headunit-image.bbclass"
    "recipes-core/images/headunit-image.bb"
    "recipes-comm/vsomeip/vsomeip_3.5.8.bb"
    "recipes-comm/commonapi-core/commonapi-core_3.2.4.bb"
    "recipes-comm/commonapi-someip/commonapi-someip-runtime_3.2.4.bb"
    "recipes-module/hu-mainapp/hu-mainapp_1.0.bb"
    "recipes-module/ic-app/ic-app_1.0.bb"
)

FILE_COUNT=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
        ((FILE_COUNT++))
    else
        print_error "Missing: $file"
    fi
done

echo "Files: $FILE_COUNT/${#REQUIRED_FILES[@]} found"

# Verify layer priority
print_header "Verifying Layer Priority"

PRIORITY=$(grep "BBFILE_PRIORITY_meta-headunit" conf/layer.conf | awk '{print $NF}')

if [ "$PRIORITY" = "15" ]; then
    print_success "Layer priority is correctly set to 15"
else
    print_error "Layer priority is $PRIORITY (should be 15)"
    print_warning "Update conf/layer.conf: BBFILE_PRIORITY_meta-headunit = \"15\""
fi

# Verify recipe organization
print_header "Verifying Recipe Organization"

print_success "recipes-comm/ contains communication middleware:"
ls -1 recipes-comm/*/
echo ""

print_success "recipes-module/ contains applications:"
ls -1 recipes-module/*/
echo ""

print_success "recipes-core/ contains image definitions:"
ls -1 recipes-core/*/
echo ""

# Test BitBake parsing
print_header "Testing BitBake Recipe Parsing"

echo "Attempting to parse recipes..."

if bitbake headunit-image -c listtasks > /dev/null 2>&1; then
    print_success "headunit-image recipe parsed successfully"
else
    print_error "Failed to parse headunit-image recipe"
    echo "Run: bitbake headunit-image -c listtasks"
fi

# Compatibility check
print_header "Checking Yocto Series Compatibility"

COMPAT=$(grep "LAYERSERIES_COMPAT_meta-headunit" conf/layer.conf | sed 's/.*="\(.*\)"/\1/')
echo "Compatible with: $COMPAT"

if [[ "$COMPAT" == *"kirkstone"* ]]; then
    print_success "kirkstone compatibility confirmed"
else
    print_warning "kirkstone not in LAYERSERIES_COMPAT"
fi

# Summary
print_header "Setup Summary"

echo ""
echo "meta-headunit layer is ready for building!"
echo ""
echo "Next steps:"
echo "  1. Ensure all layers are in: $BUILDDIR/conf/bblayers.conf"
echo "  2. Configure machine in: $BUILDDIR/conf/local.conf"
echo "  3. Run build: bitbake headunit-image"
echo ""
echo "For more information, see README.md"
echo ""

# Provide build command suggestion
print_header "Suggested Build Command"

echo ""
echo "  bitbake headunit-image"
echo ""
echo "Expected output location:"
echo "  \$BUILDDIR/tmp/deploy/images/raspberrypi4-64/headunit-image-*.rootfs.*"
echo ""
