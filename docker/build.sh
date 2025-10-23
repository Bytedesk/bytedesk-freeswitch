#!/bin/bash

# FreeSWITCH Docker Image Build Script
# 用于构建 FreeSWITCH Docker 镜像并同时标记 Docker Hub 和阿里云镜像

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
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

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

log_step "Building FreeSWITCH Docker Image"
log_info "Docker Hub Image: ${DOCKERHUB_IMAGE}"
log_info "Aliyun Image: ${ALIYUN_IMAGE}"
log_info "Version: ${VERSION}"
log_info "Build Date: ${BUILD_DATE}"
log_info "VCS Ref: ${VCS_REF}"

# 检查配置文件目录
if [ ! -d "conf" ]; then
    log_warn "Configuration directory 'conf' not found."
    log_info "Creating empty conf directory..."
    mkdir -p conf
    log_info "You may need to copy FreeSWITCH configuration files to 'conf' directory."
fi

# 构建镜像（同时标记 Docker Hub 和阿里云镜像）
log_step "Starting Docker build with multi-registry tags..."

# 准备 sounds 目录：优先使用仓库根目录下的 sounds 内容
if [ -d "../sounds" ]; then
    log_step "Syncing ../sounds -> ./sounds"
    rm -rf sounds
    mkdir -p sounds
    # 使用 cp -a 保留属性；若不可用可退化为常规复制
    cp -a ../sounds/. ./sounds/ 2>/dev/null || {
        log_warn "cp -a not supported, falling back to cp -R"
        cp -R ../sounds/. ./sounds/
    }
else
    log_warn "No ../sounds directory found. Building without local sounds override."
    mkdir -p sounds
fi

docker build \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg VCS_REF="${VCS_REF}" \
    --build-arg VERSION="${VERSION}" \
    -t "${DOCKERHUB_IMAGE}:${VERSION}" \
    -t "${DOCKERHUB_IMAGE}:latest" \
    -t "${ALIYUN_IMAGE}:${VERSION}" \
    -t "${ALIYUN_IMAGE}:latest" \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    log_step "Build completed successfully!"
    echo ""
    log_info "Built images for Docker Hub:"
    echo "  - ${DOCKERHUB_IMAGE}:${VERSION}"
    echo "  - ${DOCKERHUB_IMAGE}:latest"
    echo ""
    log_info "Built images for Aliyun:"
    echo "  - ${ALIYUN_IMAGE}:${VERSION}"
    echo "  - ${ALIYUN_IMAGE}:latest"
    echo ""
    log_info "To run the container:"
    echo "  docker run -d --name freeswitch-bytedesk -p 5060:5060 -p 8021:8021 ${DOCKERHUB_IMAGE}:${VERSION}"
    echo ""
    log_info "To push to registries:"
    echo "  ./push.sh ${VERSION}"
    echo ""
    log_info "Or push manually:"
    echo "  Docker Hub:  docker push ${DOCKERHUB_IMAGE}:${VERSION}"
    echo "  Aliyun:      docker push ${ALIYUN_IMAGE}:${VERSION}"
else
    log_error "Build failed!"
    exit 1
fi
