# 模块分析：mod_snapshot、mod_spy、mod_translate

## 📊 执行摘要

| 模块 | 推荐状态 | 优先级 | 适用场景 |
|------|---------|--------|---------|
| **mod_snapshot** | ⚠️ 可选 | 低 | 特定调试场景 |
| **mod_spy** | ✅ **推荐** | **高** | **呼叫中心监控必备** |
| **mod_translate** | ❌ 不推荐 | 低 | 已过时 |

---

## 1. mod_snapshot（录音快照模块）

### 1.1 模块说明

**功能**：在通话过程中创建音频快照（截取片段），用于调试和测试。

**官方定位**：调试工具，非生产环境必需模块

### 1.2 主要功能

```xml
<!-- 录制 5 秒音频快照 -->
<action application="snapshot" data="/tmp/audio_snapshot.wav 5"/>
```

- 捕获通话的音频片段
- 用于调试音频质量问题
- 测试编解码器性能
- 分析网络抖动和丢包

### 1.3 使用场景

#### ✅ 适合场景
- **开发/测试环境**：调试音频问题
- **故障排查**：分析音质问题
- **编解码器测试**：对比不同编解码器效果
- **网络诊断**：检测网络质量问题

#### ❌ 不适合场景
- **生产环境**：不推荐常规使用
- **完整录音**：应使用 `mod_dptools` 的 `record` 应用
- **合规录音**：不满足呼叫中心录音要求

### 1.4 与其他录音方案对比

| 功能 | mod_snapshot | record 应用 | mod_local_stream |
|------|-------------|------------|-----------------|
| **完整录音** | ❌ 仅片段 | ✅ 完整 | ✅ 流式 |
| **生产环境** | ❌ 不推荐 | ✅ 推荐 | ✅ 推荐 |
| **调试用途** | ✅ 适合 | ⚠️ 过度 | ❌ 不适合 |
| **性能开销** | 低 | 中 | 低 |
| **合规性** | ❌ 不满足 | ✅ 满足 | ✅ 满足 |

### 1.5 呼叫中心录音最佳实践

#### 推荐方案：使用 record 应用
```xml
<extension name="call_recording">
  <condition field="destination_number" expression="^(\d+)$">
    <!-- 完整双向录音 -->
    <action application="set" data="RECORD_STEREO=true"/>
    <action application="record_session" data="/recordings/${uuid}.wav"/>
    
    <!-- 或使用 API 控制录音 -->
    <action application="set" data="api_on_answer=uuid_record ${uuid} start /recordings/${uuid}.wav"/>
  </condition>
</extension>
```

### 1.6 结论

**🟡 mod_snapshot 建议：可选，低优先级**

- **不启用的理由**：
  - 呼叫中心需要完整录音，非片段快照
  - 生产环境有更好的替代方案（record_session）
  - 增加系统复杂度，收益有限
  
- **启用的理由**：
  - 如果需要音频调试工具
  - 如果有特殊的音频分析需求
  - 系统资源充足，不在意额外开销

**建议：呼叫中心场景下不启用，使用 record_session 即可。**

---

## 2. mod_spy（监听/窃听模块）⭐⭐⭐⭐⭐

### 2.1 模块说明

**功能**：实时监听、窃听、耳语（whisper）和插入通话。

**官方定位**：呼叫中心质检和培训的核心模块

### 2.2 主要功能

#### 功能 1：监听（Monitor）
```bash
# 监听座席通话（仅听双方对话，不能说话）
uuid_bridge <manager_uuid> eavesdrop:<target_uuid>
```

#### 功能 2：窃听（Spy）
```bash
# 单向监听某个通道
uuid_bridge <manager_uuid> spy:<target_uuid>
```

#### 功能 3：耳语（Whisper）
```bash
# 只与座席对话，客户听不到
uuid_bridge <manager_uuid> whisper:<target_uuid>
```

#### 功能 4：三方通话（Barge）
```bash
# 加入通话，双方都能听到
uuid_bridge <manager_uuid> barge:<target_uuid>
```

### 2.3 呼叫中心应用场景

#### ✅ 关键业务场景

1. **质量监控（Quality Monitoring）**
   - 主管实时监听座席通话
   - 评估服务质量
   - 发现问题及时介入

