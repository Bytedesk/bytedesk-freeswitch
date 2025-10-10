# FreeSWITCH 模块说明 - v1.10.12

## 关于 "mod_odbc" 的重要说明

### ❌ FreeSWITCH 中没有 `mod_odbc` 模块

这是一个非常常见的误解。在 FreeSWITCH v1.10.12（以及所有版本）中：

**不存在名为 `mod_odbc` 的模块！**

查看官方源码：
- 官方 modules.conf.in: https://github.com/signalwire/freeswitch/blob/v1.10.12/build/modules.conf.in
- 在整个文件中搜索 "mod_odbc" → **找不到任何结果**

## FreeSWITCH 的 ODBC 支持架构

### 1. 核心 ODBC 支持（Core ODBC Support）

**实现方式：** 编译选项 `--enable-core-odbc-support`

```dockerfile
./configure --prefix=/usr/local/freeswitch \
            --enable-core-odbc-support \
            --enable-core-pgsql-support
```

**功能：**
- 允许 FreeSWITCH 核心使用 ODBC 连接
- 用于核心数据库（core-db）
- 配置在 `autoload_configs/switch.conf.xml`

**配置示例：**
```xml
<param name="core-db-dsn" value="mariadb://Server=localhost;Port=3306;Database=freeswitch;Uid=root;Pwd=password;" />
```

### 2. 相关的数据库模块

FreeSWITCH v1.10.12 中实际存在的数据库模块：

| 模块名 | 默认状态 | 用途 |
|--------|----------|------|
| `databases/mod_mariadb` | ❌ 注释 | MySQL/MariaDB 原生驱动 |
| `databases/mod_pgsql` | ✅ 启用 | PostgreSQL 原生驱动 |
| `event_handlers/mod_odbc_cdr` | ❌ 注释 | ODBC CDR 记录 |

### 3. 实验性模块

在 `modules.conf.in` 的最后有一行：

```
#../../contrib/mod/xml_int/mod_xml_odbc
```

这是 **`mod_xml_odbc`**（不是 `mod_odbc`），用于从数据库读取 XML 配置。

**特点：**
- 位于 contrib 目录（贡献模块）
- 标记为实验性
- 默认不构建
- 需要手动启用和编译

## 当前 Docker 镜像的配置

### ✅ 已启用的数据库支持

#### 1. 核心 ODBC 支持
```dockerfile
--enable-core-odbc-support
```

#### 2. 系统依赖
```dockerfile
apt-get install -y unixodbc-dev odbc-mariadb
```

#### 3. mod_mariadb 模块
```dockerfile
sed -i 's/^#\(databases\/mod_mariadb\)/\1/' build/modules.conf.in
make mod_mariadb && make mod_mariadb-install
```

#### 4. mod_xml_curl 模块（新增）
```dockerfile
sed -i 's/^#\(xml_int\/mod_xml_curl\)/\1/' build/modules.conf.in
```

### 📋 完整的模块启用列表

在编译前通过 sed 启用的模块：

1. **databases/mod_mariadb** - MySQL/MariaDB 数据库支持
2. **xml_int/mod_xml_curl** - HTTP/HTTPS 动态配置
3. **say/mod_say_zh** - 中文语音报号

在编译前禁用的模块（根据参数）：

1. **endpoints/mod_verto** - 旧的 WebRTC 方案（默认禁用）
2. **applications/mod_signalwire** - SignalWire 云服务（可选）

## 如何使用数据库功能

### 方式一：核心 ODBC（通过环境变量）

启动容器时设置环境变量：

```bash
docker run -d \
  --name freeswitch \
  -e FREESWITCH_DB_HOST=mysql_host \
  -e FREESWITCH_DB_NAME=freeswitch \
  -e FREESWITCH_DB_USER=root \
  -e FREESWITCH_DB_PASSWORD=password \
  -e FREESWITCH_DB_PORT=3306 \
  bytedesk/freeswitch:latest
```

容器启动脚本会自动配置 `switch.conf.xml` 中的 `core-db-dsn`。

### 方式二：mod_mariadb API（在脚本中）

#### Lua 示例
```lua
-- 连接数据库
local dbh = freeswitch.Dbh("mariadb", 
    "host=localhost;port=3306;db=mydb;user=root;pass=password")

if dbh:connected() then
    -- 执行查询
    dbh:query("SELECT * FROM users WHERE id = 1", function(row)
        for key, val in pairs(row) do
            freeswitch.consoleLog("info", key .. " = " .. val .. "\n")
        end
    end)
    
    -- 释放连接
    dbh:release()
else
    freeswitch.consoleLog("err", "Cannot connect to database\n")
end
```

