# clean_logs/auto_clean_logs
## 1. 作用
手动或自动清理数据库中系统日志表数据

## 2. 用法
```bash
mo_ctl clean_logs help
mo_ctl clean_logs # 手动清理系统日志表数据
```

```bash
mo_ctl clean_logs help
Usage           : mo_ctl auto_clean_logs [option]    # 设置自动清理系统日志表数据
  [option]      : enable | disable | status(default)
```

## 3. 前提条件
请先设置相关的参数，说明如下：
```bash
mo_ctl set_conf CLEAN_LOGS_DAYS_BEFORE=31 # 可选，清理n天前的系统日志表数据，默认值：31
mo_ctl set_conf CLEAN_LOGS_TABLE_LIST=statement_info,rawlog,metric # 可选，清理的表对象清单，目前支持有：statement_info | rawlog | metric，如需多张表请以英文逗号（,）分隔，默认值：statement_info,rawlog,metric
```

## 4. 示例
### 4.1 手动清理
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl clean_logs
2025-01-03 17:25:02.792 UTC+0800    [INFO]    CLEAN_LOGS_DAYS_BEFORE: 31, clean date: 20241203
2025-01-03 17:25:02.799 UTC+0800    [INFO]    Clean log table: statement_info, sql: select PURGE_LOG('statement_info', '20241203');
2025-01-03 17:25:02.804 UTC+0800    [INFO]    Input "select PURGE_LOG('statement_info', '20241203');" is not a path or a file, try to execute it as a query
2025-01-03 17:25:02.810 UTC+0800    [INFO]    Begin executing query "select PURGE_LOG('statement_info', '20241203');"
--------------
select PURGE_LOG('statement_info', '20241203')
--------------

+-------------------------------------------------------------------------------------------------------------------------------+
| PURGE_LOG(statement_info, 20241203)                                                                                           |
+-------------------------------------------------------------------------------------------------------------------------------+
| 
msg: prune: table 272508-statement_info, 761h25m2s ago, cacheLen 0

total: 32, stale: 0, selected: 0, no valid objs to prune |
+-------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

Bye
2025-01-03 17:25:02.826 UTC+0800    [INFO]    End executing query select PURGE_LOG('statement_info', '20241203');, succeeded
2025-01-03 17:25:02.835 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select PURGE_LOG('statement_info', '20241203');,succeeded,9
2025-01-03 17:25:02.840 UTC+0800    [INFO]    Clean log table: rawlog, sql: select PURGE_LOG('rawlog', '20241203');
2025-01-03 17:25:02.845 UTC+0800    [INFO]    Input "select PURGE_LOG('rawlog', '20241203');" is not a path or a file, try to execute it as a query
2025-01-03 17:25:02.850 UTC+0800    [INFO]    Begin executing query "select PURGE_LOG('rawlog', '20241203');"
--------------
select PURGE_LOG('rawlog', '20241203')
--------------

+-----------------------------------------------------------------------------------------------------------------------+
| PURGE_LOG(rawlog, 20241203)                                                                                           |
+-----------------------------------------------------------------------------------------------------------------------+
| 
msg: prune: table 272509-rawlog, 761h25m2s ago, cacheLen 0

total: 32, stale: 0, selected: 0, no valid objs to prune |
+-----------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

Bye
2025-01-03 17:25:02.866 UTC+0800    [INFO]    End executing query select PURGE_LOG('rawlog', '20241203');, succeeded
2025-01-03 17:25:02.875 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select PURGE_LOG('rawlog', '20241203');,succeeded,8
2025-01-03 17:25:02.881 UTC+0800    [INFO]    Clean log table: metric, sql: select PURGE_LOG('metric', '20241203');
2025-01-03 17:25:02.886 UTC+0800    [INFO]    Input "select PURGE_LOG('metric', '20241203');" is not a path or a file, try to execute it as a query
2025-01-03 17:25:02.891 UTC+0800    [INFO]    Begin executing query "select PURGE_LOG('metric', '20241203');"
--------------
select PURGE_LOG('metric', '20241203')
--------------

