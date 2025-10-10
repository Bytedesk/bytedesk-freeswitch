# mod_spy 呼叫中心监听/质检模块配置指南

## 📋 模块概述

**mod_spy** 是 FreeSWITCH 呼叫中心的核心质检模块，提供实时监听、耳语、强插等功能，是呼叫中心质量管理的必备工具。

### 核心功能

| 功能 | 英文名 | 说明 | 主管能听 | 座席能听 | 客户能听 |
|------|--------|------|----------|----------|----------|
| **监听** | Eavesdrop | 监听双方对话，不能说话 | ✅ 双方 | ❌ | ❌ |
| **窃听** | Spy | 单向监听某个通道 | ✅ 单方 | ❌ | ❌ |
| **耳语** | Whisper | 只与座席对话，客户听不到 | ✅ 座席 | ✅ 主管 | ❌ |
| **强插** | Barge | 加入三方通话，都能听到 | ✅ 双方 | ✅ 主管 | ✅ 主管 |

---

## 1. 快速开始

### 1.1 模块验证

```bash
# 验证模块已加载
docker exec freeswitch fs_cli -x "module_exists mod_spy"

# 查看模块信息
docker exec freeswitch fs_cli -x "show modules" | grep spy
```

### 1.2 基本使用

```bash
# 主管拨打 88 + 座席分机号，即可监听该座席
# 例如：主管拨打 881001 监听 1001 座席
```

---

## 2. Dialplan 配置

### 2.1 监听功能（Eavesdrop）

创建或编辑 `/usr/local/freeswitch/conf/dialplan/default/99_spy.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<include>
  <!-- 监听功能：拨打 88 + 分机号 -->
  <extension name="eavesdrop">
    <condition field="destination_number" expression="^88(\d{4})$">
      <!-- 记录日志 -->
      <action application="log" data="INFO Supervisor ${caller_id_number} monitoring extension $1"/>
      
      <!-- 播放提示音 -->
      <action application="answer"/>
      <action application="sleep" data="500"/>
      <action application="playback" data="ivr/ivr-you_are_now_entering_monitor_mode.wav"/>
      
      <!-- 查找目标座席的活动通话 UUID -->
      <action application="set" data="eavesdrop_require_group=supervisor"/>
      <action application="set" data="eavesdrop_indicate_failed=tone_stream://%(500,0,320)"/>
      <action application="set" data="eavesdrop_indicate_new=tone_stream://%(500,0,620)"/>
      
      <!-- 开始监听（双向音频） -->
      <action application="eavesdrop" data="$1"/>
      
      <!-- 如果没有找到目标 -->
      <action application="playback" data="ivr/ivr-no_user_response.wav"/>
      <action application="hangup"/>
    </condition>
  </extension>
</include>
```

### 2.2 耳语功能（Whisper）

```xml
<!-- 耳语功能：拨打 89 + 分机号 -->
<extension name="whisper">
  <condition field="destination_number" expression="^89(\d{4})$">
    <!-- 记录日志 -->
    <action application="log" data="INFO Supervisor ${caller_id_number} whispering to extension $1"/>
    
    <!-- 播放提示音 -->
    <action application="answer"/>
    <action application="playback" data="ivr/ivr-you_are_now_entering_whisper_mode.wav"/>
    
    <!-- 开始耳语（主管说话，只有座席能听到，客户听不到） -->
    <action application="eavesdrop" data="$1 whisper"/>
    
    <!-- 失败处理 -->
    <action application="playback" data="ivr/ivr-no_user_response.wav"/>
    <action application="hangup"/>
  </condition>
</extension>
```

### 2.3 强插功能（Barge）

```xml
<!-- 强插功能：拨打 90 + 分机号 -->
<extension name="barge">
  <condition field="destination_number" expression="^90(\d{4})$">
    <!-- 记录日志 -->
    <action application="log" data="INFO Supervisor ${caller_id_number} barging into extension $1"/>
    
    <!-- 播放提示音 -->
    <action application="answer"/>
    <action application="playback" data="ivr/ivr-you_are_now_joining_call.wav"/>
    
    <!-- 强插通话（三方都能听到） -->
    <action application="eavesdrop" data="$1 barge"/>
    
    <!-- 失败处理 -->
    <action application="playback" data="ivr/ivr-no_user_response.wav"/>
    <action application="hangup"/>
  </condition>
</extension>
```

