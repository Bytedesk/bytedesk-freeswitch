# FreeSWITCH Docker Makefile
# 简化常用的 Docker 操作命令

.PHONY: help build push run stop logs clean test cli status

# 默认变量
IMAGE_NAME := bytedesk/freeswitch
VERSION := 1.10.12
CONTAINER_NAME := freeswitch-bytedesk

# 颜色输出
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## 显示帮助信息
	@echo "$(GREEN)FreeSWITCH Docker Makefile$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

build: ## 构建 Docker 镜像
	@echo "$(GREEN)Building FreeSWITCH Docker image...$(NC)"
	@chmod +x build.sh
	@./build.sh $(VERSION)

push: ## 推送镜像到所有注册中心（Docker Hub + 阿里云）
	@echo "$(GREEN)Pushing FreeSWITCH Docker image to all registries...$(NC)"
	@chmod +x push.sh
	@./push.sh $(VERSION) all

push-dockerhub: ## 仅推送镜像到 Docker Hub
	@echo "$(GREEN)Pushing FreeSWITCH Docker image to Docker Hub...$(NC)"
	@chmod +x push.sh
	@./push.sh $(VERSION) dockerhub

push-aliyun: ## 仅推送镜像到阿里云
	@echo "$(GREEN)Pushing FreeSWITCH Docker image to Aliyun...$(NC)"
	@chmod +x push.sh
	@./push.sh $(VERSION) aliyun

run: ## 启动 FreeSWITCH 容器
	@echo "$(GREEN)Starting FreeSWITCH container...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)Container started!$(NC)"
	@make status

stop: ## 停止 FreeSWITCH 容器
	@echo "$(YELLOW)Stopping FreeSWITCH container...$(NC)"
	@docker-compose down
	@echo "$(GREEN)Container stopped!$(NC)"

restart: ## 重启 FreeSWITCH 容器
	@echo "$(YELLOW)Restarting FreeSWITCH container...$(NC)"
	@docker-compose restart
	@echo "$(GREEN)Container restarted!$(NC)"

logs: ## 查看容器日志
	@docker-compose logs -f

status: ## 查看容器状态
	@echo "$(GREEN)Container Status:$(NC)"
	@docker ps | grep -E "CONTAINER|$(CONTAINER_NAME)" || echo "Container not running"
	@echo ""
	@echo "$(GREEN)Health Status:$(NC)"
	@docker inspect --format='{{.State.Health.Status}}' $(CONTAINER_NAME) 2>/dev/null || echo "N/A"

cli: ## 连接到 FreeSWITCH CLI
	@echo "$(GREEN)Connecting to FreeSWITCH CLI...$(NC)"
	@docker exec -it $(CONTAINER_NAME) fs_cli -p bytedesk123

shell: ## 进入容器 Shell
	@echo "$(GREEN)Entering container shell...$(NC)"
	@docker exec -it $(CONTAINER_NAME) bash

test: ## 运行基本测试
	@echo "$(GREEN)Running tests...$(NC)"
	@echo ""
	@echo "1. Checking container status..."
	@docker ps | grep $(CONTAINER_NAME) && echo "✓ Container is running" || echo "✗ Container is not running"
	@echo ""
	@echo "2. Checking health status..."
	@docker inspect --format='{{.State.Health.Status}}' $(CONTAINER_NAME) 2>/dev/null | grep -q "healthy" && echo "✓ Container is healthy" || echo "⚠ Container health check failed"
	@echo ""
	@echo "3. Testing ESL port (8021)..."
	@nc -zv localhost 8021 2>&1 | grep -q "succeeded" && echo "✓ ESL port is open" || echo "✗ ESL port is not accessible"
	@echo ""
	@echo "4. Testing SIP port (5060)..."
	@nc -zv -u localhost 5060 2>&1 | grep -q "succeeded" && echo "✓ SIP port is open" || echo "✗ SIP port is not accessible"

clean: ## 清理容器和镜像
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@docker-compose down -v
	@docker rmi $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-volumes: ## 清理数据卷
	@echo "$(YELLOW)Removing volumes...$(NC)"
	@docker volume rm freeswitch_log freeswitch_db freeswitch_recordings freeswitch_storage 2>/dev/null || true
	@echo "$(GREEN)Volumes removed!$(NC)"

pull: ## 从 Docker Hub 拉取镜像
	@echo "$(GREEN)Pulling image from Docker Hub...$(NC)"
	@docker pull $(IMAGE_NAME):$(VERSION)

info: ## 显示镜像和容器信息
	@echo "$(GREEN)Image Information:$(NC)"
	@docker images | grep -E "REPOSITORY|$(IMAGE_NAME)" || echo "Image not found"
	@echo ""
	@echo "$(GREEN)Container Information:$(NC)"
	@docker ps -a | grep -E "CONTAINER|$(CONTAINER_NAME)" || echo "Container not found"
	@echo ""
	@echo "$(GREEN)Volume Information:$(NC)"
	@docker volume ls | grep -E "DRIVER|freeswitch" || echo "No volumes found"

version: ## 显示版本信息
	@echo "Image: $(IMAGE_NAME):$(VERSION)"
	@echo "Container: $(CONTAINER_NAME)"
	@docker --version
	@docker-compose --version

# 快捷命令别名
up: run ## 启动容器（run 的别名）
down: stop ## 停止容器（stop 的别名）
ps: status ## 查看状态（status 的别名）
exec: shell ## 进入容器（shell 的别名）

.DEFAULT_GOAL := help
