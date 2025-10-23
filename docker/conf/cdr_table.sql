# ************************************************************
# Sequel Ace SQL dump
# 版本号： 20080
#
# https://sequel-ace.com/
# https://github.com/Sequel-Ace/Sequel-Ace
#
# 主机: 124.220.58.234 (MySQL 8.0.42-0ubuntu0.24.04.1)
# 数据库: bytedesk_freeswitch
# 生成时间: 2025-10-22 23:38:19 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
SET NAMES utf8mb4;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE='NO_AUTO_VALUE_ON_ZERO', SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# 转储表 cdr
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `cdr` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(64) NOT NULL,
  `bleg_uuid` varchar(64) DEFAULT NULL,
  `account_code` varchar(64) DEFAULT NULL,
  `domain_name` varchar(255) DEFAULT NULL,
  `caller_id_name` varchar(255) DEFAULT NULL,
  `caller_id_number` varchar(64) DEFAULT NULL,
  `destination_number` varchar(64) DEFAULT NULL,
  `context` varchar(64) DEFAULT NULL,
  `start_stamp` datetime DEFAULT NULL,
  `answer_stamp` datetime DEFAULT NULL,
  `end_stamp` datetime DEFAULT NULL,
  `duration` int DEFAULT '0',
  `billsec` int DEFAULT '0',
  `hangup_cause` varchar(255) DEFAULT NULL,
  `read_codec` varchar(64) DEFAULT NULL,
  `write_codec` varchar(64) DEFAULT NULL,
  `sip_hangup_disposition` varchar(64) DEFAULT NULL,
  `ani` varchar(64) DEFAULT NULL,
  `aniii` varchar(64) DEFAULT NULL,
  `network_addr` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_uuid` (`uuid`),
  KEY `idx_start` (`start_stamp`),
  KEY `idx_dest` (`destination_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
