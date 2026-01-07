#!/bin/bash
#
# VehicleControlECU 배포를 위한 자동 설치 스크립트
# 라즈베리파이에서 실행
#

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   VehicleControlECU 의존성 설치 스크립트                        ║"
echo "║   Raspberry Pi + PiRacer 환경                                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  이 스크립트는 root 권한이 필요합니다."
    echo "   다시 실행: sudo $0"
    exit 1
fi

echo "📦 1/5 시스템 패키지 업데이트..."
apt-get update

echo ""
echo "🔧 2/5 빌드 도구 설치..."
apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config

echo ""
echo "🎨 3/5 Qt5 라이브러리 설치..."
apt-get install -y \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    libqt5core5a \
    libqt5qml5 \
    libqt5quick5 \
    qml-module-qtquick2 \
    qml-module-qtquick-controls2

echo ""
echo "🔌 4/5 PiRacer 하드웨어 라이브러리 설치..."
# I2C 및 하드웨어 인터페이스
apt-get install -y \
    i2c-tools \
    libi2c-dev \
    python3-smbus \
    pigpio \
    libpigpio-dev

# I2C 활성화
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
    echo "   ✅ I2C 활성화됨 (재부팅 필요)"
else
    echo "   ✅ I2C 이미 활성화됨"
fi

echo ""
echo "📚 5/5 vsomeip & CommonAPI 확인..."

# vsomeip & CommonAPI가 이미 설치되어 있는지 확인
if ldconfig -p | grep -q "libvsomeip3.so" && ldconfig -p | grep -q "libCommonAPI.so"; then
    echo "✅ vsomeip & CommonAPI가 이미 설치되어 있습니다."
else
    echo "⚠️  vsomeip & CommonAPI가 설치되어 있지 않습니다!"
    echo ""
    echo "   라즈베리파이에서 직접 빌드해야 합니다:"
    echo "   sudo ./build_vsomeip_rpi.sh"
    echo ""
    echo "   (약 15-20분 소요)"
fi

# 설치 확인
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 설치 완료! 라이브러리 확인:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ldconfig -p | grep -q vsomeip; then
    echo "✅ vsomeip 설치됨:"
    ldconfig -p | grep vsomeip | head -3
else
    echo "⚠️  vsomeip를 찾을 수 없습니다!"
fi

echo ""

if ldconfig -p | grep -q CommonAPI; then
    echo "✅ CommonAPI 설치됨:"
    ldconfig -p | grep CommonAPI | head -3
else
    echo "⚠️  CommonAPI를 찾을 수 없습니다!"
fi

echo ""

if command -v qmake >/dev/null 2>&1; then
    echo "✅ Qt5 설치됨: $(qmake -version | grep Qt)"
else
    echo "⚠️  Qt5를 찾을 수 없습니다!"
fi

echo ""

if command -v i2cdetect >/dev/null 2>&1; then
    echo "✅ I2C 도구 설치됨"
else
    echo "⚠️  I2C 도구를 찾을 수 없습니다!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 다음 단계:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. CommonAPI 생성 코드가 있는지 확인:"
echo "   ls ~/commonapi/generated/"
echo ""
echo "2. VehicleControlECU 빌드:"
echo "   cd ~/VehicleControlECU"
echo "   ./build.sh"
echo ""
echo "3. 실행:"
echo "   ./run.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
