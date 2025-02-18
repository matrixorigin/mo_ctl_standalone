#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# help

#confs
TOOL_NAME="mo_ctl"
USAGE_OPTION_LIST="auto_backup | auto_clean_logs | auto_log_rotate | backup | clean_backup | clean_logs | connect | csv_convert | ddl_convert | deploy | get_branch | get_cid | get_conf | help | monitor | pprof | precheck | restart | set_conf | sql | start | status | stop | uninstall | upgrade | version | watchdog"

USAGE_AUTO_BACKUP="setup a crontab task to backup your databases automatically"
USAGE_AUTO_CLEAN_LOGS="set up a crontab task to clean system log table data automatically"
USAGE_BACKUP="create a backup of your databases manually"
USAGE_BUILD_IMAGE="build an MO image from source code"
USAGE_CLEAN_BACKUP="clean old backups older than conf ${BACKUP_CLEAN_DAYS_BEFORE} days manually"
USAGE_CLEAN_LOGS="clean system log table data manually"
USAGE_CONNECT="connect to mo via mysql client using connection info configured"
USAGE_CSV_CONVERT="convert a csv file to a sql file in format \"insert into values\" or \"load data inline format='csv'\""
USAGE_DDL_CONVERT="convert a ddl file to mo format from other types of database"
USAGE_DEPLOY="deploy mo onto the path configured"
USAGE_GET_BRANCH="print which git branch mo is currently on"
USAGE_GET_CID="print mo git commit id from the path configured"
USAGE_GET_CONF="get configurations"
USAGE_HELP="print help information"
USAGE_MONITOR="monitor system related operations"
USAGE_PRECHECK="check pre-requisites for ${TOOL_NAME}"
USAGE_PPROF="collect pprof information"
USAGE_RESTART="a combination operation of stop and start"
USAGE_SET_CONF="set configurations"
USAGE_SQL="execute sql from string, or a file or a path containg multiple files"
USAGE_STATUS="check if there's any mo process running on this machine"
USAGE_START="start mo-service from the path configured"
USAGE_STOP="stop all mo-service processes found on this machine"
USAGE_UNINSTALL="uninstall mo from path MO_PATH=${MO_PATH}/matrixone"
USAGE_UPGRADE="upgrade or downgrade mo from current version to a target commit id or stable version"
USAGE_VERSION="show ${TOOL_NAME} and matrixone version"
USAGE_WATCHDOG="setup a watchdog crontab task for mo-service to keep it alive"
USAGE_RESTORE="restore mo from a data backup"
USAGE_AUTO_LOG_ROTATE="set up a crontab task to split and compress mo-service log file automatically"
USAGE_DATAX="run datax jobs or list report"

function help_precheck()
{
    option="precheck"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_PRECHECK}"
    echo -n "   Check list : "
    for item in ${CHECK_LIST[@]}; do
        echo -n "${item} "
    done
    echo ""
}


function help_deploy()
{
    option="deploy"
    echo "Usage         : ${TOOL_NAME} ${option} [mo_version] [force] [nobuild] # ${USAGE_DEPLOY}"
    echo "Options    :"
    echo "  [mo_version]: optional, specify an mo version to deploy"
    echo "  [force]     : optional, if specified will delete all content under MO_PATH and deploy from beginning"
    echo "  [nobuild]   : optional, if specified will skip building mo-service"
    echo "Note          : 'deploy' is valid only when MO_DEPLOY_MODE is set to 'git'"
    echo "Examples      : ${TOOL_NAME} ${option}             # default, same as ${TOOL_NAME} ${option} ${MO_DEFAULT_VERSION}"
    echo "                ${TOOL_NAME} ${option} main        # deploy development latest version"
    echo "                ${TOOL_NAME} ${option} d29764a     # deploy development version d29764a"
    echo "                ${TOOL_NAME} ${option} 1.2.0       # deploy stable verson 1.2.0"
    echo "                ${TOOL_NAME} ${option} force       # delete all under MO_PATH and deploy verson ${MO_DEFAULT_VERSION}"
    echo "                ${TOOL_NAME} ${option} 1.2.0 force # delete all under MO_PATH and deploy stable verson 1.2.0 from beginning"
    echo "                ${TOOL_NAME} ${option} main        # deploy development latest version, but don't build mo-service, i.e. only pull git codes"
}


function help_deploy_docker()
{
    option="deploy"
    echo "Usage         : ${TOOL_NAME} ${option}  # ${USAGE_DEPLOY}"
}

function help_status()
{
    option="status"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_STATUS}"
}


