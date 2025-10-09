# ByteDesk FreeSWITCH Docker Image

[![Docker Hub](https://img.shields.io/docker/v/bytedesk/freeswitch?label=Docker%20Hub)](https://hub.docker.com/r/bytedesk/freeswitch)
[![Docker Pulls](https://img.shields.io/docker/pulls/bytedesk/freeswitch)](https://hub.docker.com/r/bytedesk/freeswitch)
[![License](https://img.shields.io/github/license/Bytedesk/bytedesk-freeswitch)](LICENSE)

FreeSWITCH 1.10.12 Docker image for ByteDesk Call Center System, based on Ubuntu 22.04 LTS.

## 🚨 Security Warning

> **⚠️ CRITICAL: Change default passwords before production deployment!**
> 
> This image contains default passwords that MUST be changed:
> 1. **ESL Password**: Set via `FREESWITCH_ESL_PASSWORD` environment variable (required)
> 2. **SIP User Password**: Set via `FREESWITCH_DEFAULT_PASSWORD` environment variable (default is `1234`)
> 
> **Failure to change default passwords can lead to:**
> - Unauthorized access to your phone system
> - Toll fraud and financial loss
> - Call record leakage
> - System abuse for illegal activities
> 
> 📖 See [Security Guide](docker/SECURITY.md) for detailed security configuration.

## 📑 Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Ports](#ports)
- [Testing](#testing)
- [Security](#security)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Quick Start

### Pull and Run (Development)

```bash
# Pull from Docker Hub
docker pull bytedesk/freeswitch:latest

# Pull from Alibaba Cloud (recommended for China)
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest

# Run container
docker run -d \
  --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD='dev_esl_pass_123' \
  -e FREESWITCH_DEFAULT_PASSWORD='dev_sip_pass_123' \
  bytedesk/freeswitch:latest
```

### Production Deployment

```bash
docker run -d \
  --name freeswitch-prod \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021 \
  -p 7443:7443 \
  -p 16384-32768:16384-32768/udp \
  -e FREESWITCH_ESL_PASSWORD='YOUR_STRONG_ESL_PASSWORD' \
  -e FREESWITCH_DEFAULT_PASSWORD='YOUR_STRONG_SIP_PASSWORD' \
  -e FREESWITCH_DOMAIN=sip.yourdomain.com \
  -e FREESWITCH_EXTERNAL_IP=YOUR_PUBLIC_IP \
  -e TZ=Asia/Shanghai \
  -v freeswitch_data:/usr/local/freeswitch \
  --restart=unless-stopped \
  bytedesk/freeswitch:latest
```

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
- ❌ mod_verto disabled (use SIP over WebSocket instead)

## Comparison with "Official" Image

- safarov/freeswitch — supports amd64 only (see tags → https://hub.docker.com/r/safarov/freeswitch/tags)
- bytedesk/freeswitch — supports both amd64 and arm64 (see tags → https://hub.docker.com/r/bytedesk/freeswitch/tags)

Tip: Multi-arch images run natively on x86_64 servers and ARM devices like Apple Silicon (M1/M2/M3) without manual image switching.

## Installation

### Method 1: Docker Run

See [Quick Start](#quick-start) section above.

### Method 2: Docker Compose

#### Basic Setup (Using Built-in Configuration)

Create a `docker-compose.yml` file:

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

#### Advanced Setup (Using Custom Configuration)

If you need custom configuration, mount the configuration directory:

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
      # ✅ Mount custom configuration directory (CRITICAL: use the correct path)
      - ./freeswitch-conf:/usr/local/freeswitch/etc/freeswitch
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

**Prepare custom configuration files:**

```bash
# 1. Export default configuration to local directory
mkdir -p ./freeswitch-conf
docker run --rm bytedesk/freeswitch:latest \
  tar -C /usr/local/freeswitch/etc/freeswitch -cf - . | tar -C ./freeswitch-conf -xf -

# 2. Modify configuration files (e.g., change ESL password)
# Edit ./freeswitch-conf/autoload_configs/event_socket.conf.xml

# 3. Start the container (it will use your custom configuration)
docker compose up -d

# 4. Verify the configuration is effective
docker exec -it freeswitch-bytedesk fs_cli -p YOUR_ESL_PASSWORD -x 'global_getvar conf_dir'
# Should output: /usr/local/freeswitch/etc/freeswitch
```

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

## Security

### Password Security

1. **Change ESL Password (Required)**
   - Use at least 16 characters
   - Include uppercase, lowercase, numbers, and special characters
   - Don't use dictionary words

2. **Change SIP Default Password (Strongly Recommended)**
   - Default is `1234` - extremely weak
   - Affects users 1000-1019, 1001-brian, 1002-admin
   - Use strong password: at least 12 characters

3. **Password Strength Examples:**
   ```
   ❌ Weak: 123456, password, 1234
   ⚠️ Medium: test1234, freeswitch123
   ✅ Strong: Fs#2024@Secure!Pass, MyPbx$Str0ng#2024
   ```

### Production Checklist

Before deploying to production:

- [ ] Changed `FREESWITCH_ESL_PASSWORD`
- [ ] Changed `FREESWITCH_DEFAULT_PASSWORD`
- [ ] Configured `FREESWITCH_EXTERNAL_IP`
- [ ] Configured firewall rules
- [ ] Enabled SIP TLS (ports 5061, 5081)
- [ ] Enabled SRTP encryption
- [ ] Configured ACL access control
- [ ] Set up log monitoring
- [ ] Configured backup strategy
- [ ] Limited unnecessary port exposure
- [ ] Configured fail2ban or similar
- [ ] Reviewed default user configuration

📖 **For detailed security configuration, see [docker/SECURITY.md](docker/SECURITY.md)**

## Testing

### 1. Check Container Status

```bash
docker ps | grep freeswitch
```

### 2. View Logs

```bash
# Real-time logs
docker logs -f freeswitch

# Last 100 lines
docker logs --tail 100 freeswitch
```

### 3. Access FreeSWITCH CLI

```bash
docker exec -it freeswitch fs_cli -p YOUR_ESL_PASSWORD
```

### 4. Test with SIP Client

Use [LinPhone](https://www.linphone.org/en/download/) or [Zoiper](https://www.zoiper.com/):

**Configuration:**
- **Username**: 1000 (or 1001-1019)
- **Password**: Your `FREESWITCH_DEFAULT_PASSWORD` value
- **Domain**: Your FreeSWITCH server address
- **Transport**: UDP (5060) or TCP (5060)

**Test Extensions:**
- **9196**: Echo test (no delay)
- **9195**: Echo test (5-second delay)
- **9664**: Music on hold

### 5. Verify Configuration Path

If you encounter configuration-related issues (e.g., ESL connection failures), verify the configuration path:

```bash
# Run the verification script
./docker/verify_config_path.sh
```

This will confirm which configuration directory FreeSWITCH is actually using and provide mounting recommendations.

## Documentation

### Main Documentation

- **[Security Guide](docker/SECURITY.md)** - 🔒 Detailed security configuration (MUST READ)
- **[Docker Documentation](docker/README.md)** - 🐳 Docker-related documentation and quick links

### Tools & Scripts

- **[Configuration Path Verification Script](docker/verify_config_path.sh)** - Automated tool to verify configuration paths

### Configuration Files

- **[Dockerfile](docker/Dockerfile)** - Docker image build file
- **[docker-entrypoint.sh](docker/docker-entrypoint.sh)** - Container startup script
- **[docker-compose.yml](docker/docker-compose.yml)** - Docker Compose configuration
- **[.env.example](docker/.env.example)** - Environment variable template

### External Resources

- [FreeSWITCH Official Documentation](https://freeswitch.org/confluence/)
- [FreeSWITCH Security Best Practices](https://freeswitch.org/confluence/display/FREESWITCH/Security)
- [Docker Hub - bytedesk/freeswitch](https://hub.docker.com/r/bytedesk/freeswitch)
- [Alibaba Cloud Registry](https://cr.console.aliyun.com/repository/cn-hangzhou/bytedesk/freeswitch)
- [ByteDesk Official Docs](https://docs.bytedesk.com/)

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Support

- **Email**: 270580156@qq.com
- **GitHub Issues**: https://github.com/Bytedesk/bytedesk-freeswitch/issues
- **Documentation**: https://docs.bytedesk.com/

---

**Maintained by**: [ByteDesk](https://bytedesk.com)  
**Last Updated**: 2025-10-09
