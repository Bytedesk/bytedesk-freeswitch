# FreeSWITCH Docker 构建选项说明

本文档说明 FreeSWITCH Docker 镜像的各种构建选项和参数配置。

## 构建参数概览

| 参数 | 默认值 | 可选值 | 说明 |
|------|--------|--------|------|
| `BUILD_SIGNALWIRE` | `0` | `0`, `1` | 是否启用 SignalWire 支持 |
| `INSTALL_SOUNDS` | `basic` | `none`, `basic`, `hd`, `uhd` | 音频文件安装级别 |
| `ENABLE_VIDEO` | `0` | `0`, `1` | 是否启用视频编解码支持 |

## 详细说明

### 1. BUILD_SIGNALWIRE - SignalWire 支持

控制是否构建 SignalWire 相关依赖（libks 和 signalwire-c）。

**默认值**: `0` (禁用)

```bash
# 禁用 SignalWire (默认)
docker build --build-arg BUILD_SIGNALWIRE=0 -t freeswitch:base .

# 启用 SignalWire
docker build --build-arg BUILD_SIGNALWIRE=1 -t freeswitch:signalwire .
```

**说明**:
- `0`: 不构建 SignalWire 依赖，镜像更小更快
- `1`: 构建完整的 SignalWire 支持，可使用 mod_signalwire

**注意**: mod_verto 已彻底禁用，WebRTC 通过 SIP.js + mod_sofia (ws/wss) 实现。

### 2. INSTALL_SOUNDS - 音频文件安装

控制安装哪些音频文件（提示音、保持音乐等）。

**默认值**: `basic`

```bash
# 不安装任何音频文件（最小镜像）
docker build --build-arg INSTALL_SOUNDS=none -t freeswitch:nosounds .

# 安装基础音频 (8kHz) - 默认
docker build --build-arg INSTALL_SOUNDS=basic -t freeswitch:basic .

# 安装高清音频 (16kHz)
docker build --build-arg INSTALL_SOUNDS=hd -t freeswitch:hd .

# 安装超高清音频 (32kHz/48kHz)
docker build --build-arg INSTALL_SOUNDS=uhd -t freeswitch:uhd .
```

**音频级别对比**:

| 级别 | 采样率 | 文件大小 | 音质 | 适用场景 |
|------|--------|----------|------|----------|
| `none` | - | 最小 | - | 测试环境，不需要提示音 |
| `basic` | 8kHz | ~50MB | 标准 | 传统语音呼叫，节省带宽 |
| `hd` | 16kHz | ~100MB | 高清 | 宽带语音，客服中心 |
| `uhd` | 32-48kHz | ~200MB | 超高清 | 高端应用，音乐保持 |

**包含的音频内容**:
- 系统提示音 (欢迎语、菜单、错误提示等)
- 保持音乐 (Music on Hold)
- IVR 语音导航
- 语音信箱提示

### 3. ENABLE_VIDEO - 视频编解码支持

控制是否启用视频通话功能。

**默认值**: `0` (禁用)

```bash
# 禁用视频支持 (默认)
docker build --build-arg ENABLE_VIDEO=0 -t freeswitch:audio-only .

# 启用视频支持
docker build --build-arg ENABLE_VIDEO=1 -t freeswitch:video .
```

**支持的视频编解码器** (启用时):
- **VP8**: WebRTC 标准编解码器，开源免费
- **VP9**: VP8 的继任者，更高压缩率
- **H.264**: 广泛支持的编解码器（需注意许可）

**视频功能依赖库**:
- libvpx-dev (VP8/VP9)
- libx264-dev (H264)
- libavcodec-dev (FFmpeg 编解码器)
- libavformat-dev (容器格式)
- libavutil-dev (工具函数)
- libswscale-dev (图像缩放)

**使用场景**:
- `0`: 纯语音呼叫中心，节省资源
- `1`: 视频客服、远程会议、视频监控

## 组合使用示例

### 场景 1: 最小镜像 (仅核心功能)

```bash
docker build \
  --build-arg BUILD_SIGNALWIRE=0 \
  --build-arg INSTALL_SOUNDS=none \
  --build-arg ENABLE_VIDEO=0 \
  -t freeswitch:minimal \
  -f docker/Dockerfile \
  docker
```

**特点**: 
- 镜像最小
- 仅支持 SIP 语音
- 适合测试或自定义音频

### 场景 2: 标准呼叫中心 (推荐)

```bash
docker build \
  --build-arg BUILD_SIGNALWIRE=0 \
  --build-arg INSTALL_SOUNDS=basic \
  --build-arg ENABLE_VIDEO=0 \
  -t freeswitch:callcenter \
  -f docker/Dockerfile \
  docker
```

**特点**:
- 包含基础音频
- 纯语音呼叫
- 性能与功能平衡

### 场景 3: 高清视频客服

```bash
docker build \
  --build-arg BUILD_SIGNALWIRE=0 \
  --build-arg INSTALL_SOUNDS=hd \
  --build-arg ENABLE_VIDEO=1 \
  -t freeswitch:video-hd \
  -f docker/Dockerfile \
  docker
```

**特点**:
- 支持视频通话
- 高清音频
- 适合高端客服

### 场景 4: 完整功能版

