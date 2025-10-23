# 强烈推荐模块配置指南

## 📋 模块概述

本指南涵盖 4 个强烈推荐的呼叫中心模块：

| 模块 | 功能 | 优先级 | 适用场景 |
|------|------|--------|---------|
| **mod_avmd** | 答录机检测 | ⭐⭐⭐⭐⭐ | 外呼中心必备 |
| **mod_directory** | 企业通讯录 | ⭐⭐⭐⭐ | 中大型呼叫中心 |
| **mod_json_cdr** | JSON CDR | ⭐⭐⭐⭐ | 现代化系统 |
| **mod_voicemail_ivr** | 增强语音邮箱 | ⭐⭐⭐⭐ | 完整语音邮箱 |

---

## 1. mod_avmd（答录机检测）⭐⭐⭐⭐⭐

### 1.1 模块说明

**AVMD** = Advanced Voice Mail Detection（高级语音留言检测）

**功能**：自动检测对方是否为答录机/语音信箱，避免向答录机播放营销内容。

**适用场景**：
- 外呼营销中心
- 自动拨号系统
- 市场调研电话
- 客户回访系统

### 1.2 工作原理

AVMD 通过分析音频特征检测答录机：
- 检测特定的频率模式
- 分析语音的连续性
- 识别录音特征

检测时间：通常在 1-3 秒内完成

### 1.3 配置文件

创建 `/usr/local/freeswitch/conf/autoload_configs/avmd.conf.xml`：

```xml
<configuration name="avmd.conf" description="AVMD Configuration">
  <settings>
    <!-- 调试模式（生产环境设为 false） -->
    <param name="debug" value="0"/>
    
    <!-- 报告频率（毫秒），0 表示仅在检测完成时报告 -->
    <param name="report_status" value="0"/>
    
    <!-- 快速检测模式（减少检测时间，可能略降准确率） -->
    <param name="fast_math" value="0"/>
    
    <!-- 采样数量（越大越准确，但耗时更长） -->
    <param name="sample_n_frames" value="160"/>
    
    <!-- 简化计算（提高性能，略降准确率） -->
    <param name="simplify_calculation" value="0"/>
    
    <!-- 音频采样率 -->
    <param name="sample_rate" value="8000"/>
  </settings>
</configuration>
```

### 1.4 Dialplan 使用

#### 基础检测

```xml
<extension name="outbound_with_avmd">
  <condition field="destination_number" expression="^(\d+)$">
    <!-- 外呼 -->
    <action application="bridge" data="sofia/gateway/mygateway/$1"/>
    
    <!-- 应答后启动 AVMD 检测 -->
    <action application="avmd" data="start"/>
    
    <!-- 等待检测结果（最多 5 秒） -->
    <action application="sleep" data="5000"/>
    
    <!-- 停止检测 -->
    <action application="avmd" data="stop"/>
    
    <!-- 检查检测结果 -->
    <action application="log" data="INFO AVMD Result: ${avmd_detect}"/>
    
    <!-- 如果是答录机，挂断或执行其他操作 -->
    <action application="set" data="continue_on_fail=true"/>
    <action application="lua" data="handle_avmd_result.lua"/>
  </condition>
</extension>
```

#### 事件驱动检测

```xml
<extension name="outbound_event_avmd">
  <condition field="destination_number" expression="^(\d+)$">
    <!-- 设置 AVMD 事件回调 -->
    <action application="set" data="avmd_on_detect=lua:avmd_callback.lua"/>
    
    <!-- 外呼 -->
    <action application="bridge" data="sofia/gateway/mygateway/$1"/>
    
    <!-- 应答后自动启动 AVMD -->
    <action application="set" data="api_on_answer=avmd ${uuid} start"/>
    
    <!-- 播放欢迎语音（同时进行检测） -->
    <action application="playback" data="ivr/ivr-welcome.wav"/>
    
    <!-- AVMD 检测到答录机会触发回调，在回调中处理 -->
  </condition>
</extension>
```

### 1.5 Lua 脚本处理

