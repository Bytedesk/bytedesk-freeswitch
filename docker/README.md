# FreeSWITCH Docker

> 📖 **主要文档已移至项目根目录**  
> 请查看 [../README.md](../README.md) 或 [../README.zh.md](../README.zh.md) 获取完整的使用说明。

## 快速链接

### 📚 文档

- **[主 README (English)](../README.md)** - 完整的英文文档
- **[主 README (中文)](../README.zh.md)** - 完整的中文文档
- **[安全配置指南](./SECURITY.md)** - 详细的安全配置（必读）

### 🚀 快速开始

```bash
# 拉取镜像
docker pull bytedesk/freeswitch:latest

# 运行容器（开发环境）
docker run -d \
  --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021 \
  -e FREESWITCH_ESL_PASSWORD='dev_esl_pass' \
  -e FREESWITCH_DEFAULT_PASSWORD='dev_sip_pass' \
  bytedesk/freeswitch:latest
```

### 🔒 安全警告

⚠️ **必须修改默认密码！** 查看 [SECURITY.md](./SECURITY.md)

- `FREESWITCH_ESL_PASSWORD` - ESL 管理密码（必填）
- `FREESWITCH_DEFAULT_PASSWORD` - SIP 用户密码（默认 `1234`，必须修改）

### 📁 目录结构

```
docker/
├── README.md                  # 本文件（引导文档）
├── SECURITY.md               # 安全配置指南
├── Dockerfile                 # Docker 镜像构建文件
├── docker-entrypoint.sh       # 容器启动脚本
├── docker-compose.yml         # Docker Compose 配置
├── build.sh                   # 构建脚本
├── push.sh                    # 推送脚本
├── Makefile                   # Make 命令
├── .env.example              # 环境变量示例
└── conf/                     # FreeSWITCH 配置文件
    ├── freeswitch.xml
    ├── vars.xml
    ├── autoload_configs/
    ├── dialplan/
    ├── directory/
    └── sip_profiles/
```

### 🛠️ 常用命令

```bash
# 构建镜像
cd docker
./build.sh

# 使用 Docker Compose 启动
docker compose up -d

# 查看日志
docker logs -f freeswitch

# 进入容器
docker exec -it freeswitch bash

# 访问 FreeSWITCH CLI
docker exec -it freeswitch fs_cli -p YOUR_PASSWORD

# 停止容器
docker compose down
```

### 🌐 镜像仓库

- **Docker Hub**: `bytedesk/freeswitch:latest`
- **阿里云**: `registry.cn-hangzhou.aliyuncs.com/bytedesk/freeswitch:latest`

### 📞 支持

- **Email**: support@bytedesk.com
- **GitHub**: https://github.com/Bytedesk/bytedesk-freeswitch/issues
- **文档**: https://docs.bytedesk.com/

---

**维护者**: ByteDesk Team  
**最后更新**: 2025-10-09
