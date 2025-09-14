# DevOps Compose Makefile
# 簡化的服務管理介面

include .env

# 變數定義
ROOT_DIR := $(shell pwd)
SERVICE_DIR := $(ROOT_DIR)/$(service)
COMPOSE_FILE := $(SERVICE_DIR)/docker-compose.yml
NETWORK_FILE := $(ROOT_DIR)/docker-compose.network.yaml

# 解析服務名稱（支援短名稱和完整路徑）
RESOLVED_SERVICE := $(shell \
	if [ -z "$(service)" ]; then \
		echo ""; \
	elif [ -f "$(ROOT_DIR)/$(service)/docker-compose.yml" ]; then \
		echo "$(service)"; \
	else \
		FOUND=$$(find $(ROOT_DIR) -name "docker-compose.yml" -type f | grep -E "/$(service)/docker-compose.yml$$" | head -1); \
		if [ -n "$$FOUND" ]; then \
			echo "$$FOUND" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'; \
		else \
			FOUND=$$(find $(ROOT_DIR) -name "docker-compose.yml" -type f | grep -E "/[^/]*$(service)[^/]*/docker-compose.yml$$" | head -1); \
			if [ -n "$$FOUND" ]; then \
				echo "$$FOUND" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'; \
			else \
				echo ""; \
			fi; \
		fi; \
	fi)

# 重新定義變數使用解析後的服務名稱
SERVICE_DIR := $(ROOT_DIR)/$(RESOLVED_SERVICE)
COMPOSE_FILE := $(SERVICE_DIR)/docker-compose.yml

# 檢查服務是否存在
check-service:
	@if [ -z "$(service)" ]; then \
		echo "❌ 請指定服務名稱，例如: make start service=nexus"; \
		exit 1; \
	fi
	@if [ -z "$(RESOLVED_SERVICE)" ]; then \
		echo "❌ 找不到服務: $(service)"; \
		echo "💡 使用 'make list' 查看所有可用服務"; \
		exit 1; \
	fi
	@if [ ! -f "$(COMPOSE_FILE)" ]; then \
		echo "❌ 找不到服務配置檔案: $(COMPOSE_FILE)"; \
		exit 1; \
	fi

# 執行 docker compose 指令的通用函數
define run_compose
	@echo "🔍 解析服務: $(service) → $(RESOLVED_SERVICE)"
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
.PHONY: help init start stop restart down status logs config start-core stop-core list search

help:
	@echo "🎉 DevOps Compose 可用指令:"
	@echo ""
	@echo "核心服務:"
	@echo "  make start-core        - 啟動核心服務 (Traefik + Registry)"
	@echo "  make stop-core         - 停止核心服務"
	@echo ""
	@echo "服務管理:"
	@echo "  make start service=<name>   - 啟動指定服務"
	@echo "  make stop service=<name>    - 停止指定服務"
	@echo "  make restart service=<name> - 重啟指定服務"
	@echo "  make down service=<name>    - 完全停止服務"
	@echo "  make status service=<name>  - 查看服務狀態"
	@echo "  make logs service=<name>    - 查看服務日誌"
	@echo ""
	@echo "服務搜尋:"
	@echo "  make list              - 列出所有可用服務"
	@echo "  make search keyword=<word> - 搜尋服務"
	@echo ""
	@echo "範例:"
	@echo "  make start service=nexus          # 短名稱"
	@echo "  make start service=development/quality/nexus  # 完整路徑"
	@echo "  make search keyword=postgres      # 搜尋"
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

list:
	@echo "📋 可用服務列表："
	@echo ""
	@echo "📂 按分層分類："
	@echo ""
	@echo "🔧 核心服務:"
	@if [ -f "$(ROOT_DIR)/core/docker-compose.yml" ]; then \
		echo "  • core (Traefik + Registry Mirror)"; \
	fi
	@echo ""
	@echo "🏗️ 基礎設施層:"
	@find $(ROOT_DIR)/infrastructure -name "docker-compose.yml" -type f 2>/dev/null | while read file; do \
		service_path=$$(echo "$$file" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'); \
		service_name=$$(basename "$$service_path"); \
		echo "  • $$service_name ($$service_path)"; \
	done
	@echo ""
	@echo "🔧 平台層:"
	@find $(ROOT_DIR)/platform -name "docker-compose.yml" -type f 2>/dev/null | while read file; do \
		service_path=$$(echo "$$file" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'); \
		service_name=$$(basename "$$service_path"); \
		echo "  • $$service_name ($$service_path)"; \
	done
	@echo ""
	@echo "💻 開發層:"
	@find $(ROOT_DIR)/development -name "docker-compose.yml" -type f 2>/dev/null | while read file; do \
		service_path=$$(echo "$$file" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'); \
		service_name=$$(basename "$$service_path"); \
		echo "  • $$service_name ($$service_path)"; \
	done
	@echo ""
	@echo "🚀 應用層:"
	@find $(ROOT_DIR)/applications -name "docker-compose.yml" -type f 2>/dev/null | while read file; do \
		service_path=$$(echo "$$file" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'); \
		service_name=$$(basename "$$service_path"); \
		echo "  • $$service_name ($$service_path)"; \
	done
	@echo ""
	@echo "💡 使用方式："
	@echo "  • 短名稱: make start service=nexus"
	@echo "  • 完整路徑: make start service=development/quality/nexus"

search:
	@if [ -z "$(keyword)" ]; then \
		echo "❌ 請提供搜尋關鍵字，例如: make search keyword=nexus"; \
		exit 1; \
	fi
	@echo "🔍 搜尋結果: '$(keyword)'"
	@echo ""
	@FOUND=0; \
	find $(ROOT_DIR) -name "docker-compose.yml" -type f | while read file; do \
		service_path=$$(echo "$$file" | sed 's|$(ROOT_DIR)/||' | sed 's|/docker-compose.yml||'); \
		service_name=$$(basename "$$service_path"); \
		if echo "$$service_name" | grep -qi "$(keyword)" || echo "$$service_path" | grep -qi "$(keyword)"; then \
			echo "✓ $$service_name ($$service_path)"; \
			FOUND=1; \
		fi; \
	done; \
	if [ $$FOUND -eq 0 ]; then \
		echo "❌ 未找到包含 '$(keyword)' 的服務"; \
		echo ""; \
		echo "💡 提示: 使用 'make list' 查看所有可用服務"; \
	else \
		echo ""; \
		echo "💡 使用方式："; \
		echo "  • make start service=<服務名稱>"; \
		echo "  • make status service=<服務名稱>"; \
	fi
