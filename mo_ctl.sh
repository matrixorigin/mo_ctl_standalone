#!/bin/bash


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
    # "mysql_to_mo" "mysql_to_mo_mac" \
    "ddl_convert" "watchdog" "upgrade" "get_branch" \
)

for script in ${script_list[@]}; do
    source "${file_dir}/bin/${script}.sh"
done

os=`what_os`
# add_log "DEBUG" "Current OS: ${os}"
if [[ "${os}" == "Mac" ]] ; then
    source "${file_dir}/bin/mysql_to_mo_mac.sh"
else
    source "${file_dir}/bin/mysql_to_mo.sh"
fi 


p_ids=""

function main()
{
    rc=0
    option_1=$1
    option_2=$2
    option_3=$3
    option_4=$4
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
            shift
            set_conf $*
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
        *)
            add_log "ERROR" "Invalid option_1: ${option_1}, please refer to usage help info below"
            help_1
            cd ${current_path}
            return 1
            ;;
    esac
    
    rc=$?

    cd ${current_path}
    return ${rc}
}

main $*