#!/bin/bash
#
# Boost 라이브러리 설치 스크립트
# 라즈베리파이에서 root 권한으로 실행
#

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   Boost 라이브러리 설치                                         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  이 스크립트는 root 권한이 필요합니다."
    echo "   다시 실행: sudo $0"
    exit 1
fi

echo "📦 패키지 캐시 업데이트..."
apt-get update

echo ""
echo "🔧 vsomeip에 필요한 Boost 컴포넌트 설치..."
apt-get install -y \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-log-dev

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Boost 설치 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 다음 단계:"
echo "   sudo ./build_vsomeip_rpi.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
