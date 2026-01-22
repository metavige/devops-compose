# Hytale Server - Docker Compose

使用 Docker Compose 部署 Hytale 專屬伺服器的完整解決方案。

## 📋 目錄

- [簡介](#簡介)
- [系統需求](#系統需求)
- [快速開始](#快速開始)
- [環境變數設定](#環境變數設定)
- [首次啟動認證](#首次啟動認證)
- [進階設定](#進階設定)
- [目錄結構](#目錄結構)
- [常見問題](#常見問題)
- [參考資源](#參考資源)

## 📖 簡介

本專案提供完整的 Docker 化 Hytale 專屬伺服器部署方案，基於 [indifferentbroccoli/hytale-server-docker](https://github.com/indifferentbroccoli/hytale-server-docker) 專案進行改良和在地化。

### 主要特色

- 🚀 自動下載和更新伺服器檔案
- 🔐 支援認證模式和離線模式
- 💾 自動備份功能
- 🎮 完整的遊戲模組支援
- 📊 健康檢查和資源監控
- 🔧 彈性的環境變數設定
- 📦 統一的資料目錄管理

### 資料管理優勢

本專案將所有伺服器資料統一存放在 `hytale-data/` 目錄中，帶來以下優勢：

- ✅ **集中管理**: 所有資料在同一位置，易於查找和管理
- ✅ **簡化備份**: 只需備份單一目錄即可保存所有重要資料
- ✅ **版本控制友善**: 透過 `.gitignore` 排除運行時資料，保持專案目錄整潔
- ✅ **遷移便利**: 搬移或復原伺服器時，只需複製 `hytale-data/` 目錄

## 💻 系統需求

| 資源 | 最低需求 | 建議配置 |
|------|---------|---------|
| CPU | 4 核心 | 8+ 核心 |
| 記憶體 | 4GB | 8GB+ |
| 硬碟空間 | 10GB | 20GB+ |
| 網路 | UDP 5520 埠 | - |

### 環境需求

- Docker Engine 20.10+
- Docker Compose 2.0+
- Java 25 (容器內已包含)

## 🚀 快速開始

### 1. 複製環境變數範本

```bash
cp .env.example .env
```

### 2. 編輯環境變數

根據您的需求修改 `.env` 檔案中的設定：

```bash
# 基本設定
SERVER_NAME=my-hytale-server
MAX_PLAYERS=30
MAX_MEMORY=16G
```

### 3. 建置並啟動服務

```bash
# 建置映像檔
docker compose build

# 啟動服務
docker compose up -d

# 查看日誌
docker compose logs -f hytale-server
```

### 4. 停止服務

```bash
docker compose down
```

## ⚙️ 環境變數設定

### 基本設定

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `SERVER_NAME` | hytale-server | 伺服器名稱 |
| `HYTALE_PORT` | 5520 | 對外埠號 (UDP) |
| `MAX_PLAYERS` | 20 | 最大玩家數 |
| `VIEW_DISTANCE` | 12 | 視距 (chunks) |
| `MAX_MEMORY` | 8G | Java 最大記憶體 |

### 認證設定

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `AUTH_MODE` | authenticated | 認證模式 (authenticated/offline) |
| `SESSION_TOKEN` | - | OAuth 工作階段 Token |
| `IDENTITY_TOKEN` | - | 身份驗證 Token |
| `OWNER_UUID` | - | 伺服器擁有者 UUID |

### 進階設定

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `ENABLE_BACKUPS` | false | 啟用自動備份 |
| `BACKUP_FREQUENCY` | 30 | 備份頻率 (分鐘) |
| `DISABLE_SENTRY` | true | 停用錯誤回報 |
| `USE_AOT_CACHE` | true | 使用 AOT 快取 |
| `ACCEPT_EARLY_PLUGINS` | false | 接受 Beta 插件 |
| `DOWNLOAD_ON_START` | true | 啟動時自動下載 |

## 🔐 首次啟動認證

首次啟動伺服器時，如果未設定認證 Token，您需要透過瀏覽器進行 OAuth 認證：

1. 啟動服務後，查看容器日誌：
   ```bash
   docker compose logs -f hytale-server
   ```

2. 在日誌中找到類似以下的 OAuth URL：
   ```
   請在瀏覽器中開啟此 URL 進行認證:
   https://account.hytale.com/oauth/authorize?...
   ```

3. 在瀏覽器中開啟該 URL 並使用您的 Hytale 帳號登入

4. 完成認證後，伺服器將自動繼續啟動流程

### 持久化認證

認證資訊會儲存在 `hytale-data/machine-id/` 目錄中，重新啟動容器時會自動載入。

## 🔧 進階設定

### 自訂 Java 參數

編輯 `scripts/start.sh` 檔案中的 `JAVA_OPTS` 變數：

```bash
JAVA_OPTS="-Xmx${MAX_MEMORY} -Xms${MAX_MEMORY}"
JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"
# 加入更多自訂參數...
```

### 安裝模組 (Mods)

1. 將模組檔案放入 `hytale-data/server-files/mods/` 目錄
2. 重新啟動服務：
   ```bash
   docker compose restart
   ```

**提示**: 首次啟動後，`hytale-data/` 目錄會自動建立。

### 備份管理

啟用自動備份：

```bash
# 在 .env 檔案中設定
ENABLE_BACKUPS=true
BACKUP_FREQUENCY=30  # 每 30 分鐘備份一次
```

備份檔案會儲存在 `hytale-data/backups/` 目錄中。

### 資源限制

在 `docker-compose.yml` 中調整資源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 10G
    reservations:
      cpus: '4'
      memory: 4G
```

## 📁 目錄結構

```
hytale-server/
├── docker-compose.yml      # Docker Compose 設定
├── Dockerfile              # Docker 映像檔定義
├── .env.example           # 環境變數範本
├── .env                   # 環境變數設定 (需自行建立)
├── .gitignore             # Git 忽略清單
├── README.md              # 說明文件
├── scripts/               # 啟動腳本
│   ├── init.sh           # 初始化腳本
│   └── start.sh          # 伺服器啟動腳本
└── hytale-data/          # 伺服器資料統一目錄 (自動產生)
    ├── server-files/     # 伺服器檔案
    │   ├── HytaleServer.jar  # 伺服器主程式
    │   ├── mods/         # 模組目錄
    │   ├── universe/     # 世界資料
    │   └── config/       # 設定檔
    ├── backups/          # 備份目錄
    └── machine-id/       # 認證持久化檔案
```

### 目錄說明

- **hytale-data/**: 所有伺服器運行時產生的資料都統一存放在此目錄，方便備份和管理
  - **server-files/**: 伺服器主要檔案，包含執行檔、世界資料、模組等
  - **backups/**: 自動備份的存檔位置
  - **machine-id/**: 認證資訊持久化，重啟後無需重新認證

## 🛠️ 常見問題

### 伺服器無法啟動

1. 檢查 Java 記憶體設定是否超過系統可用記憶體
2. 確認 UDP 5520 埠未被佔用
3. 查看容器日誌排除錯誤：
   ```bash
   docker compose logs hytale-server
   ```

### 連線問題

1. 確認防火牆已開放 UDP 5520 埠：
   ```bash
   # Linux (UFW)
   sudo ufw allow 5520/udp

   # Linux (firewalld)
   sudo firewall-cmd --add-port=5520/udp --permanent
   sudo firewall-cmd --reload
   ```

2. 檢查路由器是否已設定埠轉發 (Port Forwarding)

### 效能優化

1. 調整視距以減少記憶體使用：
   ```bash
   VIEW_DISTANCE=8  # 降低視距
   ```

2. 增加記憶體配置：
   ```bash
   MAX_MEMORY=16G  # 增加到 16GB
   ```

3. 使用 SSD 儲存以提升 I/O 效能

### 重新建置映像檔

如果修改了 Dockerfile 或腳本，需要重新建置：

```bash
docker compose build --no-cache
docker compose up -d
```

## 📚 參考資源

- [Hytale 官方網站](https://hytale.com/)
- [原始專案 GitHub](https://github.com/indifferentbroccoli/hytale-server-docker)
- [Docker 官方文件](https://docs.docker.com/)
- [Docker Compose 文件](https://docs.docker.com/compose/)

## 📝 技術細節

### 網路協定

Hytale 使用 **QUIC 協定**透過 **UDP** 進行通訊，而非傳統的 TCP。因此埠映射必須使用 `/udp` 標記。

### 健康檢查

容器包含健康檢查機制，每 30 秒檢查一次 `HytaleServer.jar` 程序是否正常運作：

```yaml
healthcheck:
  test: ["CMD", "pgrep", "-f", "HytaleServer.jar"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 5m
```

### 優雅關閉

容器支援優雅關閉 (Graceful Shutdown)，接收到 `SIGTERM` 訊號時會：

1. 通知玩家伺服器即將關閉
2. 儲存世界資料
3. 等待程序正常結束
4. 若超時則強制終止

## 🤝 貢獻

歡迎提交 Issue 或 Pull Request 來改善此專案！

## 📄 授權

本專案基於原始專案的 GPL-3.0 授權條款。

---

**注意事項:**
- 本專案為社群開發，非 Hytale 官方維護
- 伺服器檔案會在首次啟動時自動下載
- 建議定期備份世界資料
- 資源需求會隨玩家數量和視距而變化
