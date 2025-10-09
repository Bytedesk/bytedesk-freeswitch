# FreeSWITCH Docker Build and Deployment

## 简介

本目录包含 FreeSWITCH 1.10.12 的 Docker 镜像构建文件，用于 ByteDesk 呼叫中心系统。

## 目录结构

```
docker/
├── Dockerfile              # Docker 镜像构建文件
├── docker-entrypoint.sh   # 容器启动脚本
├── .dockerignore          # Docker 构建忽略文件
├── docker-compose.yml     # 单独运行的 Docker Compose 配置
├── build.sh               # 构建脚本
├── push.sh                # 推送脚本
└── conf/                  # FreeSWITCH 配置文件目录
    └── (从 /usr/local/freeswitch/conf 复制配置文件)
```

## 前置准备

1. **准备配置文件**

   在构建镜像前，需要准备 FreeSWITCH 的配置文件。您可以：
   
   - 从已安装的 FreeSWITCH 复制配置：
     ```bash
     cp -r /usr/local/freeswitch/conf ./conf
     ```
   
   - 或使用 FreeSWITCH 默认配置（构建时会自动生成）

2. **安装 Docker**

   确保已安装 Docker 和 Docker Compose：
   ```bash
   docker --version
   docker-compose --version
   ```

## 构建镜像

### 方法一：使用构建脚本（推荐）

```bash
# 赋予执行权限
chmod +x build.sh

# 构建镜像
./build.sh

# 构建并指定版本
./build.sh 1.10.12
```

### 方法二：手动构建

```bash
# 基础构建
docker build -t bytedesk/freeswitch:1.10.12 .

# 构建最新版本标签
docker build -t bytedesk/freeswitch:latest .

# 同时构建多个标签
docker build -t bytedesk/freeswitch:1.10.12 -t bytedesk/freeswitch:latest .
```

### 构建参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| FREESWITCH_VERSION | FreeSWITCH 版本 | v1.10.12 |
| FREESWITCH_PREFIX | 安装路径 | /usr/local/freeswitch |

使用构建参数：
```bash
docker build --build-arg FREESWITCH_VERSION=v1.10.11 -t bytedesk/freeswitch:1.10.11 .
```

## 推送镜像到镜像仓库

### 支持的镜像仓库

- **Docker Hub**: `bytedesk/freeswitch`
- **阿里云**: `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch`

### 方法一：使用推送脚本（推荐）

#### 推送到所有镜像仓库

```bash
# 赋予执行权限
chmod +x push.sh

# 推送到 Docker Hub 和阿里云
./push.sh 1.10.12

# 或使用默认版本
./push.sh
```

#### 仅推送到 Docker Hub

```bash
./push.sh 1.10.12 dockerhub
```

#### 仅推送到阿里云

```bash
./push.sh 1.10.12 aliyun
```

### 方法二：使用 Makefile

```bash
# 推送到所有镜像仓库
make push

# 仅推送到 Docker Hub
make push-dockerhub

# 仅推送到阿里云
make push-aliyun
```

### 方法三：手动推送

#### 登录镜像仓库

```bash
# 登录 Docker Hub
docker login

# 登录阿里云
docker login registry.cn-hangzhou.aliyuncs.com

#### 推送到 Docker Hub

```bash
# 推送指定版本
docker push bytedesk/freeswitch:1.10.12

# 推送最新版本
docker push bytedesk/freeswitch:latest
```

#### 推送到阿里云

```bash
# 推送指定版本
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12

# 推送最新版本
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest
```

> **详细推送指南**: 请参考 [PUSH_GUIDE.md](./PUSH_GUIDE.md) 获取更多推送相关的详细说明。
```

## 运行容器

### 快速启动（单独运行）

```bash
docker run -d \
  --name freeswitch-bytedesk \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021 \
  -p 7443:7443 \
  -p 16384-32768:16384-32768/udp \
  -e FREESWITCH_ESL_PASSWORD=bytedesk123 \
  -e FREESWITCH_DOMAIN=your-domain.com \
  -e TZ=Asia/Shanghai \
  bytedesk/freeswitch:1.10.12
```

