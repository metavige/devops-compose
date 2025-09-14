#!/bin/bash

# 停止核心基礎服務

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

stop_core() {
    log_info "停止核心基礎服務..."

    cd core
    docker compose down
    cd ..

    log_success "核心服務已停止"
}

main() {
    echo "=== 停止 DevOps Compose 核心服務 ==="
    stop_core
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi