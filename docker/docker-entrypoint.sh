#!/bin/bash
set -e

# FreeSWITCH Docker Entrypoint Script
# 用于初始化和启动 FreeSWITCH 服务

FREESWITCH_PREFIX=${FREESWITCH_PREFIX:-/usr/local/freeswitch}
BAIDU_MRCP_BASE=/opt/mrcp/baidu
BAIDU_MRCP_DIR=""

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

# ============================================
# 修复 IPv6 问题
# ============================================
log_info "Disabling IPv6 configurations..."

# 1. 删除 IPv6 相关的 SIP profiles
if [ -d "${FREESWITCH_PREFIX}/conf/sip_profiles/internal-ipv6" ]; then
    log_info "Removing internal-ipv6 directory..."
    rm -rf ${FREESWITCH_PREFIX}/conf/sip_profiles/internal-ipv6
fi

if [ -d "${FREESWITCH_PREFIX}/conf/sip_profiles/external-ipv6" ]; then
    log_info "Removing external-ipv6 directory..."
    rm -rf ${FREESWITCH_PREFIX}/conf/sip_profiles/external-ipv6
fi

# 2. 删除 IPv6 XML 配置文件
rm -f ${FREESWITCH_PREFIX}/conf/sip_profiles/internal-ipv6.xml 2>/dev/null || true
rm -f ${FREESWITCH_PREFIX}/conf/sip_profiles/external-ipv6.xml 2>/dev/null || true
rm -f ${FREESWITCH_PREFIX}/conf/sip_profiles/internal-ipv6.xml.deactive 2>/dev/null || true
rm -f ${FREESWITCH_PREFIX}/conf/sip_profiles/external-ipv6.xml.deactive 2>/dev/null || true

# 3. 确保 event_socket 只监听 IPv4
log_info "Configuring event_socket for IPv4 only..."
if [ -f "${FREESWITCH_PREFIX}/conf/autoload_configs/event_socket.conf.xml" ]; then
    # 替换任何 :: 为 0.0.0.0
    sed -i 's/listen-ip" value="::"/listen-ip" value="0.0.0.0"/g' \
        ${FREESWITCH_PREFIX}/conf/autoload_configs/event_socket.conf.xml
fi

log_info "IPv6 configurations disabled successfully"

# ============================================
# Baidu MRCP Server 配置与启动（如启用）
# ============================================

