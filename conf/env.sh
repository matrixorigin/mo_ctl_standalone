################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
###### configurations ######


###########################################
# set below confs on demand
###########################################

# General
# D|d: Debug, I|i: INFO, W|w: WARN, E|e: ERROR
TOOL_LOG_LEVEL="I"
TOOL_LOG_PATH="/data/logs/mo_ctl"

# For deploy
# path to deploy matrixone, recommanded path: /data/mo/${DATE}/
MO_PATH="/data/mo/"
# log path used to store mo-service logs
MO_LOG_PATH="${MO_PATH}/matrixone/logs"

# mo-service log file prefix
# enum: yes(default)|no , where,
# 'yes': meaning automatically creating timestamp as log file name postfix, e.g. stdout-20240929_110548.log. Everytime when mo-service is started or restarted, 2 new log files will be created and log content will be written.  
# 'no': meaning no postfix will be added to the log file name, e.g. stdout.log. Everytime when mo-service is started or restarted, the log content will be appended to the log files used last time and before.
MO_LOG_POSTFIX="no"  



# conf file source folder
MO_CONF_SRC_PATH=""

# For connect
# target mo instance type: local | remote
# deprecated: MO_SERVER_TYPE="local"
# host ip to connect where mo is deployed, by default: 127.0.0.1
MO_HOST="127.0.0.1"
# host port to connect where mo is deployed, by default: 6001
# note: this conf is not meant to be the server side conf, but the client side conf
MO_PORT="6001"
# username to connect to mo, by default: root
MO_USER="root"
# password of the user to connect to mo, please use your own password 
MO_PW="111"
# mo deploy mode: docker | git | binary, default: git
MO_DEPLOY_MODE="git"
# env GOTOOLCHAIN used when 'make build' of mo-service, e.g. go1.22.3
MO_MAKE_BUILD_GOTOOLCHAIN=""

# for docker
# deprecated: MO_REPO="matrixorigin/matrixone"
# full image name of mo container, default: matrixorigin/matrixone:1.0.1
MO_CONTAINER_IMAGE="matrixorigin/matrixone:1.2.0"
# mo container name
MO_CONTAINER_NAME="mo"
# mo container sql port (PS: constant value, DONT CHANGE)
MO_CONTAINER_PORT="6001"
# mo container debug port (PS: constant value, DONT CHANGE)
MO_CONTAINER_DEBUG_PORT="12345"
# mo container conf host path
MO_CONTAINER_CONF_HOST_PATH=""
# mo container conf file inside container
MO_CONTAINER_CONF_CON_FILE="/etc/quickstart/launch.toml"
# mo container data host path
MO_CONTAINER_DATA_HOST_PATH="/data/mo/"
# default value, will be overwritten by actual machine hostname in runtime
MO_CONTAINER_HOSTNAME="705203be8a9e"
# mo container limit for memory (unit: m) (e.g. 1000 | 1500 | 2000 | ...)
MO_CONTAINER_LIMIT_MEMORY=""
# use ratio to set mo container limit for memory based on the total memory of the machine (unit: %)
MO_CONTAINER_MEMORY_RATIO=90
# auto restart mo container in case it is down? (yes|no)
MO_CONTAINER_AUTO_RESTART="yes"
# mo container limit for cpu (e.g. 1 | 1.5 | 2 | ...)
MO_CONTAINER_LIMIT_CPU=""
# extra mount options
MO_CONTAINER_EXTRA_MOUNT_OPTION=""
# replace below image repo with ccr.ccs.tencentyun.com/mo-infra? option: yes | no
# images: golang:1.22.3-bookworm , ubuntu:22.04
MO_CONTAINER_DEPIMAGE_REPLACE_REPO="yes" 
# timezone, choose from: default(usually UTC) | host (same as host local time)
MO_CONTAINER_TIMEZONE="default"


###########################################
# no need to set below conf for most cases 
###########################################

