#!/bin/bash
# setconf

function set_kv()
{
    key=$1
    value=$2


    # 1. check if key is in conf list, that is, a valid key
    if ! grep "^${key}=.*" "${CONF_FILE}" >/dev/null 2>&1; then
        add_log "ERROR" "Conf ${key} is not a valid item in conf file ${CONF_FILE}, skipping"
        return 1
    fi

    # 2. check if value is not empty, that is, a valid value
    if [[ "${value}" == "" ]]; then
        add_log "ERROR" "The value of conf ${key} is empty, which is not allowed"
        rc=1
        return 1
    fi

    # 3. Set conf key=value
    add_log "INFO" "Setting conf ${key}=${value}"
    os=`what_os`
    if [[ ${os} == "Linux" ]] ; then
        sed -i "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
    else
        sed -i "" "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
    fi 

}

function set_conf()
{
    list=$1
    rc=0
    for kv in $(echo $list | sed "s/,/ /g")
    do
        # 1. check if format is key=value
        if ! echo ${kv} | grep "=" >/dev/null 2>&1; then
            add_log "ERROR" "Conf ${kv} is a invalid format, please set conf as key=value, skipping"
            rc=1
            continue
        fi

        # 2. seperate key=value
        key=`echo ${kv} | awk -F"=" '{print $1}'`
        value=`echo ${kv} | awk -F"=" '{print $2}'`


        # 3. set key=value
        add_log "INFO" "Try to set conf: ${key}=${value}"
        if ! set_kv "${key}" "${value}"; then
            rc=1
        fi
    done

    return ${rc}
}