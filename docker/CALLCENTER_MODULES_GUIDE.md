# FreeSWITCH 呼叫中心模块配置指南

## 概述

本文档详细说明了 ByteDesk 呼叫中心系统中启用的 FreeSWITCH 模块，包括配置方法和使用场景。

## 已启用的模块列表

### 1. 核心呼叫中心模块

#### 1.1 mod_callcenter (呼叫中心核心)
**用途：** 提供完整的呼叫中心功能，包括队列管理、座席管理、技能路由等。

**配置文件：** `autoload_configs/callcenter.conf.xml`

**主要功能：**
- 呼叫队列管理
- 座席状态管理（就绪、忙碌、小休、示忙等）
- 技能路由（Skill-based Routing）
- 队列优先级
- 等待音乐和提示音
- 座席性能统计
- 实时队列监控

**配置示例：**
```xml
<configuration name="callcenter.conf" description="CallCenter">
  <settings>
    <param name="odbc-dsn" value="mariadb://Server=mysql;Port=3306;Database=freeswitch;Uid=root;Pwd=password;"/>
    <!-- 使用数据库存储座席和队列配置 -->
    <param name="dbname" value="callcenter"/>
  </settings>

  <queues>
    <queue name="support">
      <param name="strategy" value="longest-idle-agent"/>
      <param name="moh-sound" value="$${hold_music}"/>
      <param name="time-base-score" value="queue"/>
      <param name="max-wait-time" value="0"/>
      <param name="max-wait-time-with-no-agent" value="120"/>
      <param name="max-wait-time-with-no-agent-time-reached" value="5"/>
      <param name="tier-rules-apply" value="false"/>
      <param name="tier-rule-wait-second" value="300"/>
      <param name="tier-rule-no-agent-no-wait" value="false"/>
      <param name="discard-abandoned-after" value="60"/>
      <param name="abandoned-resume-allowed" value="false"/>
    </queue>
  </queues>

  <agents>
    <agent name="1001@default" type="callback" contact="[call_timeout=30]user/1001" status="Logged Out"/>
    <agent name="1002@default" type="callback" contact="[call_timeout=30]user/1002" status="Logged Out"/>
  </agents>

  <tiers>
    <!-- 将座席分配到队列 -->
    <tier agent="1001@default" queue="support" level="1" position="1"/>
    <tier agent="1002@default" queue="support" level="1" position="2"/>
  </tiers>
</configuration>
```

**API 命令：**
```bash
# 座席登录
callcenter_config agent set status 1001@default 'Available'

# 座席登出
callcenter_config agent set status 1001@default 'Logged Out'

# 查看队列状态
callcenter_config queue list

# 查看座席状态
callcenter_config agent list

# 将呼叫加入队列
<action application="callcenter" data="support"/>
```

#### 1.2 mod_fifo (先进先出队列)
**用途：** 简单的先进先出呼叫队列，适合小型呼叫中心或简单场景。

**特点：**
- 比 mod_callcenter 更轻量
- 支持多个队列
- 支持座席手动签入/签出
- 支持等待音乐

**使用场景：**
- 小型团队（<10人）
- 简单的呼叫排队需求
- 不需要复杂的技能路由

**拨号计划示例：**
```xml
<extension name="fifo_queue">
  <condition field="destination_number" expression="^6000$">
    <action application="answer"/>
    <action application="fifo" data="myqueue in"/>
  </condition>
</extension>

<!-- 座席拨打 6001 接听队列 -->
<extension name="fifo_agent">
  <condition field="destination_number" expression="^6001$">
    <action application="answer"/>
    <action application="fifo" data="myqueue out nowait"/>
  </condition>
</extension>
```

### 2. 安全和防护模块

#### 2.1 mod_fail2ban
**用途：** 自动检测和阻止暴力破解攻击，保护 SIP 服务器安全。

**配置文件：** `autoload_configs/fail2ban.conf.xml`

**功能：**
- 监控认证失败事件
- 自动封禁恶意 IP
- 支持白名单
- 可配置封禁时间

