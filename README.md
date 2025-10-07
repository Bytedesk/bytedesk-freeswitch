# ByteDesk FreeSWITCH Docker Image

## Workflow Overview

This project uses multiple independent GitHub Actions workflows to implement the CI/CD pipeline:

### 1. freeswitch-docker.yml - FreeSWITCH Image Build Workflow

Triggers:

- Pushing a tag that starts with `freeswitch-v` (e.g., `freeswitch-v1.10.12`)
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
Push tag freeswitch-v1.10.12
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
git tag freeswitch-v1.10.12

# Push the tag
git push origin freeswitch-v1.10.12
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
docker pull bytedesk/freeswitch:1.10.12

# Pull from Alibaba Cloud (recommended in Mainland China)
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12

# Run the container
docker run -d \
  --name freeswitch-bytedesk \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD=bytedesk123 \
  bytedesk/freeswitch:1.10.12
```
