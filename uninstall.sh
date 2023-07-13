#!/bin/bash
#uninstall.sh

function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"
    #format: 2023-07-13_15:37:40
    #nowtime=`date '+%F_%T'`
    #format: 2023-07-13_15:37:22.775
    nowtime=`date '+%Y-%m-%d_%H:%M:%S.%N'`
    nowtime=`echo "${nowtime}" | cut -b 1-23`
    
    case "${level}" in
        "e"|"E")
            level="ERROR"
            ;;
        "W"|"w")
            level="WARN" 
            ;;
        "I"|"i")
            level="INFO" 
            ;;
        "d"|"D")
            level="DEBUG" 
            ;;
        *)
            echo "These are valid log levels: E/e/W/w/I/i/D/d."
            echo "   E/e: ERROR, W/w: WARN, I/i: INFO, D/d: DEBUG"
            exit 1
        ;;
    esac 

    if [[ "${add_line}" == "n" ]]; then
        echo -n "${nowtime}    [${level}]    ${msg}"
    else
        echo "${nowtime}    [${level}]    ${msg}"
    fi
}


function to_lower()
{
    echo $(echo $1 | tr '[A-Z]' '[a-z]') 
}

function usage()
{
    echo "  Usage          : $0" # uninstalling mo_ctl tool, will need to input Yes/No to confirm or not
}


function tool_uninstall()
{
    mo_ctl_global_path=/usr/local/bin
    mo_ctl_local_path=~/mo_ctl

    add_log "W" "You're uninstalling mo_ctl tool, are you sure? (Yes/No)"
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "E" "User input not confirmed or timed out, exiting"
        return 1
    fi
    add_log "I" "Uninstalling mo_ctl now"
    add_log "I" "Removing path ${mo_ctl_local_path}"
    rm -rf ~/mo_ctl
    add_log "I" "Done"
    add_log "I" "Removing file ${mo_ctl_global_path}/mo_ctl"
    rm -f ${mo_ctl_global_path}/mo_ctl
    add_log "I" "Done"
    add_log "I" "All done, exiting"
}

function main()
{
    option=$1
    case "${option}" in
        "help")
            usage
            ;;
        *)
            tool_uninstall
            ;;
    esac
}

main $*