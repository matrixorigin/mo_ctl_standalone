#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# auto_clean_logs

acl_name="auto_clean_logs"
CLEAN_LOGS_CRON_PATH="/etc/cron.d"
CLEAN_LOGS_CRON_FILE_NAME="mo_clean_logs"
CLEAN_LOGS_CRON_USER=""
CLEAN_LOGS_CRON_SCRIPT="/usr/local/bin/mo_ctl clean_logs"
OS=""

function clean_logs() {
    clean_sysdb_logs_date=$(date -d "@$(($(date +%s) - CLEAN_LOGS_DAYS_BEFORE * 86400))" +%Y%m%d)
    add_log "I" "CLEAN_LOGS_DAYS_BEFORE: ${CLEAN_LOGS_DAYS_BEFORE}, clean date: ${clean_sysdb_logs_date}"
    for table in $(echo "${CLEAN_LOGS_TABLE_LIST}" | sed "s/,/ /g"); do
        sql="select PURGE_LOG('${table}', '${clean_sysdb_logs_date}');"
        add_log "I" "Clean log table: ${table}, sql: ${sql}"
        sql "${sql}"
    done
}

function auto_clean_logs_status() {
    rc=0

    if [[ "${OS}" == "Mac" ]]; then
        # 1. Mac
        # to do
        :
    else
        # 2. Linux
        if [[ -f ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME} ]]; then
            add_log "D" "Cron file ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME} for ${acl_name} already exists, trying to get content: "
            acl_content=$(cat ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME})
            add_log "D" "${acl_content}"
            if [[ "${acl_content}" == "" ]]; then
                add_log "E" "Content seems to be empty, something might be wrong when enabling ${acl_name}."
                add_log "D" "The correct content should be: ${CLEAN_LOGS_CRON_CONTENT}"
                add_log "I" "${acl_name} status：disabled"
                rc=1
            fi
            add_log "I" "${acl_name} status：enabled"
        else
            add_log "D" "Cron file ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME} for ${acl_name} does not exist"
            add_log "I" "${acl_name} status：disabled"
            rc=1
        fi

    fi

    return ${rc}
}

function auto_clean_logs_enable() {
    if [[ "${os}" == "Mac" ]]; then
        add_log "E" "Currently ${acl_name} is not supported on MacOS system"
    fi

    if ! check_cron_service; then
        return 1
    fi

    if ! auto_clean_logs_status; then
        add_log "I" "Enabling ${acl_name}"

        add_log "D" "Creating log folder: mkdir -p ${TOOL_LOG_PATH}/${acl_name}/"
        mkdir -p ${TOOL_LOG_PATH}/${acl_name}/

        if [[ "${OS}" == "Mac" ]]; then
            # 1. Mac
            # to do
            :
        else
            # 2. Linux
            add_log "I" "Creating cron file ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME} for ${acl_name}"
            add_log "D" "Content: ${CLEAN_LOGS_CRON_CONTENT}"

            if sudo touch ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME} && sudo chown ${CLEAN_LOGS_CRON_USER} ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME} && sudo echo "${CLEAN_LOGS_CRON_CONTENT}" > ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME}; then
                add_log "I" "Succeeded"
                sudo chown root:root ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME}
            else
                add_log "E" "Failed"
                return 1
            fi
        fi
        auto_clean_logs_status
    else
        add_log "I" "No need to enable ${acl_name} as it is already enabled, exiting"
        return 0
    fi

}

function auto_clean_logs_disable() {
    if auto_clean_logs_status; then
        if [[ "${OS}" == "Mac" ]]; then
            # 1. Mac
            # to do
            :
        else
            # 2. Linux
            add_log "I" "Disabling ${acl_name} by removing cron file ${CLEAN_LOGS_CRON_PATH}/${CLEAN_LOGS_CRON_FILE_NAME}"
            if cd ${CLEAN_LOGS_CRON_PATH} && sudo rm -f ./${CLEAN_LOGS_CRON_FILE_NAME}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
        fi
        auto_clean_logs_status
        return 0
    else
        add_log "I" "No need to disable ${acl_name} as it is already disabled, exiting"
        return 0
    fi
}

function auto_clean_logs() {
    option="$1"
    OS=$(what_os)
    CLEAN_LOGS_CRON_USER=$(whoami)

    # backup cron file and its content
    #yearmonth_expr="\$(date '+\\%Y\\%m\\%d_\\%H\\%M\\%S')"
    datetime_expr="\$(date '+\\%Y\\%m\\%d_\\%H\\%M\\%S')"
    CLEAN_LOGS_CRON_CONTENT="${CLEAN_LOGS_CRON_SCHEDULE} ${CLEAN_LOGS_CRON_USER} ${CLEAN_LOGS_CRON_SCRIPT} > ${TOOL_LOG_PATH}/${acl_name}/${datetime_expr}.log 2>&1"

    case "${option}" in
        "" | "status")
            auto_clean_logs_status
            ;;
        "enable")
            auto_clean_logs_enable
            ;;
        "disable")
            auto_clean_logs_disable
            ;;
        *)
            add_log "E" "Invalid option for ${acl_name}: ${option}"
            help_auto_clean_logs
            return 1
            ;;
    esac

}
