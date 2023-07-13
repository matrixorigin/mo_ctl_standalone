#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# uninstall

function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"
    #format: 2023-07-13_15:37:40
    #nowtime=`date '+%F_%T'`
    #format: 2023-07-13_15:37:22.775
    notime=`date +%Y-%m-%d'_'%H:%M:%S.%N | cut -b 1-23`

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


function check_uninstall_pre_requisites()
{
    rc=0
    add_log "I" "Checking pre-requisites before uninstalling MO"

    add_log "I" "Check if mo-service running"
    if mo_ctl status | grep "${MO_PATH}/matrixone"; then
        add_log "E" "Detected mo-service running with path ${MO_PATH}/matrixone, please try to stop it first via 'mo_ctl stop [force]' before uninstalling mo"
        rc=1
    fi

    add_log "I" "Check if mo-service watchdog enabled"
    if mo_ctl watchdog; then
        add_log "E" "mo-watchdog is enabled, please try to disable it via 'mo_ctl watchdog disable before uninstalling mo"
        rc=1
    fi

    if [[ "${rc}" == "1" ]]; then
        add_log "E" "Check pre-requisites before uninstalling failed, exiting"
    else
        add_log "I" "Check pre-requisites before uninstalling succeeded"
    fi

    return ${rc}
}

function uninstall()
{
    add_log "W" "You're uninstalling MO from path ${MO_PATH}/matrixone, are you sure? (Yes/No)"
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "E" "User input not confirmed or timed out, exiting"
        return 1
    fi

    if ! check_uninstall_pre_requisites; then
        return 1
    fi

    if [[ -d "${MO_PATH}/matrixone" ]]; then
        if cd ${MO_PATH} && rm -rf ./matrixone/; then
            add_log "I" "Uninstall MO succeeded."
        else
            add_log "E" "Uninstall MO failed."
            return 1
        fi
    else
        add_log "I" "${MO_PATH}/matrixone does not exist, thus no need to uninstall"
    fi
}