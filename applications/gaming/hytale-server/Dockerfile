# Hytale Server Docker Image
FROM eclipse-temurin:25-jdk

# 安裝必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    procps \
    jq \
    curl \
    unzip \
    wget \
    uuid-runtime \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 元資料標籤
LABEL maintainer="devops-compose" \
    name="hytale-server" \
    description="Dockerized Hytale Dedicated Server"

# 建立使用者和群組
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g 1000 hytale && \
    useradd -u 1000 -g 1000 -m -d /home/hytale -s /bin/bash hytale

# 環境變數設定
ENV HOME=/home/hytale \
    CONFIG_DIR=/hytale-config \
    DEFAULT_PORT=5520 \
    SERVER_NAME=hytale-server \
    MAX_PLAYERS=20 \
    VIEW_DISTANCE=12 \
    ENABLE_BACKUPS=false \
    BACKUP_FREQUENCY=30 \
    DISABLE_SENTRY=true \
    USE_AOT_CACHE=true \
    AUTH_MODE=authenticated \
    ACCEPT_EARLY_PLUGINS=false \
    DOWNLOAD_ON_START=true \
    SESSION_TOKEN="" \
    IDENTITY_TOKEN="" \
    OWNER_UUID="" \
    MAX_MEMORY=8G

# 複製腳本檔案
COPY ./scripts /home/hytale/server/

# 建立必要目錄並設定權限
RUN mkdir -p /home/hytale/server-files && \
    mkdir -p /var/lib/dbus && \
    chmod +x /home/hytale/server/*.sh && \
    chown -R 1000:1000 /home/hytale

WORKDIR /home/hytale/server

# 健康檢查
HEALTHCHECK --start-period=5m \
    --interval=30s \
    --timeout=10s \
    CMD pgrep -f "HytaleServer.jar" > /dev/null || exit 1

# 容器啟動點
ENTRYPOINT ["/home/hytale/server/init.sh"]
