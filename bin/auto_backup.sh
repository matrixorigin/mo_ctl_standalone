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
BACKUP_MOBR_DIRNAME=""
# Mac: to do
# BACKUP_CRON_PLIST_NAME="com.matrixorigin.mo.autobacup"
# BACKUP_CRON_PLIST_FILE="${WORK_DIR}/bin/mo_autobacup.plist"
OS=""

function backup_precheck()
{

    option=$1

    case "${option}" in
        "mo")
            if [[ "${MO_SERVER_TYPE}" == "local" ]]; then
                if ! status; then
                    add_log "E" "MO seems not to be running, please make sure mo-service is running before performing a backup"
                    return 1
                fi
            fi
            ;;
        "mobr")
            if [[ ! -f ${BACKUP_MOBR_PATH} ]] ; then
                add_log "E" "BACKUP_MOBR_PATH ${BACKUP_MOBR_PATH} is not a file or does not exist, please check again, exiting"
                return 1
            fi
            ;;
        "modump")
            if [[ ! -f ${BACKUP_MODUMP_PATH} ]] ; then
                add_log "E" "BACKUP_MODUMP_PATH ${BACKUP_MODUMP_PATH} is not a file or does not exist, please check again, exiting"
                return 1
            fi
            ;;
        *)
            add_log "E" "Invalid option for backup_precheck: ${option}"
            return 1
            ;;
    esac    

}

function backup_list()
{

    option="$1"
    BACKUP_MOBR_DIRNAME=`dirname "${BACKUP_MOBR_PATH}"`

    if [[ "${option}" == "detail" ]]; then
        
        if [[ ! -f ${BACKUP_MOBR_PATH} ]] ; then
            add_log "E" "BACKUP_MOBR_PATH ${BACKUP_MOBR_PATH} is not a file or does not exist, please check again, exiting"
            return 1
        fi


        add_log "I" "Listing backup report (detail, physical only)"
        add_log "I" "------------------------------------"
        cd ${BACKUP_MOBR_DIRNAME} && ./mo_br list
    else
        if [[ ! -f ${BACKUP_REPORT} ]]; then
            add_log "E" "No backup action can be found, exiting"
            return 1 
        fi
        add_log "I" "Listing backup report (summary)"
        add_log "I" "------------------------------------"
        cat ${BACKUP_REPORT}
    fi
}