```bash
docker build \
  --build-arg BUILD_SIGNALWIRE=1 \
  --build-arg INSTALL_SOUNDS=uhd \
  --build-arg ENABLE_VIDEO=1 \
  -t freeswitch:full \
  -f docker/Dockerfile \
  docker
```

**特点**:
- 所有功能完整
- 镜像最大
- 适合开发测试

## Docker Compose 示例

```yaml
version: '3.8'

services:
  # 最小版本
  freeswitch-minimal:
    build:
      context: ./docker
      dockerfile: Dockerfile
      args:
        BUILD_SIGNALWIRE: 0
        INSTALL_SOUNDS: none
        ENABLE_VIDEO: 0
    ports:
      - "5060:5060/udp"
      - "5080:5080/udp"
      - "8021:8021"
      - "16384-32768:16384-32768/udp"

  # 标准版本（推荐）
  freeswitch-standard:
    build:
      context: ./docker
      dockerfile: Dockerfile
      args:
        BUILD_SIGNALWIRE: 0
        INSTALL_SOUNDS: basic
        ENABLE_VIDEO: 0
    ports:
      - "5060:5060/udp"
      - "5080:5080/udp"
      - "7443:7443"
      - "8021:8021"
      - "16384-32768:16384-32768/udp"

  # 视频支持版本
  freeswitch-video:
    build:
      context: ./docker
      dockerfile: Dockerfile
      args:
        BUILD_SIGNALWIRE: 0
        INSTALL_SOUNDS: hd
        ENABLE_VIDEO: 1
    ports:
      - "5060:5060/udp"
      - "5080:5080/udp"
      - "7443:7443"
      - "8021:8021"
      - "16384-32768:16384-32768/udp"
    environment:
      - FREESWITCH_ESL_PASSWORD=your-password
```

## 镜像大小对比

| 配置 | 预估大小 | 构建时间 |
|------|----------|----------|
| Minimal (无音频) | ~800MB | ~20分钟 |
| Basic (8kHz) | ~850MB | ~25分钟 |
| HD (16kHz) | ~900MB | ~30分钟 |
| UHD (48kHz) | ~1GB | ~35分钟 |
| Video + HD | ~950MB | ~35分钟 |
| Full (所有功能) | ~1.2GB | ~40分钟 |

*注: 实际大小和时间取决于网络速度和硬件配置*

## 性能影响

### 音频文件级别

- **none**: 无额外性能开销，但需自行提供音频
- **basic**: 几乎无性能影响
- **hd/uhd**: 磁盘 I/O 略有增加，CPU 编解码开销略增

### 视频支持

启用视频后的性能影响：

| 指标 | 无视频 | 启用视频 |
|------|--------|----------|
| CPU 使用 | 基准 | +30-50% (视频编解码) |
| 内存使用 | 基准 | +20-30% (视频缓冲) |
| 带宽 | 64-128 Kbps | +500 Kbps - 2 Mbps |
| 并发能力 | 100+ | 20-50 (取决于硬件) |

**建议**:
- 纯语音场景禁用视频以节省资源
- 视频场景建议配置: 4核8G起步

## WebRTC 配置说明

由于 mod_verto 已禁用，WebRTC 通过以下方式实现：

### 前端使用 SIP.js

```javascript
const userAgent = new SIP.UserAgent({
  uri: 'sip:1000@yourdomain.com',
  transportOptions: {
    server: 'wss://yourdomain.com:7443'
  },
  authorizationUsername: '1000',
  authorizationPassword: 'password',
  sessionDescriptionHandlerFactoryOptions: {
    constraints: {
      audio: true,
      video: true  // 仅当 ENABLE_VIDEO=1 时可用
    }
  }
});
```

### SIP Profile 配置

确保 `sip_profiles/internal.xml` 中启用:

```xml
<!-- WebSocket 支持 -->
<param name="ws-binding" value=":5066"/>
<param name="wss-binding" value=":7443"/>

<!-- TLS 证书 -->
<param name="tls" value="true"/>
<param name="tls-cert-dir" value="/usr/local/freeswitch/certs"/>
```

## 故障排除

### 1. 音频文件安装失败

**症状**: `make sounds-install` 失败

**解决方案**:
```bash
# 检查网络连接
curl -I https://files.freeswitch.org/

# 手动下载音频包
cd /usr/local/freeswitch
wget https://files.freeswitch.org/releases/sounds/...
```

### 2. 视频编解码不可用

**症状**: 视频通话无图像

**检查步骤**:
```bash
# 进入容器
docker exec -it freeswitch fs_cli

# 检查编解码器
show codecs

# 应该看到 VP8/VP9/H264
```

### 3. 构建时间过长

**优化建议**:
- 使用 `--build-arg INSTALL_SOUNDS=basic` 而非 `uhd`
- 启用 Docker BuildKit 缓存
- 使用多阶段构建（已实现）

## 相关资源

- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [SIP.js 文档](https://sipjs.com/)
- [WebRTC 标准](https://webrtc.org/)
- [VP8/VP9 编解码器](https://www.webmproject.org/)

## 更新日志

- **2025-01-09**: 
  - 新增 `INSTALL_SOUNDS` 参数支持
  - 新增 `ENABLE_VIDEO` 视频支持
  - 彻底禁用 mod_verto
  - 改用 SIP.js + mod_sofia 实现 WebRTC

---

**维护者**: ByteDesk <270580156@qq.com>  
**最后更新**: 2025年1月9日
