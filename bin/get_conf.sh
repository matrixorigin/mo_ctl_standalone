#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# get_conf

function get_kv()
{
    key=$1
    value=`grep "^${key}=" "${CONF_FILE}" | head -n 1 | awk -F"=" '{print $2}'`
    echo $value
}

function get_conf()
{
    list=$1
    rc=0    

    if [[ "${list}" == "" ]] || [[ "${list}" == "all" ]]; then
        add_log "I" "Below are all configurations set in conf file ${CONF_FILE}"
        grep -v "^#" "${CONF_FILE}" |tr -s '\n' | grep "="
        return 0
    fi

    for key in $(echo $list | sed "s/,/ /g")
    do
        value=`get_kv ${key}`
        if [ ! -n "${value}" ]; then
            add_log "E" "Get conf failed: ${key} is not set in conf file "${CONF_FILE}" or is set to empty value"
            rc=1
        else
            add_log "I" "Get conf succeeded: ${key}=${value}"
        fi
    done
    return ${rc}
}