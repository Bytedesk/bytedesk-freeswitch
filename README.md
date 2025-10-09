# ByteDesk FreeSWITCH Docker Image

## Workflow Overview

This project uses multiple independent GitHub Actions workflows to implement the CI/CD pipeline:

### 1. freeswitch-docker.yml - FreeSWITCH Image Build Workflow

Triggers:

- Pushing a tag that starts with `freeswitch-v` (e.g., `freeswitch-v0.0.8`)
- Manual dispatch (supports custom version)
- Changes in the `docker/` directory

Capabilities:

- Build the FreeSWITCH Docker image
- Push the image to Alibaba Cloud Container Registry (ACR)
- Push the image to Docker Hub
- Create a GitHub Release
- Automatically test the image

Outputs:

- Docker image: `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest`
- Docker image: `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:{version}`
- Docker image: `bytedesk/freeswitch:latest`
- Docker image: `bytedesk/freeswitch:{version}`
- GitHub Release (includes usage documentation)

## Workflow Diagram

### FreeSWITCH Image Workflow

```bash
Push tag freeswitch-v0.0.8
or manually trigger the workflow
    ↓
freeswitch-docker.yml workflow
    ├── Build FreeSWITCH image
    ├── Push to Alibaba Cloud image registry
    ├── Push to Docker Hub
    ├── Create GitHub Release
    └── Test image functionality
```

## Configuration Requirements

### Secrets required by freeswitch-docker.yml

- `DOCKER_HUB_ACCESS_TOKEN` - Docker Hub access token
- `ALIYUN_DOCKER_USERNAME` - Alibaba Cloud Container Registry username
- `ALIYUN_DOCKER_PASSWORD` - Alibaba Cloud Container Registry password
- `GITHUB_TOKEN` - GitHub token (provided automatically)

## Usage

### ByteDesk Main Application Release Flow

#### 1. Create a new version

```bash
# Create a new tag
git tag v1.0.0

# Push the tag
git push origin v1.0.0
```

### 2. Monitor deployment status

1. Check the workflow run status on the repository’s Actions page

### FreeSWITCH Image Release Flow

#### 1. Create a FreeSWITCH image version

```bash
# Create a FreeSWITCH tag
git tag freeswitch-v0.0.8

# Push the tag
git push origin freeswitch-v0.0.8
```

#### 2. Manually trigger a build (optional)

1. Go to the GitHub Actions page
2. Select the "Build FreeSWITCH Docker" workflow
3. Click "Run workflow"
4. Enter a version (e.g., `1.10.12`)
5. Choose whether to push to the image registries
6. Click "Run workflow" to start building

#### 3. Use the built image

```bash
# Pull from Docker Hub
docker pull bytedesk/freeswitch:latest

# Pull from Alibaba Cloud (recommended in Mainland China)
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest

# Run the container
docker run -d \
  --name freeswitch-bytedesk \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD=password \
  bytedesk/freeswitch:latest
```

## Custom configuration

The container ships with a full FreeSWITCH configuration under `/usr/local/freeswitch/conf`. To run with your own XML files:

1. Prepare a config directory on the host (either start from the defaults or your existing deployment):

   ```bash
   mkdir -p ./freeswitch-conf
   docker run --rm bytedesk/freeswitch:latest \
     tar -C /usr/local/freeswitch/conf -cf - . | tar -C ./freeswitch-conf -xf -
   ```

2. Edit the XML files locally. Common touch-points:
   - `vars.xml` & `sip_profiles/internal.xml` for domains, ports, codecs.
   - `autoload_configs/switch.conf.xml` for core behaviour (RTP range, core DB).
   - `autoload_configs/db.conf.xml` & `autoload_configs/odbc.conf.xml` for ODBC/`mod_mariadb` DSNs.

3. Mount the folder into the container so FreeSWITCH boots with your files:

   ```bash
   docker run -d \
     --name freeswitch-bytedesk \
     -v $(pwd)/freeswitch-conf:/usr/local/freeswitch/conf \
     -p 5060:5060/tcp -p 5060:5060/udp \
     -p 8021:8021 \
     -e FREESWITCH_ESL_PASSWORD=password \
     bytedesk/freeswitch:latest
   ```

> ℹ️ The image also contains `/usr/local/freeswitch/etc/freeswitch`, which is left over from the upstream install tree. Runtime FreeSWITCH reads configuration exclusively from `/usr/local/freeswitch/conf` (verified against `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest`), so mount or edit that path when supplying custom XML files.

### Environment overrides for database DSNs

If you prefer to keep the bundled XML files and only swap database connectivity, set the following environment variables when starting the container. The entrypoint rewrites `switch.conf.xml`, `db.conf.xml`, and `odbc.conf.xml` automatically:

| Variable | Description | Default |
|----------|-------------|---------|
| `FREESWITCH_DB_HOST` | Database host (required to trigger rewrite) | - |
| `FREESWITCH_DB_NAME` | Database schema | - |
| `FREESWITCH_DB_USER` | Database user | `root` |
| `FREESWITCH_DB_PASSWORD` | Database password | empty |
| `FREESWITCH_DB_PORT` | Database port | `3306` |
| `FREESWITCH_DB_CHARSET` | Charset for ODBC DSN | `utf8mb4` |
| `FREESWITCH_DB_SCHEME` | DSN scheme for FreeSWITCH core (`mariadb`, `mysql`, `pgsql`, ...) | `mariadb` |
| `FREESWITCH_DB_ODBC_DIALECT` | Prefix for ODBC DSN (`mysql`/`mariadb`) | `mysql` |

Example:

```bash
docker run -d \
  --name freeswitch-bytedesk \
  -e FREESWITCH_DB_HOST=db.internal \
  -e FREESWITCH_DB_NAME=freeswitch_prod \
  -e FREESWITCH_DB_USER=fs_user \
  -e FREESWITCH_DB_PASSWORD=secret \
  -e FREESWITCH_DB_PORT=3307 \
  -e FREESWITCH_DB_SCHEME=mariadb \
  -e FREESWITCH_DB_ODBC_DIALECT=mariadb \
  bytedesk/freeswitch:latest
```

After the container starts, you can verify the rewritten DSN values by inspecting the mounted files or reading `/usr/local/freeswitch/conf/autoload_configs/*.xml` inside the container.

### Docker Compose example

For repeatable deployments, you can manage the container with Docker Compose:

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
      FREESWITCH_ESL_PASSWORD: bytedesk123
      FREESWITCH_DB_HOST: db.example.com
      FREESWITCH_DB_NAME: freeswitch
      FREESWITCH_DB_USER: fs_user
      FREESWITCH_DB_PASSWORD: fs_secret
      TZ: Asia/Shanghai
    volumes:
      - ./freeswitch-conf:/usr/local/freeswitch/conf
      - freeswitch-log:/usr/local/freeswitch/log
      - freeswitch-db:/usr/local/freeswitch/db
      - freeswitch-recordings:/usr/local/freeswitch/recordings
    healthcheck:
      test: ["CMD", "fs_cli", "-p", "bytedesk123", "-x", "status"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  freeswitch-log:
  freeswitch-db:
  freeswitch-recordings:
```

Place the snippet in a `docker-compose.yml` file and run `docker compose up -d`. Update the volume paths if you keep configuration files elsewhere, and align the database credentials with your environment.
The example assumes an existing MariaDB/MySQL instance reachable at `db.example.com`; adjust the hostname and credentials to match your deployment.