### 2.4 通过 UUID 监听

```xml
<!-- 通过 UUID 监听（更精确） -->
<extension name="eavesdrop_by_uuid">
  <condition field="destination_number" expression="^87(.+)$">
    <action application="answer"/>
    <action application="eavesdrop" data="$1"/>
  </condition>
</extension>
```

---

## 3. API 命令

### 3.1 基础命令

```bash
# 1. 监听指定分机（自动找到活动通话）
fs_cli -x "uuid_bridge <supervisor_uuid> eavesdrop:<extension>"

# 2. 监听指定 UUID
fs_cli -x "uuid_bridge <supervisor_uuid> eavesdrop:<target_uuid>"

# 3. 耳语模式
fs_cli -x "uuid_bridge <supervisor_uuid> eavesdrop:<target_uuid> whisper"

# 4. 强插模式
fs_cli -x "uuid_bridge <supervisor_uuid> eavesdrop:<target_uuid> barge"

# 5. 停止监听
fs_cli -x "uuid_kill <supervisor_uuid>"
```

### 3.2 查询命令

```bash
# 查看所有活动通话
fs_cli -x "show channels"

# 查看正在监听的通话
fs_cli -x "show channels like eavesdrop"

# 查看指定分机的通话
fs_cli -x "show channels like 1001"

# 获取分机的 UUID
fs_cli -x "uuid_dump <uuid>"
```

### 3.3 高级命令

```bash
# 设置监听参数
fs_cli -x "uuid_setvar <supervisor_uuid> eavesdrop_require_group supervisor"
fs_cli -x "uuid_setvar <supervisor_uuid> eavesdrop_indicate_failed tone_stream://%(500,0,320)"
fs_cli -x "uuid_setvar <supervisor_uuid> eavesdrop_indicate_new tone_stream://%(500,0,620)"

# 录制监听会话
fs_cli -x "uuid_record <supervisor_uuid> start /recordings/monitor_${uuid}.wav"
```

---

## 4. 与 mod_callcenter 集成

### 4.1 座席状态记录

在呼叫中心队列配置中，记录座席的 UUID：

```xml
<extension name="callcenter_agent">
  <condition field="destination_number" expression="^(queue\d+)$">
    <!-- 座席接听时记录 UUID -->
    <action application="set" data="api_on_answer=db insert/agent_uuid/${cc_agent} ${uuid}"/>
    
    <!-- 座席挂断时清除 UUID -->
    <action application="set" data="api_on_hangup=db delete/agent_uuid/${cc_agent}"/>
    
    <!-- 进入队列 -->
    <action application="callcenter" data="$1@default"/>
  </condition>
</extension>
```

### 4.2 主管监听座席

```xml
<extension name="supervisor_monitor">
  <condition field="destination_number" expression="^88(\d{4})$">
    <!-- 从数据库查询座席的活动 UUID -->
    <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
    
    <!-- 检查是否找到 UUID -->
    <action application="log" data="INFO Target UUID: ${target_uuid}"/>
    
    <action application="answer"/>
    
    <!-- 如果找到 UUID，开始监听 -->
    <action application="eavesdrop" data="${target_uuid}"/>
    
    <!-- 如果没找到 -->
    <action application="playback" data="ivr/ivr-no_user_response.wav"/>
  </condition>
</extension>
```

### 4.3 队列状态监控

```bash
# 查看队列中的座席
fs_cli -x "callcenter_config queue list agents support@default"

# 查看座席状态
fs_cli -x "callcenter_config agent list"

# 监听正在通话的座席
fs_cli -x "callcenter_config queue list members support@default" | grep "Talking"
```

---

## 5. Web 管理界面集成

### 5.1 Node.js + ESL 示例

