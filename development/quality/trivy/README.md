# Trivy - 容器安全掃描工具

Trivy 是一個全面且易於使用的容器安全掃描工具，可以檢測容器映像、檔案系統和 Git 儲存庫中的漏洞。

## 功能特色

- 🔍 **漏洞掃描** - 掃描 OS 套件和應用程式依賴
- 🔐 **秘密檢測** - 查找 API 金鑰、密碼等敏感資訊
- ⚙️ **錯誤配置檢測** - 掃描 IaC 配置檔案（Dockerfile、Kubernetes 等）
- 📦 **多種掃描目標** - 支援容器映像、檔案系統、Git 儲存庫
- 🚀 **Server 模式** - 提供 REST API 整合

## 快速開始

### 啟動服務

```bash
# 使用 Make
make start service=development/quality/trivy

# 使用 Task
task start:trivy

# 直接使用 Docker Compose
cd development/quality/trivy
docker compose up -d
```

### 存取服務

- **Trivy API**: https://trivy.docker.internal

## 使用方式

### 1. 使用 API 掃描映像

Trivy Server 提供 HTTP API，可由 `curl` 或其他 HTTP 客戶端呼叫。不過實際可用的端點與請求格式會隨 Trivy 版本與部署方式而異，且官方並不保證未公開的端點（例如 `/scan`）的穩定性。

因此，請依照你所使用的 Trivy 版本，參考官方文件中的「Server mode / HTTP API」章節取得正確的 API path 與參數，再撰寫對應的 `curl` 請求。
### 2. 使用 CLI 客戶端連接 Server

```bash
# 安裝 Trivy CLI（如果尚未安裝）
brew install aquasecurity/trivy/trivy

# 使用 client 模式連接到 server（使用本地端點）
trivy image --server http://localhost:8080 nginx:latest

# 掃描本地映像
trivy image --server http://localhost:8080 myapp:1.0.0

# 掃描並輸出 JSON 格式
trivy image --server http://localhost:8080 \
  --format json \
  --output result.json \
  nginx:latest

# 只顯示嚴重和高危漏洞
trivy image --server http://localhost:8080 \
  --severity CRITICAL,HIGH \
  nginx:latest
```

### 3. 掃描檔案系統

```bash
# 掃描專案目錄
trivy fs --server http://localhost:8080 /path/to/project

# 掃描 IaC 配置
trivy config --server http://localhost:8080 /path/to/kubernetes
```

### 4. 掃描 Git 儲存庫

```bash
# 掃描遠端儲存庫
trivy repo --server http://localhost:8080 https://github.com/user/repo

# 掃描本地儲存庫
trivy repo --server http://localhost:8080 /path/to/repo
```

## 整合範例

### CI/CD Pipeline 整合

```yaml
# GitLab CI 範例
# 注意：在 CI/CD 環境中，使用服務名稱（http://trivy:8080）而非 localhost
# 確保 Trivy 服務與 CI runner 在同一 Docker 網路中
security_scan:
  stage: test
  image: aquasec/trivy:latest
  script:
    - trivy image --server http://trivy:8080 --exit-code 1 --severity CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - merge_requests
    - main
```

### Docker Build 整合

```bash
# 建置映像後立即掃描
docker build -t myapp:latest .
trivy image --server http://localhost:8080 myapp:latest
```

## 設定說明

### 環境變數

- `TRIVY_LISTEN` - Server 監聽位址（預設：0.0.0.0:8080）
- `TRIVY_DEBUG` - 啟用除錯模式（預設：false）
- `TZ` - 時區設定

### 資料持久化

漏洞資料庫和快取儲存在 `./cache` 目錄中，確保：
- 資料庫更新後仍然保留
- 加速後續掃描速度

## 管理指令

```bash
# 查看服務狀態
make status service=development/quality/trivy

# 查看日誌
make logs service=development/quality/trivy

# 重啟服務
make restart service=development/quality/trivy

# 停止服務
make stop service=development/quality/trivy
```

## 資料目錄

```
trivy/
├── docker-compose.yml  # Docker Compose 配置
├── cache/             # 漏洞資料庫快取（自動建立）
└── README.md          # 本說明文件
```

## 注意事項

1. **首次啟動** - 第一次啟動時會下載漏洞資料庫，可能需要幾分鐘
2. **資料庫更新** - 漏洞資料庫會定期自動更新
3. **Docker Socket** - 預設未掛載 Docker socket，如需掃描本地容器映像請手動啟用 docker-compose.yml 中的對應設定
4. **網路存取** - 需要網路連線以下載和更新漏洞資料庫
5. **服務端點選擇**：
   - 從主機使用 CLI：`http://localhost:8080`
   - 從同一 Docker 網路內的容器：`http://trivy:8080`
   - 透過 Traefik 的 HTTPS 存取（REST API）：`https://trivy.docker.internal`

## 相關連結

- [Trivy 官方文件](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [漏洞資料庫來源](https://github.com/aquasecurity/trivy-db)

## 故障排除

### 問題：服務無法啟動

```bash
# 檢查 Docker 網路
docker network ls | grep devops

# 檢查埠號是否被佔用
lsof -i :8080
```

### 問題：掃描速度慢

```bash
# 手動更新資料庫
docker exec trivy trivy image --download-db-only

# 清除快取重新開始
rm -rf cache/*
docker compose restart
```

### 問題：無法連接 Server

```bash
# 確認服務運行中
docker ps | grep trivy

# 檢查日誌
docker compose logs trivy
```
