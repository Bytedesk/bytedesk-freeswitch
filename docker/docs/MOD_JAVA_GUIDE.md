# FreeSWITCH mod_java 模块配置指南

## 概述

mod_java 允许您使用 Java 语言编写 FreeSWITCH 应用程序和脚本。这为 Java 开发者提供了强大的呼叫控制能力。

## 已完成的配置

### 1. Dockerfile 更新

#### 添加 Java 依赖
```dockerfile
# Java 开发环境（用于 mod_java）
default-jdk default-jre
```

这将安装：
- **default-jdk**: Java Development Kit（Java 开发工具包）
- **default-jre**: Java Runtime Environment（Java 运行时环境）

在 Ubuntu 22.04 上，这通常是 OpenJDK 11 或更高版本。

#### 启用编译
```dockerfile
sed -i 's/^#\(languages\/mod_java\)/\1/' build/modules.conf.in
```

### 2. modules.conf.xml 更新

```xml
<!-- Java 语言支持 - 用于编写 Java 应用 -->
<load module="mod_java" />
```

## mod_java 配置文件

配置文件位置：`/usr/local/freeswitch/conf/autoload_configs/java.conf.xml`

### 基本配置示例

```xml
<configuration name="java.conf" description="Java Configuration">
  <settings>
    <!-- Java 类路径 -->
    <param name="classpath" value="/usr/local/freeswitch/scripts/java"/>
    
    <!-- JVM 选项 -->
    <param name="options" value="-Xmx256m -Xms128m"/>
    
    <!-- 启动类（可选） -->
    <!-- <param name="startup-class" value="org.freeswitch.Startup"/> -->
    
    <!-- 启动脚本（可选） -->
    <!-- <param name="startup-script" value="/usr/local/freeswitch/scripts/startup.js"/> -->
  </settings>
</configuration>
```

### 配置参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| classpath | Java 类路径，指定 .class 或 .jar 文件位置 | /usr/local/freeswitch/scripts/java |
| options | JVM 启动参数 | -Xmx256m |
| startup-class | FreeSWITCH 启动时自动加载的 Java 类 | 无 |
| startup-script | FreeSWITCH 启动时自动执行的脚本 | 无 |

### JVM 选项建议

```xml
<!-- 生产环境推荐配置 -->
<param name="options" value="-Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"/>

<!-- 开发环境调试配置 -->
<param name="options" value="-Xmx256m -Xms128m -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"/>
```

## Java 应用示例

### 1. 简单的呼叫处理器

```java
// /usr/local/freeswitch/scripts/java/SimpleCallHandler.java
package org.freeswitch.example;

import org.freeswitch.swig.*;

public class SimpleCallHandler {
    
    public static void handle(CoreSession session) {
        // 接听电话
        session.answer();
        
        // 获取呼叫信息
        String callerNumber = session.getVariable("caller_id_number");
        String destNumber = session.getVariable("destination_number");
        
        System.out.println("Call from: " + callerNumber + " to: " + destNumber);
        
        // 播放欢迎语音
        session.streamFile("/usr/local/freeswitch/sounds/en/us/callie/ivr/8000/ivr-welcome.wav", 0);
        
        // 播放音乐保持
        session.streamFile("/usr/local/freeswitch/sounds/music/8000/suite-espanola-op-47-leyenda.wav", 0);
        
        // 挂断
        session.hangup();
    }
}
```

### 编译 Java 代码

```bash
# 创建目录
mkdir -p /usr/local/freeswitch/scripts/java/org/freeswitch/example

# 编译（需要 FreeSWITCH Java 库）
javac -cp /usr/local/freeswitch/lib/freeswitch.jar \
      -d /usr/local/freeswitch/scripts/java \
      SimpleCallHandler.java
```

### 2. 拨号计划集成

```xml
<!-- /usr/local/freeswitch/conf/dialplan/default.xml -->
<extension name="java_handler">
  <condition field="destination_number" expression="^7000$">
    <action application="java" data="org.freeswitch.example.SimpleCallHandler"/>
  </condition>
</extension>
```

### 3. 高级应用 - 数据库集成

