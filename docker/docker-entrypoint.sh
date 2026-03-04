#!/bin/bash
set -e

# FreeSWITCH Docker Entrypoint Script
# 用于初始化和启动 FreeSWITCH 服务

FREESWITCH_PREFIX=${FREESWITCH_PREFIX:-/usr/local/freeswitch}
BAIDU_MRCP_BASE=/opt/mrcp/baidu
BAIDU_MRCP_DIR=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

get_conf_dir() {
  if [ -f "${FREESWITCH_PREFIX}/etc/freeswitch/freeswitch.xml" ]; then
    echo "${FREESWITCH_PREFIX}/etc/freeswitch"
  elif [ -f "${FREESWITCH_PREFIX}/conf/freeswitch.xml" ]; then
    echo "${FREESWITCH_PREFIX}/conf"
  else
    echo "${FREESWITCH_PREFIX}/conf"
  fi
}

CONF_DIR="$(get_conf_dir)"

# ============================================
# 修复 IPv6 相关问题（可通过 DISABLE_IPV6=false 关闭）
# ============================================
if [ "${DISABLE_IPV6:-true}" = "true" ]; then
  log_info "Disabling IPv6 configurations..."

  rm -rf "${CONF_DIR}/sip_profiles/internal-ipv6" 2>/dev/null || true
  rm -rf "${CONF_DIR}/sip_profiles/external-ipv6" 2>/dev/null || true
  rm -f "${CONF_DIR}/sip_profiles/internal-ipv6.xml" 2>/dev/null || true
  rm -f "${CONF_DIR}/sip_profiles/external-ipv6.xml" 2>/dev/null || true
  rm -f "${CONF_DIR}/sip_profiles/internal-ipv6.xml.deactive" 2>/dev/null || true
  rm -f "${CONF_DIR}/sip_profiles/external-ipv6.xml.deactive" 2>/dev/null || true

  log_info "Configuring event_socket for IPv4 only..."
  if [ -f "${CONF_DIR}/autoload_configs/event_socket.conf.xml" ]; then
    sed -i 's#<param name="listen-ip" value="[^"]*"/>#<param name="listen-ip" value="0.0.0.0"/>#g' \
      "${CONF_DIR}/autoload_configs/event_socket.conf.xml"
    sed -i 's#<param name="apply-inbound-acl" value="[^"]*"/>#<param name="apply-inbound-acl" value="0.0.0.0/0"/>#g' \
      "${CONF_DIR}/autoload_configs/event_socket.conf.xml"

    if grep -q 'stop-on-bind-error' "${CONF_DIR}/autoload_configs/event_socket.conf.xml"; then
      sed -i 's#<param name="stop-on-bind-error" value="[^"]*"/>#<param name="stop-on-bind-error" value="false"/>#g' \
        "${CONF_DIR}/autoload_configs/event_socket.conf.xml"
    else
      sed -i 's#</settings>#    <param name="stop-on-bind-error" value="false"/>\n  </settings>#g' \
        "${CONF_DIR}/autoload_configs/event_socket.conf.xml"
    fi
  fi

  if [ -f "${CONF_DIR}/autoload_configs/acl.conf.xml" ]; then
    sed -i '/cidr="::/d' "${CONF_DIR}/autoload_configs/acl.conf.xml"
  fi

  log_info "IPv6 configurations disabled successfully"
fi