function help_start()
{
    option="start"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_START}"
    echo "Note          : when MO_DEPLOY_MODE=git', ${TOOL_NAME} finds mo-service under path MO_PATH/matrixone/ (currently set as ${MO_PATH}/matrixone/)"
    echo "              : when MO_DEPLOY_MODE='binary', ${TOOL_NAME} finds mo-service under path MO_PATH/ (current conf: MO_PATH=${MO_PATH})"
    echo "              : when MO_DEPLOY_MODE='docker', ${TOOL_NAME} creates a container from image MO_CONTAINER_IMAGE (current conf: MO_CONTAINER_IMAGE=${MO_CONTAINER_IMAGE})"
    echo "Examples      : ${TOOL_NAME} ${option}"
}

function help_stop()
{
    option="stop"
    echo "Usage         : ${TOOL_NAME} ${option} [force] # ${USAGE_STOP}"
    echo "Options    :"
    echo "  [force]     : optional: if specified, will try to kill mo-services with -9 option, so be very carefully"
    echo "Note          : If,"
    echo "                1. MO_DEPLOY_MODE=binary, will only stop mo container with name ${MO_CONTAINER_NAME}"
    echo "                2. MO_DEPLOY_MODE=git|binary, will stop all mo-service processes found on this machine"
    echo "Examples      : ${TOOL_NAME} ${option}"
    echo "                ${TOOL_NAME} ${option} force"
}


function help_restart()
{
    option="restart"
    echo "Usage         : ${TOOL_NAME} ${option} [force] # ${USAGE_RESTART}"
    echo "Note          : ${option} is a combination of 'stop' and 'start', thus will try 'stop' first, then try 'start'"
    echo "Examples      : ${TOOL_NAME} ${option}"
    echo "                ${TOOL_NAME} ${option} force"
}

function help_connect()
{
    option="connect"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_CONNECT}"
    echo "Note          : Please set below confs first"
    echo "                1. MO_HOST (optional, default: 127.0.0.1): ip or domain name of target mo to ${option}, default: 127.0.0.1"
    echo "                2. MO_PORT (optional, default: 6001): port of target mo to ${option}"
    echo "                3. MO_USER (optional, default: dump): user name of target mo to ${option}"
    echo "                4. MO_PW (optional, default: 111): user password of target mo to ${option}"
    echo "Examples      : ${TOOL_NAME} set_conf MO_HOST=127.0.0.1"
    echo "                ${TOOL_NAME} set_conf MO_PORT=6001"
    echo "                ${TOOL_NAME} set_conf MO_USER=dump"
    echo "                ${TOOL_NAME} set_conf MO_PW=111"
    echo "                ${TOOL_NAME} ${option}"
}



function help_pprof()
{
    option="pprof"
    echo "Usage          : ${TOOL_NAME} ${option} [item] [duration] # ${USAGE_PPROF}"
    echo "Options        : 1. [item] (optional, default: profile): Specify kind of profile to collect, available: cpu | heap | allocs | goroutine | trace | malloc"
    echo "                 2. [duration] (optional, default: 30): Specify duration in seconds to collect the profile, only valid for 'cpu' and 'trace'"
    echo "Example        : ${TOOL_NAME} ${option}         # collect cpu profile for 30s"
    echo "                 ${TOOL_NAME} ${option} cpu     # same as above"
    echo "                 ${TOOL_NAME} ${option} cpu 30  # same as above" 
    echo "                 ${TOOL_NAME} ${option} heap    # collect heap profile"
}


function help_set_conf()
{
    option="set_conf"
    echo "Usage         : ${TOOL_NAME} ${option} [setting] # ${USAGE_SET_CONF}"
    echo "Options       :"
    echo "  [setting]   : (required) choose one of below"
    echo "                1. conf setting in 'key=value' format, only single conf is supported"
    echo "                2. 'reset', reset all currently confs back to default values (!!!DANGEROUS!!!)"
    echo "Examples      : ${TOOL_NAME} ${option} MO_PATH=/data/mo/20230629"
    echo "                ${TOOL_NAME} ${option} BACKUP_CRON_SCHEDULE=\"30 23 * * *\"             # in case your conf value contains a special character like '*', use double \" to quote it"
    echo "                ${TOOL_NAME} ${option} MO_LOG_PATH=\"\\\${MO_PATH}/matrixone/logs\"      # in case your conf value contains a special character like '$', use double \" and \\ to quote it"
    echo "                ${TOOL_NAME} ${option} reset                                            # reset all confs to default, note this could be DANGEROUS as all of your current settings will be lost and reset to default values. Use it very carefully!!!"
}

function help_get_conf()
{
    option="getconf"
    echo "Usage         : ${TOOL_NAME} ${option} [conf_list] # ${USAGE_GET_CONF}"
    echo "Options       :"
    echo "  [conf_list] : (optional, default: all) choose one of below"
    echo "              : 1. use 'all' to print all confs"
    echo "              : 2. one or multiple conf key names, seperated by comma, e.g. MO_HOST,MO_PORT"
    echo "Examples      : ${TOOL_NAME} ${option} MO_PATH,MO_PW,MO_PORT  # get multiple configurations"
    echo "              : ${TOOL_NAME} ${option} MO_PATH                # get single configuration"
    echo "              : ${TOOL_NAME} ${option} all                    # get all configurations"
    echo "              : ${TOOL_NAME} ${option}                        # get all configurations"
}

