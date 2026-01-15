#!/bin/bash

# ════════════════════════════════════════════════════════════
# Rebuild All Apps for Single Weston Architecture
# ════════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "Rebuilding All Apps for Single Weston (wayland-0)"
echo "════════════════════════════════════════════════════════════"
echo "Project Root: ${PROJECT_ROOT}"
echo ""

APPS=("GearApp" "MediaApp" "AmbientApp" "HomeScreenApp")
SUCCESS_COUNT=0
FAIL_COUNT=0

for APP in "${APPS[@]}"; do
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "Building ${APP}..."
    echo "════════════════════════════════════════════════════════════"
    
    cd "${PROJECT_ROOT}/app/${APP}"
    
    if [ ! -f "./build.sh" ]; then
        echo "❌ build.sh not found for ${APP}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    if ./build.sh; then
        echo "✅ ${APP} build successful"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ ${APP} build failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Build Summary"
echo "════════════════════════════════════════════════════════════"
echo "✅ Successful: ${SUCCESS_COUNT}"
echo "❌ Failed: ${FAIL_COUNT}"
echo ""

if [ ${FAIL_COUNT} -eq 0 ]; then
    echo "🎉 All apps built successfully!"
    echo ""
    echo "To run the system:"
    echo "  cd ${PROJECT_ROOT}"
    echo "  ./stop-jetson-single-weston.sh"
    echo "  ./run-jetson-single-weston.sh"
else
    echo "⚠️  Some apps failed to build. Please check the errors above."
    exit 1
fi
