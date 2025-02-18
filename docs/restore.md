# restore
## 1. 作用
还原数据备份到mo

## 2. 用法
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl restore help
Usage           : mo_ctl restore             # restore mo from a data backup
Note            : Currently only supported on Linux. Please set below confs first
                  ------------------------- 
                   1. Common settings       
                  ------------------------- 
                    1) RESTORE_TYPE (optional, default: physical): backup type to restore, choose from "physical" | "logical". e.g. mo_ctl set_conf RESTORE_TYPE="logical"

                  ------------------------- 
                   2. For physical backups  
                  ------------------------- 
                    1) BACKUP_MOBR_PATH (optional, default: /data/tools/mo-backup/mo_br): Path to mo_br backup tool
                    2) RESTORE_PATH (required): path to restore, which must be an empty folder, e.g. mo_ctl set_conf RESTORE_PATH="/data/mo/restore"
                    3) RESTORE_BKID (required): backup id to restore, which can be found using cmd "mo_ctl backup list detail", e.g. mo_ctl set_conf RESTORE_BKID="6363b248-fc9f-11ee-845e-b07b25235fd0"
                    4) RESTORE_PHYSICAL_TYPE (optional, default: filesystem]: target restore storage type, choose from "filesystem" | "s3"
                    if RESTORE_PHYSICAL_TYPE=s3
                      a) RESTORE_S3_ENDPOINT (optional, default: ''): s3 endpoint, e.g. https://cos.ap-nanjing.myqcloud.com
                      b) RESTORE_S3_ID (optional, default: ''): s3 id, e.g. B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k
                      c) RESTORE_S3_KEY (optional, default: ''): s3 key, e.g. QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j
                      d) RESTORE_S3_BUCKET (optional, default: ''): s3 bucket, e.g. mybucket
                      e) RESTORE_S3_REGION (optional, default: ''): s3 region, e.g. ap-nanjing
                      f) RESTORE_S3_COMPRESSION (optional, default: ''): s3 compression
                      g) RESTORE_S3_ROLE_ARN (optional, default: ''): s3 role arn
                      h) RESTORE_S3_IS_MINIO (optional, default: 'no'): is minio type or not, choose from "no" | "yes"

                  ------------------------- 
                   3. For logical restore  
                  ------------------------- 
                    1) BACKUP_MODUMP_PATH (optional, default: /data/tools/mo_dump/mo-dump): Path to mo-dump backup tool
                    2) RESTORE_LOGICAL_SRC (required): Path of a directory or file to logical backup data source, e.g. /data/backup/db1.sql
                    3) RESTORE_LOGICAL_DB (optional): if set, will add database name to mysql command when restoring logical backup data. i.e. MYSQL_PWD=xx mysql -hxxx -Pxxx db_name < backup_data.sql
                    4) RESTORE_LOGICAL_TYPE (optional, default: ddl): available: ddl | insert | csv
