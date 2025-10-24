# FreeSWITCH Docker Image
# Based on Ubuntu 22.04 LTS with FreeSWITCH 1.10.12

FROM ubuntu:22.04

LABEL maintainer="ByteDesk <270580156@qq.com>"
LABEL description="FreeSWITCH 1.10.12 for ByteDesk Call Center"
LABEL version="1.10.12"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV FREESWITCH_VERSION=v1.10.12
ENV FREESWITCH_PREFIX=/usr/local/freeswitch
ENV PATH=$PATH:$FREESWITCH_PREFIX/bin
# Initialize LD_LIBRARY_PATH safely (avoid undefined var warning under BuildKit)
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH:-}
# Default password for SIP users (can be overridden via FREESWITCH_DEFAULT_PASSWORD env var)
# WARNING: Change this in production environment for security!
ENV FREESWITCH_DEFAULT_PASSWORD=1234

# Baidu MRCP server envs (can be overridden at runtime via Compose)
ENV BAIDU_MRCP_ENABLE=1 \
    BAIDU_APPID="" \
    BAIDU_API_KEY="" \
    BAIDU_SECRET_KEY="" \
    BAIDU_MRCP_SIP_PORT=5070 \
    BAIDU_MRCP_CONTROL_PORT=1544 \
    BAIDU_MRCP_SAVE_AUDIO=1 \
    BAIDU_MRCP_URL="https://www.weiyuai.cn/download/mrcp_server_baidu.tar.gz"

# 可选构建参数：
# BUILD_SIGNALWIRE=1 启用 signalwire-c / mod_signalwire 依赖链 (默认 0)
# 注意：mod_verto 已彻底禁用，WebRTC 可通过 SIP.js + mod_sofia (ws/wss) 实现
ARG BUILD_SIGNALWIRE=0

# Sounds 安装选项 (默认安装 8kHz 基础音频包)
# INSTALL_SOUNDS=none 跳过所有声音文件安装
# INSTALL_SOUNDS=basic 仅安装 8kHz 音频和音乐保持
# INSTALL_SOUNDS=hd 安装 16kHz 高清音频
# INSTALL_SOUNDS=uhd 安装 32kHz/48kHz 超高清音频
ARG INSTALL_SOUNDS=basic

# 视频编解码支持 (默认禁用，启用需要额外依赖)
# ENABLE_VIDEO=1 启用 VP8/VP9/H264 视频编解码支持
ARG ENABLE_VIDEO=0

# 设置工作目录
WORKDIR /root

# 安装系统依赖
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    unixodbc-dev odbc-mariadb git build-essential automake autoconf libtool libtool-bin \
    python3 python3-dev python3-distutils \
    zlib1g-dev libjpeg-dev libncurses5-dev libssl-dev libpcre3-dev libspeexdsp-dev \
    libspeex-dev libcurl4-openssl-dev libopus-dev libsqlite3-dev libldns-dev libedit-dev \
    pkg-config uuid-dev yasm cmake libtiff-dev libpq-dev curl wget ca-certificates \
    libsndfile1-dev \
    # UniMRCP 依赖（APR/APR-Util/Expat）
    libapr1-dev libaprutil1-dev libexpat1-dev \
    liblua5.3-dev lua5.3 \
    libmariadb-dev libmariadb-dev-compat \
    libssl-dev libcrypto++-dev libgnutls28-dev \
    # Redis 客户端库（用于 mod_hiredis 和 mod_redis）
    libhiredis-dev redis-tools \
    # Java 开发环境（用于 mod_java）
    default-jdk default-jre \
    # 视频编解码依赖库
    libvpx-dev libx264-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 编译安装 libks（仅当 BUILD_SIGNALWIRE=1 时需要）
# 注意：mod_verto 已禁用，不再构建 libks，除非启用 signalwire
RUN if [ "${BUILD_SIGNALWIRE}" = "1" ]; then \
            echo "Building libks (needed for BUILD_SIGNALWIRE=1)"; \
            git clone --depth 1 https://github.com/signalwire/libks.git && cd libks && \
            cmake -S . -B build \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=/usr/local \
                -DWITH_TESTS=OFF \
                -DENABLE_DEB_PACKAGING=OFF \
                -DBUILD_SHARED_LIBS=ON \
                -DBUILD_STATIC_LIBS=OFF && \
            cmake --build build -- -j"$(nproc)" && \
            cmake --install build && \
            ldconfig && cd .. && rm -rf libks; \
        else \
            echo "Skipping libks (BUILD_SIGNALWIRE=${BUILD_SIGNALWIRE})"; \
        fi

