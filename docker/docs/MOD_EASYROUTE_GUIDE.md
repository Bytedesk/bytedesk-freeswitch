# mod_easyroute 模块配置指南

## 模块概述

`mod_easyroute` 是 FreeSWITCH 的路由查询模块，用于从数据库中获取简化的路由信息。它主要用于：

- **号码路由查询**：根据被叫号码查询路由信息
- **数据库集成**：支持 ODBC 连接各种数据库
- **简化配置**：相比 mod_lcr 更轻量级的路由解决方案
- **高性能查询**：支持缓存和批量查询

---

## 1. 配置文件

### 1.1 基础配置 (easyroute.conf.xml)

创建 `/usr/local/freeswitch/conf/autoload_configs/easyroute.conf.xml`：

```xml
<configuration name="easyroute.conf" description="EasyRoute Module">
  <settings>
    <!-- ODBC DSN 配置 -->
    <param name="db-dsn" value="mysql_easyroute"/>
    
    <!-- 数据库用户名 -->
    <param name="db-username" value="freeswitch"/>
    
    <!-- 数据库密码 -->
    <param name="db-password" value="password"/>
    
    <!-- 默认技术前缀 -->
    <param name="default-techprefix" value="sofia/gateway"/>
    
    <!-- 默认网关 -->
    <param name="default-gateway" value="default_gateway"/>
    
    <!-- 查询缓存时间（秒） -->
    <param name="cache-lookup-time" value="300"/>
    
    <!-- 最大缓存条目数 -->
    <param name="max-cache-size" value="10000"/>
  </settings>
</configuration>
```

### 1.2 数据库表结构

#### MySQL/MariaDB 表结构

```sql
-- 创建 easyroute 数据库
CREATE DATABASE IF NOT EXISTS easyroute DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE easyroute;

-- 路由表
CREATE TABLE IF NOT EXISTS numbers (
    number VARCHAR(32) NOT NULL PRIMARY KEY,
    gateway VARCHAR(128) NOT NULL,
    group VARCHAR(128) DEFAULT NULL,
    limit INT(11) DEFAULT 0,
    techprefix VARCHAR(128) DEFAULT NULL,
    acctcode VARCHAR(128) DEFAULT NULL,
    translated VARCHAR(32) DEFAULT NULL,
    
    INDEX idx_number (number),
    INDEX idx_gateway (gateway),
    INDEX idx_group (group)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 网关表（可选）
CREATE TABLE IF NOT EXISTS gateways (
    gateway_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    gateway_name VARCHAR(128) NOT NULL UNIQUE,
    gateway_ip VARCHAR(64) NOT NULL,
    gateway_port INT(11) DEFAULT 5060,
    gateway_prefix VARCHAR(32) DEFAULT NULL,
    enabled TINYINT(1) DEFAULT 1,
    
    INDEX idx_gateway_name (gateway_name),
    INDEX idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 插入示例数据

```sql
-- 插入路由规则
INSERT INTO numbers (number, gateway, `group`, techprefix, translated) VALUES
('1001', 'internal', 'local', 'sofia/internal', NULL),
('1002', 'internal', 'local', 'sofia/internal', NULL),
('10%', 'internal', 'local', 'sofia/internal', NULL),
('86%', 'gateway1', 'international', 'sofia/gateway', NULL),
('00%', 'gateway2', 'international', 'sofia/gateway', NULL),
('*', 'default_gateway', 'default', 'sofia/gateway', NULL);

