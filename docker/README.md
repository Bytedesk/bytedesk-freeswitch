# FreeSWITCH Docker

> 📖 **主要文档已移至项目根目录**  
> 请查看 [../README.md](../README.md) 或 [../README.zh.md](../README.zh.md) 获取完整的使用说明。

## 快速链接

### 📚 文档

- **[主 README (English)](../README.md)** - 完整的英文文档
- **[主 README (中文)](../README.zh.md)** - 完整的中文文档
- **[安全配置指南](./SECURITY.md)** - 详细的安全配置（必读）
- **[配置路径指南](./CONFIG_PATH_GUIDE.md)** - 配置路径验证和故障排查

### 🚀 快速开始

```bash
# 拉取镜像
docker pull bytedesk/freeswitch:latest

# 运行容器（开发环境）
docker run -d \
  --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD='dev_esl_pass' \
  -e FREESWITCH_DEFAULT_PASSWORD='dev_sip_pass' \
  bytedesk/freeswitch:latest
```

### 🔒 安全警告

⚠️ **必须修改默认密码！** 查看 [SECURITY.md](./SECURITY.md)

- `FREESWITCH_ESL_PASSWORD` - ESL 管理密码（必填）
- `FREESWITCH_DEFAULT_PASSWORD` - SIP 用户密码（默认 `1234`，必须修改）

### � 配置路径验证工具

```bash
# 验证 FreeSWITCH 实际使用的配置路径
./docker/verify_config_path.sh
```

**重要**: FreeSWITCH 实际使用的配置路径是 `/usr/local/freeswitch/etc/freeswitch`，挂载自定义配置时必须使用此路径。

### 🗄️ 数据库支持

- 支持 MySQL/MariaDB（含 `mod_mariadb`）
- 支持 PostgreSQL（FreeSWITCH 核心在构建时已启用 `--enable-core-pgsql-support`）

如需查看完整数据库环境变量与示例，请参考主文档：[../README.md](../README.md) / [../README.zh.md](../README.zh.md)。

### �📁 目录结构

```bash
docker/
├── README.md                  # 本文件（引导文档）
├── SECURITY.md               # 安全配置指南
├── Dockerfile                 # Docker 镜像构建文件
├── docker-entrypoint.sh       # 容器启动脚本
├── docker-compose.yml         # Docker Compose 配置
├── build.sh                   # 构建脚本
├── push.sh                    # 推送脚本
├── verify_config_path.sh      # 配置路径验证脚本
├── Makefile                   # Make 命令
├── .env.example              # 环境变量示例
└── conf/                     # FreeSWITCH 配置文件
    ├── freeswitch.xml
    ├── vars.xml
    ├── autoload_configs/
    ├── dialplan/
    ├── directory/
    └── sip_profiles/
```

### 🛠️ 常用命令

```bash
# 构建镜像
cd docker
./build.sh

# 使用 Docker Compose 启动
docker compose up -d

# 查看日志
docker logs -f freeswitch

# 进入容器
docker exec -it freeswitch bash

# 访问 FreeSWITCH CLI
docker exec -it freeswitch fs_cli -p YOUR_PASSWORD

# 停止容器
docker compose down
```

### 可选组件：UniMRCP / mod_unimrcp

UniMRCP 与 mod_unimrcp 的源码构建在 CI（特别是多架构 buildx）和部分环境中较为脆弱，会因为底层系统库版本差异导致链接失败或编译无法通过。

默认情况下镜像构建会跳过 UniMRCP（以提高稳定性与速度）。如需启用，请通过构建参数：

```bash
cd docker
# 启用 UniMRCP 构建（注意：会显著增加构建时间，并可能需要额外运行时依赖）
BUILD_UNIMRCP=1 ./build.sh
```

在 GitHub Actions 中也可通过 workflow 的 build step 添加 `--build-arg BUILD_UNIMRCP=1` 来启用。

### WebSocket 音频流支持：mod_audio_stream

镜像现在默认编译并加载 `mod_audio_stream`，用于将 FreeSWITCH 实时音频通过 WebSocket 发送到外部 ASR、Agent、TTS 或其他流式处理服务。

默认策略：