### 使用 Docker Compose（单独运行）

```bash
# 启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止
docker-compose down
```

### 在 ByteDesk Compose 中使用

编辑 `starter/src/main/resources/compose.yaml`，取消注释 FreeSWITCH 服务：

```yaml
services:
  bytedesk-freeswitch:
    image: bytedesk/freeswitch:1.10.12
    container_name: freeswitch-bytedesk
    restart: always
    ports:
      - "15060:5060/tcp"
      - "15060:5060/udp"
      - "15080:5080/tcp"
      - "15080:5080/udp"
      - "8021:8021"
      - "17443:7443"
      - "15066:5066"
      - "16000-16129:16000-16129/udp"
    environment:
      - FREESWITCH_ESL_PASSWORD=bytedesk123
      - FREESWITCH_DOMAIN=your-domain.com
      - FREESWITCH_EXTERNAL_IP=your-public-ip
      - TZ=Asia/Shanghai
    volumes:
      - freeswitch_data:/usr/local/freeswitch
    networks:
      - bytedesk-network
    healthcheck:
      test: ["CMD", "fs_cli", "-p", "bytedesk123", "-x", "status"]
      interval: 30s
      timeout: 10s
      retries: 5
```

## 环境变量配置

| 环境变量 | 说明 | 默认值 | 必填 |
|----------|------|--------|------|
| FREESWITCH_ESL_PASSWORD | ESL 连接密码 | - | 是 |
| FREESWITCH_DOMAIN | SIP 域名 | - | 否 |
| FREESWITCH_EXTERNAL_IP | 外部 IP 地址（NAT） | - | 否 |
| FREESWITCH_RTP_START | RTP 起始端口 | 16384 | 否 |
| FREESWITCH_RTP_END | RTP 结束端口 | 32768 | 否 |
| FREESWITCH_DB_HOST | 数据库主机 | - | 否 |
| FREESWITCH_DB_NAME | 数据库名称 | - | 否 |
| FREESWITCH_DB_USER | 数据库用户 | root | 否 |
| FREESWITCH_DB_PASSWORD | 数据库密码 | - | 否 |
| FREESWITCH_DB_PORT | 数据库端口 | 3306 | 否 |
| FREESWITCH_DB_CHARSET | 数据库字符集（ODBC 连接） | utf8mb4 | 否 |
| FREESWITCH_DB_SCHEME | 核心数据库连接协议（mariadb/mysql/pgsql 等） | mariadb | 否 |
| FREESWITCH_DB_ODBC_DIALECT | ODBC 连接前缀（mysql/mariadb） | mysql | 否 |
| TZ | 时区 | Asia/Shanghai | 否 |

> **提示**：当设置 `FREESWITCH_DB_HOST` 与 `FREESWITCH_DB_NAME` 时，容器启动脚本会自动重写 `switch.conf.xml`、`db.conf.xml` 与 `odbc.conf.xml` 中的 DSN 配置，确保 `mod_mariadb`、核心数据库及其他 ODBC 消费者均连接到外部数据库。可以配合 `FREESWITCH_DB_USER`、`FREESWITCH_DB_PASSWORD`、`FREESWITCH_DB_CHARSET` 等变量实现完全自定义的连接信息。

## 端口说明

### 必需开放的端口

| 端口 | 协议 | 说明 |
|------|------|------|
| 5060 | TCP/UDP | SIP 内部端口 |
| 5080 | TCP/UDP | SIP 外部端口 |
| 8021 | TCP | ESL 管理端口 |
| 7443 | TCP | WebRTC WSS |
| 16384-32768 | UDP | RTP 媒体流 |

### 可选端口

| 端口 | 协议 | 说明 |
|------|------|------|
| 5061 | TCP | SIP 内部 TLS |
| 5081 | TCP | SIP 外部 TLS |
| 5066 | TCP | WebSocket 信令 |
| 3478-3479 | UDP | STUN 服务 |
| 8081-8082 | TCP | HTTP 服务 |

## 数据持久化

建议挂载以下目录到宿主机：

