# FreeSWITCH Docker 安全配置指南

## 🔒 概述

本文档提供 FreeSWITCH Docker 镜像的安全配置最佳实践。FreeSWITCH 作为 VoIP 系统，是话费欺诈（Toll Fraud）的常见目标。遵循本指南可以大大降低安全风险。

## 🚨 紧急：必须修改的默认配置

### 1. ESL 管理密码

**风险等级**: 🔴 极高

ESL (Event Socket Library) 是 FreeSWITCH 的管理接口，可以完全控制系统。

```bash
# ❌ 危险：未设置密码
docker run -d bytedesk/freeswitch:latest

# ✅ 安全：设置强密码
docker run -d \
  -e FREESWITCH_ESL_PASSWORD='MyStr0ng#ESL!Pass2024' \
  bytedesk/freeswitch:latest
```

**密码要求**:
- 最少 16 个字符
- 包含大写字母、小写字母、数字和特殊字符
- 不要使用字典单词
- 不要包含系统信息（如主机名、用户名）

### 2. SIP 用户默认密码

**风险等级**: 🔴 极高

`default_password` 是所有 SIP 用户（1000-1019）的默认密码。

```bash
# ❌ 危险：使用默认密码 1234
docker run -d \
  -e FREESWITCH_ESL_PASSWORD='esl_pass' \
  bytedesk/freeswitch:latest

# ✅ 安全：设置强密码
docker run -d \
  -e FREESWITCH_ESL_PASSWORD='MyStr0ng#ESL!Pass2024' \
  -e FREESWITCH_DEFAULT_PASSWORD='MyStr0ng#SIP!Pass2024' \
  bytedesk/freeswitch:latest
```

**影响的用户**:
- 用户 1000-1019（标准用户）
- 用户 1001-brian
- 用户 1002-admin
- 其他在 `directory/default/*.xml` 中配置的用户

## 🛡️ 网络安全

### 1. 限制 ESL 端口访问

ESL 端口（8021）只应从可信网络访问：

```bash
# ✅ 仅绑定到 localhost
docker run -d \
  -p 127.0.0.1:8021:8021 \
  -e FREESWITCH_ESL_PASSWORD='strong_pass' \
  bytedesk/freeswitch:latest

# ✅ 使用防火墙规则
# 只允许特定 IP 访问
iptables -A INPUT -p tcp --dport 8021 -s 192.168.1.100 -j ACCEPT
iptables -A INPUT -p tcp --dport 8021 -j DROP
```

### 2. 配置防火墙

```bash
# 允许 SIP 信令端口
ufw allow 5060/tcp
ufw allow 5060/udp
ufw allow 5080/tcp
ufw allow 5080/udp

# 允许 RTP 媒体端口
ufw allow 16384:32768/udp

# 允许 WebRTC
ufw allow 7443/tcp

# 限制 ESL 端口（仅本地）
ufw allow from 127.0.0.1 to any port 8021

# 启用防火墙
ufw enable
```

### 3. 使用 Docker 网络隔离

```yaml
# docker-compose.yml
version: '3.8'

services:
  freeswitch:
    image: bytedesk/freeswitch:latest
    networks:
      - internal  # 内部网络
      - public    # 公网访问
    environment:
      - FREESWITCH_ESL_PASSWORD=${ESL_PASSWORD}
      - FREESWITCH_DEFAULT_PASSWORD=${SIP_PASSWORD}

  application:
    networks:
      - internal  # 只能通过内部网络访问 FreeSWITCH

networks:
  internal:
    internal: true  # 不允许外部访问
  public:
    driver: bridge
```

## 🔐 加密通信

### 1. 启用 SIP TLS

修改 `conf/sip_profiles/internal.xml`:

```xml
<param name="tls" value="true"/>
<param name="tls-only" value="false"/>  <!-- 改为 true 强制 TLS -->
<param name="tls-bind-params" value="transport=tls"/>
<param name="tls-sip-port" value="5061"/>
<param name="tls-cert-dir" value="/usr/local/freeswitch/certs"/>
<param name="tls-version" value="tlsv1.2"/>
```

### 2. 启用 SRTP

修改 `conf/vars.xml`:

```xml
<!-- 启用 SRTP 媒体加密 -->
<X-PRE-PROCESS cmd="set" data="rtp_secure_media=true"/>
<X-PRE-PROCESS cmd="set" data="rtp_secure_media_inbound=true"/>
<X-PRE-PROCESS cmd="set" data="rtp_secure_media_outbound=true"/>
```

### 3. 生成 SSL 证书

```bash
# 使用 Let's Encrypt
certbot certonly --standalone -d sip.yourdomain.com

# 复制证书到容器
docker cp /etc/letsencrypt/live/sip.yourdomain.com/fullchain.pem \
  freeswitch:/usr/local/freeswitch/certs/

docker cp /etc/letsencrypt/live/sip.yourdomain.com/privkey.pem \
  freeswitch:/usr/local/freeswitch/certs/
```

