# 微语 freeswitch docker 镜像

## 工作流概览

本项目使用多个独立的 GitHub Actions 工作流来实现 CI/CD 流程：

### 1. freeswitch-docker.yml - FreeSWITCH 镜像构建工作流

**触发条件：**

- 推送以 `freeswitch-v` 开头的标签（例如：`freeswitch-v1.10.12`）
- 手动触发（支持自定义版本号）
- `deploy/freeswitch/docker/` 目录变更

**功能：**

- 构建 FreeSWITCH Docker 镜像
- 推送镜像到阿里云容器镜像服务
- 推送镜像到 Docker Hub
- 创建 GitHub Release
- 自动测试镜像

**输出：**

- Docker 镜像：`registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest`
- Docker 镜像：`registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:{version}`
- Docker 镜像：`bytedesk/freeswitch:latest`
- Docker 镜像：`bytedesk/freeswitch:{version}`
- GitHub Release（包含使用文档）

## 工作流关系图

### FreeSWITCH 镜像工作流

```bash
推送标签 freeswitch-v1.10.12
或手动触发工作流
    ↓
freeswitch-docker.yml 工作流
    ├── 构建 FreeSWITCH 镜像
    ├── 推送到阿里云镜像仓库
    ├── 推送到 Docker Hub
    ├── 创建 GitHub Release
    └── 测试镜像功能
```

## 配置要求

### freeswitch-docker.yml 需要的 Secrets

- `DOCKER_HUB_ACCESS_TOKEN` - Docker Hub 访问令牌
- `ALIYUN_DOCKER_USERNAME` - 阿里云容器镜像服务用户名
- `ALIYUN_DOCKER_PASSWORD` - 阿里云容器镜像服务密码
- `GITHUB_TOKEN` - GitHub 令牌（自动提供）

## 使用流程

### ByteDesk 主应用发布流程

#### 1. 创建新版本

```bash
# 创建新标签
git tag v1.0.0

# 推送标签
git push origin v1.0.0
```

### 2. 监控部署状态

在 GitHub 仓库的 Actions 页面查看工作流执行状态

### FreeSWITCH 镜像发布流程

#### 1. 创建 FreeSWITCH 镜像版本

```bash
# 创建 FreeSWITCH 标签
git tag freeswitch-v1.10.12

# 推送标签
git push origin freeswitch-v1.10.12
```

#### 2. 手动触发构建（可选）

1. 进入 GitHub Actions 页面
2. 选择 "Build FreeSWITCH Docker" 工作流
3. 点击 "Run workflow"
4. 输入版本号（如 `1.10.12`）
5. 选择是否推送到镜像仓库
6. 点击 "Run workflow" 开始构建

#### 3. 使用构建的镜像

```bash
# 从 Docker Hub 拉取
docker pull bytedesk/freeswitch:1.10.12

# 从阿里云拉取（中国大陆推荐）
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12

# 运行容器
docker run -d \
  --name freeswitch-bytedesk \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD=bytedesk123 \
  bytedesk/freeswitch:1.10.12
```