**配置示例：**
```xml
<configuration name="fail2ban.conf" description="Fail2ban Configuration">
  <settings>
    <!-- 检测窗口时间（秒） -->
    <param name="time-window" value="300"/>
    <!-- 失败次数阈值 -->
    <param name="max-attempts" value="5"/>
    <!-- 封禁时长（秒），0 表示永久 -->
    <param name="ban-time" value="3600"/>
    <!-- 白名单 IP -->
    <param name="whitelist" value="192.168.1.0/24,10.0.0.0/8"/>
  </settings>
</configuration>
```

**API 命令：**
```bash
# 查看被封禁的 IP
fail2ban list

# 手动封禁 IP
fail2ban ban <IP地址>

# 解封 IP
fail2ban unban <IP地址>

# 清空所有封禁
fail2ban clear
```

#### 2.2 mod_blacklist
**用途：** 黑名单管理，阻止特定号码或 IP 的呼叫。

**功能：**
- 支持号码黑名单
- 支持 IP 黑名单
- 支持正则表达式匹配
- 可与数据库集成

**拨号计划示例：**
```xml
<extension name="check_blacklist">
  <condition field="${blacklist(check ${caller_id_number})}" expression="^true$">
    <action application="respond" data="403 Forbidden"/>
    <action application="hangup"/>
  </condition>
</extension>
```

**API 命令：**
```bash
# 添加号码到黑名单
blacklist add 13800138000

# 从黑名单移除
blacklist del 13800138000

# 检查号码是否在黑名单
blacklist check 13800138000
```

### 3. 路由和分配模块

#### 3.1 mod_distributor (负载均衡)
**用途：** 按照策略分配呼叫到不同的网关或座席。

**配置文件：** `autoload_configs/distributor.conf.xml`

**支持的策略：**
- `round-robin` - 轮询
- `random` - 随机
- `weighted-round-robin` - 加权轮询

**配置示例：**
```xml
<configuration name="distributor.conf" description="Distributor Configuration">
  <lists>
    <!-- 定义网关组 -->
    <list name="gateways" total-weight="0">
      <node name="gateway1" weight="1"/>
      <node name="gateway2" weight="1"/>
      <node name="gateway3" weight="2"/>
    </list>
  </lists>
</configuration>
```

**拨号计划示例：**
```xml
<extension name="outbound_call">
  <condition field="destination_number" expression="^9(\d+)$">
    <action application="set" data="gateway=${distributor(gateways)}"/>
    <action application="bridge" data="sofia/gateway/${gateway}/$1"/>
  </condition>
</extension>
```

#### 3.2 mod_lcr (最低成本路由)
**用途：** 根据费率自动选择最经济的呼出路由。

**配置文件：** `autoload_configs/lcr.conf.xml`

**功能：**
- 按号码前缀匹配路由
- 按费率排序
- 支持时间段费率
- 支持网关质量评分

**配置示例：**
```xml
<configuration name="lcr.conf" description="LCR Configuration">
  <settings>
    <param name="odbc-dsn" value="mariadb://Server=mysql;Port=3306;Database=freeswitch;Uid=root;Pwd=password;"/>
  </settings>
  
  <profiles>
    <profile name="default">
      <param name="order_by" value="rate"/>
      <param name="id_column" value="id"/>
      <param name="digits_column" value="digits"/>
      <param name="rate_column" value="rate"/>
      <param name="carrier_column" value="carrier"/>
    </profile>
  </profiles>
</configuration>
```

**数据库表结构：**
```sql
CREATE TABLE lcr (
    id INT PRIMARY KEY AUTO_INCREMENT,
    digits VARCHAR(20),      -- 号码前缀
    rate DECIMAL(10,5),      -- 每分钟费率
    carrier VARCHAR(50),     -- 运营商名称
    gateway VARCHAR(100),    -- 网关地址
    enabled TINYINT(1)       -- 是否启用
);
```

**拨号计划示例：**
```xml
<extension name="lcr_outbound">
  <condition field="destination_number" expression="^9(\d+)$">
    <action application="lcr" data="$1"/>
    <action application="bridge" data="${lcr_auto_route}"/>
  </condition>
</extension>
```

#### 3.3 mod_cidlookup (来电显示查询)
**用途：** 查询来电号码的归属信息，显示公司名称、部门等。

**配置文件：** `autoload_configs/cidlookup.conf.xml`

**功能：**
- 从数据库查询号码信息
- 支持 HTTP API 查询
- 支持缓存
- 自动更新来电显示名称