```javascript
const esl = require('modesl');
const conn = new esl.Connection('localhost', 8021, 'ClueCon', () => {
    console.log('ESL Connected');
});

// 监听座席
function monitorAgent(supervisorUuid, agentExtension) {
    // 查询座席 UUID
    conn.api('db select/agent_uuid/' + agentExtension, (res) => {
        const agentUuid = res.getBody();
        
        if (agentUuid && agentUuid !== '-ERR') {
            // 开始监听
            conn.api(`uuid_bridge ${supervisorUuid} eavesdrop:${agentUuid}`, (res) => {
                console.log('Monitoring started:', res.getBody());
            });
        } else {
            console.log('Agent not in call');
        }
    });
}

// 耳语座席
function whisperAgent(supervisorUuid, agentExtension) {
    conn.api('db select/agent_uuid/' + agentExtension, (res) => {
        const agentUuid = res.getBody();
        
        if (agentUuid && agentUuid !== '-ERR') {
            conn.api(`uuid_bridge ${supervisorUuid} eavesdrop:${agentUuid} whisper`, (res) => {
                console.log('Whisper started:', res.getBody());
            });
        }
    });
}

// 强插通话
function bargeCall(supervisorUuid, agentExtension) {
    conn.api('db select/agent_uuid/' + agentExtension, (res) => {
        const agentUuid = res.getBody();
        
        if (agentUuid && agentUuid !== '-ERR') {
            conn.api(`uuid_bridge ${supervisorUuid} eavesdrop:${agentUuid} barge`, (res) => {
                console.log('Barge started:', res.getBody());
            });
        }
    });
}

// 停止监听
function stopMonitoring(supervisorUuid) {
    conn.api(`uuid_kill ${supervisorUuid}`, (res) => {
        console.log('Monitoring stopped');
    });
}

module.exports = { monitorAgent, whisperAgent, bargeCall, stopMonitoring };
```

### 5.2 Python + ESL 示例

```python
import ESL

class CallMonitor:
    def __init__(self, host='localhost', port=8021, password='ClueCon'):
        self.conn = ESL.ESLconnection(host, str(port), password)
        
        if self.conn.connected():
            print('ESL Connected')
        else:
            raise Exception('ESL Connection Failed')
    
    def get_agent_uuid(self, agent_extension):
        """获取座席的活动通话 UUID"""
        result = self.conn.api(f'db select/agent_uuid/{agent_extension}')
        uuid = result.getBody().strip()
        
        if uuid and uuid != '-ERR':
            return uuid
        return None
    
    def monitor_agent(self, supervisor_uuid, agent_extension):
        """监听座席"""
        agent_uuid = self.get_agent_uuid(agent_extension)
        
        if agent_uuid:
            cmd = f'uuid_bridge {supervisor_uuid} eavesdrop:{agent_uuid}'
            result = self.conn.api(cmd)
            return result.getBody()
        else:
            return 'Agent not in call'
    
    def whisper_agent(self, supervisor_uuid, agent_extension):
        """耳语座席"""
        agent_uuid = self.get_agent_uuid(agent_extension)
        
        if agent_uuid:
            cmd = f'uuid_bridge {supervisor_uuid} eavesdrop:{agent_uuid} whisper'
            result = self.conn.api(cmd)
            return result.getBody()
        else:
            return 'Agent not in call'
    
    def barge_call(self, supervisor_uuid, agent_extension):
        """强插通话"""
        agent_uuid = self.get_agent_uuid(agent_extension)
        
        if agent_uuid:
            cmd = f'uuid_bridge {supervisor_uuid} eavesdrop:{agent_uuid} barge'
            result = self.conn.api(cmd)
            return result.getBody()
        else:
            return 'Agent not in call'
    
    def stop_monitoring(self, supervisor_uuid):
        """停止监听"""
        result = self.conn.api(f'uuid_kill {supervisor_uuid}')
        return result.getBody()
    
    def get_active_agents(self):
        """获取所有活跃座席"""
        result = self.conn.api('db select/agent_uuid')
        # 解析结果
        return result.getBody()

# 使用示例
monitor = CallMonitor()
monitor.monitor_agent('supervisor-uuid-123', '1001')
```

### 5.3 REST API 示例

