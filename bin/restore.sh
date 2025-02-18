#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# restore

restore_name="restore"
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
        "deploy_mode")
            if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
                add_log "D" "Currently restoring from a physical backup is only supported when MO_DEPLOY_MODE is set to 'git' or 'binary', current setting is ${MO_DEPLOY_MODE}"
                return 1
            fi
            ;;
        *)
            add_log "E" "Invalid option for backup_precheck: ${option}"
            return 1
            ;;
    esac    

}

function restore_prep_report()
{
    restore_report_path=`dirname "${RESTORE_REPORT}"`
    add_log "D" "Creating restore report direcory: mkdir -p ${restore_report_path}"
    mkdir -p ${restore_report_path}
    if [[ ! -s "${RESTORE_REPORT}" ]]; then
        add_log "D" "Creating restore report file ${RESTORE_REPORT}"
        echo "restore_date|restore_target|restore_type|physical_bk_id|logical_restore_src|logical_type|duration_ms|outcome|bk_size" > "${RESTORE_REPORT}"
    fi
}

function restore_physical()
{
    if [[ "${MO_HOST}" != "127.0.0.1" ]]; then
        add_log "E" "Currently mo_ctl only support restoring physical backup data on a local mo server, thus please set MO_HOST to 127.0.0.1 if that's the case."
        return 1
    fi

    if ! restore_precheck "deploy_mode"; then
        return 1
    fi

    if ! restore_precheck "mo" "down"; then
        return 1
    fi

    if ! restore_precheck "mobr"; then
        return 1
    fi

    add_log "I" "Restore settings"
    add_log "I" "------------------------------------"
    get_conf | grep RESTORE
    add_log "I" "------------------------------------"

    add_log "I" "Step_1. Restore physical data"

    if [[ "${RESTORE_BKID}" == "" ]]; then
        add_log "E" "RESTORE_BKID seems to be empty, please set it first, e.g. mo_ctl set_conf RESTORE_BKID=xxxxxxx , exiting"
        return 1
    fi

    add_log "I" "Restore begins"

    br_meta_option=""
    if [[ "${BACKUP_MOBR_META_PATH}" != "" ]]; then
        br_meta_option="--meta_path ${BACKUP_MOBR_META_PATH}"
        add_log "D" "BACKUP_MOBR_META_PATH is not empty, will add option ${br_meta_option}"
    fi

    BACKUP_MOBR_DIRNAME=`dirname "${BACKUP_MOBR_PATH}"`

    cmd="${BACKUP_MOBR_PATH} restore ${RESTORE_BKID} ${br_meta_option} --restore_dir ${RESTORE_PHYSICAL_TYPE}"
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


    restore_timestamp=`date '+%Y%m%d_%H%M%S'`
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

    bk_size="n.a."
    bk_size_in_bytes="n.a."
    if [[ ${outcome} == "succeeded" ]]; then
        add_log "D" "Get size of backup id ${RESTORE_BKID}"
        bk_size=`cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} list ${br_meta_option} | grep "${RESTORE_BKID}" | awk -F "|" '{print $3}' | sed 's# ##g'`
        add_log "D" "bk_size: ${bk_size}"
        if [[ "1" == "0" ]]; then
            if echo "${bk_size}" | grep "kB" >/dev/null; then
                number=`echo "${bk_size}" | awk -F "kB" '{print $1}'`
                #let bk_size_in_bytes=number*1024
                bk_size_in_bytes=`awk -v n1="$number" 'BEGIN{print n1*1024}'`
            elif echo "${bk_size}" | grep "MB" >/dev/null; then
                number=`echo "${bk_size}" | awk -F "MB" '{print $1}'`
                #let bk_size_in_bytes=number*1024*1024
                bk_size_in_bytes=`awk -v n1="$number" 'BEGIN{print n1*1024*1024}'`

            elif echo "${bk_size}" | grep "GB" >/dev/null; then
                number=`echo "${bk_size}" | awk -F "GB" '{print $1}'`
                #let bk_size_in_bytes=number*1024*1024*1024
                bk_size_in_bytes=`awk -v n1="$number" 'BEGIN{print n1*1024*1024*1024}'`
            else
                bk_size_in_bytes="${bk_size}"
            fi
        fi
        add_log "D" "bk_size: ${bk_size}, bk_size_in_bytes: ${bk_size_in_bytes}"

    fi

    add_log "D" "Writing entry to report ${RESTORE_REPORT}"
    add_log "D" "${restore_timestamp}|${MO_HOST},${MO_PORT},${MO_USER}|physical|${RESTORE_BKID}|||${cost}|${outcome}|${bk_size}"    
    echo "${restore_timestamp}|${MO_HOST},${MO_PORT},${MO_USER}|physical|${RESTORE_BKID}|||${cost}|${outcome}|${bk_size}" >> ${RESTORE_REPORT}


    if [[ ${rc} -ne 0 ]]; then
        add_log "E" "Restore ends with non-zero rc"
    else
        add_log "I" "Restore ends with 0 rc"
    fi

    return ${rc}
}