2. **座席培训（Agent Training）**
   - 新员工培训时，主管监听并耳语指导
   - 实战培训，提高学习效率
   - 不影响客户体验

3. **紧急支援（Emergency Support）**
   - 座席遇到难题时，主管耳语提示
   - 避免转接影响客户体验
   - 提高首次解决率

4. **投诉处理（Complaint Handling）**
   - 客户投诉时，主管介入（Barge）
   - 及时化解矛盾
   - 降低客户流失率

5. **合规审计（Compliance Audit）**
   - 随机抽查座席话术
   - 确保合规性
   - 收集质检数据

### 2.4 配置示例

#### 2.4.1 Dialplan 配置

```xml
<!-- 主管监听座席 -->
<extension name="eavesdrop">
  <condition field="destination_number" expression="^88(\d{4})$">
    <!-- 查找座席的活动通话 UUID -->
    <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
    
    <!-- 播放提示音 -->
    <action application="playback" data="ivr/ivr-you_are_now_entering_monitor_mode.wav"/>
    
    <!-- 开始监听 -->
    <action application="eavesdrop" data="${target_uuid}"/>
  </condition>
</extension>

<!-- 主管耳语 -->
<extension name="whisper">
  <condition field="destination_number" expression="^89(\d{4})$">
    <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
    <action application="playback" data="ivr/ivr-you_are_now_entering_whisper_mode.wav"/>
    <action application="eavesdrop" data="${target_uuid} whisper"/>
  </condition>
</extension>

<!-- 主管插入通话 -->
<extension name="barge">
  <condition field="destination_number" expression="^90(\d{4})$">
    <action application="set" data="target_uuid=${db(select/agent_uuid/$1)}"/>
    <action application="playback" data="ivr/ivr-you_are_now_joining_call.wav"/>
    <action application="eavesdrop" data="${target_uuid} barge"/>
  </condition>
</extension>
```

#### 2.4.2 API 命令

```bash
# 1. 监听座席（只听，不说）
fs_cli -x "uuid_bridge <manager_uuid> eavesdrop:<agent_uuid>"

# 2. 耳语模式（只与座席对话）
fs_cli -x "uuid_bridge <manager_uuid> eavesdrop:<agent_uuid> whisper"

# 3. 强插模式（加入三方通话）
fs_cli -x "uuid_bridge <manager_uuid> eavesdrop:<agent_uuid> barge"

# 4. 查看正在监听的通话
fs_cli -x "show channels like eavesdrop"

# 5. 停止监听
fs_cli -x "uuid_kill <manager_uuid>"
```

### 2.5 与 mod_callcenter 集成

#### 2.5.1 座席状态监控

```xml
<!-- 在呼叫中心队列中记录座席 UUID -->
<extension name="callcenter_answer">
  <condition field="destination_number" expression="^queue">
    <!-- 记录座席 UUID 到数据库 -->
    <action application="set" data="api_on_answer=db insert/agent_uuid/${cc_agent} ${uuid}"/>
    
    <!-- 进入队列 -->
    <action application="callcenter" data="support@default"/>
  </condition>
</extension>
```

#### 2.5.2 Web 管理界面集成

```javascript
// 通过 ESL 实现 Web 监听控制
function startMonitoring(supervisorUuid, agentExtension) {
    const agentUuid = db.query('SELECT uuid FROM agent_uuid WHERE agent = ?', [agentExtension]);
    
    // 发送监听命令
    esl.api('uuid_bridge', `${supervisorUuid} eavesdrop:${agentUuid}`);
}

function startWhisper(supervisorUuid, agentExtension) {
    const agentUuid = db.query('SELECT uuid FROM agent_uuid WHERE agent = ?', [agentExtension]);
    esl.api('uuid_bridge', `${supervisorUuid} eavesdrop:${agentUuid} whisper`);
}
```

### 2.6 安全与权限控制

#### 2.6.1 ACL 配置

```xml
<!-- conf/autoload_configs/acl.conf.xml -->
<configuration name="acl.conf" description="Network Lists">
  <network-lists>
    <list name="supervisors" default="deny">
      <!-- 只允许主管 IP 执行监听操作 -->
      <node type="allow" cidr="192.168.1.100/32"/>
      <node type="allow" cidr="192.168.1.101/32"/>
    </list>
  </network-lists>
</configuration>
```