```javascript
// Express.js REST API
const express = require('express');
const app = express();
const esl = require('modesl');

const eslConn = new esl.Connection('localhost', 8021, 'ClueCon');

// 监听座席
app.post('/api/monitor', (req, res) => {
    const { supervisorUuid, agentExtension } = req.body;
    
    eslConn.api(`db select/agent_uuid/${agentExtension}`, (result) => {
        const agentUuid = result.getBody();
        
        if (agentUuid && agentUuid !== '-ERR') {
            eslConn.api(`uuid_bridge ${supervisorUuid} eavesdrop:${agentUuid}`, (bridgeRes) => {
                res.json({ 
                    success: true, 
                    message: 'Monitoring started',
                    agentUuid: agentUuid
                });
            });
        } else {
            res.json({ 
                success: false, 
                message: 'Agent not in call' 
            });
        }
    });
});

// 耳语座席
app.post('/api/whisper', (req, res) => {
    const { supervisorUuid, agentExtension } = req.body;
    
    eslConn.api(`db select/agent_uuid/${agentExtension}`, (result) => {
        const agentUuid = result.getBody();
        
        if (agentUuid && agentUuid !== '-ERR') {
            eslConn.api(`uuid_bridge ${supervisorUuid} eavesdrop:${agentUuid} whisper`, (bridgeRes) => {
                res.json({ success: true, message: 'Whisper started' });
            });
        } else {
            res.json({ success: false, message: 'Agent not in call' });
        }
    });
});

// 停止监听
app.post('/api/stop-monitor', (req, res) => {
    const { supervisorUuid } = req.body;
    
    eslConn.api(`uuid_kill ${supervisorUuid}`, (result) => {
        res.json({ success: true, message: 'Monitoring stopped' });
    });
});

app.listen(3000, () => {
    console.log('API Server listening on port 3000');
});
```

---

## 6. 安全与权限控制

### 6.1 ACL 配置

限制只有主管可以执行监听操作：

```xml
<!-- conf/autoload_configs/acl.conf.xml -->
<configuration name="acl.conf" description="Network Lists">
  <network-lists>
    <list name="supervisors" default="deny">
      <!-- 只允许主管 IP 地址 -->
      <node type="allow" cidr="192.168.1.100/32" description="Supervisor 1"/>
      <node type="allow" cidr="192.168.1.101/32" description="Supervisor 2"/>
      <node type="allow" cidr="10.0.0.0/24" description="Supervisor Network"/>
    </list>
  </network-lists>
</configuration>
```

### 6.2 用户权限验证

使用 Lua 脚本验证权限：

```lua
-- check_supervisor_permission.lua
local caller = session:getVariable("caller_id_number")

-- 从数据库查询是否是主管
local dbh = freeswitch.Dbh("mariadb://Server=mysql;Database=callcenter;Uid=root;Pwd=password;")
local query = string.format("SELECT role FROM users WHERE extension = '%s'", caller)

local is_supervisor = false

dbh:query(query, function(row)
    if row.role == 'supervisor' or row.role == 'admin' then
        is_supervisor = true
    end
end)

if not is_supervisor then
    freeswitch.consoleLog("WARNING", "Unauthorized monitoring attempt by: " .. caller .. "\n")
    session:execute("playback", "ivr/ivr-you_are_not_authorized.wav")
    session:hangup()
else
    freeswitch.consoleLog("INFO", "Supervisor " .. caller .. " authorized for monitoring\n")
end
```

在 Dialplan 中使用：

```xml
<extension name="eavesdrop_with_auth">
  <condition field="destination_number" expression="^88(\d{4})$">
    <!-- 验证权限 -->
    <action application="lua" data="check_supervisor_permission.lua"/>
    
    <!-- 如果通过验证，继续监听 -->
    <action application="answer"/>
    <action application="eavesdrop" data="$1"/>
  </condition>
</extension>
```

### 6.3 监听日志记录

记录所有监听操作到数据库：

```sql
-- 监听日志表
CREATE TABLE monitoring_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supervisor_ext VARCHAR(32) NOT NULL,
    supervisor_name VARCHAR(128),
    agent_ext VARCHAR(32) NOT NULL,
    agent_name VARCHAR(128),
    monitor_type ENUM('eavesdrop', 'whisper', 'barge') NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration INT,
    customer_number VARCHAR(32),
    call_uuid VARCHAR(64),
    
    INDEX idx_supervisor (supervisor_ext),
    INDEX idx_agent (agent_ext),
    INDEX idx_time (start_time),
    INDEX idx_type (monitor_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

使用 Lua 记录日志：

```lua
-- log_monitoring.lua
local supervisor = session:getVariable("caller_id_number")
local agent = argv[1]
local monitor_type = argv[2] or "eavesdrop"
local target_uuid = session:getVariable("target_uuid")

