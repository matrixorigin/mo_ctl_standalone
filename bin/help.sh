#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# help

#confs
TOOL_NAME="mo_ctl"
USAGE_OPTION_LIST="auto_backup | auto_clean_logs | backup | clean_backup | clean_logs | connect | csv_convert | ddl_convert | deploy | get_branch | get_cid | get_conf | help | monitor | pprof | precheck | restart | set_conf | sql | start | status | stop | uninstall | upgrade | version | watchdog"

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
USAGE_PATH="print mo path configured"
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
    echo "Usage         : ${TOOL_NAME} ${option} [mo_version] [force] # ${USAGE_DEPLOY}"
    echo "  [mo_version]: optional: specify an mo version to deploy"
    echo "  [force]     : optional: if specified will delete all content under MO_PATH and deploy from beginning"
    echo "  e.g.        : ${TOOL_NAME} ${option}             # default, same as ${TOOL_NAME} ${option} ${MO_DEFAULT_VERSION}"
    echo "              : ${TOOL_NAME} ${option} main        # deploy development latest version"
    echo "              : ${TOOL_NAME} ${option} d29764a     # deploy development version d29764a"
    echo "              : ${TOOL_NAME} ${option} 0.8.0       # deploy stable verson 0.8.0"
    echo "              : ${TOOL_NAME} ${option} force       # delete all under MO_PATH and deploy verson ${MO_DEFAULT_VERSION}"
    echo "              : ${TOOL_NAME} ${option} 0.8.0 force # delete all under MO_PATH and deploy stable verson 0.8.0 from beginning"
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
}

function help_stop()
{
    option="stop"
    echo "Usage         : ${TOOL_NAME} ${option} [force] # ${USAGE_STOP}"
    echo " [force]      : optional: if specified, will try to kill mo-services with -9 option, so be very carefully"
    echo "  e.g.        : ${TOOL_NAME} ${option}         # default, stop all mo-service processes found on this machine"
    echo "              : ${TOOL_NAME} ${option} force   # stop all mo-services with kill -9 command"
}


function help_restart()
{
    option="restart"
    echo "Usage         : ${TOOL_NAME} ${option} [force] # ${USAGE_RESTART}"
    echo " [force]      : optional: if specified, will try to kill mo-services with -9 option, so be very carefully"
    echo "  e.g.        : ${TOOL_NAME} ${option}         # default, stop all mo-service processes found on this machine and start mo-serivce under path of conf MO_PATH"
    echo "              : ${TOOL_NAME} ${option} force   # stop all mo-services with kill -9 command and start mo-serivce under path of conf MO_PATH"
}

function help_connect()
{
    option="connect"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_CONNECT}"
}

function help_get_cid()
{
    option="get_cid"
    echo "Usage         : ${TOOL_NAME} ${option} [less] # ${USAGE_GET_CID}"
    echo "  [less]      : optional, if specified, print less info with cid only, otherwise print more info"

}

function help_path()
{
    option="path"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_PATH}"
}


function help_pprof()
{
    option="pprof"
    echo "Usage         : ${TOOL_NAME} ${option} [item] [duration] # ${USAGE_PPROF}"
    echo "  [item]      : optional: specify what pprof to collect, available: profile | heap | allocs"
    echo "  1) profile  : default, collect profile pprof for 30 seconds"
    echo "  2) heap     : collect heap pprof at current moment"
    echo "  3) allocs   : collect allocs pprof at current moment"
    echo "  [duration]  : optional: only valid when [item]=profile, specifiy duration to collect profile"
    echo "  e.g.        : ${TOOL_NAME} ${option}"
    echo "              : ${TOOL_NAME} ${option} profile    # collect duration will use conf value PPROF_PROFILE_DURATION from conf file or 30 if it's not set"
    echo "              : ${TOOL_NAME} ${option} profile 30"
    echo "              : ${TOOL_NAME} ${option} heap"
}

