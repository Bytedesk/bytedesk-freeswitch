# mod_odbc_cdr 配置指南

## 概述

`mod_odbc_cdr` 模块用于将 FreeSWITCH 的 CDR（呼叫详单记录）通过 ODBC 写入数据库。

## 启用状态

✅ 已在 Dockerfile 中启用编译
✅ 已在 modules.conf.xml 中配置加载
✅ 已提供配置文件和数据库表结构

## 配置步骤

### 1. 准备数据库

首先，在您的 MySQL/MariaDB 数据库中创建 CDR 表：

```bash
# 连接到数据库
mysql -h your_host -u your_user -p your_database

# 执行 SQL 脚本创建表
mysql -h your_host -u your_user -p your_database < /path/to/cdr_table.sql
```

或者手动执行 `conf/cdr_table.sql` 中的 SQL 语句。

### 2. 配置数据库连接

使用 Docker 环境变量配置数据库连接：

```bash
docker run -d \
  --name freeswitch \
  -e FREESWITCH_DB_HOST=mysql_host \
  -e FREESWITCH_DB_NAME=freeswitch \
  -e FREESWITCH_DB_USER=root \
  -e FREESWITCH_DB_PASSWORD=password \
  -e FREESWITCH_DB_PORT=3306 \
  -e FREESWITCH_DB_CHARSET=utf8mb4 \
  bytedesk/freeswitch:latest
```

容器启动时，`docker-entrypoint.sh` 会自动配置：
- `autoload_configs/odbc.conf.xml` - ODBC 数据源配置
- `autoload_configs/db.conf.xml` - 数据库连接配置
- `autoload_configs/switch.conf.xml` - 核心数据库配置

### 3. 自定义配置（可选）

如果需要自定义 CDR 字段映射，修改 `autoload_configs/odbc_cdr.conf.xml`：

```xml
<schema>
  <!-- 添加更多字段映射 -->
  <field var="read_codec" column="read_codec"/>
  <field var="write_codec" column="write_codec"/>
  <field var="remote_media_ip" column="remote_media_ip"/>
  <!-- 自定义通道变量 -->
  <field var="my_custom_var" column="custom_field"/>
</schema>
```

然后在数据库表中添加相应的字段：

```sql
ALTER TABLE cdr ADD COLUMN read_codec VARCHAR(50);
ALTER TABLE cdr ADD COLUMN write_codec VARCHAR(50);
ALTER TABLE cdr ADD COLUMN remote_media_ip VARCHAR(50);
ALTER TABLE cdr ADD COLUMN custom_field VARCHAR(255);
```

### 4. 在拨号计划中设置自定义变量

```xml
<extension name="set_custom_cdr_vars">
  <condition field="destination_number" expression="^(\d+)$">
    <!-- 设置账户代码 -->
    <action application="set" data="accountcode=customer_001"/>
    <!-- 设置自定义字段 -->
    <action application="set" data="my_custom_var=special_call"/>
    <action application="bridge" data="user/$1"/>
  </condition>
</extension>
```

## CDR 表结构说明

### 基本字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | BIGINT | 自增主键 |
| `uuid` | VARCHAR(255) | 通话唯一标识 |
| `caller_id_name` | VARCHAR(255) | 主叫名称 |
| `caller_id_number` | VARCHAR(255) | 主叫号码 |
| `destination_number` | VARCHAR(255) | 被叫号码 |
| `context` | VARCHAR(255) | 拨号计划上下文 |
| `start_stamp` | DATETIME | 通话开始时间 |
| `answer_stamp` | DATETIME | 通话接听时间 |
| `end_stamp` | DATETIME | 通话结束时间 |
| `duration` | INT | 通话总时长(秒) |
| `billsec` | INT | 计费时长(秒) |
| `hangup_cause` | VARCHAR(50) | 挂机原因 |
| `accountcode` | VARCHAR(255) | 账户代码 |
| `sip_hangup_disposition` | VARCHAR(50) | SIP挂机处理 |

### 时间字段说明

- **start_stamp**: 呼叫创建时间（通道创建）
- **answer_stamp**: 呼叫接听时间（对方应答）
- **end_stamp**: 呼叫结束时间（挂机）
- **duration**: `end_stamp - start_stamp`（总通话时长，包括振铃时间）
- **billsec**: `end_stamp - answer_stamp`（计费时长，只计算接听后的时间）

## 使用示例

### 查询最近的通话记录

```sql
SELECT 
  caller_id_number,
  destination_number,
  start_stamp,
  duration,
  billsec,
  hangup_cause
FROM cdr 
ORDER BY start_stamp DESC 
LIMIT 100;
```

### 统计每日通话量

```sql
SELECT 
  DATE(start_stamp) as call_date,
  COUNT(*) as total_calls,
  SUM(CASE WHEN answer_stamp IS NOT NULL THEN 1 ELSE 0 END) as answered_calls,
  SUM(duration) as total_duration,
  SUM(billsec) as total_billsec
FROM cdr 
WHERE start_stamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(start_stamp)
ORDER BY call_date DESC;
```