## 🔍 访问控制

### 1. 配置 ACL（访问控制列表）

编辑 `conf/autoload_configs/acl.conf.xml`:

```xml
<configuration name="acl.conf" description="Network Lists">
  <network-lists>
    <!-- 可信网络 -->
    <list name="trusted" default="deny">
      <node type="allow" cidr="192.168.1.0/24"/>
      <node type="allow" cidr="10.0.0.0/8"/>
    </list>
    
    <!-- 公网访问（限制注册） -->
    <list name="public" default="deny">
      <node type="allow" cidr="203.0.113.0/24"/>
    </list>
  </network-lists>
</configuration>
```

### 2. 在 SIP Profile 中应用 ACL

编辑 `conf/sip_profiles/external.xml`:

```xml
<param name="apply-inbound-acl" value="public"/>
<param name="auth-calls" value="true"/>
```

### 3. 配置 Fail2Ban

创建 `/etc/fail2ban/filter.d/freeswitch.conf`:

```ini
[Definition]
failregex = \[WARNING\] sofia_reg\.c:\d+ SIP auth failure \(REGISTER\) on sofia profile \'[^']+\' for \[.*\] from ip <HOST>
            \[WARNING\] sofia_reg\.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'[^']+\' for \[.*\] from ip <HOST>
ignoreregex =
```

创建 `/etc/fail2ban/jail.d/freeswitch.conf`:

```ini
[freeswitch]
enabled = true
port = 5060,5061,5080,5081
protocol = tcp,udp
filter = freeswitch
logpath = /var/log/freeswitch/freeswitch.log
maxretry = 5
bantime = 3600
findtime = 600
action = iptables-allports[name=freeswitch]
```

## 📊 监控和告警

### 1. 监控失败的认证尝试

```bash
# 实时监控失败的注册尝试
docker exec -it freeswitch tail -f /usr/local/freeswitch/log/freeswitch.log | grep "auth failure"

# 统计失败尝试
docker exec -it freeswitch grep "auth failure" /usr/local/freeswitch/log/freeswitch.log | wc -l
```

### 2. 监控异常呼叫

```bash
# 监控国际长途呼叫
docker exec -it freeswitch fs_cli -p ${ESL_PASSWORD} -x "show channels" | grep "^\+[0-9]"

# 监控长时间通话
docker exec -it freeswitch fs_cli -p ${ESL_PASSWORD} -x "show channels" | awk '{if ($10 > 3600) print}'
```

### 3. 设置告警

使用 Prometheus + Grafana 监控关键指标：

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'freeswitch'
    static_configs:
      - targets: ['freeswitch:9282']  # 需要安装 mod_prometheus
```

## 🚫 防止话费欺诈

### 1. 限制拨号权限

编辑 `conf/dialplan/default.xml`:

```xml
<!-- 阻止国际长途 -->
<extension name="block_international">
  <condition field="destination_number" expression="^(00|\+|011)">
    <action application="hangup" data="CALL_REJECTED"/>
  </condition>
</extension>

<!-- 限制特定前缀 -->
<extension name="block_premium">
  <condition field="destination_number" expression="^(900|976)">
    <action application="hangup" data="CALL_REJECTED"/>
  </condition>
</extension>
```

### 2. 设置呼叫频率限制

```xml
<extension name="rate_limit">
  <condition field="destination_number" expression="^(.*)$">
    <action application="limit" data="hash outbound ${caller_id_number} 5/60"/>
    <action application="bridge" data="sofia/gateway/my_gateway/$1"/>
  </condition>
</extension>
```

### 3. 设置账户余额限制

使用 mod_nibblebill 进行实时计费：

```xml
<!-- conf/autoload_configs/nibblebill.conf.xml -->
<configuration name="nibblebill.conf" description="Nibble Billing">
  <settings>
    <param name="db_dsn" value="mysql://user:pass@host/db"/>
    <param name="db_table" value="accounts"/>
    <param name="balance_field" value="balance"/>
  </settings>
</configuration>
```

## 🔄 定期维护

### 1. 更新检查清单

- [ ] 每月检查 FreeSWITCH 安全公告
- [ ] 每季度更新 Docker 镜像
- [ ] 每半年审查用户权限
- [ ] 每年更换密码

### 2. 日志审计

```bash
# 定期导出日志进行分析
docker exec freeswitch tar czf /tmp/logs-$(date +%Y%m%d).tar.gz /usr/local/freeswitch/log/
docker cp freeswitch:/tmp/logs-$(date +%Y%m%d).tar.gz ./

# 分析 CDR 记录
docker exec freeswitch sqlite3 /usr/local/freeswitch/db/cdr.db "SELECT * FROM cdr WHERE duration > 3600;"
```

### 3. 备份策略

```bash
#!/bin/bash
# backup-freeswitch.sh