function help_set_conf()
{
    option="set_conf"
    echo "Usage         : ${TOOL_NAME} ${option} [conf_list] # ${USAGE_SET_CONF}"
    echo " [conf_list]  : configuration list in key=value format, note that setting multiple confs at the same time is not supported"
    echo "              : ${TOOL_NAME} ${option} MO_PATH=/data/mo/20230629"
    echo "              : ${TOOL_NAME} ${option} BACKUP_CRON_SCHEDULE=\"30 23 * * *\"             # in case your conf value contains a special character like '*', use double \" to quote it"
    echo "              : ${TOOL_NAME} ${option} MO_LOG_PATH=\"\\\${MO_PATH}/matrixone/logs\"      # in case your conf value contains a special character like '$', use double \" and \\ to quote it"
    echo "              : ${TOOL_NAME} ${option} reset                                            # reset all confs to default, note this could be dangerous as all of your current settings will be lost. Use it very carefully!!!"
}

function help_get_conf()
{
    option="getconf"
    echo "Usage         : ${TOOL_NAME} ${option} [conf_list] # ${USAGE_GET_CONF}"
    echo " [conf_list]  : optional: configuration list in key, seperated by comma."
    echo "              : use 'all' or leave it as blank to print all configurations"
    echo "  e.g.        : ${TOOL_NAME} ${option} MO_PATH,MO_PW,MO_PORT  # get multiple configurations"
    echo "              : ${TOOL_NAME} ${option} MO_PATH                # get single configuration"
    echo "              : ${TOOL_NAME} ${option} all                    # get all configurations"
    echo "              : ${TOOL_NAME} ${option}                        # get all configurations"
}

function help_ddl_convert()
{
    option="ddl_convert"
    echo "Usage           : ${TOOL_NAME} ${option} [options] [src_file] [tgt_file] # ${USAGE_DDL_CONVERT}"
    echo " [options]      : available: mysql_to_mo"
    echo " [src_file]     : source file to be converted, will use env DDL_SRC_FILE from conf file by default"
    echo " [tgt_file]     : target file of converted output, will use env DDL_TGT_FILE from conf file by default"
    echo "  e.g.          : ${TOOL_NAME} ${option} mysql_to_mo /tmp/mysql.sql /tmp/mo.sql"
}

function help_watchdog()
{
    option="watchdog"
    echo "Usage           : ${TOOL_NAME} ${option} [options]   # ${USAGE_WATCHDOG}"
    echo " [options]      : available: enable | disable | status"
    echo "  e.g.          : ${TOOL_NAME} ${option} enable      # enable watchdog service for mo, by default it will check if mo-servie is alive and pull it up if it's dead every one minute"
    echo "                : ${TOOL_NAME} ${option} disable     # disable watchdog"
    echo "                : ${TOOL_NAME} ${option} status      # check if watchdog is enabled or disabled"
    echo "                : ${TOOL_NAME} ${option}             # same as ${TOOL_NAME} ${option} status"
}


function help_upgrade()
{
    option="upgrade"
    echo "Usage           : ${TOOL_NAME} ${option} [version_or_commitid]   # ${USAGE_UPGRADE}"
    echo " [commitid]     : a commit id such as '38888f7', or a stable version such as '0.8.0'"
    echo "                : use 'latest' to upgrade to latest commit on main branch if you don't know the id"
    echo "  e.g.          : ${TOOL_NAME} ${option} 38888f7              # upgrade/downgrade to commit id 38888f7 on main branch"
    echo "                : ${TOOL_NAME} ${option} latest               # upgrade/downgrade to latest commit on main branch"
    echo "                : ${TOOL_NAME} ${option} 0.8.0                # upgrade/downgrade to stable version 0.8.0"

}



function help_get_branch()
{
    option="get_branch"
    echo "Usage           : ${TOOL_NAME} ${option}        # ${USAGE_GET_BRANCH}"
}

function help_uninstall()
{
    option="uninstall"
    echo "Usage           : ${TOOL_NAME} ${option}        # ${USAGE_UNINSTALL}"
    echo "                                          # note: you will need to input 'Yes/No' to confirm before uninstalling"

}

function help_sql()
{
    option="sql"
    echo "Usage           : ${TOOL_NAME} ${option} [sql]                 # ${USAGE_SQL}"
    echo "  [sql]         : a string quote by \"\", or a file, or a path"
    echo "  e.g.          : ${TOOL_NAME} ${option} \"use test;select 1;\"  # execute sql \"use test;select 1\""
    echo "                : ${TOOL_NAME} ${option} /data/q1.sql            # execute sql in file /data/q1.sql"
    echo "                : ${TOOL_NAME} ${option} /data/                  # execute all sql files with .sql postfix in /data/"
}

