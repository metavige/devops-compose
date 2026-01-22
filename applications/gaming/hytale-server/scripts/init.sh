#!/bin/bash
set -e

# 載入共用函數
source /home/hytale/server/functions.sh

# 顯示橫幅
LogAction "Hytale Server Docker Container"
echo ""

# 設定使用者和群組 ID
PUID=${PUID:-1000}
PGID=${PGID:-1000}

LogInfo "使用者 ID: $PUID"
LogInfo "群組 ID: $PGID"

# 調整使用者和群組 ID
if [ "$PUID" != "1000" ] || [ "$PGID" != "1000" ]; then
    LogInfo "調整 hytale 使用者的 UID/GID..."
    groupmod -o -g "$PGID" hytale
    usermod -o -u "$PUID" hytale
    chown -R hytale:hytale /home/hytale
fi

# 產生持久的 machine-id
MACHINE_ID_DIR="/home/hytale/.machine-id"
mkdir -p "$MACHINE_ID_DIR"

# 檢查 UUID 檔案是否存在且有內容
if [ ! -s "$MACHINE_ID_DIR/uuid" ]; then
    LogInfo "產生持久的 machine-id 用於加密認證..."
    uuidgen > "$MACHINE_ID_DIR/uuid"
    cat "$MACHINE_ID_DIR/uuid" | tr -d '-' > "$MACHINE_ID_DIR/machine-id"
    cp "$MACHINE_ID_DIR/machine-id" "$MACHINE_ID_DIR/dbus-machine-id"
    LogSuccess "已產生新的 machine-id: $(cat $MACHINE_ID_DIR/uuid)"
else
    LogInfo "使用現有的 machine-id: $(cat $MACHINE_ID_DIR/uuid)"
fi

# 連結 machine-id 檔案
ln -sf "$MACHINE_ID_DIR/machine-id" /etc/machine-id
ln -sf "$MACHINE_ID_DIR/dbus-machine-id" /var/lib/dbus/machine-id

# 檢查是否需要下載伺服器檔案
if [ "${DOWNLOAD_ON_START}" = "true" ]; then
    download_server
else
    LogWarn "跳過伺服器下載 (DOWNLOAD_ON_START=false)"
fi

# 訊號處理器，用於優雅關閉
term_handler() {
    LogWarn "收到關閉訊號，正在停止伺服器..."
    shutdown_server
    exit 0
}

trap 'term_handler' SIGTERM SIGINT

# 匯出環境變數
export JAVA_HOME
export PATH
export DEFAULT_PORT
export SERVER_NAME
export MAX_PLAYERS
export VIEW_DISTANCE
export ENABLE_BACKUPS
export BACKUP_FREQUENCY
export DISABLE_SENTRY
export USE_AOT_CACHE
export AUTH_MODE
export ACCEPT_EARLY_PLUGINS
export SESSION_TOKEN
export IDENTITY_TOKEN
export OWNER_UUID
export MAX_MEMORY

# 切換到 hytale 使用者並啟動伺服器
LogAction "啟動 Hytale 伺服器"
LogInfo "伺服器設定:"
LogInfo "  - 埠號: $DEFAULT_PORT"
LogInfo "  - 最大玩家數: $MAX_PLAYERS"
LogInfo "  - 視距: $VIEW_DISTANCE"
LogInfo "  - 最大記憶體: $MAX_MEMORY"
LogInfo "  - 認證模式: $AUTH_MODE"
echo ""

# 執行啟動腳本
exec su -p -c "/home/hytale/server/start.sh" hytale