-- 插入网关信息
INSERT INTO gateways (gateway_name, gateway_ip, gateway_port, enabled) VALUES
('gateway1', '192.168.1.100', 5060, 1),
('gateway2', '192.168.1.101', 5060, 1),
('default_gateway', '192.168.1.102', 5060, 1);
```

### 1.3 ODBC 配置

#### /etc/odbc.ini

```ini
[mysql_easyroute]
Description = MySQL EasyRoute Database
Driver = MariaDB
Server = localhost
Port = 3306
Database = easyroute
UserName = freeswitch
Password = password
Option = 3
```

#### /etc/odbcinst.ini

```ini
[MariaDB]
Description = MariaDB ODBC Driver
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
Setup = /usr/lib/x86_64-linux-gnu/odbc/libodbcmyS.so
FileUsage = 1
```

---

## 2. Dialplan 集成

### 2.1 基本路由查询

```xml
<extension name="easyroute_lookup">
  <condition field="destination_number" expression="^(\d+)$">
    <!-- 执行路由查询 -->
    <action application="easyroute" data="${destination_number}"/>
    
    <!-- 使用查询结果拨号 -->
    <action application="bridge" data="${easy_techprefix}/${easy_gateway}/${easy_dest}"/>
    
    <anti-action application="hangup" data="NO_ROUTE_DESTINATION"/>
  </condition>
</extension>
```

### 2.2 带回退的路由查询

```xml
<extension name="easyroute_with_failover">
  <condition field="destination_number" expression="^(\d+)$">
    <!-- 主路由查询 -->
    <action application="set" data="continue_on_fail=true"/>
    <action application="easyroute" data="${destination_number}"/>
    
    <action application="log" data="INFO EasyRoute: ${easy_techprefix}/${easy_gateway}/${easy_dest}"/>
    
    <!-- 尝试主路由 -->
    <action application="bridge" data="${easy_techprefix}/${easy_gateway}/${easy_dest}"/>
    
    <!-- 如果失败，使用备用网关 -->
    <action application="bridge" data="sofia/gateway/backup_gateway/${destination_number}"/>
    
    <!-- 最终回退 -->
    <action application="hangup" data="NO_ROUTE_DESTINATION"/>
  </condition>
</extension>
```

### 2.3 带号码转换的路由

```xml
<extension name="easyroute_with_translation">
  <condition field="destination_number" expression="^(\d+)$">
    <action application="easyroute" data="${destination_number}"/>
    
    <!-- 如果有号码转换，使用转换后的号码 -->
    <action application="set" data="effective_dest=${easy_translated:-${easy_dest}}"/>
    
    <action application="bridge" data="${easy_techprefix}/${easy_gateway}/${effective_dest}"/>
  </condition>
</extension>
```

### 2.4 带并发限制的路由

```xml
<extension name="easyroute_with_limit">
  <condition field="destination_number" expression="^(\d+)$">
    <action application="easyroute" data="${destination_number}"/>
    
    <!-- 检查路由并发限制 -->
    <action application="limit" data="hash ${easy_gateway} ${easy_limit} !NORMAL_CIRCUIT_CONGESTION"/>
    
    <action application="bridge" data="${easy_techprefix}/${easy_gateway}/${easy_dest}"/>
  </condition>
</extension>
```

---

## 3. API 命令

### 3.1 路由查询命令

```bash
# 查询指定号码的路由
fs_cli -x "easyroute 8613800138000"

# 输出示例：
# techprefix: sofia/gateway
# gateway: gateway1
# destination: 8613800138000
# group: international
# limit: 100
```

### 3.2 缓存管理命令

```bash
# 查看缓存统计
fs_cli -x "easyroute cache status"

# 清除所有缓存
fs_cli -x "easyroute cache clear"

# 清除特定号码的缓存
fs_cli -x "easyroute cache clear 8613800138000"
```

### 3.3 配置重载

```bash
# 重新加载 easyroute 配置
fs_cli -x "reload mod_easyroute"
```

---

## 4. 通道变量

### 4.1 查询结果变量

路由查询成功后，会设置以下通道变量：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `easy_techprefix` | 技术前缀 | `sofia/gateway` |
| `easy_gateway` | 网关名称 | `gateway1` |
| `easy_dest` | 目标号码 | `8613800138000` |
| `easy_group` | 路由组 | `international` |
| `easy_limit` | 并发限制 | `100` |
| `easy_acctcode` | 计费代码 | `INTL` |
| `easy_translated` | 转换后号码 | `+8613800138000` |

### 4.2 使用示例

```xml
<action application="log" data="INFO Gateway: ${easy_gateway}, Dest: ${easy_dest}"/>
<action application="set" data="hangup_after_bridge=true"/>
<action application="bridge" data="${easy_techprefix}/${easy_gateway}/${easy_dest}"/>
```

---

## 5. 高级配置

### 5.1 多数据库支持

```xml
<configuration name="easyroute.conf" description="EasyRoute Module">
  <settings>
    <!-- 主数据库 -->
    <param name="db-dsn" value="mysql_easyroute_primary"/>
    <param name="db-username" value="freeswitch"/>
    <param name="db-password" value="password"/>
    
    <!-- 备用数据库（需要自定义查询逻辑） -->
    <!-- 可以通过 Lua 或其他脚本实现多数据库查询 -->
  </settings>