function restore_mo_data()
{
    add_log "I" "Step_2. Move mo-data path"
    if [[ "${MO_DEPLOY_MODE}" == "git" ]]; then
        mo_path="${MO_PATH}/matrixone"
    elif [[ "${MO_DEPLOY_MODE}" == "binary" ]]; then
        mo_path="${MO_PATH}"
    else
        add_log "D" "Currently restoring from a physical backup is only supported when MO_DEPLOY_MODE is set to 'git' or 'binary', current setting is ${MO_DEPLOY_MODE}"
        return 1
    fi

    add_log "D" "MO_DEPLOY_MODE: ${MO_DEPLOY_MODE}, mo_path: ${mo_path}"
    current_time=`date +"%Y%m%d_%H%M%S"`
    if [[ ! -d "${mo_path}/mo-data/" ]]; then
        add_log "W" "${mo_path}/mo-data/ does not exist, skip renaming it"
    else
        add_log "I" "Renaming ${mo_path}/mo-data to ${mo_path}/mo-data-bk-${current_time}"
        add_log "D" "cmd: mv ${mo_path}/mo-data ${mo_path}/mo-data-bk-${current_time}"
        if ! mv ${mo_path}/mo-data ${mo_path}/mo-data-bk-${current_time}; then
            add_log "E" "Failed, exiting"
            return 1
        fi
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

    if ! restore_precheck "connection"; then
        return 1
    fi

    add_log "I" "Restore settings"
    add_log "I" "------------------------------------"
    get_conf | grep RESTORE
    add_log "I" "------------------------------------"


    add_log "I" "Step_1. Restore logical data"


    dbname_option=""
    if [[ "${RESTORE_LOGICAL_DB}" != "" ]]; then
        add_log "I" "RESTORE_LOGICAL_DB=${RESTORE_LOGICAL_DB} is not empty, will add database name when restoring data"
        dbname_option="${RESTORE_LOGICAL_DB}"   
    fi



    
    if [[ -d "${RESTORE_LOGICAL_SRC}" ]]; then
        isFile="false"
        srcPath="${RESTORE_LOGICAL_SRC}"
        add_log "I" "RESTORE_LOGICAL_SRC=${RESTORE_LOGICAL_SRC} is a path, listing files in it"
        ls -lth "${RESTORE_LOGICAL_SRC}"
    elif [[ -f "${RESTORE_LOGICAL_SRC}" ]]; then
        isFile="true"
        srcPath=`dirname "${RESTORE_LOGICAL_SRC}"`
        add_log "I" "RESTORE_LOGICAL_SRC=${RESTORE_LOGICAL_SRC} is a file"
    else
        add_log "E" "RESTORE_LOGICAL_SRC=${RESTORE_LOGICAL_SRC} is a not a path nor file. Please check again. Exiting"
        return 1
    fi

    

    add_log "I" "Restore begins, please wait"
    i=1
    rc=0
    for fileName in `ls ${srcPath}/ | grep "\.sql"`; do
        if [[ "${isFile}" == "true" ]]; then
            file="${RESTORE_LOGICAL_SRC}"
        else
            file="${srcPath}/${fileName}"
        fi
        add_log "D" "cmd: MYSQL_PWD="${MO_PW}" mysql --local-infile -h${MO_HOST} -P${MO_PORT} -u${MO_USER} ${dbname_option} < ${file}"
        restore_timestamp=`date '+%Y%m%d_%H%M%S'`
        startTime=`get_nanosecond`
        if MYSQL_PWD="${MO_PW}" mysql --local-infile -h${MO_HOST} -P${MO_PORT} -u${MO_USER} ${dbname_option} < ${file}; then
            outcome="succeeded"
        else
            outcome="failed"
            let rc=rc+1
        fi
        endTime=`get_nanosecond`
        cost=`time_cost_ms ${startTime} ${endTime}`
        

        add_log "I" "Number: $i, file: ${file}, outcome: ${outcome}, cost: ${cost} ms"
        
        
        bk_size="n.a."
        if [[ ${outcome} == "succeeded" ]]; then
            add_log "D" "Calculating size of source path ${srcPath}"
            bk_size=`du -s ${srcPath} | awk '{print $1}'`
        fi

        add_log "D" "Writing entry to report"
        restore_prep_report
        echo "${restore_timestamp}|${MO_HOST},${MO_PORT},${MO_USER}|logical||${file}|${RESTORE_LOGICAL_TYPE}|${cost}|${outcome}|${bk_size}" >> ${RESTORE_REPORT}

        if [[ "${isFile}" == "true" ]]; then
            break
        fi
        let i=i+1
        
    done

    let i=i-1

    add_log "I" "-------------------------"
    add_log "I" "         Summary         "
    add_log "I" "Total: ${i}, failed: ${rc}"
    add_log "I" "-------------------------"


    if [[ ${rc} -ne 0 ]]; then
        add_log "E" "Restore ends with non-zeor rc"
    else
        add_log "I" "Restore ends with 0 rc"
    fi
    return ${rc}
}

function restore_list()
{

    option="$1"

    if [[ ! -f ${RESTORE_REPORT} ]]; then
        add_log "E" "RESTORE_REPORT ${RESTORE_REPORT} is not a valid file, exiting"
        return 1 
    fi
    #add_log "I" "Listing restore report (summary) from ${RESTORE_REPORT}"
    #add_log "I" "------------------------------------"
    cat ${RESTORE_REPORT}
}

function restore()
{
    add_log "I" "Current confs:"
    get_conf | grep -E "RESTORE|MO_PATH|MO_DEPLOY_MODE"
    
    add_log "W" "Please make sure if you really want to perform a restore(Yes/No):"
    read_user_confirm

    case "${RESTORE_TYPE}" in
        "physical")
            if ! restore_physical; then
                return 1
            fi
            
            if ! restore_mo_data; then
                return 1
            fi

            if ! restore_restart_mo; then
                return 1
            fi
            ;;
        "logical")
            if ! restore_logical; then
                return 1
            fi
            ;;
        *)
            add_log "E" "Invalid RESTORE_TYPE = ${RESTORE_TYPE}, choose from: physical | logical"
            ;;
    esac
    
  
}