```

## 3. 前提条件
### 3.1 物理备份还原
1、准备好一个备份还原数据目录，并提供备份的id
2、仅适用于本地部署的单机mo，且mo进程处于停止状态
3、mo watchdog 处于禁用状态
4、还原前，设置好以下参数
```bash
mo_ctl set_conf RESTORE_TYPE=physical # 设置还原类型为物理还原
mo_ctl set_conf BACKUP_MOBR_PATH=/data/tools/mo-backup/mo_br # 物理备份还原工具所在路径
mo_ctl set_conf RESTORE_PATH=/data/mo/restore/ # 用于存储物理还原出来数据的目录路径
mo_ctl set_conf RESTORE_BKID=01951819-d7b6-7bc1-8a58-93fa2c4d8343
mo_ctl set_conf RESTORE_PHYSICAL_TYPE=filesystem # 还原到本地文件系统
```

### 3.2 逻辑备份还原
1、准备好一个逻辑备份还原数据文件或目录
2、适用于本地或远程部署的mo，不论单机或分布式，或云上环境
3、mo处于运行中可用状态
4、还原前，设置好以下参数
```bash
mo_ctl set_conf RESTORE_TYPE=logical  # 设置还原类型为逻辑还原
mo_ctl set_conf BACKUP_MODUMP_PATH=/data/tools/mo_dump/mo-dump # 逻辑备份还原工具的路径
mo_ctl set_conf RESTORE_LOGICAL_SRC=/data/backup/db1.sql # 逻辑备份还原的目录或者文件的路径，例如：/data/backup/db1.sql 或 /data/backup/db1/
mo_ctl set_conf RESTORE_LOGICAL_DB=mydb # 逻辑备份还原的db清单，例如：mydb，如果设置了，还原命令会指定db名称，类似于：MYSQL_PWD=xx mysql -hxxx -Pxxx mydb < backup_data.sql
mo_ctl set_conf RESTORE_LOGICAL_TYPE=insert # 逻辑备份还原的类型，可选：ddl、insert、csv 
```

## 4. 示例
### 4.1 物理备份还原
以全量备份还原为例，增量备份同理：
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl sql "create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3);"
2025-02-18 16:08:08.203 UTC+0800    [INFO]    Input "create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3);" is not a path or a file, try to execute it as a query
2025-02-18 16:08:08.208 UTC+0800    [INFO]    Begin executing query "create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3);"
--------------
create database test
--------------

Query OK, 1 row affected (0.01 sec)

--------------
create table t1(id int)
--------------

Query OK, 0 rows affected (0.00 sec)

--------------
insert into t1 values (1),(2),(3)
--------------

Query OK, 3 rows affected (0.01 sec)

Bye
2025-02-18 16:08:08.244 UTC+0800    [INFO]    End executing query create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3);, succeeded
2025-02-18 16:08:08.254 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3);,succeeded,28
github@shpc2-10-222-1-9:/data$ mo_ctl sql "select * from test.t1;"
2025-02-18 16:08:18.189 UTC+0800    [INFO]    Input "select * from test.t1;" is not a path or a file, try to execute it as a query
2025-02-18 16:08:18.195 UTC+0800    [INFO]    Begin executing query "select * from test.t1;"
--------------
select * from test.t1
--------------

+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.00 sec)

Bye
2025-02-18 16:08:18.214 UTC+0800    [INFO]    End executing query select * from test.t1;, succeeded
2025-02-18 16:08:18.225 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select * from test.t1;,succeeded,11
github@shpc2-10-222-1-9:/data$ mo_ctl backup 
2025-02-18 16:08:20.941 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-02-18 16:08:20.959 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3497392       1 11 16:07 ?        00:00:06 /data/mo/2.0-dev/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/2.0-dev/matrixone/etc/launch/launch.toml
2025-02-18 16:08:20.965 UTC+0800    [INFO]    List of pid(s): 
3497392
2025-02-18 16:08:20.970 UTC+0800    [INFO]    Backup settings
2025-02-18 16:08:20.975 UTC+0800    [INFO]    ------------------------------------
BACKUP_TYPE="physical"
BACKUP_CRON_SCHEDULE="30 23 * * *"
BACKUP_DATA_PATH="/data/mo-backup"
BACKUP_CLEAN_DAYS_BEFORE="31"
BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"
BACKUP_REPORT="${TOOL_LOG_PATH}/backup/report.txt"
BACKUP_MOBR_PATH="/data/tools/mo-backup/mo_br"
BACKUP_PHYSICAL_TYPE="filesystem"
BACKUP_S3_ENDPOINT=""
BACKUP_S3_ID=""
BACKUP_S3_KEY=""
BACKUP_S3_BUCKET=""
BACKUP_S3_REGION=""
BACKUP_S3_COMPRESSION=""
BACKUP_S3_ROLE_ARN=""
BACKUP_S3_IS_MINIO="no"
BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
BACKUP_LOGICAL_DB_LIST="all_no_sysdb"
BACKUP_LOGICAL_DATA_TYPE="csv"
2025-02-18 16:08:20.986 UTC+0800    [INFO]    ------------------------------------
2025-02-18 16:08:20.992 UTC+0800    [INFO]    Backup begins
2025-02-18 16:08:21.022 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-02-18 16:08:21.063 UTC+0800    [INFO]    Physical backup method: full
Backup ID
    01951819-d7b6-7bc1-8a58-93fa2c4d8343
2025-02-18 16:08:22.550 UTC+0800    [INFO]    End with outcome: succeeded, cost: 1470 ms
2025-02-18 16:08:22.575 UTC+0800    [INFO]    Backup ends with 0 rc

github@shpc2-10-222-1-9:/data$ ll /data/mo-backup
mo-backup/     mo-backup-reg/ 
github@shpc2-10-222-1-9:/data$ ll /data/mo-backup/202502/20250218_160820/
total 12
-rw------- 1 github github  240 Feb 18 16:08 01951819-d7b6-7bc1-8a58-93fa2c4d8343.meta
-rw------- 1 github github   32 Feb 18 16:08 01951819-d7b6-7bc1-8a58-93fa2c4d8343.meta.sha256
drwxr-xr-x 5 github github 4096 Feb 18 16:08 full-01951819-d7b6-7bc1-8a58-93fa2c4d8343

github@shpc2-10-222-1-9:/data$ mo_ctl sql "create database test2;"
2025-02-18 16:12:49.148 UTC+0800    [INFO]    Input "create database test2;" is not a path or a file, try to execute it as a query
2025-02-18 16:12:49.153 UTC+0800    [INFO]    Begin executing query "create database test2;"
--------------
create database test2
--------------

Query OK, 1 row affected (0.01 sec)

Bye
2025-02-18 16:12:49.176 UTC+0800    [INFO]    End executing query create database test2;, succeeded
2025-02-18 16:12:49.186 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
create database test2;,succeeded,15
github@shpc2-10-222-1-9:/data$ mo_ctl sql "show databases;"
2025-02-18 16:12:57.675 UTC+0800    [INFO]    Input "show databases;" is not a path or a file, try to execute it as a query
2025-02-18 16:12:57.680 UTC+0800    [INFO]    Begin executing query "show databases;"
--------------
show databases
--------------

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mo_catalog         |
| mo_debug           |
| mo_task            |
| mysql              |
| system             |
| system_metrics     |
| test               |
| test2              |
+--------------------+
9 rows in set (0.00 sec)

Bye
2025-02-18 16:12:57.696 UTC+0800    [INFO]    End executing query show databases;, succeeded
2025-02-18 16:12:57.706 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
show databases;,succeeded,9

github@shpc2-10-222-1-9:/data$ mo_ctl stop
2025-02-18 16:13:15.262 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3497392       1 11 16:07 ?        00:00:41 /data/mo/2.0-dev/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/2.0-dev/matrixone/etc/launch/launch.toml
2025-02-18 16:13:15.267 UTC+0800    [INFO]    List of pid(s): 
3497392
2025-02-18 16:13:15.272 UTC+0800    [INFO]    Try stop all mo-services found for a maximum of 10 times, try no: 1
2025-02-18 16:13:15.278 UTC+0800    [INFO]    Stopping mo-service with pid 3497392 with command: kill  3497392
2025-02-18 16:13:15.283 UTC+0800    [INFO]    Wait for 5 seconds
2025-02-18 16:13:20.303 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:13:20.308 UTC+0800    [INFO]    Stop succeeded
github@shpc2-10-222-1-9:/data$ mo_ctl watchdog disable
2025-02-18 16:13:24.748 UTC+0800    [INFO]    watchdog status：disabled
2025-02-18 16:13:24.754 UTC+0800    [INFO]    No need to disable watchdog as it is already disabled, exiting

github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_TYPE=physical # 设备还原类型为物理还原
2025-02-18 16:17:01.528 UTC+0800    [INFO]    Try to set conf: RESTORE_TYPE="physical"
2025-02-18 16:17:01.541 UTC+0800    [INFO]    Setting conf RESTORE_TYPE="physical"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_MOBR_PATH=/data/tools/mo-backup/mo_br # 物理备份还原工具所在路径
2025-02-18 16:17:03.376 UTC+0800    [INFO]    Try to set conf: BACKUP_MOBR_PATH="/data/tools/mo-backup/mo_br"
2025-02-18 16:17:03.388 UTC+0800    [INFO]    Setting conf BACKUP_MOBR_PATH="/data/tools/mo-backup/mo_br"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_PATH=/data/mo/restore/ # 用于存储物理还原出来数据的目录路径
2025-02-18 16:17:05.169 UTC+0800    [INFO]    Try to set conf: RESTORE_PATH="/data/mo/restore/"
2025-02-18 16:17:05.181 UTC+0800    [INFO]    Setting conf RESTORE_PATH="/data/mo/restore/"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_BKID=01951819-d7b6-7bc1-8a58-93fa2c4d8343
2025-02-18 16:17:07.424 UTC+0800    [INFO]    Try to set conf: RESTORE_BKID="01951819-d7b6-7bc1-8a58-93fa2c4d8343"
2025-02-18 16:17:07.437 UTC+0800    [INFO]    Setting conf RESTORE_BKID="01951819-d7b6-7bc1-8a58-93fa2c4d8343"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_PHYSICAL_TYPE=filesystem # 还原到本地文件系统
2025-02-18 16:17:09.094 UTC+0800    [INFO]    Try to set conf: RESTORE_PHYSICAL_TYPE="filesystem"
2025-02-18 16:17:09.106 UTC+0800    [INFO]    Setting conf RESTORE_PHYSICAL_TYPE="filesystem"
github@shpc2-10-222-1-9:/data$ mo_ctl restore
2025-02-18 16:17:11.946 UTC+0800    [INFO]    Current confs:
MO_PATH="/data/mo/2.0-dev"
MO_DEPLOY_MODE="git"
MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
RESTORE_TYPE="physical"
RESTORE_PATH="/data/mo/restore/"
RESTORE_REPORT="${TOOL_LOG_PATH}/restore-report.txt"
RESTORE_PHYSICAL_TYPE="filesystem"
RESTORE_BKID="01951819-d7b6-7bc1-8a58-93fa2c4d8343"
RESTORE_S3_ENDPOINT=""
RESTORE_S3_ID=""
RESTORE_S3_KEY=""
RESTORE_S3_BUCKET=""
RESTORE_S3_REGION=""
RESTORE_S3_COMPRESSION=""
RESTORE_S3_ROLE_ARN=""
RESTORE_S3_IS_MINIO="no"
RESTORE_LOGICAL_DB=""
RESTORE_LOGICAL_SRC=""
RESTORE_LOGICAL_TYPE="ddl"
2025-02-18 16:17:11.958 UTC+0800    [WARN]    Please make sure if you really want to perform a restore(Yes/No):
yes
2025-02-18 16:17:13.149 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:17:13.171 UTC+0800    [INFO]    watchdog status：disabled
2025-02-18 16:17:13.176 UTC+0800    [INFO]    Restore settings
2025-02-18 16:17:13.181 UTC+0800    [INFO]    ------------------------------------
RESTORE_TYPE="physical"
RESTORE_PATH="/data/mo/restore/"
RESTORE_REPORT="${TOOL_LOG_PATH}/restore-report.txt"
RESTORE_PHYSICAL_TYPE="filesystem"
RESTORE_BKID="01951819-d7b6-7bc1-8a58-93fa2c4d8343"
RESTORE_S3_ENDPOINT=""
RESTORE_S3_ID=""
RESTORE_S3_KEY=""
RESTORE_S3_BUCKET=""
RESTORE_S3_REGION=""
RESTORE_S3_COMPRESSION=""
RESTORE_S3_ROLE_ARN=""
RESTORE_S3_IS_MINIO="no"
RESTORE_LOGICAL_DB=""
RESTORE_LOGICAL_SRC=""
RESTORE_LOGICAL_TYPE="ddl"
2025-02-18 16:17:13.193 UTC+0800    [INFO]    ------------------------------------
2025-02-18 16:17:13.199 UTC+0800    [INFO]    Step_1. Restore physical data
2025-02-18 16:17:13.204 UTC+0800    [INFO]    Restore begins
From:
    BackupDir: filesystem
    Path: /data/mo-backup/202502/20250218_160820

To
    BackupDir: filesystem
    Path: /data/mo/restore/

TaePath
    ./mo-data/shared
restore tae file path ./mo-data/shared, parallelism 1,  parallel count num: 1
restore file num: 1, total file num: 64, cost : 76.497µs
Copy tae file 1
    01951819-4069-7ec1-86ad-acd5b5875e58_00000 => mo-data/shared/01951819-4069-7ec1-86ad-acd5b5875e58_00000
Copy tae file 34
    ckp/meta_0-0_1739866101719036581-0.ckp => mo-data/shared/ckp/meta_0-0_1739866101719036581-0.ckp
Copy tae file 2
    01951819-76a2-71fb-ac44-d5642546fe34_00000 => mo-data/shared/01951819-76a2-71fb-ac44-d5642546fe34_00000
Copy tae file 3
    01951819-7d9e-7eab-9736-575caca8fb82_00000 => mo-data/shared/01951819-7d9e-7eab-9736-575caca8fb82_00000
Copy tae file 4
    01951819-8e40-7b8d-9ed2-f43b9c189c67_00000 => mo-data/shared/01951819-8e40-7b8d-9ed2-f43b9c189c67_00000
Copy tae file 5
    01951819-406a-7142-9455-c994eb027a88_00000 => mo-data/shared/01951819-406a-7142-9455-c994eb027a88_00000
Copy tae file 6
    01951819-a32e-7acf-b012-bb97a042ca2d_00000 => mo-data/shared/01951819-a32e-7acf-b012-bb97a042ca2d_00000
Copy tae file 7
    01951819-d976-7d70-a655-c32784964e42_00000 => mo-data/shared/01951819-d976-7d70-a655-c32784964e42_00000
Copy tae file 8
    01951819-4069-7eb3-af42-8fdaaa0dbb94_00000 => mo-data/shared/01951819-4069-7eb3-af42-8fdaaa0dbb94_00000
Copy tae file 9
    01951819-406a-711b-bd6b-18423ff5cb2d_00000 => mo-data/shared/01951819-406a-711b-bd6b-18423ff5cb2d_00000
Copy tae file 10
    01951819-406a-7171-9697-88aa01744cc1_00000 => mo-data/shared/01951819-406a-7171-9697-88aa01744cc1_00000
Copy tae file 11
    01951819-406a-7192-9cf2-67b6f9b2a87e_00000 => mo-data/shared/01951819-406a-7192-9cf2-67b6f9b2a87e_00000
Copy tae file 12
    01951819-76c0-736f-8d1c-b28f4fdaba80_00000 => mo-data/shared/01951819-76c0-736f-8d1c-b28f4fdaba80_00000
Copy tae file 13
    01951819-406a-7059-9733-7874c089a893_00000 => mo-data/shared/01951819-406a-7059-9733-7874c089a893_00000
Copy tae file 14
    01951819-4069-7ee0-9ab5-1c1efe83f588_00000 => mo-data/shared/01951819-4069-7ee0-9ab5-1c1efe83f588_00000
Copy tae file 15
    01951819-4069-7f21-a718-5cdd3af34d83_00000 => mo-data/shared/01951819-4069-7f21-a718-5cdd3af34d83_00000
Copy tae file 16
    01951819-406a-7025-98a0-6d64dc1858ed_00000 => mo-data/shared/01951819-406a-7025-98a0-6d64dc1858ed_00000
Copy tae file 17
    01951819-406a-7008-8061-5fea348d23d7_00000 => mo-data/shared/01951819-406a-7008-8061-5fea348d23d7_00000
Copy tae file 18
    01951819-9d77-777f-b3ac-6da9c381aea6_00000 => mo-data/shared/01951819-9d77-777f-b3ac-6da9c381aea6_00000
Copy tae file 19
    01951819-406a-7154-b2cb-d7d284ce2538_00000 => mo-data/shared/01951819-406a-7154-b2cb-d7d284ce2538_00000
Copy tae file 20
    01951819-d96d-7852-af65-a50662301a8a_00000 => mo-data/shared/01951819-d96d-7852-af65-a50662301a8a_00000
Copy tae file 21
    01951819-4069-7e5d-acea-9df786d9a9c3_00000 => mo-data/shared/01951819-4069-7e5d-acea-9df786d9a9c3_00000
Copy tae file 22
    01951819-4069-7f39-b68c-7081e2cfed5a_00000 => mo-data/shared/01951819-4069-7f39-b68c-7081e2cfed5a_00000
Copy tae file 23
    01951819-8306-7333-ab31-fc6f5c79582a_00000 => mo-data/shared/01951819-8306-7333-ab31-fc6f5c79582a_00000
Copy tae file 24
    01951819-406a-7103-92b6-bea1abd80f52_00000 => mo-data/shared/01951819-406a-7103-92b6-bea1abd80f52_00000
Copy tae file 25
    01951819-4069-7f01-af76-23ec905fdc40_00000 => mo-data/shared/01951819-4069-7f01-af76-23ec905fdc40_00000
Copy tae file 26
    01951819-8306-736b-858c-ca17dc1a878d_00000 => mo-data/shared/01951819-8306-736b-858c-ca17dc1a878d_00000
Copy tae file 27
    01951819-d969-7a3b-941b-cf22a35d457c_00000 => mo-data/shared/01951819-d969-7a3b-941b-cf22a35d457c_00000
Copy tae file 28
    01951819-d97a-7a92-be65-3e6544b70c7d_00000 => mo-data/shared/01951819-d97a-7a92-be65-3e6544b70c7d_00000
Copy tae file 29
    01951819-4069-7eef-beb5-addd39b96400_00000 => mo-data/shared/01951819-4069-7eef-beb5-addd39b96400_00000
Copy tae file 30
    01951819-4069-7ea2-808c-65dffa9e2400_00000 => mo-data/shared/01951819-4069-7ea2-808c-65dffa9e2400_00000
Copy tae file 31
    01951819-406a-7017-ad54-d22468d5a48b_00000 => mo-data/shared/01951819-406a-7017-ad54-d22468d5a48b_00000
Copy tae file 32
    01951819-4069-7f0e-b304-153e49e0069b_00000 => mo-data/shared/01951819-4069-7f0e-b304-153e49e0069b_00000
Copy tae file 33
    01951819-76ba-74ca-a1ae-6199a33862ef_00000 => mo-data/shared/01951819-76ba-74ca-a1ae-6199a33862ef_00000
Copy tae file 35
    01951819-406a-7103-92b6-bea1abd80f52_01000 => mo-data/shared/01951819-406a-7103-92b6-bea1abd80f52_01000
Copy tae file 36
    01951819-76ba-74ca-a1ae-6199a33862ef_01000 => mo-data/shared/01951819-76ba-74ca-a1ae-6199a33862ef_01000
Copy tae file 37
    01951819-4069-7ec1-86ad-acd5b5875e58_01000 => mo-data/shared/01951819-4069-7ec1-86ad-acd5b5875e58_01000
Copy tae file 38
    01951819-406a-7017-ad54-d22468d5a48b_01000 => mo-data/shared/01951819-406a-7017-ad54-d22468d5a48b_01000
Copy tae file 39
    01951819-9d77-777f-b3ac-6da9c381aea6_01000 => mo-data/shared/01951819-9d77-777f-b3ac-6da9c381aea6_01000
Copy tae file 40
    01951819-8306-7333-ab31-fc6f5c79582a_01000 => mo-data/shared/01951819-8306-7333-ab31-fc6f5c79582a_01000
Copy tae file 41
    01951819-406a-7154-b2cb-d7d284ce2538_01000 => mo-data/shared/01951819-406a-7154-b2cb-d7d284ce2538_01000
Copy tae file 42
    01951819-76a2-71fb-ac44-d5642546fe34_01000 => mo-data/shared/01951819-76a2-71fb-ac44-d5642546fe34_01000
Copy tae file 43
    01951819-a32e-7acf-b012-bb97a042ca2d_01000 => mo-data/shared/01951819-a32e-7acf-b012-bb97a042ca2d_01000
Copy tae file 44
    01951819-406a-7059-9733-7874c089a893_01000 => mo-data/shared/01951819-406a-7059-9733-7874c089a893_01000
Copy tae file 45
    01951819-4069-7ee0-9ab5-1c1efe83f588_01000 => mo-data/shared/01951819-4069-7ee0-9ab5-1c1efe83f588_01000
Copy tae file 46
    01951819-4069-7f0e-b304-153e49e0069b_01000 => mo-data/shared/01951819-4069-7f0e-b304-153e49e0069b_01000
Copy tae file 47
    01951819-406a-7008-8061-5fea348d23d7_01000 => mo-data/shared/01951819-406a-7008-8061-5fea348d23d7_01000
Copy tae file 48
    01951819-4069-7eb3-af42-8fdaaa0dbb94_01000 => mo-data/shared/01951819-4069-7eb3-af42-8fdaaa0dbb94_01000
Copy tae file 49
    01951819-4069-7f01-af76-23ec905fdc40_01000 => mo-data/shared/01951819-4069-7f01-af76-23ec905fdc40_01000
Copy tae file 50
    01951819-406a-711b-bd6b-18423ff5cb2d_01000 => mo-data/shared/01951819-406a-711b-bd6b-18423ff5cb2d_01000
Copy tae file 51
    01951819-406a-7142-9455-c994eb027a88_01000 => mo-data/shared/01951819-406a-7142-9455-c994eb027a88_01000
Copy tae file 52
    01951819-406a-7171-9697-88aa01744cc1_01000 => mo-data/shared/01951819-406a-7171-9697-88aa01744cc1_01000
Copy tae file 53
    01951819-7d9e-7eab-9736-575caca8fb82_01000 => mo-data/shared/01951819-7d9e-7eab-9736-575caca8fb82_01000
Copy tae file 54
    01951819-4069-7e5d-acea-9df786d9a9c3_01000 => mo-data/shared/01951819-4069-7e5d-acea-9df786d9a9c3_01000
Copy tae file 55
    01951819-4069-7eef-beb5-addd39b96400_01000 => mo-data/shared/01951819-4069-7eef-beb5-addd39b96400_01000
Copy tae file 56
    01951819-406a-7192-9cf2-67b6f9b2a87e_01000 => mo-data/shared/01951819-406a-7192-9cf2-67b6f9b2a87e_01000
Copy tae file 57
    01951819-4069-7f21-a718-5cdd3af34d83_01000 => mo-data/shared/01951819-4069-7f21-a718-5cdd3af34d83_01000
Copy tae file 58
    01951819-76c0-736f-8d1c-b28f4fdaba80_01000 => mo-data/shared/01951819-76c0-736f-8d1c-b28f4fdaba80_01000
Copy tae file 59
    01951819-406a-7025-98a0-6d64dc1858ed_01000 => mo-data/shared/01951819-406a-7025-98a0-6d64dc1858ed_01000
Copy tae file 60
    01951819-4069-7f39-b68c-7081e2cfed5a_01000 => mo-data/shared/01951819-4069-7f39-b68c-7081e2cfed5a_01000
Copy tae file 61
    01951819-4069-7ea2-808c-65dffa9e2400_01000 => mo-data/shared/01951819-4069-7ea2-808c-65dffa9e2400_01000
Copy tae file 62
    01951819-da77-704e-ba28-e32c54a9290d_00000 => mo-data/shared/01951819-da77-704e-ba28-e32c54a9290d_00000
Copy tae file 63
    01951819-da7a-7e37-8ef8-3849f302a0ac_00000 => mo-data/shared/01951819-da7a-7e37-8ef8-3849f302a0ac_00000
Copy tae file 64
    ckp/meta_1739866101719036581-1_1739866102134784726-0.ckp => mo-data/shared/ckp/meta_1739866101719036581-1_1739866102134784726-0.ckp
restore end file num: 64, cost: 250.145126ms
Copy hakeeper file 1
    hakeeper/hk_data => mo-data/local/hk_data
Hakeeper file path in the restore directory
    /data/mo/restore/mo-data/local/hk_data
2025-02-18 16:17:13.506 UTC+0800    [INFO]    Outcome: succeeded, cost: 283 ms
2025-02-18 16:17:13.552 UTC+0800    [INFO]    Restore ends with 0 rc
2025-02-18 16:17:13.557 UTC+0800    [INFO]    Step_2. Move mo-data path
2025-02-18 16:17:13.569 UTC+0800    [INFO]    Renaming /data/mo/2.0-dev/matrixone/mo-data to /data/mo/2.0-dev/matrixone/mo-data-bk-20250218_161713
2025-02-18 16:17:13.582 UTC+0800    [INFO]    Moving /data/mo/restore//mo-data to /data/mo/2.0-dev/matrixone/mo-data
2025-02-18 16:17:13.594 UTC+0800    [INFO]    Step_3. Restart mo
2025-02-18 16:17:13.629 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:17:13.634 UTC+0800    [INFO]    No need to stop mo-service
2025-02-18 16:17:13.640 UTC+0800    [INFO]    Stop succeeded
2025-02-18 16:17:13.645 UTC+0800    [INFO]    Wait for 2 seconds
2025-02-18 16:17:15.665 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:17:15.680 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="git"
2025-02-18 16:17:15.687 UTC+0800    [INFO]    GO memory limit(Mi): 9542
2025-02-18 16:17:15.697 UTC+0800    [INFO]    Starting mo-service: cd /data/mo/2.0-dev/matrixone/ && GOMEMLIMIT=9542MiB /data/mo/2.0-dev/matrixone/mo-service -daemon -debug-http :9876  -launch /data/mo/2.0-dev/matrixone/etc/launch/launch.toml >/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/stdout-20250218_161715.log 2>/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/stderr-20250218_161715.log
2025-02-18 16:17:15.731 UTC+0800    [INFO]    Wait for 2 seconds
2025-02-18 16:17:17.751 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3501330       1 11 16:17 ?        00:00:00 /data/mo/2.0-dev/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/2.0-dev/matrixone/etc/launch/launch.toml
2025-02-18 16:17:17.756 UTC+0800    [INFO]    List of pid(s): 
3501330
2025-02-18 16:17:17.762 UTC+0800    [INFO]    Start succeeded

github@shpc2-10-222-1-9:/data$ mo_ctl status
2025-02-18 16:17:32.854 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3501330       1  9 16:17 ?        00:00:01 /data/mo/2.0-dev/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/2.0-dev/matrixone/etc/launch/launch.toml
2025-02-18 16:17:32.859 UTC+0800    [INFO]    List of pid(s): 
3501330

github@shpc2-10-222-1-9:/data$ mo_ctl sql "show databases; show tables in test; select * from test.t1;"
2025-02-18 16:17:49.087 UTC+0800    [INFO]    Input "show databases; show tables in test; select * from test.t1;" is not a path or a file, try to execute it as a query
2025-02-18 16:17:49.092 UTC+0800    [INFO]    Begin executing query "show databases; show tables in test; select * from test.t1;"
--------------
show databases
--------------

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mo_catalog         |
| mo_debug           |
| mo_task            |
| mysql              |
| system             |
| system_metrics     |
| test               |
+--------------------+
8 rows in set (0.00 sec)

--------------
show tables in test
--------------

+----------------+
| Tables_in_test |
+----------------+
| t1             |
+----------------+
1 row in set (0.00 sec)

--------------
select * from test.t1
--------------

+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.01 sec)

Bye
2025-02-18 16:17:49.112 UTC+0800    [INFO]    End executing query show databases; show tables in test; select * from test.t1;, succeeded
2025-02-18 16:17:49.121 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
show databases; show tables in test; select * from test.t1;,succeeded,13

```

### 4.2 逻辑备份还原
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl sql "show databases; show tables in test; select * from test.t1;"
2025-02-18 16:22:55.554 UTC+0800    [INFO]    Input "show databases; show tables in test; select * from test.t1;" is not a path or a file, try to execute it as a query
2025-02-18 16:22:55.560 UTC+0800    [INFO]    Begin executing query "show databases; show tables in test; select * from test.t1;"
--------------
show databases
--------------

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mo_catalog         |
| mo_debug           |
| mo_task            |
| mysql              |
| system             |
| system_metrics     |
| test               |
+--------------------+
8 rows in set (0.00 sec)

--------------
show tables in test
--------------

+----------------+
| Tables_in_test |
+----------------+
| t1             |
+----------------+
1 row in set (0.00 sec)

--------------
select * from test.t1
--------------

+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.00 sec)

Bye
2025-02-18 16:22:55.578 UTC+0800    [INFO]    End executing query show databases; show tables in test; select * from test.t1;, succeeded
2025-02-18 16:22:55.588 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
show databases; show tables in test; select * from test.t1;,succeeded,12

github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_TYPE=logical
2025-02-18 16:25:25.602 UTC+0800    [INFO]    Try to set conf: BACKUP_TYPE="logical"
2025-02-18 16:25:25.617 UTC+0800    [INFO]    Setting conf BACKUP_TYPE="logical"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_MODUMP_PATH=/data/tools/mo_dump/mo-dump
2025-02-18 16:25:27.075 UTC+0800    [INFO]    Try to set conf: BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
2025-02-18 16:25:27.087 UTC+0800    [INFO]    Setting conf BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_LOGICAL_DATA_TYPE="insert"
2025-02-18 16:25:35.049 UTC+0800    [INFO]    Try to set conf: BACKUP_LOGICAL_DATA_TYPE="insert"
2025-02-18 16:25:35.063 UTC+0800    [INFO]    Setting conf BACKUP_LOGICAL_DATA_TYPE="insert"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_LOGICAL_DS="mydb"
2025-02-18 16:25:40.741 UTC+0800    [INFO]    Try to set conf: BACKUP_LOGICAL_DS="mydb"
2025-02-18 16:25:40.753 UTC+0800    [INFO]    Setting conf BACKUP_LOGICAL_DS="mydb"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_DATA_PATH="/data/mo-backup"
2025-02-18 16:25:48.841 UTC+0800    [INFO]    Try to set conf: BACKUP_DATA_PATH="/data/mo-backup"
2025-02-18 16:25:48.854 UTC+0800    [INFO]    Setting conf BACKUP_DATA_PATH="/data/mo-backup"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_LOGICAL_DB_LIST=test
2025-02-18 16:26:09.147 UTC+0800    [INFO]    Try to set conf: BACKUP_LOGICAL_DB_LIST="test"
2025-02-18 16:26:09.159 UTC+0800    [INFO]    Setting conf BACKUP_LOGICAL_DB_LIST="test"

