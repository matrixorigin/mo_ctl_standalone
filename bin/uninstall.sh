#!/bin/bash
# uninstall

function check_uninstall_pre_requisites()
{
    rc=0
    add_log "INFO" "Checking pre-requisites before uninstalling MO"

    add_log "INFO" "Check if mo-service running"
    if mo_ctl status | grep "${MO_PATH}/matrixone"; then
        add_log "ERROR" "Detected mo-service running with path ${MO_PATH}/matrixone, please try to stop it first via 'mo_ctl stop [force]' before uninstalling mo"
        rc=1
    fi

    add_log "INFO" "Check if mo-service watchdog enabled"
    if mo_ctl watchdog; then
        add_log "ERROR" "mo-watchdog is enabled, please try to disable it via 'mo_ctl watchdog disable before uninstalling mo"
        rc=1
    fi

    if [[ "${rc}" == "1" ]]; then
        add_log "ERROR" "Check pre-requisites before uninstalling failed, exiting"
    else
        add_log "INFO" "Check pre-requisites before uninstalling succeeded"
    fi

    return ${rc}
}

function uninstall()
{
    add_log "WARN" "You're uninstalling MO from path ${MO_PATH}/matrixone, are you sure? (Yes/No)"
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "ERROR" "User input not confirmed or timed out, exiting"
        return 1
    fi

    if ! check_uninstall_pre_requisites; then
        return 1
    fi

    if [[ -d "${MO_PATH}/matrixone" ]]; then
        if cd ${MO_PATH} && rm -rf ./matrixone/; then
            add_log "INFO" "Uninstall MO succeeded."
        else
            add_log "ERROR" "Uninstall MO failed."
            return 1
        fi
    else
        add_log "INFO" "${MO_PATH}/matrixone does not exist, thus no need to uninstall"
    fi
}