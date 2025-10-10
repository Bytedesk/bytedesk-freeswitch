# 更新日志 - mod_odbc_cdr 启用

## 本次更新内容

### ✅ 已启用 mod_odbc_cdr 模块

`mod_odbc_cdr` 是 FreeSWITCH 中 **真实存在** 的 ODBC 相关模块，用于通过 ODBC 将 CDR（呼叫详单记录）写入数据库。

### 与之前讨论的区别

| 模块名 | 是否存在 | 用途 | 状态 |
|--------|----------|------|------|
| `mod_odbc` | ❌ 不存在 | - | N/A |
| `mod_odbc_cdr` | ✅ 存在 | CDR记录写入数据库 | ✅ 已启用 |
| `mod_xml_odbc` | ✅ 存在(实验性) | 从数据库读取XML配置 | ❌ 未启用 |
| 核心 ODBC 支持 | ✅ 内置功能 | 核心数据库连接 | ✅ 已启用 |

## 修改文件清单

### 1. Dockerfile
**位置**: `docker/Dockerfile` 第 145 行

**修改内容**:
```dockerfile
# 启用 event_handlers/mod_odbc_cdr 模块（ODBC CDR 记录）
sed -i 's/^#\(event_handlers\/mod_odbc_cdr\)/\1/' build/modules.conf.in && \
```

### 2. modules.conf.xml
**位置**: `docker/conf/autoload_configs/modules.conf.xml`

**修改内容**:
```xml
<!-- ODBC CDR - 通过 ODBC 将 CDR 记录写入数据库 -->
<load module="mod_odbc_cdr" />
```

### 3. odbc_cdr.conf.xml（新增）
**位置**: `docker/conf/autoload_configs/odbc_cdr.conf.xml`

**说明**: mod_odbc_cdr 模块的配置文件，包含字段映射和数据库连接设置

### 4. cdr_table.sql（新增）
**位置**: `docker/conf/cdr_table.sql`

**说明**: CDR 数据库表结构定义（MySQL/MariaDB）

### 5. MOD_ODBC_CDR_GUIDE.md（新增）
**位置**: `docker/MOD_ODBC_CDR_GUIDE.md`

**说明**: 完整的 mod_odbc_cdr 配置和使用指南

## 当前启用的模块总览

### 数据库相关模块

```
✅ databases/mod_mariadb          - MySQL/MariaDB 原生驱动
✅ event_handlers/mod_odbc_cdr    - ODBC CDR 记录
✅ databases/mod_pgsql            - PostgreSQL 原生驱动（默认启用）
✅ 核心 ODBC 支持                  - --enable-core-odbc-support
```

### 其他启用的模块

```
✅ xml_int/mod_xml_curl           - HTTP 动态配置
✅ say/mod_say_zh                 - 中文语音报号
❌ endpoints/mod_verto            - 已禁用（使用 mod_sofia + WebSocket）
❌ applications/mod_signalwire    - 已禁用（除非 BUILD_SIGNALWIRE=1）
```

## 使用方法

### 快速启动

```bash
docker run -d \
  --name freeswitch \
  -e FREESWITCH_DB_HOST=mysql_host \
  -e FREESWITCH_DB_NAME=freeswitch \
  -e FREESWITCH_DB_USER=root \
  -e FREESWITCH_DB_PASSWORD=password \
  -p 5060:5060/udp \
  -p 5080:5080/udp \
  -p 8021:8021/tcp \
  -p 16384-32768:16384-32768/udp \
  bytedesk/freeswitch:latest
```

### 创建 CDR 表

```bash
# 在 MySQL/MariaDB 中执行
mysql -h mysql_host -u root -p freeswitch < docker/conf/cdr_table.sql
```

### 验证安装

```bash
# 检查模块是否编译
docker exec freeswitch ls -l /usr/local/freeswitch/mod/mod_odbc_cdr.so

# 检查模块是否加载
docker exec -it freeswitch fs_cli -x "module_exists mod_odbc_cdr"

# 查看 CDR 记录
mysql -h mysql_host -u root -p freeswitch -e "SELECT * FROM cdr ORDER BY start_stamp DESC LIMIT 10;"
```

## 构建命令

```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker

# 标准构建（包含 mod_odbc_cdr）
docker build -t bytedesk/freeswitch:1.10.12 .

# 或使用 Makefile
make build
```

## 数据库表结构预览

```sql
CREATE TABLE `cdr` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` VARCHAR(255) NOT NULL,
  `caller_id_name` VARCHAR(255) DEFAULT NULL,
  `caller_id_number` VARCHAR(255) DEFAULT NULL,
  `destination_number` VARCHAR(255) DEFAULT NULL,
  `context` VARCHAR(255) DEFAULT NULL,
  `start_stamp` DATETIME DEFAULT NULL,
  `answer_stamp` DATETIME DEFAULT NULL,
  `end_stamp` DATETIME DEFAULT NULL,
  `duration` INT DEFAULT 0,
  `billsec` INT DEFAULT 0,
  `hangup_cause` VARCHAR(50) DEFAULT NULL,
  `accountcode` VARCHAR(255) DEFAULT NULL,
  `sip_hangup_disposition` VARCHAR(50) DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_uuid` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## CDR 记录示例

| uuid | caller_id_number | destination_number | start_stamp | duration | billsec | hangup_cause |
|------|------------------|-------------------|-------------|----------|---------|--------------|
| abc123... | 1000 | 1001 | 2024-01-15 10:30:00 | 125 | 120 | NORMAL_CLEARING |
| def456... | 1002 | 8888 | 2024-01-15 10:35:00 | 45 | 0 | NO_ANSWER |

## 文档索引

- **完整配置指南**: `MOD_ODBC_CDR_GUIDE.md`
- **模块说明**: `MODULES_EXPLANATION.md`
- **快速参考**: `MODULES_QUICK_REFERENCE.md`

## 注意事项

1. ⚠️ **不要混淆 `mod_odbc` 和 `mod_odbc_cdr`**
   - `mod_odbc`: 不存在的模块
   - `mod_odbc_cdr`: 存在且已启用的 CDR 模块

2. ⚠️ **数据库连接配置**
   - CDR 使用 `odbc.conf.xml` 中的 ODBC DSN
   - 通过环境变量自动配置（FREESWITCH_DB_*）

3. ⚠️ **性能考虑**
   - 高并发场景建议使用数据库连接池
   - 定期归档历史 CDR 数据
   - 考虑使用主从复制提高查询性能

4. ✅ **备份策略**
   - 可以同时启用 `mod_cdr_csv` 作为备份
   - CDR 数据建议定期备份

## 下一步

重新构建镜像后：

1. ✅ mod_odbc_cdr 将自动编译
2. ✅ 启动时自动加载模块
3. ✅ 配置数据库连接后自动记录 CDR
4. ✅ 通过 SQL 查询分析通话数据

## 版本兼容性

- ✅ FreeSWITCH: v1.10.12
- ✅ Ubuntu: 22.04 LTS
- ✅ MySQL: 5.7+
- ✅ MariaDB: 10.3+

---

**更新时间**: 2025-01-15
**更新人**: ByteDesk Team
