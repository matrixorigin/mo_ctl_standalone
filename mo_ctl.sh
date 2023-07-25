#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################

if ! pwd >/dev/null 2>&1; then
    nowtime="`date '+%Y-%m-%d_%H:%M:%S.%N'`"
    nowtime="`echo "${nowtime}" | cut -b 1-23`"
    echo "${nowtime}    [ERROR]    You're currently on a path that no loner exists, please change to a valid directory and re-execute mo_ctl command"
    exit 1
fi

# File dir
file_dir=`cd "$(dirname "$0")" || exit; pwd`

# Get confs and scripts
# confs
CONF_FILE="${file_dir}/conf/env.sh"
source "${CONF_FILE}"
# scripts
script_list=("basic" "help" "precheck" "deploy" \
    "status" "start" "stop" "restart" \
    "connect" "pprof" "set_conf" "get_conf" "get_cid" \
    "mysql_to_mo" "ddl_convert" "watchdog" "upgrade" \
    "get_branch" "uninstall" "sql" \
)

for script in ${script_list[@]}; do
    source "${file_dir}/bin/${script}.sh"
done

p_ids=""

function main()
{
    rc=0
    all_vars="$*"
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

    case "${option_1}" in
        "" | "help")
            help_1
            ;;
        "precheck")
            precheck
            ;;
        "deploy")
            deploy ${option_2} ${option_3}
            ;;
        "status")
            status
            ;;
        "start")
            start
            ;;
        "stop")
            stop ${option_2}
            ;;
        "restart")
            restart ${option_2}
            ;;
        "connect")
            connect
            ;;
        "get_cid")
            get_cid ${option_2}
            ;;
        "pprof")
            pprof ${option_2} ${option_3} 
            ;;
        "set_conf")
            shift_vars=`echo "${all_vars#* }"`
            set_conf "${shift_vars}"
            ;;
        "get_conf")
            get_conf ${option_2}
            ;;
        "ddl_convert")
            ddl_convert ${option_2} ${option_3} ${option_4}
            ;;
        "watchdog")
            watchdog ${option_2}
            ;;
        "upgrade")
            upgrade ${option_2}
            ;;
        "get_branch")
            get_branch ${option_2}
            ;;
        "uninstall")
            uninstall
            ;;
        "sql")
            shift_vars=`echo "${all_vars#* }"`
            sql "${shift_vars}"
            ;;
        *)
            add_log "E" "Invalid option_1: ${option_1}, please refer to usage help info below"
            help_1
            cd ${current_path}
            return 1
            ;;
    esac
    
    rc=$?

    cd ${current_path}
    return ${rc}
}

main "$*"