if [ "${BAIDU_MRCP_ENABLE:-1}" = "1" ]; then
    # 如果目录不存在则尝试下载并解压
    if [ ! -d "${BAIDU_MRCP_BASE}" ]; then
        mkdir -p "${BAIDU_MRCP_BASE}"
    fi

    # 探测已存在的布局
    if [ -d "${BAIDU_MRCP_BASE}/mrcp-server" ]; then
        BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/mrcp-server"
    elif [ -d "${BAIDU_MRCP_BASE}/mrcp_server_baidu/mrcp-server" ]; then
        BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/mrcp_server_baidu/mrcp-server"
    fi

    # 如未找到，则执行下载
    if [ -z "${BAIDU_MRCP_DIR}" ]; then
        URL=${BAIDU_MRCP_URL:-"https://www.weiyuai.cn/download/mrcp_server_baidu.tar.gz"}
        TMP_TAR="${BAIDU_MRCP_BASE}/baidu-mrcp-server.tar.gz"
        log_info "Downloading Baidu MRCP Server from ${URL} ..."
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "${TMP_TAR}" "${URL}" || log_warn "curl download failed"
        fi
        if [ ! -s "${TMP_TAR}" ] && command -v wget >/dev/null 2>&1; then
            wget -O "${TMP_TAR}" "${URL}" || log_warn "wget download failed"
        fi
        if [ -s "${TMP_TAR}" ]; then
            tar -xzf "${TMP_TAR}" -C "${BAIDU_MRCP_BASE}" && rm -f "${TMP_TAR}"
        else
            log_warn "Baidu MRCP package not downloaded; skipping MRCP setup."
        fi

        # 重新探测布局
        if [ -d "${BAIDU_MRCP_BASE}/mrcp-server" ]; then
            BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/mrcp-server"
        elif [ -d "${BAIDU_MRCP_BASE}/mrcp_server_baidu/mrcp-server" ]; then
            BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/mrcp_server_baidu/mrcp-server"
        fi
    fi

    if [ -n "${BAIDU_MRCP_DIR}" ] && [ -d "${BAIDU_MRCP_DIR}" ]; then
        log_info "Configuring Baidu MRCP Server..."

    # 确保运行库路径包含 MRCP lib
    export LD_LIBRARY_PATH="${BAIDU_MRCP_DIR}/lib:${LD_LIBRARY_PATH}"

    # 1) 配置 SIP 端口，避免与 FreeSWITCH 冲突（默认 5070）
    BAIDU_MRCP_SIP_PORT=${BAIDU_MRCP_SIP_PORT:-5070}
    sed -i "s#<sip-port>[0-9]\+#<sip-port>${BAIDU_MRCP_SIP_PORT}#" \
        "${BAIDU_MRCP_DIR}/conf/unimrcpserver.xml"

    # 2) 配置 IP 获取方式为 auto（若文件已有则保持）
    # 文件默认即为 <ip type="auto"/>，此处仅确保没有被手动写死
    sed -i "s#<ip>\([0-9\.]*\)</ip>#<ip type=\"auto\"/>#g" \
        "${BAIDU_MRCP_DIR}/conf/unimrcpserver.xml" || true

    # 3) 配置监测检查地址（默认 127.0.0.1 1544）
    BAIDU_MRCP_CONTROL_PORT=${BAIDU_MRCP_CONTROL_PORT:-1544}
    sed -i "s#^_check_cmd_pro=.*#_check_cmd_pro=\"./bin/check 127.0.0.1 ${BAIDU_MRCP_CONTROL_PORT}\"#" \
        "${BAIDU_MRCP_DIR}/conf/unimrcpserver_control.conf" || true

    # 4) 写入鉴权信息（ASR/TTS），以及是否保存音频
    if [ -n "${BAIDU_APPID}" ]; then
        sed -i "s#^AUTH_APPID\s*:.*#AUTH_APPID : ${BAIDU_APPID}#" "${BAIDU_MRCP_DIR}/conf/mrcp-asr.conf" || true
        sed -i "s#^AUTH_APPID\s*:.*#AUTH_APPID : ${BAIDU_APPID}#" "${BAIDU_MRCP_DIR}/conf/mrcp-proxy.conf" || true
    fi
    if [ -n "${BAIDU_API_KEY}" ]; then
        # 注意：配置文件中键名为 AUTH_APPKEY
        sed -i "s#^AUTH_APPKEY\s*:.*#AUTH_APPKEY : \"${BAIDU_API_KEY}\"#" "${BAIDU_MRCP_DIR}/conf/mrcp-asr.conf" || true
        sed -i "s#^AUTH_APPKEY\s*:.*#AUTH_APPKEY : \"${BAIDU_API_KEY}\"#" "${BAIDU_MRCP_DIR}/conf/mrcp-proxy.conf" || true
    fi
    if [ -n "${BAIDU_SECRET_KEY}" ]; then
        # 若后续版本需要 SECRET，可在此写入相应键；当前样例文件未使用 SECRET
        log_warn "BAIDU_SECRET_KEY provided but not used by current MRCP config files."
    fi
    sed -i "s#^NEED_SAVE_AUDIO\s*:.*#NEED_SAVE_AUDIO : ${BAIDU_MRCP_SAVE_AUDIO:-1}#" "${BAIDU_MRCP_DIR}/conf/mrcp-asr.conf" || true
    sed -i "s#^NEED_SAVE_AUDIO\s*:.*#NEED_SAVE_AUDIO : ${BAIDU_MRCP_SAVE_AUDIO:-1}#" "${BAIDU_MRCP_DIR}/conf/mrcp-proxy.conf" || true

    # 5) 将 FreeSWITCH 的 mrcp_profiles/baidu.xml 指向本地 MRCP 服务
    if [ -f "${FREESWITCH_PREFIX}/conf/mrcp_profiles/baidu.xml" ]; then
        sed -i "s#value=\"your_server_ip\"#value=\"127.0.0.1\"#" \
            "${FREESWITCH_PREFIX}/conf/mrcp_profiles/baidu.xml"
        sed -i "s#<param name=\"server-port\" value=\"[0-9]\+\"/>#<param name=\"server-port\" value=\"${BAIDU_MRCP_SIP_PORT}\"/>#" \
            "${FREESWITCH_PREFIX}/conf/mrcp_profiles/baidu.xml"
    fi

        # 6) 首次初始化工具链（如存在 bootstrap.sh）
        if [ -x "${BAIDU_MRCP_BASE}/bootstrap.sh" ]; then
            log_info "Running MRCP bootstrap.sh ..."
            "${BAIDU_MRCP_BASE}/bootstrap.sh" || log_warn "bootstrap.sh failed"
        elif [ -x "${BAIDU_MRCP_BASE}/mrcp_server_baidu/bootstrap.sh" ]; then
            log_info "Running MRCP bootstrap.sh ..."
            "${BAIDU_MRCP_BASE}/mrcp_server_baidu/bootstrap.sh" || log_warn "bootstrap.sh failed"
        fi

        # 7) 启动 MRCP Server（后台）
    log_info "Starting Baidu MRCP Server on 127.0.0.1:${BAIDU_MRCP_SIP_PORT}..."
    (
      cd "${BAIDU_MRCP_DIR}" && \
      ./bin/unimrcpserver -r . >/var/log/unimrcpserver.out 2>&1 &
    ) || log_warn "Failed to start unimrcpserver in background."
        else
            log_warn "Baidu MRCP directory not found after download; skipping MRCP startup."
        fi