#### avmd_callback.lua
```lua
-- AVMD 检测回调脚本
local avmd_result = session:getVariable("avmd_detect")

freeswitch.consoleLog("INFO", "AVMD Detection Result: " .. (avmd_result or "UNKNOWN") .. "\n")

if avmd_result == "TRUE" then
    -- 检测到答录机
    freeswitch.consoleLog("NOTICE", "Voice mail detected! Hanging up.\n")
    
    -- 记录到数据库
    local dbh = freeswitch.Dbh("mariadb://Server=mysql;Database=callcenter;Uid=root;Pwd=password;")
    local dest = session:getVariable("destination_number")
    local query = string.format([[
        INSERT INTO avmd_results (phone_number, result, timestamp)
        VALUES ('%s', 'VOICEMAIL', NOW())
    ]], dest)
    dbh:query(query)
    
    -- 播放留言后挂断
    session:execute("playback", "voicemail_message.wav")
    session:hangup()
else
    -- 真人接听
    freeswitch.consoleLog("INFO", "Human detected, proceeding with call.\n")
    
    -- 继续正常流程
    session:execute("playback", "ivr/ivr-welcome.wav")
end
```

### 1.6 API 命令

```bash
# 启动检测
uuid_avmd <uuid> start

# 停止检测
uuid_avmd <uuid> stop

# 查看状态
uuid_dump <uuid> | grep avmd
```

### 1.7 通道变量

| 变量名 | 说明 | 值 |
|--------|------|-----|
| `avmd_detect` | 检测结果 | TRUE（答录机）/ FALSE（真人）|
| `avmd_total_time` | 检测耗时（毫秒） | 数字 |
| `avmd_status` | 检测状态 | start / stop / detecting |

### 1.8 性能调优

#### 快速检测（降低延迟）
```xml
<param name="fast_math" value="1"/>
<param name="sample_n_frames" value="80"/>
```

#### 高精度检测（提高准确率）
```xml
<param name="fast_math" value="0"/>
<param name="sample_n_frames" value="320"/>
```

### 1.9 最佳实践

1. **并行检测**：边播放语音边检测，减少延迟
2. **超时设置**：设置 5 秒超时，避免长时间等待
3. **结果记录**：记录检测结果用于优化
4. **A/B 测试**：测试不同参数的准确率

---

## 2. mod_directory（企业通讯录）⭐⭐⭐⭐

### 2.1 模块说明

**功能**：提供电话通讯录功能，支持按姓名/分机号查找联系人。

**适用场景**：
- 企业内部通讯录
- 快速拨号
- 座席辅助工具
- IVR 查找功能

### .2 配置文件

创建 `/usr/local/freeswitch/conf/autoload_configs/directory.conf.xml`：

```xml
<configuration name="directory.conf" description="Directory Module">
  <settings>
    <!-- 搜索结果最大数量 -->
    <param name="max-result" value="5"/>
    
    <!-- 最小搜索长度 -->
    <param name="min-search-length" value="3"/>
    
    <!-- 数据源（directory 或 ldap） -->
    <param name="source" value="directory"/>
    
    <!-- 搜索超时（毫秒） -->
    <param name="timeout" value="5000"/>
  </settings>
  
  <profiles>
    <profile name="default">
      <!-- TTS 引擎（如果需要语音播报） -->
      <param name="tts-engine" value="flite"/>
      <param name="tts-voice" value="kal"/>
    </profile>
  </profiles>
</configuration>
```

### 2.3 Dialplan 使用

#### 通讯录查询

```xml
<extension name="company_directory">
  <condition field="destination_number" expression="^411$">
    <!-- 应答 -->
    <action application="answer"/>
    
    <!-- 播放欢迎语 -->
    <action application="playback" data="ivr/ivr-welcome_to_directory.wav"/>
    
    <!-- 启动通讯录查询 -->
    <action application="directory" data="default"/>
    
    <!-- 挂断 -->
    <action application="hangup"/>
  </condition>
</extension>
```

#### 自定义音频提示

```xml
<extension name="custom_directory">
  <condition field="destination_number" expression="^411$">
    <action application="answer"/>
    
    <!-- 设置提示音 -->
    <action application="set" data="directory_greeting=custom/dir_greeting.wav"/>
    <action application="set" data="directory_not_found=custom/dir_not_found.wav"/>
    
    <!-- 启动通讯录 -->
    <action application="directory" data="default ${domain_name} ${context}"/>
  </condition>
</extension>
```

### 2.4 用户目录配置

在用户配置中添加通讯录信息 `conf/directory/default/*.xml`：

```xml
<user id="1001">
  <params>
    <param name="password" value="1234"/>
  </params>
  <variables>
    <!-- 通讯录信息 -->
    <variable name="directory-visible" value="true"/>
    <variable name="directory-exten-visible" value="true"/>
    <variable name="dial-string" value="{presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(${dialed_user}@${dialed_domain})}"/>
    
    <!-- 用户信息 -->
    <variable name="effective_caller_id_name" value="张三"/>
    <variable name="effective_caller_id_number" value="1001"/>
    <variable name="user_context" value="default"/>
  </variables>
</user>
```