**配置示例：**
```xml
<configuration name="cidlookup.conf" description="CID Lookup">
  <settings>
    <param name="url" value="http://api.example.com/lookup?number=${caller_id_number}"/>
    <param name="cache" value="true"/>
    <param name="cache-expire" value="3600"/>
  </settings>
</configuration>
```

**拨号计划示例：**
```xml
<extension name="cidlookup">
  <condition field="destination_number" expression="^(.*)$">
    <action application="cidlookup" data="${caller_id_number}"/>
    <action application="set" data="effective_caller_id_name=${cidlookup(name)}"/>
  </condition>
</extension>
```

### 4. 计费模块

#### 4.1 mod_nibblebill (实时计费)
**用途：** 实时计费和余额扣费，防止欠费呼叫。

**配置文件：** `autoload_configs/nibblebill.conf.xml`

**功能：**
- 实时余额查询
- 按秒计费
- 余额不足自动挂断
- 支持心跳扣费
- 支持最小计费单位

**配置示例：**
```xml
<configuration name="nibblebill.conf" description="Nibblebill Configuration">
  <settings>
    <!-- 数据库连接 -->
    <param name="db_dsn" value="mariadb://Server=mysql;Port=3306;Database=billing;Uid=root;Pwd=password;"/>
    
    <!-- 余额查询 SQL -->
    <param name="db_column_cash" value="SELECT balance FROM accounts WHERE id='${caller_id_number}'"/>
    
    <!-- 扣费 SQL -->
    <param name="db_column_account" value="UPDATE accounts SET balance=balance-${nibble_total_billed} WHERE id='${caller_id_number}'"/>
    
    <!-- 心跳间隔（秒） -->
    <param name="heartbeat" value="60"/>
    
    <!-- 最低余额预警 -->
    <param name="lowbal_amt" value="5"/>
    <param name="lowbal_action" value="play ivr/ivr-low_balance.wav"/>
    
    <!-- 余额不足挂断 -->
    <param name="nobal_amt" value="0"/>
    <param name="nobal_action" value="hangup"/>
  </settings>
</configuration>
```

**拨号计划示例：**
```xml
<extension name="billing_outbound">
  <condition field="destination_number" expression="^9(\d+)$">
    <!-- 设置费率（每分钟） -->
    <action application="set" data="nibble_rate=0.10"/>
    <action application="nibblebill" data="check"/>
    <action application="bridge" data="sofia/gateway/provider/$1"/>
  </condition>
</extension>
```

**数据库表结构：**
```sql
CREATE TABLE accounts (
    id VARCHAR(50) PRIMARY KEY,
    balance DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'CNY'
);

CREATE TABLE cdr_billing (
    uuid VARCHAR(255) PRIMARY KEY,
    caller_id VARCHAR(50),
    destination VARCHAR(50),
    duration INT,
    billsec INT,
    rate DECIMAL(10,5),
    cost DECIMAL(10,2),
    timestamp DATETIME
);
```

### 5. 数据存储和缓存

#### 5.1 mod_hiredis (Redis 客户端)
**用途：** 连接 Redis 服务器，提供高性能缓存和数据存储。

**配置文件：** `autoload_configs/hiredis.conf.xml`

**功能：**
- 连接 Redis 服务器
- 支持集群和哨兵模式
- 提供 API 接口
- 支持发布/订阅

**配置示例：**
```xml
<configuration name="hiredis.conf" description="Redis Configuration">
  <profiles>
    <profile name="default">
      <connections>
        <connection name="primary">
          <param name="hostname" value="redis"/>
          <param name="port" value="6379"/>
          <param name="password" value=""/>
          <param name="timeout_ms" value="500"/>
        </connection>
      </connections>
      <params>
        <param name="ignore-connect-fail" value="true"/>
        <param name="ignore-error" value="false"/>
      </params>
    </profile>
  </profiles>
</configuration>
```

**使用示例（Lua）：**
```lua
-- 连接 Redis
local redis = require("hiredis")
local conn = redis.connect('redis', 6379)

-- 设置值
conn:command("SET", "caller:" .. caller_id, caller_name)
conn:command("EXPIRE", "caller:" .. caller_id, 3600)

-- 获取值
local name = conn:command("GET", "caller:" .. caller_id)
```

