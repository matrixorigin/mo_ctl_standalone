#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# watchdog

wd_name="watchdog"
WD_CRON_PATH="/etc/cron.d"
WD_CRON_FILE_NAME="mo_watchdog"
WD_CRON_FILE_PATH="${WD_CRON_PATH}/${WD_CRON_FILE_NAME}"
WD_CRON_SCHEDULE="* * * * *"
WD_CRON_USER=""
WD_CRON_SCRIPT="! /usr/local/bin/mo_ctl status && /usr/local/bin/mo_ctl start"
WD_CRON_CONTENT=""
WD_CRON_PLIST_NAME="com.matrixorigin.mo.watchdog"
WD_CRON_PLIST_FILE="${WORK_DIR}/bin/mo_watchdog.plist"
OS=""


function watchdog_status()
{

    if ! check_cron_service; then
        return 1
    fi

    if [[ "${OS}" == "Mac" ]]; then
        # 1. Mac
        add_log "D" "Check if ${WD_CRON_PLIST_NAME} is in launchctl list: launchctl list \"${WD_CRON_PLIST_NAME}\""
        if launchctl list "${WD_CRON_PLIST_NAME}"; then
            add_log "D" "Plist file with name ${WD_CRON_PLIST_NAME} is already set in launchctl list"
            add_log "I" "${wd_name} status：enabled"
        else
            add_log "D" "Plist file with name ${WD_CRON_PLIST_NAME} is not set in launchctl list"
            add_log "I" "${wd_name} status：disabled"
            return 1
        fi
    else
        # 2. Linux
        if [[ -f ${WD_CRON_PATH}/${WD_CRON_FILE_NAME} ]]; then
            add_log "D" "Cron file ${WD_CRON_PATH}/${WD_CRON_FILE_NAME} already exists, trying to get content: "
            content=`cat ${WD_CRON_PATH}/${WD_CRON_FILE_NAME}`
            add_log "D" "${content}"
            if [[ "${content}" == "" ]];then
                add_log "E" "Content seems to be empty, something might be wrong when enabling ${wd_name}." 
                add_log "D" "The correct content should be: ${WD_CRON_CONTENT}"
                add_log "I" "${wd_name} status：disabled"
                return 1
            fi
            add_log "I" "${wd_name} status：enabled"
        else
            add_log "I" "${wd_name} status：disabled"
            return 1
        fi
    fi
}

function watchdog_enable()
{
    if ! watchdog_status; then
        add_log "D" "Creating log folder: mkdir -p ${LOG_DIR}/${wd_name}/"
        mkdir -p ${LOG_DIR}/${wd_name}/

        if [[ "${OS}" == "Mac" ]]; then
            # 1. Mac
            current_user=`whoami`
            place_holder="PLACEHOLDER"
            add_log "I" "Replacing user in ${WD_CRON_PLIST_FILE}: sed -i \"\" \"s#${place_holder}#${current_user}#g\" ${WD_CRON_PLIST_FILE}"
            if sed -i "" "s#${place_holder}#${current_user}#g" ${WD_CRON_PLIST_FILE}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
            add_log "I" "Loading plist file : launchctl load -w ${WD_CRON_PLIST_FILE}"
            if launchctl load -w ${WD_CRON_PLIST_FILE}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
        else    
            # 2. Linux
            add_log "I" "Creating cron file ${WD_CRON_PATH}/${WD_CRON_FILE_NAME}"
            add_log "I" "Content: ${WD_CRON_CONTENT}"

            if sudo touch ${WD_CRON_PATH}/${WD_CRON_FILE_NAME} && sudo chown ${WD_CRON_USER} ${WD_CRON_PATH}/${WD_CRON_FILE_NAME} && sudo echo "${WD_CRON_CONTENT}"> ${WD_CRON_PATH}/${WD_CRON_FILE_NAME} ; then
                add_log "I" "Succeeded"
                sudo chown root:root ${WD_CRON_PATH}/${WD_CRON_FILE_NAME} 
            else
                add_log "E" "Failed"
                return 1
            fi
        fi
            watchdog_status
            return 0
    else
        add_log "I" "No need to enable ${wd_name} as it is already enabled, exiting"
        return 0

    fi
}

function watchdog_disable()
{
    if watchdog_status; then
        if [[ "${OS}" == "Mac" ]]; then        
            # 1. Mac
            add_log "I" "Disabling ${wd_name}: launchctl unload -w ${WD_CRON_PLIST_FILE}"
            if launchctl unload -w ${WD_CRON_PLIST_FILE}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
            current_user=`whoami`
            place_holder="PLACEHOLDER"
            add_log "I" "Replacing user in ${WD_CRON_PLIST_FILE}: sed -i \"\" \"s#${current_user}#${place_holder}#g\" ${WD_CRON_PLIST_FILE}"
            if sed -i "" "s#${current_user}#${place_holder}#g" ${WD_CRON_PLIST_FILE}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
        else
            # 2. Linux
            add_log "I" "Disabling ${wd_name} by removing cron file ${WD_CRON_PATH}/${WD_CRON_FILE_NAME}"
            if cd ${WD_CRON_PATH} && sudo rm -f ./${WD_CRON_FILE_NAME}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
        fi
        watchdog_status
    else
        add_log "I" "No need to disable ${wd_name} as it is already disabled, exiting"
        return 0
    fi
}



function watchdog()
{
    option=$1

    OS=`what_os`
    WD_CRON_USER=`whoami`

    date_expr="\$(date '+\\%Y\\%m\\%d_\\%H\\%M\\%S')"
    #WD_CRON_SCRIPT="`cat ${WORK_DIR}/bin/${WD_CRON_FILE_NAME}.sh`"
    WD_CRON_CONTENT="${WD_CRON_SCHEDULE} ${WD_CRON_USER} ${WD_CRON_SCRIPT}"
    #WD_CRON_CONTENT="${WD_CRON_SCHEDULE} ${WD_CRON_USER} ${WD_CRON_SCRIPT} > ${LOG_DIR}/${ab_name}/log.${date_expr}.log 2>&1"

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
            add_log "E" "Invalid option for ${wd_name}: ${option}"
            help_watchdog
            return 1
            ;;
    esac
}