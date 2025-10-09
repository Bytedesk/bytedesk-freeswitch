# 微语 FreeSWITCH Docker 镜像

[![Docker Hub](https://img.shields.io/docker/v/bytedesk/freeswitch?label=Docker%20Hub)](https://hub.docker.com/r/bytedesk/freeswitch)
[![Docker Pulls](https://img.shields.io/docker/pulls/bytedesk/freeswitch)](https://hub.docker.com/r/bytedesk/freeswitch)
[![License](https://img.shields.io/github/license/Bytedesk/bytedesk-freeswitch)](LICENSE)

微语呼叫中心系统的 FreeSWITCH 1.10.12 Docker 镜像，基于 Ubuntu 22.04 LTS。

## 🚨 安全警告

> **⚠️ 重要：在生产环境部署前必须修改默认密码！**
> 
> 本镜像包含以下需要修改的默认密码：
> 1. **ESL 密码**: 通过 `FREESWITCH_ESL_PASSWORD` 环境变量设置（必填）
> 2. **SIP 用户密码**: 通过 `FREESWITCH_DEFAULT_PASSWORD` 环境变量设置（默认为 `1234`）
> 
> **不修改默认密码将导致严重的安全风险：**
> - 未授权访问您的电话系统
> - 话费欺诈（Toll Fraud）
> - 通话记录泄露
> - 系统被用于非法呼叫
> 
> 📖 详细安全配置请查看 [安全建议](#安全建议) 部分

## 📑 目录

- [快速开始](#快速开始)
- [功能特性](#功能特性)
- [安装方式](#安装方式)
- [配置说明](#配置说明)
- [环境变量](#环境变量)
- [端口说明](#端口说明)
- [安全建议](#安全建议)
- [从源码构建](#从源码构建)
- [CI/CD 工作流](#cicd-工作流)
- [文档](#文档)
- [技术支持](#技术支持)

## 快速开始

### 拉取并运行（开发环境）

```bash
# 从 Docker Hub 拉取
docker pull bytedesk/freeswitch:latest

# 从阿里云拉取（中国大陆推荐）
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest

# 运行容器
docker run -d \
  --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD='dev_esl_pass_123' \
  -e FREESWITCH_DEFAULT_PASSWORD='dev_sip_pass_123' \
  bytedesk/freeswitch:latest
```

### 生产环境部署

```bash
docker run -d \
  --name freeswitch-prod \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021 \
  -p 7443:7443 \
  -p 16384-32768:16384-32768/udp \
  -e FREESWITCH_ESL_PASSWORD='您的强ESL密码' \
  -e FREESWITCH_DEFAULT_PASSWORD='您的强SIP密码' \
  -e FREESWITCH_DOMAIN=sip.yourdomain.com \
  -e FREESWITCH_EXTERNAL_IP=您的公网IP \
  -e TZ=Asia/Shanghai \
  -v freeswitch_data:/usr/local/freeswitch \
  --restart=unless-stopped \
  bytedesk/freeswitch:latest
```

## 功能特性

- ✅ FreeSWITCH 1.10.12 稳定版
- ✅ 基于 Ubuntu 22.04 LTS
- ✅ 包含 mod_mariadb 模块
- ✅ 支持 MySQL/MariaDB 数据库
- ✅ 支持 WebRTC（通过 SIP.js + mod_sofia）
- ✅ 支持视频通话（VP8/VP9/H264）
- ✅ 包含基础音频文件（8kHz）
- ✅ 支持 SIP TLS 加密
- ✅ 内置健康检查
- ✅ 环境变量配置
- ✅ 支持多架构（amd64/arm64）
- ❌ mod_verto 已禁用（改用 SIP over WebSocket）

## CI/CD 工作流概览

本项目使用多个独立的 GitHub Actions 工作流来实现 CI/CD 流程：

### 1. freeswitch-docker.yml - FreeSWITCH 镜像构建工作流

**触发条件：**

- 推送以 `freeswitch-v` 开头的标签（例如：`freeswitch-v0.0.8`）
- 手动触发（支持自定义版本号）
- `docker/` 目录变更

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
推送标签 freeswitch-v0.0.8
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

## 安装方式

### 方式一：Docker Run

参见上方 [快速开始](#快速开始) 部分。

### 方式二：Docker Compose

创建 `docker-compose.yml` 文件：

```yaml
version: "3.9"

services:
  freeswitch:
    image: bytedesk/freeswitch:latest
    container_name: freeswitch-bytedesk
    restart: unless-stopped
    ports:
      - "5060:5060/tcp"
      - "5060:5060/udp"
      - "5080:5080/tcp"
      - "5080:5080/udp"
      - "8021:8021"
      - "7443:7443"
      - "16384-32768:16384-32768/udp"
    environment:
      FREESWITCH_ESL_PASSWORD: ${ESL_PASSWORD}
      FREESWITCH_DEFAULT_PASSWORD: ${SIP_PASSWORD}
      FREESWITCH_DOMAIN: ${DOMAIN}
      FREESWITCH_EXTERNAL_IP: ${EXTERNAL_IP}
      TZ: Asia/Shanghai
    volumes:
      - freeswitch-log:/usr/local/freeswitch/log
      - freeswitch-db:/usr/local/freeswitch/db
      - freeswitch-recordings:/usr/local/freeswitch/recordings
    healthcheck:
      test: ["CMD", "fs_cli", "-p", "${ESL_PASSWORD}", "-x", "status"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  freeswitch-log:
  freeswitch-db:
  freeswitch-recordings:
```

创建 `.env` 文件（从 `docker/.env.example` 复制）：

```bash
ESL_PASSWORD=MyStr0ng#ESL!Pass2024
SIP_PASSWORD=MyStr0ng#SIP!Pass2024
DOMAIN=sip.company.com
EXTERNAL_IP=203.0.113.10
```

启动容器：

```bash
docker compose up -d
```

## 配置说明

### 自定义配置文件

#### 重要：配置文件路径说明

**FreeSWITCH 实际使用的配置路径**: `/usr/local/freeswitch/etc/freeswitch`

容器内虽然同时存在两个配置目录：
- `/usr/local/freeswitch/etc/freeswitch` - ✅ **运行时实际使用**（正确的挂载路径）
- `/usr/local/freeswitch/conf` - ❌ 备用目录（不被FreeSWITCH进程读取）

**验证方法**：
```bash
# 在容器内验证当前使用的配置路径
docker exec -it freeswitch-container fs_cli -p YOUR_ESL_PASSWORD -x 'global_getvar conf_dir'
# 输出: /usr/local/freeswitch/etc/freeswitch
```

#### 配置自定义XML文件步骤

1. **导出默认配置：**

   ```bash
   mkdir -p ./freeswitch-conf
   docker run --rm bytedesk/freeswitch:latest \
     tar -C /usr/local/freeswitch/etc/freeswitch -cf - . | tar -C ./freeswitch-conf -xf -
   ```

2. **在本地编辑 XML 文件：**
   - `vars.xml` & `sip_profiles/internal.xml` - SIP 域名、端口、编解码
   - `autoload_configs/switch.conf.xml` - RTP 端口、核心数据库
   - `autoload_configs/db.conf.xml` & `autoload_configs/odbc.conf.xml` - 数据库 DSN
   - `autoload_configs/event_socket.conf.xml` - ESL配置

3. **挂载自定义配置（使用正确路径）：**

   ```bash
   docker run -d \
     --name freeswitch \
     -v $(pwd)/freeswitch-conf:/usr/local/freeswitch/etc/freeswitch \
     -p 5060:5060/tcp -p 5060:5060/udp \
     -p 8021:8021 \
     -e FREESWITCH_ESL_PASSWORD=password \
     bytedesk/freeswitch:latest
   ```

> ⚠️ **关键提示**: 
> - 必须挂载到 `/usr/local/freeswitch/etc/freeswitch` 路径，这是FreeSWITCH运行时实际读取的配置目录
> - 如果挂载到 `/usr/local/freeswitch/conf` 路径，FreeSWITCH将无法读取自定义配置，可能导致ESL连接失败等问题
> - 使用 `fs_cli -x 'global_getvar conf_dir'` 命令可验证当前配置路径

## 环境变量

### 核心配置

| 变量名 | 说明 | 默认值 | 必填 | 安全等级 |
|--------|------|--------|------|----------|
| `FREESWITCH_ESL_PASSWORD` | ESL 管理密码 | - | ✅ 是 | 🔴 高 |
| `FREESWITCH_DEFAULT_PASSWORD` | SIP 用户默认密码 | `1234` | ⚠️ 强烈建议 | 🔴 高 |
| `FREESWITCH_DOMAIN` | SIP 域名或 IP 地址 | - | 否 | 🟡 中 |
| `FREESWITCH_EXTERNAL_IP` | NAT 穿透外部 IP | - | 否 | 🟢 低 |
| `TZ` | 时区设置 | `Asia/Shanghai` | 否 | 🟢 低 |

### RTP 媒体配置

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `FREESWITCH_RTP_START` | RTP 起始端口 | `16384` | 否 |
| `FREESWITCH_RTP_END` | RTP 结束端口 | `32768` | 否 |

### 数据库配置

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `FREESWITCH_DB_HOST` | 数据库主机 | - | 否 |
| `FREESWITCH_DB_NAME` | 数据库名称 | - | 否 |
| `FREESWITCH_DB_USER` | 数据库用户 | `root` | 否 |
| `FREESWITCH_DB_PASSWORD` | 数据库密码 | - | 否 |
| `FREESWITCH_DB_PORT` | 数据库端口 | `3306` | 否 |
| `FREESWITCH_DB_CHARSET` | 数据库字符集 | `utf8mb4` | 否 |
| `FREESWITCH_DB_SCHEME` | 核心数据库连接协议 | `mariadb` | 否 |
| `FREESWITCH_DB_ODBC_DIALECT` | ODBC 连接方言 | `mysql` | 否 |

### 配置示例

**开发环境：**
```bash
docker run -d \
  -e FREESWITCH_ESL_PASSWORD=dev123 \
  -e FREESWITCH_DEFAULT_PASSWORD=test1234 \
  bytedesk/freeswitch:latest
```

**生产环境（带数据库）：**
```bash
docker run -d \
  -e FREESWITCH_ESL_PASSWORD='MyStr0ng#ESL!Pass2024' \
  -e FREESWITCH_DEFAULT_PASSWORD='MyStr0ng#SIP!Pass2024' \
  -e FREESWITCH_DOMAIN=sip.company.com \
  -e FREESWITCH_EXTERNAL_IP=203.0.113.10 \
  -e FREESWITCH_DB_HOST=mysql.internal \
  -e FREESWITCH_DB_NAME=freeswitch \
  -e FREESWITCH_DB_USER=fsuser \
  -e FREESWITCH_DB_PASSWORD='db_secure_pass' \
  bytedesk/freeswitch:latest
```

## 端口说明

### 必需端口

| 端口 | 协议 | 说明 |
|------|------|------|
| 5060 | TCP/UDP | SIP 内部 |
| 5080 | TCP/UDP | SIP 外部 |
| 8021 | TCP | ESL 管理 |
| 7443 | TCP | WebRTC WSS |
| 16384-32768 | UDP | RTP 媒体 |

### 可选端口

| 端口 | 协议 | 说明 |
|------|------|------|
| 5061 | TCP | SIP 内部 TLS |
| 5081 | TCP | SIP 外部 TLS |
| 5066 | TCP | WebSocket 信令 |
| 3478-3479 | UDP | STUN 服务 |

## 安全建议

### 密码安全

1. **修改 ESL 密码（必须）**
   - 至少 16 个字符
   - 包含大小写字母、数字和特殊字符
   - 不要使用字典单词

2. **修改 SIP 默认密码（强烈建议）**
   - 默认为 `1234` - 极度脆弱
   - 影响用户 1000-1019、1001-brian、1002-admin
   - 使用强密码：至少 12 个字符

3. **密码强度示例：**
   ```
   ❌ 弱: 123456, password, 1234
   ⚠️ 中等: test1234, freeswitch123
   ✅ 强: Fs#2024@Secure!Pass, MyPbx$Str0ng#2024
   ```

### 生产环境检查清单

部署到生产环境前：

- [ ] 已修改 `FREESWITCH_ESL_PASSWORD`
- [ ] 已修改 `FREESWITCH_DEFAULT_PASSWORD`
- [ ] 已配置 `FREESWITCH_EXTERNAL_IP`
- [ ] 已配置防火墙规则
- [ ] 已启用 SIP TLS（端口 5061, 5081）
- [ ] 已启用 SRTP 加密
- [ ] 已配置 ACL 访问控制
- [ ] 已设置日志监控
- [ ] 已配置备份策略
- [ ] 已限制不必要的端口暴露
- [ ] 已配置 fail2ban 或类似工具
- [ ] 已审查默认用户配置

📖 **详细安全配置请参见 [docker/SECURITY.md](docker/SECURITY.md)**

## 从源码构建

### 前置要求

- 已安装 Docker 和 Docker Compose
- 已安装 Git

### 构建步骤

1. **克隆仓库：**

   ```bash
   git clone https://github.com/Bytedesk/bytedesk-freeswitch.git
   cd bytedesk-freeswitch
   ```

2. **构建镜像：**

   ```bash
   cd docker
   ./build.sh 1.10.12
   ```

   或手动构建：

   ```bash
   docker build -t bytedesk/freeswitch:1.10.12 .
   ```

3. **测试镜像：**

   ```bash
   docker run -d \
     --name freeswitch-test \
     -e FREESWITCH_ESL_PASSWORD=test123 \
     bytedesk/freeswitch:1.10.12
   
   # 查看日志
   docker logs freeswitch-test
   
   # 测试 CLI 访问
   docker exec -it freeswitch-test fs_cli -p test123
   ```

更多详情请参见 [docker/BUILD_AND_DEPLOY.md](docker/BUILD_AND_DEPLOY.md)

## CI/CD 工作流

### 发布流程

#### 1. 创建新版本标签

```bash
# 创建新标签
git tag v1.0.0

# 推送标签
git push origin v1.0.0
```

#### 2. 监控部署状态

在 GitHub 仓库的 Actions 页面查看工作流执行状态。

### FreeSWITCH 镜像发布流程

#### 1. 创建 FreeSWITCH 镜像版本

```bash
# 创建 FreeSWITCH 标签
git tag freeswitch-v0.0.8

# 推送标签
git push origin freeswitch-v0.0.8
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
docker pull bytedesk/freeswitch:latest

# 从阿里云拉取（中国大陆推荐）
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest

# 运行容器
docker run -d \
  --name freeswitch-bytedesk \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD='strong_password' \
  -e FREESWITCH_DEFAULT_PASSWORD='strong_sip_password' \
  bytedesk/freeswitch:latest
```

## 测试验证

### 1. 检查容器状态

```bash
docker ps | grep freeswitch
```

### 2. 查看日志

```bash
# 实时日志
docker logs -f freeswitch

# 最近 100 行
docker logs --tail 100 freeswitch
```

### 3. 访问 FreeSWITCH CLI

```bash
docker exec -it freeswitch fs_cli -p 您的ESL密码
```

### 4. 使用 SIP 客户端测试

使用 [LinPhone](https://www.linphone.org/en/download/) 或 [Zoiper](https://www.zoiper.com/)：

**配置参数：**
- **用户名**: 1000（或 1001-1019）
- **密码**: 您的 `FREESWITCH_DEFAULT_PASSWORD` 值
- **域名**: 您的 FreeSWITCH 服务器地址
- **传输**: UDP (5060) 或 TCP (5060)

**测试分机：**
- **9196**: 回音测试（无延迟）
- **9195**: 回音测试（5秒延迟）
- **9664**: 保持音乐

### 5. 验证配置路径

如果遇到配置相关问题（例如 ESL 连接失败），请验证配置路径：

```bash
# 运行验证脚本
./docker/verify_config_path.sh
```

这将确认 FreeSWITCH 实际使用的配置目录并提供挂载建议。

## 文档

### 主要文档

- **[安全指南](docker/SECURITY.md)** - 🔒 详细的安全配置（必读）
- **[Docker 文档](docker/README.md)** - 🐳 Docker 相关文档和快速链接

### 工具脚本

- **[配置路径验证脚本](docker/verify_config_path.sh)** - 自动验证配置路径的工具

### 配置文件

- **[Dockerfile](docker/Dockerfile)** - Docker 镜像构建文件
- **[docker-entrypoint.sh](docker/docker-entrypoint.sh)** - 容器启动脚本
- **[docker-compose.yml](docker/docker-compose.yml)** - Docker Compose 配置
- **[.env.example](docker/.env.example)** - 环境变量模板

### 外部资源

- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [FreeSWITCH 安全最佳实践](https://freeswitch.org/confluence/display/FREESWITCH/Security)
- [Docker Hub - bytedesk/freeswitch](https://hub.docker.com/r/bytedesk/freeswitch)
- [阿里云镜像仓库](https://cr.console.aliyun.com/repository/cn-hangzhou/bytedesk/freeswitch)
- [微语官方文档](https://docs.bytedesk.com/)

## 故障排查

### 容器无法启动

1. 查看日志：`docker logs freeswitch`
2. 验证端口可用性
3. 检查配置文件
4. 验证权限

### 无法连接 ESL

1. 验证端口 8021 已暴露
2. 检查 ESL 密码
3. 查看防火墙设置
4. **验证配置路径**：运行 `./docker/verify_config_path.sh` 确保挂载到正确的路径（`/usr/local/freeswitch/etc/freeswitch`）

### 音频问题

1. 验证 RTP 端口范围（16384-32768）已开放
2. 检查 NAT 配置
3. 验证 `FREESWITCH_EXTERNAL_IP` 设置正确

### 认证失败

1. 验证 `FREESWITCH_DEFAULT_PASSWORD` 已设置
2. 检查 `/usr/local/freeswitch/conf/directory` 中的用户配置
3. 查看 SIP 客户端设置

更多问题请参见 [docker/README.md](docker/README.md) 或在 GitHub 创建 Issue。

## 贡献

欢迎贡献！请：

1. Fork 仓库
2. 创建功能分支
3. 提交更改
4. 提交 Pull Request

## 许可证

本项目采用 [LICENSE](LICENSE) 文件中指定的许可证。

## 技术支持

- **邮箱**: 270580156@qq.com
- **GitHub Issues**: https://github.com/Bytedesk/bytedesk-freeswitch/issues
- **文档**: https://docs.bytedesk.com/

---

**维护者**: [微语](https://bytedesk.com)  
**最后更新**: 2025-10-09