# for precheck
CHECK_LIST=("go" "gcc" "git" "mysql" "docker")
GCC_VERSION="8.5.0"
CLANG_VERSION="13.0"
GO_VERSION="1.22.3"
DOCKER_SERVER_VERSION="20"

# for deploy
# which url to be used for git cloning mo
MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
# in case you have network issues accessing above address, you can set one of the backup addresses below to replace the default value:
# default: "https://github.com/matrixorigin/matrixone.git"
# "https://ghproxy.com/https://github.com/matrixorigin/matrixone.git"
# "https://hub.yzuu.cf/matrixorigin/matrixone.git"
# "https://kgithub.com/matrixorigin/matrixone.git"
# "https://gitclone.com/github.com/matrixorigin/matrixone.git"
#)

# default version of which mo to be deployed
MO_DEFAULT_VERSION="v1.2.0"
# which go proxy to be used when downloading go dependencies
# you can set this go proxy when building mo-service
GOPROXY="https://goproxy.cn,direct"

# for stop
# interval between stop and check status after stop, unit: seconds
STOP_INTERVAL="5"

# for start
# interval between start and check status after start, unit: seconds
START_INTERVAL="2"
# debug port that mo-service uses when it is started, which can be used to collect pprof info
MO_DEBUG_PORT="9876"
# conf file used to start mo-service
MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
# GO memory limit ratio, x%. By default, 90% is recommended
GO_MEM_LIMIT_RATIO=90
# time interval (in seconds) of auto profile collecting. Empty by default, meaning will not turn on auto profile collecting
PPROF_INTERVAL=""
# use nohup or -daemon(default) to start mo-service? choose from: nohup | daemon
DAEMON_METHOD="daemon" 


# for restart
# interval between stop and start, unit: seconds
RESTART_INTERVAL="2"

# for pprof
# output path of pprof results 
PPROF_OUT_PATH="/tmp/pprof-test/"
# duration to collect pprof profile, unit: seconds
PPROF_PROFILE_DURATION="30"

# for csv convert
# const: maximum batch size
CSV_CONVERT_MAX_BATCH_SIZE=100000000
# source csv file to convert
CSV_CONVERT_SRC_FILE=""
# batch size of target file
CSV_CONVERT_BATCH_SIZE=8192
# a directory to generate the converted target file with name ${CSV_CONVERT_SRC_FILE}_${current_timestamp}.sql
CSV_CONVERT_TGT_DIR="/tmp/"
# convert type: 1|2|3
# 1: insert into values
# 2: load data inline format='csv', data='1\n2\n' into table db_1.tb_1;
# 3: 
# load data  inline format='csv', data=$XXX$
# 1,2,3
# 11,22,33
# 111,222,333
# $XXX$ 
# into table db_1.tb_1;
CSV_CONVERT_TYPE=3
# metadata info, containing below info and in below format:
# This will be converted automatically into
# format: ${DB}.${TABLE}(${COL_1},${COL_2}, ...., ${COL_N})
# e.g. school.student(id,name,age)

# database name, e.g. school
CSV_CONVERT_META_DB=""
# table name, e.g. student
CSV_CONVERT_META_TABLE=""
# OPTIONAL: column list, seperated by ','  e.g. col1,col2,col3
CSV_CONVERT_META_COLUMN_LIST=""

# transaction type
# 1: multi transactions
# 2: single trancation(will add begin; and end;)
CSV_CONVERT_TN_TYPE=1

# directory for temp files
CSV_CONVERT_TMP_DIR="/tmp"

# add " or not? (no|yes)
CSV_CONVERT_INSERT_ADD_QUOTE="no"

# fields terminated by
CSV_FIELDS_TERMINATED_BY=""

# for version
MO_TOOL_NAME="mo_ctl"
MO_TOOL_VERSION="V1.2"
MO_SERVER_NAME="超融合数据库MatrixOne企业版软件"
MO_SERVER_VERSION="V1.2"

