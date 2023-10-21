#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# auto_backup

ab_name="auto_backup"
cb_name="auto_clean_old_backup"
BACKUP_CRON_PATH="/etc/cron.d"
BACKUP_CRON_FILE_NAME="mo_backup"
BACKUP_CRON_USER=""
BACKUP_CRON_SCRIPT="/usr/local/bin/mo_ctl backup"
BACKUP_CRON_CONTENT=""
BACKUP_SYSDB_LIST="mo_task,information_schema,mysql,system_metrics,system,mo_catalog"
CLEAN_BK_CRON_FILE_NAME="mo_clean_old_backup"
CLEAN_BK_CRON_SCRIPT="/usr/local/bin/mo_ctl clean_backup"

# Mac: to do
# BACKUP_CRON_PLIST_NAME="com.matrixorigin.mo.autobacup"
# BACKUP_CRON_PLIST_FILE="${WORK_DIR}/bin/mo_autobacup.plist"
OS=""


function backup()
{
    add_log "I" "Backup type: ${BACKUP_TYPE}, backup databases: ${BACKUP_DB_LIST}"

    all_dbs=`MYSQL_PWD="${MO_PW}" mysql -u"${MO_USER}" -P"${MO_PORT}" -h"${MO_HOST}" -e "show databases" -N -s`
    add_log "D" "All databases in current system: ${all_dbs}"

    backup_db_list=""
    case "${BACKUP_DB_LIST}" in
        "all")
            backup_dbs=`echo "${all_dbs}" | tr ' ' ','`
            ;;
        "all_no_sysdb")
            for db in ${all_dbs}; do
                if echo "${BACKUP_SYSDB_LIST}" | grep -v "${db}" >/dev/null 2>&1; then
                    backup_db_list="${backup_db_list},${db}"
                fi
            done

            len=${#backup_db_list}
            start_pos=1
            backup_db_list=${backup_db_list:${start_pos}:${len}}
            ;;
        *)
            backup_db_list=${BACKUP_DB_LIST}
            ;;
    esac

    if [[ "${backup_db_list}" == "" ]]; then
        add_log "E" "Final backup database list seems to be empty, please check conf BACKUP_DB_LIST"
        return 1
    fi

    backup_timestamp=`date '+%Y%m%d_%H%M%S'`
    case "${BACKUP_TYPE}" in
        "logical")
            csv_option=""
            if [[ "${BACKUP_DATA_TYPE}" == "csv" ]]; then
                csv_option="-csv"
            fi
            add_log "D" "Creating backup direcory: mkdir -p ${BACKUP_PATH}/${backup_timestamp}/"
            mkdir -p ${BACKUP_PATH}/${backup_timestamp}/
            for db in $(echo "${backup_db_list}" | sed "s/,/ /g"); do
                add_log "I" "Begin to back up database: ${db}"

                startTime=`get_nanosecond`
                add_log "D" "Backup command: cd ${BACKUP_PATH}/${backup_timestamp}/ && ${MO_PATH}/matrixone/mo-dump -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${db} ${csv_option} > ${BACKUP_PATH}/${backup_timestamp}/${db}.sql && cd -"
                if cd ${BACKUP_PATH}/${backup_timestamp}/ && ${MO_PATH}/matrixone/mo-dump -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${db} ${csv_option} > ${BACKUP_PATH}/${backup_timestamp}/${db}.sql && cd - >/dev/null 2>&1; then
                    endTime=`get_nanosecond`
                    outcome="outcome"
                else
                    endTime=`get_nanosecond`
                    outcome="failed"

                fi
                cost=`time_cost_ms ${startTime} ${endTime}`

                add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"
            done
            ;;
        "physical")
            # to do until mo_br is ready
            add_log "E" "Currently only 'logical' is supported"
            return 1
            ;;

        *)
            add_log "E" "Invalid backup type ${BACKUP_TYPE}, valid range: logical(default) | physical"
            return 1
            ;;
    esac
}



function clean_backup()
{
    add_log "I" "Cleaning backups before ${BACKUP_CLEAN_DAYS_BEFORE} days"
    clean_date=`date -d "${BACKUP_CLEAN_DAYS_BEFORE} day ago" +%Y%m%d`
    add_log "I" "Clean date: ${clean_date}"
    for backup_dir in `ls ${BACKUP_PATH}`; do
        backup_date=`echo "${backup_dir}" | awk -F"_" '{print $1}'`
        backup_date_int=`date -d "${backup_date}" +%s`
        clean_date_int=`date -d "${clean_date}" +%s`
        if [[ ${backup_date_int} -le ${clean_date_int} ]]; then
            add_log "I" "Backup directory : ${backup_dir}, action: delete"
            if cd ${BACKUP_PATH} && rm -rf ./${backup_dir}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
            fi
        else
            add_log "I" "Backup directory : ${backup_dir}, action: skip"
        fi
    done
}

