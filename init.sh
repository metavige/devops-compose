#!/bin/bash

# DevOps Compose 初始化腳本
# 自動設定環境並啟動核心基礎服務

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查必要條件
check_prerequisites() {
    log_info "檢查必要條件..."

    # 檢查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安裝"
        exit 1
    fi

    # 檢查 Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安裝或版本過舊"
        exit 1
    fi

    log_success "必要條件檢查通過"
}

# 建立環境變數檔案
setup_env() {
    log_info "設定環境變數..."

    if [ ! -f .env ]; then
        log_info "建立 .env 檔案..."
        cat > .env << EOF
# DevOps Compose 環境變數
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops
TRAEFIK_VERSION=v3.7

# 時區設定
TZ=Asia/Taipei

# Docker Registry Mirror
REGISTRY_MIRROR=https://registry.docker.internal
EOF
        log_success ".env 檔案已建立"
    else
        log_info ".env 檔案已存在，跳過建立"
    fi

    # 載入環境變數
    set -a; source .env; set +a
}

# 建立 Docker 網路
setup_network() {
    log_info "設定 Docker 網路..."

    if ! docker network inspect ${DEFAULT_NETWORK:-devops} &> /dev/null; then
        docker network create ${DEFAULT_NETWORK:-devops}
        log_success "Docker 網路 '${DEFAULT_NETWORK:-devops}' 已建立"
    else
        log_info "Docker 網路 '${DEFAULT_NETWORK:-devops}' 已存在"
    fi
}

# 建立必要目錄
setup_directories() {
    log_info "建立必要目錄..."

    # 建立資料目錄
    mkdir -p infrastructure/network/traefik/{certs,conf,logs}
    mkdir -p infrastructure/docker/registry/{data,certs}

    # 建立憑證（如果不存在）
    local cert_dir="infrastructure/network/traefik/certs"
    if [ ! -f "$cert_dir/traefik.crt" ] && [ ! -f "$cert_dir/local-cert.pem" ]; then
        if command -v mkcert &> /dev/null; then
            log_info "使用 mkcert 建立憑證..."
            cd "$cert_dir"
            # 檢查 mkcert 是否已初始化
            if ! mkcert -CAROOT &> /dev/null; then
                log_info "初始化 mkcert..."
                mkcert -install
            fi
            # 生成憑證 (向後相容，使用舊的命名)
            mkcert -cert-file traefik.crt -key-file traefik.key "*.docker.internal" "docker.internal" localhost 127.0.0.1
            cd - > /dev/null
            log_success "mkcert 憑證已建立"
        else
            log_warning "mkcert 未安裝，使用 openssl 建立自簽憑證..."
            log_info "建議安裝 mkcert: brew install mkcert"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$cert_dir/traefik.key" \
                -out "$cert_dir/traefik.crt" \
                -subj "/C=TW/ST=Taiwan/L=Taipei/O=DevOps/OU=IT/CN=*.docker.internal" \
                -addext "subjectAltName=DNS:*.docker.internal,DNS:docker.internal"
            log_success "openssl 自簽憑證已建立"
        fi
    else
        log_info "憑證檔案已存在，跳過建立"
    fi

    log_success "目錄結構已建立"
}

# 設定本機 DNS resolver，讓 *.$MY_DOMAIN 交給 CoreDNS (127.0.0.1:10053) 解析
setup_dns() {
    log_info "設定本機 DNS resolver..."

    local domain="${MY_DOMAIN:-docker.internal}"

    if [ "$(uname)" != "Darwin" ]; then
        log_warning "非 macOS：請手動把 *.${domain} 指向 127.0.0.1:10053 (Linux 可用 systemd-resolved)"
        return 0
    fi

    local resolver_file="/etc/resolver/${domain}"
    local expected
    expected="$(printf 'nameserver 127.0.0.1\nport 10053')"
    if [ -f "$resolver_file" ] && [ "$(cat "$resolver_file")" = "$expected" ]; then
        log_info "resolver 設定已存在，跳過"
        return 0
    fi

    log_info "寫入 ${resolver_file} (需要 sudo)"
    sudo mkdir -p /etc/resolver
    printf 'nameserver 127.0.0.1\nport 10053\n' | sudo tee "$resolver_file" > /dev/null
    log_success "resolver 設定完成"
}

