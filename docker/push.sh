#!/bin/bash

# FreeSWITCH Docker Image Push Script
# 用于推送 FreeSWITCH Docker 镜像到 Docker Hub 和阿里云镜像仓库

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DOCKERHUB_IMAGE="bytedesk/freeswitch"
ALIYUN_IMAGE="registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch"
VERSION="${1:-1.10.12}"
PUSH_TARGET="${2:-all}"  # all, dockerhub, aliyun

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

log_step "Pushing FreeSWITCH Docker Images"
log_info "Docker Hub Image: ${DOCKERHUB_IMAGE}"
log_info "Aliyun Image: ${ALIYUN_IMAGE}"
log_info "Version: ${VERSION}"
log_info "Push Target: ${PUSH_TARGET}"

# 推送函数
push_to_dockerhub() {
    log_step "Pushing to Docker Hub..."
    
    # 检查镜像是否存在
    if ! docker images | grep -q "${DOCKERHUB_IMAGE}.*${VERSION}"; then
        log_error "Docker Hub image ${DOCKERHUB_IMAGE}:${VERSION} not found!"
        log_info "Please build the image first using: ./build.sh ${VERSION}"
        return 1
    fi
    
    # 检查是否已登录 Docker Hub
    log_info "Checking Docker Hub login status..."
    if ! docker info 2>/dev/null | grep -q "Username"; then
        log_warn "Not logged in to Docker Hub."
        log_info "Attempting to login..."
        docker login
        if [ $? -ne 0 ]; then
            log_error "Docker Hub login failed!"
            return 1
        fi
    fi
    
    # 推送指定版本
    log_info "Pushing ${DOCKERHUB_IMAGE}:${VERSION}..."
    docker push "${DOCKERHUB_IMAGE}:${VERSION}"
    if [ $? -ne 0 ]; then
        log_error "Failed to push ${DOCKERHUB_IMAGE}:${VERSION}"
        return 1
    fi
    
    # 推送 latest 标签
    log_info "Pushing ${DOCKERHUB_IMAGE}:latest..."
    docker push "${DOCKERHUB_IMAGE}:latest"
    if [ $? -ne 0 ]; then
        log_error "Failed to push ${DOCKERHUB_IMAGE}:latest"
        return 1
    fi
    
    log_info "✅ Docker Hub push completed successfully!"
    return 0
}

push_to_aliyun() {
    log_step "Pushing to Aliyun Container Registry..."
    
    # 检查镜像是否存在
    if ! docker images | grep -q "${ALIYUN_IMAGE}.*${VERSION}"; then
        log_error "Aliyun image ${ALIYUN_IMAGE}:${VERSION} not found!"
        log_info "Please build the image first using: ./build.sh ${VERSION}"
        return 1
    fi
    
    # 检查是否已登录阿里云
    log_info "Checking Aliyun Container Registry login status..."
    log_warn "Please ensure you are logged in to Aliyun Container Registry."
    log_info "If not logged in, run: docker login registry.cn-hangzhou.aliyuncs.com"
    echo ""
    read -p "Continue pushing to Aliyun? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Aliyun push cancelled."
        return 1
    fi
    
    # 推送指定版本
    log_info "Pushing ${ALIYUN_IMAGE}:${VERSION}..."
    docker push "${ALIYUN_IMAGE}:${VERSION}"
    if [ $? -ne 0 ]; then
        log_error "Failed to push ${ALIYUN_IMAGE}:${VERSION}"
        log_info "Please login first: docker login registry.cn-hangzhou.aliyuncs.com"
        return 1
    fi
    
    # 推送 latest 标签
    log_info "Pushing ${ALIYUN_IMAGE}:latest..."
    docker push "${ALIYUN_IMAGE}:latest"
    if [ $? -ne 0 ]; then
        log_error "Failed to push ${ALIYUN_IMAGE}:latest"
        return 1
    fi
    
    log_info "✅ Aliyun push completed successfully!"
    return 0
}

# 根据参数选择推送目标
DOCKERHUB_SUCCESS=0
ALIYUN_SUCCESS=0

case "${PUSH_TARGET}" in
    "dockerhub")
        push_to_dockerhub
        DOCKERHUB_SUCCESS=$?
        ;;
    "aliyun")
        push_to_aliyun
        ALIYUN_SUCCESS=$?
        ;;
    "all"|*)
        push_to_dockerhub
        DOCKERHUB_SUCCESS=$?
        echo ""
        push_to_aliyun
        ALIYUN_SUCCESS=$?
        ;;
esac

# 显示推送结果摘要
echo ""
log_step "Push Summary"
echo ""

if [ $DOCKERHUB_SUCCESS -eq 0 ]; then
    log_info "✅ Docker Hub: SUCCESS"
    echo "  - ${DOCKERHUB_IMAGE}:${VERSION}"
    echo "  - ${DOCKERHUB_IMAGE}:latest"
    echo "  - URL: https://hub.docker.com/r/bytedesk/freeswitch"
    echo "  - Pull: docker pull ${DOCKERHUB_IMAGE}:${VERSION}"
else
    log_warn "❌ Docker Hub: FAILED or SKIPPED"
fi

echo ""

if [ $ALIYUN_SUCCESS -eq 0 ]; then
    log_info "✅ Aliyun Container Registry: SUCCESS"
    echo "  - ${ALIYUN_IMAGE}:${VERSION}"
    echo "  - ${ALIYUN_IMAGE}:latest"
    echo "  - URL: https://cr.console.aliyun.com/repository/cn-hangzhou/bytedesk/freeswitch"
    echo "  - Pull: docker pull ${ALIYUN_IMAGE}:${VERSION}"
else
    log_warn "❌ Aliyun Container Registry: FAILED or SKIPPED"
fi

echo ""

# 返回状态
if [ "${PUSH_TARGET}" == "all" ]; then
    if [ $DOCKERHUB_SUCCESS -eq 0 ] && [ $ALIYUN_SUCCESS -eq 0 ]; then
        log_step "All pushes completed successfully! 🎉"
        exit 0
    else
        log_error "Some pushes failed. Please check the logs above."
        exit 1
    fi
else
    if [ $DOCKERHUB_SUCCESS -eq 0 ] || [ $ALIYUN_SUCCESS -eq 0 ]; then
        log_step "Push completed successfully! 🎉"
        exit 0
    else
        log_error "Push failed. Please check the logs above."
        exit 1
    fi
fi
