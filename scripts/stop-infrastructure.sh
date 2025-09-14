#!/bin/bash

# Infrastructure 層停止腳本

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 工作目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🛑 停止 Infrastructure 基礎設施層...${NC}"

cd "$PROJECT_DIR"

# 反向順序停止服務
echo -e "${YELLOW}🔐 停止安全層...${NC}"
docker-compose -f infrastructure/security/docker-compose.yml down

echo -e "${YELLOW}💾 停止儲存層...${NC}"
docker-compose -f infrastructure/storage/docker-compose.yml down

echo -e "${YELLOW}📡 停止網路層...${NC}"
docker-compose -f infrastructure/network/docker-compose.yml down

echo -e "${GREEN}✅ Infrastructure 基礎設施層已停止${NC}"