#### 2.6.2 权限验证

```xml
<extension name="eavesdrop_with_auth">
  <condition field="destination_number" expression="^88(\d{4})$">
    <!-- 验证权限 -->
    <action application="lua" data="check_supervisor_permission.lua"/>
    
    <!-- 记录监听日志 -->
    <action application="log" data="NOTICE Supervisor ${caller_id_number} monitoring agent $1"/>
    
    <action application="eavesdrop" data="${target_uuid}"/>
  </condition>
</extension>
```

### 2.7 监控指标

#### 2.7.1 需要记录的数据

```sql
CREATE TABLE monitoring_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supervisor_ext VARCHAR(32),
    agent_ext VARCHAR(32),
    monitor_type ENUM('eavesdrop', 'whisper', 'barge'),
    start_time DATETIME,
    end_time DATETIME,
    duration INT,
    customer_number VARCHAR(32),
    INDEX idx_supervisor (supervisor_ext),
    INDEX idx_agent (agent_ext),
    INDEX idx_time (start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 2.7.2 统计报表

```sql
-- 主管监听频率统计
SELECT 
    supervisor_ext,
    COUNT(*) as monitor_count,
    AVG(duration) as avg_duration,
    DATE(start_time) as date
FROM monitoring_logs
GROUP BY supervisor_ext, DATE(start_time);

-- 座席被监听次数
SELECT 
    agent_ext,
    COUNT(*) as monitored_count,
    monitor_type,
    DATE(start_time) as date
FROM monitoring_logs
GROUP BY agent_ext, monitor_type, DATE(start_time);
```

### 2.8 性能考虑

| 指标 | 数值 | 说明 |
|------|------|------|
| **额外带宽** | +64kbps | 每个监听会话 |
| **CPU 开销** | 低 | 主要是媒体复制 |
| **内存开销** | 低 | 约 2-5MB/会话 |
| **最大并发监听** | 1000+ | 取决于服务器性能 |

### 2.9 结论

**🟢 mod_spy 强烈推荐：必需模块，高优先级**

#### ✅ 启用理由

1. **呼叫中心核心功能**：
   - 质量监控是呼叫中心基础功能
   - 座席培训必备工具
   - 提高服务质量的关键手段

2. **业务价值高**：
   - 提升客户满意度
   - 降低投诉率
   - 加快新员工培训速度
   - 提高首次解决率

3. **行业标准**：
   - 几乎所有商业呼叫中心系统都有此功能
   - 客户期望的标准功能
   - 合规性要求（某些行业）

4. **技术成熟**：
   - 稳定可靠
   - 性能开销低
   - 配置简单

#### 📊 实际应用数据

根据呼叫中心最佳实践：
- 主管座席比例：1:10 至 1:20
- 每个座席每周被监听 2-5 次
- 监听时长：5-15 分钟
- 质检覆盖率：20-30% 的通话

**建议：呼叫中心场景必须启用！**

---

## 3. mod_translate（号码转换模块）

### 3.1 模块说明

**功能**：在拨号计划中进行号码转换和重写。

**官方定位**：已过时的模块，已被更好的方案替代

### 3.2 主要功能

```xml
<!-- 使用 mod_translate 转换号码 -->
<action application="translate" data="from_pattern to_pattern"/>
```

- 号码格式转换
- 添加/删除前缀
- 号码正则替换

### 3.3 为什么不推荐

#### ❌ 已过时的理由

1. **功能已被替代**：
   - `mod_dptools` 的 `regex` 和 `transfer` 完全覆盖其功能
   - 更强大的 Dialplan 条件匹配
   - Lua/Python 脚本提供更灵活的号码处理

2. **维护状态**：
   - 官方文档标注为 "legacy"（遗留模块）
   - 社区活跃度低
   - 新功能开发停滞

3. **替代方案更好**：
   ```xml
   <!-- 使用 regex 替代 mod_translate -->
   <action application="set" data="effective_caller_id_number=${regex(${caller_id_number}|^0(\d+)$|86\1)}"/>
   
   <!-- 或使用 inline 直接在 condition 中处理 -->
   <condition field="destination_number" expression="^0(\d+)$">
     <action application="bridge" data="sofia/gateway/mygateway/86$1"/>
   </condition>
   ```

### 3.4 现代号码转换方案

#### 方案 1：Dialplan 条件匹配（推荐）

```xml
<extension name="number_translation">
  <!-- 去除前导 0，添加国家代码 86 -->
  <condition field="destination_number" expression="^0(\d{10})$">
    <action application="set" data="effective_destination_number=86$1"/>
    <action application="bridge" data="sofia/gateway/intl/${effective_destination_number}"/>
  </condition>
  
  <!-- 7 位号码添加区号 -->
  <condition field="destination_number" expression="^(\d{7})$">
    <action application="set" data="effective_destination_number=755$1"/>
    <action application="bridge" data="sofia/gateway/local/${effective_destination_number}"/>
  </condition>