# ============================================
# Baidu MRCP Server 配置与启动（如启用）
# ============================================
if [ "${BAIDU_MRCP_ENABLE:-1}" = "1" ]; then
  if [ -d "${BAIDU_MRCP_BASE}/mrcp-server" ]; then
    BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/mrcp-server"
  elif [ -d "${BAIDU_MRCP_BASE}/MRCPServer/mrcp-server" ]; then
    BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/MRCPServer/mrcp-server"
  elif [ -d "${BAIDU_MRCP_BASE}/mrcp_server_baidu/mrcp-server" ]; then
    BAIDU_MRCP_DIR="${BAIDU_MRCP_BASE}/mrcp_server_baidu/mrcp-server"
  fi

  if [ -n "${BAIDU_MRCP_DIR}" ] && [ -d "${BAIDU_MRCP_DIR}" ]; then
    log_info "Configuring Baidu MRCP Server..."

    export LD_LIBRARY_PATH="${BAIDU_MRCP_DIR}/lib:${LD_LIBRARY_PATH}"

    BAIDU_MRCP_SIP_PORT=${BAIDU_MRCP_SIP_PORT:-5070}
    sed -i "s#<sip-port>[0-9]\+#<sip-port>${BAIDU_MRCP_SIP_PORT}#" \
      "${BAIDU_MRCP_DIR}/conf/unimrcpserver.xml"

    sed -i "s#<ip>\([0-9\.]*\)</ip>#<ip type=\"auto\"/>#g" \
      "${BAIDU_MRCP_DIR}/conf/unimrcpserver.xml" || true

    BAIDU_MRCP_CONTROL_PORT=${BAIDU_MRCP_CONTROL_PORT:-1544}
    sed -i "s#^_check_cmd_pro=.*#_check_cmd_pro=\"./bin/check 127.0.0.1 ${BAIDU_MRCP_CONTROL_PORT}\"#" \
      "${BAIDU_MRCP_DIR}/conf/unimrcpserver_control.conf" || true

    if [ -n "${BAIDU_APPID}" ]; then
      sed -i "s#^AUTH_APPID\s*:.*#AUTH_APPID : ${BAIDU_APPID}#" "${BAIDU_MRCP_DIR}/conf/mrcp-asr.conf" || true
      sed -i "s#^AUTH_APPID\s*:.*#AUTH_APPID : ${BAIDU_APPID}#" "${BAIDU_MRCP_DIR}/conf/mrcp-proxy.conf" || true
    fi

    if [ -n "${BAIDU_API_KEY}" ]; then
      sed -i "s#^AUTH_APPKEY\s*:.*#AUTH_APPKEY : \"${BAIDU_API_KEY}\"#" "${BAIDU_MRCP_DIR}/conf/mrcp-asr.conf" || true
      sed -i "s#^AUTH_APPKEY\s*:.*#AUTH_APPKEY : \"${BAIDU_API_KEY}\"#" "${BAIDU_MRCP_DIR}/conf/mrcp-proxy.conf" || true
    fi

    if [ -n "${BAIDU_SECRET_KEY}" ]; then
      log_warn "BAIDU_SECRET_KEY provided but not used by current MRCP config files."
    fi

    sed -i "s#^NEED_SAVE_AUDIO\s*:.*#NEED_SAVE_AUDIO : ${BAIDU_MRCP_SAVE_AUDIO:-1}#" "${BAIDU_MRCP_DIR}/conf/mrcp-asr.conf" || true
    sed -i "s#^NEED_SAVE_AUDIO\s*:.*#NEED_SAVE_AUDIO : ${BAIDU_MRCP_SAVE_AUDIO:-1}#" "${BAIDU_MRCP_DIR}/conf/mrcp-proxy.conf" || true

    if [ -f "${CONF_DIR}/mrcp_profiles/baidu.xml" ]; then
      sed -i "s#value=\"your_server_ip\"#value=\"127.0.0.1\"#" "${CONF_DIR}/mrcp_profiles/baidu.xml"
      sed -i "s#<param name=\"server-port\" value=\"[0-9]\+\"/>#<param name=\"server-port\" value=\"${BAIDU_MRCP_SIP_PORT}\"/>#" \
        "${CONF_DIR}/mrcp_profiles/baidu.xml"
    fi

    mkdir -p "${BAIDU_MRCP_DIR}/logs"

    log_info "Starting Baidu MRCP Server on 127.0.0.1:${BAIDU_MRCP_SIP_PORT}..."
    (
      cd "${BAIDU_MRCP_DIR}" && \
      ./bin/unimrcpserver -r . > /var/log/unimrcpserver.out 2>&1 &
    ) || log_warn "Failed to start unimrcpserver in background."

    sleep 1
    if pgrep -f unimrcpserver >/dev/null 2>&1; then
      log_info "Baidu MRCP Server started (pid: $(pgrep -f unimrcpserver | tr '\n' ' ')). Logs: ${BAIDU_MRCP_DIR}/logs"
    else
      log_warn "Baidu MRCP Server process not detected. Please check: ${BAIDU_MRCP_DIR}/logs and /var/log/unimrcpserver.out"
    fi
  else
    log_warn "Baidu MRCP directory not found in image; skipping MRCP startup."
  fi