```java
package org.freeswitch.example;

import org.freeswitch.swig.*;
import java.sql.*;

public class DatabaseCallHandler {
    
    private static final String DB_URL = "jdbc:mysql://localhost:3306/callcenter";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "password";
    
    public static void handle(CoreSession session) {
        session.answer();
        
        String callerNumber = session.getVariable("caller_id_number");
        
        try {
            // 连接数据库
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            
            // 查询客户信息
            PreparedStatement stmt = conn.prepareStatement(
                "SELECT name, vip_level FROM customers WHERE phone = ?"
            );
            stmt.setString(1, callerNumber);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                String name = rs.getString("name");
                int vipLevel = rs.getInt("vip_level");
                
                // 设置变量供其他应用使用
                session.setVariable("customer_name", name);
                session.setVariable("vip_level", String.valueOf(vipLevel));
                
                // VIP 客户优先处理
                if (vipLevel >= 3) {
                    session.execute("set", "cc_base_score=100");
                    session.streamFile("/sounds/vip_welcome.wav", 0);
                } else {
                    session.streamFile("/sounds/welcome.wav", 0);
                }
                
                // 转接到队列
                session.execute("callcenter", "support@default");
            } else {
                // 新客户
                session.streamFile("/sounds/new_customer.wav", 0);
                session.execute("callcenter", "support@default");
            }
            
            rs.close();
            stmt.close();
            conn.close();
            
        } catch (SQLException e) {
            System.err.println("Database error: " + e.getMessage());
            session.streamFile("/sounds/error.wav", 0);
        }
    }
}
```

### 4. 事件监听器

```java
package org.freeswitch.example;

import org.freeswitch.esl.*;

public class CallCenterMonitor {
    
    public static void main(String[] args) {
        try {
            // 连接到 FreeSWITCH Event Socket
            ESLconnection conn = new ESLconnection("localhost", 8021, "ClueCon");
            
            if (!conn.connected()) {
                System.err.println("Failed to connect to FreeSWITCH");
                return;
            }
            
            // 订阅呼叫中心事件
            conn.events("plain", "CUSTOM callcenter::info");
            
            System.out.println("Monitoring call center events...");
            
            while (conn.connected()) {
                ESLevent event = conn.recvEvent();
                
                if (event != null) {
                    String eventName = event.getHeader("Event-Name");
                    String action = event.getHeader("CC-Action");
                    
                    if ("CUSTOM".equals(eventName) && action != null) {
                        handleCallCenterEvent(event, action);
                    }
                }
            }
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private static void handleCallCenterEvent(ESLevent event, String action) {
        switch (action) {
            case "member-queue-start":
                String uuid = event.getHeader("CC-Member-UUID");
                String queue = event.getHeader("CC-Queue");
                System.out.println("New caller joined queue: " + queue + " (UUID: " + uuid + ")");
                break;
                
            case "bridge-agent-start":
                String agent = event.getHeader("CC-Agent");
                String memberUuid = event.getHeader("CC-Member-UUID");
                System.out.println("Agent " + agent + " connected to caller " + memberUuid);
                break;
                
            case "bridge-agent-end":
                String agentEnd = event.getHeader("CC-Agent");
                System.out.println("Call ended with agent: " + agentEnd);
                break;
                
            default:
                System.out.println("Event: " + action);
        }
    }
}
```

## 依赖管理

### Maven 项目配置

```xml
<!-- pom.xml -->
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>org.freeswitch</groupId>
    <artifactId>freeswitch-java-app</artifactId>
    <version>1.0.0</version>
    
    <dependencies>
        <!-- FreeSWITCH Java Library -->
        <dependency>
            <groupId>org.freeswitch</groupId>
            <artifactId>freeswitch</artifactId>
            <version>1.10.12</version>
            <scope>system</scope>
            <systemPath>/usr/local/freeswitch/lib/freeswitch.jar</systemPath>
        </dependency>
        
        <!-- MySQL Connector -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
        </dependency>
        
        <!-- Redis Client -->
        <dependency>
            <groupId>redis.clients</groupId>
            <artifactId>jedis</artifactId>
            <version>4.3.1</version>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

## API 命令

### 运行 Java 应用

```bash
# 在 fs_cli 中
freeswitch@internal> java org.freeswitch.example.SimpleCallHandler

