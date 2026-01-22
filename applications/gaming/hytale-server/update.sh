#!/bin/bash
# Hytale Server 更新腳本

set -e

echo "===================================="
echo "  Hytale Server 更新工具"
echo "===================================="
echo ""

# 檢查是否需要停止伺服器
if docker compose ps | grep -q "hytale-server.*Up"; then
    echo "⚠️  偵測到伺服器正在運行"
    read -p "是否要停止伺服器進行更新? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "正在停止伺服器..."
        docker compose down
    else
        echo "取消更新。請先手動停止伺服器。"
        exit 1
    fi
fi

echo "開始下載/更新伺服器檔案..."
echo ""

# 執行更新
docker compose -f docker-compose.update.yml run --rm hytale-updater

echo ""
echo "===================================="
echo "  更新完成！"
echo "===================================="
echo ""
echo "使用以下指令啟動伺服器:"
echo "  docker compose up -d"
echo ""
