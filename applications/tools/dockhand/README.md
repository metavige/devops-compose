# Dockhand - 現代化 Docker 管理介面

Dockhand 是一個現代化、高效的 Docker 管理應用程式，提供即時容器管理、Compose 堆疊編排和多環境支援。

## 功能特色

- **容器管理**: 即時啟動、停止、重啟和監控容器
- **Compose 堆疊**: Docker Compose 部署的視覺化編輯器
- **Git 整合**: 從 Git 儲存庫部署堆疊，支援 webhooks 和自動同步
- **多環境支援**: 管理本地和遠端 Docker 主機
- **終端和日誌**: 互動式 shell 存取和即時日誌串流
- **檔案瀏覽器**: 瀏覽、上傳和下載容器中的檔案
- **身份驗證**: 支援透過 OIDC 的 SSO、本地使用者和可選的 RBAC（企業版）

## 快速開始

### 啟動服務

```bash
# 使用 Task
task start applications/tools/dockhand

# 使用 Make
make start service=applications/tools/dockhand

# 使用 Docker Compose
docker compose -f applications/tools/dockhand/docker-compose.yml up -d
```

### 存取服務

服務啟動後，可透過以下網址存取：

- **URL**: https://dockhand.docker.internal

## 配置說明

### 環境變數

- `TZ`: 時區設定（預設：`Asia/Taipei`）
- `MY_DOMAIN`: 網域名稱（預設：`docker.internal`）

### Volume 說明

- `/var/run/docker.sock`: Docker socket（唯讀），用於管理 Docker
- `/app/data`: 應用資料持久化儲存

## 技術堆疊

- **前端**: SvelteKit 2、Svelte 5、shadcn-svelte、TailwindCSS
- **後端**: Bun 運行時與 SvelteKit API 路由
- **資料庫**: SQLite 或 PostgreSQL（透過 Drizzle ORM）
- **Docker**: 直接呼叫 Docker API

## 相關連結

- **官方網站**: https://dockhand.pro
- **文件**: https://dockhand.pro/manual
- **GitHub**: https://github.com/Finsys/dockhand
- **Docker Hub**: https://hub.docker.com/r/fnsys/dockhand

## 授權

Dockhand 採用 Business Source License 1.1 (BSL 1.1) 授權。

- **免費使用於**: 個人使用、內部業務使用、非營利組織、教育、評估
- **不允許**: 將 Dockhand 作為商業 SaaS/託管服務提供
- **轉換為 Apache 2.0**: 於 2029 年 1 月 1 日