function help_ddl_convert()
{
    option="ddl_convert"
    echo "Usage         : ${TOOL_NAME} ${option} [option]  [src_file] [tgt_file] # ${USAGE_DDL_CONVERT}"
    echo "Options    :"
    echo "  [option]    : (required) currently only supports 'mysql_to_mo'"
    echo "  [src_file]  : (required) source file to be converted, will use env DDL_SRC_FILE from conf file by default"
    echo "  [tgt_file]  : (required) target file of converted output, will use env DDL_TGT_FILE from conf file by default"
    echo "Examples      : ${TOOL_NAME} ${option} mysql_to_mo /tmp/mysql.sql /tmp/mo.sql"
}

function help_watchdog()
{
    option="watchdog"
    echo "Usage           : ${TOOL_NAME} ${option} [option]    # ${USAGE_WATCHDOG}"
    echo "Options         :"
    echo " [option]       : (optional, default: status) available: enable | disable | status"
    echo "Examples        : ${TOOL_NAME} ${option} enable      # enable watchdog service for mo, by default it will check if mo-servie is alive and pull it up if it's dead every one minute"
    echo "                  ${TOOL_NAME} ${option} disable     # disable watchdog"
    echo "                  ${TOOL_NAME} ${option} status      # check if watchdog is enabled or disabled"
    echo "                  ${TOOL_NAME} ${option}             # same as ${TOOL_NAME} ${option} status"
}


function help_upgrade()
{
    option="upgrade"
    echo "Usage           : ${TOOL_NAME} ${option} [version]   # ${USAGE_UPGRADE}"
    echo " [version]      : a branch(e.g. 'main'), a commit id (e.g. '38888f7'), or a release version(e.g. '1.2.0')"
    echo "                : use 'latest' to upgrade to latest commit on main branch if you don't know the id"
    echo "Examples        : ${TOOL_NAME} ${option} 38888f7              # upgrade/downgrade to commit id 38888f7 on main branch"
    echo "                : ${TOOL_NAME} ${option} latest               # upgrade/downgrade to latest commit on main branch"
    echo "                : ${TOOL_NAME} ${option} 1.2.0                # upgrade/downgrade to stable version 1.2.0"

}


function help_get_cid()
{
    option="get_cid"
    echo "Usage         : ${TOOL_NAME} ${option} [less] # ${USAGE_GET_CID}"
    echo "  [less]      : (optional) print less info with cid only, otherwise print more info"
    echo "Examples      : ${TOOL_NAME} ${option}"
    echo "                ${TOOL_NAME} ${option} less"

}


function help_get_branch()
{
    option="get_branch"
    echo "Usage         : ${TOOL_NAME} ${option} [less] # ${USAGE_GET_BRANCH}"
    echo "  [less]      : (optional) print less info with branch only, otherwise print more info"
    echo "Examples      : ${TOOL_NAME} ${option}"
    echo "                ${TOOL_NAME} ${option} less"
}

function help_uninstall()
{
    option="uninstall"
    echo "Usage           : ${TOOL_NAME} ${option}        # ${USAGE_UNINSTALL}"
    echo "Note            : You will need to input 'Yes/No' to confirm before uninstalling"

}

function help_sql()
{
    option="sql"
    echo "Usage           : ${TOOL_NAME} ${option} [sql]                 # ${USAGE_SQL}"
    echo "  [sql]         : (required) a string quote by \"\", which could be a raw string of sql statements, a file of statements, or a path with one or more files"
    echo "Examples        : ${TOOL_NAME} ${option} \"use test;select 1;\"  # execute sql \"use test;select 1\""
    echo "                : ${TOOL_NAME} ${option} /data/q1.sql            # execute sql in file /data/q1.sql"
    echo "                : ${TOOL_NAME} ${option} /data/                  # execute all sql files with .sql postfix in /data/"
}

