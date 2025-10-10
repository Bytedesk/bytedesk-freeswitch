# ODBC 配置快速参考

## ODBC DSN 格式对照表

| 模块 | 错误格式 ❌ | 正确格式 ✅ |
|------|-----------|-----------|
| mod_db | `mysql:host=...;port=...;database=...;uid=...;pwd=...` | `freeswitch:root:password` |
| mod_odbc_cdr | `mysql:host=...;port=...;database=...;uid=...;pwd=...` | `freeswitch:root:password` |
| mod_directory | `mysql:host=...;port=...;database=...;uid=...;pwd=...` | `freeswitch:root:password` |
| mod_lcr | `mysql:host=...;port=...;database=...;uid=...;pwd=...` | `freeswitch:root:password` |

## 配置文件检查清单

- [x] **创建 `/etc/odbc.ini`** - 定义 DSN 数据源
- [x] **创建 `/etc/odbcinst.ini`** - 定义 ODBC 驱动
- [x] **修改 `vars.xml`** - 设置 `odbc_dsn` 变量为 DSN 格式
- [x] **修改 `db.conf.xml`** - 使用 DSN 格式
- [x] **修改 `directory_mysql.conf.xml`** - 使用 DSN 格式或注释掉
- [x] **更新 `Dockerfile`** - 复制 ODBC 配置文件到 `/etc/`

## 快速命令

### 测试 ODBC 连接
```bash
# 在容器中测试
docker exec -it <container_name> isql -v freeswitch root r8FqfdbWUaN3
```

### 查看 DSN 列表
```bash
docker exec -it <container_name> odbcinst -q -s
```

### 查看 FreeSWITCH 日志
```bash
docker exec -it <container_name> tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i odbc
```

### 重新构建镜像
```bash
cd docker
docker build --no-cache -t bytedesk/freeswitch:1.10.12 .
```

## 常见问题快速诊断

| 错误信息 | 可能原因 | 快速解决 |
|---------|---------|---------|
| `Invalid value for parameter [odbc-dsn]` | 格式错误 | 改为 `dsn:user:pass` 格式 |
| `Data source name not found` | DSN 未定义 | 检查 `/etc/odbc.ini` |
| `Can't open lib 'MySQL'` | 驱动路径错误 | 检查 `/etc/odbcinst.ini` 中的 Driver 路径 |
| `Access denied for user` | 密码错误 | 检查数据库密码和权限 |
| `Can't connect to MySQL server` | 网络不通 | 检查数据库地址和防火墙 |

## 文件位置

```
docker/
├── conf/
│   ├── odbc.ini           # ODBC 数据源配置（新增）
│   ├── odbcinst.ini       # ODBC 驱动配置（新增）
│   ├── vars.xml           # 全局变量（已修改）
│   └── autoload_configs/
│       ├── db.conf.xml              # DB 模块（已修改）
│       ├── directory_mysql.conf.xml # Directory 模块（已修改）
│       └── odbc_cdr.conf.xml        # CDR 模块（已验证）
└── Dockerfile             # 镜像构建文件（已修改）
```

## 验证步骤

1. ✅ **构建镜像**
   ```bash
   docker build -t bytedesk/freeswitch:1.10.12 .
   ```

2. ✅ **启动容器**
   ```bash
   docker-compose up -d
   ```

3. ✅ **检查 ODBC 文件**
   ```bash
   docker exec <container> cat /etc/odbc.ini
   docker exec <container> cat /etc/odbcinst.ini
   ```

4. ✅ **测试 ODBC 连接**
   ```bash
   docker exec <container> isql -v freeswitch root password
   ```

5. ✅ **查看 FreeSWITCH 日志**
   ```bash
   docker logs -f <container> | grep -i "odbc\|cdr\|db.conf"
   ```

6. ✅ **验证模块加载**
   ```bash
   docker exec <container> fs_cli -x "module_exists mod_odbc_cdr"
   docker exec <container> fs_cli -x "module_exists mod_db"
   ```

## 下一步

如果仍然有问题，请查看详细文档：
- `ODBC_DSN_FIX.md` - 完整的修复文档
- `MOD_AV_FFMPEG_FIX.md` - FFmpeg 符号问题修复

---

**提示**：使用 `--no-cache` 重新构建可确保使用最新的配置文件：
```bash
docker build --no-cache -t bytedesk/freeswitch:1.10.12 .
```
