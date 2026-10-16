#!/bin/bash

# Infrastructure 層啟動腳本
# 用於啟動所有基礎設施服務

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 工作目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 啟動 Infrastructure 基礎設施層...${NC}"
echo "專案目錄: $PROJECT_DIR"

# 檢查 Docker 是否運行
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未運行，請先啟動 Docker${NC}"
    exit 1
fi

# 檢查並建立 devops 網路
echo -e "${YELLOW}🔧 檢查 Docker 網路...${NC}"
if ! docker network inspect devops >/dev/null 2>&1; then
    echo "建立 devops 網路..."
    docker network create devops
    echo -e "${GREEN}✅ devops 網路建立成功${NC}"
else
    echo -e "${GREEN}✅ devops 網路已存在${NC}"
fi

# 檢查 .env 檔案
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  .env 檔案不存在，建立預設 .env 檔案...${NC}"
    cat > "$PROJECT_DIR/.env" << 'EOF'
# Infrastructure 環境變數
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops
BASE_NETWORK_YAML="docker-compose.network.yaml"

# 服務版本
TRAEFIK_VERSION=v3.7
POSTGRES_VERSION=16
REDIS_VERSION=7-alpine
KEYCLOAK_VERSION=26.3.0

# PostgreSQL 設定
POSTGRES_USER=postgres
POSTGRES_DB=postgres
PGADMIN_EMAIL=admin@example.com

# Redis 設定
REDIS_PASSWORD=redis123
REDIS_MAX_MEMORY=256mb

# Keycloak 設定
KEYCLOAK_ADMIN=admin
KEYCLOAK_DB=keycloak
KEYCLOAK_DB_USER=keycloak

# 日誌層級
LOG_LEVEL=INFO
TRAEFIK_API_INSECURE=false
EOF
    echo -e "${GREEN}✅ .env 檔案建立成功${NC}"
fi

# 載入環境變數
set -a; source "$PROJECT_DIR/.env"; set +a

cd "$PROJECT_DIR"

# 階段 1: 網路層 (最重要，必須先啟動)
echo -e "${BLUE}📡 階段 1: 啟動網路層...${NC}"
echo "  - Traefik (反向代理)"
echo "  - CoreDNS (DNS 服務)"
echo "  - Whoami (測試服務)"

docker-compose -f infrastructure/network/docker-compose.yml up -d

# 等待 Traefik 啟動
echo -e "${YELLOW}⏳ 等待 Traefik 啟動...${NC}"
timeout=60
while [ $timeout -gt 0 ]; do
    if docker-compose -f infrastructure/network/docker-compose.yml ps traefik | grep -q "Up"; then
        echo -e "${GREEN}✅ Traefik 已啟動${NC}"
        break
    fi
    sleep 2
    ((timeout-=2))
done

if [ $timeout -le 0 ]; then
    echo -e "${RED}❌ Traefik 啟動超時${NC}"
    exit 1
fi

# 階段 2: 儲存層
echo -e "${BLUE}💾 階段 2: 啟動儲存層...${NC}"
echo "  - PostgreSQL (資料庫)"
echo "  - pgAdmin (資料庫管理)"
echo "  - Redis (快取)"
echo "  - Redis Commander (Redis 管理)"

docker-compose -f infrastructure/storage/docker-compose.yml up -d

# 等待 PostgreSQL 啟動
echo -e "${YELLOW}⏳ 等待 PostgreSQL 啟動...${NC}"
timeout=60
while [ $timeout -gt 0 ]; do
    if docker-compose -f infrastructure/storage/docker-compose.yml ps postgres | grep -q "healthy"; then
        echo -e "${GREEN}✅ PostgreSQL 已啟動並健康${NC}"
        break
    fi
    sleep 2
    ((timeout-=2))
done

# 階段 3: 安全層
echo -e "${BLUE}🔐 階段 3: 啟動安全層...${NC}"
echo "  - Keycloak (身份認證)"

docker-compose -f infrastructure/security/docker-compose.yml up -d

# 顯示服務狀態
echo -e "${BLUE}📊 Infrastructure 服務狀態:${NC}"
echo ""
echo -e "${GREEN}🌐 網路層服務:${NC}"
echo "  • Traefik Dashboard: https://traefik.$MY_DOMAIN"
echo "  • Whoami Test: https://whoami.$MY_DOMAIN"
echo ""
echo -e "${GREEN}💾 儲存層服務:${NC}"
echo "  • PostgreSQL: postgres.$MY_DOMAIN:5432"
echo "  • pgAdmin: https://pgadmin.$MY_DOMAIN"
echo "  • Redis: redis.$MY_DOMAIN:6379"
echo "  • Redis Commander: https://redis-ui.$MY_DOMAIN"
echo ""
echo -e "${GREEN}🔐 安全層服務:${NC}"
echo "  • Keycloak: https://keycloak.$MY_DOMAIN"
echo ""

# 顯示重要資訊
echo -e "${YELLOW}📝 重要資訊:${NC}"
echo "  • 預設域名後綴: $MY_DOMAIN"
echo "  • 網路名稱: $DEFAULT_NETWORK"
echo "  • 密碼檔案位置: infrastructure/*/secrets/"
echo ""
echo -e "${GREEN}🎉 Infrastructure 基礎設施層啟動完成!${NC}"
echo ""
echo -e "${BLUE}下一步:${NC}"
echo "  1. 檢查所有服務是否正常運行: docker-compose -f infrastructure/network/docker-compose.yml ps"
echo "  2. 啟動開發工具層: ./scripts/start-development.sh"
echo "  3. 啟動應用層: ./scripts/start-applications.sh"