#### 5.2 mod_redis (Redis 限流和限制)
**用途：** 使用 Redis 实现呼叫限流、并发限制等功能。

**功能：**
- 呼叫频率限制
- 并发呼叫限制
- 基于时间窗口的限流
- 分布式限流

**配置示例：**
```xml
<configuration name="redis.conf" description="Redis Limit">
  <profiles>
    <profile name="default">
      <param name="host" value="redis"/>
      <param name="port" value="6379"/>
      <param name="db" value="0"/>
    </profile>
  </profiles>
</configuration>
```

**拨号计划示例（限流）：**
```xml
<extension name="rate_limit">
  <condition field="destination_number" expression="^9(\d+)$">
    <!-- 每个号码每分钟最多呼叫 10 次 -->
    <action application="limit" data="redis default ${caller_id_number} 10/60"/>
    <action application="bridge" data="sofia/gateway/provider/$1"/>
  </condition>
</extension>
```

### 6. HTTP 和外部集成

#### 6.1 mod_curl (HTTP 客户端)
**用途：** 在拨号计划中调用 HTTP API，实现与外部系统集成。

**配置文件：** `autoload_configs/curl.conf.xml`

**功能：**
- 发送 HTTP GET/POST 请求
- 支持 HTTPS
- 支持自定义 Header
- 返回结果可用于拨号计划

**配置示例：**
```xml
<configuration name="curl.conf" description="cURL Configuration">
  <settings>
    <param name="max-bytes" value="64000"/>
    <param name="default-timeout" value="5"/>
  </settings>
</configuration>
```

**拨号计划示例：**
```xml
<extension name="api_integration">
  <condition field="destination_number" expression="^8(\d+)$">
    <!-- 调用外部 API 验证 -->
    <action application="set" data="result=${curl(http://api.example.com/verify?caller=${caller_id_number}&dest=$1)}"/>
    <action application="log" data="INFO API Result: ${result}"/>
    
    <!-- 根据返回结果判断 -->
    <condition field="${result}" expression="^OK$">
      <action application="bridge" data="user/$1"/>
      <anti-action application="playback" data="ivr/ivr-call_rejected.wav"/>
    </condition>
  </condition>
</extension>
```

**Lua 脚本示例：**
```lua
-- 发送 POST 请求
function send_cdr_to_api(uuid, caller, destination)
    local curl = require("luacurl")
    
    local data = string.format(
        '{"uuid":"%s","caller":"%s","destination":"%s"}',
        uuid, caller, destination
    )
    
    local c = curl.easy_init()
    c:setopt(curl.OPT_URL, "http://api.example.com/cdr")
    c:setopt(curl.OPT_POST, 1)
    c:setopt(curl.OPT_POSTFIELDS, data)
    c:setopt(curl.OPT_HTTPHEADER, {
        "Content-Type: application/json"
    })
    
    local ok, err = c:perform()
    c:close()
    
    return ok
end
```

### 7. 脚本语言支持

#### 7.1 mod_python3 (Python 3 支持)
**用途：** 使用 Python 3 编写 FreeSWITCH 脚本和应用。

**配置文件：** `autoload_configs/python3.conf.xml`

**功能：**
- 完整的 FreeSWITCH API 支持
- 事件处理
- 拨号计划集成
- 异步调用

**配置示例：**
```xml
<configuration name="python3.conf" description="Python3 Configuration">
  <settings>
    <param name="script-directory" value="/usr/local/freeswitch/scripts"/>
    <param name="xml-handler-script" value=""/>
    <param name="xml-handler-bindings" value="dialplan"/>
  </settings>
</configuration>
```

**Python 脚本示例：**
```python
#!/usr/bin/env python3
# /usr/local/freeswitch/scripts/call_handler.py

import sys
from freeswitch import *

def handler(session, args):
    """处理呼入呼叫"""
    
    # 接听电话
    session.answer()
    
    # 获取呼叫信息
    caller = session.getVariable("caller_id_number")
    destination = session.getVariable("destination_number")
    
    # 查询数据库
    import mysql.connector
    db = mysql.connector.connect(
        host="mysql",
        user="root",
        password="password",
        database="callcenter"
    )
    
    cursor = db.cursor()
    cursor.execute("SELECT name FROM customers WHERE phone=%s", (caller,))
    result = cursor.fetchone()
    
    if result:
        # 客户存在，播放欢迎语音
        caller_name = result[0]
        session.setVariable("caller_name", caller_name)
        session.execute("playback", f"ivr/ivr-welcome_{caller_name}.wav")
    else:
        # 新客户
        session.execute("playback", "ivr/ivr-new_customer.wav")
    
    # 转接到队列
    session.execute("callcenter", "support")
    
    db.close()
```