-- 记录开始时间
local dbh = freeswitch.Dbh("mariadb://Server=mysql;Database=callcenter;Uid=root;Pwd=password;")
local query = string.format([[
    INSERT INTO monitoring_logs (supervisor_ext, agent_ext, monitor_type, start_time, call_uuid)
    VALUES ('%s', '%s', '%s', NOW(), '%s')
]], supervisor, agent, monitor_type, target_uuid)

dbh:query(query)
local log_id = dbh:last_insert_id()

-- 存储 log_id 用于后续更新
session:setVariable("monitoring_log_id", log_id)

freeswitch.consoleLog("INFO", "Monitoring log created: " .. log_id .. "\n")
```

挂断时更新结束时间：

```lua
-- update_monitoring_log.lua
local log_id = session:getVariable("monitoring_log_id")

if log_id then
    local dbh = freeswitch.Dbh("mariadb://Server=mysql;Database=callcenter;Uid=root;Pwd=password;")
    local query = string.format([[
        UPDATE monitoring_logs 
        SET end_time = NOW(), 
            duration = TIMESTAMPDIFF(SECOND, start_time, NOW())
        WHERE id = %s
    ]], log_id)
    
    dbh:query(query)
    freeswitch.consoleLog("INFO", "Monitoring log updated: " .. log_id .. "\n")
end
```

---

## 7. 监控与统计

### 7.1 实时监控

```bash
# 查看当前所有监听会话
fs_cli -x "show channels like eavesdrop" | grep -v "^0 total"

# 查看指定主管的监听会话
fs_cli -x "show channels like <supervisor_uuid>"

# 监控系统负载
fs_cli -x "status"
```

### 7.2 统计报表

#### 主管监听频率统计

```sql
SELECT 
    supervisor_ext,
    supervisor_name,
    COUNT(*) as monitor_count,
    AVG(duration) as avg_duration_seconds,
    SUM(duration) as total_duration_seconds,
    DATE(start_time) as date
FROM monitoring_logs
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY supervisor_ext, supervisor_name, DATE(start_time)
ORDER BY date DESC, monitor_count DESC;
```

#### 座席被监听次数

```sql
SELECT 
    agent_ext,
    agent_name,
    monitor_type,
    COUNT(*) as monitored_count,
    AVG(duration) as avg_duration_seconds,
    DATE(start_time) as date
FROM monitoring_logs
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY agent_ext, agent_name, monitor_type, DATE(start_time)
ORDER BY date DESC, monitored_count DESC;
```

#### 监听类型分布

```sql
SELECT 
    monitor_type,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM monitoring_logs), 2) as percentage
FROM monitoring_logs
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY monitor_type;
```

### 7.3 性能指标

| 指标 | 说明 | 目标值 |
|------|------|--------|
| **监听成功率** | 成功监听次数 / 总尝试次数 | ≥ 95% |
| **平均监听时长** | 每次监听的平均时间 | 5-15 分钟 |
| **主管座席比** | 主管数量 / 座席数量 | 1:10 至 1:20 |
| **质检覆盖率** | 被监听通话数 / 总通话数 | 20-30% |
| **系统负载** | 并发监听对 CPU/内存影响 | CPU < 70% |

---

## 8. 故障排查

### 8.1 常见问题

#### 问题 1：无法监听到座席

**症状**：
```
[WARNING] mod_eavesdrop.c:123 Cannot find target channel
```

**排查步骤**：
```bash
# 1. 检查座席是否在通话中
fs_cli -x "show channels like 1001"

# 2. 检查数据库中的 UUID 记录
fs_cli -x "db select/agent_uuid/1001"

# 3. 检查模块是否加载
fs_cli -x "module_exists mod_spy"

# 4. 检查 Dialplan 配置
fs_cli -x "xml_locate dialplan context default extension 88"
```

**解决方案**：
- 确保座席正在通话中
- 确保 UUID 正确记录到数据库
- 重新加载 Dialplan：`reloadxml`

#### 问题 2：监听无声音

**症状**：监听成功，但听不到声音

**排查步骤**：
```bash
# 1. 检查通道状态
fs_cli -x "uuid_dump <supervisor_uuid>"

# 2. 检查媒体流
fs_cli -x "uuid_display <supervisor_uuid>"