github@shpc2-10-222-1-9:/data$ mo_ctl backup
2025-02-18 16:26:09.858 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-02-18 16:26:09.877 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3501330       1 11 16:17 ?        00:01:03 /data/mo/2.0-dev/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/2.0-dev/matrixone/etc/launch/launch.toml
2025-02-18 16:26:09.882 UTC+0800    [INFO]    List of pid(s): 
3501330
2025-02-18 16:26:09.888 UTC+0800    [INFO]    Backup settings
2025-02-18 16:26:09.893 UTC+0800    [INFO]    ------------------------------------
BACKUP_TYPE="logical"
BACKUP_CRON_SCHEDULE="30 23 * * *"
BACKUP_DATA_PATH="/data/mo-backup"
BACKUP_CLEAN_DAYS_BEFORE="31"
BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"
BACKUP_REPORT="${TOOL_LOG_PATH}/backup/report.txt"
BACKUP_MOBR_PATH="/data/tools/mo-backup/mo_br"
BACKUP_PHYSICAL_TYPE="filesystem"
BACKUP_S3_ENDPOINT=""
BACKUP_S3_ID=""
BACKUP_S3_KEY=""
BACKUP_S3_BUCKET=""
BACKUP_S3_REGION=""
BACKUP_S3_COMPRESSION=""
BACKUP_S3_ROLE_ARN=""
BACKUP_S3_IS_MINIO="no"
BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
BACKUP_LOGICAL_DB_LIST="test"
BACKUP_LOGICAL_TBL_LIST=""
BACKUP_LOGICAL_DATA_TYPE="insert"
BACKUP_LOGICAL_ONEBYONE="0"
BACKUP_LOGICAL_NETBUFLEN="1048576"
BACKUP_LOGICAL_DS="mydb"
2025-02-18 16:26:09.905 UTC+0800    [INFO]    ------------------------------------
2025-02-18 16:26:09.910 UTC+0800    [INFO]    Backup begins
2025-02-18 16:26:09.939 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-02-18 16:26:09.974 UTC+0800    [INFO]    BACKUP_LOGICAL_TBL_LIST is empty, will not add -tbl option
2025-02-18 16:26:10.009 UTC+0800    [INFO]    End with outcome: succeeded, cost: 18 ms
2025-02-18 16:26:10.032 UTC+0800    [INFO]    Backup ends with 0 rc