BACKUP_DIR="/backups/freeswitch/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# 备份配置
docker exec freeswitch tar czf /tmp/conf-backup.tar.gz /usr/local/freeswitch/conf/
docker cp freeswitch:/tmp/conf-backup.tar.gz $BACKUP_DIR/

# 备份数据库
docker exec freeswitch tar czf /tmp/db-backup.tar.gz /usr/local/freeswitch/db/
docker cp freeswitch:/tmp/db-backup.tar.gz $BACKUP_DIR/

# 备份录音
docker exec freeswitch tar czf /tmp/recordings-backup.tar.gz /usr/local/freeswitch/recordings/
docker cp freeswitch:/tmp/recordings-backup.tar.gz $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
```

## 📋 生产环境部署检查清单

部署到生产环境前，请确认以下所有项目：

### 密码安全
- [ ] ✅ 已设置强 ESL 密码（`FREESWITCH_ESL_PASSWORD`）
- [ ] ✅ 已设置强 SIP 用户密码（`FREESWITCH_DEFAULT_PASSWORD`）
- [ ] ✅ 已为每个重要用户单独配置强密码
- [ ] ✅ 密码已安全存储（使用密码管理器或密钥管理服务）

### 网络安全
- [ ] ✅ ESL 端口仅限可信 IP 访问
- [ ] ✅ 已配置防火墙规则
- [ ] ✅ 已设置 Fail2Ban 或类似工具
- [ ] ✅ 已配置 ACL 访问控制
- [ ] ✅ 使用 Docker 网络隔离

### 加密通信
- [ ] ✅ 已启用 SIP TLS（端口 5061, 5081）
- [ ] ✅ 已配置有效的 SSL 证书
- [ ] ✅ 已启用 SRTP 媒体加密
- [ ] ✅ WebRTC 使用 WSS（端口 7443）

### 访问控制
- [ ] ✅ 已配置 ACL 限制 IP 范围
- [ ] ✅ 已禁用不需要的用户账户
- [ ] ✅ 已审查默认用户配置
- [ ] ✅ 已限制拨号权限

### 监控和告警
- [ ] ✅ 已设置日志监控
- [ ] ✅ 已配置失败登录告警
- [ ] ✅ 已设置异常呼叫告警
- [ ] ✅ 已配置话费监控

### 防护措施
- [ ] ✅ 已设置呼叫频率限制
- [ ] ✅ 已配置呼叫时长限制
- [ ] ✅ 已禁用国际长途（如不需要）
- [ ] ✅ 已启用实时计费

### 运维准备
- [ ] ✅ 已配置自动备份
- [ ] ✅ 已测试恢复流程
- [ ] ✅ 已配置日志轮转
- [ ] ✅ 已设置资源限制
- [ ] ✅ 已配置健康检查
- [ ] ✅ 已准备应急响应计划

## 🆘 应急响应

### 发现异常呼叫时

1. **立即操作**:
```bash
# 断开所有活动呼叫
docker exec freeswitch fs_cli -p ${ESL_PASSWORD} -x "hupall SYSTEM_SHUTDOWN"

# 禁用所有用户
docker exec freeswitch fs_cli -p ${ESL_PASSWORD} -x "reload mod_sofia"
```

2. **调查分析**:
```bash
# 查看最近的呼叫记录
docker exec freeswitch fs_cli -p ${ESL_PASSWORD} -x "show calls"

# 检查认证日志
docker exec freeswitch grep "REGISTER" /usr/local/freeswitch/log/freeswitch.log | tail -100
```

3. **修复措施**:
- 立即更改所有密码
- 更新防火墙规则
- 封禁可疑 IP
- 审查用户权限

### 发现未授权访问时

1. 立即更改 ESL 密码
2. 重新生成 SIP 用户密码
3. 审查配置文件是否被修改
4. 检查系统日志
5. 重新构建容器（如必要）

## 📚 参考资源

- [FreeSWITCH 官方安全文档](https://freeswitch.org/confluence/display/FREESWITCH/Security)
- [话费欺诈防护指南](https://freeswitch.org/confluence/display/FREESWITCH/Toll+Fraud)
- [SIP 安全最佳实践](https://tools.ietf.org/html/rfc3261#section-26)
- [OWASP VoIP 安全指南](https://owasp.org/www-community/vulnerabilities/VoIP_Security)

## 🔗 相关文档

- [README.md](./README.md) - 主要文档
- [QUICKSTART.md](./QUICKSTART.md) - 快速开始指南
- [BUILD_AND_DEPLOY.md](./BUILD_AND_DEPLOY.md) - 构建和部署指南

---

**最后更新**: 2025-10-09  
**维护者**: ByteDesk <270580156@qq.com>
