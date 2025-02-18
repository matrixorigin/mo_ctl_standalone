#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# datax

datax_name="datax"
datax_db_name=""
datax_table_name=""

function datax_precheck()
{

    cmd_list=("python3" "java")
    conf_item_list=("DATAX_TOOL_PATH" "DATAX_CONF_PATH" "DATAX_REPORT_FILE")

    # 1. check command exists
    flag=0
    for cmd in ${cmd_list[@]}; do
        if ! check_cmd "${cmd}"; then
            flag=1
        fi
    done 

    if [[ "${flag}" == "1" ]]; then
        return 1
    fi

    # 2. check conf not empty
    flag=0
    for conf_item in ${conf_item_list[@]}; do
        if ! check_conf_item_not_empty "${conf_item}"; then
            flag=1
        fi
    done 
    if [[ "${flag}" == "1" ]]; then
        return 1
    fi

}

function datax_get_db_and_table()
{
    datax_db_name=`grep "jdbc:" "${DATAX_CONF_PATH}" | awk -F "/" '{print $4}' | awk -F "?" '{print $1}'  | sort  | uniq | head -n 1`
    if echo "${datax_db_name}" | grep "$" >/dev/null 2>&1 ; then
        datax_db_name=`eval echo ${datax_db_name}`
    fi
    datax_table_name=`grep '"table":' "${DATAX_CONF_PATH}"  | awk -F ":" '{print $2}' | sed "s#\[##g" | sed "s#\]##g" | sed "s#\"##g" | sed "s# ##g" | sort | uniq | head -n 1`
    if echo "${datax_table_name}" | grep "$" >/dev/null 2>&1 ; then
        datax_table_name=`eval echo ${datax_table_name}`
    fi

    add_log "D" "datax_db_name: ${datax_db_name}, datax_table_name: ${datax_table_name}"
}

function datax_report_write()
{
    this_date=`date '+%Y-%m-%d'`
    log_path="${DATAX_TOOL_PATH}/log/${this_date}"
    log_file_name=`ls -tr ${log_path}| tail -n 1`
    log_file="${log_path}/${log_file_name}"
    add_log "D" "log_file: ${log_file}"
    if [ ! -s ${DATAX_REPORT_FILE} ]; then
        touch "${DATAX_REPORT_FILE}"
        echo "start_time,end_time,duration,avg_data_size,avg_data_rows,rows_total,rows_failed,db_name,table_name" >> "${DATAX_REPORT_FILE}"
    fi

    key_list=("任务启动时刻" "任务结束时刻" "任务总计耗时" "任务平均流量" "记录写入速度" "读出记录总数" "读写失败总数")
    key_length="${#key_list[*]}"

    k_count=1
    for key in ${key_list[@]}; do
        value=`grep "${key}" "${log_file}" | awk -F ": " '{print $2}' | sed "s/^ *//g"`
        add_log "D" "k_count: ${k_count}, key: ${key}, value: ${value}"
        let k_count=k_count+1

        echo -n "${value}," >> "${DATAX_REPORT_FILE}"
        #if [[ ${k_count} -le ${key_length} ]]; then
        #    echo -n "${value}," >> "${DATAX_REPORT_FILE}"
        #else
        #    echo "${value}" >> "${DATAX_REPORT_FILE}"
        #fi
    done

    echo "${datax_db_name},${datax_table_name}" >> "${DATAX_REPORT_FILE}"

}

function datax_get_conf()
{
    add_log "I" "Get datax related confs"
    get_conf | grep DATAX
}

function datax_run()
{

    add_log "D" "DATAX_PARA_NAME_LIST: ${DATAX_PARA_NAME_LIST}"
    if [[ "${DATAX_PARA_NAME_LIST}" != "" ]]; then
        add_log "D" "DATAX_PARA_NAME_LIST: ${DATAX_PARA_NAME_LIST} is set, will add -p option when calling datax jobs"
        para_count=1
        p_option=""
        for para_name in $(echo "${DATAX_PARA_NAME_LIST}" | sed "s/,/ /g"); do
            para_value=`eval echo '$'${para_name}`
            add_log "D" "para_count: ${para_count}, para_name: ${para_name}, para_value: ${para_value}"
            if [[ "${p_option}" == "" ]]; then
                p_option="-D${para_name}=${para_value}"
            else
                p_option="${p_option} -D${para_name}=${para_value}"
            fi
            let para_count=para_count+1
        done
        add_log "D" "p_option: ${p_option}"
    fi

    if [[ -d ${DATAX_CONF_PATH} ]] || [[ -s ${DATAX_CONF_PATH} ]]; then
        add_log "I" "DATAX_CONF_PATH ${DATAX_CONF_PATH} is a directory or a file, listing files in it"
        add_log "I" "---------------------------------"
        ls -lth ${DATAX_CONF_PATH}
        add_log "I" "---------------------------------"

        add_log "I" "Please confirm if you really want to continue to execute datax jobs(Yes/No): "
        read_user_confirm

        i=1
        failed="0"
        for conf_file in `ls ${DATAX_CONF_PATH}`; do
            datax_get_db_and_table
            basename_conf_file=`basename ${conf_file}`
            conf_dir="${DATAX_CONF_PATH}"
            if  [[ -s ${DATAX_CONF_PATH} ]]; then
                conf_dir=`dirname "${DATAX_CONF_PATH}"`
            fi
            
            add_log "I" "File No.: ${i}, file_path: ${conf_dir}/${basename_conf_file}"
            if [[ "${p_option}" != "" ]]; then
                add_log "D" "cmd: python3 ${DATAX_TOOL_PATH}/bin/datax.py -p ${p_option} ${conf_dir}/${basename_conf_file}"
                if ! python3 ${DATAX_TOOL_PATH}/bin/datax.py -p "${p_option}" ${conf_dir}/${basename_conf_file}; then
                    add_log "E" "Result: failed"
                    let failed=failed+1
                else
                    add_log "I" "Result: success"
                    datax_report_write
                fi
            else
                add_log "D" "cmd: python3 ${DATAX_TOOL_PATH}/bin/datax.py ${conf_dir}/${basename_conf_file}"
                if ! python3 ${DATAX_TOOL_PATH}/bin/datax.py ${conf_dir}/${basename_conf_file}; then
                    add_log "E" "Result: failed"
                    let failed=failed+1
                else
                    add_log "I" "Result: success"
                    datax_report_write
                fi

            fi

            let i=i+1
        done
        let total=i-1

        add_log "I" "---------------------------------"
        add_log "I" "             SUMMARY             "
        add_log "I" "------TOTAL: ${total}, FAILED: ${failed} ------"
        add_log "I" "---------------------------------"

    else
        add_log "E" "DATAX_CONF_PATH ${DATAX_CONF_PATH} is not a valid directory or a non-empty file, exiting"
        failed=1
    fi

    return ${failed}

}

function datax_report_list()
{
    if [[ ! -s ${DATAX_REPORT_FILE} ]]; then
        add_log "E" "Report DATAX_REPORT_FILE ${DATAX_REPORT_FILE} does not exist or is empty, exiting"
        return 1
    else
        cat ${DATAX_REPORT_FILE}
    fi

}


function datax()
{
    if ! datax_precheck; then
        return 1
    fi

    datax_get_conf

    if ! datax_run; then
        return 1
    fi

}