- `docker/Dockerfile` 中的 `MOD_AUDIO_STREAM_REF` 默认值为 `main`
- GitHub Actions 手动构建时也暴露了 `mod_audio_stream_ref` 输入参数
- 该参数支持 `branch`、`tag` 或 `commit SHA`

如果你更关注可复现构建，建议不要长期跟随 `main`，而是固定为明确版本标签或提交号。

本地构建示例：

```bash
cd docker
docker build \
  --build-arg MOD_AUDIO_STREAM_REF=v1.0.0 \
  -t bytedesk/freeswitch:mod-audio-stream .
```

固定到具体提交示例：

```bash
cd docker
docker build \
  --build-arg MOD_AUDIO_STREAM_REF=ec2a781 \
  -t bytedesk/freeswitch:mod-audio-stream .
```

GitHub Actions 手动触发建议：

- 日常跟踪上游：保留默认值 `main`
- 预发布/生产构建：填写已验证的 tag 或 commit SHA

构建完成后可在容器内验证模块是否已安装并加载：

```bash
docker exec -it freeswitch fs_cli -x "show modules like audio_stream"
```

若返回包含 `mod_audio_stream`，说明模块已成功安装。

### 🌐 镜像仓库

- **Docker Hub**: `bytedesk/freeswitch:latest`
- **阿里云**: `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest`

### 📞 支持

- **Email**: <270580156@qq.com>
- **GitHub**: <https://github.com/Bytedesk/bytedesk-freeswitch/issues>
- **文档**: <https://docs.bytedesk.com/>

---

**维护者**: ByteDesk Team  
**最后更新**: 2025-10-09

## � 声音资源（sounds）覆盖策略

镜像构建时将优先使用仓库提供的本地声音资源：

- 构建脚本 `docker/build.sh` 会在构建前自动同步仓库根目录的 `sounds/` 到 `docker/sounds/`。
- `docker/Dockerfile` 会删除镜像内默认的 `${FREESWITCH_PREFIX}/sounds`，并用构建上下文中的 `sounds/` 完整覆盖。

使用方式：

1) 在仓库根目录维护你的声音包：`./sounds/`（如 `en/`, `zh/`, `music/` 等结构）。
2) 使用脚本构建（推荐）：

  ```bash
  cd docker
  ./build.sh
  ```

1) 若直接使用 `docker build` 而不经过脚本，请确保 `docker/sounds/` 目录存在（本仓库已提供占位文件保证目录存在）。

可选：若你不想下载 FreeSWITCH 官方声音包以减少构建时间/体积，可在构建时传参 `--build-arg INSTALL_SOUNDS=none`，镜像仍会使用你的本地 `sounds/` 内容。

## �🎙️ MRCP 支持（mod_unimrcp，可选构建）

本镜像默认不编译 `mod_unimrcp`（`BUILD_UNIMRCP=0`），以保证多架构构建稳定性与构建速度。
如需作为 MRCP 客户端对接外部 MRCP Server（如百度/腾讯/讯飞等），请在构建时启用 `BUILD_UNIMRCP=1`。

### 配置步骤

1) 构建时启用 UniMRCP / mod_unimrcp

```bash
cd docker
BUILD_UNIMRCP=1 ./build.sh
```

1. 修改 MRCP Profile：`conf/mrcp_profiles/baidu.xml`

- 将 `server-ip` 改为实际 MRCP Server 的 IP，`server-port` 通常为 5060（SIP）。

1. 模块加载与客户端配置

- 自动加载：`autoload_configs/modules.conf.xml` 已包含 `<load module="mod_unimrcp"/>`
- 客户端设置：`autoload_configs/unimrcp.conf.xml` 默认 `default-profile=baidu`

1. 运行时验证

```bash
docker exec -it freeswitch fs_cli -x "show modules | grep unimrcp"
```

若输出包含 `mod_unimrcp`，说明模块加载成功；若无输出，请先确认镜像是否使用 `BUILD_UNIMRCP=1` 构建。

### 在 Dialplan 中使用示例

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

> 更详细的 MRCP 服务端搭建与说明，请参考仓库文档 `freeswitch_mrcp.md`（或你的内部文档）。