function help_csv_convert()
{
    option="csv_convert"
    echo "Usage           : ${TOOL_NAME} ${option}                        # ${USAGE_CSV_CONVERT}"
    echo "Note            : Please set below confs first"
    echo "                  1. CSV_CONVERT_SRC_FILE: source csv file to convert, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_SRC_FILE=\"/data/test.csv\""
    echo "                  2. CSV_CONVERT_BATCH_SIZE: batch size of target file, note max batch size is limited to ${CSV_CONVERT_MAX_BATCH_SIZE}, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_BATCH_SIZE=8192"
    echo "                  3. CSV_CONVERT_TGT_DIR: a directory to generate target file, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TGT_DIR=/data/target_dir/"
    echo "                  4. CSV_CONVERT_TYPE: [optional, default: 3] convert type: 1|2|3, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TYPE=3"
    echo "                     1: insert into values"
    echo "                     2: load data inline format='csv', data='1\n2\n' into table db_1.tb_1;"
    echo "                     3: "
    echo "                        load data  inline format='csv', data=\$XXX\$"
    echo "                        1,2,3"
    echo "                        11,22,33"
    echo "                        111,222,333"
    echo "                        \$XXX\$ "
    echo "                        into table db_1.tb_1;"
    echo "                   5. CSV_CONVERT_META_DB: database name, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_META_DB=school"
    echo "                   6. CSV_CONVERT_META_TABLE: table name, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_META_TABLE=student"
    echo "                   7. CSV_CONVERT_META_COLUMN_LIST: [optional, default: empty] column list, seperated by ',' , e.g. ${TOOL_NAME} set_conf CSV_CONVERT_META_COLUMN_LIST=id,name,age"
    echo "                   8. CSV_CONVERT_TN_TYPE: [optional, default: 1] transaction type, available: 1|2, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TN_TYPE=1"
    echo "                     1: multi transactions"
    echo "                     2: single transation(will add 'begin;' at first line and 'end;' at last line)"
    echo "                   9. CSV_CONVERT_TMP_DIR: [optional, default: /tmp] a directory to contain temporary files, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TMP_DIR=/tmp/"
    echo "                   10. CSV_CONVERT_INSERT_ADD_QUOTE="no": [optional, default: no] add quote to column value"

}

function help_version()
{
    option="version"
    echo "Usage        : ${TOOL_NAME} ${option} # ${USAGE_VERSION}"
}

function help_bk_notes()
{
    echo "Note         : Currently only supported on Linux. Please set below confs first"
    echo "               ------------------------- "
    echo "                1. Common settings       "
    echo "               ------------------------- "
    echo "               1) BACKUP_REPORT (optional, default: \${TOOL_LOG_PATH}/backup/report.txt): path to backup report file"
    echo "               2) BACKUP_MOBR_META_PATH (optional, default: \${TOOL_LOG_PATH}/mo_br.meta): path to backup metadata file"
    echo "               3) BACKUP_DATA_PATH (optional, default: /data/mo-backup): backup data path in filesystem or s3"
    echo "               4) BACKUP_DATA_PATH_AUTO_TS (optional, default: yes): available: 'yes'|'no'. If 'yes', will add timestamp subpaths to backup data path, e.g. \${BACKUP_DATA_PATH}/202406/20240620_161838"
    echo "               5) BACKUP_TYPE (optional, default: physical): available: 'physical' | 'logical'. Backup type"

    echo "               ------------------------- "
    echo "                2. Auto backup settings       "
    echo "               ------------------------- "

    echo "               1) BACKUP_CRON_SCHEDULE_FULL (optional, default: 30 23 * * *): for auto_backup of physical full type, cron expression to control backup schedule time and frequency, in standard cron format (https://crontab.guru/)"
    echo "               2) BACKUP_CRON_SCHEDULE_INCREMENTAL (optional, default: * */2 * * *): for auto_backup of physical incremental type, same format as BACKUP_CRON_SCHEDULE_FULL"
    echo "               3) BACKUP_CLEAN_DAYS_BEFORE (optional, default: 31): for auto_backup clean up, clean old backup files before [x] days"
    echo "               4) BACKUP_CLEAN_CRON_SCHEDULE (optional, default: 0 6 * * *): for auto_backup clean up, cron to control auto clean of old backups"

    echo ""
    echo "               ------------------------- "
    echo "                3. For physical backups  "
    echo "               ------------------------- "
    echo "               1) BACKUP_MOBR_PATH (optional, default: /data/tools/mo-backup/mo_br): Path to mo_br backup tool"
    echo "               2) BACKUP_PHYSICAL_METHOD (optional, default: full): available: full | incremental"
    echo "                       full: perform a full data backup from scratch"
    echo "                       incremental: perform an incremental data backup based on a full backup or incremental backup"
    echo "               3) BACKUP_PHYSICAL_BASE_BKID (required, when BACKUP_PHYSICAL_METHOD=incremental): the backup id which incremental to be based on"
    echo "               4) BACKUP_PHYSICAL_PARALLEL_NUM (optional, default: 2): physical backup parallism"
    echo "               5) BACKUP_AUTO_SET_LAST_BKID (optional, default: yes): available: 'yes'|'no'. If 'yes', will automatically set BACKUP_PHYSICAL_BASE_BKID to last success backup id"
    echo "               6) BACKUP_PHYSICAL_TYPE (optional, default: filesystem): target backup storage type, choose from \"filesystem\" | \"s3\""
    echo "               if BACKUP_PHYSICAL_TYPE=s3, please set below confs:"
    echo "                 a) BACKUP_S3_ENDPOINT (optional, default: ''): s3 endpoint, e.g. https://cos.ap-nanjing.myqcloud.com"
    echo "                 b) BACKUP_S3_ID (optional, default: ''): s3 id, e.g. B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k"
    echo "                 c) BACKUP_S3_KEY (optional, default: ''): s3 key, e.g. QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j"
    echo "                 d) BACKUP_S3_BUCKET (optional, default: ''): s3 bucket, e.g. mybucket"
    echo "                 e) BACKUP_S3_REGION (optional, default: ''): s3 region, e.g. ap-nanjing"
    echo "                 f) BACKUP_S3_COMPRESSION (optional, default: ''): s3 compression"
    echo "                 g) BACKUP_S3_ROLE_ARN (optional, default: ''): s3 role arn"
    echo "                 h) BACKUP_S3_IS_MINIO (optional, default: 'no'): is minio type or not, choose from \"no\" | \"yes\""

    echo ""
    echo "               ------------------------- "
    echo "                4. For logical backups  "
    echo "               ------------------------- "
    echo "                 1) BACKUP_MODUMP_PATH (optional, default: /data/tools/mo_dump/mo-dump): Path to mo-dump backup tool"
    echo "                 2) BACKUP_LOGICAL_DB_LIST (optional, default: all_no_sysdb): backup databases, seperated by ',' for each database. e.g. 'all' , 'all_no_sysdb' or 'db1,db2,db3'"
    echo "                   Note: 'all' and 'all_no_sysdb' are special settings. "
    echo "                   a) all: all databases, including all system and user databases"
    echo "                   b) all_no_sysdb: all databases, including all user databases, but no system databases"
    echo "                   c) db1,db2,db3: example to backup db1, db2 and db3"
    echo "                 3) BACKUP_LOGICAL_DATA_TYPE (optional, default: csv): available: insert | csv. Backup data type"
    echo "                 4) BACKUP_LOGICAL_ONEBYONE (optional, default: 0): available: 0|1. If set to 1, will backup databases/tables one by one into multiple backup files."
    echo "                 5) BACKUP_LOGICAL_NETBUFLEN (optional, default: 1048576): backup net buffer length(bytes, integer), default: 1048576(1M) , max: 16777216(16M)"
    echo "                 6) BACKUP_LOGICAL_DS (optional, default: none): backup logical dataset name: (optional) the dataset name of the backup database, e.g. myds_001"

}

