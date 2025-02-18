# `backup`/`auto_backup`
## 1. 作用
手动或自动备份您的mo数据库实例的数据。

## 2. 用法
### 2.1. 手动备份
```bash
mo_ctl backup             # 手动备份
mo_ctl backup list        # 查看备份历史
mo_ctl backup list detail # 查看备份历史详细结果（物理备份适用）
```

### 2.2. 自动备份
```bash
Usage           : mo_ctl auto_backup [option]    # 设置自动备份
 [option]       : available: enable | disable | status
                : mo_ctl auto_backup             # 查看自动备份状态
                : mo_ctl auto_backup status      # 查看自动备份状态
  e.g.          : mo_ctl auto_backup enable      # 启用自动备份
                : mo_ctl auto_backup disable     # 禁用自动备份
```

查看帮助示例输出
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl backup help
Usage         : mo_ctl backup             # create a backup of your databases manually
              : mo_ctl backup list        # list backup report in summary
              : mo_ctl backup list detail # list backup report in detail(physical only)
```

```bash
github@shpc2-10-222-1-9:/data/mo/main/matrixone$ mo_ctl auto_backup help
Usage           : mo_ctl auto_backup [option]    # setup a crontab task to backup your databases automatically
 [option]       : available: enable | disable | status
                : mo_ctl auto_backup             # same as mo_ctl auto_backup status
                : mo_ctl auto_backup status      # check if auto backup is enabled or disabled
  e.g.          : mo_ctl auto_backup enable      # enable auto backup for your databases
                : mo_ctl auto_backup disable     # disable auto backup for your databases
```

```bash
Note         : Currently only supported on Linux. Please set below confs first
               ------------------------- 
                1. Common settings       
               ------------------------- 
               1) BACKUP_REPORT (optional, default: ${TOOL_LOG_PATH}/backup/report.txt): path to backup report file
               2) BACKUP_MOBR_META_PATH (optional, default: ${TOOL_LOG_PATH}/mo_br.meta): path to backup metadata file
               3) BACKUP_DATA_PATH (optional, default: /data/mo-backup): backup data path in filesystem or s3
               4) BACKUP_DATA_PATH_AUTO_TS (optional, default: yes): available: 'yes'|'no'. If 'yes', will add timestamp subpaths to backup data path, e.g. ${BACKUP_DATA_PATH}/202406/20240620_161838
               5) BACKUP_TYPE (optional, default: physical): available: 'physical' | 'logical'. Backup type
               ------------------------- 
                2. Auto backup settings       
               ------------------------- 
               1) BACKUP_CRON_SCHEDULE_FULL (optional, default: 30 23 * * *): for auto_backup of physical full type, cron expression to control backup schedule time and frequency, in standard cron format (https://crontab.guru/)
               2) BACKUP_CRON_SCHEDULE_INCREMENTAL (optional, default: */2 * * * *): for auto_backup of physical incremental type, same format as BACKUP_CRON_SCHEDULE_FULL
               3) BACKUP_CLEAN_DAYS_BEFORE (optional, default: 31): for auto_backup clean up, clean old backup files before [x] days
               4) BACKUP_CLEAN_CRON_SCHEDULE (optional, default: 0 6 * * *): for auto_backup clean up, cron to control auto clean of old backups

               ------------------------- 
                3. For physical backups  
               ------------------------- 
               1) BACKUP_MOBR_PATH (optional, default: /data/tools/mo-backup/mo_br): Path to mo_br backup tool
               2) BACKUP_PHYSICAL_METHOD (optional, default: full): available: full | incremental
                       full: perform a full data backup from scratch
                       incremental: perform an incremental data backup based on a full backup or incremental backup
               3) BACKUP_PHYSICAL_BASE_BKID (required, when BACKUP_PHYSICAL_METHOD=incremental): the backup id which incremental to be based on
               4) BACKUP_AUTO_SET_LAST_BKID (optional, default: yes): available: 'yes'|'no'. If 'yes', will automatically set BACKUP_PHYSICAL_BASE_BKID to last success backup id
               5) BACKUP_PHYSICAL_TYPE (optional, default: filesystem): target backup storage type, choose from "filesystem" | "s3"
               if BACKUP_PHYSICAL_TYPE=s3, please set below confs:
                 a) BACKUP_S3_ENDPOINT (optional, default: ''): s3 endpoint, e.g. https://cos.ap-nanjing.myqcloud.com
                 b) BACKUP_S3_ID (optional, default: ''): s3 id, e.g. B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k
                 c) BACKUP_S3_KEY (optional, default: ''): s3 key, e.g. QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j
                 d) BACKUP_S3_BUCKET (optional, default: ''): s3 bucket, e.g. mybucket
                 e) BACKUP_S3_REGION (optional, default: ''): s3 region, e.g. ap-nanjing
                 f) BACKUP_S3_COMPRESSION (optional, default: ''): s3 compression
                 g) BACKUP_S3_ROLE_ARN (optional, default: ''): s3 role arn
                 h) BACKUP_S3_IS_MINIO (optional, default: 'no'): is minio type or not, choose from "no" | "yes"

               ------------------------- 
                4. For logical backups  
               ------------------------- 
                 1) BACKUP_MODUMP_PATH (optional, default: /data/tools/mo_dump/mo-dump): Path to mo-dump backup tool
                 2) BACKUP_LOGICAL_DB_LIST (optional, default: all_no_sysdb): backup databases, seperated by ',' for each database. e.g. 'all' , 'all_no_sysdb' or 'db1,db2,db3'
                   Note: 'all' and 'all_no_sysdb' are special settings. 
                   a) all: all databases, including all system and user databases
                   b) all_no_sysdb: all databases, including all user databases, but no system databases
                   c) db1,db2,db3: example to backup db1, db2 and db3
                 3) BACKUP_LOGICAL_DATA_TYPE (optional, default: csv): available: insert | csv. Backup data type
                 4) BACKUP_LOGICAL_ONEBYONE (optional, default: 0): available: 0|1. If set to 1, will backup databases/tables one by one into multiple backup files.
                 5) BACKUP_LOGICAL_NETBUFLEN (optional, default: 1048576): backup net buffer length(bytes, integer), default: 1048576(1M) , max: 16777216(16M)
                 6) BACKUP_LOGICAL_DS (optional, default: none): backup logical dataset name: (optional) the dataset name of the backup database, e.g. myds_001
