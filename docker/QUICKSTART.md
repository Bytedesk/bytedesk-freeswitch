# FreeSWITCH Docker 快速开始指南

本指南帮助您快速构建和部署 FreeSWITCH Docker 镜像。

## 📋 前置要求

- Docker 已安装（版本 20.10+）
- Docker Compose 已安装（版本 1.29+）
- Git 已安装
- 2GB+ 可用磁盘空间

## 🚀 快速开始

### 步骤 1: 进入 Docker 目录

```bash
cd deploy/freeswitch/docker
```

### 步骤 2: 构建镜像

```bash
# 赋予脚本执行权限
chmod +x build.sh push.sh

# 构建 Docker 镜像
./build.sh

# 构建过程需要 20-30 分钟，请耐心等待
```

构建成功后会看到：
```
✓ Build completed successfully!
  - bytedesk/freeswitch:1.10.12
  - bytedesk/freeswitch:latest
```

### 步骤 3: 测试运行（可选）

```bash
# 使用 docker-compose 启动测试
docker-compose up -d

# 查看日志
docker-compose logs -f freeswitch

# 测试完成后停止
docker-compose down
```

### 步骤 4: 推送到 Docker Hub（可选）

如果您想将镜像推送到 Docker Hub：

```bash
# 登录 Docker Hub
docker login

# 推送镜像
./push.sh
```

> **注意**: 推送到 Docker Hub 需要修改镜像名称为您自己的仓库名。

## 📦 在 ByteDesk 项目中使用

### 方法一：使用已构建的本地镜像

在 `starter/src/main/resources/compose.yaml` 中，FreeSWITCH 服务已配置好：

```bash
# 返回项目根目录
cd ../../..

# 启动所有服务（包括 FreeSWITCH）
docker-compose -f starter/src/main/resources/compose.yaml up -d

# 或只启动 FreeSWITCH
docker-compose -f starter/src/main/resources/compose.yaml up -d bytedesk-freeswitch
```

### 方法二：使用 Docker Hub 镜像

如果镜像已推送到 Docker Hub，其他环境可以直接使用：

```yaml
services:
  bytedesk-freeswitch:
    image: bytedesk/freeswitch:1.10.12  # 或使用 :latest
    # ... 其他配置
```

## 🔧 配置说明

### 必需的环境变量

```yaml
environment:
  - FREESWITCH_ESL_PASSWORD=bytedesk123  # ESL 连接密码
```

### 生产环境推荐配置

```yaml
environment:
  - FREESWITCH_ESL_PASSWORD=your-strong-password
  - FREESWITCH_DOMAIN=your-domain.com
  - FREESWITCH_EXTERNAL_IP=your-public-ip  # 公网 IP
  - TZ=Asia/Shanghai
```

### 数据库集成（可选）

连接到 ByteDesk MySQL：

```yaml
environment:
  - FREESWITCH_DB_HOST=bytedesk-mysql
  - FREESWITCH_DB_NAME=freeswitch
  - FREESWITCH_DB_USER=root
  - FREESWITCH_DB_PASSWORD=r8FqfdbWUaN3
  - FREESWITCH_DB_PORT=3306
```

## 📝 验证部署

### 1. 检查容器状态

```bash
docker ps | grep freeswitch
```

应该看到容器状态为 `healthy`。

### 2. 查看日志

```bash
docker logs -f freeswitch-bytedesk
```

### 3. 连接 FreeSWITCH CLI

```bash
docker exec -it freeswitch-bytedesk fs_cli -p bytedesk123
```

在 CLI 中执行：
```
status
sofia status
```

### 4. 测试 ESL 连接

```bash
telnet localhost 8021
```

### 5. 使用 SIP 客户端测试

下载 [LinPhone](https://www.linphone.org/en/download/)，配置：

- Username: `1000`
- Password: `1234`
- Domain: `localhost` (或您的服务器 IP)
- Transport: `UDP`

拨打测试号码：
- `9196` - 回音测试（无延迟）
- `9664` - 保持音乐

## 🐛 故障排查

### 问题 1: 构建失败

**错误**: 下载依赖失败

**解决方案**:
```bash
# 检查网络连接
# 重试构建
./build.sh
```

### 问题 2: 容器无法启动

**检查日志**:
```bash
docker logs freeswitch-bytedesk
```

**常见原因**:
- 端口被占用（检查 5060, 8021 端口）
- 权限问题
- 配置文件错误

### 问题 3: 无法连接 ESL

**检查**:
1. 端口 8021 是否开放
2. ESL 密码是否正确
3. 防火墙设置

```bash
# 测试端口
nc -zv localhost 8021

# 查看容器网络
docker inspect freeswitch-bytedesk | grep IPAddress
```

### 问题 4: SIP 注册失败

**检查**:
1. 端口 5060 是否开放
2. 域名/IP 配置是否正确
3. NAT 设置（生产环境）

```bash
# 查看 SIP 状态
docker exec -it freeswitch-bytedesk fs_cli -x "sofia status"
```

## 📚 更多信息

### 文档链接

- [完整 README](README.md) - 详细文档
- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [ByteDesk 文档](https://docs.bytedesk.com/)

### 常用命令

```bash
# 构建镜像
./build.sh [version]

# 推送镜像
./push.sh [version]

# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 进入容器
docker exec -it freeswitch-bytedesk bash

# 连接 CLI
docker exec -it freeswitch-bytedesk fs_cli -p bytedesk123
```

### 端口说明

| 端口 | 协议 | 说明 |
|------|------|------|
| 5060 | TCP/UDP | SIP 内部 |
| 5080 | TCP/UDP | SIP 外部 |
| 8021 | TCP | ESL 管理 |
| 7443 | TCP | WebRTC WSS |
| 16384-32768 | UDP | RTP 媒体流 |

## 🔒 安全建议

1. **修改默认密码**: 
   ```yaml
   - FREESWITCH_ESL_PASSWORD=your-strong-password
   ```

2. **限制 ESL 访问**: 
   只允许特定 IP 访问 8021 端口

3. **使用 TLS**: 
   生产环境启用 SIP TLS (5061/5081)

4. **防火墙配置**: 
   只开放必要的端口

5. **定期更新**: 
   保持镜像版本更新

## 💡 提示

- 首次构建需要下载大量依赖，耗时较长
- 配置文件可以通过挂载卷自定义
- 建议在测试环境先验证配置
- 生产环境务必配置外部 IP 和 NAT
- RTP 端口范围根据并发数调整

## 🆘 获取帮助

如有问题，请：

1. 查看日志：`docker logs freeswitch-bytedesk`
2. 检查配置：确认环境变量和端口映射
3. 参考文档：[README.md](README.md)
4. 提交 Issue：GitHub Issues
5. 联系支持：support@bytedesk.com

---

**祝您使用愉快！** 🎉