else
  log_info "Baidu MRCP Server disabled or not found; skipping."
fi

# ============================================
# 通用配置逻辑
# ============================================
if [ -n "${FREESWITCH_ESL_PASSWORD:-}" ]; then
  log_info "Setting ESL password..."
  sed -i "s#<param name=\"password\" value=\".*\"/>#<param name=\"password\" value=\"${FREESWITCH_ESL_PASSWORD}\"/>#g" \
    "${CONF_DIR}/autoload_configs/event_socket.conf.xml"
fi

if [ -n "${FREESWITCH_DEFAULT_PASSWORD:-}" ]; then
  log_info "Setting default password..."
  sed -i "s#<X-PRE-PROCESS cmd=\"set\" data=\"default_password=.*\"/>#<X-PRE-PROCESS cmd=\"set\" data=\"default_password=${FREESWITCH_DEFAULT_PASSWORD}\"/>#g" \
    "${CONF_DIR}/vars.xml"
fi

if [ -n "${FREESWITCH_DOMAIN:-}" ]; then
  log_info "Setting SIP domain to ${FREESWITCH_DOMAIN}..."
  sed -i "s#<X-PRE-PROCESS cmd=\"set\" data=\"domain=.*\"/>#<X-PRE-PROCESS cmd=\"set\" data=\"domain=${FREESWITCH_DOMAIN}\"/>#g" \
    "${CONF_DIR}/vars.xml"
fi

if [ -n "${FREESWITCH_EXTERNAL_IP:-}" ]; then
  log_info "Setting external IP to ${FREESWITCH_EXTERNAL_IP}..."
  sed -i "s#<X-PRE-PROCESS cmd=\"set\" data=\"external_rtp_ip=.*\"/>#<X-PRE-PROCESS cmd=\"set\" data=\"external_rtp_ip=${FREESWITCH_EXTERNAL_IP}\"/>#g" \
    "${CONF_DIR}/vars.xml"
  sed -i "s#<X-PRE-PROCESS cmd=\"set\" data=\"external_sip_ip=.*\"/>#<X-PRE-PROCESS cmd=\"set\" data=\"external_sip_ip=${FREESWITCH_EXTERNAL_IP}\"/>#g" \
    "${CONF_DIR}/vars.xml"
fi

if [ -n "${FREESWITCH_RTP_START:-}" ] && [ -n "${FREESWITCH_RTP_END:-}" ]; then
  log_info "Setting RTP port range to ${FREESWITCH_RTP_START}-${FREESWITCH_RTP_END}..."
  sed -i "s#<param name=\"rtp-start-port\" value=\".*\"/>#<param name=\"rtp-start-port\" value=\"${FREESWITCH_RTP_START}\"/>#g" \
    "${CONF_DIR}/autoload_configs/switch.conf.xml"
  sed -i "s#<param name=\"rtp-end-port\" value=\".*\"/>#<param name=\"rtp-end-port\" value=\"${FREESWITCH_RTP_END}\"/>#g" \
    "${CONF_DIR}/autoload_configs/switch.conf.xml"
