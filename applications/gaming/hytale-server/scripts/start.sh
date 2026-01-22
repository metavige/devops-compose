#!/bin/bash
set -e

# 載入共用函數
source /home/hytale/server/functions.sh

# 切換到伺服器目錄
cd /home/hytale/server-files/Server

# 顯示首次啟動訊息
if [ ! -f "server.properties" ]; then
    echo ""
    LogAction "首次啟動檢測"
    LogInfo "首次啟動時，您需要透過瀏覽器進行認證。"
    LogInfo "請留意控制台日誌中的 OAuth URL。"
    echo ""
fi

# 建構 Java 啟動參數
JAVA_OPTS="-Xmx${MAX_MEMORY} -Xms${MAX_MEMORY}"
JAVA_OPTS="$JAVA_OPTS -XX:+UseG1GC"
JAVA_OPTS="$JAVA_OPTS -XX:+ParallelRefProcEnabled"
JAVA_OPTS="$JAVA_OPTS -XX:MaxGCPauseMillis=200"
JAVA_OPTS="$JAVA_OPTS -XX:+UnlockExperimentalVMOptions"
JAVA_OPTS="$JAVA_OPTS -XX:+DisableExplicitGC"
JAVA_OPTS="$JAVA_OPTS -XX:G1NewSizePercent=30"
JAVA_OPTS="$JAVA_OPTS -XX:G1MaxNewSizePercent=40"
JAVA_OPTS="$JAVA_OPTS -XX:G1HeapRegionSize=8M"
JAVA_OPTS="$JAVA_OPTS -XX:G1ReservePercent=20"
JAVA_OPTS="$JAVA_OPTS -XX:G1HeapWastePercent=5"
JAVA_OPTS="$JAVA_OPTS -XX:G1MixedGCCountTarget=4"
JAVA_OPTS="$JAVA_OPTS -XX:InitiatingHeapOccupancyPercent=15"
JAVA_OPTS="$JAVA_OPTS -XX:G1MixedGCLiveThresholdPercent=90"
JAVA_OPTS="$JAVA_OPTS -XX:G1RSetUpdatingPauseTimePercent=5"
JAVA_OPTS="$JAVA_OPTS -XX:SurvivorRatio=32"
JAVA_OPTS="$JAVA_OPTS -XX:+PerfDisableSharedMem"
JAVA_OPTS="$JAVA_OPTS -XX:MaxTenuringThreshold=1"

# 建構伺服器參數
SERVER_ARGS=""
[ -n "$DEFAULT_PORT" ] && SERVER_ARGS="$SERVER_ARGS --port=$DEFAULT_PORT"
[ -n "$MAX_PLAYERS" ] && SERVER_ARGS="$SERVER_ARGS --max-players=$MAX_PLAYERS"
[ -n "$VIEW_DISTANCE" ] && SERVER_ARGS="$SERVER_ARGS --view-distance=$VIEW_DISTANCE"
[ -n "$AUTH_MODE" ] && SERVER_ARGS="$SERVER_ARGS --auth-mode=$AUTH_MODE"
[ "$DISABLE_SENTRY" = "true" ] && SERVER_ARGS="$SERVER_ARGS --disable-sentry"
[ "$USE_AOT_CACHE" = "true" ] && SERVER_ARGS="$SERVER_ARGS --use-aot-cache"
[ "$ACCEPT_EARLY_PLUGINS" = "true" ] && SERVER_ARGS="$SERVER_ARGS --accept-early-plugins"

# 認證 token
[ -n "$SESSION_TOKEN" ] && SERVER_ARGS="$SERVER_ARGS --session-token=$SESSION_TOKEN"
[ -n "$IDENTITY_TOKEN" ] && SERVER_ARGS="$SERVER_ARGS --identity-token=$IDENTITY_TOKEN"
[ -n "$OWNER_UUID" ] && SERVER_ARGS="$SERVER_ARGS --owner-uuid=$OWNER_UUID"

LogInfo "正在啟動 Hytale 伺服器..."
LogInfo "Java 選項: $JAVA_OPTS"
LogInfo "伺服器參數: $SERVER_ARGS"
echo ""

# 啟動伺服器
# 使用完整路徑或從 JAVA_HOME 找到 java
if [ -n "$JAVA_HOME" ]; then
    JAVA_BIN="$JAVA_HOME/bin/java"
else
    JAVA_BIN="java"
fi

exec $JAVA_BIN $JAVA_OPTS -jar HytaleServer.jar $SERVER_ARGS
