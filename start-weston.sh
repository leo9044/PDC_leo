#!/bin/bash

# ════════════════════════════════════════════════════════
# NVIDIA Jetson Weston 실행 스크립트
# 공식 문서: https://docs.nvidia.com/jetson/archives/r35.5.0/DeveloperGuide/SD/WindowingSystems/WestonWayland.html
# ════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════"
echo "Starting Weston on NVIDIA Jetson Orin Nano"
echo "════════════════════════════════════════════════════════"

# XDG_RUNTIME_DIR 설정 (필수)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo ""

# Weston 설정 파일 생성
WESTON_INI="$HOME/.config/weston.ini"
mkdir -p $(dirname $WESTON_INI)

cat > $WESTON_INI << 'EOF'
[core]
backend=drm-backend.so
require-input=false

[shell]
background-image=/usr/share/backgrounds/warty-final-ubuntu.png
background-type=scale-crop
panel-position=none
locking=false

[output]
name=HDMI-A-1
mode=1920x1080
transform=normal

[keyboard]
keymap_layout=us

[terminal]
font=monospace
font-size=14
EOF

echo "✅ Weston config created: $WESTON_INI"
echo ""

# 기존 Weston 종료
killall -9 weston 2>/dev/null
sleep 1

echo "🚀 Starting Weston (DRM backend)..."
echo "   Press Ctrl+Alt+Backspace to exit Weston"
echo ""

# Weston 실행
weston --backend=drm-backend.so --log=/tmp/weston.log 2>&1
