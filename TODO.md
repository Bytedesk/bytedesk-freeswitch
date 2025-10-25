# TODO

- [x] 默认使用 docker/sounds 文件夹替换freeswitch编译之后的sounds文件夹，因为默认为空
	- 已实现：构建前由 `docker/build.sh` 同步仓库根目录 `sounds/` 到 `docker/sounds/`，并在 `docker/Dockerfile` 中用本地 `sounds/` 覆盖 `${FREESWITCH_PREFIX}/sounds`
- [x] docker/etc/odbcinst.ini 文件中的 Driver 和 Setup 路径是否是docker镜像之内的路径？如何确保路径文件存在？当前镜像是否存在此路径文件
	- 已修正：MySQL 区块改为使用 Ubuntu 22.04 的 MariaDB ODBC 驱动 `/usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so` 作为 `Driver` 与 `Setup`；PostgreSQL 区块暂注释，待安装 `odbc-postgresql` 后启用；镜像构建后路径通过系统包提供，`libmaodbc.so` 可用，确保文件存在
- [x] docker/etc/odbcinst.ini 中增加两种架构说明示例
	- 已增加：在文件头部与 [MySQL] 区块提供 amd64/arm64 路径示例，默认使用 amd64，arm64 作为注释备选；并在 compose 中支持通过 volume 将 deploy 下的 odbc 配置只读挂载
- [x] 参考 freeswitch_mrcp.md 增加默认配置，并随 FreeSWITCH 启动百度 MRCP Server（改为运行时按 URL 下载），在 docker-compose 开放 baidu_appid、baidu_api_key、baidu_secret_key 等变量配置
- [x] The following files are over 100MB. If you commit these files, you will no longer be able to push this repository to GitHub.com.
docker/mrcp/mrcp_server_baidu/mrcp-server/plugin/libbaidu-asr.so
We recommend you avoid committing these files or use Git LFS to store large files on
GitHub.
 - [x] 因体积太大，无法上传到 GitHub，取消使用本地 docker/mrcp_server_baidu，改为容器启动时从 URL 下载（已在入口脚本实现，支持 BAIDU_MRCP_URL 覆盖）
- [x] 能否修改为在编译 FreeSWITCH 的时候，直接将 mrcp_server_baidu 下载并打包到镜像中（已实现：Dockerfile 构建期通过 BAIDU_MRCP_URL 下载并解压，入口脚本仅负责启动）
- [] 没有目录 /opt/mrcp/baidu/，存在目录 /opt/mrcp/baidu/MRCPServer/mrcp-server/logs，但文件夹中没有发现log文件
- [] 另外教我如何查看docker容器内端口是否存在的命令
