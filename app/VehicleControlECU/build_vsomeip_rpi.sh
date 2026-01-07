#!/bin/bash
#
# 라즈베리파이에서 vsomeip & CommonAPI 빌드
# ARM64 아키텍처용
#

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   vsomeip & CommonAPI 빌드 스크립트                           ║"
echo "║   Raspberry Pi ARM64 아키텍처용                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  이 스크립트는 root 권한이 필요합니다."
    echo "   다시 실행: sudo $0"
    exit 1
fi

INSTALL_PREFIX="/usr/local"
BUILD_DIR="$HOME/vsomeip_build"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1/4 필수 의존성 설치..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get update
apt-get install -y \
    build-essential \
    cmake \
    git \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-log-dev \
    asciidoc \
    source-highlight \
    doxygen \
    graphviz

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2/4 vsomeip 빌드 (약 10-15분 소요)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "vsomeip" ]; then
    git clone https://github.com/COVESA/vsomeip.git
fi

cd vsomeip
git checkout 3.5.8  # 개발 PC와 동일한 버전

mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SIGNAL_HANDLING=1 \
    -DBUILD_EXAMPLES=ON

make -j$(nproc)
make install
ldconfig

echo "✅ vsomeip 설치 완료"

cd $BUILD_DIR

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3/4 CommonAPI Core 빌드..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "capicxx-core-runtime" ]; then
    git clone https://github.com/COVESA/capicxx-core-runtime.git
fi

cd capicxx-core-runtime
git checkout 3.2.4  # 개발 PC와 동일한 버전

mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
make install
ldconfig

echo "✅ CommonAPI Core 설치 완료"

cd $BUILD_DIR

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4/4 CommonAPI SomeIP 빌드..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "capicxx-someip-runtime" ]; then
    git clone https://github.com/COVESA/capicxx-someip-runtime.git
fi

cd capicxx-someip-runtime
git checkout 3.2.4  # 개발 PC와 동일한 버전

mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
make install
ldconfig

echo "✅ CommonAPI SomeIP 설치 완료"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 모든 라이브러리 빌드 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "설치 확인:"
ldconfig -p | grep vsomeip
ldconfig -p | grep CommonAPI

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 다음 단계:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. VehicleControlECU 빌드:"
echo "   cd ~/VehicleControlECU"
echo "   ./build.sh"
echo ""
echo "2. 실행:"
echo "   ./run.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"