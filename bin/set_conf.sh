#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# set_conf

function set_kv()
{
    key=$1
    value=$2


    # 1. check if key is in conf list, that is, a valid key
    if ! grep "^${key}=.*" "${CONF_FILE}" >/dev/null 2>&1; then
        add_log "E" "Conf ${key} is not a valid item in conf file ${CONF_FILE}, skipping"
        return 1
    fi

    # 2. check if value is not empty, that is, a valid value
    if [[ "${value}" == "" ]]; then
        add_log "E" "The value of conf ${key} is empty, which is not allowed"
        rc=1
        return 1
    fi

    # 3. Set conf key=value
    add_log "I" "Setting conf ${key}=${value}"
    os=`what_os`
    if [[ ${os} == "Linux" ]] ; then
        sed -i "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
    else
        sed -i "" "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
    fi 

}

function set_conf()
{
    list=$*

    if [[ "${list}" == "" ]]; then
        add_log "E" "Set list cannot be empty"
        help_set_conf
        return 1
    fi

    rc=0
    for kv in $(echo $list | sed "s/,/ /g")
    do
        # 1. check if format is key=value
        if ! echo ${kv} | grep "=" >/dev/null 2>&1; then
            add_log "E" "Conf ${kv} is an invalid format, please set conf as key=value, skipping"
            rc=1
            continue
        fi

        # 2. seperate key=value
        key=`echo ${kv} | awk -F"=" '{print $1}'`
        value=`echo ${kv} | awk -F"=" '{print $2}'`


        # 3. set key=value
        add_log "I" "Try to set conf: ${key}=${value}"
        if ! set_kv "${key}" "${value}"; then
            rc=1
        else
            if [[ "${key}" == "MO_GIT_URL" ]]; then
                if [[ -d ${MO_PATH}/matrixone/.git/ ]]; then
                    add_log "I" "Key is MO_GIT_URL, setting mo git remote url"
                    if cd ${MO_PATH}/matrixone/ && git remote set-url origin ${value}; then
                        add_log "I" "Succeeded"
                    else
                        add_log "E" "Failed"
                        rc=1
                    fi
                fi
            fi
        fi
    done

    return ${rc}
}