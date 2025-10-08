# FreeSwitch Docker 镜像修复说明

## 修改内容总结

### 1. 修改的文件

#### ✅ docker-entrypoint.sh
**位置**: `/Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker/docker-entrypoint.sh`

**主要修改**:
```bash
# 新增 IPv6 禁用逻辑（在原有配置之前）
# ============================================
# 修复 IPv6 问题
# ============================================
log_info "Disabling IPv6 configurations..."

# 1. 删除 IPv6 相关的 SIP profiles
rm -rf ${FREESWITCH_PREFIX}/conf/sip_profiles/internal-ipv6
rm -rf ${FREESWITCH_PREFIX}/conf/sip_profiles/external-ipv6

# 2. 删除 IPv6 XML 配置文件
rm -f ${FREESWITCH_PREFIX}/conf/sip_profiles/internal-ipv6.xml*
rm -f ${FREESWITCH_PREFIX}/conf/sip_profiles/external-ipv6.xml*

# 3. 确保 event_socket 只监听 IPv4
sed -i 's/listen-ip" value="::"/listen-ip" value="0.0.0.0"/g' \
    ${FREESWITCH_PREFIX}/conf/autoload_configs/event_socket.conf.xml

log_info "IPv6 configurations disabled successfully"
```

**其他修改**:
- 默认 CMD 从 `-nc` 改为 `-nf` (保持前台运行，适合 Docker)
- 添加日志输出：`log_info "  - IPv6: DISABLED"`

#### ✅ Dockerfile
**位置**: `/Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker/Dockerfile`

**修改**:
```dockerfile
# 修改前
CMD ["freeswitch", "-nc", "-nonat"]

# 修改后
CMD ["freeswitch", "-nf", "-nonat"]
```

### 2. 备份文件

已创建备份文件：
- `docker-entrypoint.sh.bak`
- `Dockerfile.bak`

如需恢复，执行：
```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker
cp docker-entrypoint.sh.bak docker-entrypoint.sh
cp Dockerfile.bak Dockerfile
```

## 构建和发布步骤

### 步骤 1: 查看修改
```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker

# 查看 entrypoint 修改
diff docker-entrypoint.sh.bak docker-entrypoint.sh

# 查看 Dockerfile 修改
diff Dockerfile.bak Dockerfile
```

### 步骤 2: 构建新镜像
```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker

# 方式 1: 使用构建脚本
./build.sh

# 方式 2: 手动构建
docker build -t bytedesk/freeswitch:latest .
docker build -t bytedesk/freeswitch:1.10.12 .
```

### 步骤 3: 本地测试
```bash
# 停止旧容器
docker rm -f freeswitch-bytedesk

# 使用新镜像启动测试容器
docker run -d \
  --name freeswitch-test \
  -p 18021:8021 \
  -p 15060:5060 \
  -e FREESWITCH_ESL_PASSWORD=bytedesk123 \
  -e FREESWITCH_DOMAIN=localhost \
  -e TZ=Asia/Shanghai \
  bytedesk/freeswitch:latest

# 等待启动
sleep 20

# 测试 ESL 连接
docker exec freeswitch-test fs_cli -p bytedesk123 -x "status"

# 检查日志
docker logs freeswitch-test 2>&1 | grep -E "IPv6|event_socket|ERR"

# 确认没有 IPv6 错误
docker logs freeswitch-test 2>&1 | grep "IPv6: DISABLED"
```

**预期输出**:
```
[INFO] Disabling IPv6 configurations...
[INFO] Removing internal-ipv6 directory...
[INFO] Removing external-ipv6 directory...
[INFO] Configuring event_socket for IPv4 only...
[INFO] IPv6 configurations disabled successfully
[INFO] FreeSWITCH configuration:
[INFO]   - Prefix: /usr/local/freeswitch
[INFO]   - ESL Port: 8021
[INFO]   - SIP Ports: 5060, 5080
[INFO]   - WebRTC Port: 7443
[INFO]   - RTP Ports: 16384-32768
[INFO]   - IPv6: DISABLED
```

### 步骤 4: 推送到镜像仓库

#### 推送到阿里云镜像仓库
```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker

# 方式 1: 使用推送脚本
./push.sh

# 方式 2: 手动推送
# 登录阿里云
docker login registry.cn-hangzhou.aliyuncs.com

# 打标签
docker tag bytedesk/freeswitch:latest registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest
docker tag bytedesk/freeswitch:1.10.12 registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12
docker tag bytedesk/freeswitch:latest registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12-$(date +%Y%m%d)

# 推送
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12
docker push registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12-$(date +%Y%m%d)
```