```

### 2.3. 清理旧备份
```bash
Usage           : mo_ctl clean_backup            # 清理旧备份
```

注意：请先设置好以下参数：
```bash
mo_ctl set_conf BACKUP_CLEAN_DAYS_BEFORE=31 # 可选，清理x天前的备份数据，默认值：31
```


## 3. 前提条件
在执行`mo_ctl backup`进行备份前，请务必参考**帮助说明**和**示例**指引，先进行相关参数的设置，再进行备份操作。

## 4. 示例
### 4.1 公共参数设置
备份前，请先设置一些公共的参数
```bash
mo_ctl set_conf BACKUP_REPORT="\${TOOL_LOG_PATH}/backup/report.txt" # 可选，备份报告的存储路径，默认值：${TOOL_LOG_PATH}/backup/report.txt
mo_ctl set_conf BACKUP_MOBR_META_PATH="\${TOOL_LOG_PATH}/mo_br.meta" # 可选，物理备份适用，mo_br工具所需的metadata元文件路径，默认值：${TOOL_LOG_PATH}/mo_br.meta
mo_ctl set_conf BACKUP_DATA_PATH=/data/mo-backup # 可选，数据备份文件存储路径（文件系统或S3），默认值：/data/mo-backup
mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS=yes # 可选，是否在备份文件存储路径添加时间戳的子目录，格式为${BACKUP_DATA_PATH}/202406/20240620_161838，可选值：yes（默认）|no
mo_ctl set_conf BACKUP_TYPE=logical # 必选，备份方式类型，可选值：physical（默认，物理备份） | logical（逻辑备份）。请根据需要选择对应的备份类型。
```

### 4.2 手动备份
#### 4.2.1 逻辑备份
备份前，请先设置与逻辑备份相关的参数
```bash
mo_ctl set_conf BACKUP_MODUMP_PATH=/data/tools/mo_dump/mo-dump  # 可选，mo_dump工具二进制文件的绝对路径，默认值：/data/tools/mo_dump/mo-dump
mo_ctl set_conf BACKUP_TYPE=logical # 必选，备份方式类型，可选值：physical（默认，物理备份） | logical（逻辑备份）
mo_ctl set_conf BACKUP_LOGICAL_DB_LIST=all_no_sysdb # 可选，备份的数据库清单，多个用英文逗号（,）分隔，例如：db1,db2,db3。特殊的的可选值：all | all_no_sysdb（默认），其中：all表示所有的数据库，all_no_sysdb表示除系统数据库（如mo_catalog、mysql等）外的所有数据库（一般理解为业务数据库的总和）
mo_ctl set_conf BACKUP_LOGICAL_DATA_TYPE=csv # 可选，逻辑备份方式类型，可选值：csv（csv文件+ddl/load语句） | insert（ddl/insert语句）
mo_ctl set_conf BACKUP_LOGICAL_NETBUFLEN=1048576 # 可选，备份数据时数据流大小（单位：字节，格式：整型），默认为：1048576(1M)，最大值为：16777216(16M)"
mo_ctl set_conf BACKUP_LOGICAL_DS=myds_001 # 可选，备份时报告写入的数据集的名称，取决于业务需求，默认为空
```

设置完成后，可以执行备份操作
```bash
mo_ctl backup
```

备份过程输出示例：
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl backup
2025-01-03 15:06:25.607 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-01-03 15:06:25.625 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github    324564       1 11 14:59 ?        00:00:49 /data/mo/main/matrixone/mo-service -daemon -debug-http :12345 -launch /data/mo/main/matrixone/etc/launch/launch.toml
2025-01-03 15:06:25.631 UTC+0800    [INFO]    List of pid(s): 
324564
2025-01-03 15:06:25.636 UTC+0800    [INFO]    Backup settings
2025-01-03 15:06:25.641 UTC+0800    [INFO]    ------------------------------------
BACKUP_SYSDB_LIST="mo_task,information_schema,mysql,system_metrics,system,mo_catalog,mo_debug"
BACKUP_TYPE="logical"
BACKUP_CRON_SCHEDULE="30 23 * * *"
BACKUP_DATA_PATH="/data/mo-backup-reg/data-bk"
BACKUP_DATA_PATH_AUTO_TS="yes"
BACKUP_CLEAN_DAYS_BEFORE="31"
BACKUP_CLEAN_CRON_SCHEDULE="0 7 * * *"
BACKUP_REPORT="/data/cus_reg/bk-and-restore/backup/report.txt"
BACKUP_MOBR_PATH="/data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br"
BACKUP_PHYSICAL_TYPE="filesystem"
BACKUP_MOBR_META_PATH="${TOOL_LOG_PATH}/mo_br.meta"
BACKUP_PHYSICAL_METHOD="incremental"
BACKUP_PHYSICAL_BASE_BKID="019279af-8485-7a9c-bf69-ce8c39c12adc"
BACKUP_PHYSICAL_PARALLEL_NUM=4
BACKUP_S3_ENDPOINT=""
BACKUP_S3_ID=""
BACKUP_S3_KEY=""
BACKUP_S3_BUCKET=""
BACKUP_S3_REGION=""
BACKUP_S3_COMPRESSION=""
BACKUP_S3_ROLE_ARN=""
BACKUP_S3_IS_MINIO="no"
BACKUP_MODUMP_PATH="/data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo_dump/mo-dump"
BACKUP_LOGICAL_DB_LIST="all_no_sysdb"
BACKUP_LOGICAL_TBL_LIST=""
BACKUP_LOGICAL_DATA_TYPE="csv"
BACKUP_LOGICAL_ONEBYONE="0"
BACKUP_LOGICAL_NETBUFLEN="1048576"
BACKUP_LOGICAL_DS="myds_001"
2025-01-03 15:06:25.653 UTC+0800    [INFO]    ------------------------------------
2025-01-03 15:06:25.658 UTC+0800    [INFO]    Backup begins
2025-01-03 15:06:25.664 UTC+0800    [DEBUG]    backup_outpath: /data/mo-backup-reg/data-bk/202501/20250103_150625
2025-01-03 15:06:25.669 UTC+0800    [DEBUG]    BACKUP_TYPE: logical, BACKUP_PHYSICAL_METHOD: incremental
2025-01-03 15:06:25.674 UTC+0800    [DEBUG]    Creating backup data direcory: mkdir -p /data/mo-backup-reg/data-bk/202501/20250103_150625
2025-01-03 15:06:25.681 UTC+0800    [DEBUG]    Creating backup report direcory: mkdir -p /data/cus_reg/bk-and-restore/backup
2025-01-03 15:06:25.686 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-01-03 15:06:25.699 UTC+0800    [DEBUG]    All databases in current system: information_schema
mo_catalog
mo_debug
mo_task
mysql
system
system_metrics
test
2025-01-03 15:06:25.709 UTC+0800    [DEBUG]    backup_db_list: test
2025-01-03 15:06:25.715 UTC+0800    [DEBUG]    backup_db_list=test seems to be one exact database, thus will take conf BACKUP_LOGICAL_TBL_LIST= into consideration
2025-01-03 15:06:25.721 UTC+0800    [DEBUG]    BACKUP_LOGICAL_ONEBYONE is not set to 1, will backup tables all at once
2025-01-03 15:06:25.726 UTC+0800    [INFO]    BACKUP_LOGICAL_TBL_LIST is empty, will not add -tbl option
2025-01-03 15:06:25.731 UTC+0800    [DEBUG]    Backup command: cd /data/mo-backup-reg/data-bk/202501/20250103_150625 && /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo_dump/mo-dump -net-buffer-length 1048576 -u dump -P 6001 -h 127.0.0.1 -p 111 -db test  -csv  > /data/mo-backup-reg/data-bk/202501/20250103_150625/test.sql && cd - >/dev/null 2>&1
2025-01-03 15:06:25.764 UTC+0800    [INFO]    End with outcome: succeeded, cost: 22 ms
2025-01-03 15:06:25.770 UTC+0800    [DEBUG]    Calculating size of backup path /data/mo-backup-reg/data-bk/202501/20250103_150625
2025-01-03 15:06:25.777 UTC+0800    [DEBUG]    Writing entry to report /data/cus_reg/bk-and-restore/backup/report.txt
2025-01-03 15:06:25.782 UTC+0800    [DEBUG]    20250103_150625||myds_001|all_no_sysdb|logical|/data/mo-backup-reg/data-bk/202501/20250103_150625|csv|22|succeeded|12|1048576
2025-01-03 15:06:25.787 UTC+0800    [INFO]    Backup ends with 0 rc
```

