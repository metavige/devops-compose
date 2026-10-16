# DevOps Compose

一個完整的 Docker Compose 驅動的 DevOps 服務棧，提供分層架構、自動化初始化和簡化的管理介面。

## ✨ 主要特色

- 🏗️ **分層架構** - 核心服務、基礎設施、平台、開發和應用層的清晰分離
- 🚀 **一鍵初始化** - 自動化環境設定和核心服務啟動
- 🌐 **統一代理** - Traefik 提供 HTTPS 和服務發現
- 📦 **Registry Mirror** - Docker Hub 的本地快取代理
- ⚙️ **簡化管理** - Make 和 Task 的統一服務管理介面
- 🔧 **自動配置** - 支援 direnv 的環境自動載入

## 📋 系統需求

- Docker >= 20.10
- Docker Compose >= 2.0
- Make (可選)
- Task (可選) - `brew install go-task/tap/go-task`
- mkcert (建議) - `brew install mkcert`，產生瀏覽器信任的本機憑證
- direnv (可選) - `brew install direnv`

## 🚀 快速開始

### 1. 一鍵初始化

```bash
# 克隆專案
git clone <repository-url>
cd devops-compose

# 初始化環境 (建立網路、憑證、DNS resolver、啟動核心服務)
# 寫入 /etc/resolver 時會要求 sudo
./init.sh
```

### 2. 使用 direnv 自動載入 (可選)

```bash
# 安裝 direnv 並設定 shell hook
brew install direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc  # 或 ~/.zshrc

# 允許此目錄
direnv allow

# 之後每次進入目錄都會自動顯示可用指令
```

### 3. 驗證核心服務

訪問以下服務確認運作正常：

- **Traefik Dashboard**: https://traefik.docker.internal
- **Registry Mirror**: https://registry.docker.internal
- **測試服務**: https://whoami.docker.internal

## 🏗️ 架構概覽

```
devops-compose/
├── core/                    # 核心基礎服務 (必須先啟動)
│   ├── traefik/            # 反向代理和服務發現
│   ├── registry/           # Docker Hub mirror
│   └── docker-compose.yml # 核心服務整合
├── infrastructure/         # 基礎設施層
│   ├── storage/           # PostgreSQL, Redis, MySQL
│   ├── security/          # Keycloak, Vaultwarden, 安全服務
│   └── monitoring/        # 監控和日誌
├── platform/              # 平台層
│   ├── harbor2/           # 容器鏡像倉庫
│   └── portainer/         # 容器管理
├── development/           # 開發工具鏈
│   ├── scm/              # GitLab, Gitea
│   ├── cicd/             # Jenkins
│   └── quality/          # Nexus, SonarQube, Trivy
└── applications/         # 業務應用
    ├── tools/            # 實用工具 (Dozzle, PDF, Excalidraw, FileBrowser, IT-Tools)
    └── various-apps/     # 各種應用服務
```

## 🎯 服務管理

### 使用 Make (推薦)

```bash
# 顯示可用指令
make help

# 核心服務管理
make start-core           # 啟動核心服務
make stop-core           # 停止核心服務

# 服務管理
make start service=development/quality/nexus        # 啟動 Nexus
make stop service=infrastructure/storage/postgres   # 停止 PostgreSQL
make restart service=platform/harbor2              # 重啟 Harbor
make logs service=development/scm/gitlab           # 查看 GitLab 日誌
make status service=core                           # 查看服務狀態
```

### 使用 Task

```bash
# 顯示可用指令
task

# 核心服務
task start:core          # 啟動核心服務
task stop:core          # 停止核心服務

# 快捷指令
task start:postgres     # 啟動 PostgreSQL
task start:gitlab       # 啟動 GitLab
task start:nexus        # 啟動 Nexus

# 通用指令
task start development/quality/nexus
task logs infrastructure/storage/postgres
```

### 直接使用腳本

```bash
# 核心服務腳本
./scripts/start-core.sh   # 啟動核心服務
./scripts/stop-core.sh    # 停止核心服務

# 手動初始化
./init.sh                # 完整初始化流程
```

## 🌐 網路和服務發現

### Traefik 代理

所有服務都透過 Traefik 提供 HTTPS 存取：

- 格式：`https://服務名.docker.internal`
- 自動 SSL 憑證
- 服務發現和負載均衡

### DNS 解析

`*.docker.internal` 不是公開網域，由 repo 內的 CoreDNS 容器（隨核心服務啟動，監聽主機 port 10053）回答，一律指向 `127.0.0.1`，再由 Traefik 依 Host 轉發。不需要在主機安裝 dnsmasq。

macOS 只要讓系統 resolver 把這個網域交給 CoreDNS，`./init.sh` 會自動寫入（需要 sudo），也可以手動執行：

```bash
task dns:setup        # 或 make dns-setup
```

寫入的內容是 `/etc/resolver/docker.internal`：

```
nameserver 127.0.0.1
port 10053
```

驗證：

```bash
task dns:check        # 或 make dns-check
```

注意 `dig`、`nslookup` 不會經過 `/etc/resolver`，直接用它們查會以為沒生效；請用 `dscacheutil` 或 `curl` 驗證。

離線也能用，因為查詢不出本機。若在其他機器臨時使用、不想動系統設定，可改用公開的萬用 DNS，例如把 `.env` 的 `MY_DOMAIN` 改成 `127.0.0.1.nip.io`（需要能連外，且可能被企業 DNS 的 rebinding 防護擋掉），並重新產生涵蓋該網域的憑證。

