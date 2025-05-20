#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# uninstall

function check_uninstall_pre_requisites() {
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

function remove_cron_files() {
    add_log "I" "Removing cron task files"
    sudo rm -f /etc/cron.d/mo_backup
    sudo rm -f /etc/cron.d/mo_clean_old_backup
    sudo rm -f /etc/cron.d/mo_clean_logs
    sudo rm -f /etc/cron.d/mo_watchdog
}

function remove_matrixone_files() {
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

function uninstall() {
    get_conf MO_DEPLOY_MODE
    get_conf DAEMON_METHOD

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
        if ! check_uninstall_pre_requisites; then
            return 1
        fi

        add_log "W" "You're uninstalling MO container ${MO_CONTAINER_NAME} and image ${MO_CONTAINER_IMAGE}, are you sure? (Yes/No)"
        read_user_confirm

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
        read_user_confirm

        if ! check_uninstall_pre_requisites; then
            return 1
        fi

        if [[ "${DAEMON_METHOD}" == "systemd" ]]; then
            add_log "I" "Stopping and disabling matrixone service via systemd"
            sudo systemctl stop matrixone.service
            sudo systemctl disable matrixone.service
            add_log "I" "Removing systemd service file"
            sudo rm -f /etc/systemd/system/matrixone.service
            sudo systemctl daemon-reload
        fi

        remove_cron_files
        remove_matrixone_files
    fi
}