function help_auto_backup()
{
    option="auto_backup"
    echo "Usage           : ${TOOL_NAME} ${option} [option]    # ${USAGE_AUTO_BACKUP}"
    echo " [option]       : available: enable | disable | status"
    echo "                : ${TOOL_NAME} ${option}             # same as ${TOOL_NAME} ${option} status"
    echo "                : ${TOOL_NAME} ${option} status      # check if auto backup is enabled or disabled"
    echo "  e.g.          : ${TOOL_NAME} ${option} enable      # enable auto backup for your databases"
    echo "                : ${TOOL_NAME} ${option} disable     # disable auto backup for your databases"

    help_bk_notes
}

function help_backup()
{
    option="backup"
    echo "Usage         : ${TOOL_NAME} ${option}             # ${USAGE_BACKUP}"
    echo "              : ${TOOL_NAME} ${option} list        # list backup report in summary"
    echo "              : ${TOOL_NAME} ${option} list detail # list backup report in detail(physical only)"
    help_bk_notes
}

function help_clean_backup()
{
    option="clean_backup"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_CLEAN_BACKUP}"
    help_bk_notes
}

function help_restore_notes()
{
    echo "Note            : Currently only supported on Linux. Please set below confs first"

    echo "                  ------------------------- "
    echo "                   1. Common settings       "
    echo "                  ------------------------- "
    echo "                    1) RESTORE_TYPE (optional, default: physical): backup type to restore, choose from \"physical\" | \"logical\". e.g. ${TOOL_NAME} set_conf RESTORE_TYPE=\"logical\""
    echo ""
    echo "                  ------------------------- "
    echo "                   2. For physical backups  "
    echo "                  ------------------------- "
    echo "                    1) BACKUP_MOBR_PATH (optional, default: /data/tools/mo-backup/mo_br): Path to mo_br backup tool"
    echo "                    2) RESTORE_PATH (required): path to restore, which must be an empty folder, e.g. ${TOOL_NAME} set_conf RESTORE_PATH=\"/data/mo/restore\""
    echo "                    3) RESTORE_BKID (required): backup id to restore, which can be found using cmd \"${TOOL_NAME} backup list detail\", e.g. ${TOOL_NAME} set_conf RESTORE_BKID=\"6363b248-fc9f-11ee-845e-b07b25235fd0\""
    echo "                    4) RESTORE_PHYSICAL_TYPE (optional, default: filesystem]: target restore storage type, choose from \"filesystem\" | \"s3\""
    echo "                    if RESTORE_PHYSICAL_TYPE=s3"
    echo "                      a) RESTORE_S3_ENDPOINT (optional, default: ''): s3 endpoint, e.g. https://cos.ap-nanjing.myqcloud.com"
    echo "                      b) RESTORE_S3_ID (optional, default: ''): s3 id, e.g. B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k"
    echo "                      c) RESTORE_S3_KEY (optional, default: ''): s3 key, e.g. QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j"
    echo "                      d) RESTORE_S3_BUCKET (optional, default: ''): s3 bucket, e.g. mybucket"
    echo "                      e) RESTORE_S3_REGION (optional, default: ''): s3 region, e.g. ap-nanjing"
    echo "                      f) RESTORE_S3_COMPRESSION (optional, default: ''): s3 compression"
    echo "                      g) RESTORE_S3_ROLE_ARN (optional, default: ''): s3 role arn"
    echo "                      h) RESTORE_S3_IS_MINIO (optional, default: 'no'): is minio type or not, choose from \"no\" | \"yes\""

    echo ""
    echo "                  ------------------------- "
    echo "                   3. For logical restore  "
    echo "                  ------------------------- "
    echo "                    1) BACKUP_MODUMP_PATH (optional, default: /data/tools/mo_dump/mo-dump): Path to mo-dump backup tool"
    echo "                    2) RESTORE_LOGICAL_SRC (required): Path of a directory or file to logical backup data source, e.g. /data/backup/db1.sql"
    echo "                    3) RESTORE_LOGICAL_DB (optional): if set, will add database name to mysql command when restoring logical backup data. i.e. MYSQL_PWD=xx mysql -hxxx -Pxxx db_name < backup_data.sql"
    echo "                    4) RESTORE_LOGICAL_TYPE (optional, default: ddl): available: ddl | insert | csv"

}