github@shpc2-10-222-1-9:/data$ ll /data/mo-backup/202502/20250218_16
20250218_160820/ 20250218_162411/ 20250218_162420/ 20250218_162554/ 20250218_162609/ 
github@shpc2-10-222-1-9:/data$ ll /data/mo-backup/202502/20250218_162609/
total 4
-rw-r--r-- 1 github github 281 Feb 18 16:26 test.sql
github@shpc2-10-222-1-9:/data$ mo_ctl sql "drop database test; show databases;"
2025-02-18 16:27:23.401 UTC+0800    [INFO]    Input "drop database test; show databases;" is not a path or a file, try to execute it as a query
2025-02-18 16:27:23.406 UTC+0800    [INFO]    Begin executing query "drop database test; show databases;"
--------------
drop database test
--------------

Query OK, 1 row affected (0.02 sec)

--------------
show databases
--------------

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mo_catalog         |
| mo_debug           |
| mo_task            |
| mysql              |
| system             |
| system_metrics     |
+--------------------+
7 rows in set (0.00 sec)

Bye
2025-02-18 16:27:23.441 UTC+0800    [INFO]    End executing query drop database test; show databases;, succeeded
2025-02-18 16:27:23.450 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
drop database test; show databases;,succeeded,28


github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_TYPE=logical  # 设置还原类型为逻辑还原
2025-02-18 16:28:46.151 UTC+0800    [INFO]    Try to set conf: RESTORE_TYPE="logical"
2025-02-18 16:28:46.163 UTC+0800    [INFO]    Setting conf RESTORE_TYPE="logical"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf BACKUP_MODUMP_PATH=/data/tools/mo_dump/mo-dump # 逻辑备份还原工具的路径
2025-02-18 16:28:49.038 UTC+0800    [INFO]    Try to set conf: BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
2025-02-18 16:28:49.050 UTC+0800    [INFO]    Setting conf BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_LOGICAL_SRC=/data/mo-backup/202502/20250218_162609/test.sql
2025-02-18 16:29:04.882 UTC+0800    [INFO]    Try to set conf: RESTORE_LOGICAL_SRC="/data/mo-backup/202502/20250218_162609/test.sql"
2025-02-18 16:29:04.894 UTC+0800    [INFO]    Setting conf RESTORE_LOGICAL_SRC="/data/mo-backup/202502/20250218_162609/test.sql"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_LOGICAL_DB=test
2025-02-18 16:29:35.935 UTC+0800    [INFO]    Try to set conf: RESTORE_LOGICAL_DB="test"
2025-02-18 16:29:35.947 UTC+0800    [INFO]    Setting conf RESTORE_LOGICAL_DB="test"
github@shpc2-10-222-1-9:/data$ mo_ctl set_conf RESTORE_LOGICAL_TYPE=insert
2025-02-18 16:29:39.784 UTC+0800    [INFO]    Try to set conf: RESTORE_LOGICAL_TYPE="insert"
2025-02-18 16:29:39.795 UTC+0800    [INFO]    Setting conf RESTORE_LOGICAL_TYPE="insert"

