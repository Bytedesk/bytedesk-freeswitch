> [MOVED] 本文档已迁移至 `docker/docs/MOD_JAVA_UPDATE_SUMMARY.md`，此处副本已弃用，请访问新位置。
# mod_java 模块启用总结

## 更新日期
2025-10-10

## 用户需求
启用 `languages/mod_java` 模块，以便使用 Java 语言编写 FreeSWITCH 应用程序。

## 已完成的工作

### 1. ✅ Dockerfile 更新

#### 添加 Java 依赖包
```dockerfile
# Java 开发环境（用于 mod_java）
default-jdk default-jre
```

这将安装：
- **default-jdk** - Java Development Kit（OpenJDK）
- **default-jre** - Java Runtime Environment

在 Ubuntu 22.04 上，通常安装的是 OpenJDK 11 或更高版本。

#### 启用 mod_java 编译
```dockerfile
sed -i 's/^#\(languages\/mod_java\)/\1/' build/modules.conf.in
```

### 2. ✅ modules.conf.xml 更新

添加模块加载配置：
```xml
<!-- Java 语言支持 - 用于编写 Java 应用 -->
<load module="mod_java" />
```

### 3. ✅ 创建配置文档

创建了详细的配置指南：`MOD_JAVA_GUIDE.md`

包含内容：
- mod_java 配置说明
- JVM 参数优化
- Java 应用示例
- 数据库集成示例
- 事件监听器示例
- Maven 项目配置
- API 命令使用
- 性能优化建议
- 故障排查指南
- 安全建议

## mod_java 主要功能

### 1. 呼叫处理
使用 Java 处理呼入/呼出呼叫：
```java
public class CallHandler {
    public static void handle(CoreSession session) {
        session.answer();
        session.streamFile("/sounds/welcome.wav", 0);
        session.hangup();
    }
}
```

### 2. 数据库集成
```java
// 查询客户信息
Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
PreparedStatement stmt = conn.prepareStatement("SELECT * FROM customers WHERE phone = ?");
```

### 3. 事件监听
```java
// 监听呼叫中心事件
ESLconnection conn = new ESLconnection("localhost", 8021, "ClueCon");
conn.events("plain", "CUSTOM callcenter::info");
```

### 4. API 调用
```java
// 执行 FreeSWITCH API 命令
API api = new API();
String result = api.executeString("status");
```

## 使用场景

### 1. 企业级应用开发
- 复杂的业务逻辑处理
- 大型系统集成
- 企业应用服务器集成

### 2. 数据库密集型应用
- 客户关系管理（CRM）集成
- 实时数据查询和更新
- 报表生成

### 3. 第三方系统集成
- REST API 调用
- SOAP Web 服务集成
- 消息队列集成（ActiveMQ、RabbitMQ）

### 4. 高性能计算
- 并发处理
- 线程池管理
- 异步任务处理

## 配置要求

### 系统要求
- **CPU**: 2+ 核心（推荐 4 核）
- **内存**: 最少 2GB RAM（JVM 需要额外内存）
- **磁盘**: 额外 500MB（JDK 安装）

### JVM 内存配置

| 系统规模 | 堆内存（Xmx） | 初始内存（Xms） | 并发呼叫 |
|---------|--------------|----------------|----------|
| 小型    | 256MB        | 128MB          | < 50     |
| 中型    | 512MB        | 256MB          | 50-200   |
| 大型    | 1024MB       | 512MB          | > 200    |

## 性能对比

### 与其他语言模块对比

| 特性 | mod_java | mod_lua | mod_python3 |
|------|----------|---------|-------------|
| 执行速度 | 快 | 非常快 | 中等 |
| 内存占用 | 高（JVM） | 低 | 中等 |
| 开发效率 | 高 | 中 | 高 |
| 库生态 | 非常丰富 | 丰富 | 非常丰富 |
| 类型安全 | 强类型 | 动态类型 | 动态类型 |
| 适用场景 | 企业应用 | 轻量脚本 | 快速开发 |

## 拨号计划示例

```xml
<!-- 使用 Java 处理呼叫 -->
<extension name="java_handler">
  <condition field="destination_number" expression="^7000$">
    <action application="java" data="org.freeswitch.example.CallHandler"/>
  </condition>
</extension>

<!-- 使用 Java 进行客户查询 -->
<extension name="java_customer_lookup">
  <condition field="destination_number" expression="^7001$">
    <action application="java" data="org.freeswitch.example.CustomerLookup"/>
  </condition>
</extension>
```

## 验证步骤

### 1. 检查 Java 安装
```bash
docker exec freeswitch java -version
```

预期输出：
```
openjdk version "11.0.x" ...
OpenJDK Runtime Environment ...
OpenJDK 64-Bit Server VM ...
```

