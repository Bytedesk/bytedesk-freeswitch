# ODBC DSN 配置错误修复

## 问题描述

FreeSWITCH 启动时报错：

```
2025-10-10 06:33:47.929801 0.00% [ERR] switch_xml_config.c:267 Invalid value [mysql:host=bytedesk-mysql;port=3306;database=bytedesk;uid=root;pwd=r8FqfdbWUaN3;charset=utf8mb4] for parameter [odbc-dsn]

Item name: [odbc-dsn]
Type: string (optional)
Syntax: dsn:username:password
Help: If set, the ODBC DSN used by the limit and db applications
```

## 问题原因

FreeSWITCH 的 `odbc-dsn` 参数期望的格式是 `dsn:username:password`，而配置文件中使用了 MySQL 原生连接字符串格式。

### 错误格式（MySQL 连接字符串）

```xml
<param name="odbc-dsn" value="mysql:host=bytedesk-mysql;port=3306;database=bytedesk;uid=root;pwd=r8FqfdbWUaN3;charset=utf8mb4"/>
```

### 正确格式（ODBC DSN）

```xml
<param name="odbc-dsn" value="freeswitch:root:r8FqfdbWUaN3"/>
```

## ODBC 配置说明

ODBC (Open Database Connectivity) 需要两个配置文件：

### 1. `/etc/odbc.ini` - ODBC 数据源配置

定义数据源名称（DSN）及其连接参数：

```ini
[freeswitch]
Description = FreeSWITCH MySQL Database
Driver      = MySQL
Server      = bytedesk-mysql
Port        = 3306
Database    = bytedesk
User        = root
Password    = r8FqfdbWUaN3
Charset     = utf8mb4
Option      = 3
```

### 2. `/etc/odbcinst.ini` - ODBC 驱动配置

定义 ODBC 驱动程序：

```ini
[MySQL]
Description = MySQL ODBC Driver
Driver      = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
Threading   = 2
```

## 修复内容

### 1. 创建 ODBC 配置文件

创建了以下文件：
- `docker/conf/odbc.ini` - ODBC 数据源配置
- `docker/conf/odbcinst.ini` - ODBC 驱动配置

### 2. 修改 Dockerfile

在 Dockerfile 中添加了 ODBC 配置文件的复制步骤：

```dockerfile
# 配置 ODBC（复制 ODBC 配置文件到系统目录）
RUN mkdir -p /etc/odbc && \
    cp ${FREESWITCH_PREFIX}/conf/odbc.ini /etc/odbc.ini && \
    cp ${FREESWITCH_PREFIX}/conf/odbcinst.ini /etc/odbcinst.ini && \
    chmod 644 /etc/odbc.ini /etc/odbcinst.ini
```

### 3. 修改配置文件

#### 3.1 `vars.xml` - 全局变量

**修改前：**
```xml
<X-PRE-PROCESS cmd="set" data="odbc_dsn=mysql:host=${db_host};port=${db_port};database=${db_name};uid=${db_username};pwd=${db_password};charset=utf8mb4"/>
```

**修改后：**
```xml
<!-- ODBC DSN Name (format: dsn:username:password) -->
<X-PRE-PROCESS cmd="set" data="odbc_dsn=freeswitch:${db_username}:${db_password}"/>
```

#### 3.2 `autoload_configs/db.conf.xml` - DB 模块配置

**修改前：**
```xml
<param name="odbc-dsn" value="mysql:host=bytedesk-mysql;port=3306;database=bytedesk;uid=root;pwd=r8FqfdbWUaN3;charset=utf8mb4" />
```

**修改后：**
```xml
<!-- ODBC DSN 连接格式: dsn:username:password -->
<param name="odbc-dsn" value="freeswitch:root:r8FqfdbWUaN3" />
```

#### 3.3 `autoload_configs/directory_mysql.conf.xml` - Directory 模块配置

**修改前：**
```xml
<param name="odbc-dsn" value="mysql:host=124.220.58.234;port=3306;database=bytedesk;uid=root;pwd=nDWXYLK6QQTr;charset=utf8mb4"/>
```

**修改后：**
```xml
<!-- 注意：如果不需要从数据库加载用户，可以注释掉此参数 -->
<!--<param name="odbc-dsn" value="freeswitch:root:r8FqfdbWUaN3"/>-->
```

## ODBC DSN 格式说明

FreeSWITCH 支持两种 ODBC 连接方式：

### 方式一：使用 DSN 名称（推荐）

```xml
<param name="odbc-dsn" value="dsn_name:username:password"/>
```

- `dsn_name`：在 `/etc/odbc.ini` 中定义的数据源名称
- `username`：数据库用户名
- `password`：数据库密码

**优点**：
- 配置集中管理
- 修改连接参数只需修改 odbc.ini
- 支持连接池和高级选项

### 方式二：使用连接字符串（不推荐）

某些模块（如 `mod_mariadb`）可能支持直接的连接字符串：

```xml
<param name="connection-string" value="host=localhost;user=root;password=pass;database=db"/>
```

但 `mod_odbc_cdr`、`mod_db`、`mod_lcr` 等核心模块要求使用标准 DSN 格式。

## 相关模块配置

以下模块需要正确的 ODBC DSN 配置：

### 1. mod_odbc_cdr（CDR 记录）

```xml
<!-- odbc_cdr.conf.xml -->
<param name="odbc-dsn" value="$${odbc_dsn:freeswitch}"/>
```

引用 `vars.xml` 中定义的变量，默认值为 `freeswitch`。

### 2. mod_db（数据库操作）

```xml
<!-- db.conf.xml -->
<param name="odbc-dsn" value="freeswitch:root:r8FqfdbWUaN3"/>
```