# 在拨号计划中
<action application="java" data="org.freeswitch.example.SimpleCallHandler"/>
```

### 加载 Java 类

```bash
# 预加载类到 JVM
freeswitch@internal> java load org.freeswitch.example.SimpleCallHandler
```

### 重新加载 Java 模块

```bash
# 重新加载 mod_java（会重启 JVM）
freeswitch@internal> reload mod_java
```

## 性能优化

### 1. JVM 内存配置

```xml
<!-- 小型系统 -->
<param name="options" value="-Xmx256m -Xms128m"/>

<!-- 中型系统 -->
<param name="options" value="-Xmx512m -Xms256m"/>

<!-- 大型系统 -->
<param name="options" value="-Xmx1024m -Xms512m"/>
```

### 2. 垃圾回收优化

```xml
<!-- 使用 G1 垃圾回收器（推荐） -->
<param name="options" value="-Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200"/>

<!-- 使用 ZGC（Java 11+） -->
<param name="options" value="-Xmx512m -Xms256m -XX:+UseZGC"/>
```

### 3. 连接池配置

```java
// 使用 HikariCP 数据库连接池
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

public class DatabasePool {
    private static HikariDataSource dataSource;
    
    static {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://localhost:3306/callcenter");
        config.setUsername("root");
        config.setPassword("password");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(5);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        
        dataSource = new HikariDataSource(config);
    }
    
    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }
}
```

## 故障排查

### 查看 Java 日志

```bash
# 查看 FreeSWITCH 日志
tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i java

# 查看 JVM 错误日志
ls -l /usr/local/freeswitch/log/hs_err_*.log
```

### 常见问题

#### 1. ClassNotFoundException

```bash
# 检查类路径
fs_cli -x "java classpath"

# 添加额外的 jar 文件到类路径
<param name="classpath" value="/usr/local/freeswitch/scripts/java:/path/to/your/libs/*"/>
```

#### 2. OutOfMemoryError

```bash
# 增加堆内存
<param name="options" value="-Xmx1024m -Xms512m"/>

# 启用堆转储以便分析
<param name="options" value="-Xmx512m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp"/>
```

#### 3. 模块加载失败

```bash
# 检查 Java 是否正确安装
docker exec freeswitch java -version

# 检查 mod_java.so 是否存在
docker exec freeswitch ls -la /usr/local/freeswitch/mod/mod_java.so

# 手动加载模块
docker exec freeswitch fs_cli -x "load mod_java"
```

## 安全建议

1. **限制类路径** - 只包含必需的目录和库
2. **使用 SecurityManager** - 限制 Java 代码的权限
3. **输入验证** - 验证所有外部输入
4. **资源限制** - 设置合理的 JVM 内存限制
5. **日志记录** - 记录所有关键操作

## 部署清单

- [ ] 安装 Java JDK 和 JRE
- [ ] 配置 java.conf.xml
- [ ] 设置类路径
- [ ] 编译 Java 应用
- [ ] 测试 Java 模块加载
- [ ] 配置拨号计划
- [ ] 设置 JVM 内存参数
- [ ] 配置日志记录
- [ ] 性能测试
- [ ] 监控 JVM 性能

## 参考资源

- [FreeSWITCH Java API 文档](https://freeswitch.org/confluence/display/FREESWITCH/Java+ESL)
- [Oracle Java Documentation](https://docs.oracle.com/en/java/)
- [OpenJDK](https://openjdk.java.net/)
- [FreeSWITCH Event Socket Library](https://freeswitch.org/confluence/display/FREESWITCH/Event+Socket+Library)

## 更新日志

- 2025-10-10: 启用 mod_java 模块
- 添加 default-jdk 和 default-jre 依赖
- 创建配置指南和示例代码

---

**维护者：** ByteDesk Team  
**联系方式：** 270580156@qq.com  
**项目地址：** https://github.com/Bytedesk/bytedesk-freeswitch
