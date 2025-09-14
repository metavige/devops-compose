# DevOps Compose Makefile
# 簡化的服務管理介面

include .env

# 變數定義
ROOT_DIR := $(shell pwd)
SERVICE_DIR := $(ROOT_DIR)/$(service)
COMPOSE_FILE := $(SERVICE_DIR)/docker-compose.yml
NETWORK_FILE := $(ROOT_DIR)/docker-compose.network.yaml

# 檢查服務是否存在
check-service:
	@if [ -z "$(service)" ]; then \
		echo "❌ 請指定服務名稱，例如: make start service=development/quality/nexus"; \
		exit 1; \
	fi
	@if [ ! -f "$(COMPOSE_FILE)" ]; then \
		echo "❌ 找不到服務配置檔案: $(COMPOSE_FILE)"; \
		exit 1; \
	fi

# 執行 docker compose 指令的通用函數
define run_compose
	@echo "📁 服務目錄: $(SERVICE_DIR)"
	@if [ -f "$(NETWORK_FILE)" ]; then \
		echo "🔗 使用網路配置: $(NETWORK_FILE)"; \
		docker compose --project-directory $(SERVICE_DIR) -f $(NETWORK_FILE) -f $(COMPOSE_FILE) $(1); \
	else \
		echo "🐳 使用預設配置"; \
		docker compose --project-directory $(SERVICE_DIR) -f $(COMPOSE_FILE) $(1); \
	fi
endef

# 目標定義
.PHONY: help init start stop restart down status logs config start-core stop-core

help:
	@echo "🎉 DevOps Compose 可用指令:"
	@echo ""
	@echo "核心服務:"
	@echo "  make start-core        - 啟動核心服務 (Traefik + Registry)"
	@echo "  make stop-core         - 停止核心服務"
	@echo ""
	@echo "服務管理:"
	@echo "  make start service=<path>   - 啟動指定服務"
	@echo "  make stop service=<path>    - 停止指定服務"
	@echo "  make restart service=<path> - 重啟指定服務"
	@echo "  make down service=<path>    - 完全停止服務"
	@echo "  make status service=<path>  - 查看服務狀態"
	@echo "  make logs service=<path>    - 查看服務日誌"
	@echo ""
	@echo "範例:"
	@echo "  make start service=development/quality/nexus"
	@echo "  make start service=infrastructure/storage/postgres"
	@echo ""
	@echo "其他:"
	@echo "  make init              - 初始化環境"
	@echo "  make help              - 顯示此說明"

init:
	@echo "🚀 初始化 DevOps Compose 環境..."
	@./init.sh

start-core:
	@echo "🚀 啟動核心基礎服務..."
	@./scripts/start-core.sh

stop-core:
	@echo "🛑 停止核心基礎服務..."
	@./scripts/stop-core.sh

start: check-service
	@echo "🚀 啟動服務: $(service)"
	$(call run_compose,up -d)

stop: check-service
	@echo "🛑 停止服務: $(service)"
	$(call run_compose,stop)

restart: check-service
	@echo "🔄 重啟服務: $(service)"
	$(call run_compose,restart)

down: check-service
	@echo "🗑️  完全停止服務: $(service)"
	$(call run_compose,down)

status: check-service
	@echo "📊 服務狀態: $(service)"
	$(call run_compose,ps)

logs: check-service
	@echo "📋 服務日誌: $(service)"
	$(call run_compose,logs -f)

config: check-service
	@echo "⚙️  服務配置: $(service)"
	$(call run_compose,config)