# for auto backup, currently only linux is supported
# backup
# DONT CHANGE
BACKUP_SYSDB_LIST="mo_task,information_schema,mysql,system_metrics,system,mo_catalog,mo_debug"
# backup type: physical(default)|logical
BACKUP_TYPE="physical"
# full backup: cron to control auto backup schedule time and frequency, in standard cron format (https://crontab.guru/)
BACKUP_CRON_SCHEDULE_FULL="30 23 * * *"
# incremental backup: same as above
BACKUP_CRON_SCHEDULE_INCREMENTAL="* */2 * * *"
# backup data path
BACKUP_DATA_PATH="/data/mo-backup"
# add timestamp subpaths to backup data path? format: ${BACKUP_DATA_PATH}/202406/20240620_161838
BACKUP_DATA_PATH_AUTO_TS="yes"
# auto clean old backups
# clean old backup files before [x] (default: 31) days
BACKUP_CLEAN_DAYS_BEFORE="31"
# cron to control auto clean of old backups
BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"
# backup history
BACKUP_REPORT="${TOOL_LOG_PATH}/backup-report.txt"

# 1. physical backups
# backup tools
# s3 client
S3_CLIENT="/usr/local/bin/mc"
S3_CONFIG_DIR=""
S3_API_VERSION=""
# mo_br
BACKUP_MOBR_PATH="/data/tools/mo-backup/mo_br"
# backup target type: filesystem(default)|s3
BACKUP_PHYSICAL_TYPE="filesystem"
# mobr meta file
BACKUP_MOBR_META_PATH="${TOOL_LOG_PATH}/mo_br.meta"
# backup physical method: full(default)|incremental
BACKUP_PHYSICAL_METHOD="full"
# backup physical base backup id, only valid when BACKUP_PHYSICAL_METHOD='incremental' 
BACKUP_PHYSICAL_BASE_BKID=""
# if yes, will automatically set BACKUP_PHYSICAL_BASE_BKID to last sucess backup id: yes(default)|no
BACKUP_AUTO_SET_LAST_BKID="yes"
# physical backup parallism, default: 2
BACKUP_PHYSICAL_PARALLEL_NUM=2

# 1) when BACKUP_PHYSICAL_TYPE="filesystem"
# backup directory, same as BACKUP_PATH
# BACKUP_PATH="/data/mo-backup"
# 2) when BACKUP_PHYSICAL_TARGET_TYPE="s3"
BACKUP_S3_ENDPOINT=""
BACKUP_S3_ID=""
BACKUP_S3_KEY=""
BACKUP_S3_BUCKET=""
# deprecated: use BACKUP_DATA_PATH as BACKUP_S3_PATH
# BACKUP_S3_PATH="${BACKUP_DATA_PATH}"
BACKUP_S3_REGION=""
BACKUP_S3_COMPRESSION=""
BACKUP_S3_ROLE_ARN=""
BACKUP_S3_IS_MINIO="no"

# 2. logical backups
# mo-dump
BACKUP_MODUMP_PATH="/data/tools/mo_dump/mo-dump"
# backup databases, seperated by ',' for each database. Note: 'all' and 'all_no_sysdb' are special settings
# all: all databases, including all system and user databases
# all_no_sysdb: (default) all databases, including all user databases, but no system databases
# other settings by user, e.g. db1,db2,db3
BACKUP_LOGICAL_DB_LIST="all_no_sysdb"
# backup tables, seperated by ','
# Note: BACKUP_LOGICAL_TBL_LIST is only vailid when BACKUP_LOGICAL_DB_LIST has exactly one database, otherwise it will be ignored
BACKUP_LOGICAL_TBL_LIST=""
# backup data type(only valid when BACKUP_TYPE=logical) : insert | csv(default) | ddl
BACKUP_LOGICAL_DATA_TYPE="csv"
# backup data per database one by one (only valid when BACKUP_TYPE=logical): 0 (default, all at once) | 1 (one by one)
BACKUP_LOGICAL_ONEBYONE="0"
# backup net buffer length(integer): 1048576(default, 1M), Max is 16777216 (16M)
BACKUP_LOGICAL_NETBUFLEN="1048576"
# backup logical dataset name: (optional) the dataset name of the backup database
BACKUP_LOGICAL_DS=""


