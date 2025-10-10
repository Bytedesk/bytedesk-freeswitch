# mod_java 启用检查清单

## ✅ 已完成的配置

### 1. Dockerfile 更新
- [x] 添加 Java 依赖：`default-jdk default-jre`
- [x] 启用 mod_java 编译：`sed -i 's/^#\(languages\/mod_java\)/\1/' build/modules.conf.in`

### 2. 模块配置更新
- [x] 在 `modules.conf.xml` 中添加 `<load module="mod_java" />`

### 3. 文档创建
- [x] 创建 `MOD_JAVA_GUIDE.md` - 详细配置指南
- [x] 创建 `MOD_JAVA_UPDATE_SUMMARY.md` - 更新总结
- [x] 更新 `CALLCENTER_QUICK_START.md` - 添加 mod_java

## 🔧 部署步骤

### 1. 构建镜像
```bash
cd /Users/ningjinpeng/Desktop/git/github/bytedesk-freeswitch/docker
docker build -t bytedesk/freeswitch:java .
```

### 2. 启动容器
```bash
docker run -d \
  --name freeswitch-java \
  -p 5060:5060/udp \
  -p 8021:8021 \
  bytedesk/freeswitch:java
```

### 3. 验证 Java 安装
```bash
docker exec freeswitch-java java -version
```

预期输出：
```
openjdk version "11.0.x" 2024-xx-xx
OpenJDK Runtime Environment (build 11.0.x+x-Ubuntu-xxubuntu1)
OpenJDK 64-Bit Server VM (build 11.0.x+x-Ubuntu-xxubuntu1, mixed mode)
```

### 4. 验证 mod_java 编译
```bash
docker exec freeswitch-java ls -la /usr/local/freeswitch/mod/mod_java.so
```

预期输出：
```
-rwxr-xr-x 1 root root xxxxx Oct 10 xx:xx /usr/local/freeswitch/mod/mod_java.so
```

### 5. 验证模块加载
```bash
docker exec freeswitch-java fs_cli -x "show modules" | grep java
```

预期输出：
```
mod_java
```

### 6. 测试 Java 功能
```bash
# 进入容器
docker exec -it freeswitch-java bash

# 创建测试目录
mkdir -p /usr/local/freeswitch/scripts/java

# 创建测试类
cat > /usr/local/freeswitch/scripts/java/HelloFS.java << 'EOF'
public class HelloFS {
    public static void main(String[] args) {
        System.out.println("FreeSWITCH Java Module Works!");
        System.out.println("Arguments: " + String.join(", ", args));
    }
}
EOF

# 编译
cd /usr/local/freeswitch/scripts/java
javac HelloFS.java

# 测试运行
fs_cli -x "java HelloFS test arg1 arg2"
```

## 📋 配置检查

### 必需的配置文件

#### 1. java.conf.xml
位置：`/usr/local/freeswitch/conf/autoload_configs/java.conf.xml`

创建基本配置：
```bash
docker exec freeswitch-java bash -c 'cat > /usr/local/freeswitch/conf/autoload_configs/java.conf.xml << EOF
<configuration name="java.conf" description="Java Configuration">
  <settings>
    <param name="classpath" value="/usr/local/freeswitch/scripts/java"/>
    <param name="options" value="-Xmx256m -Xms128m"/>
  </settings>
</configuration>
EOF'
```

#### 2. 重新加载配置
```bash
docker exec freeswitch-java fs_cli -x "reload mod_java"
```

## 🧪 功能测试

### 测试 1: 基本 Java 执行
```bash
# 创建测试
docker exec freeswitch-java bash -c 'cat > /tmp/test_java.sh << "SCRIPT"
#!/bin/bash
echo "Testing Java execution..."
fs_cli -x "java HelloFS"
SCRIPT'

docker exec freeswitch-java bash /tmp/test_java.sh
```

### 测试 2: 呼叫处理测试
创建简单的呼叫处理器并测试。

### 测试 3: 数据库连接测试
如果使用数据库，测试连接。

## 🔍 故障排查

### 问题 1: mod_java.so 不存在
```bash
# 检查编译日志
docker logs freeswitch-java 2>&1 | grep -i "java"

# 手动检查模块目录
docker exec freeswitch-java ls -la /usr/local/freeswitch/mod/ | grep java
```

### 问题 2: Java 未安装
```bash
# 检查 Java
docker exec freeswitch-java which java
docker exec freeswitch-java java -version

# 如果未安装，重新构建镜像
docker build --no-cache -t bytedesk/freeswitch:java .
```

### 问题 3: 模块加载失败
```bash
# 查看日志
docker exec freeswitch-java tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i java

# 尝试手动加载
docker exec freeswitch-java fs_cli -x "load mod_java"
```

### 问题 4: ClassNotFoundException
```bash
# 检查类路径
docker exec freeswitch-java fs_cli -x "eval \${java_classpath}"

# 确保类文件在正确位置
docker exec freeswitch-java ls -la /usr/local/freeswitch/scripts/java/
```

## 📊 性能验证

### 内存使用
```bash
# 检查容器内存
docker stats freeswitch-java --no-stream

# 检查 JVM 内存
docker exec freeswitch-java bash -c 'jps -v'
```

### CPU 使用
```bash
# 监控 CPU
docker exec freeswitch-java top -b -n 1 | head -20
```

## 📝 完成确认

- [ ] Docker 镜像构建成功
- [ ] Java 已正确安装（java -version 正常）
- [ ] mod_java.so 文件存在
- [ ] mod_java 模块已加载
- [ ] java.conf.xml 配置正确
- [ ] 测试 Java 类可以编译
- [ ] 测试 Java 类可以执行
- [ ] 拨号计划中可以调用 Java
- [ ] 日志记录正常
- [ ] 性能指标正常

## 🎯 下一步行动

1. **开发 Java 应用**
   - 创建呼叫处理器
   - 实现业务逻辑
   - 集成数据库

2. **配置优化**
   - 调整 JVM 参数
   - 配置连接池
   - 设置日志级别

3. **测试部署**
   - 功能测试
   - 性能测试
   - 压力测试

4. **生产部署**
   - 监控配置
   - 备份策略
   - 告警设置

## 📚 参考文档

- [MOD_JAVA_GUIDE.md](./MOD_JAVA_GUIDE.md) - 完整配置指南
- [MOD_JAVA_UPDATE_SUMMARY.md](./MOD_JAVA_UPDATE_SUMMARY.md) - 更新总结
- [CALLCENTER_MODULES_GUIDE.md](./CALLCENTER_MODULES_GUIDE.md) - 呼叫中心模块
- [FreeSWITCH 官方文档](https://freeswitch.org/confluence/)

## ⚠️ 注意事项

1. **内存要求**：Java 应用需要额外的内存（最少 512MB 给 JVM）
2. **启动时间**：JVM 启动需要时间，初次加载会较慢
3. **GC 停顿**：注意监控垃圾回收对呼叫的影响
4. **类加载**：大量类加载会影响性能，建议预热

## 🆘 获取帮助

如果遇到问题：
1. 查看 FreeSWITCH 日志：`/usr/local/freeswitch/log/freeswitch.log`
2. 查看 JVM 错误日志：`/usr/local/freeswitch/log/hs_err_*.log`
3. 检查系统日志：`docker logs freeswitch-java`
4. 联系技术支持：270580156@qq.com

---

**最后更新：** 2025-10-10  
**版本：** 1.0  
**状态：** ✅ 配置完成，待测试