function help_restore()
{
    option="restore"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_RESTORE}"
    help_restore_notes
}


function help_cl_notes()
{
    echo "Note            : Currently only supported on Linux. Please set below confs first"
    echo "                  1. CLEAN_LOGS_DAYS_BEFORE (optional, default: 31): clean old system log table data before [x] days. "
    echo "                  2. CLEAN_LOGS_TABLE_LIST (optional, default: statement_info,rawlog,metric): log tables to clean, choose one or multiple(seperated by ',') values from: statement_info | rawlog | metric, e.g. statement_info,rawlog,metric"
    echo "                  3. CLEAN_LOGS_CRON_SCHEDULE (optional, default: Default: 0 3 * * *): cron schedule of clean task"

    echo "Examples       : 1. Mannualy clean mo log table data before '31' days, including 'statement_info,rawlog,metric' tables"
    echo "                 ${TOOL_NAME} set_conf CLEAN_LOGS_DAYS_BEFORE=31"
    echo "                 ${TOOL_NAME} set_conf CLEAN_LOGS_TABLE_LIST=statement_info,rawlog,metric"
    echo "                 ${TOOL_NAME} clean_logs"
    echo "                 2. Check if the crontab job to automatically clean mo log table data is enabled"
    echo "                 ${TOOL_NAME} auto_clean_logs # or ${TOOL_NAME} auto_clean_logs status"
    echo "                 3. Set up a crontab job to automatically clean mo log table data before '31' days, including 'statement_info,rawlog,metric' tables, at 03:00 every day"
    echo "                 ${TOOL_NAME} set_conf CLEAN_LOGS_DAYS_BEFORE=31"
    echo "                 ${TOOL_NAME} set_conf CLEAN_LOGS_TABLE_LIST=statement_info,rawlog,metric"
    echo "                 ${TOOL_NAME} set_conf CLEAN_LOGS_CRON_SCHEDULE=\"0 3 * * *\""
    echo "                 ${TOOL_NAME} auto_clean_logs enable"
    echo "                 4. Disable the crontab job to automatically clean mo log table data"
    echo "                 ${TOOL_NAME} auto_clean_logs dsiable"

}

function help_clean_logs()
{
    option="clean_logs"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_CLEAN_LOGS}"
    help_cl_notes
}

function help_auto_clean_logs()
{
    option="auto_clean_logs"
    echo "Usage           : ${TOOL_NAME} ${option} [option]    # ${USAGE_AUTO_CLEAN_LOGS}"
    echo "  [option]      : enable | disable | status(default)"
    help_cl_notes

}

