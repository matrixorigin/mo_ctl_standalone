# `sql`
## 1. 作用
使用`mo_ctl`工具来执行sql语句、sql文件或一个目录下的多个sql文件

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl sql help
Usage           : mo_ctl sql [sql]                 # execute sql from string, or a file or a path containg multiple files
  [sql]         : (required) a string quote by "", which could be a raw string of sql statements, a file of statements, or a path with one or more files
Examples        : mo_ctl sql "use test;select 1;"  # execute sql "use test;select 1"
                : mo_ctl sql /data/q1.sql            # execute sql in file /data/q1.sql
                : mo_ctl sql /data/                  # execute all sql files with .sql postfix in /data/
```
## 3. 前提条件
MO正常运行，且以下`mo_ctl`工具的配置已设置，例如：
```bash
mo_ctl set_conf MO_HOST=127.0.0.1  # 主机名或IP
mo_ctl set_conf MO_PORT=6001 # 端口号
mo_ctl set_conf MO_HOST=dump  # 用户名
mo_ctl set_conf MO_HOST=111  # 用户密码
```

## 4. 示例
### 1）执行sql语句
```bash
github@shpc2-10-222-1-9:~$ mo_ctl sql "select 1, version(); show databases;"
2025-01-21 17:17:01.165 UTC+0800    [INFO]    Input "select 1, version(); show databases;" is not a path or a file, try to execute it as a query
2025-01-21 17:17:01.171 UTC+0800    [INFO]    Begin executing query "select 1, version(); show databases;"
--------------
select 1, version()
--------------

+------+-------------------------+
| 1    | version()               |
+------+-------------------------+
|    1 | 8.0.30-MatrixOne-v2.1.0 |
+------+-------------------------+
1 row in set (0.00 sec)

--------------
show databases
--------------

+---------------------+
| Database            |
+---------------------+
| db1                 |
| db2                 |
| information_schema  |
| dn3                 |
| db5                 |
| mo_catalog          |
| mo_debug            |
| mo_task             |
| mysql               |
| db33                |
| system              |
| system_metrics      |
| db99                |
+---------------------+
13 rows in set (0.00 sec)

Bye
2025-01-21 17:17:01.194 UTC+0800    [INFO]    End executing query select 1, version(); show databases;, succeeded
2025-01-21 17:17:01.203 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select 1, version(); show databases;,succeeded,16
```

### 2）执行sql文件
```bash
github@shpc2-10-222-1-9:~$ echo "select 1, version(); show databases;" > /tmp/1.sql
github@shpc2-10-222-1-9:~$ cat /tmp/1.sql
select 1, version(); show databases;
github@shpc2-10-222-1-9:~$ mo_ctl sql "/tmp/1.sql"
2025-01-21 17:18:00.120 UTC+0800    [INFO]    Input /tmp/1.sql is a file
2025-01-21 17:18:00.125 UTC+0800    [INFO]    Begin executing query file /tmp/1.sql
--------------
select 1, version()
--------------

+------+-------------------------+
| 1    | version()               |
+------+-------------------------+
|    1 | 8.0.30-MatrixOne-v2.1.0 |
+------+-------------------------+
1 row in set (0.00 sec)

--------------
show databases
--------------

+---------------------+
| Database            |
+---------------------+
| db1                 |
| db2                 |
| information_schema  |
| dn3                 |
| db5                 |
| mo_catalog          |
| mo_debug            |
| mo_task             |
| mysql               |
| db33                |
| system              |
| system_metrics      |
| db99                |
+---------------------+
13 rows in set (0.00 sec)

Bye
2025-01-21 17:18:00.142 UTC+0800    [INFO]    End executing query file /tmp/1.sql, succeeded
2025-01-21 17:18:00.152 UTC+0800    [INFO]    Query report:
query_file,outcome,time_cost_ms
/tmp/1.sql,succeeded,9
```

### 3）执行一个目录下的全部.sql文件
```bash
github@shpc2-10-222-1-9:~$ mkdir /tmp/sql_files
github@shpc2-10-222-1-9:~$ echo "select 1, version(); show databases;" > /tmp/sql_files/1.sql
github@shpc2-10-222-1-9:~$ echo "select current_timestamp;" > /tmp/sql_files/2.sql
github@shpc2-10-222-1-9:~$ mo_ctl sql "/tmp/sql_files/"
2025-01-21 17:20:05.489 UTC+0800    [INFO]    Input /tmp/sql_files/ is a path, listing .sql files in it: 
1.sql
2.sql
2025-01-21 17:20:05.497 UTC+0800    [INFO]    Begin executing query file 1.sql
--------------
select 1, version()
--------------

+------+-------------------------+
| 1    | version()               |
+------+-------------------------+
|    1 | 8.0.30-MatrixOne-v2.1.0 |
+------+-------------------------+
1 row in set (0.00 sec)

--------------
show databases
--------------

+---------------------+
| Database            |
+---------------------+
| db1                 |
| db2                 |
| information_schema  |
| dn3                 |
| db5                 |
| mo_catalog          |
| mo_debug            |
| mo_task             |
| mysql               |
| db33                |
| system              |
| system_metrics      |
| db99                |
+---------------------+
13 rows in set (0.00 sec)

Bye
2025-01-21 17:20:05.514 UTC+0800    [INFO]    End executing query file 1.sql, succeeded
2025-01-21 17:20:05.523 UTC+0800    [INFO]    Begin executing query file 2.sql
--------------
select current_timestamp
--------------

+----------------------------+
| current_timestamp()        |
+----------------------------+
| 2025-01-21 17:20:05.537391 |
+----------------------------+
1 row in set (0.00 sec)

Bye
2025-01-21 17:20:05.541 UTC+0800    [INFO]    End executing query file 2.sql, succeeded
2025-01-21 17:20:05.550 UTC+0800    [INFO]    Done executing all query files in path /tmp/sql_files/
2025-01-21 17:20:05.555 UTC+0800    [INFO]    Query report:
query_file,outcome,time_cost_ms
1.sql,succeeded,10
2.sql,succeeded,10
```