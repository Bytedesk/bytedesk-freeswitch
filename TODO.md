# TODO

- [x] 默认使用 docker/sounds 文件夹替换freeswitch编译之后的sounds文件夹，因为默认为空
	- 已实现：构建前由 `docker/build.sh` 同步仓库根目录 `sounds/` 到 `docker/sounds/`，并在 `docker/Dockerfile` 中用本地 `sounds/` 覆盖 `${FREESWITCH_PREFIX}/sounds`
- [x] docker/etc/odbcinst.ini 文件中的 Driver 和 Setup 路径是否是docker镜像之内的路径？如何确保路径文件存在？当前镜像是否存在此路径文件
	- 已修正：MySQL 区块改为使用 Ubuntu 22.04 的 MariaDB ODBC 驱动 `/usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so` 作为 `Driver` 与 `Setup`；PostgreSQL 区块暂注释，待安装 `odbc-postgresql` 后启用；镜像构建后路径通过系统包提供，`libmaodbc.so` 可用，确保文件存在
- [x] docker/etc/odbcinst.ini 中增加两种架构说明示例
	- 已增加：在文件头部与 [MySQL] 区块提供 amd64/arm64 路径示例，默认使用 amd64，arm64 作为注释备选；并在 compose 中支持通过 volume 将 deploy 下的 odbc 配置只读挂载
- [] 最新版镜像发布之后，运行报错，修复bug：
2025-10-23 12:57:05.502569 0.00% [INFO] mod_odbc_cdr.c:164 Field [network_addr] (network_addr) added to [cdr]
2025-10-23 20:57:07


2025-10-23 12:57:05.517858 0.00% [ERR] switch_odbc.c:375 STATE: HY000 CODE 2002 ERROR: [unixODBC][ma-3.1.15]Can't connect to local server through socket '/var/run/mysqld/mysqld.sock' (2)
2025-10-23 20:57:07


2025-10-23 20:57:07


2025-10-23 12:57:05.517908 0.00% [CRIT] switch_core_sqldb.c:645 Failure to connect to ODBC freeswitch!
2025-10-23 20:57:07


2025-10-23 12:57:05.517913 0.00% [ERR] mod_odbc_cdr.c:189 Error Opening DB
2025-10-23 20:57:07


2025-10-23 12:57:05.517914 0.00% [CRIT] mod_odbc_cdr.c:486 Cannot open DB!
2025-10-23 20:57:07


2025-10-23 12:57:05.517949 0.00% [CRIT] switch_loadable_module.c:1754 Error Loading module /usr/local/freeswitch/lib/freeswitch/mod/mod_odbc_cdr.so
2025-10-23 20:57:07


**Module load routine returned an error**

- [] 最新版镜像发布之后，运行报错，修复bug：2025-10-23 20:57:07


2025-10-23 12:57:07.574108 0.00% [CONSOLE] mod_local_stream.c:289 Can't open directory: /usr/local/freeswitch/share/freeswitch/sounds/music/32000
2025-10-23 20:57:07


2025-10-23 12:57:07.574141 0.00% [CONSOLE] mod_local_stream.c:289 Can't open directory: /usr/local/freeswitch/share/freeswitch/sounds/music/16000
2025-10-23 20:57:07


2025-10-23 12:57:07.574175 0.00% [CONSOLE] mod_local_stream.c:289 Can't open directory: /usr/local/freeswitch/share/freeswitch/sounds/music/48000