function backup()
{

    ! backup_precheck "mo" && return 1

    add_log "I" "Backup settings"
    add_log "I" "------------------------------------"
    get_conf | grep BACKUP
    add_log "I" "------------------------------------"


    add_log "I" "Backup starts"

    backup_yearmonth=`date '+%Y%m'`
    backup_timestamp=`date '+%Y%m%d_%H%M%S'`
    
    add_log "D" "Creating backup data direcory: mkdir -p ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/"
    mkdir -p ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/

    backup_report_path=`dirname "${BACKUP_REPORT}"`
    add_log "D" "Creating backup report direcory: mkdir -p ${backup_report_path}"
    mkdir -p ${backup_report_path}
    if [[ ! -f "${BACKUP_REPORT}" ]]; then
        add_log "D" "Creating backup report file ${BACKUP_REPORT}"
        echo "backup_date | db_list | backup_type | backup_path | logical_data_type | duration_ms | outcome" > "${BACKUP_REPORT}"
    fi
 
    backup_db_list=""
    backup_conf_db_list="${BACKUP_LOGICAL_DB_LIST}"
    logical_data_type=""

    case "${BACKUP_TYPE}" in
        # 1) logical backups : mo_dump
        "logical")
            logical_data_type=${BACKUP_LOGICAL_DATA_TYPE}

            ! backup_precheck "modump" && return 1

            all_dbs=`MYSQL_PWD="${MO_PW}" mysql -u"${MO_USER}" -P"${MO_PORT}" -h"${MO_HOST}" -e "show databases" -N -s`
            add_log "D" "All databases in current system: ${all_dbs}"

            case "${BACKUP_LOGICAL_DB_LIST}" in
                "all")
                    backup_db_list=`echo "${all_dbs}" | tr ' ' ','`
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
                    backup_db_list=${BACKUP_LOGICAL_DB_LIST}
                    ;;
            esac
            
            add_log "D" "backup_db_list: ${backup_db_list}"
            if [[ "${backup_db_list}" == "" ]]; then
                add_log "E" "Final backup database list seems to be empty, please check conf BACKUP_LOGICAL_DB_LIST"
                return 1
            fi


            csv_option=""
            no_data_option=""
            if [[ "${BACKUP_LOGICAL_DATA_TYPE}" == "csv" ]]; then
                csv_option="-csv"
            elif [[ "${BACKUP_LOGICAL_DATA_TYPE}" == "ddl" ]]; then
                no_data_option="-no-data"
            fi

            # 1. in case we have multiple databases
            if echo "${backup_db_list}" | grep "," >/dev/null 2>&1 ; then
                add_log "W" "backup_db_list=${backup_db_list} seems to be a list containing multiple dbs, thus will ignore conf BACKUP_LOGICAL_TBL_LIST=${BACKUP_LOGICAL_TBL_LIST} and backup databases in db list only"

                # 1.1. backup databases one by one
                if [[ "${BACKUP_LOGICAL_ONEBYONE}" == "1" ]]; then
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is set to 1, will backup tables one by one"
                
                    for db in $(echo "${backup_db_list}" | sed "s/,/ /g"); do
                        add_log "I" "Begin to back up database: ${db}"

                        add_log "D" "Backup command: cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${db} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/${db}.sql && cd - >/dev/null 2>&1"
                        startTime=`get_nanosecond`
                        if cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${db} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/${db}.sql && cd - >/dev/null 2>&1; then
                            endTime=`get_nanosecond`
                            outcome="succeeded"
                        else
                            endTime=`get_nanosecond`
                            outcome="failed"

                        fi
                        
                        cost=`time_cost_ms ${startTime} ${endTime}`

                        add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"
                    done
                
                # 1.2. backup databases all at once
                else
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is not set to 1, will backup databases all at once"
                    add_log "I" "Begin to back up databases in list: ${backup_db_list}"
                    add_log "D" "Backup command: cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/mo.sql && cd - >/dev/null 2>&1"
                
                    startTime=`get_nanosecond`
                    if cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/mo.sql && cd - >/dev/null 2>&1; then
                        endTime=`get_nanosecond`
                        outcome="succeeded"
                    else
                        endTime=`get_nanosecond`
                        outcome="failed"

                    fi
                    cost=`time_cost_ms ${startTime} ${endTime}`

                    add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"

                fi

            # 2. in case we have only one database
            else
                add_log "D" "backup_db_list=${backup_db_list} seems to be one exact database, thus will take conf BACKUP_LOGICAL_TBL_LIST=${BACKUP_LOGICAL_TBL_LIST} into consideration"
                
                if [[ "${BACKUP_LOGICAL_ONEBYONE}" == "1" ]]; then
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is set to 1, will backup tables one by one"

                    for tbl in $(echo "${BACKUP_LOGICAL_TBL_LIST}" | sed "s/,/ /g"); do
                        add_log "I" "Begin to back up table: ${tbl}"

                        add_log "D" "Backup command: cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} -tbl ${tbl} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/${db}_${tbl}.sql && cd - >/dev/null 2>&1"
                        startTime=`get_nanosecond`
                        if cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} -tbl ${tbl} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/${db}_${tbl}.sql && cd - >/dev/null 2>&1; then
                            endTime=`get_nanosecond`
                            outcome="succeeded"
                        else
                            endTime=`get_nanosecond`
                            outcome="failed"

                        fi
                        cost=`time_cost_ms ${startTime} ${endTime}`

                        add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"
                    done


                # backup tables all at once
                else
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is not set to 1, will backup tables all at once"
                    add_log "I" "Begin to back up tables in list: ${BACKUP_LOGICAL_TBL_LIST} in database ${backup_db_list}"
                    add_log "D" "Backup command: cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} -tbl ${BACKUP_LOGICAL_TBL_LIST} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/${backup_db_list}.sql && cd - >/dev/null 2>&1"
                
                    startTime=`get_nanosecond`
                    if cd ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} -tbl ${BACKUP_LOGICAL_TBL_LIST} ${csv_option} ${no_data_option} > ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/${backup_db_list}.sql && cd - >/dev/null 2>&1; then
                        endTime=`get_nanosecond`
                        outcome="succeeded"
                    else
                        endTime=`get_nanosecond`
                        outcome="failed"

                    fi
                    cost=`time_cost_ms ${startTime} ${endTime}`

                    add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"

                fi


            fi

            
            ;;

        # 2) physical backups : mo_br
        "physical")
            #backup_db_list="all"
            backup_conf_db_list="all"
            logical_data_type="n.a."

            ! backup_precheck "mobr" && return 1

            BACKUP_MOBR_DIRNAME=`dirname "${BACKUP_MOBR_PATH}"`
            case "${BACKUP_PHYSICAL_TYPE}" in
                "filesystem")
                    add_log "D" "Backup command: cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup --host \"${MO_HOST}\" --port \"${MO_PORT}\" --user \"${MO_USER}\" --password \"${MO_PW}\" --backup_dir \"filesystem\" --path \"${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/\""
                    
                    startTime=`get_nanosecond`
                    if cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup --host "${MO_HOST}" --port "${MO_PORT}" --user "${MO_USER}" --password "${MO_PW}" --backup_dir "filesystem" --path "${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/" ; then
                        outcome="succeeded"
                    else
                        outcome="failed"
                    fi
                    ;;
                "s3")
                    minio_option=""
                    if [[ "${BACKUP_S3_IS_MINIO}" != "no" ]]; then
                        minio_option="--is_minio"
                    fi

                    role_arn_option=""
                    if [[ "${BACKUP_S3_ROLE_ARN}" != "" ]]; then
                        role_arn_option="--role_arn ${BACKUP_S3_ROLE_ARN}"
                    fi
                    
                    add_log "D" "Backup command: cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup --host \"${MO_HOST}\" --port \"${MO_PORT}\" --user \"${MO_USER}\" --password \"${MO_PW}\" --backup_dir \"s3\" --endpoint \"${BACKUP_S3_ENDPOINT}\" --access_key_id \"${BACKUP_S3_ID}\" --secret_access_key \"${BACKUP_S3_KEY}\" --bucket \"${BACKUP_S3_BUCKET}\" --filepath \"${BACKUP_DATA_PATH}\" --region \"${BACKUP_S3_REGION}\" --compression \"${BACKUP_S3_COMPRESSION}\" \"${role_arn_option}\" \"${minio_option}\""

                    startTime=`get_nanosecond`
                    if cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup --host "${MO_HOST}" --port "${MO_PORT}" --user "${MO_USER}" --password "${MO_PW}" --backup_dir "s3" --endpoint "${BACKUP_S3_ENDPOINT}" --access_key_id "${BACKUP_S3_ID}" --secret_access_key "${BACKUP_S3_KEY}" --bucket "${BACKUP_S3_BUCKET}" --filepath "${BACKUP_DATA_PATH}" --region "${BACKUP_S3_REGION}" --compression "${BACKUP_S3_COMPRESSION}" "${role_arn_option}" "${minio_option}"; then
                        outcome="succeeded"
                    else
                        outcome="failed"
                    fi
                    ;;


                 *)
                    add_log "E" "Invalid BACKUP_PHYSICAL_TYPE ${BACKUP_PHYSICAL_TYPE}, valid range: filesystem (default) | s3"
                    return 1
                    ;;
            esac

            endTime=`get_nanosecond`
            cost=`time_cost_ms ${startTime} ${endTime}`
            add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"

    esac

    # output report record
    echo "${backup_timestamp} | ${backup_conf_db_list} | ${BACKUP_TYPE} | ${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}/ | ${logical_data_type} | ${cost} | ${outcome}" >> "${BACKUP_REPORT}"

    add_log "I" "Backup ends"

}



