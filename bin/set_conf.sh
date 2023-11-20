#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# set_conf

function set_kv()
{
    key="$1"
    value="$2"

    # replace '*' with '\*'
    value=`echo "${value}" |sed "s/\*/\\\\\*/g"`

    add_log "D" "key: ${key}, value: ${value}"


    # 1. check if key is in conf list, that is, a valid key
    if ! grep "^${key}=.*" "${CONF_FILE}" >/dev/null 2>&1; then
        add_log "E" "Conf ${key} is not a valid item in conf file ${CONF_FILE}, skipping"
        return 1
    fi

    # 2. check if value is not empty, that is, a valid value
    if [[ "${value}" == "" ]]; then
        case "${key}" in
            "MO_CONTAINER_DATA_HOST_PATH" | "MO_CONTAINER_CONF_HOST_PATH" | "CSV_CONVERT_META_COLUMN_LIST" | "MO_CONTAINER_LIMIT_CPU" | "MO_CONTAINER_LIMIT_MEMORY" | "MO_CONTAINER_EXTRA_MOUNT_OPTION")
                :
                ;;
            *)
                add_log "E" "The value of conf ${key} is empty, which is not allowed"
                rc=1
                return 1
            ;;
        esac 

    fi

    # 3. Set conf key=value
    add_log "I" "Setting conf ${key}=\"${value}\""
    os=`what_os`
    if [[ ${os} == "Linux" ]] ; then
        sed -i "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
    else
        sed -i "" "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
    fi 

}

function set_conf()
{
    list="$*"
    tmp_key=`to_lower "${list}"`

    add_log "D" "conf list: ${list}"

    # list cannot be empty
    if [[ "${list}" == "" ]]; then
        add_log "E" "Set list cannot be empty"
        help_set_conf
        return 1
    # reset conf
    elif [[ "${tmp_key}" == "reset" ]]; then
        add_log "I" "You're about to set all confs, which will be replaced by default settings. This could be dangerous since all of your current settings will be lost!!! Are you sure? (Yes/No)"
        read -t 30 user_confirm
        if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
            add_log "E" "User input not confirmed or timed out, exiting"
            return 1
        fi
        
        if cp -pf ${CONF_FILE_DEFAULT} ${CONF_FILE}; then
            add_log "I" "Reset all confs succeeded"
            return 0
        else
            add_log "E" "Reset confs failed"
            return 1
        fi
    fi


    rc=0
    
    # deprecated: setting multiple confs in a time is no longer supported
    # for kv in $(echo "$list")
    # deprecated: seperated by ',' is no longer supported   
    # for kv in $(echo $list | sed "s/,/ /g")
    # do
    kv="${list}"
        # 1. check if format is key=value
        if ! echo "${kv}" | grep "=" >/dev/null 2>&1; then
            add_log "E" "Conf ${kv} is an invalid format, please set conf as key=value, skipping"
            rc=1
            continue
        fi

        # 2. seperate key=value
        key=`echo "${kv}" | awk -F"=" '{print $1}'`
        value=`echo "${kv}" | awk -F"=" '{print $2}'`


        # 3. set key=value
        add_log "I" "Try to set conf: ${key}=\"${value}\""
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
    # done

    return ${rc}
}