# 啟動核心服務
start_core_services() {
    log_info "啟動核心基礎服務..."

    cd core
    docker compose up -d
    cd ..

    log_success "核心服務啟動完成"
    log_info "等待服務初始化..."
    sleep 5
}

# 驗證服務狀態
verify_services() {
    log_info "驗證服務狀態..."

    # 檢查 DNS（走系統 resolver，dig 不會經過 /etc/resolver）
    if dscacheutil -q host -a name "traefik.${MY_DOMAIN:-docker.internal}" 2>/dev/null | grep -q '127.0.0.1'; then
        log_success "✓ DNS: *.${MY_DOMAIN:-docker.internal} → 127.0.0.1"
    else
        log_warning "⚠ DNS 尚未解析，檢查 /etc/resolver/${MY_DOMAIN:-docker.internal} 與 coredns 容器"
    fi

    # 檢查 Traefik
    if curl -sf https://traefik.docker.internal/api/version > /dev/null 2>&1; then
        log_success "✓ Traefik Dashboard: https://traefik.docker.internal"
    else
        log_warning "⚠ Traefik 可能尚未就緒"
    fi

    # 檢查 Registry
    if curl -sf https://registry.docker.internal/v2/ > /dev/null 2>&1; then
        log_success "✓ Registry Mirror: https://registry.docker.internal"
    else
        log_warning "⚠ Registry Mirror 可能尚未就緒"
    fi

    # 檢查 Whoami
    if curl -sf https://whoami.docker.internal > /dev/null 2>&1; then
        log_success "✓ Test Service: https://whoami.docker.internal"
    else
        log_warning "⚠ Test Service 可能尚未就緒"
    fi
}

# 設定 Docker Registry Mirror
setup_docker_daemon() {
    log_info "配置 Docker Daemon Registry Mirror..."

    # 建議設定內容
    cat > /tmp/daemon.json << EOF
{
  "registry-mirrors": [
    "https://registry.docker.internal"
  ],
  "insecure-registries": [
    "registry.docker.internal"
  ]
}
EOF

    log_warning "請根據你的 Docker 環境手動設定 Registry Mirror："
    echo
    log_info "🐳 Docker Desktop (macOS/Windows):"
    echo "  Docker Desktop → Settings → Docker Engine → 將以下內容加入設定"
    echo
    log_info "🚀 OrbStack (macOS):"
    echo "  OrbStack → Settings → Docker → Engine → 將以下內容加入設定"
    echo "  或編輯: ~/.orbstack/config/docker.json"
    echo
    log_info "🐧 Linux:"
    echo "  編輯: /etc/docker/daemon.json"
    echo
    log_info "📋 設定內容："
    cat /tmp/daemon.json
    echo
    log_info "⚠️  設定完成後請重啟 Docker/OrbStack"

    rm /tmp/daemon.json
}

# 顯示使用說明
show_usage() {
    log_success "=== DevOps Compose 初始化完成 ==="
    echo
    log_info "可用服務："
    echo "  • Traefik Dashboard: https://traefik.docker.internal"
    echo "  • Registry Mirror:   https://registry.docker.internal"
    echo "  • Test Service:      https://whoami.docker.internal"
    echo
    log_info "常用指令："
    echo "  • 啟動核心服務: ./scripts/start-core.sh"
    echo "  • 停止核心服務: ./scripts/stop-core.sh"
    echo "  • 啟動其他服務: make start service=<service>"
    echo "  • 或使用 Task:   task start:<service>"
    echo
    log_info "下一步："
    echo "  1. 確認服務運作正常"
    echo "  2. 配置 Docker Registry Mirror (如需要)"
    echo "  3. 啟動所需的其他服務"
}

# 主程序
main() {
    log_info "開始初始化 DevOps Compose 環境..."
    echo

    check_prerequisites
    setup_env
    setup_network
    setup_directories
    setup_dns
    start_core_services
    verify_services
    setup_docker_daemon
    show_usage

    echo
    log_success "初始化完成！"
}

# 如果是直接執行腳本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi