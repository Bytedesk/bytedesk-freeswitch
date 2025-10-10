-- FreeSWITCH ODBC CDR 数据库表结构
-- 用于 mod_odbc_cdr 模块记录呼叫详单

-- 创建 CDR 表
CREATE TABLE IF NOT EXISTS `cdr` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `uuid` VARCHAR(255) NOT NULL COMMENT '通话唯一标识',
  `caller_id_name` VARCHAR(255) DEFAULT NULL COMMENT '主叫名称',
  `caller_id_number` VARCHAR(255) DEFAULT NULL COMMENT '主叫号码',
  `destination_number` VARCHAR(255) DEFAULT NULL COMMENT '被叫号码',
  `context` VARCHAR(255) DEFAULT NULL COMMENT '拨号计划上下文',
  `start_stamp` DATETIME DEFAULT NULL COMMENT '通话开始时间',
  `answer_stamp` DATETIME DEFAULT NULL COMMENT '通话接听时间',
  `end_stamp` DATETIME DEFAULT NULL COMMENT '通话结束时间',
  `duration` INT DEFAULT 0 COMMENT '通话总时长(秒)',
  `billsec` INT DEFAULT 0 COMMENT '计费时长(秒)',
  `hangup_cause` VARCHAR(50) DEFAULT NULL COMMENT '挂机原因',
  `accountcode` VARCHAR(255) DEFAULT NULL COMMENT '账户代码',
  `sip_hangup_disposition` VARCHAR(50) DEFAULT NULL COMMENT 'SIP挂机处理',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_uuid` (`uuid`),
  KEY `idx_caller_id_number` (`caller_id_number`),
  KEY `idx_destination_number` (`destination_number`),
  KEY `idx_start_stamp` (`start_stamp`),
  KEY `idx_answer_stamp` (`answer_stamp`),
  KEY `idx_end_stamp` (`end_stamp`),
  KEY `idx_hangup_cause` (`hangup_cause`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='FreeSWITCH CDR 呼叫详单记录';

-- 创建索引以提升查询性能
-- 按时间范围查询
CREATE INDEX idx_time_range ON cdr(start_stamp, end_stamp);

-- 按账户查询
CREATE INDEX idx_accountcode ON cdr(accountcode);

-- 示例查询：
-- 1. 查询最近的通话记录
-- SELECT * FROM cdr ORDER BY start_stamp DESC LIMIT 100;

-- 2. 查询某个号码的通话记录
-- SELECT * FROM cdr WHERE caller_id_number = '1000' OR destination_number = '1000';

-- 3. 统计某时间段的通话量
-- SELECT DATE(start_stamp) as date, COUNT(*) as call_count, SUM(duration) as total_duration
-- FROM cdr 
-- WHERE start_stamp >= '2024-01-01' AND start_stamp < '2024-02-01'
-- GROUP BY DATE(start_stamp);

-- 4. 查询未接通的电话
-- SELECT * FROM cdr WHERE answer_stamp IS NULL;

-- 5. 查询通话时长超过5分钟的记录
-- SELECT * FROM cdr WHERE duration > 300 ORDER BY duration DESC;