#### 推送到 Docker Hub（可选）
```bash
# 登录 Docker Hub
docker login

# 推送
docker push bytedesk/freeswitch:latest
docker push bytedesk/freeswitch:1.10.12
```

### 步骤 5: 更新应用配置并测试

#### 5.1 拉取新镜像
```bash
# 停止旧容器
cd /Users/ningjinpeng/Desktop/git/private/github/bytedesk-private/starter/src/main/resources
docker compose -f compose.yaml down bytedesk-freeswitch

# 删除旧镜像
docker rmi registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest

# 拉取新镜像
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest
```

#### 5.2 启用 FreeSwitch 功能
编辑 `application-local.properties`:
```properties
# 启用 FreeSwitch
bytedesk.call.freeswitch.enabled=true
```

#### 5.3 启动容器
```bash
cd /Users/ningjinpeng/Desktop/git/private/github/bytedesk-private/starter/src/main/resources
docker compose -f compose.yaml up -d bytedesk-freeswitch
```

#### 5.4 验证
```bash
# 等待启动
sleep 30

# 运行检查脚本
./check_freeswitch.sh

# 预期结果：
# ✓ 容器存在
# ✓ 容器正在运行
# ✓ 容器健康状态: healthy
# ✓ 端口映射正常
# ✓ ESL 连接成功
```

#### 5.5 启动应用
重新启动 Spring Boot 应用，应该可以成功连接到 FreeSwitch。

## 问题排查

### 如果 ESL 仍然连接失败

1. **检查日志中是否有 IPv6 错误**
```bash
docker logs freeswitch-bytedesk 2>&1 | grep -i ipv6
```

应该看到：
```
[INFO] IPv6: DISABLED
```

不应该看到：
```
[ERR] Cannot get information about IP address ::
```

2. **检查 event_socket 模块是否正常启动**
```bash
docker logs freeswitch-bytedesk 2>&1 | grep event_socket
```

应该看到：
```
Successfully Loaded [mod_event_socket]
Starting runtime thread for mod_event_socket
```

不应该看到：
```
Thread ended for mod_event_socket
```

3. **检查容器内是否真的删除了 IPv6 配置**
```bash
docker exec freeswitch-bytedesk ls -la /usr/local/freeswitch/conf/sip_profiles/ | grep ipv6
```

应该没有任何输出。

4. **手动测试 ESL 连接**
```bash
# 从容器内
docker exec freeswitch-bytedesk fs_cli -p bytedesk123 -x "status"

# 从宿主机
telnet 127.0.0.1 18021
# 然后输入：auth bytedesk123
```

### 如果容器无法启动

1. **检查日志**
```bash
docker logs freeswitch-bytedesk --tail 100
```

2. **检查是否是镜像问题**
```bash
docker run --rm -it bytedesk/freeswitch:latest /bin/bash
# 检查文件是否存在
ls -la /usr/local/bin/docker-entrypoint.sh
cat /usr/local/bin/docker-entrypoint.sh | grep "IPv6"
```

## Git 提交建议

```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker

git add docker-entrypoint.sh Dockerfile
git commit -m "fix: 修复 FreeSwitch ESL IPv6 绑定失败问题

- 在容器启动时自动删除 IPv6 相关的 SIP profiles
- 确保 event_socket 只监听 IPv4 地址
- 修改默认启动参数从 -nc 改为 -nf，适配 Docker 环境
- 添加详细日志输出

修复错误：
[ERR] mod_event_socket.c:2960 Cannot get information about IP address ::
[NOTICE] Thread ended for mod_event_socket

测试：
- 容器可正常启动
- ESL 服务正常工作
- 健康检查通过
- 无 IPv6 相关错误日志
"

git push origin main
```

## 版本说明

- **修复前版本**: `1.10.12` (存在 IPv6 问题)
- **修复后版本**: `1.10.12-20251008` (建议添加日期标签)
- **latest 标签**: 始终指向最新修复版本

## 回滚计划

如果新镜像出现问题，可以快速回滚：

```bash
# 使用备份文件恢复
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker
cp docker-entrypoint.sh.bak docker-entrypoint.sh
cp Dockerfile.bak Dockerfile

# 或者使用旧版本镜像
docker pull registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:1.10.12-backup
```

## 联系信息

如有问题，请联系：
- 邮箱：270580156@qq.com
- GitHub：https://github.com/Bytedesk/bytedesk