function help_csv_convert()
{
    option="csv_convert"
    echo "Usage           : ${TOOL_NAME} ${option}                        # ${USAGE_CSV_CONVERT}"
    echo "Note: please set below configurations first before you run this option"
    echo "      1. CSV_CONVERT_SRC_FILE: source csv file to convert, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_SRC_FILE=\"/data/test.csv\""
    echo "      2. CSV_CONVERT_BATCH_SIZE: batch size of target file, note max batch size is limited to ${CSV_CONVERT_MAX_BATCH_SIZE}, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_BATCH_SIZE=8192"
    echo "      3. CSV_CONVERT_TGT_DIR: a directory to generate target file, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TGT_DIR=/data/target_dir/"
    echo "      4. CSV_CONVERT_TYPE: [OPTIONAL, default: 3] convert type: 1|2|3, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TYPE=3"
    echo "          1: insert into values"
    echo "          2: load data inline format='csv', data='1\n2\n' into table db_1.tb_1;"
    echo "          3: "
    echo "              load data  inline format='csv', data=\$XXX\$"
    echo "              1,2,3"
    echo "              11,22,33"
    echo "              111,222,333"
    echo "              \$XXX\$ "
    echo "              into table db_1.tb_1;"
    echo "      5. CSV_CONVERT_META_DB: database name, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_META_DB=school"
    echo "      6. CSV_CONVERT_META_TABLE: table name, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_META_TABLE=student"
    echo "      7. CSV_CONVERT_META_COLUMN_LIST: [OPTIONAL, default: empty] column list, seperated by ',' , e.g. ${TOOL_NAME} set_conf CSV_CONVERT_META_COLUMN_LIST=id,name,age"
    echo "      8. CSV_CONVERT_TN_TYPE: [OPTIONAL, default: 1] transaction type, choose from: 1|2, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TN_TYPE=1"
    echo "          1: multi transactions"
    echo "          2: single transation(will add 'begin;' at first line and 'end;' at last line)"
    echo "      9. CSV_CONVERT_TMP_DIR: [OPTIONAL, default: /tmp] a directory to contain temporary files, e.g. ${TOOL_NAME} set_conf CSV_CONVERT_TMP_DIR=/tmp/"
}

function help_version()
{
    option="version"
    echo "Usage         : ${TOOL_NAME} ${option} # ${USAGE_VERSION}"
}