# 3. 检查编解码器
fs_cli -x "show codec"
```

**解决方案**：
- 检查网络连接
- 确保编解码器兼容（PCMU/PCMA）
- 检查 RTP 端口是否开放（16384-32768）

#### 问题 3：耳语功能客户也能听到

**症状**：使用耳语功能，客户也能听到主管的声音

**原因**：使用了错误的命令或参数

**正确用法**：
```bash
# 正确：使用 whisper 参数
uuid_bridge <supervisor_uuid> eavesdrop:<agent_uuid> whisper

# 错误：使用 barge（会让所有人听到）
uuid_bridge <supervisor_uuid> eavesdrop:<agent_uuid> barge
```

#### 问题 4：权限验证失败

**症状**：主管无法监听

**排查步骤**：
```bash
# 1. 检查 ACL 配置
fs_cli -x "acl check 192.168.1.100"

# 2. 测试 Lua 权限脚本
fs_cli -x "lua check_supervisor_permission.lua"

# 3. 查看日志
tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i permission
```

### 8.2 调试技巧

#### 启用调试日志

```bash
# 启用 mod_spy 调试日志
fs_cli -x "console loglevel mod_spy debug"

# 查看详细日志
tail -f /usr/local/freeswitch/log/freeswitch.log | grep -i eavesdrop
```

#### 通话诊断

```bash
# 查看所有通道
fs_cli -x "show channels as xml" | grep -A 20 "<uuid>"

# 查看通道变量
fs_cli -x "uuid_dump <uuid>"

# 测试桥接
fs_cli -x "uuid_bridge <uuid1> <uuid2>"
```

---

## 9. 最佳实践

### 9.1 监听策略

#### 随机抽样监听
- 每周每个座席至少监听 2-5 通电话
- 随机选择不同时段
- 覆盖各种通话类型（咨询、投诉、销售等）

#### 目标监听
- 新员工：前两周每天监听 2-3 通
- 问题座席：增加监听频率
- 投诉处理：实时监听并准备介入

### 9.2 质检流程

```
1. 监听前准备
   ├── 登录质检系统
   ├── 查看座席状态
   └── 准备质检表单

2. 实时监听
   ├── 记录关键点
   ├── 评分（话术、态度、专业性）
   └── 决定是否介入（耳语/强插）

3. 监听后处理
   ├── 填写质检报告
   ├── 反馈给座席
   ├── 安排培训（如需）
   └── 更新知识库
```

### 9.3 培训建议

#### 主管培训内容
1. 监听功能使用方法
2. 何时使用耳语 vs 强插
3. 质检评分标准
4. 如何有效反馈

#### 座席培训内容
1. 告知可能被监听
2. 监听是为了帮助提升，非惩罚
3. 如何识别主管耳语（提示音）
4. 如何配合主管强插

### 9.4 合规建议

#### 法律要求
- 在 IVR 中明确告知通话可能被录音/监听
- 保护客户隐私信息
- 监听录音保存期限（通常 6-12 个月）
- 监听权限严格控制

#### 提示语示例
```xml
<action application="playback" data="ivr/ivr-this_call_may_be_monitored_or_recorded.wav"/>
```

中文录音内容：
> "您好，为保证服务质量，本次通话可能被录音或监听，感谢您的配合。"

---

## 10. 性能优化

### 10.1 系统资源

| 资源 | 单个监听会话 | 100 并发监听 |
|------|-------------|-------------|
| **带宽** | ~64 kbps | ~6.4 Mbps |
| **CPU** | < 1% | < 10% |
| **内存** | ~2-5 MB | ~200-500 MB |

### 10.2 优化建议

1. **使用低比特率编解码器**
   ```xml
   <action application="set" data="absolute_codec_string=PCMU"/>
   ```

2. **限制并发监听数量**
   ```xml
   <action application="limit" data="hash supervisor 10 !NORMAL_TEMPORARY_FAILURE"/>
   ```

3. **定期清理数据库日志**
   ```sql
   DELETE FROM monitoring_logs WHERE start_time < DATE_SUB(NOW(), INTERVAL 6 MONTH);
   ```

4. **使用 Redis 缓存座席 UUID**
   ```bash
   # 替代数据库查询
   fs_cli -x "hash insert/agent_uuid/1001 <uuid>"
   fs_cli -x "hash select/agent_uuid/1001"
   ```

---

## 11. 高级功能

### 11.1 录制监听会话

```xml
<extension name="eavesdrop_with_recording">
  <condition field="destination_number" expression="^88(\d{4})$">
    <!-- 设置录音文件名 -->
    <action application="set" data="monitoring_record_file=/recordings/monitor_${caller_id_number}_$1_${strftime(%Y%m%d_%H%M%S)}.wav"/>
    
    <!-- 开始录音 -->
    <action application="set" data="RECORD_STEREO=true"/>
    <action application="record_session" data="${monitoring_record_file}"/>
    
    <!-- 监听 -->
    <action application="answer"/>
    <action application="eavesdrop" data="$1"/>
  </condition>