</extension>
```

#### 方案 2：使用 mod_easyroute（已启用）

```xml
<!-- 使用 mod_easyroute 从数据库查询号码转换规则 -->
<extension name="easyroute_translation">
  <condition field="destination_number" expression="^(\d+)$">
    <action application="easyroute" data="${destination_number}"/>
    
    <!-- easy_translated 变量包含转换后的号码 -->
    <action application="bridge" data="${easy_techprefix}/${easy_gateway}/${easy_translated}"/>
  </condition>
</extension>
```

#### 方案 3：Lua 脚本（灵活性最高）

```lua
-- number_translate.lua
local destination = session:getVariable("destination_number")

-- 规则 1：去除前导 0
local translated = destination:gsub("^0(%d+)$", "86%1")

-- 规则 2：7 位号码添加区号
if #translated == 7 then
    translated = "755" .. translated
end

-- 规则 3：从数据库查询自定义规则
local dbh = freeswitch.Dbh("mariadb://Server=mysql;Database=freeswitch;Uid=root;Pwd=password;")
local query = string.format("SELECT translated_number FROM number_translations WHERE original_number = '%s'", destination)
dbh:query(query, function(row)
    translated = row.translated_number
end)

-- 设置转换后的号码
session:setVariable("translated_number", translated)

-- 拨号
session:execute("bridge", "sofia/gateway/mygateway/" .. translated)
```

#### 方案 4：mod_cidlookup（已启用）

```xml
<!-- 使用 mod_cidlookup 进行号码查询和转换 -->
<configuration name="cidlookup.conf" description="CID Lookup">
  <settings>
    <param name="url" value="http://api.example.com/number_lookup?number=${caller_id_number}"/>
    <param name="cache" value="true"/>
  </settings>
</configuration>
```

### 3.5 功能对比

| 功能 | mod_translate | Dialplan Regex | Lua 脚本 | mod_easyroute |
|------|--------------|----------------|----------|---------------|
| **号码转换** | ✅ 基础 | ✅ 强大 | ✅ 最强 | ✅ 数据库驱动 |
| **灵活性** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **性能** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **维护性** | ⭐ 已过时 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **学习曲线** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |

### 3.6 实际应用示例

#### 场景：中国号码标准化

```xml
<extension name="china_number_normalization">
  <!-- 1. 手机号：13x/14x/15x/16x/17x/18x/19x -->
  <condition field="destination_number" expression="^(1[3-9]\d{9})$">
    <action application="set" data="normalized_number=+86$1"/>
    <action application="bridge" data="sofia/gateway/mobile/${normalized_number}"/>
  </condition>
  
  <!-- 2. 固话（带区号）：010-12345678 -->
  <condition field="destination_number" expression="^(0\d{2,3})-?(\d{7,8})$">
    <action application="set" data="normalized_number=+86$1$2"/>
    <action application="bridge" data="sofia/gateway/landline/${normalized_number}"/>
  </condition>
  
  <!-- 3. 国际号码：00xx... 转换为 +xx... -->
  <condition field="destination_number" expression="^00(\d+)$">
    <action application="set" data="normalized_number=+$1"/>
    <action application="bridge" data="sofia/gateway/international/${normalized_number}"/>
  </condition>
