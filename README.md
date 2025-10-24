# ByteDesk FreeSWITCH Docker Image

[![Docker Hub](https://img.shields.io/docker/v/bytedesk/freeswitch?label=Docker%20Hub)](https://hub.docker.com/r/bytedesk/freeswitch)
[![Docker Pulls](https://img.shields.io/docker/pulls/bytedesk/freeswitch)](https://hub.docker.com/r/bytedesk/freeswitch)
[![License](https://img.shields.io/github/license/Bytedesk/bytedesk-freeswitch)](LICENSE)

FreeSWITCH 1.10.12 Docker image for ByteDesk Call Center System, based on Ubuntu 22.04 LTS.

## 📑 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Ports](#ports)
- [Security](#security)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Features

- ✅ FreeSWITCH 1.10.12 stable release
- ✅ Based on Ubuntu 22.04 LTS
- ✅ mod_mariadb module included
- ✅ MySQL/MariaDB database support
- ✅ WebRTC support via SIP.js + mod_sofia
- ✅ Video call support (VP8/VP9/H264)
- ✅ Basic audio files included (8kHz)
- ✅ SIP TLS encryption support
- ✅ Health check enabled
- ✅ Environment variable configuration
- ✅ Multi-architecture support (amd64/arm64)
- ✅ Baidu MRCP Server integrated by default (bundled in image and auto-started)
- ✅ MRCP client support available (mod_unimrcp, opt-in build)
- ❌ mod_verto disabled (use SIP over WebSocket instead)

## Comparison with "Official" Image

- safarov/freeswitch — supports amd64 only (see tags → https://hub.docker.com/r/safarov/freeswitch/tags)
- bytedesk/freeswitch — supports both amd64 and arm64 (see tags → https://hub.docker.com/r/bytedesk/freeswitch/tags)

Tip: Multi-arch images run natively on x86_64 servers and ARM devices like Apple Silicon (M1/M2/M3) without manual image switching.

## Installation

### Method 1: Docker Run

```bash
# Pull from Docker Hub
docker pull bytedesk/freeswitch:latest

# Pull from Alibaba Cloud (recommended for China)
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest

# Run container (adjust env/ports for your scenario)
docker run -d \
  --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021 \
  -p 7443:7443 \
  -p 16384-32768:16384-32768/udp \
  -e FREESWITCH_ESL_PASSWORD='YOUR_ESL_PASSWORD' \
  -e FREESWITCH_DEFAULT_PASSWORD='YOUR_SIP_PASSWORD' \
  -e FREESWITCH_DOMAIN=sip.yourdomain.com \
  -e FREESWITCH_EXTERNAL_IP=YOUR_PUBLIC_IP \
  -e TZ=Asia/Shanghai \
  -v freeswitch_data:/usr/local/freeswitch \
  # Config directory - override container config with local files (actual runtime path: /usr/local/freeswitch/etc/freeswitch)
  -v ../../../../deploy/freeswitch/conf:/usr/local/freeswitch/etc/freeswitch \
  --restart=unless-stopped \
  bytedesk/freeswitch:latest
```

### Method 2: Docker Compose

#### Single Example (Optional Custom Configuration)

Create a `docker-compose.yml` file (uncomment the mount line if you want to use local custom configs):

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
      FREESWITCH_ESL_PASSWORD: ${ESL_PASSWORD}
      FREESWITCH_DEFAULT_PASSWORD: ${SIP_PASSWORD}
      FREESWITCH_DOMAIN: ${DOMAIN}
      FREESWITCH_EXTERNAL_IP: ${EXTERNAL_IP}
      TZ: Asia/Shanghai
    volumes:
      # Optional: mount custom configuration directory (actual runtime path: /usr/local/freeswitch/etc/freeswitch)
      # - ./freeswitch-conf:/usr/local/freeswitch/etc/freeswitch
      # Or, per your project structure:
      # - ../../../../deploy/freeswitch/conf:/usr/local/freeswitch/etc/freeswitch
      # Data persistence
      - freeswitch-log:/usr/local/freeswitch/log
      - freeswitch-db:/usr/local/freeswitch/db
      - freeswitch-recordings:/usr/local/freeswitch/recordings
    healthcheck:
      test: ["CMD", "fs_cli", "-p", "${ESL_PASSWORD}", "-x", "status"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  freeswitch-log:
  freeswitch-db:
  freeswitch-recordings:
```

Note: When using local custom configuration, make sure the target path is `/usr/local/freeswitch/etc/freeswitch`, which is the actual configuration directory read by FreeSWITCH at runtime.

Create a `.env` file (copy from `docker/.env.example`):

```bash
ESL_PASSWORD=MyStr0ng#ESL!Pass2024
SIP_PASSWORD=MyStr0ng#SIP!Pass2024
DOMAIN=sip.company.com
EXTERNAL_IP=203.0.113.10
```

Start the container:

```bash
docker compose up -d
```

## Configuration

### Custom Configuration Files
### Baidu MRCP Server (built-in)

- The image downloads and bundles Baidu MRCP Server during build. On container start, it writes configs from env vars and starts the server in background.
- FreeSWITCH connects to the built-in server via `127.0.0.1:5070` by default (`mrcp_profiles/baidu.xml`).
- No port mapping is required for typical usage. If you want to expose the MRCP server for external clients, publish `5070/udp,tcp`, `1544/tcp`, and `1554/tcp`.

Runtime environment variables:

- `BAIDU_MRCP_ENABLE`: enable built-in MRCP server (default 1)
- `BAIDU_APPID`: Baidu AppID
- `BAIDU_API_KEY`: Baidu API Key (maps to AUTH_APPKEY in config)
- `BAIDU_SECRET_KEY`: Baidu Secret Key (not used in current sample configs, reserved)
- `BAIDU_MRCP_SIP_PORT`: MRCP server SIP port (default 5070 to avoid FS 5060 conflict)
- `BAIDU_MRCP_CONTROL_PORT`: MRCPv2 control port (default 1544)
- `BAIDU_MRCP_SAVE_AUDIO`: whether to save audio (1/0, default 1)

Build-time argument:

- `BAIDU_MRCP_URL`: download URL of the Baidu MRCP Server tarball (default `https://www.weiyuai.cn/download/mrcp_server_baidu.tar.gz`)

Compose snippet (partial):

```yaml
environment:
  - BAIDU_MRCP_ENABLE=1
  - BAIDU_APPID=your_app_id
  - BAIDU_API_KEY=your_api_key
  - BAIDU_SECRET_KEY=your_secret_key
  - BAIDU_MRCP_SIP_PORT=5070
  - BAIDU_MRCP_CONTROL_PORT=1544
  - BAIDU_MRCP_SAVE_AUDIO=1
```

Verify runtime:

```bash
# Check MRCP server output in container logs
docker logs -f freeswitch-bytedesk | tail -n 200
# Or inspect detailed log inside container
docker exec -it freeswitch-bytedesk bash -lc 'tail -n 200 /var/log/unimrcpserver.out'
```

FreeSWITCH default profile: `conf/mrcp_profiles/baidu.xml`

```xml
<profile name="baidu" version="2">
  <param name="server-ip" value="127.0.0.1"/>
  <param name="server-port" value="5070"/>
  <param name="sip-transport" value="udp"/>
  <recogparams>
    <param name="start-input-timers" value="false"/>
  </recogparams>
</profile>
```

### MRCP (mod_unimrcp) Quick Notes (client)

- The image includes loading config for mod_unimrcp. To use it as a client inside the image, enable UniMRCP build at image build time (`--build-arg BUILD_UNIMRCP=1`).
- Default client profile file: `conf/mrcp_profiles/baidu.xml` (edit `server-ip` to your MRCP server).
- UniMRCP client settings file: `conf/autoload_configs/unimrcp.conf.xml` (`default-profile=baidu`).
- Verify module: `fs_cli -x "show modules | grep unimrcp"` should list `mod_unimrcp`.

Dialplan example:

```xml
<extension name="baidu_asr_test">
  <condition field="destination_number" expression="^9001$">
    <action application="answer"/>
    <action application="sleep" data="1000"/>
    <action application="speak" data="Please speak"/>
    <action application="play_and_detect_speech"
            data="silence_stream://2000 mrcp:baidu {start-input-timers=false}builtin:grammar/boolean grammar.xml"/>
    <action application="log" data="INFO ASR result: ${detect_speech_result}"/>
  </condition>
</extension>
```


#### Important: Configuration Path Information

**FreeSWITCH actual configuration path**: `/usr/local/freeswitch/etc/freeswitch`

The container contains two configuration directories:
- `/usr/local/freeswitch/etc/freeswitch` - ✅ **Actually used at runtime** (correct mount path)
- `/usr/local/freeswitch/conf` - ❌ Backup directory (not read by FreeSWITCH process)

**Verification method**:
```bash
# Verify the actual configuration path in the container
docker exec -it freeswitch-container fs_cli -p YOUR_ESL_PASSWORD -x 'global_getvar conf_dir'
# Output: /usr/local/freeswitch/etc/freeswitch
```

#### Steps to Configure Custom XML Files

1. **Export default configuration:**

   ```bash
   mkdir -p ./freeswitch-conf
   docker run --rm bytedesk/freeswitch:latest \
     tar -C /usr/local/freeswitch/etc/freeswitch -cf - . | tar -C ./freeswitch-conf -xf -
   ```

2. **Edit XML files locally:**
   - `vars.xml` & `sip_profiles/internal.xml` - SIP domains, ports, codecs
   - `autoload_configs/switch.conf.xml` - RTP port range, core database
   - `autoload_configs/db.conf.xml` & `autoload_configs/odbc.conf.xml` - Database DSN
   - `autoload_configs/event_socket.conf.xml` - ESL configuration

3. **Mount custom configuration (use correct path):**

   ```bash
   docker run -d \
     --name freeswitch \
     -v $(pwd)/freeswitch-conf:/usr/local/freeswitch/etc/freeswitch \
     -p 5060:5060/tcp -p 5060:5060/udp \
     -p 8021:8021 \
     -e FREESWITCH_ESL_PASSWORD=password \
     bytedesk/freeswitch:latest
   ```

> ⚠️ **Critical Notice**: 
> - You MUST mount to `/usr/local/freeswitch/etc/freeswitch` path, this is the actual configuration directory FreeSWITCH reads at runtime
> - If you mount to `/usr/local/freeswitch/conf` path, FreeSWITCH will not read the custom configuration, which may cause issues like ESL connection failure
> - Use `fs_cli -x 'global_getvar conf_dir'` command to verify the current configuration path

## Environment Variables

### Core Configuration

| Variable | Description | Default | Required | Security Level |
|----------|-------------|---------|----------|----------------|
| `FREESWITCH_ESL_PASSWORD` | ESL management password | - | ✅ Yes | 🔴 High |
| `FREESWITCH_DEFAULT_PASSWORD` | Default SIP user password | `1234` | ⚠️ Strongly Recommended | 🔴 High |
| `FREESWITCH_DOMAIN` | SIP domain or IP address | - | No | 🟡 Medium |
| `FREESWITCH_EXTERNAL_IP` | External IP for NAT traversal | - | No | 🟢 Low |
| `TZ` | Timezone | `Asia/Shanghai` | No | 🟢 Low |

### RTP Media Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FREESWITCH_RTP_START` | RTP start port | `16384` | No |
| `FREESWITCH_RTP_END` | RTP end port | `32768` | No |

### Database Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `FREESWITCH_DB_HOST` | Database host | - | No |
| `FREESWITCH_DB_NAME` | Database name | - | No |
| `FREESWITCH_DB_USER` | Database user | `root` | No |
| `FREESWITCH_DB_PASSWORD` | Database password | - | No |
| `FREESWITCH_DB_PORT` | Database port | `3306` | No |
| `FREESWITCH_DB_CHARSET` | Database charset | `utf8mb4` | No |
| `FREESWITCH_DB_SCHEME` | Core DB connection scheme | `mariadb` | No |
| `FREESWITCH_DB_ODBC_DIALECT` | ODBC connection dialect | `mysql` | No |

### Configuration Examples

**Development Environment:**
```bash
docker run -d \
  -e FREESWITCH_ESL_PASSWORD=dev123 \
  -e FREESWITCH_DEFAULT_PASSWORD=test1234 \
  bytedesk/freeswitch:latest
```

**Production with Database:**
```bash
docker run -d \
  -e FREESWITCH_ESL_PASSWORD='MyStr0ng#ESL!Pass2024' \
  -e FREESWITCH_DEFAULT_PASSWORD='MyStr0ng#SIP!Pass2024' \
  -e FREESWITCH_DOMAIN=sip.company.com \
  -e FREESWITCH_EXTERNAL_IP=203.0.113.10 \
  -e FREESWITCH_DB_HOST=mysql.internal \
  -e FREESWITCH_DB_NAME=freeswitch \
  -e FREESWITCH_DB_USER=fsuser \
  -e FREESWITCH_DB_PASSWORD='db_secure_pass' \
  bytedesk/freeswitch:latest
```

## Ports

### Required Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 5060 | TCP/UDP | SIP internal |
| 5080 | TCP/UDP | SIP external |
| 8021 | TCP | ESL management |
| 7443 | TCP | WebRTC WSS |
| 16384-32768 | UDP | RTP media |

### Optional Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 5061 | TCP | SIP internal TLS |
| 5081 | TCP | SIP external TLS |
| 5066 | TCP | WebSocket signaling |
| 3478-3479 | UDP | STUN service |
