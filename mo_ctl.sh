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
    "mysql_to_mo" "mysql_to_mo_mac" "ddl_convert" \
)

for script in ${script_list[@]}; do
    source "${file_dir}/bin/${script}.sh"
done


p_ids=""

function main()
{
    option_1=$1
    option_2=$2
    option_3=$3
    option_4=$4
    if [[ ${option_2} == "help" ]]; then
        help_2
        exit 0
    fi

    case ${option_1} in
        help)
            help_1
            ;;
        precheck)
            precheck
            ;;
        deploy)
            deploy ${option_2} ${option_3}
            ;;
        status)
            status
            ;;
        start)
            start
            ;;
        stop)
            stop ${option_2}
            ;;
        restart)
            restart
            ;;
        connect)
            connect
            ;;
        get_cid)
            get_cid
            ;;
        pprof)
            pprof ${option_2} ${option_3} 
            ;;
        set_conf)
            set_conf ${option_2}
            ;;
        get_conf)
            get_conf ${option_2}
            ;;
        ddl_convert)
            ddl_convert ${option_2} ${option_3} ${option_4}
            ;;
        *)
            add_log "ERROR" "Invalid option_1 ${option_1}"
            help_1
            exit 1
            ;;
    esac

}

main $*
