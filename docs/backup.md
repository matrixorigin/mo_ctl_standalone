# mo_ctl backup
## 1. 作用
备份您的mo数据库实例的数据。

## 2. 用法
```bash
mo_ctl backup [help | list] [detail]
```

查看帮助示例输出
```bash
root@shpc3-10-222-1-8:~# mo_ctl backup help
Usage         : mo_ctl backup             # create a backup of your databases manually
              : mo_ctl backup help        # print help info
              : mo_ctl backup list        # list backup report in summary
              : mo_ctl backup list detail # list backup report in detail(physical only)
  Note          : currently only supported on linux systems
                : please set below configurations first before you run the [enable] option
  ------------------------- 
   1. Common settings       
  ------------------------- 
    1) BACKUP_DATA_PATH [default: /data/mo-backup]: backup data path in filesystem or s3. e.g. mo_ctl set_conf BACKUP_DATA_PATH=/data/mo-backup
    2) BACKUP_TYPE [default: physical]: backup type choose from "physical" | "logical". e.g. mo_ctl set_conf BACKUP_TYPE="logical"
    3) BACKUP_CRON_SCHEDULE [default: 30 23 * * *]: cron expression to control backup schedule time and frequency, in standard cron format (https://crontab.guru/). e.g. mo_ctl set_conf BACKUP_TYPE="30 23 * * *"
    4) BACKUP_CLEAN_DAYS_BEFORE [default: 31]: clean old backup files before [x] days. e.g. mo_ctl set_conf BACKUP_CLEAN_DAYS_BEFORE=31
    5) BACKUP_CLEAN_CRON_SCHEDULE [default: 0 6 * * *]: cron to control auto clean of old backups. e.g. mo_ctl set_conf BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"

  ------------------------- 
   2. For physical backups  
  ------------------------- 
    1) BACKUP_MOBR_PATH [default: /data/tools/mo-backup/mo_br]: Path to mo_br backup tool
    2) BACKUP_PHYSICAL_TYPE [default: filesystem]: target backup storage type, choose from "filesystem" | "s3"
      if BACKUP_PHYSICAL_TYPE=s3
        a) BACKUP_S3_ENDPOINT [default: '']: s3 endpoint, e.g. https://cos.ap-nanjing.myqcloud.com
        b) BACKUP_S3_ID [default: '']: s3 id, e.g. B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k
        c) BACKUP_S3_KEY [default: '']: s3 key, e.g. QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j
        d) BACKUP_S3_BUCKET [default: '']: s3 bucket, e.g. mybucket
        e) BACKUP_S3_REGION [default: '']: s3 region, e.g. ap-nanjing
        f) BACKUP_S3_COMPRESSION [default: '']: s3 compression
        g) BACKUP_S3_ROLE_ARN [default: '']: s3 role arn
        h) BACKUP_S3_IS_MINIO [default: 'no']: is minio type or not, choose from "no" | "yes"

  ------------------------- 
   3. For logical backups  
  ------------------------- 
    1) BACKUP_MODUMP_PATH [default: /data/tools/mo_dump/mo-dump]: Path to mo-dump backup tool
    2) BACKUP_LOGICAL_DB_LIST [OPTIONAL, default: all_no_sysdb]: (only valid when BACKUP_TYPE=logical) backup databases, seperated by ',' for each database.
       Note: 'all' and 'all_no_sysdb' are special settings. e.g. mo_ctl set_conf BACKUP_DB_LIST="db1,db2,db3"
         a) all: all databases, including all system and user databases
         b) all_no_sysdb: all databases, including all user databases, but no system databases
         c) other settings by user: e.g. db1,db2,db3
    3) BACKUP_LOGICAL_DATA_TYPE [OPTIONAL, default: csv]: (only valid when BACKUP_TYPE=logical) backup data type, choose from: insert | csv . e.g. mo_ctl set_conf BACKUP_DATA_TYPE="csv"
    4) BACKUP_LOGICAL_ONEBYONE [OPTIONAL, default: 0]: (only valid when BACKUP_TYPE=logical) backup databases/tables one by one? choose from: 0 | 1
```


## 3. 前提条件
在执行`mo_ctl backup`进行备份前，请务必参考**帮助说明**和**示例**指引，先进行相关参数的设置，再进行备份操作。

## 4. 示例
### 4.1. 列举备份历史
显示历史的备份操作记录。
```bash
mo_ctl backup list [detail]
```
示例输出：
1. 不加`detail`参数，显示一般的信息，包括`备份日期`、`备份源系统连接串`、`数据集名称`、`数据库清单`、`备份类型`、`备份路径`、`逻辑备份数据类型`、`备份耗时`、`备份是否成功`、`备份数据大小`、`逻辑备份缓冲区大小`等。
```bash
root@shpc3-10-222-1-8:~# mo_ctl backup list
backup_date|backup_target|ds_name|db_list|backup_type|backup_path|logical_data_type|duration_ms|outcome|bk_size_in_bytes|logical_net_buffer_length
20240624_132225|127.0.0.1,6001,dump||all|physical|/data/mo-backup-reg/data-bk/202406/20240624_132225|n.a.|824|succeeded|2092|n.a.
```