function help_build_image()
{
    option="build_image"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_BUILD_IMAGE}"
    echo "Note            : Please set below configurations first before you run the [enable] option"
    echo "                  1. MO_PATH (optional, default: /data/mo): path to MO source codes. "
    echo "                  2. GOPROXY (optional, default: https://proxy.golang.com.cn,direct): GO proxy setting. "
    echo "                  3. MO_BUILD_IMAGE_PATH (optional, default: /tmp): path to save target MO image"
    echo "Examples        : Build an MO image based on main branch latest commit id"
    echo "                  ${TOOL_NAME} set_conf MO_DEPLOY_MODE=git"
    echo "                  ${TOOL_NAME} set_conf MO_PATH=/data/mo/src"
    echo "                  ${TOOL_NAME} set_conf GOPROXY=https://proxy.golang.com.cn,direct"
    echo "                  ${TOOL_NAME} set_conf MO_BUILD_IMAGE_PATH=/data/mo/images"
    echo "                  ${TOOL_NAME} ${option}"
}

function help_monitor()
{
    option="monitor"
    echo "Usage           : ${TOOL_NAME} ${option} [option_1] [option_2]        # ${USAGE_MONITOR}"
    echo "Options"
    echo "  [option_1]    : deploy | uninstall | status | start | stop"
    echo "  [option_2]    : when [option_1]=deploy, available: online | offline"
    echo "                    online: deploy ${option} online"
    echo "                    offline: deploy ${option} offline"
    echo "Examples        : ${TOOL_NAME} ${option} deploy          # deploy monitor system (online or offline)"
    echo "                  ${TOOL_NAME} ${option} uninstall       # uninstall monitor system"
    echo "                  ${TOOL_NAME} ${option} status          # check if monitor system is running"
    echo "                  ${TOOL_NAME} ${option} start           # start monitor system if not running"
    echo "                  ${TOOL_NAME} ${option} stop            # stop monitor system if running"
}

function help_log_rotate_notes()
{
    option=$1
    echo "Note            : Currently only supported on Linux. Please set below confs first"
    echo "                  1. MO_LOG_AUTO_SPLIT: [optional], 'daily' (default) | 'size'"
    echo "                     'daily': task to be scheduled on a daily basis"
    echo "                     'size': task will be execute once log size exeeceds conf MO_LOG_MAX_SIZE"
    echo "                  2. MO_LOG_MAX_SIZE: [optional], format: [size][unit], default: 1024M, only takes effect when MO_LOG_AUTO_SPLIT=size"
    echo "                     [size]: Maximum log size before it will be splitted and archived, e.g. 1024"
    echo "                     [unit]: empty(bytes,default), k(kilobytes), M(megabytes), G(gigabytes)"
    echo "                  3. MO_LOG_RESERVE_NUM: [optional], format: [positive_integer_number], default: 100"
    echo "                     [positive_integer_number]: number of archived log files"


}


function help_auto_log_rotate()
{
    option="auto_log_rotate"
    echo "Usage           : ${TOOL_NAME} ${option} [option]            # ${USAGE_AUTO_LOG_ROTATE}"
    echo "Options         : "
    echo "  [option]      : enable | disable | status(default)"
    
    help_log_rotate_notes ${option}

    echo "Examples        : "
    echo "  1. Check if ${option} is enabled"
    echo "     ${TOOL_NAME} ${option} enable # or, ${TOOL_NAME} ${option} status"
    echo "  2. Automatically rotate mo-service log on a daily basis by reserving at most 1000 log files"
    echo "     ${TOOL_NAME} set_conf MO_LOG_AUTO_SPLIT=daily"
    echo "     ${TOOL_NAME} set_conf MO_LOG_RESERVE_NUM=1000"
    echo "     ${TOOL_NAME} ${option}"
    echo "  3. Automatically rotate mo-service log as long as its size exeeceds 1024M by reserving at most 1000 log files"
    echo "     ${TOOL_NAME} set_conf MO_LOG_AUTO_SPLIT=size"
    echo "     ${TOOL_NAME} set_conf MO_LOG_MAX_SIZE=1024M"
    echo "     ${TOOL_NAME} set_conf MO_LOG_RESERVE_NUM=1000"
    echo "     ${TOOL_NAME} ${option} enable"
    echo "  4. Disable ${option}"
    echo "     ${TOOL_NAME} ${option} disable"

}

