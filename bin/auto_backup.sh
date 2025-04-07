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
BACKUP_CRON_SCRIPT_FULL="( /usr/local/bin/mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS=yes  && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=full  && /usr/local/bin/mo_ctl backup )"
BACKUP_CRON_SCRIPT_INCREMENTAL="( sleep 2 && /usr/local/bin/mo_ctl set_conf BACKUP_PHYSICAL_METHOD=incremental  && /usr/local/bin/mo_ctl backup )"




BACKUP_CRON_CONTENT_FULL=""
BACKUP_CRON_CONTENT_INCREMENTAL=""
CLEAN_BK_CRON_FILE_NAME="mo_clean_old_backup"
CLEAN_BK_CRON_SCRIPT="/usr/local/bin/mo_ctl clean_backup"
BACKUP_MOBR_DIRNAME=""
# Mac: to do
# BACKUP_CRON_PLIST_NAME="com.matrixorigin.mo.autobacup"
# BACKUP_CRON_PLIST_FILE="${WORK_DIR}/bin/mo_autobacup.plist"
OS=""


function backup_get_last_physical_bkid()
{
    option="$1"
    last_bkid=""
    if [[ "${BACKUP_MOBR_META_PATH}" == "" ]]; then
        BACKUP_MOBR_META_PATH="${BACKUP_MOBR_PATH}/mo_br.meta"
    fi

    last_bkid=`grep "${option}" ${BACKUP_MOBR_META_PATH} | tail -n 1 | awk -F "," '{print $1}' |  sed "s/[[:space:]][[:space:]]*//g"`
    echo "${last_bkid}"
}

function backup_precheck()
{

    option=$1
    add_log "I" "MO_HOST: ${MO_HOST}"
    case "${option}" in
        "mo")
            if [[ "${MO_HOST}" == "127.0.0.1" ]]; then
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

            mo_br_ps_info=`ps -ef |grep "mo_br backup" |grep -v grep`
            if [[ "${mo_br_ps_info}" != "" ]] ; then
                add_log "D" "mo_br_ps_info"
                add_log "D" "${mo_br_ps_info}" "l"
                add_log "E" "At least one mo_br process is running, will not perform physical backup until it's done, exiting"
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


        br_meta_option=""
        if [[ "${BACKUP_MOBR_META_PATH}" != "" ]]; then
            br_meta_option="--meta_path ${BACKUP_MOBR_META_PATH}"
            #add_log "D" "BACKUP_MOBR_META_PATH is not empty, will add option ${br_meta_option}"
        fi

        #add_log "I" "Listing backup report (detail, physical only)"
        #add_log "I" "------------------------------------"
        #add_log "D" "cmd: cd ${BACKUP_MOBR_DIRNAME} && ./mo_br ${br_meta_option} list"
        cd ${BACKUP_MOBR_DIRNAME} && ./mo_br ${br_meta_option} list
    else
        if [[ ! -f ${BACKUP_REPORT} ]]; then
            add_log "E" "BACKUP_REPORT ${BACKUP_REPORT} is not a valid file, exiting"
            return 1 
        fi
        #add_log "I" "Listing backup report (summary) from ${BACKUP_REPORT}"
        #add_log "I" "------------------------------------"
        cat ${BACKUP_REPORT}
    fi
}