### 2.5 LDAP 集成（企业级）

如果使用 LDAP/Active Directory：

```xml
<configuration name="directory.conf">
  <settings>
    <param name="source" value="ldap"/>
    <param name="ldap-uri" value="ldap://ldap.company.com:389"/>
    <param name="ldap-base" value="ou=users,dc=company,dc=com"/>
    <param name="ldap-binddn" value="cn=admin,dc=company,dc=com"/>
    <param name="ldap-bindpass" value="password"/>
    <param name="ldap-filter" value="(objectClass=inetOrgPerson)"/>
  </settings>
</configuration>
```

### 2.6 最佳实践

1. **分组管理**：按部门分组通讯录
2. **权限控制**：设置 `directory-visible` 控制可见性
3. **缓存优化**：频繁查询的联系人可以缓存
4. **TTS 播报**：配置 TTS 引擎播报姓名

---

## 3. mod_json_cdr（JSON CDR）⭐⭐⭐⭐

### 3.1 模块说明

**功能**：以 JSON 格式记录和发送 CDR（Call Detail Record）。

**优势**：
- 结构化数据，易于解析
- 支持嵌套对象
- 现代 API 友好
- 易于集成到各种系统

### 3.2 配置文件

创建 `/usr/local/freeswitch/conf/autoload_configs/json_cdr.conf.xml`：

```xml
<configuration name="json_cdr.conf" description="JSON CDR Configuration">
  <settings>
    <!-- HTTP POST URL（发送 CDR 到 API） -->
    <param name="url" value="http://api.example.com/cdr"/>
    
    <!-- 认证方式 -->
    <!-- <param name="auth-scheme" value="basic"/> -->
    <!-- <param name="username" value="apiuser"/> -->
    <!-- <param name="password" value="apipass"/> -->
    
    <!-- 超时设置（秒） -->
    <param name="timeout" value="5"/>
    
    <!-- 重试次数 -->
    <param name="retries" value="3"/>
    
    <!-- 重试延迟（秒） -->
    <param name="delay" value="1"/>
    
    <!-- 记录 HTTP 响应 -->
    <param name="log-http-response" value="true"/>
    
    <!-- 记录到文件（备份） -->
    <param name="log-dir" value="/var/log/freeswitch/json_cdr"/>
    
    <!-- 是否同时记录到文件 -->
    <param name="log-b-leg" value="true"/>
    
    <!-- 错误日志目录 -->
    <param name="err-log-dir" value="/var/log/freeswitch/json_cdr_errors"/>
    
    <!-- 是否启用 -->
    <param name="enable-cacert-check" value="false"/>
    
    <!-- 自定义 HTTP 头 -->
    <param name="encode" value="true"/>
    <param name="encode-values" value="true"/>
    
    <!-- 包含的字段 -->
    <param name="cdr-filter" value=""/>
  </settings>
</configuration>
```

### 3.3 JSON CDR 格式示例

```json
{
  "core-uuid": "abc123-def456-ghi789",
  "channel_data": {
    "state": "CS_REPORTING",
    "direction": "inbound",
    "state_number": "11",
    "flags": "0=1;1=1;",
    "caps": "1=1;2=1;"
  },
  "variables": {
    "direction": "inbound",
    "uuid": "call-uuid-123",
    "session_id": "1",
    "sip_from_user": "1001",
    "sip_from_uri": "1001@domain.com",
    "sip_to_user": "1002",
    "sip_to_uri": "1002@domain.com",
    "caller_id_name": "张三",
    "caller_id_number": "1001",
    "destination_number": "1002",
    "context": "default",
    "start_stamp": "2025-10-10 10:00:00",
    "answer_stamp": "2025-10-10 10:00:05",
    "end_stamp": "2025-10-10 10:05:00",
    "duration": "300",
    "billsec": "295",
    "hangup_cause": "NORMAL_CLEARING",
    "accountcode": "",
    "read_codec": "PCMU",
    "write_codec": "PCMU"
  },
  "app_log": {
    "applications": [
      {
        "app_name": "answer",
        "app_data": "",
        "app_stamp": "2025-10-10 10:00:05"
      },
      {
        "app_name": "playback",
        "app_data": "ivr/ivr-welcome.wav",
        "app_stamp": "2025-10-10 10:00:06"
      }
    ]
  }
}
```

### 3.4 API 接收示例