**拨号计划集成：**
```xml
<extension name="python_handler">
  <condition field="destination_number" expression="^8888$">
    <action application="python3" data="call_handler"/>
  </condition>
</extension>
```

#### 7.2 mod_lua (Lua 脚本支持)
**用途：** 使用 Lua 编写轻量级脚本（已默认启用）。

**优势：**
- 执行速度快
- 内存占用小
- 语法简单
- 与 FreeSWITCH 集成紧密

**示例脚本：**
```lua
-- /usr/local/freeswitch/scripts/queue_callback.lua

-- 获取参数
local caller = session:getVariable("caller_id_number")
local queue_name = argv[1]

-- 记录回调请求
local dbh = freeswitch.Dbh("mariadb", 
    "host=mysql;port=3306;db=callcenter;user=root;pass=password")

if dbh:connected() then
    local sql = string.format(
        "INSERT INTO callbacks (phone, queue, timestamp) VALUES ('%s', '%s', NOW())",
        caller, queue_name
    )
    dbh:query(sql)
    dbh:release()
end

-- 播放确认消息
session:answer()
session:streamFile("ivr/ivr-callback_scheduled.wav")
session:hangup()
```

## 呼叫中心系统推荐模块组合

### 小型呼叫中心（<20座席）
```
✅ 必需模块：
- mod_fifo (简单队列)
- mod_conference (会议功能)
- mod_voicemail (语音邮箱)
- mod_blacklist (黑名单)
- mod_fail2ban (安全防护)
- mod_lua (脚本支持)

🔄 可选模块：
- mod_curl (API 集成)
- mod_redis (缓存)
```

### 中型呼叫中心（20-100座席）
```
✅ 必需模块：
- mod_callcenter (专业队列)
- mod_conference (会议功能)
- mod_voicemail (语音邮箱)
- mod_blacklist (黑名单)
- mod_fail2ban (安全防护)
- mod_distributor (负载均衡)
- mod_cidlookup (来电识别)
- mod_curl (API 集成)
- mod_hiredis + mod_redis (高性能缓存)
- mod_lua (脚本支持)

🔄 可选模块：
- mod_python3 (复杂业务逻辑)
- mod_lcr (成本路由)
- mod_nibblebill (计费)
```

### 大型呼叫中心（>100座席）
```
✅ 必需所有模块：
- mod_callcenter (专业队列)
- mod_conference (会议功能)
- mod_voicemail (语音邮箱)
- mod_blacklist (黑名单)
- mod_fail2ban (安全防护)
- mod_distributor (负载均衡)
- mod_lcr (智能路由)
- mod_cidlookup (来电识别)
- mod_nibblebill (实时计费)
- mod_curl (API 集成)
- mod_hiredis + mod_redis (分布式缓存)
- mod_lua (脚本支持)
- mod_python3 (复杂业务)

💡 额外推荐：
- mod_xml_curl (动态配置)
- mod_odbc_cdr (CDR 记录)
- mod_mariadb (数据库集成)
```

## 模块依赖关系

```
mod_callcenter
├── 依赖: mod_odbc_cdr (CDR 记录)
└── 建议: mod_xml_curl (动态配置)

mod_lcr
└── 依赖: 数据库连接 (MariaDB/PostgreSQL)

mod_nibblebill
└── 依赖: 数据库连接 (MariaDB/PostgreSQL)

mod_redis
└── 依赖: mod_hiredis

mod_python3
└── 依赖: python3-dev, python3-distutils

mod_curl
└── 依赖: libcurl4-openssl-dev
```

## 性能优化建议

