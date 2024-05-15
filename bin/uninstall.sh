#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# uninstall

function check_uninstall_pre_requisites()
{
    rc=0
    add_log "I" "Checking pre-requisites before uninstalling MO"

    add_log "I" "Check if mo-service running"

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
        if mo_ctl status; then
            add_log "E" "Detected mo container named ${MO_CONTAINER_NAME} running, please try to stop it first via 'mo_ctl stop [force]' before uninstalling mo"
            rc=1
        fi
    else
        if mo_ctl status | grep "${MO_PATH}/matrixone"; then
            add_log "E" "Detected mo-service running with path ${MO_PATH}/matrixone, please try to stop it first via 'mo_ctl stop [force]' before uninstalling mo"
            rc=1
        fi
    fi

    add_log "I" "Check if mo-service watchdog enabled"
    if mo_ctl watchdog; then
        add_log "E" "mo-watchdog is enabled, please try to disable it via 'mo_ctl watchdog disable' before uninstalling mo"
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

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then


        if ! check_uninstall_pre_requisites; then
            return 1
        fi

        add_log "W" "You're uninstalling MO container ${MO_CONTAINER_NAME} and image ${MO_CONTAINER_IMAGE}, are you sure? (Yes/No)"
        read -t 30 user_confirm
        if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
            add_log "E" "User input not confirmed or timed out, exiting"
            return 1
        fi

        add_log "I" "Removing container ${MO_CONTAINER_NAME}"
        if ! docker rm ${MO_CONTAINER_NAME}; then
            add_log "E" "Failed"
            add_log "E" "Uninstall MO failed."
            return 1
        fi



        add_log "I" "Removing image ${MO_CONTAINER_IMAGE}"
        if ! docker rmi ${MO_CONTAINER_IMAGE}; then
            add_log "E" "Failed"
            add_log "E" "Uninstall MO failed."
            return 1
        fi

        add_log "I" "Uninstall MO succeeded."


    else
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

    fi
}