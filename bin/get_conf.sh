#!/bin/bash
# getconf

function get_kv()
{
    key=$1
    value=`grep "^${key}=" "${CONF_FILE}" | head -1 | awk -F"=" '{print $2}'`
    echo $value
}

function get_conf()
{
    list=$1
    rc=0


    if [[ "${list}" == "" ]]; then
        add_log "ERROR" "Not conf detected, please specifiy at leaset one conf"
        help_get_conf
        return 1
    fi        

    if [[ "${list}" == "all" ]]; then
        add_log "INFO" "Below are all configurations set in conf file ${CONF_FILE}"
        grep -v "^#" "${CONF_FILE}" |tr -s '\n' | grep "="
        return 0
    fi

    for key in $(echo $list | sed "s/,/ /g")
    do
        value=`get_kv ${key}`
        if [ ! -n "${value}" ]; then
            add_log "ERROR" "Get conf failed: ${key} is not set in conf file "${CONF_FILE}" or is set to empty value"
            rc=1
        else
            add_log "INFO" "Get conf succeeded: ${key}=${value}"
        fi
    done
    return ${rc}
}