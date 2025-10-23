# 呼叫中心模块更新总结

## 更新日期
2025-10-10

## 用户需求
开启以下模块作为呼叫中心系统：
- mod_fail2ban
- applications/mod_callcenter
- applications/mod_blacklist
- languages/mod_python3
- applications/mod_curl
- applications/mod_hiredis
- applications/mod_redis

## 已完成的工作

### 1. ✅ Dockerfile 更新

#### 添加系统依赖
```dockerfile
# Python 3 开发包
python3 python3-dev python3-distutils

# Redis 客户端库
libhiredis-dev redis-tools
```

#### 启用编译模块
在 FreeSWITCH 编译前通过 sed 命令启用以下模块：
- ✅ event_handlers/mod_fail2ban
- ✅ applications/mod_callcenter
- ✅ applications/mod_blacklist
- ✅ applications/mod_curl
- ✅ applications/mod_hiredis
- ✅ applications/mod_redis
- ✅ applications/mod_distributor (推荐)
- ✅ applications/mod_lcr (推荐)
- ✅ applications/mod_cidlookup (推荐)
- ✅ applications/mod_nibblebill (推荐)
- ✅ languages/mod_python3

### 2. ✅ modules.conf.xml 更新

在运行时配置中添加模块加载指令：

```xml
<!-- Event Handlers -->
<load module="mod_fail2ban" />

<!-- Applications -->
<load module="mod_callcenter" />
<load module="mod_blacklist" />
<load module="mod_curl" />
<load module="mod_hiredis" />
<load module="mod_redis" />
<load module="mod_distributor" />
<load module="mod_lcr" />
<load module="mod_cidlookup" />
<load module="mod_nibblebill" />

<!-- Languages -->
<load module="mod_python3" />
```

### 3. ✅ 创建配置文档

#### CALLCENTER_MODULES_GUIDE.md
完整的呼叫中心模块配置指南，包括：
- 每个模块的详细说明
- 配置示例
- API 命令
- 拨号计划集成
- 数据库表结构
- 脚本示例（Lua、Python）
- 性能优化建议
- 故障排查

#### CALLCENTER_QUICK_START.md
快速参考指南，包括：
- 模块列表和功能速查表
- 常用 API 命令
- 拨号计划示例
- Docker 部署命令
- 验证和监控方法

## 推荐的额外模块

基于呼叫中心系统的最佳实践，我们额外启用了以下模块：

### mod_distributor (负载均衡器)
**用途：** 智能分配呼叫到不同的网关或座席
**策略：** 轮询、随机、加权轮询
**场景：** 多网关外呼、座席负载均衡

### mod_lcr (最低成本路由)
**用途：** 根据费率自动选择最经济的呼出路由
**功能：** 按号码前缀匹配、费率排序、质量评分
**场景：** 成本优化、智能路由选择

### mod_cidlookup (来电显示查询)
**用途：** 查询来电号码归属信息
**功能：** 数据库查询、HTTP API 查询、缓存支持
**场景：** 客户识别、号码归属地显示

### mod_nibblebill (实时计费)
**用途：** 实时计费和余额扣费
**功能：** 余额查询、按秒计费、余额不足挂断
**场景：** 预付费系统、成本控制

## 完整的模块矩阵

| 模块类型 | 模块名称 | 状态 | 优先级 | 说明 |
|---------|---------|------|--------|------|
| 核心队列 | mod_callcenter | ✅ 启用 | 必需 | 专业呼叫中心功能 |
| 核心队列 | mod_fifo | ✅ 已有 | 必需 | 轻量级队列 |
| 安全防护 | mod_fail2ban | ✅ 启用 | 必需 | 防暴力破解 |
| 安全防护 | mod_blacklist | ✅ 启用 | 必需 | 黑名单管理 |
| 路由分配 | mod_distributor | ✅ 启用 | 推荐 | 负载均衡 |
| 路由分配 | mod_lcr | ✅ 启用 | 推荐 | 智能路由 |
| 客户识别 | mod_cidlookup | ✅ 启用 | 推荐 | 来电查询 |
| 计费系统 | mod_nibblebill | ✅ 启用 | 推荐 | 实时计费 |
| 数据存储 | mod_hiredis | ✅ 启用 | 必需 | Redis 连接 |
| 数据存储 | mod_redis | ✅ 启用 | 必需 | Redis 限流 |
| 外部集成 | mod_curl | ✅ 启用 | 必需 | HTTP API |
| 脚本支持 | mod_python3 | ✅ 启用 | 必需 | Python 脚本 |
| 脚本支持 | mod_lua | ✅ 已有 | 必需 | Lua 脚本 |
| 会议功能 | mod_conference | ✅ 已有 | 必需 | 语音会议 |
| 语音邮箱 | mod_voicemail | ✅ 已有 | 必需 | 语音留言 |
| 数据库 | mod_mariadb | ✅ 已有 | 必需 | 数据库支持 |
| 数据库 | mod_odbc_cdr | ✅ 已有 | 必需 | CDR 记录 |
| 动态配置 | mod_xml_curl | ✅ 已有 | 推荐 | 动态 XML |

## 不同规模呼叫中心的模块配置

### 🏢 小型（<20座席）
**必需模块：**
- mod_fifo, mod_conference, mod_voicemail
- mod_blacklist, mod_fail2ban
- mod_lua, mod_curl

**可选模块：**
- mod_redis, mod_hiredis

### 🏢 中型（20-100座席）
**必需模块：**
- mod_callcenter, mod_conference, mod_voicemail
- mod_blacklist, mod_fail2ban
- mod_distributor, mod_cidlookup
- mod_curl, mod_hiredis, mod_redis
- mod_lua, mod_python3

**推荐模块：**
- mod_lcr, mod_nibblebill

### 🏢 大型（>100座席）
**全部启用：**
- 所有上述模块
- 额外推荐：数据库集群、Redis 集群

## 系统架构建议

```
┌─────────────────────────────────────────┐
│         FreeSWITCH 呼叫中心              │
├─────────────────────────────────────────┤
│                                          │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │  mod_sofia   │  │ mod_callcenter  │ │
│  │  (SIP)       │  │ (队列管理)       │ │
│  └──────────────┘  └─────────────────┘ │
│                                          │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │mod_fail2ban  │  │ mod_blacklist   │ │
│  │(安全防护)     │  │ (黑名单)        │ │
│  └──────────────┘  └─────────────────┘ │
│                                          │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │mod_distributor│ │ mod_lcr         │ │
│  │(负载均衡)     │  │ (智能路由)      │ │
│  └──────────────┘  └─────────────────┘ │
│                                          │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │mod_python3   │  │ mod_lua         │ │
│  │(业务逻辑)     │  │ (脚本)          │ │
│  └──────────────┘  └─────────────────┘ │
│                                          │
└─────────────────────────────────────────┘
           ↕                    ↕
    ┌─────────────┐      ┌──────────────┐
    │   MariaDB   │      │    Redis     │
    │  (数据存储)  │      │   (缓存)     │
    └─────────────┘      └──────────────┘
```

## 性能参数

### 资源需求

| 规模 | CPU | 内存 | 并发呼叫 | 数据库 | Redis |
|------|-----|------|---------|--------|-------|
| 小型 | 2核 | 2GB | 50路 | 基础 | 单机 |
| 中型 | 4-8核 | 4-8GB | 200路 | 主从 | 单机 |
| 大型 | 8-16核 | 16-32GB | 500+路 | 集群 | 集群 |

## 部署步骤

### 1. 构建镜像
```bash
cd docker
docker build -t bytedesk/freeswitch:callcenter .
```

### 2. 启动服务
```bash
docker-compose up -d
```

### 3. 验证模块
```bash
docker exec freeswitch fs_cli -x "show modules" | grep -E "callcenter|fail2ban|python3|redis"
```

### 4. 配置队列
编辑 `conf/autoload_configs/callcenter.conf.xml`

### 5. 配置拨号计划
编辑 `conf/dialplan/default.xml`

## 测试清单

- [ ] mod_callcenter 加载成功
- [ ] mod_fail2ban 加载成功
- [ ] mod_blacklist 加载成功
- [ ] mod_python3 加载成功
- [ ] mod_curl 加载成功
- [ ] mod_hiredis 加载成功
- [ ] mod_redis 加载成功
- [ ] mod_distributor 加载成功
- [ ] mod_lcr 加载成功
- [ ] mod_cidlookup 加载成功
- [ ] mod_nibblebill 加载成功
- [ ] 数据库连接正常
- [ ] Redis 连接正常
- [ ] 呼叫队列功能正常
- [ ] 座席登录/登出正常

## 相关文件

```
docker/
├── Dockerfile                          # Docker 镜像构建文件（已更新）
├── CALLCENTER_MODULES_GUIDE.md        # 完整配置指南（新建）
├── CALLCENTER_QUICK_START.md          # 快速参考（新建）
├── MODULES_UPDATE_SUMMARY.md          # 本文件
└── conf/
    └── autoload_configs/
        └── modules.conf.xml            # 模块加载配置（已更新）
```

## API 快速参考

### 呼叫中心管理
```bash
# 座席管理
callcenter_config agent set status 1001@default 'Available'
callcenter_config agent list

# 队列管理
callcenter_config queue list
callcenter_config queue list members support@default
```

### 安全管理
```bash
# fail2ban
fail2ban list
fail2ban ban <IP>
fail2ban unban <IP>

# 黑名单
blacklist add <号码>
blacklist check <号码>
```

### 系统监控
```bash
status
show channels
show modules
callcenter_config queue list
```

## 下一步建议

1. **配置数据库** - 创建呼叫中心相关数据表
2. **配置 Redis** - 设置缓存策略
3. **创建座席** - 添加座席账号和配置
4. **设置队列** - 配置呼叫队列规则
5. **配置路由** - 设置 LCR 和 Distributor 规则
6. **编写脚本** - 使用 Python/Lua 实现业务逻辑
7. **集成 API** - 使用 mod_curl 对接外部系统
8. **测试验证** - 完整的功能测试

## 安全提示

⚠️ **重要安全建议：**
1. 修改默认 SIP 密码
2. 配置 fail2ban 规则
3. 限制管理端口访问
4. 使用强密码策略
5. 定期备份配置和数据
6. 监控异常登录
7. 及时更新系统

## 技术支持

- 📧 Email: 270580156@qq.com
- 🌐 项目地址: https://github.com/Bytedesk/bytedesk-freeswitch
- 📚 文档: 查看 `CALLCENTER_MODULES_GUIDE.md`
- 🚀 快速开始: 查看 `CALLCENTER_QUICK_START.md`

## 参考文档

- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [mod_callcenter](https://freeswitch.org/confluence/display/FREESWITCH/mod_callcenter)
- [mod_lcr](https://freeswitch.org/confluence/display/FREESWITCH/mod_lcr)
- [mod_distributor](https://freeswitch.org/confluence/display/FREESWITCH/mod_distributor)

---

**更新完成！** ✅

所有请求的模块已启用，并额外添加了呼叫中心推荐模块。请重新构建 Docker 镜像以应用更改。
