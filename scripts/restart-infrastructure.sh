#!/bin/bash

# Infrastructure 層重啟腳本

set -e

# 顏色定義
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# 工作目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🔄 重啟 Infrastructure 基礎設施層...${NC}"

# 停止服務
"$SCRIPT_DIR/stop-infrastructure.sh"

# 等待一下
sleep 3

# 啟動服務
"$SCRIPT_DIR/start-infrastructure.sh"

echo -e "${GREEN}✅ Infrastructure 基礎設施層重啟完成${NC}"