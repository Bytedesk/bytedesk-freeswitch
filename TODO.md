# TODO

- [x] 默认使用 docker/sounds 文件夹替换freeswitch编译之后的sounds文件夹，因为默认为空
	- 已实现：构建前由 `docker/build.sh` 同步仓库根目录 `sounds/` 到 `docker/sounds/`，并在 `docker/Dockerfile` 中用本地 `sounds/` 覆盖 `${FREESWITCH_PREFIX}/sounds`
- [x] docker/etc/odbcinst.ini 文件中的 Driver 和 Setup 路径是否是docker镜像之内的路径？如何确保路径文件存在？当前镜像是否存在此路径文件
	- 已修正：MySQL 区块改为使用 Ubuntu 22.04 的 MariaDB ODBC 驱动 `/usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so` 作为 `Driver` 与 `Setup`；PostgreSQL 区块暂注释，待安装 `odbc-postgresql` 后启用；镜像构建后路径通过系统包提供，`libmaodbc.so` 可用，确保文件存在
- [x] docker/etc/odbcinst.ini 中增加两种架构说明示例
	- 已增加：在文件头部与 [MySQL] 区块提供 amd64/arm64 路径示例，默认使用 amd64，arm64 作为注释备选；并在 compose 中支持通过 volume 将 deploy 下的 odbc 配置只读挂载