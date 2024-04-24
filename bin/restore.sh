#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# restore

ab_name="restore"
OS=""


function restore_precheck()
{

    option=$1
    expected_status=$2

    case "${option}" in
        "mo")
            if status; then
                if [[ "${expected_status}" == "down" ]]; then
                    add_log "E" "MO seems to be running, please make sure mo-service is stopped before performing a restore"
                    return 1
                fi
            else
                if [[ "${expected_status}" == "up" ]]; then
                    add_log "E" "MO seems not to be running, please make sure mo-service is running before performing a restore"
                    return 1
                else
                    if watchdog; then
                        add_log "E" "MO watchdog seems to be enabled, please make sure it is disabled before performing a restore"
                        return 1
                    fi
                fi


            fi
            ;;


        "connection")
            add_log "I" "Check mo connectivity"
            if ! sql "show databases;select version(); select git_version();"; then
                add_log "E" "MO cannot be connected"
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

function restore_physical()
{
    add_log "I" "MO_HOST: ${MO_HOST}"
    if [[ "MO_HOST" != "127.0.0.1" ]]; then
        add_log "E" "Currently mo_ctl only support restoring physical backup data on a local mo server, thus please set MO_HOST to 127.0.0.1 if that's the case."
        return 1
    fi

    ! restore_precheck "mo" "down" && return 1

    ! restore_precheck "mobr" && return 1

    add_log "I" "Restore settings"
    add_log "I" "------------------------------------"
    get_conf | grep RESTORE
    add_log "I" "------------------------------------"

    add_log "I" "Step_1. Restore physical data"

    add_log "I" "Restore begins"

    backup_yearmonth=`date '+%Y%m'`
    backup_timestamp=`date '+%Y%m%d_%H%M%S'`

    BACKUP_MOBR_DIRNAME=`dirname "${BACKUP_MOBR_PATH}"`

    cmd="${BACKUP_MOBR_PATH} restore ${RESTORE_BKID} --restore_dir ${RESTORE_PHYSICAL_TYPE}"
    case "${RESTORE_PHYSICAL_TYPE}" in
        "filesystem")
            cmd="${cmd} --restore_path ${RESTORE_PATH}"
            ;;
        "s3")
            restore_s3_is_minio=""


            role_arn_option=""
            if [[ "${RESTORE_S3_ROLE_ARN}" != "" ]]; then
                role_arn_option="--restore_role_arn ${RESTORE_S3_ROLE_ARN}"
            fi

            compress_option=""
            if [[ "${RESTORE_S3_COMPRESSION}" != "" ]]; then
                compress_option="--restore_compression ${RESTORE_S3_COMPRESSION}"
            fi

            minio_option=""
            if [[ "${BACKUP_S3_IS_MINIO}" != "no" ]]; then
                minio_option="--restore_is_minio"
            fi

            mkdir -p "${RESTORE_PATH}"

            cmd="${cmd} --restore_endpoint \"${RESTORE_S3_ENDPOINT}\" --restore_access_key_id \"${RESTORE_S3_ID}\" --restore_secret_access_key \"${RESTORE_S3_KEY}\" --restore_bucket \"${RESTORE_S3_BUCKET}\" --restore_filepath ${RESTORE_PATH} --restore_region \"${RESTORE_S3_REGION}\" \"${compress_option}\" \"${role_arn_option}\" \"${minio_option}\" "
            ;;
        *)
            add_log "E" "Invalid RESTORE_PHYSICAL_TYPE = ${RESTORE_PHYSICAL_TYPE}, choose from: filesystem | s3"
            ;;
    esac

    add_log "D" "cmd: cd ${BACKUP_MOBR_DIRNAME} && ${cmd}"


    startTime=`get_nanosecond`
    if cd ${BACKUP_MOBR_DIRNAME} && ${cmd}; then
        outcome="succeeded"
    else
        outcome="failed"
        rc=1
    fi
    endTime=`get_nanosecond`
    cost=`time_cost_ms ${startTime} ${endTime}`
    
    add_log "I" "Outcome: ${outcome}, cost: ${cost} ms"

    if [[ ${rc} -ne 0 ]]; then
        add_log "E" "Restore ends with non-zero rc"
    else
        add_log "I" "Restore ends with 0 rc"
    fi
}

