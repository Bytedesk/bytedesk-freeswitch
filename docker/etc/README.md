# FreeSWITCH ODBC 系统配置文件

此文件夹包含系统级别的 ODBC 配置文件，这些文件会被复制到 Docker 容器的 `/etc/` 目录。

## 文件说明

### odbc.ini
- **用途**: ODBC 数据源名称 (DSN) 配置
- **目标位置**: `/etc/odbc.ini`
- **说明**: 定义了 FreeSWITCH 使用的 ODBC 数据源连接信息

### odbcinst.ini
- **用途**: ODBC 驱动程序配置
- **目标位置**: `/etc/odbcinst.ini`
- **说明**: 定义了 MySQL 和 PostgreSQL 的 ODBC 驱动程序位置和设置

## 与其他配置的关系

```
docker/
├── etc/                           # 系统级 ODBC 配置（本文件夹）
│   ├── odbc.ini                  # → /etc/odbc.ini
│   └── odbcinst.ini              # → /etc/odbcinst.ini
│
└── conf/                          # FreeSWITCH 应用配置
    ├── vars.xml                   # 定义数据库连接变量
    └── autoload_configs/
        ├── odbc.conf.xml         # FreeSWITCH 内部 ODBC 连接池
        ├── db.conf.xml           # mod_db 使用系统 DSN (freeswitch:user:pass)
        └── odbc_cdr.conf.xml     # mod_odbc_cdr 使用内部连接池 (default)
```

## 配置层次

1. **系统 ODBC** (etc/odbc.ini, etc/odbcinst.ini)
   - 提供系统级的 DSN 配置
   - mod_db 通过 DSN 名称连接数据库

2. **FreeSWITCH ODBC 池** (conf/autoload_configs/odbc.conf.xml)
   - FreeSWITCH 内部管理的数据库连接池
   - mod_odbc_cdr 和其他模块通过数据库名引用

3. **模块配置** (conf/autoload_configs/*.conf.xml)
   - 各个模块根据需要选择使用系统 DSN 或内部连接池

## 环境变量

这些配置文件会在容器启动时通过 `docker-entrypoint.sh` 脚本使用以下环境变量进行动态配置：

- `FREESWITCH_DB_HOST` - 数据库主机地址（默认: bytedesk-mysql）
- `FREESWITCH_DB_PORT` - 数据库端口（默认: 3306）
- `FREESWITCH_DB_NAME` - 数据库名称（默认: bytedesk_freeswitch）
- `FREESWITCH_DB_USER` - 数据库用户名（默认: root）
- `FREESWITCH_DB_PASSWORD` - 数据库密码

## 注意事项

1. **安全性**: 生产环境中请修改默认的数据库密码
2. **路径**: 驱动程序路径需要与系统实际安装的驱动位置一致
3. **字符集**: 建议使用 `utf8mb4` 以支持完整的 Unicode 字符
4. **连接选项**: `Option = 16777216` 启用 MySQL 自动重连

## 更新日期
2025-10-10