### 2. 检查模块编译
```bash
docker exec freeswitch ls -la /usr/local/freeswitch/mod/mod_java.so
```

### 3. 检查模块加载
```bash
docker exec freeswitch fs_cli -x "show modules" | grep java
```

预期输出：
```
mod_java
```

### 4. 测试 Java 应用
```bash
# 创建测试类
cat > /usr/local/freeswitch/scripts/java/Test.java << 'EOF'
public class Test {
    public static void main(String[] args) {
        System.out.println("FreeSWITCH Java Module is working!");
    }
}
EOF

# 编译
javac /usr/local/freeswitch/scripts/java/Test.java

# 在 fs_cli 中测试
fs_cli -x "java Test"
```

## 构建和部署

### 构建 Docker 镜像
```bash
cd docker
docker build -t bytedesk/freeswitch:java .
```

### 启动容器
```bash
docker run -d \
  --name freeswitch \
  -p 5060:5060/udp \
  -p 8021:8021 \
  -e JAVA_HOME=/usr/lib/jvm/default-java \
  bytedesk/freeswitch:java
```

### 验证部署
```bash
# 检查 Java 版本
docker exec freeswitch java -version

# 检查 mod_java 加载
docker exec freeswitch fs_cli -x "module_exists mod_java"
```

## 常见问题

### Q1: mod_java 加载失败？
**A:** 检查以下几点：
1. 确认 JDK 已正确安装：`java -version`
2. 检查 JAVA_HOME 环境变量：`echo $JAVA_HOME`
3. 查看 FreeSWITCH 日志：`tail -f /usr/local/freeswitch/log/freeswitch.log`

### Q2: ClassNotFoundException？
**A:** 检查类路径配置：
```xml
<param name="classpath" value="/usr/local/freeswitch/scripts/java:/path/to/libs/*"/>
```

### Q3: OutOfMemoryError？
**A:** 增加 JVM 堆内存：
```xml
<param name="options" value="-Xmx1024m -Xms512m"/>
```

### Q4: Java 性能慢？
**A:** 优化建议：
1. 使用连接池（数据库、Redis）
2. 启用 G1 垃圾回收器
3. 预加载常用类
4. 使用异步处理

## 最佳实践

### 1. 使用连接池
```java
// HikariCP 数据库连接池
HikariConfig config = new HikariConfig();
config.setMaximumPoolSize(10);
dataSource = new HikariDataSource(config);
```

### 2. 异步处理
```java
// 使用 CompletableFuture 进行异步处理
CompletableFuture.supplyAsync(() -> {
    return queryDatabase();
}).thenAccept(result -> {
    processResult(result);
});
```

### 3. 错误处理
```java
try {
    session.answer();
    // 处理呼叫
} catch (Exception e) {
    session.consoleLog("ERROR", "Call handling failed: " + e.getMessage());
    session.streamFile("/sounds/error.wav", 0);
} finally {
    session.hangup();
}
```

### 4. 日志记录
```java
import java.util.logging.*;

Logger logger = Logger.getLogger(CallHandler.class.getName());
logger.info("Processing call from: " + callerNumber);
logger.warning("Database connection slow");
logger.severe("Critical error occurred");
```

## 相关文档

- [MOD_JAVA_GUIDE.md](./MOD_JAVA_GUIDE.md) - 详细配置指南
- [CALLCENTER_MODULES_GUIDE.md](./CALLCENTER_MODULES_GUIDE.md) - 呼叫中心模块指南
- [CALLCENTER_QUICK_START.md](./CALLCENTER_QUICK_START.md) - 快速开始指南

## 参考资源

- [FreeSWITCH Java API](https://freeswitch.org/confluence/display/FREESWITCH/Java+ESL)
- [OpenJDK Documentation](https://openjdk.java.net/documentation/)
- [Java SE API Documentation](https://docs.oracle.com/en/java/javase/11/docs/api/)
- [FreeSWITCH Event Socket Library](https://freeswitch.org/confluence/display/FREESWITCH/Event+Socket+Library)

## 下一步

1. ✅ **编写 Java 应用** - 创建自定义呼叫处理逻辑
2. ✅ **配置 JVM 参数** - 优化内存和性能
3. ✅ **集成数据库** - 连接 MySQL/PostgreSQL
4. ✅ **实现业务逻辑** - 开发呼叫中心功能
5. ✅ **性能测试** - 压力测试和优化
6. ✅ **监控部署** - 设置监控和告警

## 更新日志

- 2025-10-10: 启用 mod_java 模块
  - 添加 default-jdk 和 default-jre 依赖
  - 在 Dockerfile 中启用编译
  - 在 modules.conf.xml 中启用加载
  - 创建详细的配置指南

---

**维护者：** ByteDesk Team  
**联系方式：** 270580156@qq.com  
**项目地址：** https://github.com/Bytedesk/bytedesk-freeswitch
