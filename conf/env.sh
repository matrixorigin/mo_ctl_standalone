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

# For deploy
# path to deploy matrixone, recommanded path: /data/mo/${DATE}/
MO_PATH="/data/mo/"
# log path used to store mo-service logs
MO_LOG_PATH="${MO_PATH}/matrixone/logs"

# For connect
# host ip to connect where mo is deployed, by default: 127.0.0.1
MO_HOST="127.0.0.1"
# host port to connect where mo is deployed, by default: 6001
# note: this conf is not meant to be the server side conf, but the client side conf
MO_PORT="6001"
# username to connect to mo, by default: root
MO_USER="root"
# password of the user to connect to mo, please use your own password 
MO_PW="111"
# mo deploy mode: docker | host
MO_DEPLOY_MODE="host"
MO_REPO="matrixorigin/matrixone"
MO_IMAGE_PREFIX="nightly"
MO_IMAGE_FULL=""
MO_CONTAINER_NAME="mo"
MO_CONTAINER_PORT="6001"
MO_CONTAINER_DEBUG_PORT="12345"
MO_CONTAINER_CONF_HOST_PATH=""
MO_CONTAINER_CONF_CON_FILE="/etc/quickstart/launch.toml"
MO_CONTAINER_DATA_HOST_PATH="/data/mo/"
MO_CONTAINER_HOSTNAME="705203be8a9e"
MO_CONTAINER_MEMORY_RATIO=90

###########################################
# no need to set below conf for most cases 
###########################################

# for precheck
CHECK_LIST=("go" "gcc" "git" "mysql" "docker")
GCC_VERSION="8.5.0"
CLANG_VERSION="13.0"
GO_VERSION="1.20"
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
MO_DEFAULT_VERSION="1.0.0-rc1"
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


# for version
MO_TOOL_NAME="mo_ctl"
MO_TOOL_VERSION="V1.0"
MO_SERVER_NAME="超融合数据库MatrixOne企业版软件"
MO_SERVER_VERSION="V1.0"

# for auto backup, currently only linux is supported
# backup databases, seperated by ',' for each database. Note: 'all' and 'all_no_system' are special settings
# all: all databases, including all system and user databases
# all_no_sysdb: (default) all databases, including all user databases, but no system databases
# other settings by user, e.g. db1,db2,db3
BACKUP_DB_LIST="all_no_sysdb"
# backup type: logical(default)|physical
BACKUP_TYPE="logical"
# cron to control auto backup schedule time and frequency, in standard cron format (https://crontab.guru/)
BACKUP_CRON_SCHEDULE="30 23 * * *"
# backup data type(only valid when BACKUP_TYPE=logical) : insert(default) | csv
BACKUP_DATA_TYPE="insert"
# backup directory
BACKUP_PATH="/data/mo-backup"
# clean old backup files before [x] (default: 7) days
BACKUP_CLEAN_DAYS_BEFORE="7"
# cron to control auto clean of old backups
BACKUP_CLEAN_CRON_SCHEDULE="0 6 * * *"
