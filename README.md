# ByteDesk FreeSWITCH Docker Image

## Workflow Overview

This project uses multiple independent GitHub Actions workflows to implement the CI/CD pipeline:

### 1. freeswitch-docker.yml - FreeSWITCH Image Build Workflow

Triggers:

- Pushing a tag that starts with `freeswitch-v` (e.g., `freeswitch-v1.10.12`)
- Manual dispatch (supports custom version)
- Changes in the `deploy/freeswitch/docker/` directory

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
2. Wait for `bytedesk.yml` to complete
3. Observe `deploy-k8s.yml` automatically start and run

#### 3. Verify the deployment

```bash
# Check Pod status
kubectl get pods -n bytedesk

# Check service status
kubectl get svc -n bytedesk

# Check deployment status
kubectl get deployment -n bytedesk

# View logs
kubectl logs -f deployment/bytedesk -n bytedesk
```

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

## Advantages

### Benefits of the separation design

1. Modularity: build and deployment are separated, making maintenance easier
2. Flexibility: build and deployment flows can be controlled independently
3. Reusability: the deployment workflow can be triggered by other build workflows
4. Fault isolation: build failures won’t affect deployment configuration
5. Parallel processing: multiple builds can run concurrently while deployments execute sequentially

### Automation advantages

1. Zero-downtime deployment: Kubernetes rolling updates
2. Versioning: automatically uses Git tags as image versions
3. Health checks: automatically verify application status after deployment
4. Rollback support: quickly roll back to previous versions

## Troubleshooting

### Build failures

- Check whether Maven dependencies are correct
- Verify image registry credentials
- Inspect specific errors in the build logs

### Deployment failures

- Verify Kubernetes cluster configuration
- Check cluster resources
- Look at Pod events and logs
- Confirm image registry accessibility

### Common issues

1. Insufficient permissions: ensure the ServiceAccount has enough permissions
2. Insufficient resources: check CPU and memory availability
3. Network issues: verify cluster networking
4. Image pull failed: verify the image tag and registry access

## Enhancement Suggestions

### Features you can add

1. Multi-environment deployments: separate workflows for dev/staging/prod
2. Notification integration: add Slack/DingTalk notifications
3. Performance testing: run performance tests after deployment
4. Security scanning: integrate container security scans
5. Backup strategy: automatically back up data before deployment

### Monitoring and logging

1. Prometheus monitoring: integrate application metrics
2. ELK logging: centralized log management
3. Alerting: set alerts for key metrics
