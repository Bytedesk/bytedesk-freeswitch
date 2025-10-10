# ODBC 配置文件重组总结

## 变更日期
2025-10-10

## 变更内容

### 1. 创建新的文件夹结构
在 `docker/` 文件夹内创建了 `etc/` 文件夹，与 `conf/` 文件夹同级。

```
docker/
├── etc/              # 新增：系统级配置文件
│   ├── README.md
│   ├── odbc.ini
│   └── odbcinst.ini
└── conf/             # 原有：FreeSWITCH 应用配置
    └── ...
```

### 2. 文件移动
将以下文件从 `docker/conf/` 移动到 `docker/etc/`：
- `odbc.ini` - ODBC 数据源配置
- `odbcinst.ini` - ODBC 驱动程序配置

### 3. Dockerfile 更新
更新了 `/docker/Dockerfile` 中的 ODBC 配置部分：

**修改前**:
```dockerfile
# 复制配置文件
COPY conf/ ${FREESWITCH_PREFIX}/conf/

# 配置 ODBC（复制 ODBC 配置文件到系统目录）
RUN mkdir -p /etc/odbc && \
    cp ${FREESWITCH_PREFIX}/conf/odbc.ini /etc/odbc.ini && \
    cp ${FREESWITCH_PREFIX}/conf/odbcinst.ini /etc/odbcinst.ini && \
    chmod 644 /etc/odbc.ini /etc/odbcinst.ini
```

**修改后**:
```dockerfile
# 复制配置文件
COPY conf/ ${FREESWITCH_PREFIX}/conf/

# 配置 ODBC（复制 ODBC 配置文件到系统目录）
# 从 docker/etc/ 文件夹复制 ODBC 配置文件
COPY etc/odbc.ini /etc/odbc.ini
COPY etc/odbcinst.ini /etc/odbcinst.ini
RUN chmod 644 /etc/odbc.ini /etc/odbcinst.ini
```

### 4. 添加文档
创建了 `docker/etc/README.md` 文档，详细说明：
- 文件用途和目标位置
- 与其他配置文件的关系
- 配置层次结构
- 环境变量说明
- 注意事项

## 变更原因

### 更清晰的文件组织
- **系统级配置** (`etc/`) - 包含会被复制到容器 `/etc/` 目录的系统级配置文件
- **应用级配置** (`conf/`) - 包含 FreeSWITCH 应用程序专用的配置文件

### 符合 Linux 标准
- `/etc/` 目录在 Linux 系统中是标准的系统配置文件目录
- 将系统级的 ODBC 配置与 FreeSWITCH 应用配置分离更符合 Unix/Linux 的文件系统层次标准

### 更好的可维护性
- 明确区分系统级配置和应用级配置
- 更容易理解配置文件的用途和作用域
- 减少配置文件混乱

## 配置层次说明

```
系统层 (docker/etc/)
├── odbc.ini          → 复制到 /etc/odbc.ini
└── odbcinst.ini      → 复制到 /etc/odbcinst.ini
    ↓
    被引用 (DSN 格式: freeswitch:user:pass)
    ↓
FreeSWITCH 层 (docker/conf/)
├── vars.xml
│   └── odbc_dsn=freeswitch:${db_username}:${db_password}
│
└── autoload_configs/
    ├── odbc.conf.xml     # FreeSWITCH 内部连接池 (database name="default")
    ├── db.conf.xml       # 使用系统 DSN (mod_db)
    └── odbc_cdr.conf.xml # 使用内部连接池 (mod_odbc_cdr)
```

## 影响范围

### 需要重新构建
此变更修改了 Dockerfile，因此需要重新构建 Docker 镜像：

```bash
cd docker
docker build -t bytedesk/freeswitch:latest .
```

### 配置文件位置
- 容器内 `/etc/odbc.ini` 和 `/etc/odbcinst.ini` 的来源从 `conf/` 改为 `etc/`
- FreeSWITCH 的其他配置文件位置不变，仍在 `/usr/local/freeswitch/conf/`

### 功能影响
- **无功能变更** - 只是重新组织了文件结构，配置内容和功能完全相同
- 所有 ODBC 相关功能保持不变

## 后续步骤

1. **重新构建镜像**
   ```bash
   cd docker
   docker build -t bytedesk/freeswitch:latest .
   ```

2. **测试验证**
   - 启动容器并验证 ODBC 配置是否正确加载
   - 检查 `/etc/odbc.ini` 和 `/etc/odbcinst.ini` 是否存在
   - 测试数据库连接是否正常

3. **文档更新**
   - 更新其他相关文档中提到文件路径的部分
   - 更新部署文档说明新的文件结构

## 相关文档
- `/docker/etc/README.md` - ODBC 系统配置说明
- `/docker/ODBC_DSN_FIX_SUMMARY.md` - ODBC DSN 配置修复说明
- `/docker/ODBC_QUICK_REFERENCE.md` - ODBC 快速参考

## 检查清单
- [x] 创建 `docker/etc/` 文件夹
- [x] 移动 `odbc.ini` 到 `docker/etc/`
- [x] 移动 `odbcinst.ini` 到 `docker/etc/`
- [x] 更新 `Dockerfile` 中的 COPY 路径
- [x] 创建 `docker/etc/README.md` 文档
- [x] 创建变更总结文档
- [ ] 重新构建 Docker 镜像
- [ ] 测试验证 ODBC 功能
