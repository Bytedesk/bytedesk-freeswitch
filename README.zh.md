# 微语 freeswitch docker 镜像

## 工作流概览

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
  -e FREESWITCH_ESL_PASSWORD=password \
  bytedesk/freeswitch:latest
```

## 自定义配置文件

容器内置的 FreeSWITCH 配置位于 `/usr/local/freeswitch/conf`。如需加载自定义 XML 文件，可按以下步骤操作：

1. 在宿主机准备配置目录（可从默认配置复制一份作为起点）：

   ```bash
   mkdir -p ./freeswitch-conf
   docker run --rm bytedesk/freeswitch:latest \
     tar -C /usr/local/freeswitch/conf -cf - . | tar -C ./freeswitch-conf -xf -
   ```

2. 在本地编辑 XML 文件，常见修改点包括：
   - `vars.xml`、`sip_profiles/internal.xml`：SIP 域名、端口、编解码设置
   - `autoload_configs/switch.conf.xml`：核心参数（RTP 端口、核心数据库等）
   - `autoload_configs/db.conf.xml`、`autoload_configs/odbc.conf.xml`：`mod_mariadb` / ODBC 数据源配置

3. 运行容器时挂载该目录，即可让 FreeSWITCH 使用自定义配置：

   ```bash
   docker run -d \
     --name freeswitch-bytedesk \
     -v $(pwd)/freeswitch-conf:/usr/local/freeswitch/conf \
     -p 5060:5060/tcp -p 5060:5060/udp \
     -p 8021:8021 \
     -e FREESWITCH_ESL_PASSWORD=password \
     bytedesk/freeswitch:latest
   ```

> ℹ️ 镜像中还保留了 `/usr/local/freeswitch/etc/freeswitch`（源于上游安装目录），但实际运行仅读取 `/usr/local/freeswitch/conf`。我们已在 `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest` 镜像中核实，请在挂载或编辑自定义配置时始终使用 `/usr/local/freeswitch/conf`。

### 使用环境变量覆盖数据库连接

如果仅需保留镜像内的配置而替换数据库连接信息，可在启动容器时设置以下环境变量。启动脚本会自动重写 `switch.conf.xml`、`db.conf.xml` 与 `odbc.conf.xml` 中的 DSN：

| 环境变量 | 说明 | 默认值 |
|----------|------|--------|
| `FREESWITCH_DB_HOST` | 数据库主机（设置后触发重写） | - |
| `FREESWITCH_DB_NAME` | 数据库名称 | - |
| `FREESWITCH_DB_USER` | 数据库用户 | `root` |
| `FREESWITCH_DB_PASSWORD` | 数据库密码 | 空 |
| `FREESWITCH_DB_PORT` | 数据库端口 | `3306` |
| `FREESWITCH_DB_CHARSET` | ODBC 连接字符集 | `utf8mb4` |
| `FREESWITCH_DB_SCHEME` | 核心数据库协议（`mariadb`、`mysql`、`pgsql` 等） | `mariadb` |
| `FREESWITCH_DB_ODBC_DIALECT` | ODBC 前缀（`mysql`/`mariadb`） | `mysql` |

示例：

```bash
docker run -d \
  --name freeswitch-bytedesk \
  -e FREESWITCH_DB_HOST=db.internal \
  -e FREESWITCH_DB_NAME=freeswitch_prod \
  -e FREESWITCH_DB_USER=fs_user \
  -e FREESWITCH_DB_PASSWORD=secret \
  -e FREESWITCH_DB_PORT=3307 \
  -e FREESWITCH_DB_SCHEME=mariadb \
  -e FREESWITCH_DB_ODBC_DIALECT=mariadb \
  bytedesk/freeswitch:latest
```

容器启动后，可在挂载目录中查看 `autoload_configs/*.xml`，确认 DSN 已按环境变量更新。

### Docker Compose 示例

如果希望通过 Docker Compose 统一管理服务，可参考以下示例：

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
      FREESWITCH_ESL_PASSWORD: bytedesk123
      FREESWITCH_DB_HOST: db.example.com
      FREESWITCH_DB_NAME: freeswitch
      FREESWITCH_DB_USER: fs_user
      FREESWITCH_DB_PASSWORD: fs_secret
      TZ: Asia/Shanghai
    volumes:
      - ./freeswitch-conf:/usr/local/freeswitch/conf
      - freeswitch-log:/usr/local/freeswitch/log
      - freeswitch-db:/usr/local/freeswitch/db
      - freeswitch-recordings:/usr/local/freeswitch/recordings
    healthcheck:
      test: ["CMD", "fs_cli", "-p", "bytedesk123", "-x", "status"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  freeswitch-log:
  freeswitch-db:
  freeswitch-recordings:
```

将上述内容保存为 `docker-compose.yml`，执行 `docker compose up -d` 即可启动。若自定义了配置目录或数据库参数，请同步调整 `volumes` 与 `environment` 中的路径与变量。
示例中假设已有可访问的 MariaDB/MySQL 服务（域名为 `db.example.com`），实际使用时请替换为真实的数据库地址与凭据。