2. 在设置`BACKUP_TYPE`=`physical`的前提条件下，加`detail`参数可以查看更多的备份信息，包括`物理备份ID`、`备份数据大小`、`备份介质类型和路径`、`备份开始时间`、`备份耗时`、`备份完成时间`等。
```bash
github@shpc3-10-222-1-8:~$ mo_ctl backup list detail
+--------------------------------------+--------+-----------------------------------------------------+---------------------------+--------------+---------------------------+
|                  ID                  |  SIZE  |                        PATH                         |          AT TIME          |   DURATION   |       COMPLETE TIME       |
+--------------------------------------+--------+-----------------------------------------------------+---------------------------+--------------+---------------------------+
| 34594659-23cb-11ef-a919-7486e22ce4c0 | 13 MB  |            BackupDir: filesystem  Path:             | 2024-06-06 14:08:31 +0800 | 2.434269511s | 2024-06-06 14:08:33 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240606_140830/ |                           |              |                           |
| b7b3e919-23cb-11ef-8842-7486e22ce4c0 | 14 MB  |            BackupDir: filesystem  Path:             | 2024-06-06 14:12:11 +0800 | 2.442422506s | 2024-06-06 14:12:13 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240606_141211/ |                           |              |                           |
| fd8359ff-2d3e-11ef-8cb9-7486e22ce4c0 | 1.1 GB |            BackupDir: filesystem  Path:             | 2024-06-18 14:49:59 +0800 | 4.059283732s | 2024-06-18 14:50:03 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240618_144959/ |                           |              |                           |
| 2265efc5-2d52-11ef-9def-7486e22ce4c0 | 1.1 GB |            BackupDir: filesystem  Path:             | 2024-06-18 17:07:02 +0800 | 3.772525992s | 2024-06-18 17:07:05 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240618_170701/ |                           |              |                           |
| 083554ee-2ed2-11ef-ac21-7486e22ce4c0 | 1.3 MB |            BackupDir: filesystem  Path:             | 2024-06-20 14:55:07 +0800 | 789.573755ms | 2024-06-20 14:55:08 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240620_145507/ |                           |              |                           |
| 84bad290-2eef-11ef-a62c-7486e22ce4c0 | 1.7 MB |            BackupDir: filesystem  Path:             | 2024-06-20 18:26:12 +0800 | 798.048763ms | 2024-06-20 18:26:13 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240620_182612/ |                           |              |                           |
| d1508076-2f80-11ef-8997-7486e22ce4c0 | 2.5 MB |            BackupDir: filesystem  Path:             | 2024-06-21 11:46:17 +0800 | 796.940568ms | 2024-06-21 11:46:18 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240621_114617/ |                           |              |                           |
| be4b8cd8-31e9-11ef-978d-7486e22ce4c0 | 1.5 MB |            BackupDir: filesystem  Path:             | 2024-06-24 13:22:25 +0800 | 800.612277ms | 2024-06-24 13:22:26 +0800 |
|                                      |        | /data/mo-backup-reg/data-bk/202406/20240624_132225/ |                           |              |                           |
+--------------------------------------+--------+-----------------------------------------------------+---------------------------+--------------+---------------------------+
```
### 4.2 逻辑备份
备份前，请先设置与逻辑备份相关的参数
```bash
mo_ctl set_conf BACKUP_DATA_PATH=/data/mo-backup
mo_ctl set_conf 
  1) BACKUP_DATA_PATH [default: /data/mo-backup]: backup data path in filesystem or s3. e.g. mo_ctl set_conf BACKUP_DATA_PATH=/data/mo-backup
    2) BACKUP_TYPE [default: physical]: backup type choose from "physical" | "logical". e.g. mo_ctl set_conf BACKUP_TYPE="logical"
    3) BACKUP_CRON_SCHEDULE [default: 30 23 * * *]: cron expression to control backup schedule time and frequency, in standard cron format (https://crontab.guru/). e.g. mo_ctl set_conf BACKUP_TYPE="30 23 * * *"
    4) BACKUP_CLEAN_DAYS_BEFORE [default: 31]: clean old backup files before [x] days. e.g. mo_ctl set_conf BACKUP_CLEAN_DAYS_BEFORE=31
    5) BACKUP_CLEAN_CRON_SCHEDULE [default: 0 6 * * *]: cron to control auto clean of old backups. e.g. mo_ctl set_conf BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"


```

### 3) 物理备份