</configuration>
```

### 5.2 自定义查询语句

默认查询语句为：

```sql
SELECT gateway, `group`, `limit`, techprefix, acctcode, translated 
FROM numbers 
WHERE number = ?
```

如需自定义查询，可以通过修改源码或使用 Lua 脚本包装。

### 5.3 性能优化

```xml
<configuration name="easyroute.conf" description="EasyRoute Module">
  <settings>
    <!-- 增加缓存时间（秒） -->
    <param name="cache-lookup-time" value="600"/>
    
    <!-- 增加缓存大小 -->
    <param name="max-cache-size" value="50000"/>
    
    <!-- 启用数据库连接池（通过 ODBC 配置） -->
  </settings>
</configuration>
```

---

## 6. Lua 脚本集成

### 6.1 Lua 路由查询

```lua
-- easyroute_lookup.lua
local destination = argv[1] or session:getVariable("destination_number")

-- 执行 easyroute 查询
session:execute("easyroute", destination)

-- 获取查询结果
local techprefix = session:getVariable("easy_techprefix")
local gateway = session:getVariable("easy_gateway")
local dest = session:getVariable("easy_dest")
local group = session:getVariable("easy_group")

-- 日志记录
freeswitch.consoleLog("INFO", string.format(
    "EasyRoute Result: %s/%s/%s (Group: %s)\n",
    techprefix, gateway, dest, group
))

-- 执行拨号
if gateway and dest then
    local dial_string = string.format("%s/%s/%s", techprefix, gateway, dest)
    session:execute("bridge", dial_string)
else
    freeswitch.consoleLog("ERR", "EasyRoute lookup failed for: " .. destination .. "\n")
    session:hangup("NO_ROUTE_DESTINATION")
end
```

### 6.2 Dialplan 调用

```xml
<extension name="lua_easyroute">
  <condition field="destination_number" expression="^(\d+)$">
    <action application="lua" data="easyroute_lookup.lua ${destination_number}"/>
  </condition>
</extension>
```

---

## 7. 监控与调试

### 7.1 日志配置

在 `conf/autoload_configs/logfile.conf.xml` 中启用 easyroute 日志：

```xml
<map name="debug" value="console,debug,info,notice,warning,err,crit,alert"/>
```

### 7.2 调试命令

```bash
# 启用模块调试
fs_cli -x "console loglevel mod_easyroute debug"

# 查看路由查询日志
tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i easyroute

# 测试数据库连接
fs_cli -x "odbc test mysql_easyroute"
```

### 7.3 性能监控

```bash
# 查看缓存命中率
fs_cli -x "easyroute cache status"

# 输出示例：
# Cache Size: 5000
# Cache Hits: 25000
# Cache Misses: 1000
# Hit Rate: 96.15%
```

---

## 8. 故障排查

### 8.1 常见问题

#### 问题 1：数据库连接失败

**症状**：
```
[ERR] mod_easyroute.c:123 Cannot connect to database
```

**解决方案**：
```bash
# 1. 测试 ODBC 连接
odbcinst -j
isql -v mysql_easyroute freeswitch password

# 2. 检查数据库权限
mysql -u freeswitch -p
SHOW GRANTS FOR 'freeswitch'@'localhost';

# 3. 验证配置文件
cat /etc/odbc.ini
```

#### 问题 2：路由查询返回空

**症状**：
```
[WARNING] mod_easyroute.c:234 No route found for number: 8613800138000
```

**解决方案**：
```sql
-- 检查数据库中的路由规则
SELECT * FROM numbers WHERE number LIKE '861380%';

