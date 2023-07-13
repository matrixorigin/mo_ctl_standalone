#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# watchdog

CRON_PATH="/etc/cron.d"
CRON_FILE_NAME="mo_watchdog"
CRON_FILE_PATH="${CRON_PATH}/${CRON_FILE_NAME}"
CRON_SCHEDULE="* * * * *"
CRON_USER=`whoami`
CRON_SCRIPT="! /usr/local/bin/mo_ctl status && /usr/local/bin/mo_ctl start > /dev/null 2>&1"
CRON_CONTENT="${CRON_SCHEDULE} ${CRON_USER} ${CRON_SCRIPT}"

function watchdog_check_cron()
{
    add_log "I" "Get status of service cron which mo-watchdog depends on."
    if systemctl status cron >/dev/null 2>&1 || service cron status >/dev/null 2>&1 || systemctl status crond >/dev/null 2>&1 || service crond status >/dev/null 2>&1; then
        add_log "I" "Succeeded. Service cron seems to be running."
    else
        add_log "E" "Failed. Please check again via 'systemctl status conrb' to make sure it's running. Or try to restart it via 'systemctl restart cron'."
        return 1
    fi
}

function watchdog_status()
{
    if ! watchdog_check_cron; then
        return 1
    fi

    if [[ -f ${CRON_PATH}/${CRON_FILE_NAME} ]]; then
        add_log "I" "Cron file ${CRON_PATH}/${CRON_FILE_NAME} already exists, trying to get content: "
        content=`cat ${CRON_PATH}/${CRON_FILE_NAME}`
        add_log "I" "${content}"
        if [[ "${content}" == "" ]];then
            add_log "E" "Content seems to be empty, something might be wrong when enabling watchdog." 
            add_log "I" "The correct content should be: ${CRON_CONTENT}"
            add_log "I" "mo_watchdog status： disabled"
            return 1
        fi
        add_log "I" "mo_watchdog status： enabled"
    else
        add_log "I" "mo_watchdog status： disabled"
        return 1
    fi
}

function watchdog_enable()
{
    if ! watchdog_status; then
        add_log "I" "Creating cron file ${CRON_PATH}/${CRON_FILE_NAME}"
        add_log "I" "Content: ${CRON_CONTENT}"

        if sudo touch ${CRON_PATH}/${CRON_FILE_NAME} && sudo chown ${CRON_USER} ${CRON_PATH}/${CRON_FILE_NAME} && sudo echo "${CRON_CONTENT}"> ${CRON_PATH}/${CRON_FILE_NAME} ; then
            add_log "I" "Succeeded"
            sudo chown root:root ${CRON_PATH}/${CRON_FILE_NAME} 
        else
            add_log "E" "Failed"
            return 1
        fi

        watchdog_status
        return 0
    else
        add_log "I" "No need to enable MO watchdog as it is already enabled, exiting"
        return 0

    fi
}

function watchdog_disable()
{
    if watchdog_status; then
        add_log "I" "Disabling mo_watchdog by removing cron file ${CRON_PATH}/${CRON_FILE_NAME}"
        if cd ${CRON_PATH} && sudo rm -f ./${CRON_FILE_NAME}; then
            add_log "I" "Succeeded"
        else
            add_log "E" "Failed"
            return 1
        fi
        watchdog_status
        return 0
    else
        add_log "I" "No need to disable MO watchdog as it is already disabled, exiting"
        return 0
    fi
}



function watchdog()
{
    option=$1

    case "${option}" in
        "" | "status")
            watchdog_status
            ;;
        "enable")
            watchdog_enable
            ;;
        "disable")
            watchdog_disable
            ;;
        *)
            add_log "E" "Invalid option for watchdog: ${option}"
            help_watchdog
            return 1
            ;;
    esac
}