#### Node.js Express
```javascript
const express = require('express');
const app = express();

app.use(express.json({ limit: '10mb' }));

app.post('/cdr', (req, res) => {
    const cdr = req.body;
    
    console.log('Received CDR:');
    console.log(`- UUID: ${cdr.variables.uuid}`);
    console.log(`- From: ${cdr.variables.caller_id_number}`);
    console.log(`- To: ${cdr.variables.destination_number}`);
    console.log(`- Duration: ${cdr.variables.duration}s`);
    console.log(`- Hangup: ${cdr.variables.hangup_cause}`);
    
    // 存储到数据库
    saveCDRToDatabase(cdr).then(() => {
        res.status(200).send('OK');
    }).catch(err => {
        console.error('Failed to save CDR:', err);
        res.status(500).send('Error');
    });
});

app.listen(3000, () => {
    console.log('CDR API listening on port 3000');
});
```

#### Python Flask
```python
from flask import Flask, request, jsonify
import json
from datetime import datetime

app = Flask(__name__)

@app.route('/cdr', methods=['POST'])
def receive_cdr():
    cdr = request.get_json()
    
    # 提取关键信息
    uuid = cdr['variables']['uuid']
    caller = cdr['variables']['caller_id_number']
    callee = cdr['variables']['destination_number']
    duration = cdr['variables'].get('duration', 0)
    hangup_cause = cdr['variables']['hangup_cause']
    
    print(f"CDR Received: {caller} -> {callee}, {duration}s, {hangup_cause}")
    
    # 存储到数据库
    try:
        save_to_db(cdr)
        return jsonify({'status': 'ok'}), 200
    except Exception as e:
        print(f"Error saving CDR: {e}")
        return jsonify({'status': 'error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
```

### 3.5 数据库存储

```sql
CREATE TABLE json_cdr_records (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(64) UNIQUE NOT NULL,
    caller_id_number VARCHAR(32),
    destination_number VARCHAR(32),
    start_stamp DATETIME,
    answer_stamp DATETIME,
    end_stamp DATETIME,
    duration INT,
    billsec INT,
    hangup_cause VARCHAR(64),
    direction VARCHAR(16),
    json_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_uuid (uuid),
    INDEX idx_caller (caller_id_number),
    INDEX idx_destination (destination_number),
    INDEX idx_start (start_stamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.6 最佳实践

1. **API 认证**：使用 Basic Auth 或 API Key 保护 CDR 接口
2. **文件备份**：同时记录到文件，防止 API 故障导致数据丢失
3. **异步处理**：API 快速响应，异步处理 CDR 数据
4. **监控告警**：监控 CDR 发送失败率

---

## 4. mod_voicemail_ivr（增强语音邮箱）⭐⭐⭐⭐

### 4.1 模块说明

**功能**：提供完整的语音邮箱 TUI（电话用户界面），允许用户通过电话管理留言。

**与 mod_voicemail 的区别**：
- mod_voicemail：基础留言功能（录音、播放）
- mod_voicemail_ivr：完整管理界面（删除、转发、保存等）

### 4.2 配置文件

使用现有的 `voicemail.conf.xml`，mod_voicemail_ivr 会自动读取。

### 4.3 Dialplan 使用

#### 检查语音邮箱

```xml
<extension name="check_voicemail">
  <condition field="destination_number" expression="^\*97$">
    <action application="answer"/>
    <action application="sleep" data="1000"/>
    
    <!-- 使用 IVR 方式检查语音邮箱 -->
    <action application="voicemail" data="check default ${domain_name}"/>
  </condition>
</extension>
```

#### 从指定分机检查

```xml
<extension name="check_voicemail_ext">
  <condition field="destination_number" expression="^\*98(\d+)$">
    <action application="answer"/>
    
    <!-- 检查指定分机的语音邮箱 -->
    <action application="voicemail" data="check default ${domain_name} $1"/>
  </condition>
</extension>
```

### 4.4 TUI 菜单功能

当用户拨打语音邮箱时，会听到以下菜单选项：

```
主菜单：
1 - 播放新留言
2 - 更改文件夹
3 - 高级选项
4 - 偏好设置
5 - 留言管理
* - 帮助
0 - 退出

播放留言时：
1 - 保存留言
2 - 删除留言
3 - 转发留言
4 - 重新播放
5 - 下一条留言
6 - 上一条留言
7 - 回拨来电号码
8 - 快进
9 - 回退
```

### 4.5 高级功能配置

#### 邮件通知增强

```xml
<param name="email-from" value="voicemail@company.com"/>
<param name="notify-email-subject" value="新语音留言 - ${voicemail_caller_id_name}"/>
<param name="notify-email-body" value="
您收到一条新的语音留言！

