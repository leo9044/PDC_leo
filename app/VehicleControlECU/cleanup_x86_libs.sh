#!/bin/bash
#
# x86_64 라이브러리 및 CMake 설정 완전 제거 스크립트
# 라즈베리파이에서 root 권한으로 실행
#

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   x86_64 라이브러리 완전 제거                                   ║"
echo "║   (ARM64 재빌드를 위한 정리)                                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Root 권한 확인
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  이 스크립트는 root 권한이 필요합니다."
    echo "   다시 실행: sudo $0"
    exit 1
fi

echo "🧹 1/3 기존 라이브러리 파일 제거..."
rm -f /usr/local/lib/libvsomeip* 2>/dev/null || true
rm -f /usr/local/lib/libCommonAPI* 2>/dev/null || true
echo "   ✅ 라이브러리 파일 제거됨"

echo ""
echo "🧹 2/3 헤더 파일 제거..."
rm -rf /usr/local/include/vsomeip* 2>/dev/null || true
rm -rf /usr/local/include/CommonAPI* 2>/dev/null || true
echo "   ✅ 헤더 파일 제거됨"

echo ""
echo "🧹 3/3 CMake 설정 파일 제거..."
rm -rf /usr/local/lib/cmake/CommonAPI* 2>/dev/null || true
rm -rf /usr/local/lib/cmake/vsomeip* 2>/dev/null || true
rm -rf /usr/local/lib/pkgconfig/vsomeip* 2>/dev/null || true
rm -rf /usr/local/lib/pkgconfig/CommonAPI* 2>/dev/null || true
echo "   ✅ CMake 설정 제거됨"

echo ""
echo "🔄 라이브러리 캐시 업데이트..."
ldconfig

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 정리 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 다음 단계:"
echo "   1. Boost 설치 (아직 안했다면):"
echo "      sudo apt-get install -y libboost-all-dev"
echo ""
echo "   2. ARM64 빌드 실행:"
echo "      sudo ./build_vsomeip_rpi.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
