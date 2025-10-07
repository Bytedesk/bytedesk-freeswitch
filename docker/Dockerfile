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

# 设置工作目录
WORKDIR /root

# 安装系统依赖
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    unixodbc-dev mysql-connector-odbc git build-essential automake autoconf libtool libtool-bin python3 \
    zlib1g-dev libjpeg-dev libncurses5-dev libssl-dev libpcre3-dev libspeexdsp-dev \
    libspeex-dev libcurl4-openssl-dev libopus-dev libsqlite3-dev libldns-dev libedit-dev \
    pkg-config uuid-dev yasm cmake libtiff-dev libpq-dev curl wget ca-certificates \
    libmariadb-dev libmariadb-dev-compat && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 编译安装 libks
RUN git clone https://github.com/signalwire/libks.git && \
    cd libks && \
    cmake . && \
    make && make install && \
    cd .. && rm -rf libks

# 编译安装 signalwire-c
RUN git clone https://github.com/signalwire/signalwire-c && \
    cd signalwire-c && \
    cmake . && \
    make && make install && \
    cd .. && rm -rf signalwire-c

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
    ./configure && \
    make && make install && \
    cd .. && rm -rf spandsp

# 编译安装 Lua 5.3.0
RUN curl -R -O http://www.lua.org/ftp/lua-5.3.0.tar.gz && \
    tar xf lua-5.3.0.tar.gz && \
    cd lua-5.3.0 && \
    make MYCFLAGS="-fPIC" linux && \
    make install && \
    cd .. && rm -rf lua-5.3.0 lua-5.3.0.tar.gz

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
    ./bootstrap.sh && \
    ./configure --prefix=${FREESWITCH_PREFIX} \
                --enable-core-odbc-support \
                --enable-core-pgsql-support && \
    # 修改 Makefile 移除 -Werror
    sed -i 's/-Werror //g' src/mod/applications/mod_av/Makefile && \
    make && make install && \
    # 编译 mod_mariadb 模块
    make mod_mariadb && \
    make mod_mariadb-install && \
    cd .. && rm -rf freeswitch

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
CMD ["freeswitch", "-nc", "-nonat"]