### 1. Redis 缓存策略
```lua
-- 缓存客户信息
local function get_customer_info(phone)
    local redis_key = "customer:" .. phone
    
    -- 先从 Redis 查询
    local cached = redis:command("GET", redis_key)
    if cached then
        return cached
    end
    
    -- Redis 未命中，查询数据库
    local dbh = freeswitch.Dbh("mariadb", db_conn_string)
    local info = query_database(dbh, phone)
    
    -- 写入 Redis 缓存（1小时过期）
    redis:command("SETEX", redis_key, 3600, info)
    
    return info
end
```

### 2. 数据库连接池
```python
# Python 数据库连接池
from DBUtils.PooledDB import PooledDB
import mysql.connector

db_pool = PooledDB(
    creator=mysql.connector,
    maxconnections=20,
    host="mysql",
    user="root",
    password="password",
    database="callcenter"
)

def get_db_connection():
    return db_pool.connection()
```

### 3. 异步处理
```lua
-- 使用 API 后台任务
api = freeswitch.API()
api:executeString("bgapi luarun send_notification.lua " .. uuid)
```

## 监控和维护

### 1. 模块状态检查
```bash
# 进入 fs_cli
fs_cli

# 查看已加载模块
show modules

# 重新加载模块
reload mod_callcenter

# 卸载模块
unload mod_callcenter

# 加载模块
load mod_callcenter
```

### 2. 队列监控
```bash
# 查看队列状态
callcenter_config queue list

# 查看队列详情
callcenter_config queue list members support@default
callcenter_config queue list tiers support@default

# 查看座席状态
callcenter_config agent list
```

### 3. 性能监控
```bash
# 查看系统状态
status

# 查看通道数
show channels count

# 查看会话数
show sessions

# API 调用统计
api_command_stats
```

## 故障排查

### 模块加载失败
```bash
# 查看日志
tail -f /usr/local/freeswitch/log/freeswitch.log

# 检查模块文件
ls -la /usr/local/freeswitch/mod/mod_*.so

# 测试加载
load mod_callcenter
```

### 数据库连接问题
```bash
# 测试 ODBC 连接
isql -v mariadb_datasource

# 在 fs_cli 中测试数据库
lua
dbh = freeswitch.Dbh("mariadb", "host=mysql;db=freeswitch;user=root;pass=password")
print(dbh:connected())
```

### Redis 连接问题
```bash
# 测试 Redis 连接
redis-cli -h redis ping

# 在 fs_cli 中测试
hiredis_raw default GET test_key
```

## 安全建议

1. **启用 fail2ban** - 防止暴力破解
2. **使用强密码** - SIP 账号和数据库密码
3. **限制 IP 访问** - 使用 ACL 限制访问
4. **定期更新** - 保持 FreeSWITCH 版本最新
5. **监控日志** - 定期检查异常登录
6. **备份数据** - 定期备份配置和数据库

## 相关配置文件

```
/usr/local/freeswitch/conf/
├── autoload_configs/
│   ├── callcenter.conf.xml      # 呼叫中心配置
│   ├── distributor.conf.xml     # 负载均衡配置
│   ├── lcr.conf.xml             # 最低成本路由
│   ├── cidlookup.conf.xml       # 来电查询
│   ├── nibblebill.conf.xml      # 计费配置
│   ├── hiredis.conf.xml         # Redis 配置
│   ├── fail2ban.conf.xml        # 安全防护
│   ├── curl.conf.xml            # HTTP 配置
│   ├── python3.conf.xml         # Python 配置
│   └── modules.conf.xml         # 模块加载配置
├── dialplan/
│   └── default.xml              # 拨号计划
└── directory/
    └── default.xml              # 用户目录
```

## 参考文档

- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)
- [mod_callcenter 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_callcenter)
- [mod_lcr 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_lcr)
- [mod_distributor 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_distributor)
- [Lua 脚本示例](https://freeswitch.org/confluence/display/FREESWITCH/Lua+examples)

## 更新日志

- 2025-10-10: 初始版本，添加所有呼叫中心必需模块
- 启用模块: mod_fail2ban, mod_callcenter, mod_blacklist, mod_python3, mod_curl, mod_hiredis, mod_redis
- 推荐模块: mod_distributor, mod_lcr, mod_cidlookup, mod_nibblebill

---

**维护者：** ByteDesk Team  
**联系方式：** 270580156@qq.com  
**项目地址：** https://github.com/Bytedesk/bytedesk-freeswitch
