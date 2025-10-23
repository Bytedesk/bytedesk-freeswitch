> [MOVED] 本文档已迁移至 `docker/docs/MOD_AV_FFMPEG_FIX.md`，此处副本已弃用，请访问新位置。
# mod_av FFmpeg 符号未定义问题修复

## 问题描述

编译后的镜像在启动 FreeSWITCH 时报错：

```
2025-10-10 06:33:48.478337 0.00% [CRIT] switch_loadable_module.c:1754 Error Loading module /usr/local/freeswitch/lib/freeswitch/mod/mod_av.so

**/usr/local/freeswitch/lib/freeswitch/mod/mod_av.so: undefined symbol: av_stream_get_parser**
```

## 问题原因

1. **使用了错误的库**：Dockerfile 中使用的是 `libav`（release/12），而不是 `FFmpeg`
2. **符号不存在**：`av_stream_get_parser` 函数在旧版 libav 12 中不存在
3. **版本不兼容**：FreeSWITCH 的 `mod_av` 模块需要 FFmpeg 4.x 或更高版本

## libav vs FFmpeg

- **libav**：FFmpeg 的一个分支（2011年从 FFmpeg 分离），开发较为缓慢
- **FFmpeg**：主流的多媒体处理库，持续更新维护
- **mod_av**：FreeSWITCH 的音视频处理模块，依赖 FFmpeg API

## 解决方案

### 1. 替换 libav 为 FFmpeg 4.4 LTS

修改 Dockerfile，将 libav 替换为 FFmpeg：

```dockerfile
# 编译安装 FFmpeg（mod_av 需要 FFmpeg 而不是 libav）
# 使用 FFmpeg 4.4 LTS 版本以确保兼容性
RUN git clone --depth 1 -b release/4.4 https://github.com/FFmpeg/FFmpeg.git && \
    cd FFmpeg && \
    ./configure --enable-shared \
                --disable-static \
                --enable-pic \
                --enable-libopus \
                --enable-libvpx \
                --enable-libx264 \
                --disable-doc \
                --disable-htmlpages \
                --disable-manpages \
                --disable-podpages \
                --disable-txtpages \
                --prefix=/usr/local && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig && \
    cd .. && rm -rf FFmpeg
```

### 2. FFmpeg 配置说明

- `--enable-shared`：生成动态链接库（.so 文件）
- `--disable-static`：不生成静态库，减小镜像大小
- `--enable-pic`：生成位置无关代码（Position Independent Code）
- `--enable-libopus`：启用 Opus 音频编解码器支持
- `--enable-libvpx`：启用 VP8/VP9 视频编解码器支持（如果需要视频）
- `--enable-libx264`：启用 H.264 视频编解码器支持（如果需要视频）
- `--disable-doc`：禁用文档生成，加快编译速度
- `--prefix=/usr/local`：安装到 /usr/local 目录

### 3. 运行 ldconfig

确保在编译安装后运行 `ldconfig`，以便系统能找到新安装的 FFmpeg 共享库：

```dockerfile
RUN ldconfig
```

### 4. 验证修复

重新构建镜像后，检查 FFmpeg 库是否正确安装：

```bash
# 进入容器
docker exec -it <container_id> bash

# 检查 FFmpeg 版本
ffmpeg -version

# 检查 mod_av.so 依赖的库
ldd /usr/local/freeswitch/lib/freeswitch/mod/mod_av.so

# 检查是否能找到 av_stream_get_parser 符号
nm -D /usr/local/lib/libavformat.so | grep av_stream_get_parser
```

如果看到类似以下输出，说明符号存在：

```
000000000012a3b0 T av_stream_get_parser
```

### 5. FreeSWITCH 启动验证

启动 FreeSWITCH 后，检查 mod_av 是否正确加载：

```bash
fs_cli -x "module_exists mod_av"
```

如果返回 `true`，说明模块加载成功。

## FFmpeg 版本选择

### FFmpeg 4.4 LTS（推荐）

- **稳定性**：长期支持版本
- **兼容性**：与 FreeSWITCH 1.10.x 完全兼容
- **API 稳定**：包含所有 mod_av 需要的 API

### FFmpeg 5.x/6.x

如果需要更新的特性，也可以使用更新版本：

```dockerfile
# 使用 FFmpeg 6.1（最新 LTS）
RUN git clone --depth 1 -b release/6.1 https://github.com/FFmpeg/FFmpeg.git && \
    # ... 配置保持不变
```

## 相关模块

如果启用了 `ENABLE_VIDEO=1`，mod_av 还需要以下编解码器支持：

- **libvpx**：VP8/VP9 视频编解码（已通过 apt 安装）
- **libx264**：H.264 视频编解码（已通过 apt 安装）
- **libopus**：Opus 音频编解码（已通过 apt 安装）

这些库已在 apt 安装阶段包含：

```dockerfile
libvpx-dev libx264-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev
```

## 重新构建镜像

```bash
# 清理旧镜像
docker rmi bytedesk/freeswitch:1.10.12

# 重新构建（不使用缓存）
cd docker
docker build --no-cache -t bytedesk/freeswitch:1.10.12 .

# 或使用 docker-compose
docker-compose build --no-cache
```

## 故障排查

### 1. 检查库路径

```bash
# 检查 LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH

# 检查 ldconfig 缓存
ldconfig -p | grep libav
```

应该看到：

```
libavutil.so.56 (libc6,x86-64) => /usr/local/lib/libavutil.so.56
libavformat.so.58 (libc6,x86-64) => /usr/local/lib/libavformat.so.58
libavcodec.so.58 (libc6,x86-64) => /usr/local/lib/libavcodec.so.58
```

### 2. 检查 mod_av 依赖

```bash
ldd /usr/local/freeswitch/lib/freeswitch/mod/mod_av.so
```

输出中不应该有 "not found" 的库。

### 3. 检查编译日志

如果仍有问题，检查 FreeSWITCH 编译时的配置输出：

```bash
# 在 docker build 过程中，查看配置输出
# 应该看到类似：
# checking for avcodec_encode_video2 in -lavcodec... yes
# checking for av_frame_alloc in -lavutil... yes
```

## 参考资料

- [FFmpeg 官方文档](https://ffmpeg.org/documentation.html)
- [FreeSWITCH mod_av 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_av)
- [FFmpeg 编译指南](https://trac.ffmpeg.org/wiki/CompilationGuide)

## 更新日志

- **2025-10-10**：将 libav 替换为 FFmpeg 4.4 LTS，修复 `av_stream_get_parser` 符号未定义问题
