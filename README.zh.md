# 微语 FreeSWITCH Docker 镜像

[![Docker Hub](https://img.shields.io/docker/v/bytedesk/freeswitch?label=Docker%20Hub)](https://hub.docker.com/r/bytedesk/freeswitch)
[![Docker Pulls](https://img.shields.io/docker/pulls/bytedesk/freeswitch)](https://hub.docker.com/r/bytedesk/freeswitch)
[![License](https://img.shields.io/github/license/Bytedesk/bytedesk-freeswitch)](LICENSE)

微语呼叫中心系统的 FreeSWITCH 1.10.12 Docker 镜像，基于 Ubuntu 22.04 LTS。

## 📑 目录

- [功能特性](#功能特性)
- [安装方式](#安装方式)
- [配置说明](#配置说明)
- [环境变量](#环境变量)
- [端口说明](#端口说明)
- [安全](#安全)
- [文档](#文档)
- [贡献](#贡献)
- [许可证](#许可证)
- [支持](#支持)

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
- ✅ 默认内置 MRCP 客户端支持（已编译并加载 mod_unimrcp）
- ❌ mod_verto 已禁用（改用 SIP over WebSocket）

## 与官方镜像对比

- 官方镜像：safarov/freeswitch — 仅支持 amd64 架构（查看标签 → https://hub.docker.com/r/safarov/freeswitch/tags）
- 本镜像：bytedesk/freeswitch — 同时支持 amd64 与 arm64 多架构（查看标签 → https://hub.docker.com/r/bytedesk/freeswitch/tags）

提示：多架构镜像可在 x86_64 服务器与 Apple Silicon（M1/M2/M3）等 ARM 设备上直接运行，无需手动切换镜像。

## 安装方式

### 方式一：Docker Run

```bash
# 拉取镜像（可二选一）
docker pull bytedesk/freeswitch:latest
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest  # 中国大陆推荐

# 运行容器（统一命令，开发/生产通用，按需调整变量与端口暴露）
docker run -d \
  --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021 \
  -p 7443:7443 \
  -p 16384-32768:16384-32768/udp \
  -e FREESWITCH_ESL_PASSWORD='YOUR_ESL_PASSWORD' \
  -e FREESWITCH_DEFAULT_PASSWORD='YOUR_SIP_PASSWORD' \
  -e FREESWITCH_DOMAIN=sip.yourdomain.com \
  -e FREESWITCH_EXTERNAL_IP=YOUR_PUBLIC_IP \
  -e TZ=Asia/Shanghai \
  -v freeswitch_data:/usr/local/freeswitch \
  # 配置文件目录 - 使用本地配置文件覆盖容器内的配置（经验证实际使用 /usr/local/freeswitch/etc/freeswitch）
  -v ../../../../deploy/freeswitch/conf:/usr/local/freeswitch/etc/freeswitch \
  --restart=unless-stopped \
  bytedesk/freeswitch:latest
```

### 方式二：Docker Compose

#### 单一示例（可选自定义配置）

创建 `docker-compose.yml` 文件（如需自定义配置，取消注释挂载行）：

```yaml
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
      # 可选：挂载自定义配置目录（实际运行路径：/usr/local/freeswitch/etc/freeswitch）
      # - ./freeswitch-conf:/usr/local/freeswitch/etc/freeswitch
      # 也可按项目结构改为：
      # - ../../../../deploy/freeswitch/conf:/usr/local/freeswitch/etc/freeswitch
      # 数据持久化
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

说明：当需要加载本地自定义配置时，取消注释自定义配置挂载行，确保目标路径为 `/usr/local/freeswitch/etc/freeswitch`，这是 FreeSWITCH 实际读取的配置目录。

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
### MRCP（mod_unimrcp）快速说明

- 镜像已默认编译并加载 `mod_unimrcp`
- 客户端 Profile：`conf/mrcp_profiles/baidu.xml`（请将 `server-ip` 改为你的 MRCP Server）
- 客户端设置：`conf/autoload_configs/unimrcp.conf.xml`（`default-profile=baidu`）
- 验证模块：`fs_cli -x "show modules | grep unimrcp"` 应看到 `mod_unimrcp`

拨号计划示例：

```xml
<extension name="baidu_asr_test">
  <condition field="destination_number" expression="^9001$">
    <action application="answer"/>
    <action application="sleep" data="1000"/>
    <action application="speak" data="请说话"/>
    <action application="play_and_detect_speech"
            data="silence_stream://2000 mrcp:baidu {start-input-timers=false}builtin:grammar/boolean grammar.xml"/>
    <action application="log" data="INFO 识别结果: ${detect_speech_result}"/>
  </condition>
</extension>
```


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