</extension>
```

### 3.7 结论

**🔴 mod_translate 不推荐：已过时，低优先级**

#### ❌ 不启用理由

1. **功能已被替代**：
   - Dialplan 原生支持更强大的正则表达式
   - Lua/Python 脚本提供更灵活的处理
   - mod_easyroute 提供数据库驱动的转换

2. **维护问题**：
   - 官方标记为遗留模块
   - 社区支持有限
   - 可能在未来版本中移除

3. **无额外价值**：
   - 不提供任何现代方案无法实现的功能
   - 增加系统复杂度
   - 增加学习成本

4. **性能无优势**：
   - Dialplan 内联处理更快
   - 无需加载额外模块

**建议：不启用，使用 Dialplan 正则表达式或 Lua 脚本替代。**

---

## 4. 总结与建议

### 4.1 模块启用建议

| 模块 | 推荐 | 优先级 | 建议 |
|------|------|--------|------|
| **mod_spy** | ✅ **是** | **高** | **必须启用** |
| mod_snapshot | ⚠️ 可选 | 低 | 按需启用 |
| mod_translate | ❌ 否 | 低 | 不推荐 |

### 4.2 呼叫中心场景决策

#### ✅ 必须启用：mod_spy

**理由**：
- 呼叫中心质量监控核心功能
- 座席培训必备工具
- 提升服务质量关键手段
- 行业标准功能
- 技术成熟稳定

**实施建议**：
1. 配置监听、耳语、强插功能
2. 集成到 Web 管理界面
3. 建立监听日志和统计
4. 设置权限控制和审计
5. 培训主管使用方法

#### ⚠️ 可选启用：mod_snapshot

**理由**：
- 仅用于调试场景
- 生产环境用处有限
- 有更好的录音方案（record_session）

**决策标准**：
- ✅ 如果：有专门的音频调试需求
- ✅ 如果：需要快速音频采样工具
- ❌ 如果：仅需要完整通话录音
- ❌ 如果：追求系统简洁性

#### ❌ 不推荐：mod_translate

**理由**：
- 功能已被现代方案完全替代
- 官方标记为遗留模块
- 无额外价值

**替代方案**：
- 使用 Dialplan 正则表达式
- 使用 Lua/Python 脚本
- 使用 mod_easyroute（已启用）

### 4.3 最终推荐配置

#### 建议的模块列表

```xml
<!-- 呼叫中心必需模块（已启用） -->
<load module="mod_callcenter"/>      <!-- 呼叫中心核心 -->
<load module="mod_fail2ban"/>        <!-- 安全防护 -->
<load module="mod_blacklist"/>       <!-- 黑名单 -->
<load module="mod_distributor"/>     <!-- 负载均衡 -->
<load module="mod_lcr"/>             <!-- 成本路由 -->
<load module="mod_cidlookup"/>       <!-- 来电查询 -->
<load module="mod_nibblebill"/>      <!-- 实时计费 -->
<load module="mod_curl"/>            <!-- HTTP API -->
<load module="mod_hiredis"/>         <!-- Redis 连接 -->
<load module="mod_redis"/>           <!-- Redis 限流 -->
<load module="mod_easyroute"/>       <!-- 路由查询 -->

<!-- 强烈推荐添加的模块 -->
<load module="mod_spy"/>             <!-- ⭐ 监听/质检 -->

<!-- 可选模块 -->
<!-- <load module="mod_snapshot"/> --> <!-- 仅调试时启用 -->

<!-- 不推荐的模块 -->
<!-- <load module="mod_translate"/> --> <!-- 已过时，不推荐 -->
```

### 4.4 实施路线图

#### 第一阶段：启用 mod_spy（必需）

```bash
# 1. 修改 Dockerfile 启用编译
sed -i 's/^#\(applications\/mod_spy\)/\1/' build/modules.conf.in

# 2. 修改 modules.conf.xml 启用加载
<load module="mod_spy"/> <!-- 监听/窃听/耳语 -->

# 3. 配置 Dialplan
# 添加监听拨号计划（88xxxx）

# 4. 重建镜像
docker build -t bytedesk/freeswitch:spy .