### 查询某号码的通话历史

```sql
SELECT 
  uuid,
  caller_id_number,
  destination_number,
  start_stamp,
  answer_stamp,
  duration,
  hangup_cause
FROM cdr 
WHERE caller_id_number = '1000' OR destination_number = '1000'
ORDER BY start_stamp DESC
LIMIT 50;
```

### 查询未接来电

```sql
SELECT 
  caller_id_number,
  destination_number,
  start_stamp,
  hangup_cause
FROM cdr 
WHERE answer_stamp IS NULL
  AND hangup_cause != 'ORIGINATOR_CANCEL'
ORDER BY start_stamp DESC;
```

### 计算接通率

```sql
SELECT 
  DATE(start_stamp) as call_date,
  COUNT(*) as total_calls,
  SUM(CASE WHEN answer_stamp IS NOT NULL THEN 1 ELSE 0 END) as answered_calls,
  ROUND(SUM(CASE WHEN answer_stamp IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as answer_rate
FROM cdr 
WHERE start_stamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(start_stamp)
ORDER BY call_date DESC;
```

## 性能优化建议

### 1. 索引优化

已在 `cdr_table.sql` 中创建了基本索引，根据实际查询需求可以添加更多：

```sql
-- 复合索引示例
CREATE INDEX idx_caller_time ON cdr(caller_id_number, start_stamp);
CREATE INDEX idx_dest_time ON cdr(destination_number, start_stamp);
```

### 2. 分区表（大数据量场景）

当 CDR 记录超过百万条时，考虑使用分区表：

```sql
-- 按月分区示例
ALTER TABLE cdr 
PARTITION BY RANGE (TO_DAYS(start_stamp)) (
  PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
  PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
  PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')),
  -- 继续添加分区...
  PARTITION pmax VALUES LESS THAN MAXVALUE
);
```

### 3. 定期归档

建议定期将历史 CDR 数据归档到历史表：

```sql
-- 创建归档表
CREATE TABLE cdr_archive LIKE cdr;

-- 归档3个月前的数据
INSERT INTO cdr_archive 
SELECT * FROM cdr 
WHERE start_stamp < DATE_SUB(NOW(), INTERVAL 3 MONTH);

-- 删除已归档数据
DELETE FROM cdr 
WHERE start_stamp < DATE_SUB(NOW(), INTERVAL 3 MONTH);
```

## 故障排查

### 检查模块是否加载

```bash
docker exec -it freeswitch fs_cli -x "module_exists mod_odbc_cdr"
# 或
docker exec -it freeswitch fs_cli -x "show modules" | grep odbc_cdr
```

### 检查 ODBC 连接

```bash
docker exec -it freeswitch fs_cli -x "odbc status"
```

### 查看错误日志

```bash
docker exec -it freeswitch tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i "odbc\|cdr"
```

### 手动测试 CDR 写入

在 fs_cli 中执行测试呼叫：

```
# 从分机1000呼叫分机1001
originate user/1000 &echo
```

然后检查数据库：

```sql
SELECT * FROM cdr ORDER BY start_stamp DESC LIMIT 1;
```

## 与其他 CDR 模块的对比

| 特性 | mod_cdr_csv | mod_cdr_sqlite | mod_odbc_cdr | mod_xml_cdr |
|------|-------------|----------------|--------------|-------------|
| 存储方式 | CSV文件 | SQLite数据库 | ODBC数据库 | HTTP POST |
| 实时查询 | ❌ | ✅ | ✅ | ❌ |
| 高并发 | ⚠️ | ⚠️ | ✅ | ✅ |
| 配置复杂度 | 简单 | 简单 | 中等 | 简单 |
| 适用场景 | 小规模/调试 | 小规模 | 中大规模 | API集成 |
| 性能 | 高 | 中 | 高 | 中 |

## 最佳实践

1. **生产环境建议**：使用 `mod_odbc_cdr` + MySQL/MariaDB 主从复制
2. **开发测试**：使用 `mod_cdr_csv` 快速调试
3. **API 集成**：使用 `mod_xml_cdr` 推送到自己的API
4. **混合方案**：同时启用多个 CDR 模块作为备份

## 参考资源

- [FreeSWITCH CDR 文档](https://freeswitch.org/confluence/display/FREESWITCH/CDR)
- [mod_odbc_cdr 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_odbc_cdr)
- [ODBC 配置](https://freeswitch.org/confluence/display/FREESWITCH/ODBC)

## 总结

✅ `mod_odbc_cdr` 已成功启用并配置
✅ 提供了完整的数据库表结构
✅ 支持通过环境变量配置数据库连接
✅ 包含丰富的查询示例和优化建议

重新构建镜像后，CDR 记录将自动写入您配置的数据库！🎉