function backup()
{

    if ! backup_precheck "mo"; then
        return 1
    fi

    add_log "I" "Backup settings"
    add_log "I" "------------------------------------"
    get_conf | grep BACKUP
    add_log "I" "------------------------------------"


    add_log "I" "Backup begins"

    backup_yearmonth=`date '+%Y%m'`
    backup_timestamp=`date '+%Y%m%d_%H%M%S'`
    if [[ "${BACKUP_DATA_PATH_AUTO_TS}" == "no" ]]; then
        backup_outpath="${BACKUP_DATA_PATH}"
    else
        backup_outpath="${BACKUP_DATA_PATH}/${backup_yearmonth}/${backup_timestamp}"
    fi

    add_log "D" "backup_outpath: ${backup_outpath}"

    #if [[ "${BACKUP_TYPE}" == "logical" ]] && [[ "${BACKUP_LOGICAL_DS}" != "" ]] ; then
    #    backup_outpath="${backup_outpath}_${BACKUP_LOGICAL_DS}"
    #fi

    add_log "D" "BACKUP_TYPE: ${BACKUP_TYPE}, BACKUP_PHYSICAL_METHOD: ${BACKUP_PHYSICAL_METHOD}"
    if [[ "${BACKUP_TYPE}" != "physical" ]] || [[ "${BACKUP_PHYSICAL_METHOD}" != "incremental" ]] ; then 
        add_log "D" "Creating backup data direcory: mkdir -p ${backup_outpath}"
        mkdir -p ${backup_outpath}
    fi

    backup_report_path=`dirname "${BACKUP_REPORT}"`
    add_log "D" "Creating backup report direcory: mkdir -p ${backup_report_path}"
    mkdir -p ${backup_report_path}
    if [[ ! -f ${BACKUP_REPORT} ]]; then
        add_log "D" "Creating backup report file ${BACKUP_REPORT}"
        echo "backup_date|backup_target|ds_name|db_list|backup_type|backup_path|logical_data_type|duration_ms|outcome|bk_size_in_bytes|logical_net_buffer_length" > "${BACKUP_REPORT}"
    fi
 
    backup_db_list=""
    backup_conf_db_list="${BACKUP_LOGICAL_DB_LIST}"
    logical_data_type=""

    rc=0
    case "${BACKUP_TYPE}" in
        # 1) logical backups : mo_dump
        "logical")
            logical_data_type=${BACKUP_LOGICAL_DATA_TYPE}
            net_buffer_length="${BACKUP_LOGICAL_NETBUFLEN}"

            if ! backup_precheck "modump";then
                return 1
            fi

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

                        add_log "D" "Backup command: cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${db} ${csv_option} ${no_data_option} > ${backup_outpath}/${db}.sql && cd - >/dev/null 2>&1"
                        startTime=`get_nanosecond`
                        if cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${db} ${csv_option} ${no_data_option} > ${backup_outpath}/${db}.sql && cd - >/dev/null 2>&1; then
                            endTime=`get_nanosecond`
                            outcome="succeeded"
                        else
                            endTime=`get_nanosecond`
                            outcome="failed"
                            rc=1

                        fi
                        
                        cost=`time_cost_ms ${startTime} ${endTime}`

                        add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"
                    done
                
                # 1.2. backup databases all at once
                else
                    outfile_name="mo.sql"
                    if [[ "${BACKUP_LOGICAL_DS}" != "" ]]; then
                        outfile_name="${BACKUP_LOGICAL_DS}.sql"
                    fi
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is not set to 1, will backup databases all at once"
                    add_log "I" "Begin to back up databases in list: ${backup_db_list}"
                    add_log "D" "Backup command: cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} ${csv_option} ${no_data_option} > ${backup_outpath}/${outfile_name} && cd - >/dev/null 2>&1"
                
                    startTime=`get_nanosecond`
                    if cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} ${csv_option} ${no_data_option} > ${backup_outpath}/${outfile_name} && cd - >/dev/null 2>&1; then
                        endTime=`get_nanosecond`
                        outcome="succeeded"
                    else
                        endTime=`get_nanosecond`
                        outcome="failed"
                        rc=1
                    fi
                    cost=`time_cost_ms ${startTime} ${endTime}`

                    add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"

                fi

            # 2. in case we have only one database
            else
                add_log "D" "backup_db_list=${backup_db_list} seems to be one exact database, thus will take conf BACKUP_LOGICAL_TBL_LIST=${BACKUP_LOGICAL_TBL_LIST} into consideration"
                

                # backup tables all at once
                if [[ "${BACKUP_LOGICAL_ONEBYONE}" == "0" ]]; then
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is not set to 1, will backup tables all at once"
                    if [[ "${BACKUP_LOGICAL_TBL_LIST}" == "" ]]; then
                        add_log "I" "BACKUP_LOGICAL_TBL_LIST is empty, will not add -tbl option"
                        tbl_option=""
                    else
                        add_log "I" "Begin to back up tables in list: ${BACKUP_LOGICAL_TBL_LIST} in database ${backup_db_list}"
                        tbl_option="-tbl ${BACKUP_LOGICAL_TBL_LIST}"
                    fi
                    
                    add_log "D" "Backup command: cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} ${tbl_option} ${csv_option} ${no_data_option} > ${backup_outpath}/${backup_db_list}.sql && cd - >/dev/null 2>&1"
                
                    startTime=`get_nanosecond`
                    if cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} ${tbl_option} ${csv_option} ${no_data_option} > ${backup_outpath}/${backup_db_list}.sql && cd - >/dev/null 2>&1; then
                        endTime=`get_nanosecond`
                        outcome="succeeded"
                    else
                        endTime=`get_nanosecond`
                        outcome="failed"
                        rc=1

                    fi
                    cost=`time_cost_ms ${startTime} ${endTime}`

                    add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"                 

                else
                    add_log "D" "BACKUP_LOGICAL_ONEBYONE is set to 1, will backup tables one by one"

                    for tbl in $(echo "${BACKUP_LOGICAL_TBL_LIST}" | sed "s/,/ /g"); do
                        add_log "I" "Begin to back up table: ${tbl}"

                        add_log "D" "Backup command: cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} -tbl ${tbl} ${csv_option} ${no_data_option} > ${backup_outpath}/${db}_${tbl}.sql && cd - >/dev/null 2>&1"
                        startTime=`get_nanosecond`
                        if cd ${backup_outpath} && ${BACKUP_MODUMP_PATH} -net-buffer-length ${BACKUP_LOGICAL_NETBUFLEN} -u ${MO_USER} -P ${MO_PORT} -h ${MO_HOST} -p ${MO_PW} -db ${backup_db_list} -tbl ${tbl} ${csv_option} ${no_data_option} > ${backup_outpath}/${db}_${tbl}.sql && cd - >/dev/null 2>&1; then
                            endTime=`get_nanosecond`
                            outcome="succeeded"
                        else
                            endTime=`get_nanosecond`
                            outcome="failed"
                            rc=1
                        fi
                        cost=`time_cost_ms ${startTime} ${endTime}`

                        add_log "I" "End with outcome: ${outcome}, cost: ${cost} ms"
                    done
                fi



            fi
            
            
            
            ;;

        # 2) physical backups : mo_br
        "physical")
            #backup_db_list="all"
            backup_conf_db_list="all"
            logical_data_type="n.a."
            net_buffer_length="n.a."

            if ! backup_precheck "mobr"; then
                return 1
            fi

            br_meta_option=""
            if [[ "${BACKUP_MOBR_META_PATH}" != "" ]]; then
                br_meta_option="--meta_path ${BACKUP_MOBR_META_PATH}"
                add_log "D" "BACKUP_MOBR_META_PATH is not empty, will add option ${br_meta_option}"
            fi

            if [[ "${BACKUP_PHYSICAL_PARALLEL_NUM}" == "" ]]; then
                BACKUP_PHYSICAL_PARALLEL_NUM="1"
                add_log "D" "BACKUP_PHYSICAL_PARALLEL_NUM is empty, will use default value 1"
            fi


            BACKUP_MOBR_DIRNAME=`dirname "${BACKUP_MOBR_PATH}"`

            # 1. incremental
            add_log "D" "Judging physical backup method(full or incremental): BACKUP_PHYSICAL_METHOD=${BACKUP_PHYSICAL_METHOD}"
            if [[ "${BACKUP_PHYSICAL_METHOD}" == "incremental" ]]; then
                add_log "I" "Physical backup method: incremental"
                add_log "D" "BACKUP_PHYSICAL_BASE_BKID: ${BACKUP_PHYSICAL_BASE_BKID}"
                
                if [[ "${BACKUP_PHYSICAL_BASE_BKID}" == "" ]]; then
                    add_log "I" "Base backup id is empty, try to get it"
                    bkid=`backup_get_last_physical_bkid`
                    add_log "I" "Got base backup id: $bkid"
                    if [[ "$bkid" == "" ]]; then
                        add_log "E" "Cannot get base backup id, it is still empty."
                        add_log "I" "Hints: use 'mo_ctl backup list detail' to show previous backup ids"
                        return 1
                    fi
                    BACKUP_PHYSICAL_BASE_BKID="${bkid}"
                fi
                # get backup path of bkid
                add_log "D" "BACKUP_MOBR_PATH: ${BACKUP_MOBR_PATH}"
                if [[ "${BACKUP_MOBR_PATH}" != "" ]]; then
                    add_log "D" "Try to get backup path of backup id ${BACKUP_PHYSICAL_BASE_BKID} from ${BACKUP_MOBR_PATH}"
                    add_log "D" "cmd: ${BACKUP_MOBR_PATH} list ${br_meta_option} | grep -A 4 ${BACKUP_PHYSICAL_BASE_BKID} | tail -n 1 | awk -F  \"|\" '{print \$4}' | awk '{print $1}' | sed 's/ //g'"
                    real_bk_path=`${BACKUP_MOBR_PATH} list ${br_meta_option} | grep -A 4 ${BACKUP_PHYSICAL_BASE_BKID} | tail -n 1 | awk -F  "|" '{print $4}' | awk '{print $1}' | sed 's/ //g'`
                else
                    add_log "D" "Try to get backup path of backup id ${BACKUP_PHYSICAL_BASE_BKID} from 'mo_ctl backup list detail'"
                    add_log "D" "cmd: mo_ctl backup list detail  | grep -A 4 ${BACKUP_PHYSICAL_BASE_BKID}  | tail -n 1 | awk -F \"|\" '{print \$4}' | sed \"s/[[:space:]][[:space:]]*//g\""
                    real_bk_path=`mo_ctl backup list detail  | grep -A 4 ${BACKUP_PHYSICAL_BASE_BKID}  | tail -n 1 | awk -F "|" '{print $4}' | sed "s/[[:space:]][[:space:]]*//g"`
                fi
                add_log "D" "real_bk_path: ${real_bk_path}"

                if [[ "${real_bk_path}" == "" ]]; then
                    add_log "E" "Failed to backup path of backup id ${BACKUP_PHYSICAL_BASE_BKID}"
                    return 1
                else
                    backup_outpath="${real_bk_path}"
                    add_log "D" "backup_outpath: ${backup_outpath}"
                fi

                delta_option="--backup_type incremental --base_id ${BACKUP_PHYSICAL_BASE_BKID}"
            # 2. full
            else
                add_log "I" "Physical backup method: full"
                delta_option=""
            fi

            case "${BACKUP_PHYSICAL_TYPE}" in
                "filesystem")
                    add_log "D" "Backup command: cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup ${br_meta_option} --parallelism ${BACKUP_PHYSICAL_PARALLEL_NUM} --host ${MO_HOST} --port ${MO_PORT} --user ${MO_USER} --password ${MO_PW} --backup_dir filesystem --path ${backup_outpath} ${delta_option}"
                    startTime=`get_nanosecond`
                    if cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup ${br_meta_option} --parallelism ${BACKUP_PHYSICAL_PARALLEL_NUM} --host ${MO_HOST} --port ${MO_PORT} --user ${MO_USER} --password ${MO_PW} --backup_dir filesystem --path ${backup_outpath} ${delta_option}; then
                        outcome="succeeded"
                    else
                        outcome="failed"
                        rc=1
                    fi
                    ;;
                "s3")
                    minio_option=""
                    if [[ "${BACKUP_S3_IS_MINIO}" == "yes" ]]; then
                        minio_option="--is_minio"
                    fi

                    role_arn_option=""
                    if [[ "${BACKUP_S3_ROLE_ARN}" != "" ]]; then
                        role_arn_option="--role_arn ${BACKUP_S3_ROLE_ARN}"
                    fi
                    
                    add_log "D" "Backup command: cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup ${br_meta_option} --parallelism \"${BACKUP_PHYSICAL_PARALLEL_NUM}\" --host \"${MO_HOST}\" --port \"${MO_PORT}\" --user \"${MO_USER}\" --password \"${MO_PW}\" --backup_dir \"s3\" --endpoint \"${BACKUP_S3_ENDPOINT}\" --access_key_id \"${BACKUP_S3_ID}\" --secret_access_key \"${BACKUP_S3_KEY}\" --bucket \"${BACKUP_S3_BUCKET}\" --filepath \"${backup_outpath}\" --region \"${BACKUP_S3_REGION}\" --compression \"${BACKUP_S3_COMPRESSION}\" \"${role_arn_option}\" \"${minio_option}\" ${delta_option}"

                    startTime=`get_nanosecond`
                    if cd ${BACKUP_MOBR_DIRNAME} && ${BACKUP_MOBR_PATH} backup ${br_meta_option} --parallelism "${BACKUP_PHYSICAL_PARALLEL_NUM}" --host "${MO_HOST}" --port "${MO_PORT}" --user "${MO_USER}" --password "${MO_PW}" --backup_dir "s3" --endpoint "${BACKUP_S3_ENDPOINT}" --access_key_id "${BACKUP_S3_ID}" --secret_access_key "${BACKUP_S3_KEY}" --bucket "${BACKUP_S3_BUCKET}" --filepath "${backup_outpath}" --region "${BACKUP_S3_REGION}" --compression "${BACKUP_S3_COMPRESSION}" "${role_arn_option}" "${minio_option}" ${delta_option}; then
                        outcome="succeeded"
                    else
                        outcome="failed"
                        rc=1
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

    
    bk_size="n.a."
    if [ ${outcome} = "succeeded" -a ${BACKUP_PHYSICAL_TYPE} = "filesystem" ]; then
        add_log "D" "Calculating size of backup path ${backup_outpath}"
        bk_size=`du -s ${backup_outpath} | awk '{print $1}'`
    fi

    # output report record
    add_log "D" "Writing entry to report ${BACKUP_REPORT}"
    add_log "D" "${backup_timestamp}|${bakcup_target}|${BACKUP_LOGICAL_DS}|${backup_conf_db_list}|${BACKUP_TYPE}|${backup_outpath}|${logical_data_type}|${cost}|${outcome}|${bk_size}|${net_buffer_length}"
    bakcup_target="${MO_HOST},${MO_PORT},${MO_USER}"
    echo "${backup_timestamp}|${bakcup_target}|${BACKUP_LOGICAL_DS}|${backup_conf_db_list}|${BACKUP_TYPE}|${backup_outpath}|${logical_data_type}|${cost}|${outcome}|${bk_size}|${net_buffer_length}" >> "${BACKUP_REPORT}"

    if [[ ${rc} -ne 0 ]]; then
        add_log "E" "Backup ends with non-zero rc"
    else
        add_log "I" "Backup ends with 0 rc"
        if [[ "${BACKUP_AUTO_SET_LAST_BKID}" == "yes" ]]; then
            add_log "D" "BACKUP_AUTO_SET_LAST_BKID is set to 'yes', try to get last success backup id"
            bkid=`backup_get_last_physical_bkid`
            set_conf BACKUP_PHYSICAL_BASE_BKID="${bkid}"
        fi
    fi

    return ${rc}

}

