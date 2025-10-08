#!/bin/bash
set -e

# FreeSWITCH Docker Entrypoint Script
# 用于初始化和启动 FreeSWITCH 服务

FREESWITCH_PREFIX=${FREESWITCH_PREFIX:-/usr/local/freeswitch}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置 ESL 密码
if [ -n "$FREESWITCH_ESL_PASSWORD" ]; then
    log_info "Setting ESL password..."
    sed -i "s/<param name=\"password\" value=\".*\"\/>/<param name=\"password\" value=\"${FREESWITCH_ESL_PASSWORD}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/autoload_configs/event_socket.conf.xml
fi

# 配置 SIP 域名/IP
if [ -n "$FREESWITCH_DOMAIN" ]; then
    log_info "Setting SIP domain to ${FREESWITCH_DOMAIN}..."
    sed -i "s/<X-PRE-PROCESS cmd=\"set\" data=\"domain=.*\"\/>/<X-PRE-PROCESS cmd=\"set\" data=\"domain=${FREESWITCH_DOMAIN}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/vars.xml
fi

# 配置外部 IP (用于 NAT 穿透)
if [ -n "$FREESWITCH_EXTERNAL_IP" ]; then
    log_info "Setting external IP to ${FREESWITCH_EXTERNAL_IP}..."
    sed -i "s/<X-PRE-PROCESS cmd=\"set\" data=\"external_rtp_ip=.*\"\/>/<X-PRE-PROCESS cmd=\"set\" data=\"external_rtp_ip=${FREESWITCH_EXTERNAL_IP}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/vars.xml
    sed -i "s/<X-PRE-PROCESS cmd=\"set\" data=\"external_sip_ip=.*\"\/>/<X-PRE-PROCESS cmd=\"set\" data=\"external_sip_ip=${FREESWITCH_EXTERNAL_IP}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/vars.xml
fi

# 配置 RTP 端口范围
if [ -n "$FREESWITCH_RTP_START" ] && [ -n "$FREESWITCH_RTP_END" ]; then
    log_info "Setting RTP port range to ${FREESWITCH_RTP_START}-${FREESWITCH_RTP_END}..."
    sed -i "s/<param name=\"rtp-start-port\" value=\".*\"\/>/<param name=\"rtp-start-port\" value=\"${FREESWITCH_RTP_START}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/autoload_configs/switch.conf.xml
    sed -i "s/<param name=\"rtp-end-port\" value=\".*\"\/>/<param name=\"rtp-end-port\" value=\"${FREESWITCH_RTP_END}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/autoload_configs/switch.conf.xml
fi

# 配置数据库连接 (MySQL/MariaDB)
if [ -n "$FREESWITCH_DB_HOST" ] && [ -n "$FREESWITCH_DB_NAME" ]; then
    log_info "Configuring database connection..."
    DB_USER=${FREESWITCH_DB_USER:-root}
    DB_PASSWORD=${FREESWITCH_DB_PASSWORD:-}
    DB_PORT=${FREESWITCH_DB_PORT:-3306}
    
    DB_DSN="mariadb://Server=${FREESWITCH_DB_HOST};Port=${DB_PORT};Database=${FREESWITCH_DB_NAME};Uid=${DB_USER};Pwd=${DB_PASSWORD};"
    
    sed -i "s|<param name=\"core-db-dsn\" value=\".*\"\/>|<param name=\"core-db-dsn\" value=\"${DB_DSN}\"\/|g" \
        ${FREESWITCH_PREFIX}/conf/autoload_configs/switch.conf.xml
fi

# 设置时区
if [ -n "$TZ" ]; then
    log_info "Setting timezone to ${TZ}..."
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo ${TZ} > /etc/timezone
fi

# 创建必要的目录
mkdir -p ${FREESWITCH_PREFIX}/log
mkdir -p ${FREESWITCH_PREFIX}/db
mkdir -p ${FREESWITCH_PREFIX}/recordings
mkdir -p ${FREESWITCH_PREFIX}/storage

# 检查配置文件
if [ ! -f "${FREESWITCH_PREFIX}/conf/freeswitch.xml" ]; then
    log_error "Configuration file not found: ${FREESWITCH_PREFIX}/conf/freeswitch.xml"
    exit 1
fi

log_info "FreeSWITCH configuration:"
log_info "  - Prefix: ${FREESWITCH_PREFIX}"
log_info "  - ESL Port: 8021"
log_info "  - SIP Ports: 5060, 5080"
log_info "  - WebRTC Port: 7443"
log_info "  - RTP Ports: 16384-32768"

# 启动 FreeSWITCH
log_info "Starting FreeSWITCH..."

# 如果有额外参数，使用它们；否则使用默认参数
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec freeswitch -nc -nonat -nf
fi