# 5. 测试验证
fs_cli -x "module_exists mod_spy"
```

#### 第二阶段：配置质检流程

1. 创建监听权限管理
2. 集成 Web 管理界面
3. 建立监听日志记录
4. 设置监听策略（频率、时长）
5. 培训主管使用

#### 第三阶段：数据分析（可选）

1. 统计监听数据
2. 生成质检报表
3. 分析座席表现
4. 优化培训计划

### 4.5 成本收益分析

| 模块 | 开发成本 | 维护成本 | 业务价值 | ROI |
|------|---------|---------|---------|-----|
| **mod_spy** | 低（1-2天） | 低 | **高** | **高** ⭐⭐⭐⭐⭐ |
| mod_snapshot | 极低（1小时） | 极低 | 低 | 中等 ⭐⭐⭐ |
| mod_translate | 低（半天） | 中（需维护规则） | 低 | 低 ⭐ |

---

## 5. 常见问题

### Q1: mod_spy 会影响通话质量吗？

**A:** 不会。mod_spy 只是复制音频流，不会干扰原始通话。性能开销极低（每个监听会话约 64kbps 带宽 + 2-5MB 内存）。

### Q2: 监听是否合法？是否需要提示客户？

**A:** 根据地区法律不同：
- **中国**：建议在 IVR 中播放"本次通话将被录音用于质量监控"
- **欧盟 GDPR**：必须明确告知并获得同意
- **美国**：各州法律不同，建议咨询法律顾问

**最佳实践**：在通话开始时播放提示音：
```xml
<action application="playback" data="ivr/ivr-this_call_may_be_monitored.wav"/>
```

### Q3: 一个主管可以同时监听多个座席吗？

**A:** 可以，但不推荐。原因：
- 人工监听质量下降
- 带宽和性能开销累加
- 难以有效评估服务质量

**建议**：主管同时监听不超过 2 个座席，更多使用录音回放质检。

### Q4: mod_snapshot 能用于合规录音吗？

**A:** 不能。理由：
- 只录制片段，非完整通话
- 不支持双声道分离
- 缺少元数据（时间戳、通话 ID 等）
- 不满足金融/医疗等行业合规要求

**合规录音请使用**：
- `record_session` 应用
- `mod_odbc_cdr`（已启用）记录元数据
- 加密存储和访问控制

### Q5: 如果已经在使用 Lua 脚本做号码转换，还需要 mod_translate 吗？

**A:** 不需要。Lua 脚本完全覆盖 mod_translate 的功能，且更灵活强大。坚持使用 Lua 方案即可。

---

## 6. 参考资源

### 官方文档

- [mod_spy 官方文档](https://freeswitch.org/confluence/display/FREESWITCH/mod_spy)
- [mod_dptools 录音功能](https://freeswitch.org/confluence/display/FREESWITCH/mod_dptools%3A+record)
- [eavesdrop 应用](https://freeswitch.org/confluence/display/FREESWITCH/mod_dptools%3A+eavesdrop)

### 社区最佳实践

- FreeSWITCH 邮件列表：呼叫中心质检讨论
- GitHub Issues：mod_spy 使用案例
- FreeSWITCH 中文社区：监听配置示例

---

## 7. 下一步行动

### 推荐操作

1. **立即启用 mod_spy**：
   ```bash
   # 修改 Dockerfile 和 modules.conf.xml
   # 重建镜像并部署
   ```

2. **配置监听功能**：
   - 添加监听拨号计划
   - 设置权限控制
   - 测试各种监听模式

3. **培训团队**：
   - 培训主管使用监听功能
   - 制定质检标准
   - 建立监听日志制度

4. **持续优化**：
   - 收集使用反馈
   - 分析监听数据
   - 优化服务质量

---

## 总结

**最终建议**：

- ✅ **立即启用 mod_spy**：呼叫中心必需功能，业务价值极高
- ⚠️ **暂不启用 mod_snapshot**：非生产必需，可按需启用
- ❌ **不启用 mod_translate**：已过时，无额外价值

**实施优先级**：
1. 🥇 mod_spy（高优先级，立即实施）
2. 🥉 mod_snapshot（低优先级，可选）
3. ❌ mod_translate（不推荐）

希望这份详细分析能帮助你做出明智的决策！🎯
