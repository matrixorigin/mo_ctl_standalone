#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# set_conf

# const

# enum
ENUM_TOOL_LOG_LEVEL="d,D,I,i,W,w,E,e"
ENUM_MO_DEPLOY_MODE="git,docker,binary"
#ENUM_MO_SERVER_TYPE="local,remote"
ENUM_MO_CONTAINER_AUTO_RESTART="no,yes"
ENUM_CSV_CONVERT_TYPE="1,2,3"
ENUM_CSV_CONVERT_TN_TYPE="1,2"
ENUM_CSV_CONVERT_INSERT_ADD_QUOTE="no,yes"
ENUM_BACKUP_TYPE="logical,physical"
ENUM_BACKUP_S3_IS_MINIO="no,yes"
ENUM_BACKUP_LOGICAL_DATA_TYPE="ddl,insert,csv"
ENUM_BACKUP_LOGICAL_ONEBYONE="0,1"

function set_kv() {
    key="$1"
    value="$2"

    # replace '*' with '\*'
    value=$(echo "${value}" | sed "s/\*/\\\*/g")

    add_log "D" "key: ${key}, value: ${value}"

    # 1. check if key is in conf list, that is, a valid key
    if ! grep "^${key}=.*" "${CONF_FILE}" > /dev/null 2>&1; then
        add_log "E" "Conf ${key} is not a valid item in conf file ${CONF_FILE}, skipping"
        return 1
    fi

    # 2. Validity check
    case "${key}" in
        # 2.1 enum list
        #"TOOL_LOG_LEVEL"| "MO_DEPLOY_MODE"| "MO_SERVER_TYPE"| "MO_CONTAINER_AUTO_RESTART"| "CSV_CONVERT_TYPE"| "CSV_CONVERT_TN_TYPE"| "CSV_CONVERT_INSERT_ADD_QUOTE"| "BACKUP_TYPE"| "BACKUP_S3_IS_MINIO"| "BACKUP_LOGICAL_DATA_TYPE"| "BACKUP_LOGICAL_ONEBYONE")
        "TOOL_LOG_LEVEL" | "MO_DEPLOY_MODE" | "MO_CONTAINER_AUTO_RESTART" | "CSV_CONVERT_TYPE" | "CSV_CONVERT_TN_TYPE" | "CSV_CONVERT_INSERT_ADD_QUOTE" | "BACKUP_TYPE" | "BACKUP_S3_IS_MINIO" | "BACKUP_LOGICAL_DATA_TYPE" | "BACKUP_LOGICAL_ONEBYONE")

            enum_list=$(eval echo '$'"ENUM_$key")
            enum_list_2=$(echo "${enum_list}" | sed "s/,/\|/g")
            found="false"
            for enum in $(echo "${enum_list}" | sed "s/,/ /g"); do

                if [[ "${value}" == "${enum}" ]]; then
                    found="true"
                fi
            done

            if [[ "${found}" == "false" ]]; then
                add_log "E" "The value '${value}' of key '${key}' is not valid, valid range: ${enum_list_2}"
                return 1
            fi

            ;;

        # TODO: other parameters
        "MO_CONTAINER_DATA_HOST_PATH" | "MO_CONTAINER_CONF_HOST_PATH" | "CSV_CONVERT_META_COLUMN_LIST" | "MO_CONTAINER_LIMIT_CPU" | "MO_CONTAINER_LIMIT_MEMORY" | "MO_CONTAINER_EXTRA_MOUNT_OPTION" | "MO_CONF_SRC_PATH")
            :
            ;;
        *)
            :
            #add_log "E" "The value of conf ${key} is empty, which is not allowed"
            #rc=1
            #return 1
            ;;
    esac

    # 3. Set conf key=value
    add_log "I" "Setting conf ${key}=\"${value}\""
    os=$(what_os)
    if [[ ${os} == "Linux" ]]; then
        if echo "${value}" | grep "#" > /dev/null 2>&1; then
            sed -i "s|^${key}=.*|${key}=\"${value}\"|g" "${CONF_FILE}"
        else
            sed -i "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
        fi
    else
        if echo "${value}" | grep "#" > /dev/null 2>&1; then
            sed -i "" "s|^${key}=.*|${key}=\"${value}\"|g" "${CONF_FILE}"
        else
            sed -i "" "s#^${key}=.*#${key}=\"${value}\"#g" "${CONF_FILE}"
        fi
    fi

}

function set_conf_by_file() {
    conf_file="$*"
    add_log "D" "conf_file: ${conf_file}"
    i=1
    while read line; do
        add_log "D" "Conf line number: ${i}, line content: ${line}"
        if echo "${line}" | grep -e "^#" > /dev/null 2>&1; then
            add_log "D" "Line has '#' in the beginning, ignoring it as a comment line"
            let i=i+1
            continue
        fi
        key=$(echo "${line}" | awk -F "=" '{print $1}')
        value=$(echo "${line}" | awk -F "=" '{print $2}' | sed 's/^"//;s/"$//')
        if [[ "${key}" == "" ]]; then
            add_log "W" "Conf key is empty, ignoring"
            let i=i+1
            continue
        fi
        set_conf "${key}=${value}"
        let i=i+1
    done < ${conf_file}
}

function set_conf() {
    list="$*"
    tmp_key=$(to_lower "${list}")

    add_log "D" "conf list: ${list}"

    # list cannot be empty
    if [[ "${list}" == "" ]]; then
        add_log "E" "Set list cannot be empty"
        help_set_conf
        return 1
    # reset conf
    elif [[ "${tmp_key}" == "reset" ]]; then
        add_log "I" "You're about to set all confs, which will be replaced by default settings. This could be dangerous since all of your current settings will be lost!!! Are you sure? (Yes/No)"

        read_user_confirm

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
    if ! echo "${kv}" | grep "=" > /dev/null 2>&1; then
        add_log "E" "Conf ${kv} is an invalid format, please set conf as key=value as key=value, skipping"
        rc=1
    fi

    # 2. seperate key=value
    key=$(echo "${kv}" | awk -F"=" '{print $1}')
    value=$(echo "${kv}" | awk -F"=" '{print $2}')

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