function help_bk_notes()
{
    echo "  Note          : currently only supported on linux systems"
    echo "                : please set below configurations first before you run the [enable] option"

    echo "  ------------------------- "
    echo "   1. Common settings       "
    echo "  ------------------------- "
    echo "    1) BACKUP_DATA_PATH [default: /data/mo-backup]: backup data path in filesystem or s3. e.g. mo_ctl set_conf BACKUP_DATA_PATH=/data/mo-backup"
    echo "    2) BACKUP_TYPE [default: physical]: backup type choose from \"physical\" | \"logical\". e.g. mo_ctl set_conf BACKUP_TYPE=\"logical\""
    echo "    3) BACKUP_CRON_SCHEDULE [default: 30 23 * * *]: cron expression to control backup schedule time and frequency, in standard cron format (https://crontab.guru/). e.g. mo_ctl set_conf BACKUP_TYPE=\"30 23 * * *\""
    echo "    4) BACKUP_CLEAN_DAYS_BEFORE [default: 31]: clean old backup files before [x] days. e.g. mo_ctl set_conf BACKUP_CLEAN_DAYS_BEFORE=31"
    echo "    5) BACKUP_CLEAN_CRON_SCHEDULE [default: 0 6 * * *]: cron to control auto clean of old backups. e.g. mo_ctl set_conf BACKUP_CLEAN_CRON_SCHEDULE=\"0 6 * * *\""

    echo ""
    echo "  ------------------------- "
    echo "   2. For physical backups  "
    echo "  ------------------------- "
    echo "    1) BACKUP_MOBR_PATH [default: /data/tools/mo-backup/mo_br]: Path to mo_br backup tool"
    echo "    2) BACKUP_PHYSICAL_TYPE [default: filesystem]: target backup storage type, choose from \"filesystem\" | \"s3\""
    echo "      if BACKUP_PHYSICAL_TYPE=s3"
    echo "        a) BACKUP_S3_ENDPOINT [default: '']: s3 endpoint, e.g. https://cos.ap-nanjing.myqcloud.com"
    echo "        b) BACKUP_S3_ID [default: '']: s3 id, e.g. B4v6Khv484X81dk81jQFzc9YxKl98JOyxkX1k"
    echo "        c) BACKUP_S3_KEY [default: '']: s3 key, e.g. QFzc9YxKl98JOyxkX1kB4v6Khv484X81dk81j"
    echo "        d) BACKUP_S3_BUCKET [default: '']: s3 bucket, e.g. mybucket"
    echo "        e) BACKUP_S3_REGION [default: '']: s3 region, e.g. ap-nanjing"
    echo "        f) BACKUP_S3_COMPRESSION [default: '']: s3 compression"
    echo "        g) BACKUP_S3_ROLE_ARN [default: '']: s3 role arn"
    echo "        h) BACKUP_S3_IS_MINIO [default: 'no']: is minio type or not, choose from \"no\" | \"yes\""

    echo ""
    echo "  ------------------------- "
    echo "   3. For logical backups  "
    echo "  ------------------------- "
    echo "    1) BACKUP_MODUMP_PATH [default: /data/tools/mo_dump/mo-dump]: Path to mo-dump backup tool"
    echo "    2) BACKUP_LOGICAL_DB_LIST [OPTIONAL, default: all_no_sysdb]: (only valid when BACKUP_TYPE=logical) backup databases, seperated by ',' for each database."
    echo "       Note: 'all' and 'all_no_sysdb' are special settings. e.g. mo_ctl set_conf BACKUP_DB_LIST=\"db1,db2,db3\""
    echo "         a) all: all databases, including all system and user databases"
    echo "         b) all_no_sysdb: all databases, including all user databases, but no system databases"
    echo "         c) other settings by user: e.g. db1,db2,db3"
    echo "    3) BACKUP_LOGICAL_DATA_TYPE [OPTIONAL, default: csv]: (only valid when BACKUP_TYPE=logical) backup data type, choose from: insert | csv . e.g. mo_ctl set_conf BACKUP_DATA_TYPE=\"csv\""

}

function help_auto_backup()
{
    option="auto_backup"
    echo "Usage           : ${TOOL_NAME} ${option} [options]   # ${USAGE_AUTO_BACKUP}"
    echo " [options]      : available: enable | disable | status"
    echo "                : ${TOOL_NAME} ${option}             # same as ${TOOL_NAME} ${option} status"
    echo "                : ${TOOL_NAME} ${option} status      # check if auto backup is enabled or disabled"
    echo "  e.g.          : ${TOOL_NAME} ${option} enable      # enable auto backup for your databases"
    echo "                : ${TOOL_NAME} ${option} disable     # disable auto backup for your databases"

    help_bk_notes
}

function help_backup()
{
    option="backup"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_BACKUP}"
    echo "Usage           : ${TOOL_NAME} ${option} list        # list backup report in summary"
    echo "Usage           : ${TOOL_NAME} ${option} list detail # list backup report in detail(physical only)"
    help_bk_notes
}

function help_clean_backup()
{
    option="clean_backup"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_CLEAN_BACKUP}"
    help_bk_notes
}

function help_cl_notes()
{
    echo "  Note          : currently only supported on linux systems"
    echo "                : please set below configurations first before you run the [enable] option"
    echo "      1. CLEAN_LOGS_DAYS_BEFORE [OPTIONAL, default: 31]: clean old system log table data before [x] (default: 31) days. e.g. mo_ctl set_conf CLEAN_LOGS_DAYS_BEFORE=31"
    echo "      2. CLEAN_LOGS_TABLE_LIST [OPTIONAL, default: statement_info,rawlog,metric]: log tables to clean, choose one or multiple(seperated by ',') values from: statement_info | rawlog | metric. e.g. mo_ctl set_conf CLEAN_LOGS_TABLE_LIST=\"statement_info,rawlog,metric\""
    echo "      3. CLEAN_LOGS_CRON_SCHEDULE [OPTIONAL, default: 0 3 * * *]: cron to control auto clean of old system log table data. e.g. mo_ctl set_conf CLEAN_LOGS_CRON_SCHEDULE=\"0 3 * * *\""
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
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_AUTO_CLEAN_LOGS}"
    help_cl_notes
}