-- 添加通配符规则
INSERT INTO numbers (number, gateway, techprefix) 
VALUES ('861%', 'gateway1', 'sofia/gateway');
```

#### 问题 3：缓存不更新

**解决方案**：
```bash
# 清除缓存
fs_cli -x "easyroute cache clear"

# 重载模块
fs_cli -x "reload mod_easyroute"
```

### 8.2 日志分析

```bash
# 查看路由查询记录
grep "easyroute" /usr/local/freeswitch/log/freeswitch.log | tail -100

# 查看数据库查询日志
grep "ODBC" /usr/local/freeswitch/log/freeswitch.log | grep easyroute
```

---

## 9. 与其他模块对比

### 9.1 mod_easyroute vs mod_lcr

| 特性 | mod_easyroute | mod_lcr |
|------|---------------|---------|
| **复杂度** | 简单 | 复杂 |
| **路由逻辑** | 单一路由 | 多路由 LCR 算法 |
| **性能** | 高（缓存友好） | 中等 |
| **配置** | 简单 | 复杂 |
| **适用场景** | 简单路由查询 | 复杂成本路由 |

### 9.2 选择建议

- **使用 mod_easyroute**：
  - 简单的号码到网关映射
  - 需要高性能查询
  - 路由规则相对固定

- **使用 mod_lcr**：
  - 需要成本路由（Least Cost Routing）
  - 多网关自动选择
  - 复杂的路由策略

---

## 10. 生产部署建议

### 10.1 数据库优化

```sql
-- 添加索引优化查询性能
CREATE INDEX idx_number_prefix ON numbers(number(10));

-- 定期清理无效路由
DELETE FROM numbers WHERE enabled = 0 AND updated_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- 优化表结构
OPTIMIZE TABLE numbers;
```

### 10.2 高可用配置

```xml
<!-- 使用数据库主从复制 -->
<!-- 在 ODBC 配置中指向主数据库 -->
<!-- 应用层实现故障转移 -->
```

### 10.3 监控指标

- 路由查询成功率
- 缓存命中率
- 平均查询延迟
- 数据库连接状态

### 10.4 安全建议

```sql
-- 限制数据库用户权限
GRANT SELECT ON easyroute.numbers TO 'freeswitch'@'localhost';
REVOKE ALL PRIVILEGES ON easyroute.* FROM 'freeswitch'@'%';

-- 使用只读账户（如果不需要动态更新）
CREATE USER 'freeswitch_readonly'@'localhost' IDENTIFIED BY 'secure_password';
GRANT SELECT ON easyroute.* TO 'freeswitch_readonly'@'localhost';
```

---

## 11. 实际应用案例

### 11.1 国际路由场景

```sql
-- 路由配置示例
INSERT INTO numbers (number, gateway, `group`, techprefix) VALUES
('86%', 'china_gateway', 'china', 'sofia/gateway'),
('1%', 'usa_gateway', 'usa', 'sofia/gateway'),
('44%', 'uk_gateway', 'uk', 'sofia/gateway'),
('*', 'default_international', 'default', 'sofia/gateway');
```

### 11.2 DID 路由场景

```sql
-- DID 到分机映射
INSERT INTO numbers (number, gateway, techprefix, translated) VALUES
('4001234567', 'internal', 'sofia/internal', '1001'),
('4001234568', 'internal', 'sofia/internal', '1002'),
('4001234569', 'internal', 'sofia/internal', 'group/sales@default');
```

---

## 总结

`mod_easyroute` 是一个轻量级、高性能的路由查询模块，适合需要简单数据库路由的场景。通过合理的配置和优化，可以实现：

- ✅ 快速路由查询（毫秒级）
- ✅ 灵活的号码匹配规则
- ✅ 高效的缓存机制
- ✅ 简单的维护管理

建议与 `mod_lcr`、`mod_distributor` 等模块配合使用，构建完整的呼叫路由解决方案。