根据提示，可以查看输出的备份文件：
```bash
github@test0:/data/mo/main/matrixone$ ls -lth /data/mo-backup-reg/data-bk/202501/20250103_150625
total 8.0K
-rw-r--r-- 1 github github 526 Jan  3 15:06 test.sql
-rw-r--r-- 1 github github   2 Jan  3 15:06 test_t1.csv
github@test0:/data/mo/main/matrixone$ cat /data/mo-backup-reg/data-bk/202501/20250103_150625/test_t1.csv 
1
github@test0:/data/mo/main/matrixone$ cat /data/mo-backup-reg/data-bk/202501/20250103_150625/test.sql 
SET foreign_key_checks = 0;

DROP DATABASE IF EXISTS `test`;
CREATE DATABASE `test` ;
USE `test`;


DROP TABLE IF EXISTS `t1`;
CREATE TABLE `t1` (
  `id` int DEFAULT NULL
);
LOAD DATA LOCAL INFILE '/data/mo-backup-reg/data-bk/202501/20250103_150625/test_t1.csv' INTO TABLE `t1` FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' PARALLEL 'FALSE';
SET foreign_key_checks = 1;
/* MODUMP SUCCESS, COST 5.300031ms */
/* !!!MUST KEEP FILE IN CURRENT DIRECTORY, OR YOU SHOULD CHANGE THE PATH IN LOAD DATA STMT!!! */ 
```

#### 4.2.2 物理备份
备份前，请先设置与物理备份相关的参数
```bash
mo_ctl set_conf BACKUP_MOBR_PATH=/data/tools/mo-backup/mo_br # 可选，mo_br工具二进制文件的绝对路径，默认值：/data/tools/mo-backup/mo_br
mo_ctl set_conf BACKUP_TYPE=physical # 必选，备份方式类型，可选值：physical（默认，物理备份） | logical（逻辑备份）
mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full # 可选，物理备份方式类型，可选值：full（全量备份，默认）| incremental（增量备份）
mo_ctl set_conf BACKUP_PHYSICAL_BASE_BKID="" # 可选，当BACKUP_PHYSICAL_METHOD=incremental时，需要指定一个基准备份id，可以是一个全量备份的id，也可以是一个增量备份的id，该id在备份过程中会打印出来
mo_ctl set_conf BACKUP_AUTO_SET_LAST_BKID=yes # 可选，是否自动设置BACKUP_PHYSICAL_BASE_BKID为本次备份的id，可选值：yes（默认）|no
mo_ctl set_conf BACKUP_PHYSICAL_TYPE=filesystem # 备份目标存储介质，可选值：filesystem（本地已挂载的文件系统）|s3（对象存储，支持标准s3协议和minio）
mo_ctl set_conf BACKUP_PHYSICAL_PARALLEL_NUM=2 # 可选，物理备份并发度，默认：2

# 当BACKUP_PHYSICAL_TYPE设置为s3时，还需要设置s3相关的参数，如下：
mo_ctl set_conf BACKUP_S3_ENDPOINT="" # 可选，s3 endpoint，例如：https://cos.ap-nanjing.myqcloud.com，默认为空
mo_ctl set_conf BACKUP_S3_ID="" # 可选：s3 access key id，例如： B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k，默认为空
mo_ctl set_conf BACKUP_S3_KEY="" # 可选，s3 secret access key，例如：QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j，默认为空
mo_ctl set_conf BACKUP_S3_BUCKET="" # 可选，s3 桶名，例如：mybucket，默认为空
mo_ctl set_conf BACKUP_S3_REGION="" # 可选，s3 地域，例如：ap-nanjing，默认为空
mo_ctl set_conf BACKUP_S3_COMPRESSION="" # 可选，s3 压缩方式，默认为空
mo_ctl set_conf BACKUP_S3_ROLE_ARN="" # 可选，s3 role arn，默认为空
mo_ctl set_conf BACKUP_S3_IS_MINIO="no" # 可选，是否minio，可选值：no（默认）|yes
```
设置完成后，可以执行备份操作
```bash
mo_ctl backup
```