function help_build_image()
{
    option="build_image"
    echo "Usage           : ${TOOL_NAME} ${option}             # ${USAGE_BUILD_IMAGE}"
    echo "  Note          : please set below configurations first before you run the [enable] option"
    echo "      1. MO_PATH [OPTIONAL, default: /data/mo]: Path to MO source codes. e.g. mo_ctl set_conf MO_PATH=/data/mo"
    echo "      2. GOPROXY [OPTIONAL, default: https://goproxy.cn,direct]: Path to save target MO image"
    echo "      3. MO_BUILD_IMAGE_PATH [OPTIONAL, default: /tmp]: go proxy setting"
}

function help_monitor()
{
    option="monitor"
    echo "Usage           : ${TOOL_NAME} ${option} [option_1] [option_2]        # ${USAGE_MONITOR}"
    echo "  [option_1]    : deploy | uninstall | status | start | stop"
    echo "  e.g.          : ${TOOL_NAME} ${option} deploy          # deploy monitor system (online or offline)"
    echo "  [option_2] for deploy : online (default) | offline"
    echo "                : ${TOOL_NAME} ${option} uninstall       # uninstall monitor system"
    echo "                : ${TOOL_NAME} ${option} status          # check if monitor system is running"
    echo "                : ${TOOL_NAME} ${option} start           # start monitor system if not running"
    echo "                : ${TOOL_NAME} ${option} stop            # stop monitor system if running"
}



function help_1()
{
    echo "Usage             : ${TOOL_NAME} [option_1] [option_2]"
    echo ""
    echo "  [option_1]      : available: ${USAGE_OPTION_LIST}"
    echo "  auto_backup     : ${USAGE_AUTO_BACKUP}"
    echo "  auto_clean_logs : ${USAGE_AUTO_CLEAN_LOGS}"
    echo "  backup          : ${USAGE_BACKUP}"
    echo "  build_image     : ${USAGE_BUILD_IMAGE}"
    echo "  clean_backup    : ${USAGE_CLEAN_BACKUP}"
    echo "  clean_logs      : ${USAGE_CLEAN_LOGS}"
    echo "  connect         : ${USAGE_CONNECT}"
    echo "  csv_convert     : ${USAGE_CSV_CONVERT}"
    echo "  ddl_convert     : ${USAGE_DDL_CONVERT}"
    echo "  deploy          : ${USAGE_DEPLOY}"
    echo "  get_branch      : ${USAGE_UPGRADE}"
    echo "  get_cid         : ${USAGE_GET_CID}"
    echo "  get_conf        : ${USAGE_GET_CONF}"
    echo "  help            : ${USAGE_HELP}"
    echo "  monitor         : ${USAGE_MONITOR}"
    echo "  pprof           : ${USAGE_PPROF}"
    echo "  precheck        : ${USAGE_PRECHECK}"
    echo "  restart         : ${USAGE_RESTART}"
    echo "  set_conf        : ${USAGE_SET_CONF}"
    echo "  sql             : ${USAGE_SQL}"
    echo "  start           : ${USAGE_START}"
    echo "  status          : ${USAGE_STATUS}"
    echo "  stop            : ${USAGE_STOP}"
    echo "  uninstall       : ${USAGE_UNINSTALL}"
    echo "  upgrade         : ${USAGE_UPGRADE}"
    echo "  version         : ${USAGE_VERSION}"
    echo "  watchdog        : ${USAGE_WATCHDOG}"
    echo "  e.g.            : ${TOOL_NAME} status"
    echo ""
    echo "  [option_2]      : Use \" ${TOOL_NAME} [option_1] help \" to get more info"
    echo "  e.g.            : ${TOOL_NAME} deploy help "
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
        auto_clean_backup)
            help_auto_clean_logs
            ;;
        build_image)
            help_build_image
            ;;
        monitor)
            help_monitor
            ;;
        *)
            add_log "E" "invalid [option_1]: ${option_1}"
            help_1
            exit 1
            ;;
    esac
}


