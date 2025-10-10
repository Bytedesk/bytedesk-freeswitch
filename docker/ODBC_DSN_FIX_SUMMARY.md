# ODBC DSN Configuration Fix Summary

## Problem
FreeSWITCH was showing the following errors on startup:

```
[ERR] switch_xml_config.c:267 Invalid value [mysql:host=bytedesk-mysql;port=3306;database=bytedesk;uid=root;pwd=r8FqfdbWUaN3;charset=utf8mb4] for parameter [odbc-dsn]

Item name: [odbc-dsn]
Type: string (optional)
Syntax: dsn:username:password
Help: If set, the ODBC DSN used by the limit and db applications

[WARNING] switch_xml_config.c:437 Configuration parameter [max-connections] is unfortunately not valid
[WARNING] switch_xml_config.c:437 Configuration parameter [pre-connect] is unfortunately not valid
[WARNING] switch_xml_config.c:437 Configuration parameter [connection-timeout] is unfortunately not valid
[WARNING] switch_xml_config.c:437 Configuration parameter [query-timeout] is unfortunately not valid
```

## Root Cause
The `db.conf.xml` file was configured incorrectly:
1. It was using a full MySQL connection string instead of the DSN format
2. It included invalid parameters that are not supported by the `mod_db` module

## Solution

### 1. Fixed `db.conf.xml`
**File**: `/docker/conf/autoload_configs/db.conf.xml`

**Before**:
```xml
<configuration name="db.conf" description="LIMIT DB Configuration">
  <settings>
    <param name="odbc-dsn" value="$${odbc_dsn}" />
    <param name="max-connections" value="25" />
    <param name="pre-connect" value="5" />
    <param name="connection-timeout" value="10" />
    <param name="query-timeout" value="30" />
  </settings>
</configuration>
```

**After**:
```xml
<configuration name="db.conf" description="LIMIT DB Configuration">
  <settings>
    <!-- ODBC DSN 连接格式: dsn:username:password -->
    <!-- DSN 名称 'freeswitch' 定义在 /etc/odbc.ini 中 -->
    <!-- 使用 vars.xml 中定义的变量 (odbc_dsn=freeswitch:root:r8FqfdbWUaN3) -->
    <param name="odbc-dsn" value="$${odbc_dsn}" />
  </settings>
</configuration>
```

### 2. Fixed `odbc_cdr.conf.xml`
**File**: `/docker/conf/autoload_configs/odbc_cdr.conf.xml`

**Before**:
```xml
<param name="odbc-dsn" value="$${odbc_dsn:freeswitch}"/>
```

**After**:
```xml
<!-- 数据库 DSN 名称，引用 odbc.conf.xml 中定义的数据库连接 -->
<!-- 使用 'default' 引用 odbc.conf.xml 中的 <database name="default"> -->
<param name="odbc-dsn" value="default"/>
```

## Understanding FreeSWITCH ODBC Configuration

FreeSWITCH has different modules that use ODBC in different ways:

### 1. `mod_db` (db.conf.xml)
- Uses the **system ODBC DSN** format: `dsn:username:password`
- The DSN name must be defined in `/etc/odbc.ini`
- This is configured in `vars.xml` as: `odbc_dsn=freeswitch:root:r8FqfdbWUaN3`
- Only supports the `odbc-dsn` parameter

### 2. `mod_odbc_cdr` (odbc_cdr.conf.xml)
- Uses **FreeSWITCH's internal ODBC** database pool
- References database connections defined in `odbc.conf.xml`
- Uses the database name (e.g., "default") not the DSN format
- Has additional configuration like table name and field mappings

### 3. `odbc.conf.xml`
- Defines FreeSWITCH's internal ODBC database connections
- Uses full connection strings: `mysql:host=xxx;port=xxx;database=xxx;...`
- Manages connection pools with parameters like `max-connections`, `pre-connect`, etc.
- These connections can be referenced by other modules using the database name

## Configuration Hierarchy

```
vars.xml
  ├─ db_host=bytedesk-mysql
  ├─ db_username=root
  ├─ db_password=r8FqfdbWUaN3
  └─ odbc_dsn=freeswitch:root:r8FqfdbWUaN3  (for mod_db)

/etc/odbc.ini (system ODBC)
  └─ [freeswitch] DSN configuration
       ├─ Server=bytedesk-mysql
       ├─ Database=bytedesk
       └─ User/Password

odbc.conf.xml (FreeSWITCH ODBC pool)
  └─ <database name="default">
       └─ Full MySQL connection string

db.conf.xml (mod_db)
  └─ Uses system ODBC DSN: "freeswitch:root:r8FqfdbWUaN3"

odbc_cdr.conf.xml (mod_odbc_cdr)
  └─ References odbc.conf.xml database: "default"

switch.conf.xml (core)
  └─ core-db-dsn uses full MariaDB connection string
```

## Verification

After these changes:
1. Restart FreeSWITCH
2. Check logs for the errors - they should be gone
3. Verify that the limit/db applications work correctly
4. Verify that CDR records are being written to the database

## Related Files
- `/docker/conf/vars.xml` - Variable definitions
- `/docker/conf/odbc.ini` - System ODBC configuration
- `/docker/conf/autoload_configs/odbc.conf.xml` - FreeSWITCH ODBC pool
- `/docker/conf/autoload_configs/db.conf.xml` - mod_db configuration
- `/docker/conf/autoload_configs/odbc_cdr.conf.xml` - mod_odbc_cdr configuration

## Date
2025-10-10