function restore_mo_data()
{
    add_log "I" "Step_2. Move mo-data path"

    if [[ "${MO_DEPLOY_MODE}" == "git" ]]; then
        mo_path="${MO_PATH}/matrixone"
    elif [[ "${MO_DEPLOY_MODE}" == "binary" ]]; then
        mo_path="${MO_PATH}/matrixone"
    else
        # todo
        return 1
    fi

    current_time=`date +"%Y%m%d_%H%M%S"`
    if [[ ! -d "${mo_path}/mo-data/" ]]; then
        add_log "W" "${MO_PATH}/mo-data/ does not exist, skip moving it"
        return 0
    fi



    add_log "I" "Moving ${mo_path}/mo-data to ${mo_path}/mo-data-bk-${current_time}"
    add_log "D" "cmd: mv ${mo_path}/mo-data ${mo_path}/mo-data-bk-${current_time}"
    if ! mv ${mo_path}/mo-data ${mo_path}/mo-data-bk-${current_time}; then
        add_log "E" "Failed, exiting"
        return 1
    fi

    add_log "I" "Moving ${RESTORE_PATH}/mo-data to ${mo_path}/mo-data"
    add_log "D" "cmd: mv ${RESTORE_PATH}/mo-data ${mo_path}/mo-data"
    if ! mv ${RESTORE_PATH}/mo-data ${mo_path}/mo-data; then
        add_log "E" "Failed, exiting"
        return 1 
    fi
}

function restore_restart_mo()
{
    add_log "I" "Step_3. Restart mo"
    mo_ctl restart
}

function restore_logical()
{

    ! restore_precheck "connection" && return 1

    #! restore_precheck "modump" && return 1

    add_log "I" "Restore settings"
    add_log "I" "------------------------------------"
    get_conf | grep RESTORE
    add_log "I" "------------------------------------"

    add_log "W" "Please confirm your settings before performing a restore(Yes/No):"
    user_confirm=""
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "E" "User input not confirmed or timed out, exiting"
        return 1
    fi

    add_log "I" "Step_1. Restore logical data"


    dbname_option=""
    if [[ "${RESTORE_LOGICAL_DB}" != "" ]]; then
        add_log "I" "RESTORE_LOGICAL_DB=${RESTORE_LOGICAL_DB} is not empty, will add database name when restoring data"
        dbname_option="${RESTORE_LOGICAL_DB}"   
    fi


    backup_yearmonth=`date '+%Y%m'`
    backup_timestamp=`date '+%Y%m%d_%H%M%S'`

    BACKUP_MODUMP_DIRNAME=`dirname "${BACKUP_MOBR_PATH}"`

    add_log "I" "Restore begins, please wait"
    #todo
    #if MYSQL_PWD="${M_PW}" mysql -h"${MO_HOST}" -P"${MO_PORT}" -u"${MO_USER}" "${dbname_option}" < ${}
    #cmd="mysql -u$}" 
    

    add_log "D" "cmd: cd ${BACKUP_MOBR_DIRNAME} && ${cmd}"


    startTime=`get_nanosecond`
    if cd ${BACKUP_MOBR_DIRNAME} && ${cmd}; then
        outcome="succeeded"
    else
        outcome="failed"
        rc=1
    fi
    endTime=`get_nanosecond`
    cost=`time_cost_ms ${startTime} ${endTime}`
    
    add_log "I" "Outcome: ${outcome}, cost: ${cost} ms"

    if [[ ${rc} -ne 0 ]]; then
        add_log "E" "Restore ends with non-zero rc"
    else
        add_log "I" "Restore ends with 0 rc"
    fi
}

function restore()
{

    case "${RESTORE_TYPE}" in
        "physical")
            ! restore_physical && return 1
            ! restore_mo_data && return 1
            ! restore_restart_mo && return 1
            ;;
        "logical")
            ! restore_logical && return 1
            ;;
        *)
            add_log "E" "Invalid RESTORE_TYPE = ${RESTORE_TYPE}, choose from: physical | logical"
            ;;
    esac
    
  
}