function get_sub_path()
{
    base_path=$1
    if [[ ${BACKUP_PHYSICAL_TYPE} == "s3" ]]; then
        base_path="${base_path#/}"
        ${S3_CLIENT} ${extra_args} ls ${alias_name}/${BACKUP_S3_BUCKET}/${base_path} | awk '{print $NF}'
    else
        ls ${base_path}
    fi
}

function delete_dir()
{
    dir_to_delete=$1

    if [[ ${dir_to_delete} == "" || ${dir_to_delete} == "/" ]]; then
        add_log "E" "invalid dir to delete: ${dir_to_delete}"
        return 1
    fi

    if [[ ${BACKUP_PHYSICAL_TYPE} == "s3" ]]; then
        dir_to_delete=`echo ${dir_to_delete} | sed -E 's#//*#/#g; s#^/##'`
        ${S3_CLIENT} ${extra_args} rm --recursive --force ${alias_name}/${BACKUP_S3_BUCKET}/${dir_to_delete}
        return $?
    else
        rm -rf ${dir_to_delete}
        return 0
    fi
}

function clean_backup()
{
    if [[ ${BACKUP_PHYSICAL_TYPE} == "s3" ]]; then
        if [[ ${S3_CLIENT} == "" ]]; then
            add_log "E" "Clean backup cannot be done as S3_CLIENT is not set"
            return 1
        fi
        if [[ ! -f ${S3_CLIENT} ]]; then
            add_log "E" "Clean backup cannot be done as S3_CLIENT could not be found"
            return 1
        fi

        # set some variables
        alias_name="backup"
        extra_args=""
        if [[ ! ${S3_CONFIG_DIR} == "" ]]; then
            extra_args="--config-dir ${S3_CONFIG_DIR}"
        fi
        api_args=""
        if [[ ! ${S3_API_VERSION} == "" ]]; then
            api_args="--api ${S3_API_VERSION}"
        fi
        ${S3_CLIENT} ${extra_args} alias set ${alias_name} ${BACKUP_S3_ENDPOINT} ${BACKUP_S3_ID} ${BACKUP_S3_KEY} ${api_args}
    fi

    if [[ "${BACKUP_DATA_PATH_AUTO_TS}" == "no" ]]; then
        add_log "E" "Clean backup is only supported when BACKUP_DATA_PATH_AUTO_TS is set to 'yes', please set it first: mo_ctl set_conf BACKUP_DATA_PATH_AUTO_TS='yes'"
        return 1
    else
        clean_path="${BACKUP_DATA_PATH}"
    fi

    add_log "I" "Cleaning backups before ${BACKUP_CLEAN_DAYS_BEFORE} days"
    clean_date=`date -d "@$(($(date +%s) - BACKUP_CLEAN_DAYS_BEFORE * 86400))" +%Y-%m-%d`
    add_log "I" "Clean date: ${clean_date}"

    for month in `get_sub_path ${clean_path}`; do
        for backup_dir in `get_sub_path ${clean_path}/${month}`; do
            backup_date_tmp=`echo "${backup_dir}" | awk -F"_" '{print $1}'`
            backup_date="${backup_date_tmp:0:4}-${backup_date_tmp:4:2}-${backup_date_tmp:6:2}"
            backup_date_int=`date -d "${backup_date}" +%s`
            clean_date_int=`date -d "${clean_date}" +%s`
            if [[ ${backup_date_int} -le ${clean_date_int} ]]; then
                add_log "I" "Backup directory : ${clean_path}/${month}/${backup_dir}, action: delete"
                delete_dir ${clean_path}/${month}/${backup_dir}
                if [[ $? -eq 0 ]]; then
                    add_log "I" "Succeeded"
                else
                    add_log "E" "Failed"
                fi
            else
                add_log "I" "Backup directory : ${clean_path}/${month}/${backup_dir}/${backup_dir}, action: skip"
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
        if [[ -s ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} ]]; then
            add_log "D" "Cron file ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} for ${ab_name} already exists, trying to get content: "
            bk_content=`cat ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME}`
            add_log "D" "${bk_content}"
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
            add_log "D" "Content: ${BACKUP_CRON_CONTENT_FULL}"

            if sudo touch ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} && sudo chown ${BACKUP_CRON_USER} ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} && sudo echo "${BACKUP_CRON_CONTENT_FULL}" > ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} && sudo echo "${BACKUP_CRON_CONTENT_INCREMENTAL}" >> ${BACKUP_CRON_PATH}/${BACKUP_CRON_FILE_NAME} ; then
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
    BACKUP_CRON_CONTENT_FULL="${BACKUP_CRON_SCHEDULE_FULL} ${BACKUP_CRON_USER} ${BACKUP_CRON_SCRIPT_FULL} >> ${TOOL_LOG_PATH}/${ab_name}/log.${date_expr}.log 2>&1"
    BACKUP_CRON_CONTENT_INCREMENTAL="${BACKUP_CRON_SCHEDULE_INCREMENTAL} ${BACKUP_CRON_USER} ${BACKUP_CRON_SCRIPT_INCREMENTAL} >> ${TOOL_LOG_PATH}/${ab_name}/log.${date_expr}.log 2>&1"

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