# 可选：编译安装 signalwire-c（仅当需要 mod_signalwire 时启用）
RUN if [ "${BUILD_SIGNALWIRE}" = "1" ]; then \
            echo "Building signalwire-c (BUILD_SIGNALWIRE=1)"; \
            git clone --depth 1 https://github.com/signalwire/signalwire-c && \
            cd signalwire-c && \
            export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig:${PKG_CONFIG_PATH:-} && \
            export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH:-} && \
            cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
                        -DCMAKE_PREFIX_PATH=/usr/local \
                        -DCMAKE_INSTALL_PREFIX=/usr/local \
                        -DBUILD_TESTING=OFF \
                        -DOPENSSL_ROOT_DIR=/usr \
                        -DOPENSSL_INCLUDE_DIR=/usr/include/openssl \
                        -DOPENSSL_CRYPTO_LIBRARY=/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/libcrypto.so \
                        -DOPENSSL_SSL_LIBRARY=/usr/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/libssl.so && \
            cmake --build build -- -j"$(nproc)" && \
            cmake --install build && \
            ldconfig && \
            cd .. && rm -rf signalwire-c; \
        else \
            echo "Skipping signalwire-c build (BUILD_SIGNALWIRE=${BUILD_SIGNALWIRE})"; \
        fi

# 编译安装 sofia-sip
RUN git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    ./bootstrap.sh && \
    ./configure && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf sofia-sip

# 编译安装 spandsp (指定版本)
RUN git clone https://github.com/freeswitch/spandsp && \
    cd spandsp && \
    git checkout -b finecode20230705 0d2e6ac65e0e8f53d652665a743015a88bf048d4 && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr/local && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf spandsp

# 使用系统提供的 Lua 5.3（通过 apt 安装），无需从源码编译

# 编译安装 FFmpeg（mod_av 需要 FFmpeg 而不是 libav）
# 使用 FFmpeg 4.4 LTS 版本以确保兼容性
RUN git clone --depth 1 -b release/4.4 https://github.com/FFmpeg/FFmpeg.git && \
    cd FFmpeg && \
    ./configure --enable-shared \
                --disable-static \
                --enable-pic \
                --enable-gpl \
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

# 注意：不要从源码安装旧版 libuuid（会与系统版冲突，导致 APR 链接到错误的符号）
## 之前这里曾手动构建 libuuid-1.0.3，会覆盖系统 /usr/local/lib 下的 libuuid，
## 导致在构建 UniMRCP 时出现 `uuid_generate@UUID_1.0` 未定义的链接错误。
## 已移除该步骤，改用系统包 uuid-dev/libuuid1（已在 apt 安装列表中）。