全量物理备份过程输出示例：
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full
2025-01-03 16:42:41.008 UTC+0800    [DEBUG]    conf list: BACKUP_PHYSICAL_METHOD=full
2025-01-03 16:42:41.016 UTC+0800    [INFO]    Try to set conf: BACKUP_PHYSICAL_METHOD="full"
2025-01-03 16:42:41.022 UTC+0800    [DEBUG]    key: BACKUP_PHYSICAL_METHOD, value: full
2025-01-03 16:42:41.028 UTC+0800    [INFO]    Setting conf BACKUP_PHYSICAL_METHOD="full"
github@test0:/data/mo/main/matrixone$ mo_ctl backup
2025-01-03 16:42:48.166 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-01-03 16:42:48.184 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github    324564       1 11 14:59 ?        00:12:11 /data/mo/main/matrixone/mo-service -daemon -debug-http :12345 -launch /data/mo/main/matrixone/etc/launch/launch.toml
2025-01-03 16:42:48.190 UTC+0800    [INFO]    List of pid(s): 
324564
2025-01-03 16:42:48.195 UTC+0800    [INFO]    Backup settings
2025-01-03 16:42:48.200 UTC+0800    [INFO]    ------------------------------------
BACKUP_SYSDB_LIST="mo_task,information_schema,mysql,system_metrics,system,mo_catalog,mo_debug"
BACKUP_TYPE="physical"
BACKUP_CRON_SCHEDULE="30 23 * * *"
BACKUP_DATA_PATH="/data/mo-backup-reg/data-bk"
BACKUP_DATA_PATH_AUTO_TS="yes"
BACKUP_CLEAN_DAYS_BEFORE="31"
BACKUP_CLEAN_CRON_SCHEDULE="0 7 * * *"
BACKUP_REPORT="/data/cus_reg/bk-and-restore/backup/report.txt"
BACKUP_MOBR_PATH="/data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br"
BACKUP_PHYSICAL_TYPE="filesystem"
BACKUP_MOBR_META_PATH="${TOOL_LOG_PATH}/mo_br.meta"
BACKUP_PHYSICAL_METHOD="full"
BACKUP_PHYSICAL_BASE_BKID="019279af-8485-7a9c-bf69-ce8c39c12adc"
BACKUP_PHYSICAL_PARALLEL_NUM="2"
BACKUP_AUTO_SET_LAST_BKID="yes"
BACKUP_S3_ENDPOINT=""
BACKUP_S3_ID=""
BACKUP_S3_KEY=""
BACKUP_S3_BUCKET=""
BACKUP_S3_REGION=""
BACKUP_S3_COMPRESSION=""
BACKUP_S3_ROLE_ARN=""
BACKUP_S3_IS_MINIO="no"
BACKUP_MODUMP_PATH="/data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo_dump/mo-dump"
BACKUP_LOGICAL_DB_LIST="all_no_sysdb"
BACKUP_LOGICAL_TBL_LIST=""
BACKUP_LOGICAL_DATA_TYPE="csv"
BACKUP_LOGICAL_ONEBYONE="0"
BACKUP_LOGICAL_NETBUFLEN="1048576"
BACKUP_LOGICAL_DS="myds_001"
2025-01-03 16:42:48.212 UTC+0800    [INFO]    ------------------------------------
2025-01-03 16:42:48.217 UTC+0800    [INFO]    Backup begins
2025-01-03 16:42:48.223 UTC+0800    [DEBUG]    backup_outpath: /data/mo-backup-reg/data-bk/202501/20250103_164248
2025-01-03 16:42:48.228 UTC+0800    [DEBUG]    BACKUP_TYPE: physical, BACKUP_PHYSICAL_METHOD: full
2025-01-03 16:42:48.233 UTC+0800    [DEBUG]    Creating backup data direcory: mkdir -p /data/mo-backup-reg/data-bk/202501/20250103_164248
2025-01-03 16:42:48.240 UTC+0800    [DEBUG]    Creating backup report direcory: mkdir -p /data/cus_reg/bk-and-restore/backup
2025-01-03 16:42:48.245 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-01-03 16:42:48.257 UTC+0800    [DEBUG]    BACKUP_MOBR_META_PATH is not empty, will add option --meta_path /data/logs/mo_ctl/mo_br.meta
2025-01-03 16:42:48.263 UTC+0800    [DEBUG]    Judging physical backup method(full or incremental): BACKUP_PHYSICAL_METHOD=full
2025-01-03 16:42:48.268 UTC+0800    [INFO]    Physical backup method: full
2025-01-03 16:42:48.274 UTC+0800    [DEBUG]    Backup command: cd /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup && /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br backup --meta_path /data/logs/mo_ctl/mo_br.meta --parallelism 2 --host 127.0.0.1 --port 6001 --user dump --password 111 --backup_dir filesystem --path /data/mo-backup-reg/data-bk/202501/20250103_164248 
Backup ID
    01942b54-d865-747c-a4b7-b8eedc96f7b6