function auto_backup_status()
{
    rc=0
    if [[ "${OS}" == "Mac" ]]; then
        # 1. Mac
        # to do
        :
    else
        # 2. Linux

        # auto backup
        if [[ -f ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} ]]; then
            add_log "D" "Cron file ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} for ${ab_name} already exists, trying to get content: "
            bk_content=`cat ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME}`
            add_log "D" "${bk_content}"
            if [[ "${bk_content}" == "" ]];then
                add_log "E" "Content seems to be empty, something might be wrong when enabling ${ab_name}." 
                add_log "D" "The correct content should be: ${BACKUP_CRON_CONTENT}"
                add_log "I" "${ab_name} status：disabled"
                rc=1
            fi
            add_log "I" "${ab_name} status：enabled"
        else
            add_log "D" "Cron file ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} for ${ab_name} does not exist"
            add_log "I" "${ab_name} status：disabled"
            rc=1
        fi

        # auto clean old backups
        if [[ -f ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} ]]; then
            add_log "D" "Cron file ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} for ${cb_name} already exists, trying to get content: "
            clean_content=""
            clean_content=`cat ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME}`
            add_log "D" "${clean_content}"
            if [[ "${clean_content}" == "" ]];then
                add_log "E" "Content seems to be empty, something might be wrong when enabling ${cb_name}." 
                add_log "D" "The correct content should be: ${CLEAN_BK_CRON_CONTENT}"
                add_log "I" "${cb_name} status：disabled"
                rc=1
            fi
            add_log "I" "${cb_name} status：enabled"
        else
            add_log "D" "Cron file ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} for ${cb_name} does not exist"
            add_log "I" "${cb_name} status：disabled"
            rc=1
        fi
    fi

    return ${rc}
}


function auto_backup_enable()
{

    if [[ "${os}" == "Mac" ]]; then
        add_log "E" "Currently ${ab_name} is not supported on MacOS system"
    fi

    if ! check_cron_service; then
        return 1
    fi

    if ! auto_backup_status; then
        add_log "I" "Enabling ${ab_name} and ${cb_name}"
        
        add_log "D" "Creating log folder: mkdir -p ${LOG_DIR}/${ab_name}/ ${LOG_DIR}/${cb_name}/"
        mkdir -p ${LOG_DIR}/${ab_name}/ ${LOG_DIR}/${cb_name}/

        if [[ "${OS}" == "Mac" ]]; then
            # 1. Mac
            # to do
            :
        else    
            # 2. Linux
            add_log "I" "Creating cron file ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} for ${ab_name}"
            add_log "D" "Content: ${BACKUP_CRON_CONTENT}"

            if sudo touch ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} && sudo chown ${BACKUP_CRON_USER} ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} && sudo echo "${BACKUP_CRON_CONTENT}"> ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} ; then
                add_log "I" "Succeeded"
                sudo chown root:root ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} 
            else
                add_log "E" "Failed"
                return 1
            fi

            add_log "I" "Creating cron file ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} for ${cb_name}"

            if sudo touch ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} && sudo chown ${BACKUP_CRON_USER} ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} && sudo echo "${CLEAN_BK_CRON_CONTENT}"> ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} ; then
                add_log "I" "Succeeded"
                sudo chown root:root ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME} 
            else
                add_log "E" "Failed"
                return 1
            fi

        fi
        auto_backup_status
    else
        add_log "I" "No need to enable ${ab_name} as it is already enabled, exiting"
        return 0

    fi

}

function auto_backup_disable()
{
    if auto_backup_status; then
        if [[ "${OS}" == "Mac" ]]; then        
            # 1. Mac
            # to do
            :
        else
            # 2. Linux
            add_log "I" "Disabling ${ab_name} by removing cron file ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME}"
            if cd ${BACKUP_CRON_PATH} && sudo rm -f ./${BACKUP_CRON_FILE_NAME}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi
            add_log "I" "Disabling auto clean old backups by removing cron file ${BACKUP_CRON_PATH}/${CLEAN_BK_CRON_FILE_NAME}"
            if cd ${BACKUP_CRON_PATH} && sudo rm -f ./${CLEAN_BK_CRON_FILE_NAME}; then
                add_log "I" "Succeeded"
            else
                add_log "E" "Failed"
                return 1
            fi

        fi
        auto_backup_status
        return 0
    else
        add_log "I" "No need to disable ${ab_name} as it is already disabled, exiting"
        return 0
    fi
}



function auto_backup()
{
    option=$1
    OS=`what_os`
    BACKUP_CRON_USER=`whoami`

    # backup cron file and its content 
    date_expr="\$(date '+\\%Y\\%m\\%d_\\%H\\%M\\%S')"
    BACKUP_CRON_CONTENT="${BACKUP_CRON_SCHEDULE} ${BACKUP_CRON_USER} ${BACKUP_CRON_SCRIPT} > ${LOG_DIR}/${ab_name}/log.${date_expr}.log 2>&1"

    # clean up for old backups cron file and its content     
    CLEAN_BK_CRON_CONTENT="${BACKUP_CLEAN_CRON_SCHEDULE} ${BACKUP_CRON_USER} ${CLEAN_BK_CRON_SCRIPT} > ${LOG_DIR}/${cb_name}/log.${date_expr} 2>&1"


    case "${option}" in
        "" | "status")
            auto_backup_status
            ;;
        "enable")
            auto_backup_enable
            ;;
        "disable")
            auto_backup_disable
            ;;
        *)
            add_log "E" "Invalid option for ${ab_name}: ${option}"
            help_auto_backup
            return 1
            ;;
    esac

}