+----------------------------------------------------------------------------------------------------------------------+
| PURGE_LOG(metric, 20241203)                                                                                          |
+----------------------------------------------------------------------------------------------------------------------+
| 
msg: prune: table 272482-metric, 761h25m2s ago, cacheLen 0

total: 3, stale: 0, selected: 0, no valid objs to prune |
+----------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

Bye
2025-01-03 17:25:02.907 UTC+0800    [INFO]    End executing query select PURGE_LOG('metric', '20241203');, succeeded
2025-01-03 17:25:02.916 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select PURGE_LOG('metric', '20241203');,succeeded,9
```

### 4.2 自动清理
请先设置与自动清理系统日志表数据相关的参数
```bash
mo_ctl set_conf CLEAN_LOGS_CRON_SCHEDULE="0 3 * * *" # 可选，自动清理的周期，默认为：0 3 * * *，即每天凌晨3点执行一次清理任务
```

查看状态（`status`）
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl auto_clean_logs
2025-01-03 17:28:52.429 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_logs for auto_clean_logs does not exist
2025-01-03 17:28:52.434 UTC+0800    [INFO]    auto_clean_logs status：disabled

github@test0:/data/mo/main/matrixone$ mo_ctl auto_clean_logs status
2025-01-03 17:29:13.003 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_logs for auto_clean_logs already exists, trying to get content: 
2025-01-03 17:29:13.009 UTC+0800    [DEBUG]    0 3 * * * github /usr/local/bin/mo_ctl clean_logs > /data/logs/mo_ctl/auto_clean_logs/$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:29:13.014 UTC+0800    [INFO]    auto_clean_logs status：enabled
```

启动（`enable`）
```bash
github@shpc2-10-222-1-9:/data/mo/main/matrixone$ mo_ctl auto_clean_logs enable
2025-01-03 17:28:55.142 UTC+0800    [DEBUG]    Get status of service cron
2025-01-03 17:28:55.151 UTC+0800    [DEBUG]    Succeeded. Service cron seems to be running.
2025-01-03 17:28:55.156 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_logs for auto_clean_logs does not exist
2025-01-03 17:28:55.162 UTC+0800    [INFO]    auto_clean_logs status：disabled
2025-01-03 17:28:55.167 UTC+0800    [INFO]    Enabling auto_clean_logs
2025-01-03 17:28:55.172 UTC+0800    [DEBUG]    Creating log folder: mkdir -p /data/logs/mo_ctl/auto_clean_logs/
2025-01-03 17:28:55.178 UTC+0800    [INFO]    Creating cron file /etc/cron.d/mo_clean_logs for auto_clean_logs
2025-01-03 17:28:55.183 UTC+0800    [DEBUG]    Content: 0 3 * * * github /usr/local/bin/mo_ctl clean_logs > /data/logs/mo_ctl/auto_clean_logs/$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:28:55.198 UTC+0800    [INFO]    Succeeded
2025-01-03 17:28:55.206 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_logs for auto_clean_logs already exists, trying to get content: 
2025-01-03 17:28:55.212 UTC+0800    [DEBUG]    0 3 * * * github /usr/local/bin/mo_ctl clean_logs > /data/logs/mo_ctl/auto_clean_logs/$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:28:55.217 UTC+0800    [INFO]    auto_clean_logs status：enabled
```

禁用（`disable`）
```bash
github@shpc2-10-222-1-9:/data/mo/main/matrixone$ mo_ctl auto_clean_logs disable
2025-01-03 17:29:38.968 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_logs for auto_clean_logs already exists, trying to get content: 
2025-01-03 17:29:38.974 UTC+0800    [DEBUG]    0 3 * * * github /usr/local/bin/mo_ctl clean_logs > /data/logs/mo_ctl/auto_clean_logs/$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:29:38.979 UTC+0800    [INFO]    auto_clean_logs status：enabled
2025-01-03 17:29:38.984 UTC+0800    [INFO]    Disabling auto_clean_logs by removing cron file /etc/cron.d/mo_clean_logs
2025-01-03 17:29:38.993 UTC+0800    [INFO]    Succeeded
2025-01-03 17:29:38.998 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_logs for auto_clean_logs does not exist
2025-01-03 17:29:39.003 UTC+0800    [INFO]    auto_clean_logs status：disabled
```