### 3. mod_lcr（最少费用路由）

```xml
<!-- lcr.conf.xml -->
<param name="odbc-dsn" value="freeswitch-mysql:freeswitch:Fr33Sw1tch"/>
```

### 4. mod_directory（用户目录）

```xml
<!-- directory.conf.xml -->
<param name="odbc-dsn" value="freeswitch:root:r8FqfdbWUaN3"/>
```

### 5. mod_nibblebill（计费）

```xml
<!-- nibblebill.conf.xml -->
<param name="odbc-dsn" value="bandwidth.com"/>
```

### 6. mod_cidlookup（来电显示查询）

```xml
<!-- cidlookup.conf.xml -->
<param name="odbc-dsn" value="phone:phone:phone"/>
```

## 验证 ODBC 配置

### 1. 测试 ODBC 连接

进入容器后，使用 `isql` 工具测试连接：

```bash
# 列出所有 DSN
odbcinst -q -s

# 测试连接
isql -v freeswitch root r8FqfdbWUaN3
```

成功连接会显示：

```
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL>
```

### 2. 查看 ODBC 日志

启用 ODBC 跟踪以诊断连接问题：

```bash
# 编辑 /etc/odbcinst.ini，添加：
[ODBC]
Trace = Yes
TraceFile = /tmp/odbc.log
```

### 3. FreeSWITCH 日志验证

启动 FreeSWITCH 后检查日志：

```bash
# 查看 CDR 模块日志
grep "odbc_cdr" /usr/local/freeswitch/log/freeswitch.log

# 查看 DB 模块日志
grep "mod_db" /usr/local/freeswitch/log/freeswitch.log
```

成功加载会显示类似：

```
2025-10-10 07:00:00.000000 [NOTICE] mod_odbc_cdr.c:123 ODBC CDR Enabled!
2025-10-10 07:00:00.000000 [INFO] mod_db.c:456 Connected to database via ODBC DSN: freeswitch
```

## 常见错误和解决方案

### 错误 1：`Invalid value for parameter [odbc-dsn]`

**原因**：使用了 MySQL 连接字符串格式，而不是 DSN 格式

**解决**：将连接字符串改为 `dsn:username:password` 格式

### 错误 2：`[unixODBC][Driver Manager]Data source name not found`

**原因**：`/etc/odbc.ini` 中未定义 DSN

**解决**：
1. 检查 `/etc/odbc.ini` 是否存在
2. 确认 DSN 名称拼写正确
3. 确认文件权限正确（644）

### 错误 3：`Can't open lib 'MySQL' : file not found`

**原因**：ODBC 驱动库路径不正确

**解决**：
1. 查找正确的驱动路径：
   ```bash
   find /usr -name "libmaodbc.so"
   ```
2. 更新 `/etc/odbcinst.ini` 中的 Driver 路径

### 错误 4：`Access denied for user`

**原因**：数据库用户名或密码错误

**解决**：
1. 检查 `/etc/odbc.ini` 中的用户名和密码
2. 确认数据库用户具有正确的权限：
   ```sql
   GRANT ALL PRIVILEGES ON bytedesk.* TO 'root'@'%' IDENTIFIED BY 'r8FqfdbWUaN3';
   FLUSH PRIVILEGES;
   ```

### 错误 5：`Can't connect to MySQL server`

**原因**：数据库服务器地址或端口错误，或网络不通

**解决**：
1. 检查数据库服务器地址和端口
2. 测试网络连接：
   ```bash
   telnet bytedesk-mysql 3306
   ping bytedesk-mysql
   ```
3. 检查防火墙规则

## 安全建议

### 1. 使用环境变量管理密码

在生产环境中，不要在配置文件中硬编码密码：

```bash
# docker-compose.yml
environment:
  - FREESWITCH_DB_PASSWORD=${DB_PASSWORD}
```

### 2. 限制文件权限

```bash
chmod 600 /etc/odbc.ini  # 仅所有者可读写
```

### 3. 使用只读用户

为只读操作（如 CDR 查询）创建专用的只读数据库用户：

```sql
CREATE USER 'freeswitch_ro'@'%' IDENTIFIED BY 'password';
GRANT SELECT ON bytedesk.* TO 'freeswitch_ro'@'%';
FLUSH PRIVILEGES;
```

### 4. 使用 SSL 连接

在 `/etc/odbc.ini` 中配置 SSL：

```ini
[freeswitch]
# ... 其他配置 ...
sslca   = /path/to/ca.pem
sslcert = /path/to/client-cert.pem
sslkey  = /path/to/client-key.pem
```

## 重新构建镜像

```bash
# 进入 docker 目录
cd docker

# 清理旧镜像
docker rmi bytedesk/freeswitch:1.10.12

# 重新构建（不使用缓存）
docker build --no-cache -t bytedesk/freeswitch:1.10.12 .

# 或使用 docker-compose
docker-compose build --no-cache
```

## 参考资料

- [FreeSWITCH ODBC 文档](https://freeswitch.org/confluence/display/FREESWITCH/ODBC)
- [unixODBC 文档](http://www.unixodbc.org/)
- [MySQL ODBC 驱动文档](https://dev.mysql.com/doc/connector-odbc/en/)
- [mod_odbc_cdr 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_odbc_cdr)

## 更新日志

- **2025-10-10**：
  - 创建 ODBC 配置文件（odbc.ini 和 odbcinst.ini）
  - 修复 db.conf.xml 中的 ODBC DSN 格式
  - 修复 directory_mysql.conf.xml 中的 ODBC DSN 格式
  - 修复 vars.xml 中的 odbc_dsn 变量
  - 更新 Dockerfile 以自动配置 ODBC