else
    log_info "Baidu MRCP Server disabled or not found; skipping."
fi

# ============================================
# 原有配置逻辑
# ============================================
# 配置 ESL 密码
if [ -n "$FREESWITCH_ESL_PASSWORD" ]; then
    log_info "Setting ESL password..."
    sed -i "s/<param name=\"password\" value=\".*\"\/>/<param name=\"password\" value=\"${FREESWITCH_ESL_PASSWORD}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/autoload_configs/event_socket.conf.xml
fi

# 配置默认密码
if [ -n "$FREESWITCH_DEFAULT_PASSWORD" ]; then
    log_info "Setting default password..."
    sed -i "s/<X-PRE-PROCESS cmd=\"set\" data=\"default_password=.*\"\/>/<X-PRE-PROCESS cmd=\"set\" data=\"default_password=${FREESWITCH_DEFAULT_PASSWORD}\"\/>/g" \
        ${FREESWITCH_PREFIX}/conf/vars.xml
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
    DB_CHARSET=${FREESWITCH_DB_CHARSET:-utf8mb4}
    DB_SCHEME=${FREESWITCH_DB_SCHEME:-mariadb}
    DB_ODBC_DIALECT=${FREESWITCH_DB_ODBC_DIALECT:-mysql}

    CORE_DSN="${DB_SCHEME}://Server=${FREESWITCH_DB_HOST};Port=${DB_PORT};Database=${FREESWITCH_DB_NAME};Uid=${DB_USER};Pwd=${DB_PASSWORD};"
    ODBC_DSN="${DB_ODBC_DIALECT}:host=${FREESWITCH_DB_HOST};port=${DB_PORT};database=${FREESWITCH_DB_NAME};uid=${DB_USER};pwd=${DB_PASSWORD};charset=${DB_CHARSET}"

    export CORE_DSN ODBC_DSN
    python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

prefix = os.environ.get("FREESWITCH_PREFIX", "/usr/local/freeswitch")
core_dsn = os.environ.get("CORE_DSN")
odbc_dsn = os.environ.get("ODBC_DSN")

updates = [
    (Path(prefix) / "conf" / "autoload_configs" / "switch.conf.xml", r'(<param name="core-db-dsn" value=")([^"\\n]*)("\s*/?>)', core_dsn),
    (Path(prefix) / "conf" / "autoload_configs" / "db.conf.xml", r'(<param name="odbc-dsn" value=")([^"\\n]*)("\s*/?>)', odbc_dsn),
    (Path(prefix) / "conf" / "autoload_configs" / "odbc.conf.xml", r'(<param name="dsn" value=")([^"\\n]*)("\s*/?>)', odbc_dsn),
]

for path, pattern, replacement in updates:
    if not replacement:
        continue
    if not path.exists():
        print(f"[WARN] File not found: {path}", file=sys.stderr)
        continue
    original = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, lambda m: f"{m.group(1)}{replacement}{m.group(3)}", original, count=1)
    if count:
        path.write_text(updated, encoding="utf-8")
    else:
        print(f"[WARN] Pattern not updated in {path}", file=sys.stderr)
PY
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
log_info "  - IPv6: DISABLED"
if [ "${BAIDU_MRCP_ENABLE:-1}" = "1" ]; then
    log_info "  - Baidu MRCP: ENABLED (SIP ${BAIDU_MRCP_SIP_PORT:-5070}, MRCP ${BAIDU_MRCP_CONTROL_PORT:-1544})"
fi

# 启动 FreeSWITCH
log_info "Starting FreeSWITCH..."

# 如果有额外参数，使用它们；否则使用默认参数
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    # 使用 -nf (no fork) 保持前台运行，适合 Docker
    exec freeswitch -nf -nonat
fi
