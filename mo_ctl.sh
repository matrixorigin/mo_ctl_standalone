#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################

if ! pwd >/dev/null 2>&1; then
    nowtime="$(date '+%Y-%m-%d_%H:%M:%S.%N')"
    nowtime="$(echo "${nowtime}" | cut -b 1-23)"
    echo "${nowtime}    [ERROR]    You're currently on a path that no loner exists, please change to a valid directory and re-execute mo_ctl command"
    exit 1
fi

# Work dir
WORK_DIR=$(cd "$(dirname "$0")" || exit; pwd)
# conf
CONF_FILE="${WORK_DIR}/conf/env.sh"
CONF_FILE_DEFAULT="${WORK_DIR}/conf/env.sh.default"
# bin
BIN_DIR="${WORK_DIR}/bin"
# log
LOG_DIR="${WORK_DIR}/log"
# scripts
#SCRIPT_LIST=("basic" "help" "precheck" "deploy" \
#    "status" "start" "stop" "restart" \
#    "connect" "pprof" "set_conf" "get_conf" "get_cid" \
#    "mysql_to_mo" "ddl_convert" "watchdog" "upgrade" \
#    "get_branch" "uninstall" "sql" "csv_convert" \
#    "version" "auto_backup" "auto_clean_logs" \
#    "build_image" "monitor" "restore" \
#)
PIDS=""
MO_V_TYPE="unknown"

# Get confs and scripts
source "${CONF_FILE}"
for script in `ls ${BIN_DIR}/ | grep .sh`; do
    source "${BIN_DIR}/${script}"
done

function apply_env()
{
    for var in $(env | grep '^_CTL_' | cut -d= -f1); do
        name=${var#_CTL_}
        eval "$name=${!var}"
    done
}

function main()
{
    rc=0
    all_vars="$*"
    #var_2=`echo ${all_vars} | awk '{print $2}'`
    option_1=`echo "${all_vars}" | awk '{print $1}'`
    option_2=`echo "${all_vars}" | awk '{print $2}'`
    option_3=`echo "${all_vars}" | awk '{print $3}'`
    option_4=`echo "${all_vars}" | awk '{print $4}'`

    # deprecated
    # option_1=$1
    # option_2=$2
    # option_3=$3
    # option_4=$4


    if [[ ${option_2} == "help" ]]; then
        help_2
        return 0
    fi

    current_path=`pwd`

    # apply the envs.
    apply_env

    if [ "x$CTL_LOG_DIR" != "x" ]; then
        mkdir -p $CTL_LOG_DIR
        CTL_LOG_FILE=$CTL_LOG_DIR/`date '+%Y%m%d_%H%M%S'`-`hostname`.log
    fi

    case "${option_1}" in
        "" | "help")
            help_1
            ;;
        "precheck")
            precheck
            ;;
        "deploy")
            deploy "${option_2}" "${option_3}" "${option_4}"
            ;;
        "status")
            status
            ;;
        "start")
            start
            ;;
        "stop")
            stop "${option_2}"
            ;;
        "restart")
            restart "${option_2}"
            ;;
        "connect")
            connect
            ;;
        "get_cid")
            get_cid "${option_2}"
            ;;
        "pprof")
            pprof "${option_2}" "${option_3}"
            ;;
        "set_conf")
            shift_vars=`echo "${all_vars#* }"`
            if [[ -s "${option_2}" ]]; then
                add_log "I" "Option 1 ${option_1} is a file, will set_conf based on it and ignore the rest options"
                set_conf_by_file "${shift_vars}"
            else
                if  [[ "${option_2}" == "" ]]; then
                    add_log "E" "Set content is empty, please check again"
                    help_set_conf
                    return 1
                fi
                set_conf "${shift_vars}"
            fi
            ;;
        "get_conf")
            get_conf "${option_2}" "${option_3}"
            ;;
        "ddl_convert")
            ddl_convert "${option_2}" "${option_3}" "${option_4}"
            ;;
        "watchdog")
            watchdog "${option_2}"
            ;;
        "upgrade")
            upgrade "${option_2}"
            ;;
        "get_branch")
            get_branch "${option_2}"
            ;;
        "uninstall")
            uninstall
            ;;
        "sql")
            if [[ "${option_2}" == "" ]]; then
                add_log "E" "Query is empty, please check again"
                help_sql
                return 1
            fi
            #shift_vars=`echo "${all_vars#* }"`
            shift_vars="${all_vars#* }"
            sql "${shift_vars}"
            ;;
        "csv_convert")
            csv_convert
            ;;
        "version")
            version
            ;;
        "auto_backup")
            auto_backup "${option_2}" "${option_3}"
            ;;
        "backup")
            if [[ "${option_2}" == "list" ]]; then
                backup_list "${option_3}"
            else
                if [ -z "$BACKUP_S3_ID" -a ! -z $AWS_ACCESS_KEY_ID ]; then
                    eval "BACKUP_S3_ID=$AWS_ACCESS_KEY_ID"
                fi
                if [ -z "$BACKUP_S3_KEY" -a ! -z $AWS_SECRET_ACCESS_KEY ]; then
                    eval "BACKUP_S3_KEY=$AWS_SECRET_ACCESS_KEY"
                fi
                backup
            fi
            ;;
        "restore")
            if [[ "${option_2}" == "list" ]]; then
                restore_list "${option_3}"
            else
                restore
            fi
            ;;
        "clean_backup")
            clean_backup
            ;;
        "clean_logs")
            clean_logs
            ;;
        "auto_clean_logs")
            auto_clean_logs "${option_2}"
            ;;
        "build_image")
            build_image
            ;;
        "monitor")
            monitor "${option_2}" "${option_3}"
            ;;
        "basic")
            "${option_2}" "${option_3}" "${option_4}" 
            ;;

        "auto_log_rotate")
            auto_log_rotate "${option_2}"
            ;;
        "datax")
            if [[ "${option_2}" == "list" ]]; then
                datax_report_list
            else
                datax
            fi
            ;;

        *)
            add_log "E" "Invalid option_1: ${option_1}, please refer to usage help info below"
            help_1
            cd "${current_path}" || exit
            return 1
            ;;
    esac
    
    rc=$?

    cd "${current_path}" || exit
    return ${rc}
}

main "$*"
