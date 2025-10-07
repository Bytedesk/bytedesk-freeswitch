# FreeSWITCH Docker 项目文件清单

本文档列出了为 FreeSWITCH Docker 镜像创建的所有文件及其用途。

## 📁 项目结构

```
deploy/freeswitch/docker/
├── Dockerfile                  # Docker 镜像构建文件
├── docker-entrypoint.sh       # 容器启动脚本
├── docker-compose.yml         # Docker Compose 配置文件
├── .dockerignore              # Docker 构建忽略文件
├── .env.example               # 环境变量配置示例
├── Makefile                   # Make 命令简化操作
├── README.md                  # 完整使用文档
├── QUICKSTART.md              # 快速开始指南
├── build.sh                   # 镜像构建脚本
├── push.sh                    # 镜像推送脚本
└── conf/                      # FreeSWITCH 配置文件目录
    └── README.md              # 配置文件说明
```

## 📄 文件说明

### 核心文件

#### 1. Dockerfile
- **用途**: Docker 镜像构建定义文件
- **内容**: 
  - 基于 Ubuntu 22.04
  - 安装 FreeSWITCH 1.10.12
  - 配置所有必需的依赖
  - 暴露所需端口
  - 健康检查配置

#### 2. docker-entrypoint.sh
- **用途**: 容器启动入口脚本
- **功能**:
  - 动态配置 ESL 密码
  - 配置 SIP 域名和外部 IP
  - 配置数据库连接
  - 初始化目录结构
  - 启动 FreeSWITCH 服务

#### 3. docker-compose.yml
- **用途**: 单独运行 FreeSWITCH 的配置
- **内容**:
  - 服务定义
  - 端口映射
  - 环境变量
  - 数据卷挂载
  - 健康检查

### 配置文件

#### 4. .dockerignore
- **用途**: 指定 Docker 构建时忽略的文件
- **排除**: 文档、脚本、测试文件等

#### 5. .env.example
- **用途**: 环境变量配置模板
- **包含**:
  - 基础配置
  - 网络配置
  - 数据库配置
  - 安全配置
  - 性能配置

### 脚本文件

#### 6. build.sh
- **用途**: 自动化构建 Docker 镜像
- **功能**:
  - 检查 Docker 环境
  - 构建镜像并打标签
  - 显示构建结果

#### 7. push.sh
- **用途**: 推送镜像到 Docker Hub
- **功能**:
  - 检查镜像是否存在
  - 登录 Docker Hub
  - 推送镜像
  - 显示推送结果

#### 8. Makefile
- **用途**: 简化常用 Docker 操作
- **命令**:
  - `make build` - 构建镜像
  - `make run` - 启动容器
  - `make stop` - 停止容器
  - `make logs` - 查看日志
  - `make cli` - 连接 CLI
  - `make test` - 运行测试
  - `make clean` - 清理资源

### 文档文件

#### 9. README.md
- **用途**: 完整的使用文档
- **内容**:
  - 项目介绍
  - 构建说明
  - 运行指南
  - 配置说明
  - 故障排查
  - 安全建议
  - 生产部署

#### 10. QUICKSTART.md
- **用途**: 快速开始指南
- **内容**:
  - 前置要求
  - 快速开始步骤
  - 配置说明
  - 验证部署
  - 故障排查
  - 常用命令

#### 11. conf/README.md
- **用途**: 配置目录说明
- **内容**:
  - 配置文件准备方法
  - 重要配置说明
  - 注意事项

## 🔧 主项目集成

### 修改的文件

#### starter/src/main/resources/compose.yaml
- **修改内容**: 更新了 FreeSWITCH 服务配置
- **变更**:
  - 使用新的镜像 `bytedesk/freeswitch:1.10.12`
  - 添加详细的环境变量配置
  - 优化端口映射
  - 添加健康检查配置
  - 添加数据持久化配置

## 🚀 使用流程

### 1. 构建镜像

```bash
cd deploy/freeswitch/docker
./build.sh
```

### 2. 测试运行

```bash
# 使用 docker-compose
docker-compose up -d

# 或使用 make
make run
```

### 3. 推送镜像（可选）

```bash
./push.sh
```

### 4. 在主项目中使用

```bash
cd ../../../
docker-compose -f starter/src/main/resources/compose.yaml up -d bytedesk-freeswitch
```

## 📋 快速命令参考

### 使用 Make 命令

```bash
make help          # 显示帮助
make build         # 构建镜像
make run           # 启动容器
make stop          # 停止容器
make logs          # 查看日志
make cli           # 连接 CLI
make shell         # 进入容器
make test          # 运行测试
make clean         # 清理资源
make info          # 显示信息
```

### 使用脚本

```bash
./build.sh         # 构建镜像
./push.sh          # 推送镜像
```

### 使用 Docker Compose

```bash
docker-compose up -d          # 启动
docker-compose down           # 停止
docker-compose logs -f        # 查看日志
docker-compose restart        # 重启
```

## 🔍 验证清单

- [ ] Dockerfile 语法正确
- [ ] docker-entrypoint.sh 可执行
- [ ] docker-compose.yml 配置正确
- [ ] 构建脚本可执行
- [ ] 推送脚本可执行
- [ ] 镜像可以成功构建
- [ ] 容器可以正常启动
- [ ] 健康检查通过
- [ ] ESL 连接成功
- [ ] SIP 端口可访问
- [ ] 配置文件加载正确

## 📝 注意事项

1. **构建时间**: 首次构建需要 20-30 分钟
2. **磁盘空间**: 确保有至少 2GB 可用空间
3. **网络环境**: 需要能访问 GitHub 和各种软件源
4. **配置文件**: conf 目录需要包含 FreeSWITCH 配置文件
5. **端口冲突**: 确保所需端口未被占用
6. **权限问题**: 脚本需要有执行权限
7. **Docker 版本**: 建议使用 Docker 20.10+ 版本

## 🔐 安全建议

1. **修改默认密码**: 
   - ESL 密码必须修改
   - 默认 SIP 用户密码建议修改

2. **限制端口访问**:
   - ESL 端口 8021 不应公开暴露
   - 使用防火墙限制访问

3. **使用环境变量**:
   - 敏感信息不要硬编码
   - 使用 .env 文件或 Docker secrets

4. **生产环境配置**:
   - 启用 TLS/SSL
   - 配置 NAT 穿透
   - 启用访问控制列表

## 📚 相关文档

- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [ByteDesk 文档](https://docs.bytedesk.com/)

## 🆘 获取帮助

如有问题，请：

1. 查看 [README.md](README.md) 完整文档
2. 查看 [QUICKSTART.md](QUICKSTART.md) 快速指南
3. 查看容器日志排查问题
4. 提交 GitHub Issue
5. 联系技术支持: support@bytedesk.com

## 📌 版本信息

- **FreeSWITCH 版本**: 1.10.12
- **基础镜像**: Ubuntu 22.04 LTS
- **文档版本**: 1.0
- **创建日期**: 2025-01-07

---

**项目完成状态**: ✅ 所有文件已创建并配置完成