2025-01-03 16:42:51.046 UTC+0800    [INFO]    End with outcome: succeeded, cost: 2760 ms
2025-01-03 16:42:51.051 UTC+0800    [DEBUG]    Calculating size of backup path /data/mo-backup-reg/data-bk/202501/20250103_164248
2025-01-03 16:42:51.058 UTC+0800    [DEBUG]    Writing entry to report /data/cus_reg/bk-and-restore/backup/report.txt
2025-01-03 16:42:51.063 UTC+0800    [DEBUG]    20250103_164248||myds_001|all|physical|/data/mo-backup-reg/data-bk/202501/20250103_164248|n.a.|2760|succeeded|12896|n.a.
2025-01-03 16:42:51.068 UTC+0800    [INFO]    Backup ends with 0 rc
2025-01-03 16:42:51.073 UTC+0800    [DEBUG]    BACKUP_AUTO_SET_LAST_BKID is set to 'yes', try to get last success backup id
2025-01-03 16:42:51.081 UTC+0800    [DEBUG]    conf list: BACKUP_PHYSICAL_BASE_BKID=01942b54-d865-747c-a4b7-b8eedc96f7b6
2025-01-03 16:42:51.088 UTC+0800    [INFO]    Try to set conf: BACKUP_PHYSICAL_BASE_BKID="01942b54-d865-747c-a4b7-b8eedc96f7b6"
2025-01-03 16:42:51.094 UTC+0800    [DEBUG]    key: BACKUP_PHYSICAL_BASE_BKID, value: 01942b54-d865-747c-a4b7-b8eedc96f7b6
2025-01-03 16:42:51.100 UTC+0800    [INFO]    Setting conf BACKUP_PHYSICAL_BASE_BKID="01942b54-d865-747c-a4b7-b8eedc96f7b6"
```

增量物理备份过程输出示例：
```bash
github@shpc2-10-222-1-9:/data/mo/main/matrixone$ mo_ctl set_conf BACKUP_PHYSICAL_METHOD=incremental
2025-01-03 16:43:19.130 UTC+0800    [DEBUG]    conf list: BACKUP_PHYSICAL_METHOD=incremental
2025-01-03 16:43:19.138 UTC+0800    [INFO]    Try to set conf: BACKUP_PHYSICAL_METHOD="incremental"
2025-01-03 16:43:19.144 UTC+0800    [DEBUG]    key: BACKUP_PHYSICAL_METHOD, value: incremental
2025-01-03 16:43:19.150 UTC+0800    [INFO]    Setting conf BACKUP_PHYSICAL_METHOD="incremental"
github@shpc2-10-222-1-9:/data/mo/main/matrixone$ mo_ctl backup
2025-01-03 16:43:19.874 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-01-03 16:43:19.893 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github    324564       1 11 14:59 ?        00:12:15 /data/mo/main/matrixone/mo-service -daemon -debug-http :12345 -launch /data/mo/main/matrixone/etc/launch/launch.toml
2025-01-03 16:43:19.898 UTC+0800    [INFO]    List of pid(s): 
324564
2025-01-03 16:43:19.904 UTC+0800    [INFO]    Backup settings
2025-01-03 16:43:19.909 UTC+0800    [INFO]    ------------------------------------
BACKUP_SYSDB_LIST="mo_task,information_schema,mysql,system_metrics,system,mo_catalog,mo_debug"
BACKUP_TYPE="physical"
BACKUP_CRON_SCHEDULE="30 23 * * *"
BACKUP_DATA_PATH="/data/mo-backup-reg/data-bk"
BACKUP_DATA_PATH_AUTO_TS="yes"
BACKUP_CLEAN_DAYS_BEFORE="31"
BACKUP_CLEAN_CRON_SCHEDULE="0 7 * * *"
BACKUP_REPORT="/data/cus_reg/bk-and-restore/backup/report.txt"
BACKUP_MOBR_PATH="/data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br"
BACKUP_PHYSICAL_TYPE="filesystem"
BACKUP_MOBR_META_PATH="${TOOL_LOG_PATH}/mo_br.meta"
BACKUP_PHYSICAL_METHOD="incremental"
BACKUP_PHYSICAL_BASE_BKID="01942b54-d865-747c-a4b7-b8eedc96f7b6"
BACKUP_PHYSICAL_PARALLEL_NUM="2"
BACKUP_AUTO_SET_LAST_BKID="yes"
BACKUP_S3_ENDPOINT=""
BACKUP_S3_ID=""
BACKUP_S3_KEY=""
BACKUP_S3_BUCKET=""
BACKUP_S3_REGION=""
BACKUP_S3_COMPRESSION=""
BACKUP_S3_ROLE_ARN=""
BACKUP_S3_IS_MINIO="no"
BACKUP_MODUMP_PATH="/data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo_dump/mo-dump"
BACKUP_LOGICAL_DB_LIST="all_no_sysdb"
BACKUP_LOGICAL_TBL_LIST=""
BACKUP_LOGICAL_DATA_TYPE="csv"
BACKUP_LOGICAL_ONEBYONE="0"
BACKUP_LOGICAL_NETBUFLEN="1048576"
BACKUP_LOGICAL_DS="myds_001"
2025-01-03 16:43:19.920 UTC+0800    [INFO]    ------------------------------------
2025-01-03 16:43:19.925 UTC+0800    [INFO]    Backup begins
2025-01-03 16:43:19.932 UTC+0800    [DEBUG]    backup_outpath: /data/mo-backup-reg/data-bk/202501/20250103_164319
2025-01-03 16:43:19.937 UTC+0800    [DEBUG]    BACKUP_TYPE: physical, BACKUP_PHYSICAL_METHOD: incremental
2025-01-03 16:43:19.942 UTC+0800    [DEBUG]    Creating backup report direcory: mkdir -p /data/cus_reg/bk-and-restore/backup
2025-01-03 16:43:19.948 UTC+0800    [INFO]    MO_HOST: 127.0.0.1
2025-01-03 16:43:19.960 UTC+0800    [DEBUG]    BACKUP_MOBR_META_PATH is not empty, will add option --meta_path /data/logs/mo_ctl/mo_br.meta
2025-01-03 16:43:19.966 UTC+0800    [DEBUG]    Judging physical backup method(full or incremental): BACKUP_PHYSICAL_METHOD=incremental
2025-01-03 16:43:19.971 UTC+0800    [INFO]    Physical backup method: incremental
2025-01-03 16:43:19.977 UTC+0800    [DEBUG]    BACKUP_PHYSICAL_BASE_BKID: 01942b54-d865-747c-a4b7-b8eedc96f7b6
2025-01-03 16:43:19.982 UTC+0800    [DEBUG]    BACKUP_MOBR_PATH: /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br
2025-01-03 16:43:19.987 UTC+0800    [DEBUG]    Try to get backup path of backup id 01942b54-d865-747c-a4b7-b8eedc96f7b6 from /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br
2025-01-03 16:43:19.992 UTC+0800    [DEBUG]    cmd: /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br list --meta_path /data/logs/mo_ctl/mo_br.meta | grep -A 1 01942b54-d865-747c-a4b7-b8eedc96f7b6 | tail -n 1 | awk -F  "|" '{print $4}' | sed 's/ //g'
2025-01-03 16:43:20.015 UTC+0800    [DEBUG]    real_bk_path: /data/mo-backup-reg/data-bk/202501/20250103_164248
2025-01-03 16:43:20.020 UTC+0800    [DEBUG]    backup_outpath: /data/mo-backup-reg/data-bk/202501/20250103_164248
2025-01-03 16:43:20.025 UTC+0800    [DEBUG]    Backup command: cd /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup && /data1/runner/_work/mo-nightly-regression/mo-nightly-regression/mo-backup/mo_br backup --meta_path /data/logs/mo_ctl/mo_br.meta --parallelism 2 --host 127.0.0.1 --port 6001 --user dump --password 111 --backup_dir filesystem --path /data/mo-backup-reg/data-bk/202501/20250103_164248 --backup_type incremental --base_id 01942b54-d865-747c-a4b7-b8eedc96f7b6
Backup ID
    01942b55-546b-7da4-a3af-303a907bcdfd