### 常見服務 URL

| 服務 | URL | 描述 |
|------|-----|------|
| Traefik | https://traefik.docker.internal | 反向代理管理界面 |
| Registry | https://registry.docker.internal | Docker registry mirror |
| GitLab | https://gitlab.docker.internal | Git 平台 |
| Harbor | https://harbor.docker.internal | 容器鏡像倉庫 |
| Nexus | https://nexus.docker.internal | 制品管理 |
| Trivy | https://trivy.docker.internal | 容器安全掃描 |
| PostgreSQL | postgres://postgres.docker.internal:5432 | 資料庫 |
| Vaultwarden | https://vault.docker.internal | 自託管密碼管理器 |
| Dozzle | https://dozzle.docker.internal | 容器日誌監控 |
| Stirling PDF | https://pdf.docker.internal | PDF 處理工具 |
| Excalidraw | https://draw.docker.internal | 手繪風格白板 |
| FileBrowser | https://files.docker.internal | 網頁檔案管理器 |
| IT-Tools | https://tools.docker.internal | 開發者工具集 |

## 📦 Docker Registry Mirror

### 自動配置

根據你的 Docker 環境設定：

**🐳 Docker Desktop (macOS/Windows)**
```
Docker Desktop → Settings → Docker Engine
```

**🚀 OrbStack (macOS)**
```
OrbStack → Settings → Docker → Engine
或編輯: ~/.orbstack/config/docker.json
```

**🐧 Linux**
```
編輯: /etc/docker/daemon.json
```

**設定內容**:
```json
{
  "registry-mirrors": [
    "https://registry.docker.internal"
  ],
  "insecure-registries": [
    "registry.docker.internal"
  ]
}
```

設定完成後重啟 Docker/OrbStack。

### 手動使用

```bash
# 直接使用 registry mirror
docker pull registry.docker.internal/nginx:latest

# 重新標記為標準名稱
docker tag registry.docker.internal/nginx:latest nginx:latest
```

## ⚙️ 環境配置

### 環境變數 (.env)

```bash
# 網域設定
MY_DOMAIN=docker.internal

# Docker 網路
DEFAULT_NETWORK=devops

# Traefik 版本
TRAEFIK_VERSION=v3.7

# 時區
TZ=Asia/Taipei
```

### 網路設定

系統使用名為 `devops` 的 Docker 網路連接所有服務：

```bash
# 手動建立網路 (init.sh 會自動建立)
docker network create devops
```

## 🔧 進階配置

### 新增服務

1. 在適當的層級目錄建立服務目錄
2. 建立 `docker-compose.yml`
3. 加入 Traefik 標籤進行代理
4. 更新 `taskfile.yml` 快捷指令 (可選)

範例 Traefik 標籤：

```yaml
services:
  myservice:
    image: myimage
    labels:
      - 'traefik.http.routers.myservice.tls=true'
      - 'traefik.http.routers.myservice.rule=Host(`myservice.$MY_DOMAIN`)'
      - 'traefik.http.routers.myservice.entrypoints=websecure'
      - 'traefik.http.services.myservice.loadbalancer.server.port=8080'
    networks:
      - devops
```

### 自定義域名

修改 `.env` 中的 `MY_DOMAIN` 變數，然後重啟服務：

```bash
# .env
MY_DOMAIN=mycompany.local

# 重啟核心服務使配置生效
make stop-core
make start-core
```

## 🔍 故障排除

### 常見問題

1. **服務無法啟動**
   ```bash
   # 檢查網路是否存在
   docker network ls | grep devops

   # 重新建立網路
   docker network create devops
   ```

2. **HTTPS 憑證問題**
   ```bash
   # 重新生成憑證
   rm infrastructure/network/traefik/certs/*
   ./init.sh
   ```

3. **服務無法存取**
   ```bash
   # 檢查 Traefik 狀態
   make status service=core

   # 查看 Traefik 日誌
   make logs service=core
   ```

4. **DNS 無法解析 (`*.docker.internal` 全部打不開)**
   ```bash
   # 確認 coredns 容器在跑
   docker ps --filter name=coredns

   # 確認 resolver 設定，內容應為 nameserver 127.0.0.1 / port 10053
   cat /etc/resolver/docker.internal

   # 用系統 resolver 驗證 (dig 不適用)
   task dns:check
   ```

5. **憑證過期**
   ```bash
   # mkcert 憑證效期約 2 年 3 個月
   openssl x509 -in infrastructure/network/traefik/certs/traefik.crt -noout -dates
   # 過期就刪掉重跑 init.sh
   ```

### 日誌查看

```bash
# 核心服務日誌
docker compose -f core/docker-compose.yml logs -f

# 特定服務日誌
make logs service=development/quality/nexus

# 系統服務狀態
docker ps --filter network=devops
```

## 🤝 貢獻

1. Fork 此專案
2. 建立功能分支
3. 提交更改
4. 建立 Pull Request

## 📄 授權

此專案採用 MIT 授權 - 詳見 [LICENSE](LICENSE) 檔案。

## 🙏 致謝

- [Traefik](https://traefik.io/) - 現代反向代理
- [Docker Registry](https://docs.docker.com/registry/) - 官方容器鏡像倉庫
- [Task](https://taskfile.dev/) - 現代化建構工具
- [direnv](https://direnv.net/) - 環境變數管理工具