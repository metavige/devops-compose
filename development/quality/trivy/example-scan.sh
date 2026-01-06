#!/bin/bash
#
# Trivy 使用範例腳本
# 這個腳本展示如何使用 Trivy 掃描容器映像
#

set -e

echo "📋 Trivy 掃描範例"
echo "=================="
echo ""

# 確認 Trivy CLI 是否已安裝
if ! command -v trivy &> /dev/null; then
    echo "⚠️  Trivy CLI 未安裝"
    echo ""
    echo "安裝方式："
    echo "  macOS:   brew install aquasecurity/trivy/trivy"
    echo "  Linux:   請參考 https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    echo ""
    exit 1
fi

# 確認 Trivy server 是否運行中
if ! docker ps | grep -q trivy; then
    echo "❌ Trivy server 未運行"
    echo "請先啟動服務："
    echo "  task start:trivy"
    echo "  或"
    echo "  make start service=development/quality/trivy"
    exit 1
fi

echo "✅ Trivy CLI 和 server 都已就緒"
echo ""

# 範例 1: 掃描公開映像
echo "📦 範例 1: 掃描 nginx:latest 映像"
echo "指令: trivy image --server http://localhost:8080 nginx:latest"
echo ""
trivy image --server http://localhost:8080 nginx:latest

echo ""
echo "---"
echo ""

# 範例 2: 只顯示嚴重和高危漏洞
echo "🔴 範例 2: 只顯示 CRITICAL 和 HIGH 級別的漏洞"
echo "指令: trivy image --server http://localhost:8080 --severity CRITICAL,HIGH nginx:latest"
echo ""
trivy image --server http://localhost:8080 --severity CRITICAL,HIGH nginx:latest

echo ""
echo "---"
echo ""

# 範例 3: 輸出為 JSON 格式
echo "📄 範例 3: 輸出為 JSON 格式"
echo "指令: trivy image --server http://localhost:8080 --format json nginx:latest"
echo ""
trivy image --server http://localhost:8080 --format json --quiet nginx:latest | jq '.Results[0].Vulnerabilities | length' | xargs -I {} echo "找到 {} 個漏洞"

echo ""
echo "✅ 掃描完成！"
echo ""
echo "💡 更多使用方式請參考 README.md"