function help_datax()
{
    option="datax"
    echo "Usage           : ${TOOL_NAME} ${option} [option1]               # ${USAGE_DATAX}"
    echo "Options         : [option1]: run|list"
    echo "  [option1]     : run|list"
    echo "    run         : Optional (default), run datax jobs"
    echo "    list        : Optional, list datax report"
    echo "Note            : Please set below configurations first before you run the [run] option"
    echo "                  1. DATAX_TOOL_PATH (default: /data/tools/datax): installation path to datax tool"
    echo "                  2. DATAX_CONF_PATH (default: /data/tools/datax/conf/test.json): path to datax conf file, e.g. /data/tools/datax/conf/test.json , or a directory containing multiple conf files, e.g. /data/tools/datax/conf/"
    echo "                  3. DATAX_REPORT_FILE (optional, default:  \${TOOL_LOG_PATH}/backup/report.txt): path to mo_ctl datax report file"
    echo "                  4. DATAX_PARA_NAME_LIST (optional, default: none): parameter lists of datax -p option, e.g. 'db_name,table_name'"
    echo "Examples        : ${TOOL_NAME} ${option}                        # run datax jobs"
    echo "                : ${TOOL_NAME} ${option} list                   # list datax report"
}


function help_1()
{
    echo "Usage               : ${TOOL_NAME} [option_1] [option_2]"
    echo ""
    echo "Options             :"
    echo "  [option_1]        : available: ${USAGE_OPTION_LIST}"
    echo "    auto_backup     : ${USAGE_AUTO_BACKUP}"
    echo "    auto_clean_logs : ${USAGE_AUTO_CLEAN_LOGS}"
    echo "    auto_log_rotate : ${USAGE_AUTO_LOG_ROTATE}"
    echo "    backup          : ${USAGE_BACKUP}"
    echo "    build_image     : ${USAGE_BUILD_IMAGE}"
    echo "    clean_backup    : ${USAGE_CLEAN_BACKUP}"
    echo "    clean_logs      : ${USAGE_CLEAN_LOGS}"
    echo "    connect         : ${USAGE_CONNECT}"
    echo "    csv_convert     : ${USAGE_CSV_CONVERT}"
    echo "    ddl_convert     : ${USAGE_DDL_CONVERT}"
    echo "    deploy          : ${USAGE_DEPLOY}"
    echo "    get_branch      : ${USAGE_UPGRADE}"
    echo "    get_cid         : ${USAGE_GET_CID}"
    echo "    get_conf        : ${USAGE_GET_CONF}"
    echo "    help            : ${USAGE_HELP}"
    echo "    monitor         : ${USAGE_MONITOR}"
    echo "    pprof           : ${USAGE_PPROF}"
    echo "    precheck        : ${USAGE_PRECHECK}"
    echo "    restart         : ${USAGE_RESTART}"
    echo "    set_conf        : ${USAGE_SET_CONF}"
    echo "    sql             : ${USAGE_SQL}"
    echo "    start           : ${USAGE_START}"
    echo "    status          : ${USAGE_STATUS}"
    echo "    stop            : ${USAGE_STOP}"
    echo "    uninstall       : ${USAGE_UNINSTALL}"
    echo "    upgrade         : ${USAGE_UPGRADE}"
    echo "    version         : ${USAGE_VERSION}"
    echo "    watchdog        : ${USAGE_WATCHDOG}"
    echo ""
    echo "  [option_2]        : Option for [option_1]. Use '${TOOL_NAME} [option_1] help' to get more info"
    echo ""
    echo "Examples            : ${TOOL_NAME} status"
    echo "                      ${TOOL_NAME} status help "
}



function help_2()
{
    option=$1
    case "${option_1}" in
        precheck)
            help_precheck
            ;;
        deploy)
            help_deploy
            ;;
        status)
            help_status
            ;;
        start)
            help_start
            ;;
        stop)
            help_stop
            ;;
        restart)
            help_restart
            ;;
        connect)
            help_connect
            ;;
        get_cid)
            help_get_cid
            ;;
        pprof)
            help_pprof
            ;;
        set_conf)
            help_set_conf
            ;;
        get_conf)
            help_get_conf
            ;;
        ddl_convert)
            help_ddl_convert
            ;;
        watchdog)
            help_watchdog
            ;;
        upgrade)
            help_upgrade
            ;;
        get_branch)
            help_get_branch
            ;;
        uninstall)
            help_uninstall
            ;;
        sql)
            help_sql
            ;;
        csv_convert)
            help_csv_convert
            ;;
        version)
            help_version
            ;;
        auto_backup)
            help_auto_backup
            ;;
        backup)
            help_backup
            ;;
        clean_backup)
            help_clean_backup
            ;;
        clean_logs)
            help_clean_logs
            ;;
        auto_clean_logs)
            help_auto_clean_logs
            ;;
        build_image)
            help_build_image
            ;;
        monitor)
            help_monitor
            ;;
        restore)
            help_restore
            ;;
        auto_log_rotate)
            help_auto_log_rotate
            ;;
        datax)
            help_datax
            ;;
        *)
            add_log "E" "invalid option_1: ${option_1}"
            help_1
            exit 1
            ;;
    esac
}


