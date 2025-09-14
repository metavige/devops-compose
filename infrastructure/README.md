# Infrastructure Layer - 基礎設施層

基礎設施層是整個 DevOps 環境的核心，提供網路、儲存、安全和監控等基礎服務。**此層必須首先啟動**，其他層級的服務都依賴於此層的服務。

## 架構概覽

```
infrastructure/
├── network/          # 網路層 - 反向代理和 DNS
├── storage/          # 儲存層 - 資料庫和快取
├── security/         # 安全層 - 身份認證和安全掃描
└── monitoring/       # 監控層 - 系統監控和日誌
```

## 啟動順序

### 推薦方式 - 使用腳本
```bash
# 一鍵啟動完整基礎設施層
./scripts/start-infrastructure.sh

# 停止基礎設施層
./scripts/stop-infrastructure.sh

# 重啟基礎設施層
./scripts/restart-infrastructure.sh
```

### 分層啟動
```bash
# 1. 網路層 (最優先)
docker-compose -f infrastructure/network/docker-compose.yml up -d

# 2. 儲存層
docker-compose -f infrastructure/storage/docker-compose.yml up -d

# 3. 安全層
docker-compose -f infrastructure/security/docker-compose.yml up -d

# 4. 監控層 (可選)
docker-compose -f infrastructure/monitoring/docker-compose.yml up -d
```

## 子層說明

### 🌐 Network Layer (網路層)
**必須最先啟動**
- **Traefik**: 反向代理和負載均衡器 (v3.5)
- **DNSmasq**: 本地 DNS 服務 (*.docker.internal)
- **CoreDNS**: 備用 DNS 服務
- **Whoami**: Traefik 測試服務

**存取點**:
- Traefik Dashboard: https://traefik.docker.internal
- DNSmasq Admin: https://dnsmasq.docker.internal
- Whoami Test: https://whoami.docker.internal

### 💾 Storage Layer (儲存層)
提供資料持久化服務
- **PostgreSQL**: 主要關聯式資料庫 (v16) + pgAdmin
- **Redis**: 快取和訊息佇列 (v7) + Redis Commander
- **MySQL**: 備用資料庫服務
- **NFS Server**: 網路共享儲存

**存取點**:
- pgAdmin: https://pgadmin.docker.internal
- Redis Commander: https://redis-ui.docker.internal
- PostgreSQL: postgres.docker.internal:5432
- Redis: redis.docker.internal:6379

### 🔐 Security Layer (安全層)
身份認證和安全服務
- **Keycloak**: 統一身份認證平台 (v26.3.0)
- **Nessus**: 安全弱點掃描工具

**存取點**:
- Keycloak: https://keycloak.docker.internal

### 📊 Monitoring Layer (監控層)
系統監控和日誌管理
- **cAdvisor**: 容器效能監控
- **Graylog**: 集中化日誌管理系統

## 依賴關係

- **Network Layer**: 無外部依賴，最先啟動
- **Storage Layer**: 依賴 Network Layer (Traefik 路由)
- **Security Layer**: 依賴 Storage Layer (資料庫)
- **Monitoring Layer**: 依賴 Network Layer

## 環境變數

關鍵環境變數在 `.env` 檔案中配置：

```bash
# 基本配置
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops

# 服務版本
TRAEFIK_VERSION=v3.5
POSTGRES_VERSION=16
REDIS_VERSION=7-alpine
KEYCLOAK_VERSION=26.3.0

# 安全配置
POSTGRES_USER=postgres
REDIS_PASSWORD=redis123
KEYCLOAK_ADMIN=admin
```

## 安全改進

相較於舊架構的安全提升：

1. **密碼管理**: 使用 Docker Secrets，不再硬編碼
2. **健康檢查**: 所有關鍵服務都有健康檢查
3. **資源限制**: 防止服務消耗過多資源
4. **網路安全**: Traefik 安全中間件配置
5. **存取控制**: 管理界面使用基本認證保護

## 故障排除

### 常見問題

1. **服務啟動失敗**
   ```bash
   # 檢查日誌
   docker-compose -f infrastructure/network/docker-compose.yml logs traefik
   ```

2. **DNS 解析失敗**
   ```bash
   # 檢查 dnsmasq 狀態
   docker-compose -f infrastructure/network/docker-compose.yml ps dnsmasq
   ```

3. **資料庫連線問題**
   ```bash
   # 檢查 PostgreSQL 健康狀態
   docker-compose -f infrastructure/storage/docker-compose.yml ps postgres
   ```

### 重置環境
```bash
# 完全停止並清理
./scripts/stop-infrastructure.sh
docker system prune -f
./scripts/start-infrastructure.sh
```

## 下一步

基礎設施層啟動完成後，可以繼續啟動其他層級：
- [Platform Layer](../platform/README.md) - 容器和平台服務
- [Development Layer](../development/README.md) - 開發工具鏈
- [Application Layer](../applications/README.md) - 業務應用