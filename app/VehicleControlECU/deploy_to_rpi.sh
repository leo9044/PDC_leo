#!/bin/bash
#
# 개발 PC에서 실행: 라즈베리파이로 파일 전송
# 

set -e

# 라즈베리파이 IP 주소 (수정 필요)
RPI_IP="greywolf1"
RPI_USER="team06"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   VehicleControlECU 배포 스크립트                              ║"
echo "║   개발 PC → Raspberry Pi 파일 전송                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 현재 스크립트 위치 확인
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."

echo "📂 프로젝트 루트: $PROJECT_ROOT"
echo "📂 VehicleControlECU: $SCRIPT_DIR"
echo "🎯 대상 라즈베리파이: $RPI_USER@$RPI_IP"
echo ""

# SSH 연결 테스트 및 디렉토리 생성
echo "🔌 라즈베리파이 연결 테스트..."
if ! ssh -o ConnectTimeout=5 $RPI_USER@$RPI_IP "echo '✅ 연결 성공'" 2>/dev/null; then
    echo "❌ 라즈베리파이에 연결할 수 없습니다!"
    echo "   IP 주소를 확인하세요: $RPI_IP"
    echo "   또는 스크립트 상단의 RPI_IP 변수를 수정하세요."
    exit 1
fi

# 필요한 디렉토리 생성
echo "📁 디렉토리 생성..."
ssh $RPI_USER@$RPI_IP "mkdir -p VehicleControlECU commonapi/generated install_folder"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 파일 전송 시작..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. VehicleControlECU 앱 전송
echo ""
echo "1️⃣  VehicleControlECU 앱 전송..."
rsync -avz --progress --exclude='build*' \
    "$SCRIPT_DIR/" \
    "$RPI_USER@$RPI_IP:VehicleControlECU/"

# 2. CommonAPI 생성 코드 전송
echo ""
echo "2️⃣  CommonAPI 생성 코드 전송..."
rsync -avz --progress \
    "$PROJECT_ROOT/commonapi/generated/" \
    "$RPI_USER@$RPI_IP:commonapi/generated/"

# 3. 라이브러리 전송
echo ""
echo "3️⃣  vsomeip & CommonAPI 라이브러리 전송..."
rsync -avz --progress \
    "$PROJECT_ROOT/install_folder/" \
    "$RPI_USER@$RPI_IP:install_folder/"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 파일 전송 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 다음 단계: 라즈베리파이에서 실행"
echo ""
echo "1. SSH 접속:"
echo "   ssh $RPI_USER@$RPI_IP"
echo ""
echo "2. 의존성 설치:"
echo "   cd ~/VehicleControlECU"
echo "   sudo ./install_dependencies.sh"
echo ""
echo "3. 빌드:"
echo "   ./build.sh"
echo ""
echo "4. 실행:"
echo "   ./run.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