github@shpc2-10-222-1-9:/data$ mo_ctl restore
2025-02-18 16:30:40.346 UTC+0800    [INFO]    Current confs:
MO_PATH="/data/mo/2.0-dev"
MO_DEPLOY_MODE="git"
MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
RESTORE_TYPE="logical"
RESTORE_PATH="/data/mo/restore/"
RESTORE_REPORT="${TOOL_LOG_PATH}/restore-report.txt"
RESTORE_PHYSICAL_TYPE="filesystem"
RESTORE_BKID="01951819-d7b6-7bc1-8a58-93fa2c4d8343"
RESTORE_S3_ENDPOINT=""
RESTORE_S3_ID=""
RESTORE_S3_KEY=""
RESTORE_S3_BUCKET=""
RESTORE_S3_REGION=""
RESTORE_S3_COMPRESSION=""
RESTORE_S3_ROLE_ARN=""
RESTORE_S3_IS_MINIO="no"
RESTORE_LOGICAL_DB="test"
RESTORE_LOGICAL_SRC="/data/mo-backup/202502/20250218_162609/test.sql"
RESTORE_LOGICAL_TYPE="insert"
2025-02-18 16:30:40.357 UTC+0800    [WARN]    Please make sure if you really want to perform a restore(Yes/No):
yes
2025-02-18 16:30:41.222 UTC+0800    [INFO]    Check mo connectivity
2025-02-18 16:30:41.227 UTC+0800    [INFO]    Input "show databases;select version(); select git_version();" is not a path or a file, try to execute it as a query
2025-02-18 16:30:41.232 UTC+0800    [INFO]    Begin executing query "show databases;select version(); select git_version();"
--------------
show databases
--------------

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mo_catalog         |
| mo_debug           |
| mo_task            |
| mysql              |
| system             |
| system_metrics     |
| test               |
+--------------------+
8 rows in set (0.00 sec)