# 编译安装 FreeSWITCH
RUN git clone -b ${FREESWITCH_VERSION} https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    # 在 bootstrap 前根据参数禁用不需要的模块（修改 build/modules.conf.in）
    # 彻底禁用 mod_verto（改用 SIP.js + mod_sofia 实现 WebRTC）
    # 使用更强力的 sed 命令确保所有 mod_verto 相关行都被注释
    sed -i '/mod_verto/s/^[^#]/# &/' build/modules.conf.in && \
    # 禁用 mod_signalwire（如未启用 BUILD_SIGNALWIRE）
    if [ "${BUILD_SIGNALWIRE}" != "1" ]; then \
        sed -i '/mod_signalwire/s/^[^#]/# &/' build/modules.conf.in; \
    fi && \
    # 确保启用 databases/mod_mariadb 模块
    sed -i 's/^#\(databases\/mod_mariadb\)/\1/' build/modules.conf.in && \
    # 启用 event_handlers/mod_odbc_cdr 模块（ODBC CDR 记录）
    sed -i 's/^#\(event_handlers\/mod_odbc_cdr\)/\1/' build/modules.conf.in && \
    # 启用 event_handlers/mod_fail2ban 模块（安全防护）
    sed -i 's/^#\(event_handlers\/mod_fail2ban\)/\1/' build/modules.conf.in && \
    # 启用 xml_int/mod_xml_curl 模块（用于动态 XML 配置）
    sed -i 's/^#\(xml_int\/mod_xml_curl\)/\1/' build/modules.conf.in && \
    # 启用中文报号模块 say/mod_say_zh（默认在 build/modules.conf.in 中被注释）
    sed -i 's/^#\(say\/mod_say_zh\)/\1/' build/modules.conf.in && \
    # 启用呼叫中心相关模块
    sed -i 's/^#\(applications\/mod_callcenter\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_blacklist\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_curl\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_hiredis\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_redis\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_distributor\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_lcr\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_cidlookup\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_nibblebill\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_easyroute\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_spy\)/\1/' build/modules.conf.in && \
    # 启用强烈推荐的呼叫中心模块
    sed -i 's/^#\(applications\/mod_avmd\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_directory\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(applications\/mod_voicemail_ivr\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(event_handlers\/mod_json_cdr\)/\1/' build/modules.conf.in && \
    # 注释掉 mod_python3（缺少 Python.h 导致编译失败）
    # sed -i 's/^#\(languages\/mod_python3\)/\1/' build/modules.conf.in && \
    sed -i 's/^#\(languages\/mod_java\)/\1/' build/modules.conf.in && \
    ./bootstrap.sh && \
    # 配置编译选项（根据视频支持参数）
    if [ "${ENABLE_VIDEO}" = "1" ]; then \
        echo "Configuring with video support (VP8/VP9/H264)..."; \
        ./configure --prefix=${FREESWITCH_PREFIX} \
                    --enable-core-odbc-support \
                    --enable-core-pgsql-support \
                    --with-vpx \
                    --with-openh264; \
    else \
        echo "Configuring without video support..."; \
        ./configure --prefix=${FREESWITCH_PREFIX} \
                    --enable-core-odbc-support \
                    --enable-core-pgsql-support; \
    fi && \
    # 修改 Makefile 移除 -Werror
    sed -i 's/-Werror //g' src/mod/applications/mod_av/Makefile && \
    make -j"$(nproc)" && make install && \
    # 编译 mod_mariadb 模块
    make mod_mariadb && \
    make mod_mariadb-install && \
    # 安装 Sounds 音频文件（根据 INSTALL_SOUNDS 参数）
    if [ "${INSTALL_SOUNDS}" != "none" ]; then \
        echo "Installing FreeSWITCH sounds (${INSTALL_SOUNDS})..."; \
        case "${INSTALL_SOUNDS}" in \
            "basic") \
                echo "Installing basic sounds (8kHz)..."; \
                make sounds-install && \
                make moh-install; \
                ;; \
            "hd") \
                echo "Installing HD sounds (16kHz)..."; \
                make hd-sounds-install && \
                make hd-moh-install; \
                ;; \
            "uhd") \
                echo "Installing UHD sounds (32kHz/48kHz)..."; \
                make uhd-sounds-install && \
                make uhd-moh-install; \
                ;; \
            *) \
                echo "Unknown INSTALL_SOUNDS value: ${INSTALL_SOUNDS}, skipping..."; \
                ;; \
        esac; \
    else \
        echo "Skipping sounds installation (INSTALL_SOUNDS=none)"; \
    fi && \
    cd .. && rm -rf freeswitch

# 确保所有共享库都被正确链接
RUN ldconfig

