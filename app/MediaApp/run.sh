#!/bin/bash

# ════════════════════════════════════════════════════════════
# MediaApp 실행 스크립트 (ECU2 - 라즈베리파이)
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="MediaApp"

# 환경변수 설정
export VSOMEIP_APPLICATION_NAME="${APP_NAME}"
export VSOMEIP_CONFIGURATION="${SCRIPT_DIR}/vsomeip.json"
export COMMONAPI_CONFIG="${SCRIPT_DIR}/commonapi.ini"

# 라이브러리 경로 설정 (환경변수 우선, 없으면 기본값)
if [ -z "$DEPLOY_PREFIX" ]; then
    export DEPLOY_PREFIX="${HOME}/DES_Head-Unit/install_folder"
fi

export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"

echo "════════════════════════════════════════════════════════════"
echo "Running ${APP_NAME}"
echo "════════════════════════════════════════════════════════════"
echo "VSOMEIP_CONFIGURATION: ${VSOMEIP_CONFIGURATION}"
echo "COMMONAPI_CONFIG: ${COMMONAPI_CONFIG}"
echo "DEPLOY_PREFIX: ${DEPLOY_PREFIX}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
echo "════════════════════════════════════════════════════════════"

# 실행 파일 경로
if [ -f "${SCRIPT_DIR}/build/${APP_NAME}" ]; then
    EXEC_PATH="${SCRIPT_DIR}/build/${APP_NAME}"
elif [ -f "${SCRIPT_DIR}/${APP_NAME}" ]; then
    EXEC_PATH="${SCRIPT_DIR}/${APP_NAME}"
else
    echo "❌ Error: ${APP_NAME} executable not found!"
    echo "   Searched in:"
    echo "   - ${SCRIPT_DIR}/build/${APP_NAME}"
    echo "   - ${SCRIPT_DIR}/${APP_NAME}"
    exit 1
fi

echo "Executable: ${EXEC_PATH}"
echo ""

# 실행
exec "${EXEC_PATH}"
