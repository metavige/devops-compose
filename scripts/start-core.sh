#!/bin/bash

# 啟動核心基礎服務 (Traefik + Registry Mirror)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查網路是否存在
check_network() {
    if ! docker network inspect ${DEFAULT_NETWORK:-devops} &> /dev/null; then
        log_info "建立 Docker 網路..."
        docker network create ${DEFAULT_NETWORK:-devops}
        log_success "Docker 網路已建立"
    fi
}

# 啟動核心服務
start_core() {
    log_info "啟動核心基礎服務..."

    # 載入環境變數
    if [ -f .env ]; then
        source .env
    fi

    check_network

    cd core
    docker compose up -d
    cd ..

    log_success "核心服務啟動完成"

    # 等待服務就緒
    log_info "等待服務初始化..."
    sleep 3

    # 顯示服務狀態
    log_info "服務狀態："
    echo "  • Traefik:  https://traefik.${MY_DOMAIN:-docker.internal}"
    echo "  • Registry: https://registry.${MY_DOMAIN:-docker.internal}"
    echo "  • Whoami:   https://whoami.${MY_DOMAIN:-docker.internal}"
}

main() {
    echo "=== 啟動 DevOps Compose 核心服務 ==="
    start_core
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi