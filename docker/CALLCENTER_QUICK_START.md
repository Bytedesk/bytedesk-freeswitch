# 呼叫中心模块快速参考

## 已启用的模块列表

### ✅ 用户请求的模块
- ✅ mod_fail2ban - 安全防护，防暴力破解
- ✅ mod_callcenter - 呼叫中心核心功能
- ✅ mod_blacklist - 黑名单管理
- ✅ mod_python3 - Python 3 脚本支持
- ✅ mod_java - Java 语言支持
- ✅ mod_curl - HTTP API 集成
- ✅ mod_hiredis - Redis 连接
- ✅ mod_redis - Redis 限流功能

### 💡 额外推荐的呼叫中心模块
- ✅ mod_distributor - 负载均衡和呼叫分配
- ✅ mod_lcr - 最低成本路由（智能路由选择）
- ✅ mod_cidlookup - 来电显示查询（号码归属地）
- ✅ mod_nibblebill - 实时计费扣费

### 📦 已有的基础模块
- ✅ mod_fifo - FIFO 队列（轻量级队列）
- ✅ mod_conference - 会议功能
- ✅ mod_voicemail - 语音邮箱
- ✅ mod_lua - Lua 脚本支持
- ✅ mod_python3 - Python 3 脚本支持
- ✅ mod_java - Java 语言支持
- ✅ mod_odbc_cdr - ODBC CDR 记录
- ✅ mod_xml_curl - 动态 XML 配置
- ✅ mod_mariadb - MariaDB 数据库支持

## 模块功能速查

| 模块 | 主要功能 | 使用场景 |
|------|---------|---------|
| mod_callcenter | 队列、座席、技能路由 | 专业呼叫中心 |
| mod_fifo | 简单队列 | 小型团队 |
| mod_distributor | 负载均衡 | 多网关分配 |
| mod_lcr | 最低成本路由 | 成本优化 |
| mod_cidlookup | 来电查询 | 客户识别 |
| mod_nibblebill | 实时计费 | 预付费系统 |
| mod_blacklist | 黑名单 | 骚扰拦截 |
| mod_fail2ban | 安全防护 | 防暴力破解 |
| mod_curl | HTTP 请求 | API 集成 |
| mod_hiredis | Redis 连接 | 高性能缓存 |
| mod_redis | Redis 限流 | 并发控制 |
| mod_python3 | Python 脚本 | 复杂业务逻辑 |
| mod_lua | Lua 脚本 | 轻量级脚本 |

## 常用 API 命令

### mod_callcenter
```bash
# 座席管理
callcenter_config agent set status 1001@default 'Available'
callcenter_config agent set status 1001@default 'Logged Out'
callcenter_config agent list

# 队列管理
callcenter_config queue list
callcenter_config queue list members support@default
callcenter_config tier add 1001@default support@default 1 1
```

### mod_fail2ban
```bash
# 查看封禁列表
fail2ban list

# 封禁/解封 IP
fail2ban ban 192.168.1.100
fail2ban unban 192.168.1.100
```

### mod_blacklist
```bash
# 黑名单管理
blacklist add 13800138000
blacklist del 13800138000
blacklist check 13800138000
```

### mod_hiredis
```bash
# Redis 命令
hiredis_raw default SET key value
hiredis_raw default GET key
hiredis_raw default DEL key
```

## 拨号计划示例

### 呼叫中心队列
```xml
<extension name="queue">
  <condition field="destination_number" expression="^6000$">
    <action application="answer"/>
    <action application="callcenter" data="support"/>
  </condition>
</extension>
```

### 黑名单检查
```xml
<extension name="blacklist_check">
  <condition field="${blacklist(check ${caller_id_number})}" expression="^true$">
    <action application="hangup" data="CALL_REJECTED"/>
  </condition>
</extension>
```

### 负载均衡
```xml
<extension name="load_balance">
  <condition field="destination_number" expression="^9(\d+)$">
    <action application="set" data="gateway=${distributor(gateways)}"/>
    <action application="bridge" data="sofia/gateway/${gateway}/$1"/>
  </condition>
</extension>
```

### LCR 路由
```xml
<extension name="lcr">
  <condition field="destination_number" expression="^9(\d+)$">
    <action application="lcr" data="$1"/>
    <action application="bridge" data="${lcr_auto_route}"/>
  </condition>
</extension>
```

### 实时计费
```xml
<extension name="billing">
  <condition field="destination_number" expression="^9(\d+)$">
    <action application="set" data="nibble_rate=0.10"/>
    <action application="nibblebill" data="check"/>
    <action application="bridge" data="sofia/gateway/provider/$1"/>
  </condition>
</extension>
```

### API 集成
```xml
<extension name="api_verify">
  <condition field="destination_number" expression="^8(\d+)$">
    <action application="set" data="result=${curl(http://api.example.com/verify?caller=${caller_id_number})}"/>
    <action application="log" data="INFO ${result}"/>
  </condition>
</extension>
```

## 配置文件位置

```
/usr/local/freeswitch/conf/autoload_configs/
├── modules.conf.xml          # 模块加载配置
├── callcenter.conf.xml       # 呼叫中心
├── distributor.conf.xml      # 负载均衡
├── lcr.conf.xml              # LCR 路由
├── cidlookup.conf.xml        # 来电查询
├── nibblebill.conf.xml       # 计费
├── hiredis.conf.xml          # Redis
├── fail2ban.conf.xml         # 安全
└── curl.conf.xml             # HTTP
```

## 系统要求

### 必需的系统包
```bash
# 已在 Dockerfile 中安装
- python3, python3-dev, python3-distutils  # Python3 支持
- libhiredis-dev, redis-tools              # Redis 支持
- libcurl4-openssl-dev                     # cURL 支持
- unixodbc-dev, odbc-mariadb              # ODBC 支持
```

## 构建 Docker 镜像

```bash
cd docker
docker build -t bytedesk/freeswitch:callcenter .
```

## 启动容器

### 基础启动
```bash
docker run -d \
  --name freeswitch \
  -p 5060:5060/udp \
  -p 5080:5080/udp \
  -p 8021:8021 \
  -p 16384-32768:16384-32768/udp \
  bytedesk/freeswitch:callcenter
```

### 带数据库配置
```bash
docker run -d \
  --name freeswitch \
  -e FREESWITCH_DB_HOST=mysql \
  -e FREESWITCH_DB_NAME=freeswitch \
  -e FREESWITCH_DB_USER=root \
  -e FREESWITCH_DB_PASSWORD=password \
  -p 5060:5060/udp \
  -p 5080:5080/udp \
  -p 8021:8021 \
  -p 16384-32768:16384-32768/udp \
  --link mysql:mysql \
  --link redis:redis \
  bytedesk/freeswitch:callcenter
```

### Docker Compose
```yaml
version: '3'
services:
  mysql:
    image: mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: freeswitch
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

  freeswitch:
    image: bytedesk/freeswitch:callcenter
    depends_on:
      - mysql
      - redis
    environment:
      FREESWITCH_DB_HOST: mysql
      FREESWITCH_DB_NAME: freeswitch
      FREESWITCH_DB_USER: root
      FREESWITCH_DB_PASSWORD: password
    ports:
      - "5060:5060/udp"
      - "5080:5080/udp"
      - "8021:8021"
      - "16384-32768:16384-32768/udp"
    volumes:
      - ./conf:/usr/local/freeswitch/conf
      - freeswitch_logs:/usr/local/freeswitch/log

volumes:
  mysql_data:
  redis_data:
  freeswitch_logs:
```

## 验证模块加载

```bash
# 进入容器
docker exec -it freeswitch fs_cli

# 检查模块
show modules | grep callcenter
show modules | grep fail2ban
show modules | grep blacklist
show modules | grep python3
show modules | grep curl
show modules | grep redis
show modules | grep hiredis
show modules | grep distributor
show modules | grep lcr
show modules | grep cidlookup
show modules | grep nibblebill
```

## 监控和诊断

### 实时日志
```bash
docker logs -f freeswitch
```

### 进入 fs_cli
```bash
docker exec -it freeswitch fs_cli
```

### 检查系统状态
```bash
fs_cli -x "status"
fs_cli -x "show channels"
fs_cli -x "callcenter_config queue list"
```

## 性能建议

### 小型系统（<20座席）
- CPU: 2 核
- 内存: 2GB
- 并发: 50 路

### 中型系统（20-100座席）
- CPU: 4-8 核
- 内存: 4-8GB
- 并发: 200 路

### 大型系统（>100座席）
- CPU: 8-16 核
- 内存: 16-32GB
- 并发: 500+ 路
- 建议: 使用 Redis 集群 + 数据库主从

## 故障排查

### 模块加载失败
```bash
# 查看错误日志
docker exec freeswitch tail -f /usr/local/freeswitch/log/freeswitch.log

# 检查模块文件
docker exec freeswitch ls -la /usr/local/freeswitch/mod/ | grep -E "callcenter|fail2ban|python3"
```

### 数据库连接失败
```bash
# 测试数据库连接
docker exec freeswitch fs_cli -x "lua"
# 在 Lua 中测试
dbh = freeswitch.Dbh("mariadb", "host=mysql;db=freeswitch;user=root;pass=password")
print(dbh:connected())
```

### Redis 连接失败
```bash
# 测试 Redis
docker exec redis redis-cli ping

# 在 FreeSWITCH 中测试
docker exec freeswitch fs_cli -x "hiredis_raw default PING"
```

## 下一步

1. ✅ **配置呼叫中心队列** - 编辑 `callcenter.conf.xml`
2. ✅ **设置座席账号** - 在数据库或配置文件中添加
3. ✅ **配置拨号计划** - 编辑 `dialplan/default.xml`
4. ✅ **配置路由规则** - 设置 LCR 和 Distributor
5. ✅ **启用安全防护** - 配置 fail2ban 规则
6. ✅ **集成外部系统** - 使用 mod_curl 和 API

## 参考文档

- [完整配置指南](./CALLCENTER_MODULES_GUIDE.md)
- [模块说明](./MODULES_EXPLANATION.md)
- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)

---

**最后更新：** 2025-10-10  
**维护者：** ByteDesk Team