2025-01-03 16:43:20.947 UTC+0800    [INFO]    End with outcome: succeeded, cost: 911 ms
2025-01-03 16:43:20.953 UTC+0800    [DEBUG]    Calculating size of backup path /data/mo-backup-reg/data-bk/202501/20250103_164248
2025-01-03 16:43:20.960 UTC+0800    [DEBUG]    Writing entry to report /data/cus_reg/bk-and-restore/backup/report.txt
2025-01-03 16:43:20.965 UTC+0800    [DEBUG]    20250103_164319||myds_001|all|physical|/data/mo-backup-reg/data-bk/202501/20250103_164248|n.a.|911|succeeded|14204|n.a.
2025-01-03 16:43:20.970 UTC+0800    [INFO]    Backup ends with 0 rc
2025-01-03 16:43:20.975 UTC+0800    [DEBUG]    BACKUP_AUTO_SET_LAST_BKID is set to 'yes', try to get last success backup id
2025-01-03 16:43:20.983 UTC+0800    [DEBUG]    conf list: BACKUP_PHYSICAL_BASE_BKID=01942b55-546b-7da4-a3af-303a907bcdfd
2025-01-03 16:43:20.991 UTC+0800    [INFO]    Try to set conf: BACKUP_PHYSICAL_BASE_BKID="01942b55-546b-7da4-a3af-303a907bcdfd"
2025-01-03 16:43:20.997 UTC+0800    [DEBUG]    key: BACKUP_PHYSICAL_BASE_BKID, value: 01942b55-546b-7da4-a3af-303a907bcdfd
2025-01-03 16:43:21.002 UTC+0800    [INFO]    Setting conf BACKUP_PHYSICAL_BASE_BKID="01942b55-546b-7da4-a3af-303a907bcdfd"
```

根据提示，可以查看输出的备份文件：
```bash
github@shpc2-10-222-1-9:/data/mo/main/matrixone$ ls -lth /data/mo-backup-reg/data-bk/202501/20250103_164248
total 24K
-rw------- 1 github github  268 Jan  3 16:43 01942b55-546b-7da4-a3af-303a907bcdfd.meta
-rw------- 1 github github   32 Jan  3 16:43 01942b55-546b-7da4-a3af-303a907bcdfd.meta.sha256
drwxr-xr-x 5 github github 4.0K Jan  3 16:43 incremental-01942b55-546b-7da4-a3af-303a907bcdfd
-rw------- 1 github github   32 Jan  3 16:42 01942b54-d865-747c-a4b7-b8eedc96f7b6.meta.sha256
-rw------- 1 github github  254 Jan  3 16:42 01942b54-d865-747c-a4b7-b8eedc96f7b6.meta
drwxr-xr-x 5 github github 4.0K Jan  3 16:42 full-01942b54-d865-747c-a4b7-b8eedc96f7b6
```

### 4.3 自动备份
请先设置与自动备份相关的参数
```bash
mo_ctl set_conf BACKUP_CRON_SCHEDULE_FULL="30 23 * * *" # 可选，物理全量备份或逻辑备份的调度周期设置，遵循标准的crontab格式（参考：https://crontab.guru/），默认值：30 23 * * *，即每天23:30分执行一次全量物理备份或逻辑备份
mo_ctl set_conf BACKUP_CRON_SCHEDULE_INCREMENTAL="* */2 * * *" # 可选，物理增量备份的调度周期设置，格式同上，默认值：* */2 * * *，即每隔2小时执行一次增量物理备份
mo_ctl set_conf BACKUP_CLEAN_DAYS_BEFORE=31 # 可选，清理x天前的备份数据，默认值：31
mo_ctl set_conf BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"  # 可选，清理旧的备份数据的调度周期，格式同上，默认值：0 6 * * *，即每天6点清理旧备份数据
```

设置完成后，可以对自动备份进行`enable`（启用）、`status`（查看状态）、`disable`（禁用）等操作
```bash
mo_ctl auto_backup # 查看状态
mo_ctl auto_backup status # 查看状态
mo_ctl auto_backup enable # 启用
mo_ctl auto_backup disable # 禁用
```

***注意***：如果对自动备份的相关参数进行了修改，需要先`disable`再`enable`，新的参数才能重新生效

示例：

查看状态：
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl auto_backup
2025-01-03 17:00:37.917 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_backup for auto_backup does not exist
2025-01-03 17:00:37.922 UTC+0800    [INFO]    auto_backup status：disabled
2025-01-03 17:00:37.928 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup does not exist
2025-01-03 17:00:37.933 UTC+0800    [INFO]    auto_clean_old_backup status：disabled

github@test0:/data/mo/main/matrixone$ mo_ctl auto_backup status
2025-01-03 17:01:03.384 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_backup for auto_backup already exists, trying to get content: 
2025-01-03 17:01:03.390 UTC+0800    [DEBUG]     github ( /usr/local/bin/mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS=yes  && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
 github ( sleep 2 && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=incremental  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:01:03.395 UTC+0800    [INFO]    auto_backup status：enabled
2025-01-03 17:01:03.400 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup already exists, trying to get content: 
2025-01-03 17:01:03.406 UTC+0800    [DEBUG]    0 7 * * * github /usr/local/bin/mo_ctl clean_backup > /data/logs/mo_ctl/auto_clean_old_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S') 2>&1
2025-01-03 17:01:03.411 UTC+0800    [INFO]    auto_clean_old_backup status：enabled
```