</extension>
```

### 11.2 多主管同时监听

```bash
# 多个主管可以同时监听同一个座席
# 主管 1
uuid_bridge <supervisor1_uuid> eavesdrop:<agent_uuid>

# 主管 2
uuid_bridge <supervisor2_uuid> eavesdrop:<agent_uuid>
```

### 11.3 监听会议室

```bash
# 监听整个会议室
uuid_bridge <supervisor_uuid> eavesdrop:<conference_uuid>
```

### 11.4 静音监听（只听不说）

```xml
<!-- 使用单向音频 -->
<action application="set" data="bypass_media=false"/>
<action application="set" data="proxy_media=false"/>
<action application="answer"/>
<action application="uuid_media" data="${target_uuid} off"/>
<action application="eavesdrop" data="${target_uuid}"/>
```

---

## 12. 示例配置文件

### 12.1 完整 Dialplan 示例

创建 `conf/dialplan/default/99_spy_monitoring.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<include>
  <!-- ============================================
       呼叫中心监听/质检功能
       ============================================ -->
  
  <!-- 监听功能：88 + 分机号 -->
  <extension name="eavesdrop_monitor">
    <condition field="destination_number" expression="^88(\d{4})$">
      <!-- 权限验证（可选） -->
      <!-- <action application="lua" data="check_supervisor_permission.lua"/> -->
      
      <!-- 记录日志 -->
      <action application="log" data="INFO Supervisor ${caller_id_number} monitoring extension $1"/>
      
      <!-- 应答并播放提示音 -->
      <action application="answer"/>
      <action application="sleep" data="500"/>
      <action application="playback" data="tone_stream://%(200,100,500,600,700)"/>
      
      <!-- 查找目标座席的 UUID -->
      <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
      
      <!-- 设置监听参数 -->
      <action application="set" data="eavesdrop_require_group=supervisor"/>
      <action application="set" data="eavesdrop_indicate_failed=tone_stream://%(500,0,320)"/>
      <action application="set" data="eavesdrop_indicate_new=tone_stream://%(500,0,620)"/>
      
      <!-- 录制监听会话（可选） -->
      <action application="set" data="RECORD_STEREO=true"/>
      <action application="record_session" data="/recordings/monitor_${caller_id_number}_$1_${strftime(%Y%m%d_%H%M%S)}.wav"/>
      
      <!-- 记录监听日志（可选） -->
      <!-- <action application="lua" data="log_monitoring.lua $1 eavesdrop"/> -->
      
      <!-- 开始监听 -->
      <action application="eavesdrop" data="$1"/>
      
      <!-- 失败提示 -->
      <action application="playback" data="ivr/ivr-no_user_response.wav"/>
      <action application="hangup"/>
    </condition>
  </extension>
  
  <!-- 耳语功能：89 + 分机号 -->
  <extension name="whisper_coaching">
    <condition field="destination_number" expression="^89(\d{4})$">
      <action application="log" data="INFO Supervisor ${caller_id_number} whispering to extension $1"/>
      <action application="answer"/>
      <action application="playback" data="tone_stream://%(200,100,800,900)"/>
      
      <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
      <action application="record_session" data="/recordings/whisper_${caller_id_number}_$1_${strftime(%Y%m%d_%H%M%S)}.wav"/>
      
      <!-- 耳语模式 -->
      <action application="eavesdrop" data="$1 whisper"/>
      
      <action application="playback" data="ivr/ivr-no_user_response.wav"/>
    </condition>
  </extension>
  
  <!-- 强插功能：90 + 分机号 -->
  <extension name="barge_intervention">
    <condition field="destination_number" expression="^90(\d{4})$">
      <action application="log" data="INFO Supervisor ${caller_id_number} barging into extension $1"/>
      <action application="answer"/>
      <action application="playback" data="tone_stream://%(200,100,1000,1100,1200)"/>
      
      <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
      <action application="record_session" data="/recordings/barge_${caller_id_number}_$1_${strftime(%Y%m%d_%H%M%S)}.wav"/>
      
      <!-- 强插模式 -->
      <action application="eavesdrop" data="$1 barge"/>
      
      <action application="playback" data="ivr/ivr-no_user_response.wav"/>
    </condition>
  </extension>
  
  <!-- 通过 UUID 监听（用于 Web 界面） -->
  <extension name="eavesdrop_by_uuid">
    <condition field="destination_number" expression="^87(.{36})$">
      <action application="answer"/>
      <action application="eavesdrop" data="$1"/>
    </condition>
  </extension>
