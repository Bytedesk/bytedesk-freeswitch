# FreeSWITCH Docker 镜像推送指南

本文档说明如何将构建好的 FreeSWITCH Docker 镜像推送到 Docker Hub 和阿里云镜像仓库。

## 📋 概述

脚本支持将镜像同时推送到：
- **Docker Hub**: `bytedesk/freeswitch`
- **阿里云镜像仓库**: `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch`

## 🔧 前置准备

### 1. 构建镜像

首先需要构建镜像（会自动为两个镜像仓库打标签）：

```bash
./build.sh [version]

# 示例
./build.sh 1.10.12
```

### 2. 配置 Docker Hub

#### 登录 Docker Hub

```bash
docker login
```

输入您的 Docker Hub 用户名和密码（或 Access Token）。

#### 获取 Access Token（推荐）

1. 登录 [Docker Hub](https://hub.docker.com/)
2. 进入 `Account Settings` → `Security`
3. 点击 `New Access Token`
4. 选择权限：`Read, Write, Delete`
5. 使用 Token 登录：

```bash
echo "YOUR_TOKEN" | docker login -u bytedesk --password-stdin
```

### 3. 配置阿里云镜像仓库

#### 创建镜像仓库

1. 登录 [阿里云容器镜像服务](https://cr.console.aliyun.com/)
2. 选择区域：杭州 (cn-hangzhou)
3. 创建命名空间：`bytedesk`
4. 创建镜像仓库：`freeswitch`

#### 登录阿里云

```bash
docker login registry.cn-hangzhou.aliyuncs.com
```

输入阿里云账号的用户名和密码。

#### 设置镜像仓库密码

1. 进入 [访问凭证](https://cr.console.aliyun.com/)
2. 左侧菜单选择 `访问凭证`
3. 设置或重置固定密码
4. 记录用户名和密码

## 🚀 使用方法

### 方式一：使用脚本（推荐）

#### 推送到所有镜像仓库

```bash
./push.sh [version]

# 示例
./push.sh 1.10.12

# 或使用默认版本
./push.sh
```

#### 仅推送到 Docker Hub

```bash
./push.sh [version] dockerhub

# 示例
./push.sh 1.10.12 dockerhub
```

#### 仅推送到阿里云

```bash
./push.sh [version] aliyun

# 示例
./push.sh 1.10.12 aliyun
```

### 方式二：使用 Makefile

#### 推送到所有镜像仓库

```bash
make push

# 或指定版本
make push VERSION=1.10.12
```

#### 仅推送到 Docker Hub

```bash
make push-dockerhub

# 或指定版本
make push-dockerhub VERSION=1.10.12
```

#### 仅推送到阿里云

```bash
make push-aliyun

# 或指定版本
make push-aliyun VERSION=1.10.12
```

### 方式三：手动推送

#### 推送到 Docker Hub

```bash
docker push bytedesk/freeswitch:1.10.12
docker push bytedesk/freeswitch:latest
```

#### 推送到阿里云

```bash
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest
```

## 📊 推送流程

### 完整推送流程

```bash
# 1. 构建镜像
./build.sh 1.10.12

# 2. 登录 Docker Hub（如未登录）
docker login

# 3. 登录阿里云（如未登录）
docker login registry.cn-hangzhou.aliyuncs.com

# 4. 推送到所有镜像仓库
./push.sh 1.10.12

# 或分别推送
./push.sh 1.10.12 dockerhub
./push.sh 1.10.12 aliyun
```

### 脚本执行流程

1. **检查镜像存在性** - 验证本地镜像是否已构建
2. **检查登录状态** - 确认已登录到镜像仓库
3. **推送版本镜像** - 推送特定版本标签
4. **推送 latest 镜像** - 推送 latest 标签
5. **显示推送摘要** - 展示推送结果和访问信息

## 📦 推送产物

### Docker Hub

```
bytedesk/freeswitch:1.10.12
bytedesk/freeswitch:latest
```

**访问地址**:
- 仓库: https://hub.docker.com/r/bytedesk/freeswitch
- 拉取: `docker pull bytedesk/freeswitch:1.10.12`

### 阿里云镜像仓库

```
registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12
registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest
```

**访问地址**:
- 仓库: https://cr.console.aliyun.com/repository/cn-hangzhou/bytedesk/freeswitch
- 拉取: `docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12`

## 🔍 验证推送

### 验证 Docker Hub

```bash
# 拉取镜像测试
docker pull bytedesk/freeswitch:1.10.12

# 查看镜像信息
docker inspect bytedesk/freeswitch:1.10.12

# 访问 Docker Hub 页面
open https://hub.docker.com/r/bytedesk/freeswitch/tags
```

### 验证阿里云

```bash
# 拉取镜像测试
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12

# 查看镜像信息
docker inspect registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12

# 访问阿里云控制台
open https://cr.console.aliyun.com/repository/cn-hangzhou/bytedesk/freeswitch
```

## ⚠️ 常见问题

### 问题 1: Docker Hub 推送失败

**错误信息**:
```
denied: requested access to the resource is denied
```

**解决方案**:
1. 检查是否已登录：`docker login`
2. 确认有仓库写入权限
3. 检查仓库名称是否正确
4. 确认 Access Token 权限足够

### 问题 2: 阿里云推送失败

**错误信息**:
```
unauthorized: authentication required
```

**解决方案**:
1. 登录阿里云：`docker login registry.cn-hangzhou.aliyuncs.com`
2. 确认镜像仓库已创建
3. 检查命名空间是否为 `bytedesk`
4. 验证密码是否正确

### 问题 3: 镜像不存在

**错误信息**:
```
Image not found
```

**解决方案**:
1. 先构建镜像：`./build.sh 1.10.12`
2. 检查镜像是否存在：`docker images | grep freeswitch`
3. 确认版本号正确

### 问题 4: 网络超时

**错误信息**:
```
net/http: TLS handshake timeout
```

**解决方案**:
1. 检查网络连接
2. 配置 Docker 代理（如需要）
3. 重试推送
4. 考虑分别推送而非一次推送所有

### 问题 5: 推送速度慢

**优化方案**:
1. 使用 Docker Hub 时考虑配置镜像加速
2. 中国大陆用户推荐使用阿里云
3. 检查本地网络带宽
4. 考虑使用代理

## 🔐 安全建议

### 1. 使用 Access Token

**Docker Hub**:
- 不要使用账号密码
- 使用 Access Token
- 定期轮换 Token
- 限制 Token 权限

### 2. 保护凭据

```bash
# 不要在脚本中硬编码密码
# 使用环境变量
export DOCKER_PASSWORD="your_password"
echo "$DOCKER_PASSWORD" | docker login -u username --password-stdin

# 或使用 Docker credential helper
```

### 3. 限制访问权限

- 使用最小权限原则
- 仅授予必要的推送权限
- 定期审查访问日志
- 启用两步验证

### 4. 私有仓库

**Docker Hub**:
- 考虑使用私有仓库
- 控制镜像访问权限

**阿里云**:
- 设置仓库为私有
- 配置访问白名单

## 📚 参考命令

### Docker 登录管理

```bash
# 登录 Docker Hub
docker login

# 使用 Token 登录
echo "TOKEN" | docker login -u username --password-stdin

# 登录阿里云
docker login registry.cn-hangzhou.aliyuncs.com

# 登出
docker logout
docker logout registry.cn-hangzhou.aliyuncs.com

# 查看登录信息
cat ~/.docker/config.json
```

### 镜像管理

```bash
# 查看本地镜像
docker images | grep freeswitch

# 查看镜像详情
docker inspect bytedesk/freeswitch:1.10.12

# 删除本地镜像
docker rmi bytedesk/freeswitch:1.10.12

# 重新标记镜像
docker tag bytedesk/freeswitch:1.10.12 bytedesk/freeswitch:latest
```

### 推送管理

```bash
# 查看推送进度
# 推送时会显示进度条

# 取消推送
# 使用 Ctrl+C

# 重新推送
./push.sh 1.10.12
```

## 🎯 最佳实践

### 1. 版本管理

- 使用语义化版本号（如 `1.10.12`）
- 每次构建打两个标签：版本号和 `latest`
- 生产环境使用具体版本号，不要使用 `latest`

### 2. 推送策略

- 开发环境：推送到单个镜像仓库测试
- 测试环境：推送到两个镜像仓库验证
- 生产环境：确认测试通过后推送

### 3. 镜像选择

- **中国大陆用户**: 优先使用阿里云镜像
- **国际用户**: 优先使用 Docker Hub
- **企业用户**: 考虑自建私有镜像仓库

### 4. 自动化

- 使用 GitHub Actions 自动推送
- 集成 CI/CD 流程
- 设置推送钩子和通知

## 📖 相关文档

- [构建脚本说明](./README.md#构建镜像)
- [Docker Hub 文档](https://docs.docker.com/docker-hub/)
- [阿里云镜像服务文档](https://help.aliyun.com/product/60716.html)
- [GitHub Actions 工作流](../../.github/workflows/freeswitch-docker.yml)

## 🆘 获取帮助

如有问题：

1. 查看脚本输出的错误信息
2. 检查登录状态和权限
3. 参考常见问题章节
4. 提交 GitHub Issue
5. 联系技术支持: support@bytedesk.com

---

**文档版本**: 1.0  
**最后更新**: 2025-01-07  
**适用版本**: FreeSWITCH 1.10.12+
