# docker/sounds

此目录在镜像构建时会被复制到 `${FREESWITCH_PREFIX}/sounds`，用于覆盖 FreeSWITCH 默认安装的声音资源。

推荐使用构建脚本：

```bash
cd docker
./build.sh
```

脚本会自动将仓库根目录的 `../sounds/` 同步到 `./sounds/`，然后 Dockerfile 在构建中完成覆盖复制。

注意：
- 若直接使用 `docker build` 而不运行脚本，请确保本目录存在（已提供 `.gitkeep` 占位）。
- 如需跳过下载官方声音包，可在构建时传 `--build-arg INSTALL_SOUNDS=none`，镜像仍会使用你的本地 `sounds/` 内容。
