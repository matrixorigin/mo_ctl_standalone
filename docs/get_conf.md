# `get_conf`
## 1. 作用
获取一个或多个`mo_ctl`工具的配置项和设置值。

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf help
Usage         : mo_ctl getconf [conf_list] # get configurations
Options       :
  [conf_list] : (optional, default: all) choose one of below
              : 1. use 'all' to print all confs
              : 2. one or multiple conf key names, seperated by comma, e.g. MO_HOST,MO_PORT
Examples      : mo_ctl getconf MO_PATH,MO_PW,MO_PORT  # get multiple configurations
              : mo_ctl getconf MO_PATH                # get single configuration
              : mo_ctl getconf all                    # get all configurations
              : mo_ctl getconf                        # get all configurations
```
## 3. 前提条件
无

## 4. 示例
获取单个配置项的值
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf MO_PATH
2025-01-21 14:45:50.565 UTC+0800    [INFO]    Get conf succeeded: MO_PATH="/data/cus_reg/mo/20250121_070243"
```

获取多个配置项的值
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf MO_PATH,MO_PW,MO_PORT
2025-01-21 14:44:26.391 UTC+0800    [INFO]    Get conf succeeded: MO_PATH="/data/cus_reg/mo/20250121_070243"
2025-01-21 14:44:26.398 UTC+0800    [INFO]    Get conf succeeded: MO_PW="111"
2025-01-21 14:44:26.404 UTC+0800    [INFO]    Get conf succeeded: MO_PORT="6001"
```

获取所有配置项的值
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf
2025-01-21 14:46:34.695 UTC+0800    [INFO]    Below are all configurations set in conf file /home/github/mo_ctl/conf/env.sh
TOOL_LOG_LEVEL="D"
TOOL_LOG_PATH="/data/logs/mo_ctl"
MO_MAKE_BUILD_GOTOOLCHAIN=""
MO_PATH="/data/cus_reg/mo/20250121_070243"
MO_LOG_PATH="/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs"
MO_CONF_SRC_PATH="/data/cus_reg/mo_confs/"
MO_SERVER_TYPE="local"
MO_HOST="127.0.0.1"
MO_PORT="6001"
MO_USER="dump"
MO_PW="111"
MO_DEPLOY_MODE="git"
MO_REPO="matrixorigin/matrixone"
MO_CONTAINER_IMAGE="matrixone:1.1-dev_8cd93a37"
MO_CONTAINER_NAME="mo-20240402_163416"
MO_CONTAINER_PORT="6001"
MO_CONTAINER_DEBUG_PORT="12345"
MO_CONTAINER_CONF_HOST_PATH=""
MO_CONTAINER_CONF_CON_FILE="/etc/quickstart/launch.toml"
MO_CONTAINER_DATA_HOST_PATH="/data/mo//20240402_163416"
MO_CONTAINER_HOSTNAME="HOST-10-222-1-9"
MO_CONTAINER_LIMIT_MEMORY=""
MO_CONTAINER_MEMORY_RATIO=90
MO_CONTAINER_AUTO_RESTART="yes"
MO_CONTAINER_LIMIT_CPU=""
MO_CONTAINER_EXTRA_MOUNT_OPTION=""
MO_CONTAINER_DEPIMAGE_REPLACE_REPO="yes" 
MO_CONTAINER_TIMEZONE="default"
CHECK_LIST=("go" "gcc" "git" "mysql" "docker")
GCC_VERSION="8.5.0"
CLANG_VERSION="13.0"
GO_VERSION="1.20"
DOCKER_SERVER_VERSION="20"
MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
MO_DEFAULT_VERSION="v1.1.0"
GOPROXY="https://mirrors.aliyun.com/goproxy,direct"
STOP_INTERVAL="5"
START_INTERVAL="2"
MO_DEBUG_PORT="12345"
MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
GO_MEM_LIMIT_RATIO="30"
RESTART_INTERVAL="2"
PPROF_OUT_PATH="/data/pprof-20241203"
PPROF_PROFILE_DURATION="30"
CSV_CONVERT_MAX_BATCH_SIZE=100000000
CSV_CONVERT_SRC_FILE=""
CSV_CONVERT_BATCH_SIZE=8192
CSV_CONVERT_TGT_DIR="/tmp/"
CSV_CONVERT_TYPE=3
CSV_CONVERT_META_DB=""
CSV_CONVERT_META_TABLE=""
CSV_CONVERT_META_COLUMN_LIST=""
CSV_CONVERT_TN_TYPE=1
CSV_CONVERT_TMP_DIR="/tmp"
CSV_CONVERT_INSERT_ADD_QUOTE="no"
MO_TOOL_NAME="mo_ctl"
MO_TOOL_VERSION="V1.0"
MO_SERVER_NAME="超融合数据库MatrixOne企业版软件"
MO_SERVER_VERSION="V1.0"
BACKUP_SYSDB_LIST="mo_task,information_schema,mysql,system_metrics,system,mo_catalog,mo_debug"
BACKUP_TYPE="physical"
BACKUP_CRON_SCHEDULE="30 23 * * *"
BACKUP_DATA_PATH="/data/mo-backup-reg/data-bk"
BACKUP_DATA_PATH_AUTO_TS="yes"
BACKUP_CLEAN_DAYS_BEFORE="31"
BACKUP_CLEAN_CRON_SCHEDULE="0 7 * * *"
BACKUP_REPORT="/data/cus_reg/bk-and-restore/backup/report.txt"
BACKUP_MOBR_PATH="/data/tools/mo-backup/mo_br"
BACKUP_PHYSICAL_TYPE="filesystem"
BACKUP_MOBR_META_PATH="${TOOL_LOG_PATH}/mo_br.meta"
BACKUP_PHYSICAL_METHOD="incremental"
BACKUP_PHYSICAL_BASE_BKID="01942b55-546b-7da4-a3af-303a907bcdfd"
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
BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
BACKUP_LOGICAL_DB_LIST="all_no_sysdb"
BACKUP_LOGICAL_TBL_LIST=""
BACKUP_LOGICAL_DATA_TYPE="csv"
BACKUP_LOGICAL_ONEBYONE="0"
BACKUP_LOGICAL_NETBUFLEN="1048576"
BACKUP_LOGICAL_DS="myds_001"
RESTORE_TYPE="logical"
RESTORE_PATH="/data/mo/restore"
RESTORE_REPORT="${TOOL_LOG_PATH}/restore-report.txt"
RESTORE_PHYSICAL_TYPE="filesystem"
RESTORE_BKID=""
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
RESTORE_LOGICAL_TYPE="insert"
CLEAN_LOGS_DAYS_BEFORE="31"
CLEAN_LOGS_TABLE_LIST="statement_info,rawlog,metric"
CLEAN_LOGS_CRON_SCHEDULE="0 3 * * *"
MO_LOG_POSTFIX="no"
MO_LOG_AUTO_SPLIT="size"
MO_LOG_MAX_SIZE="10M"
MO_LOG_RESERVE_NUM="1000"
MO_BUILD_IMAGE_PATH="/data/mo/images"
MONITOR_URL_PREFIX_1="https://mirror.ghproxy.com/github.com"
MONITOR_URL_PREFIX_2="https://dl.grafana.com"
MONITOR_NODE_EXPORTER_VERSION="1.7.0"
MONITOR_PROMETHEUS_VERSION="2.48.1"
MONITOR_GRAFANA_VERSION="10.2.3"
DATAX_TOOL_PATH="/data/tools/datax"
DATAX_CONF_PATH="/data/cus_reg/app_test/datax/confs/mysql_2_mo_template.json"
DATAX_REPORT_FILE="/data/cus_reg/app_test/datax/reports/report-20241125_183313.csv"
DATAX_PARA_NAME_LIST="DB_NAME,TABLE_NAME,SRC_HOST,SRC_PORT,SRC_USER,SRC_PW,MO_HOST,MO_PORT,MO_USER,MO_PW,CHANNEL_NUM"
```