来电者：${voicemail_caller_id_name}
号码：${voicemail_caller_id_number}
时间：${voicemail_time}
时长：${voicemail_message_len} 秒

请拨打 *97 收听留言。
"/>
```

#### 转发留言配置

```xml
<!-- 允许转发留言 -->
<param name="forward-message-ext" value="1002,1003,1004"/>
<param name="forward-message-greeting" value="custom/forward_greeting.wav"/>
```

### 4.6 最佳实践

1. **密码保护**：为语音邮箱设置密码
2. **定期清理**：自动删除 30 天前的旧留言
3. **邮件通知**：配置 SMTP 发送邮件通知
4. **留言限制**：设置最大留言时长和数量

---

## 5. 部署和验证

### 5.1 重建 Docker 镜像

```bash
cd docker
docker build -t bytedesk/freeswitch:recommended .
```

### 5.2 启动容器

```bash
docker-compose down
docker-compose up -d
```

### 5.3 验证模块加载

```bash
# 验证所有模块
docker exec freeswitch fs_cli -x "module_exists mod_avmd"
docker exec freeswitch fs_cli -x "module_exists mod_directory"
docker exec freeswitch fs_cli -x "module_exists mod_json_cdr"
docker exec freeswitch fs_cli -x "module_exists mod_voicemail_ivr"

# 查看已加载模块
docker exec freeswitch fs_cli -x "show modules" | grep -E "avmd|directory|json_cdr|voicemail"
```

### 5.4 测试功能

#### 测试 AVMD
```bash
# 外呼测试号码，检查 AVMD 是否工作
# 查看日志
docker exec freeswitch fs_cli -x "console loglevel mod_avmd debug"
```

#### 测试 Directory
```bash
# 拨打 411 进入通讯录
# 输入姓名或分机号查找
```

#### 测试 JSON CDR
```bash
# 查看 JSON CDR 日志
docker exec freeswitch tail -f /var/log/freeswitch/json_cdr/json_cdr.log
```

#### 测试 Voicemail IVR
```bash
# 拨打 *97 检查语音邮箱
# 测试菜单选项
```

---

## 6. 监控与维护

### 6.1 性能监控

```bash
# 检查模块性能
fs_cli -x "show modules" | grep -E "avmd|directory|json_cdr|voicemail"

# 查看 CDR 统计
fs_cli -x "json_cdr status"
```

### 6.2 日志查看

```bash
# AVMD 日志
tail -f /usr/local/freeswitch/log/freeswitch.log | grep avmd

# JSON CDR 日志
tail -f /var/log/freeswitch/json_cdr/json_cdr.log

# 语音邮箱日志
tail -f /usr/local/freeswitch/log/freeswitch.log | grep voicemail
```

### 6.3 故障排查

#### AVMD 检测不准确
```bash
# 调整参数
<param name="sample_n_frames" value="320"/>  # 增加采样
<param name="fast_math" value="0"/>  # 关闭快速模式
```

#### JSON CDR 发送失败
```bash
# 检查网络
curl -X POST http://api.example.com/cdr -d '{}'

# 检查日志
tail -f /var/log/freeswitch/json_cdr_errors/*.json
```

---

## 7. 总结

### 7.1 模块价值

| 模块 | ROI | 实施难度 | 维护成本 |
|------|-----|---------|---------|
| mod_avmd | 极高 | 低 | 低 |
| mod_directory | 高 | 低 | 中 |
| mod_json_cdr | 高 | 低 | 低 |
| mod_voicemail_ivr | 中 | 中 | 中 |

### 7.2 部署检查清单

- [ ] 模块编译成功
- [ ] 模块加载成功
- [ ] AVMD 配置文件创建
- [ ] Directory 配置文件创建
- [ ] JSON CDR 配置文件创建
- [ ] JSON CDR API 端点部署
- [ ] Voicemail IVR 测试通过
- [ ] 通讯录用户信息配置
- [ ] AVMD 检测测试通过
- [ ] JSON CDR 接收测试通过
- [ ] 日志监控配置完成
- [ ] 告警机制建立

---

## 参考资源

- [mod_avmd 官方文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_avmd)
- [mod_directory 官方文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_directory)
- [mod_json_cdr 官方文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_json_cdr)
- [mod_voicemail 官方文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_voicemail)

---

**配置完成！祝你的呼叫中心系统运行顺利！** 🚀📞
