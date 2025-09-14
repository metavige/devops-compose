# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Agent Notices

- Use Transitional Chinese response.

## Architecture Overview

This repository contains a layered Docker Compose architecture for DevOps services designed for local development environments. Services are organized into logical layers with clear dependencies and separation of concerns.

### Layered Architecture

#### **Infrastructure Layer** (`infrastructure/`)
**基礎設施層 - 必須首先啟動**
- **Network Layer**:
  - `traefik/` - 反向代理 (v3.5)
  - `dnsmasq/` - DNS 服務
  - `coredns/` - 備用 DNS 服務
- **Storage Layer**:
  - `postgres/` - PostgreSQL 資料庫 (v16) + pgAdmin
  - `redis/` - Redis 快取 (v7) + Redis Commander
  - `mysql/` - MySQL 資料庫
  - `nfs-server/` - 網路儲存
- **Security Layer**:
  - `keycloak/` - 身份認證 (v26.3.0)
  - `nessus/` - 安全掃描
- **Monitoring Layer**:
  - `monitor/` - cAdvisor 監控
  - `graylog/` - 日誌管理

#### **Platform Layer** (`platform/`)
**平台層 - 容器和基礎服務**
- **Container Management**:
  - `harbor2/` - 容器鏡像倉庫
  - `portainer/` - 容器管理界面
  - `rancher/` - Kubernetes 管理
- **Messaging**:
  - `rabbitmq/` - 訊息佇列
- **Runtime**:
  - `wildfly/` - 應用伺服器

#### **Development Layer** (`development/`)
**開發層 - 開發工具鏈**
- **Source Control Management**:
  - `gitlab/` - 完整 Git 平台
  - `gitea/` - 輕量 Git 服務
- **CI/CD**:
  - `jenkins/` - 持續整合
  - `n8n/` - 工作流自動化
- **Quality Assurance**:
  - `sonarqube/` - 程式碼品質
  - `nexus/` - 制品管理
- **Collaboration**:
  - `mattermost/` - 團隊溝通
  - `xwiki/` - 文件協作

#### **Application Layer** (`applications/`)
**應用層 - 業務和工具應用**
- **Business Applications**:
  - `jbpm/` - 工作流引擎
  - `jira/` - 專案管理
  - `lowcoder/` - 低代碼平台
- **Development Tools**:
  - `project-client/` - 開發環境
  - `open-webui/` - AI 工具界面
- **API Management**:
  - `3scale/` - API 管理
  - `spring-cloud/` - 微服務架構
- **Gaming**:
  - `minecraft/` - Minecraft 伺服器

### Key Files

- `infrastructure/docker-compose.yml`: 完整基礎設施堆疊
- `scripts/start-infrastructure.sh`: Infrastructure 層啟動腳本
- `scripts/stop-infrastructure.sh`: Infrastructure 層停止腳本
- `makefile`: 傳統服務管理接口 (向後兼容)
- `taskfile.yml`: Task 執行器配置
- `.env` (gitignored): 環境變數配置

## Common Commands

### Layered Architecture Management

**推薦方法 - 使用分層啟動腳本**:
```bash
# 啟動基礎設施層 (必須首先執行)
./scripts/start-infrastructure.sh

# 停止基礎設施層
./scripts/stop-infrastructure.sh

# 重啟基礎設施層
./scripts/restart-infrastructure.sh
```

**分層啟動**:
```bash
# 只啟動網路層
docker-compose -f infrastructure/network/docker-compose.yml up -d

# 只啟動儲存層
docker-compose -f infrastructure/storage/docker-compose.yml up -d

# 只啟動安全層
docker-compose -f infrastructure/security/docker-compose.yml up -d

# 啟動完整基礎設施層
docker-compose -f infrastructure/docker-compose.yml up -d
```

### 傳統服務管理 (向後兼容)

Using Make:
```bash
# Start a service (適用於舊結構)
make start service=<layer>/<category>/<service>

# Stop a service
make stop service=<layer>/<category>/<service>

# View service configuration
make config service=<layer>/<category>/<service>
```

Using Task:
```bash
# Start infrastructure services
task start infrastructure/network

# Start development tools
task start development/scm/gitlab
```

### Network Setup

Before starting any services, create the shared network:
```bash
docker network create devops
```

### Required Environment Variables

Create a `.env` file with:
```
MY_DOMAIN=docker.internal
DEFAULT_NETWORK=devops
BASE_NETWORK_YAML="docker-compose.network.yaml"
```

### Service Structure

Each service directory contains:
- `docker-compose.yml`: Service-specific configuration
- Optional `README.md`: Service-specific documentation
- Configuration files and volumes as needed

### Traefik Labels Pattern

Services typically use these Traefik labels for HTTP services:
```yaml
labels:
  - 'traefik.http.routers.{service}.tls=true'
  - 'traefik.http.routers.{service}.rule=Host(`{service}.$MY_DOMAIN`)'
  - 'traefik.http.routers.{service}.entrypoints=websecure'
  - 'traefik.http.services.{service}.loadbalancer.server.port={port}'
```

For TCP services (databases):
```yaml
labels:
  - 'traefik.tcp.routers.{service}.rule=HostSNI(`{service}.$MY_DOMAIN`)'
  - 'traefik.tcp.routers.{service}.entrypoints={service}'
  - 'traefik.tcp.services.{service}.loadBalancer.server.port={port}'
```

## Development Notes

### Startup Dependencies
- **Infrastructure Layer** must be started first - it provides networking, storage, and security foundations
- **Platform Layer** depends on Infrastructure layer
- **Development Layer** can run independently after Infrastructure
- **Application Layer** may depend on services from other layers

### Service Access
- All HTTP services accessible via `https://{service-name}.docker.internal`
- Database services use TCP routing through Traefik
- Management interfaces:
  - Traefik Dashboard: `https://traefik.docker.internal`
  - pgAdmin: `https://pgadmin.docker.internal`
  - Redis Commander: `https://redis-ui.docker.internal`
  - Keycloak: `https://keycloak.docker.internal`

### Security Improvements
- Passwords stored in `secrets/` directories, not hardcoded
- Docker Secrets used for sensitive data
- Health checks implemented for critical services
- Resource limits configured to prevent resource exhaustion
- Security middleware configured in Traefik

### Architecture Benefits
- **Modular**: Start only the layers you need
- **Secure**: Improved password and secrets management
- **Scalable**: Clear separation of concerns
- **Maintainable**: Easier to manage and upgrade individual components
- **Documented**: Clear dependencies and startup order