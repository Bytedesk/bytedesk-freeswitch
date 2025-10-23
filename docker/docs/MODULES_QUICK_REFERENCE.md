# FreeSWITCH v1.10.12 模块配置快速参考

## ⚠️ 重要提醒

### FreeSWITCH 中没有 `mod_odbc` 模块！

如果您在配置文件中看到：
```xml
<load module="mod_odbc" />  <!-- ❌ 这是错误的！这个模块不存在！ -->
```

FreeSWITCH 启动时会报错：
```
[ERR] mod_enum.c:1011 Can't load mod_odbc
```

## ✅ 正确的数据库模块配置

### 1. 使用核心 ODBC 支持

**编译时：**
```dockerfile
./configure --enable-core-odbc-support
```

**配置文件：** `autoload_configs/switch.conf.xml`
```xml
<param name="core-db-dsn" value="mariadb://Server=host;Port=3306;Database=db;Uid=user;Pwd=pass;" />
```

**不需要在 modules.conf.xml 中加载任何模块！**

### 2. 使用 mod_mariadb

**编译时（v1.10.12）：**
```bash
# 在 build/modules.conf.in 中启用
sed -i 's/^#\(databases\/mod_mariadb\)/\1/' build/modules.conf.in
make mod_mariadb && make mod_mariadb-install
```

**配置文件：** `autoload_configs/modules.conf.xml`
```xml
<!-- 如果需要在拨号计划/脚本中使用，才加载此模块 -->
<!-- <load module="mod_mariadb"/> -->
```

**使用场景：** Lua 脚本、JavaScript、拨号计划中的数据库查询

## 📋 当前镜像的模块配置

### Dockerfile 中启用的模块

```dockerfile
# 启用 mod_mariadb（MySQL/MariaDB 原生驱动）
sed -i 's/^#\(databases\/mod_mariadb\)/\1/' build/modules.conf.in

# 启用 mod_xml_curl（HTTP 动态配置）
sed -i 's/^#\(xml_int\/mod_xml_curl\)/\1/' build/modules.conf.in

# 启用 mod_say_zh（中文语音）
sed -i 's/^#\(say\/mod_say_zh\)/\1/' build/modules.conf.in

# 禁用 mod_verto（使用 mod_sofia + WebSocket 替代）
sed -i '/mod_verto/s/^[^#]/# &/' build/modules.conf.in

# 条件性禁用 mod_signalwire（除非 BUILD_SIGNALWIRE=1）
if [ "${BUILD_SIGNALWIRE}" != "1" ]; then
    sed -i '/mod_signalwire/s/^[^#]/# &/' build/modules.conf.in
fi
```

### modules.conf.xml 中加载的模块

```xml
<configuration name="modules.conf" description="Modules">
  <modules>
    <!-- Loggers -->
    <load module="mod_console" />
    <load module="mod_logfile" />

    <!-- Multi-Faceted -->
    <load module="mod_enum" />

    <!-- XML Interfaces -->
    <load module="mod_xml_curl" />

    <!-- Event Handlers -->
    <load module="mod_cdr_csv" />
    <load module="mod_event_socket" />

    <!-- Endpoints -->
    <load module="mod_sofia" />
    <load module="mod_loopback" />
    <load module="mod_rtc" />

    <!-- Applications -->
    <load module="mod_commands" />
    <load module="mod_conference" />
    <load module="mod_db" />
    <load module="mod_dptools" />
    <load module="mod_expr" />
    <load module="mod_fifo" />
    <load module="mod_hash" />
    <load module="mod_voicemail" />
    <load module="mod_esf" />
    <load module="mod_fsv" />
    <load module="mod_valet_parking" />
    <load module="mod_httapi" />

    <!-- Dialplan Interfaces -->
    <load module="mod_dialplan_xml" />
    <load module="mod_dialplan_asterisk" />

    <!-- Codec Interfaces -->
    <load module="mod_spandsp" />
    <load module="mod_g723_1" />
    <load module="mod_g729" />
    <load module="mod_amr" />
    <load module="mod_b64" />
    <load module="mod_opus" />

    <!-- File Format Interfaces -->
    <load module="mod_av" />
    <load module="mod_sndfile" />
    <load module="mod_native_file" />
    <load module="mod_png" />
    <load module="mod_local_stream" />
    <load module="mod_tone_stream" />

    <!-- Languages -->
    <load module="mod_lua" />

    <!-- Say -->
    <load module="mod_say_en" />
    <load module="mod_say_zh" />
  </modules>
</configuration>
```

## 🔍 常见错误排查

### 错误 1：Can't load mod_odbc

**错误信息：**
```
[ERR] mod_enum.c:1011 Can't load mod_odbc
```

**原因：** modules.conf.xml 中尝试加载不存在的模块

**解决方案：** 从 modules.conf.xml 中删除这一行：
```xml
<load module="mod_odbc" />  <!-- 删除这行 -->
```

### 错误 2：数据库连接失败

**检查清单：**
1. ✅ 核心 ODBC 支持已编译（`--enable-core-odbc-support`）
2. ✅ ODBC 驱动已安装（`unixodbc-dev`, `odbc-mariadb`）
3. ✅ 数据库 DSN 配置正确
4. ✅ 数据库服务器可访问
5. ✅ 用户名密码正确

### 错误 3：Lua 中无法使用数据库

**检查清单：**
1. ✅ mod_mariadb 已编译
2. ✅ mod_mariadb.so 文件存在
3. ✅ 如需在启动时加载，在 modules.conf.xml 中添加：
   ```xml
   <load module="mod_mariadb"/>
   ```

## 🚀 验证命令

```bash
# 1. 检查编译的模块文件
docker exec freeswitch ls -la /usr/local/freeswitch/mod/ | grep -E "mariadb|xml_curl|say_zh"

# 2. 检查已加载的模块
docker exec -it freeswitch fs_cli -x "show modules" | grep -E "mariadb|xml_curl|say_zh"

# 3. 检查核心配置
docker exec -it freeswitch fs_cli -x "global_getvar core_db_dsn"

# 4. 测试数据库连接（在 fs_cli 中）
docker exec -it freeswitch fs_cli
freeswitch@internal> lua
Lua> dbh = freeswitch.Dbh("mariadb", "host=your_host;db=your_db;user=your_user;pass=your_pass")
Lua> print(dbh:connected())
```

## 📚 参考文档

详细说明请查看：
- `MODULES_EXPLANATION.md` - 完整的模块说明文档
- [FreeSWITCH 官方 v1.10.12 modules.conf.in](https://github.com/signalwire/freeswitch/blob/v1.10.12/build/modules.conf.in)

---

**记住：没有 mod_odbc，只有核心 ODBC 支持！** 🎯
