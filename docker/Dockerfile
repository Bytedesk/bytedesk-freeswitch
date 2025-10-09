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
    unixodbc-dev odbc-mariadb git build-essential automake autoconf libtool libtool-bin python3 \
    zlib1g-dev libjpeg-dev libncurses5-dev libssl-dev libpcre3-dev libspeexdsp-dev \
    libspeex-dev libcurl4-openssl-dev libopus-dev libsqlite3-dev libldns-dev libedit-dev \
    pkg-config uuid-dev yasm cmake libtiff-dev libpq-dev curl wget ca-certificates \
    libsndfile1-dev \
    liblua5.3-dev lua5.3 \
    libmariadb-dev libmariadb-dev-compat \
    libssl-dev libcrypto++-dev libgnutls28-dev \
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

# 编译安装 libav
RUN git clone -b release/12 https://github.com/libav/libav.git && \
    cd libav && \
    CFLAGS=-fPIC ./configure --enable-pic --enable-shared && \
    make && make install && \
    cd .. && rm -rf libav

# 编译安装 libuuid
RUN wget https://jaist.dl.sourceforge.net/project/libuuid/libuuid-1.0.3.tar.gz && \
    tar -zxvf libuuid-1.0.3.tar.gz && \
    cd libuuid-1.0.3 && \
    ./configure && \
    make && make install && \
    cd .. && rm -rf libuuid-1.0.3 libuuid-1.0.3.tar.gz

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

# 创建符号链接
RUN ln -sf ${FREESWITCH_PREFIX}/bin/freeswitch /usr/bin/freeswitch && \
    ln -sf ${FREESWITCH_PREFIX}/bin/fs_cli /usr/bin/fs_cli

# 复制配置文件
COPY conf/ ${FREESWITCH_PREFIX}/conf/

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