#### 拨号计划示例
```xml
<extension name="database_lookup">
  <condition field="destination_number" expression="^(\d+)$">
    <action application="lua" data="db_query.lua"/>
  </condition>
</extension>
```

### 方式三：mod_xml_curl（动态配置）

#### 配置 mod_xml_curl
```xml
<!-- autoload_configs/xml_curl.conf.xml -->
<configuration name="xml_curl.conf" description="cURL XML Gateway">
  <bindings>
    <binding name="dialplan">
      <param name="gateway-url" value="http://your-api-server.com/dialplan.php" 
             bindings="dialplan"/>
    </binding>
    <binding name="directory">
      <param name="gateway-url" value="http://your-api-server.com/directory.php" 
             bindings="directory"/>
    </binding>
  </bindings>
</configuration>
```

这样 FreeSWITCH 会通过 HTTP 从您的 API 服务器动态获取配置。

## 验证安装

### 检查已编译的模块

```bash
# 查看所有已编译的模块
docker exec freeswitch ls -l /usr/local/freeswitch/mod/

# 检查特定模块
docker exec freeswitch ls -l /usr/local/freeswitch/mod/mod_mariadb.so
docker exec freeswitch ls -l /usr/local/freeswitch/mod/mod_xml_curl.so
```

### 检查已加载的模块

```bash
# 进入 fs_cli
docker exec -it freeswitch fs_cli

# 在 fs_cli 中执行
freeswitch@internal> show modules | grep mariadb
freeswitch@internal> show modules | grep xml_curl
freeswitch@internal> module_exists mod_mariadb
```

### 测试数据库连接

```bash
# 在 fs_cli 中测试
freeswitch@internal> lua
Lua> dbh = freeswitch.Dbh("mariadb", "host=your_host;db=your_db;user=your_user;pass=your_pass")
Lua> print(dbh:connected())
```

## 常见问题

### Q1: 为什么找不到 mod_odbc？
**A:** 因为这个模块根本不存在。FreeSWITCH 的 ODBC 支持是内置在核心中的，通过 `--enable-core-odbc-support` 启用。

### Q2: 我应该使用哪个模块连接 MySQL？
**A:** 推荐使用 **mod_mariadb**，它是原生的 MySQL/MariaDB 驱动，性能更好，不依赖 ODBC。

### Q3: core-db-dsn 和 mod_mariadb 有什么区别？
**A:** 
- `core-db-dsn`: 用于 FreeSWITCH 核心数据库（内部状态、注册信息等）
- `mod_mariadb`: 提供 API 供拨号计划和脚本使用，用于自定义数据库操作

### Q4: 如何启用 mod_xml_odbc？
**A:** 这是一个实验性模块，不推荐使用。推荐使用 **mod_xml_curl**（已启用）来实现动态配置，更灵活、稳定。

### Q5: 打包后缺少 mod_odbc 模块怎么办？
**A:** 这是一个误解。检查以下内容：
1. ✅ 核心 ODBC 支持已启用（`--enable-core-odbc-support`）
2. ✅ mod_mariadb 已编译安装
3. ✅ ODBC 驱动已安装（unixodbc-dev, odbc-mariadb）
4. ✅ 配置文件中不要加载 `mod_odbc`（它不存在）

## 参考资源

- [FreeSWITCH 官方文档 - Database](https://freeswitch.org/confluence/display/FREESWITCH/Database)
- [mod_mariadb 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_mariadb)
- [mod_xml_curl 文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_xml_curl)
- [FreeSWITCH v1.10.12 源码](https://github.com/signalwire/freeswitch/tree/v1.10.12)
- [modules.conf.in 原文件](https://github.com/signalwire/freeswitch/blob/v1.10.12/build/modules.conf.in)

## 总结

✅ **正确的理解：**
- FreeSWITCH 通过 `--enable-core-odbc-support` 内置 ODBC 支持
- 使用 `mod_mariadb` 进行 MySQL/MariaDB 操作
- 使用 `mod_xml_curl` 实现动态配置
- 不存在 `mod_odbc` 模块

❌ **错误的理解：**
- ~~需要编译 `mod_odbc` 模块~~
- ~~在 modules.conf.xml 中加载 `mod_odbc`~~
- ~~缺少 `mod_odbc` 是打包问题~~

您的 Docker 镜像已经正确配置了所有必要的数据库支持功能！🎉