# UniMRCP 构建选项（默认禁用，启用需传 --build-arg BUILD_UNIMRCP=1）
# 按照官方文档编译：先构建 APR/APR-Util 依赖，再构建 UniMRCP 和 mod_unimrcp
ARG BUILD_UNIMRCP=0
RUN if [ "${BUILD_UNIMRCP}" = "1" ]; then \
    echo "Building UniMRCP and mod_unimrcp for MRCP support (following official guide)..."; \
    cd /root && \
    # 步骤1：下载并编译 UniMRCP 依赖包（APR、APR-Util）
    echo "Step 1: Building UniMRCP dependencies (APR, APR-Util)..." && \
    wget -q https://www.unimrcp.org/project/component-view/unimrcp-deps-1-6-0-tar-gz/download -O unimrcp-deps-1.6.0.tar.gz && \
    tar xzf unimrcp-deps-1.6.0.tar.gz && \
    cd unimrcp-deps-1.6.0 && \
    # 编译 APR
    cd libs/apr && \
    ./configure --prefix=/usr/local/apr && \
    make -j"$(nproc)" && make install && \
    cd .. && \
    # 编译 APR-Util
    cd apr-util && \
    ./configure --prefix=/usr/local/apr --with-apr=/usr/local/apr && \
    make -j"$(nproc)" && make install && \
    cd ../.. && \
    ldconfig && \
    cd /root && rm -rf unimrcp-deps-1.6.0 unimrcp-deps-1.6.0.tar.gz && \
    # 步骤2：编译 UniMRCP
    echo "Step 2: Building UniMRCP..." && \
    git clone --depth 1 https://github.com/unispeech/unimrcp.git && \
    cd unimrcp && \
    ./bootstrap && \
    ./configure && \
    make -j"$(nproc)" && make install && \
    ldconfig && \
    cd /root && rm -rf unimrcp && \
    # 步骤3：编译并安装 mod_unimrcp
    echo "Step 3: Building mod_unimrcp..." && \
    git clone --depth 1 https://github.com/freeswitch/mod_unimrcp.git && \
    cd mod_unimrcp && \
    export PKG_CONFIG_PATH=${FREESWITCH_PREFIX}/lib/pkgconfig:/usr/local/unimrcp/lib/pkgconfig:${PKG_CONFIG_PATH:-} && \
    ./bootstrap.sh && \
    ./configure && \
    make -j"$(nproc)" && make install && \
    ldconfig && \
    cd /root && rm -rf mod_unimrcp && \
    echo "UniMRCP and mod_unimrcp build completed successfully."; \
    else \
    echo "Skipping UniMRCP and mod_unimrcp build (BUILD_UNIMRCP=${BUILD_UNIMRCP})"; \
    fi

# 创建符号链接
RUN ln -sf ${FREESWITCH_PREFIX}/bin/freeswitch /usr/bin/freeswitch && \
    ln -sf ${FREESWITCH_PREFIX}/bin/fs_cli /usr/bin/fs_cli

# 复制配置文件
COPY conf/ ${FREESWITCH_PREFIX}/conf/

# 使用本地 sounds 覆盖 FreeSWITCH 默认 sounds（若存在，将在 build.sh 中准备）
RUN rm -rf ${FREESWITCH_PREFIX}/sounds && mkdir -p ${FREESWITCH_PREFIX}/sounds
COPY sounds/ ${FREESWITCH_PREFIX}/sounds/
# 兼容路径与权限：确保 share 路径也能访问到 sounds，并授予可读/可执行权限
RUN mkdir -p ${FREESWITCH_PREFIX}/share/freeswitch \
        && if [ ! -e ${FREESWITCH_PREFIX}/share/freeswitch/sounds ]; then \
                 ln -s ${FREESWITCH_PREFIX}/sounds ${FREESWITCH_PREFIX}/share/freeswitch/sounds; \
             fi \
        && chmod -R a+rX ${FREESWITCH_PREFIX}/sounds

# 不再内置 MRCP Server 包（体积过大），改为在容器启动时按 URL 下载到 /opt/mrcp/baidu
RUN mkdir -p /opt/mrcp/baidu

# 配置 ODBC（复制 ODBC 配置文件到系统目录）
# 从 docker/etc/ 文件夹复制 ODBC 配置文件
COPY etc/odbc.ini /etc/odbc.ini
COPY etc/odbcinst.ini /etc/odbcinst.ini
RUN chmod 644 /etc/odbc.ini /etc/odbcinst.ini

# 创建数据目录
RUN mkdir -p ${FREESWITCH_PREFIX}/log \
             ${FREESWITCH_PREFIX}/db \
             ${FREESWITCH_PREFIX}/recordings \
             ${FREESWITCH_PREFIX}/storage

# 暴露端口
# SIP 端口
EXPOSE 5060/tcp 5060/udp
EXPOSE 5080/tcp 5080/udp
EXPOSE 5061/tcp
EXPOSE 5081/tcp

# WebRTC 端口
EXPOSE 5066/tcp
EXPOSE 7443/tcp

# ESL 管理端口
EXPOSE 8021/tcp

# RTP 媒体端口范围
EXPOSE 16384-32768/udp

# STUN 端口 (可选)
EXPOSE 3478/udp
EXPOSE 3479/udp

# 其他服务端口
EXPOSE 8081-8082/tcp

# 设置工作目录
WORKDIR ${FREESWITCH_PREFIX}

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD fs_cli -x "status" | grep -q "UP" || exit 1

# 启动脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["freeswitch", "-nf", "-nonat"]