# for restore

# restore type: physical | logical
RESTORE_TYPE="physical"
RESTORE_PATH="/data/mo/restore"
RESTORE_REPORT="${TOOL_LOG_PATH}/restore-report.txt"

# 1. physical restore
# restore target type: filesystem(default)|s3
RESTORE_PHYSICAL_TYPE="filesystem"
# the backup id to be restored
RESTORE_BKID=""
# 1) when BACKUP_PHYSICAL_TYPE="filesystem"
# restore directory
# same as RESTORE_PATH

# 2) when BACKUP_PHYSICAL_TARGET_TYPE="s3"
RESTORE_S3_ENDPOINT=""
RESTORE_S3_ID=""
RESTORE_S3_KEY=""
RESTORE_S3_BUCKET=""
RESTORE_S3_REGION=""
RESTORE_S3_COMPRESSION=""
RESTORE_S3_ROLE_ARN=""
RESTORE_S3_IS_MINIO="no"


# 2. logical restore
# restore target db, e.g. db1. only one db is supported
RESTORE_LOGICAL_DB=""
# restore data path (directory or file)
RESTORE_LOGICAL_SRC=""
# restore data type: csv | insert | ddl
RESTORE_LOGICAL_TYPE="ddl"




# for auto clean sysdb logs
# clean old sysdb logs before [x] (default: 31) days
CLEAN_LOGS_DAYS_BEFORE="31"
# log tables to clean, choose one or multiple(seperated by ',') values from: statement_info | rawlog | metric
CLEAN_LOGS_TABLE_LIST="statement_info,rawlog,metric"
# cron to control auto clean of old backups
CLEAN_LOGS_CRON_SCHEDULE="0 3 * * *"

# for auto log rotate
# enum: daily(default)|size, where,
# 'daily': only takes effect when MO_LOG_POSTFIX is set to no, meaning mo-service log(including stdout.log and stderr.log), will be auto splited and archived on a daily basis
# 'size': only takes effect when MO_LOG_POSTFIX is set to no, meaning mo-service log(including stdout.log and stderr.log), will be auto splited and archived when their sizes exeeced the setting of MO_LOG_MAX_SIZE
MO_LOG_AUTO_SPLIT="daily"

# only takes effect when MO_LOG_AUTO_SPLIT is set to size, where:
# ${MAX_SIZE}: Maximum log size before it will be splitted and archived, e.g. 1024M
# unit: bytes(default), KB (sizek), or MB (sizem)
MO_LOG_MAX_SIZE="1024M"

# only takes effect when MO_LOG_AUTO_SPLIT is set to 'size' or 'daily', where:
# ${NUM}: number of archived log files , e.g. 100
MO_LOG_RESERVE_NUM="10000"


# for build image
MO_BUILD_IMAGE_PATH="/tmp/"

# for monitor
# promethues and node_exporter
MONITOR_URL_PREFIX_1="https://mirror.ghproxy.com/github.com"
MONITOR_URL_PREFIX_2="https://dl.grafana.com"
MONITOR_NODE_EXPORTER_VERSION="1.7.0"
MONITOR_PROMETHEUS_VERSION="2.48.1"
MONITOR_GRAFANA_VERSION="10.2.3"

# for datax
# installation path to datax tool, e.g. /data/tools/datax/
DATAX_TOOL_PATH="/data/tools/datax"
# path to datax conf file, e.g. /data/tools/datax/conf/test.json , or a directory containing multiple conf files, e.g. /data/tools/datax/conf/
DATAX_CONF_PATH="/data/tools/datax/conf/test.json"
# path to mo_ctl datax report file
DATAX_REPORT_FILE="${TOOL_LOG_PATH}/datax.report"
# parameter lists of datax -p option, e.g. 'db_name,table_name'
DATAX_PARA_NAME_LIST=""

# the log directory of this ctl tool.
CTL_LOG_DIR=""