启用：
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl auto_backup enable
2025-01-03 17:00:53.011 UTC+0800    [DEBUG]    Get status of service cron
2025-01-03 17:00:53.020 UTC+0800    [DEBUG]    Succeeded. Service cron seems to be running.
2025-01-03 17:00:53.026 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_backup for auto_backup does not exist
2025-01-03 17:00:53.031 UTC+0800    [INFO]    auto_backup status：disabled
2025-01-03 17:00:53.036 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup does not exist
2025-01-03 17:00:53.041 UTC+0800    [INFO]    auto_clean_old_backup status：disabled
2025-01-03 17:00:53.047 UTC+0800    [INFO]    Enabling auto_backup and auto_clean_old_backup
2025-01-03 17:00:53.052 UTC+0800    [DEBUG]    Creating log folder: mkdir -p /data/logs/mo_ctl/auto_backup/ /data/logs/mo_ctl/auto_clean_old_backup/
2025-01-03 17:00:53.057 UTC+0800    [INFO]    Creating cron file /etc/cron.d/mo_backup for auto_backup
2025-01-03 17:00:53.062 UTC+0800    [DEBUG]    Content:  github ( /usr/local/bin/mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS=yes  && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:00:53.083 UTC+0800    [INFO]    Succeeded
2025-01-03 17:00:53.092 UTC+0800    [INFO]    Creating cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup
2025-01-03 17:00:53.106 UTC+0800    [INFO]    Succeeded
2025-01-03 17:00:53.115 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_backup for auto_backup already exists, trying to get content: 
2025-01-03 17:00:53.120 UTC+0800    [DEBUG]     github ( /usr/local/bin/mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS=yes  && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
 github ( sleep 2 && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=incremental  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:00:53.126 UTC+0800    [INFO]    auto_backup status：enabled
2025-01-03 17:00:53.131 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup already exists, trying to get content: 
2025-01-03 17:00:53.137 UTC+0800    [DEBUG]    0 7 * * * github /usr/local/bin/mo_ctl clean_backup > /data/logs/mo_ctl/auto_clean_old_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S') 2>&1
2025-01-03 17:00:53.142 UTC+0800    [INFO]    auto_clean_old_backup status：enabled
```

禁用：
```bash
github@test0:/data/mo/main/matrixone$ mo_ctl auto_backup disable
2025-01-03 17:02:15.556 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_backup for auto_backup already exists, trying to get content: 
2025-01-03 17:02:15.562 UTC+0800    [DEBUG]     github ( /usr/local/bin/mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS=yes  && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
 github ( sleep 2 && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=incremental  && /usr/local/bin/mo_ctl backup ) >> /data/logs/mo_ctl/auto_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S').log 2>&1
2025-01-03 17:02:15.567 UTC+0800    [INFO]    auto_backup status：enabled
2025-01-03 17:02:15.573 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup already exists, trying to get content: 
2025-01-03 17:02:15.579 UTC+0800    [DEBUG]    0 7 * * * github /usr/local/bin/mo_ctl clean_backup > /data/logs/mo_ctl/auto_clean_old_backup/log.$(date '+\%Y\%m\%d_\%H\%M\%S') 2>&1
2025-01-03 17:02:15.584 UTC+0800    [INFO]    auto_clean_old_backup status：enabled
2025-01-03 17:02:15.590 UTC+0800    [INFO]    Disabling auto_backup by removing cron file /etc/cron.d/mo_backup
2025-01-03 17:02:15.599 UTC+0800    [INFO]    Succeeded
2025-01-03 17:02:15.605 UTC+0800    [INFO]    Disabling auto clean old backups by removing cron file /etc/cron.d/mo_clean_old_backup
2025-01-03 17:02:15.614 UTC+0800    [INFO]    Succeeded
2025-01-03 17:02:15.619 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_backup for auto_backup does not exist
2025-01-03 17:02:15.625 UTC+0800    [INFO]    auto_backup status：disabled
2025-01-03 17:02:15.630 UTC+0800    [DEBUG]    Cron file /etc/cron.d/mo_clean_old_backup for auto_clean_old_backup does not exist
2025-01-03 17:02:15.635 UTC+0800    [INFO]    auto_clean_old_backup status：disabled
```

查看自动清理任务的日志：
```bash
# 获取变量TOOL_LOG_PATH，查找工具日志的路径
github@shpc2-10-222-1-9:/data/logs/mo_ctl$ mo_ctl get_conf TOOL_LOG_PATH
2025-01-21 14:15:39.091 UTC+0800    [INFO]    Get conf succeeded: TOOL_LOG_PATH="/data/logs/mo_ctl"
github@shpc2-10-222-1-9:/data/logs/mo_ctl$ cd /data/logs/mo_ctl/
github@shpc2-10-222-1-9:/data/logs/mo_ctl$ ls -lthr
total 24K
drwxr-xr-x 2 github github 4.0K Oct  9 18:42 backup
-rwxr-xr-x 1 github github   64 Jan  3 16:43 mo_br.meta.sha256
-rwxr-xr-x 1 github github 3.7K Jan  3 16:43 mo_br.meta
drwxr-xr-x 2 github github 4.0K Jan  3 17:00 auto_clean_old_backup
drwxr-xr-x 2 github github 4.0K Jan  3 17:00 auto_backup
drwxr-xr-x 2 github github 4.0K Jan  3 17:28 auto_clean_logs
# 位于子目录auto_backup/ 和 auto_clean_old_backup
github@shpc2-10-222-1-9:/data/logs/mo_ctl$ cd auto_backup/
github@shpc2-10-222-1-9:/data/logs/mo_ctl$ cd ..
github@shpc2-10-222-1-9:/data/logs/mo_ctl$ cd auto_clean_old_backup/
```

### 4.4 列举备份历史
显示历史的备份操作记录。
```bash
mo_ctl backup list [detail]
```
示例输出：
1. 不加`detail`参数，显示一般的信息，包括`备份日期`、`备份源系统连接串`、`数据集名称`、`数据库清单`、`备份类型`、`备份路径`、`逻辑备份数据类型`、`备份耗时`、`备份是否成功`、`备份数据大小`、`逻辑备份缓冲区大小`等。
```bash
root@test0:~# mo_ctl backup list
20241119_163340|127.0.0.1,6001,dump|myds_001|mytestdb|logical|/data/mo-backup-reg/data-bk/202411/20241119_163340|csv|789928|succeeded|15494660|1048576
20241218_142202|127.0.0.1,6001,dump|myds_001|mytestdb|logical|/data/mo-backup-reg/data-bk/202412/20241218_142202|csv|729|failed|n.a.|1048576
20241218_142317|127.0.0.1,6001,dump|myds_001|all|physical|/data/bk-restore-test/bk/|n.a.|17|failed|n.a.|n.a.
20241218_142438|127.0.0.1,6001,dump|myds_001|all|physical|/data/bk-restore-test/bk/|n.a.|805|succeeded|1960|n.a.
20241218_142522|127.0.0.1,6001,dump|myds_001|all|physical|/data/bk-restore-test/bk/|n.a.|697|succeeded|3184|n.a.
20250103_150554|127.0.0.1,6001,dump|myds_001|mytestdb|logical|/data/mo-backup-reg/data-bk/202501/20250103_150554|csv|708|failed|n.a.|1048576
20250103_150625|127.0.0.1,6001,dump|myds_001|all_no_sysdb|logical|/data/mo-backup-reg/data-bk/202501/20250103_150625|csv|22|succeeded|12|1048576
20250103_162710|127.0.0.1,6001,dump|myds_001|all|physical|/data/bk-restore-test/bk/|n.a.|1591|succeeded|14032|n.a.
20250103_162731|127.0.0.1,6001,dump|myds_001|all|physical|/data/mo-backup-reg/data-bk/202501/20250103_162731|n.a.|1577|succeeded|10972|n.a.
20250103_162814|127.0.0.1,6001,dump|myds_001|all|physical|/data/bk-restore-test/bk/|n.a.|1632|succeeded|25188|n.a.
20250103_164248|127.0.0.1,6001,dump|myds_001|all|physical|/data/mo-backup-reg/data-bk/202501/20250103_164248|n.a.|2760|succeeded|12896|n.a.
20250103_164319|127.0.0.1,6001,dump|myds_001|all|physical|/data/mo-backup-reg/data-bk/202501/20250103_164248|n.a.|911|succeeded|14204|n.a.
```

2. 在设置`BACKUP_TYPE`=`physical`的前提条件下，加`detail`参数可以查看更多的备份信息，包括`物理备份ID`、`备份数据大小`、`备份介质类型和路径`、`备份开始时间`、`备份耗时`、`备份完成时间`等。
```bash
github@test0:~$ mo_ctl backup list detail
+--------------------------------------+--------+----------------------------------------------------+---------------------------+--------------+---------------------------+-----------------------+-------------+
|                  ID                  |  SIZE  |                        PATH                        |          AT TIME          |   DURATION   |       COMPLETE TIME       |       BACKUPTS        | BACKUPTYPE  |
+--------------------------------------+--------+----------------------------------------------------+---------------------------+--------------+---------------------------+-----------------------+-------------+
| 01942b54-d865-747c-a4b7-b8eedc96f7b6 | 12 MB  |            BackupDir: filesystem  Path:            | 2025-01-03 16:42:48 +0800 | 2.736081646s | 2025-01-03 16:42:51 +0800 | 1735893768313706438-1 |    full     |
|                                      |        | /data/mo-backup-reg/data-bk/202501/20250103_164248 |                           |              |                           |                       |             |
| 01942b55-546b-7da4-a3af-303a907bcdfd | 12 MB  |            BackupDir: filesystem  Path:            | 2025-01-03 16:43:20 +0800 | 887.311298ms | 2025-01-03 16:43:20 +0800 | 1735893800063297593-1 | incremental |
|                                      |        | /data/mo-backup-reg/data-bk/202501/20250103_164248 |                           |              |                           |                       |             |
+--------------------------------------+--------+----------------------------------------------------+---------------------------+--------------+---------------------------+-----------------------+-------------+
```

### 4.5 清理备份数据
以清理31天前的备份数据为例：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl clean_backup
2025-01-21 14:10:28.972 UTC+0800    [INFO]    Cleaning backups before 31 days
2025-01-21 14:10:28.978 UTC+0800    [INFO]    Clean date: 20241221
2025-01-21 14:10:28.989 UTC+0800    [INFO]    Backup directory : /data/mo-backup-reg/data-bk/202412/20241218_142202, action: delete
2025-01-21 14:10:28.995 UTC+0800    [INFO]    Succeeded
2025-01-21 14:10:29.003 UTC+0800    [INFO]    Backup directory : /data/mo-backup-reg/data-bk/202501/20250103_150554/20250103_150554, action: skip
2025-01-21 14:10:29.011 UTC+0800    [INFO]    Backup directory : /data/mo-backup-reg/data-bk/202501/20250103_150625/20250103_150625, action: skip
2025-01-21 14:10:29.018 UTC+0800    [INFO]    Backup directory : /data/mo-backup-reg/data-bk/202501/20250103_162731/20250103_162731, action: skip
2025-01-21 14:10:29.025 UTC+0800    [INFO]    Backup directory : /data/mo-backup-reg/data-bk/202501/20250103_164248/20250103_164248, action: skip
```