fi

if [ -n "${FS_CORE_DB_DSN:-}" ]; then
  log_info "Configuring core-db-dsn from FS_CORE_DB_DSN..."
  CORE_DSN="${FS_CORE_DB_DSN}"
  export CORE_DSN CONF_DIR
  python3 - <<'PY'
import os
import re
from pathlib import Path

conf_dir = os.environ.get("CONF_DIR", "/usr/local/freeswitch/conf")
core_dsn = os.environ.get("CORE_DSN", "")
target = Path(conf_dir) / "autoload_configs" / "switch.conf.xml"
if target.exists() and core_dsn:
    content = target.read_text(encoding="utf-8")
    content, _ = re.subn(
        r'(<param name="core-db-dsn" value=")(?:[^"\\n]*)("\s*/?>)',
        lambda m: f'{m.group(1)}{core_dsn}{m.group(2)}',
        content,
        count=1,
    )
    target.write_text(content, encoding="utf-8")
PY
elif [ -n "${FREESWITCH_DB_HOST:-}" ] && [ -n "${FREESWITCH_DB_NAME:-}" ]; then
  log_info "Configuring database connection from FREESWITCH_DB_*..."
  DB_USER=${FREESWITCH_DB_USER:-root}
  DB_PASSWORD=${FREESWITCH_DB_PASSWORD:-}
  DB_PORT=${FREESWITCH_DB_PORT:-3306}
  DB_SCHEME=${FREESWITCH_DB_SCHEME:-mariadb}
  CORE_DSN="${DB_SCHEME}://Server=${FREESWITCH_DB_HOST};Port=${DB_PORT};Database=${FREESWITCH_DB_NAME};Uid=${DB_USER};Pwd=${DB_PASSWORD};"
  export CORE_DSN CONF_DIR
  python3 - <<'PY'
import os
import re
from pathlib import Path

conf_dir = os.environ.get("CONF_DIR", "/usr/local/freeswitch/conf")
core_dsn = os.environ.get("CORE_DSN", "")
target = Path(conf_dir) / "autoload_configs" / "switch.conf.xml"
if target.exists() and core_dsn:
    content = target.read_text(encoding="utf-8")
    content, _ = re.subn(
        r'(<param name="core-db-dsn" value=")(?:[^"\\n]*)("\s*/?>)',
        lambda m: f'{m.group(1)}{core_dsn}{m.group(2)}',
        content,
        count=1,
    )
    target.write_text(content, encoding="utf-8")
PY
fi

if [ -n "${TZ:-}" ]; then
  log_info "Setting timezone to ${TZ}..."
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi

mkdir -p "${FREESWITCH_PREFIX}/log" "${FREESWITCH_PREFIX}/db" "${FREESWITCH_PREFIX}/recordings" "${FREESWITCH_PREFIX}/storage"

if [ ! -f "${CONF_DIR}/freeswitch.xml" ]; then
  log_error "Configuration file not found: ${CONF_DIR}/freeswitch.xml"
  exit 1
fi

log_info "FreeSWITCH configuration:"
log_info "  - Prefix: ${FREESWITCH_PREFIX}"
log_info "  - Conf Dir: ${CONF_DIR}"
log_info "  - ESL Port: 8021"
log_info "  - SIP Ports: 5060, 5080"
log_info "  - WebRTC Port: 7443"
log_info "  - RTP Ports: 16384-32768"
log_info "  - IPv6: ${DISABLE_IPV6:-true}"
if [ "${BAIDU_MRCP_ENABLE:-1}" = "1" ]; then
  log_info "  - Baidu MRCP: ENABLED (SIP ${BAIDU_MRCP_SIP_PORT:-5070}, MRCP ${BAIDU_MRCP_CONTROL_PORT:-1544})"
fi

log_info "Starting FreeSWITCH..."
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec freeswitch -nf -nonat
fi