```bash
docker run -d \
  -v freeswitch_conf:/usr/local/freeswitch/conf \
  -v freeswitch_log:/usr/local/freeswitch/log \
  -v freeswitch_db:/usr/local/freeswitch/db \
  -v freeswitch_recordings:/usr/local/freeswitch/recordings \
  bytedesk/freeswitch:1.10.12
```

## 容器管理

### 查看日志

```bash
# 实时日志
docker logs -f freeswitch-bytedesk

# 最近 100 行
docker logs --tail 100 freeswitch-bytedesk
```

### 进入容器

```bash
# 进入容器 shell
docker exec -it freeswitch-bytedesk bash

# 连接 FreeSWITCH CLI
docker exec -it freeswitch-bytedesk fs_cli -p bytedesk123
```

### 重启容器

```bash
docker restart freeswitch-bytedesk
```

### 停止容器

```bash
docker stop freeswitch-bytedesk
```

### 删除容器

```bash
docker rm -f freeswitch-bytedesk
```

## 健康检查

容器内置健康检查，每 30 秒检查一次 FreeSWITCH 状态：

```bash
# 查看健康状态
docker inspect --format='{{.State.Health.Status}}' freeswitch-bytedesk
```

## 测试验证

### 1. 检查容器状态

```bash
docker ps | grep freeswitch
```

### 2. 测试 ESL 连接

```bash
telnet localhost 8021
```

### 3. 使用 SIP 客户端测试

使用 [LinPhone](https://www.linphone.org/en/download/) 等 SIP 客户端连接测试：

- Username: 1000
- Password: 1234
- Domain: 容器 IP 或域名
- Transport: UDP

### 4. 拨打测试号码

- **9196**: 回音测试（无延迟）
- **9195**: 回音测试（延迟 5 秒）
- **9664**: 保持音乐

## 性能优化

### 资源限制

```bash
docker run -d \
  --cpus="2" \
  --memory="2g" \
  --memory-swap="2g" \
  bytedesk/freeswitch:1.10.12
```

### 日志大小限制

```yaml
services:
  bytedesk-freeswitch:
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

## 故障排查

### 问题 1: 容器启动失败

**检查日志**:
```bash
docker logs freeswitch-bytedesk
```

**常见原因**:
- 端口被占用
- 配置文件错误
- 权限问题

### 问题 2: 无法连接 ESL

**检查**:
1. 端口是否开放
2. ESL 密码是否正确
3. 防火墙设置

### 问题 3: 音频问题

**检查**:
1. RTP 端口范围是否开放
2. NAT 配置是否正确
3. 外部 IP 是否设置

## 安全建议

1. **修改默认密码**: 务必修改 ESL 密码
2. **限制访问**: 使用防火墙限制 ESL 端口访问
3. **使用 TLS**: 生产环境启用 SIP TLS
4. **定期更新**: 保持镜像版本更新
5. **监控日志**: 定期检查异常访问

## 生产环境部署

### 1. 使用外部数据库

```yaml
environment:
  - FREESWITCH_DB_HOST=mysql-host
  - FREESWITCH_DB_NAME=freeswitch
  - FREESWITCH_DB_USER=freeswitch
  - FREESWITCH_DB_PASSWORD=secure_password
```

### 2. 配置 NAT 穿透

```yaml
environment:
  - FREESWITCH_EXTERNAL_IP=your-public-ip
```

### 3. 使用负载均衡

建议在 FreeSWITCH 前使用负载均衡器（如 Nginx、HAProxy）。

### 4. 监控告警

集成 Prometheus + Grafana 进行监控。

## 版本历史

| 版本 | 发布日期 | 说明 |
|------|----------|------|
| 1.10.12 | 2025-01-07 | 初始版本，基于 Ubuntu 22.04 |

## 参考链接

- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [Docker Hub](https://hub.docker.com/)
- [ByteDesk 文档](https://docs.bytedesk.com/)

## 支持

如有问题，请提交 Issue 或联系技术支持。

- Email: support@bytedesk.com
- GitHub: https://github.com/Bytedesk/bytedesk