</include>
```

### 12.2 座席 UUID 记录示例

编辑 `conf/dialplan/default/01_callcenter.xml`：

```xml
<extension name="callcenter_support">
  <condition field="destination_number" expression="^(queue_.+)$">
    <!-- 座席接听时记录 UUID -->
    <action application="set" data="api_on_answer=db insert/agent_uuid/${cc_agent} ${uuid}"/>
    
    <!-- 座席挂断时清除 UUID -->
    <action application="set" data="api_on_hangup=db delete/agent_uuid/${cc_agent}"/>
    
    <!-- 记录通话信息 -->
    <action application="set" data="api_on_answer=hash insert/call_info/${uuid}/agent ${cc_agent}"/>
    <action application="set" data="api_on_answer=hash insert/call_info/${uuid}/queue $1"/>
    <action application="set" data="api_on_answer=hash insert/call_info/${uuid}/customer ${caller_id_number}"/>
    
    <!-- 进入呼叫中心队列 -->
    <action application="callcenter" data="$1@default"/>
  </condition>
</extension>
```

---

## 13. 总结

### 13.1 关键要点

✅ **mod_spy 是呼叫中心必备模块**
- 监听（Eavesdrop）：主管监听双方对话
- 耳语（Whisper）：主管指导座席，客户听不到
- 强插（Barge）：主管加入三方通话

✅ **配置简单，功能强大**
- Dialplan 配置：88/89/90 + 分机号
- API 命令：uuid_bridge + eavesdrop
- Web 集成：通过 ESL 接口

✅ **安全与合规**
- ACL 权限控制
- 监听日志记录
- 客户隐私保护

### 13.2 实施检查清单

- [ ] 模块已启用并加载
- [ ] Dialplan 配置完成
- [ ] 座席 UUID 记录机制完成
- [ ] 权限验证配置（可选）
- [ ] 监听日志记录（可选）
- [ ] Web 界面集成（可选）
- [ ] 主管培训完成
- [ ] 座席告知监听政策
- [ ] IVR 客户提示完成
- [ ] 测试各种监听模式
- [ ] 文档和流程制定
- [ ] 监控和统计报表

### 13.3 下一步行动

1. **测试验证**
   ```bash
   # 重建 Docker 镜像
   cd docker && docker build -t bytedesk/freeswitch:spy .
   
   # 启动容器
   docker-compose up -d
   
   # 验证模块
   docker exec freeswitch fs_cli -x "module_exists mod_spy"
   ```

2. **配置 Dialplan**
   - 复制示例配置到 `conf/dialplan/default/`
   - 根据实际需求调整
   - 重载配置：`reloadxml`

3. **培训团队**
   - 培训主管使用监听功能
   - 告知座席监听政策
   - 制定质检标准和流程

---

## 参考资源

### 官方文档
- [mod_spy 官方文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_spy)
- [mod_dptools: eavesdrop](https://freeswitch.org/confluence/display/FREESWITCH/mod_dptools%3A+eavesdrop)
- [uuid_bridge API](https://freeswitch.org/confluence/display/FREESWITCH/uuid_bridge)

### 社区资源
- FreeSWITCH 邮件列表
- FreeSWITCH 中文社区
- GitHub Issues

---

**祝你的呼叫中心系统质检功能配置成功！** 🎯📞
