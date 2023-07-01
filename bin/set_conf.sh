#!/bin/bash
# setconf

function set_kv()
{
    KEY=$1
    VALUE=$2
    if [[ "${KEY}" == "" ]]; then
        add_log "ERROR" "Key is empty, please check again"
        return 1
    fi

    if ! grep "${KEY}=" "${CONF_FILE}" >/dev/null 2>&1; then
        add_log "INFO" "Key is not set in conf file yet, setting it now"
        echo "" >> "${CONF_FILE}"
        echo "${KEY}=\"${VALUE}\"" >> "${CONF_FILE}"
    else
        add_log "INFO" "Key is already set in conf file before, updating it now"
        os=`what_os`
        if [[ ${os} == "Linux" ]] ; then
            sed -i "s#^${KEY}=.*#${KEY}=\"${VALUE}\"#g" "${CONF_FILE}"
        else
            sed -i "" "s#^${KEY}=.*#${KEY}=\"${VALUE}\"#g" "${CONF_FILE}"
        fi 
    fi
}

function set_conf()
{
    list=$1
    rc=0
    for kv in $(echo $list | sed "s/,/ /g")
    do
        key=`echo ${kv} | awk -F"=" '{print $1}'`
        value=`echo ${kv} | awk -F"=" '{print $2}'`
        add_log "INFO" "Setting conf: ${key}=${value}"
        if set_kv "${key}" "${value}"; then
            add_log "INFO" "Succeeded"
        else
            add_log "ERROR" "Failed"
            rc=1
        fi    
    done
    return ${rc}
}