function clean_backup()
{
    add_log "I" "Cleaning backups before ${BACKUP_CLEAN_DAYS_BEFORE} days"
    clean_date=`date -d "${BACKUP_CLEAN_DAYS_BEFORE} day ago" +%Y%m%d`
    add_log "I" "Clean date: ${clean_date}"

    for month in `ls ${BACKUP_DATA_PATH}`; do
        for backup_dir in `ls ${BACKUP_DATA_PATH}/${month}`; do
            backup_date=`echo "${backup_dir}" | awk -F"_" '{print $1}'`
            backup_date_int=`date -d "${backup_date}" +%s`
            clean_date_int=`date -d "${clean_date}" +%s`
            if [[ ${backup_date_int} -le ${clean_date_int} ]]; then
                add_log "I" "Backup directory : ${BACKUP_DATA_PATH}/${month}/${backup_dir}, action: delete"
                if cd ${BACKUP_DATA_PATH}/${month} && rm -rf ./${backup_dir}; then
                    add_log "I" "Succeeded"
                else
                    add_log "E" "Failed"
                fi
            else
                add_log "I" "Backup directory : ${BACKUP_DATA_PATH}/${month}/${backup_dir}/${backup_dir}, action: skip"
            fi
        done
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
        
        add_log "D" "Creating log folder: mkdir -p ${TOOL_LOG_PATH}/${ab_name}/ ${TOOL_LOG_PATH}/${cb_name}/"
        mkdir -p ${TOOL_LOG_PATH}/${ab_name}/ ${TOOL_LOG_PATH}/${cb_name}/

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
    option_1="$1"
    option_2="$2"
    OS=`what_os`
    BACKUP_CRON_USER=`whoami`

    # backup cron file and its content 
    date_expr="\$(date '+\\%Y\\%m\\%d_\\%H\\%M\\%S')"
    BACKUP_CRON_CONTENT="${BACKUP_CRON_SCHEDULE} ${BACKUP_CRON_USER} ${BACKUP_CRON_SCRIPT} > ${TOOL_LOG_PATH}/${ab_name}/log.${date_expr}.log 2>&1"

    # clean up for old backups cron file and its content     
    CLEAN_BK_CRON_CONTENT="${BACKUP_CLEAN_CRON_SCHEDULE} ${BACKUP_CRON_USER} ${CLEAN_BK_CRON_SCRIPT} > ${TOOL_LOG_PATH}/${cb_name}/log.${date_expr} 2>&1"


    case "${option_1}" in
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
            add_log "E" "Invalid option_1 for ${ab_name}: ${option_1}"
            help_auto_backup
            return 1
            ;;
    esac

}
