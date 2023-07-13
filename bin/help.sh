#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# help

#confs
TOOL_NAME="mo_ctl"
USAGE_CONNECT="connect to mo via mysql client using connection info configured"
USAGE_DDL_CONVERT="convert ddl file to mo format from other types of database"
USAGE_DEPLOY="deploy mo onto the path configured"
USAGE_GET_BRANCH="print which git branch mo is currently on"
USAGE_GET_CID="print mo git commit id from the path configured"
USAGE_GET_CONF="get configurations"
USAGE_HELP="print help information"
USAGE_PATH="print mo path configured"
USAGE_PRECHECK="check pre-requisites for mo_ctl"
USAGE_PPROF="collect pprof information"
USAGE_RESTART="a combination operation of stop and start"
USAGE_SET_CONF="set configurations"
USAGE_SQL="execute sql from string, or a file or a path containg multiple files"
USAGE_STATUS="check if there's any mo process running on this machine"
USAGE_START="start mo-service from the path configured"
USAGE_STOP="stop all mo-service processes found on this machine"
USAGE_UNINSTALL="uninstall mo from path MO_PATH=${MO_PATH}/matrixone"
USAGE_UPGRADE="upgrade or downgrade mo from current version to a target commit id or stable version"
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
    option="setconf"
    echo "Usage         : ${TOOL_NAME} ${option} [conf_list] # ${USAGE_SET_CONF}"
    echo " [conf_list]  : configuration list in key=value format, seperated by comma"
    echo "  e.g.        : ${TOOL_NAME} ${option} MO_PATH=/data/mo/20230629/matrixone,MO_PW=M@trix0riginR0cks,MO_PORT=6101  # set multiple configurations"
    echo "              : ${TOOL_NAME} ${option} MO_PATH=/data/mo/20230629/matrixone                                       # set single configuration"
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

function help_1()
{
    echo "Usage             : ${TOOL_NAME} [option_1] [option_2]"
    echo ""
    echo "  [option_1]      : available: connect | ddl_connect | deploy | get_branch | get_cid | get_conf | help | pprof | precheck | query | restart | set_conf | start | status | stop | uninstall | upgrade | watchdog"
    echo "  1) connect      : ${USAGE_CONNECT}"
    echo "  2) ddl_convert  : ${USAGE_DDL_CONVERT}"
    echo "  3) deploy       : ${USAGE_DEPLOY}"
    echo "  4) get_branch   : ${USAGE_UPGRADE}"
    echo "  5) get_cid      : ${USAGE_GET_CID}"
    echo "  6) get_conf     : ${USAGE_GET_CONF}"
    echo "  7) help         : ${USAGE_HELP}"
    echo "  8) pprof        : ${USAGE_PPROF}"
    echo "  9) precheck     : ${USAGE_PRECHECK}"
    echo "  10) restart     : ${USAGE_START}"
    echo "  11) set_conf    : ${USAGE_SET_CONF}"
    echo "  12) sql         : ${USAGE_SQL}"
    echo "  13) start       : ${USAGE_START}"
    echo "  14) status      : ${USAGE_STATUS}"
    echo "  15) stop        : ${USAGE_STOP}"
    echo "  16) uninstall   : ${USAGE_UNINSTALL}"
    echo "  17) upgrade     : ${USAGE_UPGRADE}"
    echo "  18) watchdog    : ${USAGE_WATCHDOG}"
    echo "  e.g.            : ${TOOL_NAME} status"
    echo ""
    echo "  [option_2]      : Use \" ${TOOL_NAME} [option_1] help \" to get more info"
    echo "  e.g.            : ${TOOL_NAME} deploy help "
}



function help_2()
{
    option=$1
    case ${option_1} in
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
        *)
            add_log "E" "invalid [option_1]: ${option_1}"
            help_1
            exit 1
            ;;
    esac
}