--------------
select version()
--------------

+-------------------------+
| version()               |
+-------------------------+
| 8.0.30-MatrixOne-v2.0.2 |
+-------------------------+
1 row in set (0.00 sec)

--------------
select git_version()
--------------

+---------------+
| git_version() |
+---------------+
| 1f1414906     |
+---------------+
1 row in set (0.00 sec)

Bye
2025-02-18 16:30:41.248 UTC+0800    [INFO]    End executing query show databases;select version(); select git_version();, succeeded
2025-02-18 16:30:41.258 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
show databases;select version(); select git_version();,succeeded,10
2025-02-18 16:30:41.263 UTC+0800    [INFO]    Restore settings
2025-02-18 16:30:41.268 UTC+0800    [INFO]    ------------------------------------
RESTORE_TYPE="logical"
RESTORE_PATH="/data/mo/restore/"
RESTORE_REPORT="${TOOL_LOG_PATH}/restore-report.txt"
RESTORE_PHYSICAL_TYPE="filesystem"
RESTORE_BKID="01951819-d7b6-7bc1-8a58-93fa2c4d8343"
RESTORE_S3_ENDPOINT=""
RESTORE_S3_ID=""
RESTORE_S3_KEY=""
RESTORE_S3_BUCKET=""
RESTORE_S3_REGION=""
RESTORE_S3_COMPRESSION=""
RESTORE_S3_ROLE_ARN=""
RESTORE_S3_IS_MINIO="no"
RESTORE_LOGICAL_DB="test"
RESTORE_LOGICAL_SRC="/data/mo-backup/202502/20250218_162609/test.sql"
RESTORE_LOGICAL_TYPE="insert"
2025-02-18 16:30:41.280 UTC+0800    [INFO]    ------------------------------------
2025-02-18 16:30:41.285 UTC+0800    [INFO]    Step_1. Restore logical data
2025-02-18 16:30:41.290 UTC+0800    [INFO]    RESTORE_LOGICAL_DB=test is not empty, will add database name when restoring data
2025-02-18 16:30:41.296 UTC+0800    [INFO]    RESTORE_LOGICAL_SRC=/data/mo-backup/202502/20250218_162609/test.sql is a file
2025-02-18 16:30:41.301 UTC+0800    [INFO]    Restore begins, please wait
2025-02-18 16:30:41.354 UTC+0800    [INFO]    Number: 1, file: /data/mo-backup/202502/20250218_162609/test.sql, outcome: succeeded, cost: 34 ms
2025-02-18 16:30:41.377 UTC+0800    [INFO]    -------------------------
2025-02-18 16:30:41.382 UTC+0800    [INFO]             Summary         
2025-02-18 16:30:41.388 UTC+0800    [INFO]    Total: 0, failed: 0
2025-02-18 16:30:41.393 UTC+0800    [INFO]    -------------------------
2025-02-18 16:30:41.399 UTC+0800    [INFO]    Restore ends with 0 rc

github@shpc2-10-222-1-9:/data$ mo_ctl sql "show tables in test; select * from test.t1;"
2025-02-18 16:30:54.853 UTC+0800    [INFO]    Input "show tables in test; select * from test.t1;" is not a path or a file, try to execute it as a query
2025-02-18 16:30:54.858 UTC+0800    [INFO]    Begin executing query "show tables in test; select * from test.t1;"
--------------
show tables in test
--------------

+----------------+
| Tables_in_test |
+----------------+
| t1             |
+----------------+
1 row in set (0.00 sec)

--------------
select * from test.t1
--------------

+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.00 sec)

Bye
2025-02-18 16:30:54.876 UTC+0800    [INFO]    End executing query show tables in test; select * from test.t1;, succeeded
2025-02-18 16:30:54.886 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
show tables in test; select * from test.t1;,succeeded,11

```

