#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# auto_log_rotate

alr_name="auto_log_rotate"
LOG_ROTATE_CRON_PATH="/etc/logrotate.d"
LOG_ROTATE_CRON_FILE_NAME="mo-service"
MO_LOG_RESERVE_MAX_NUM="100000"
OS=""
LOG_SPLIT_STRATEGY=""

function auto_log_rotate_precheck() {
    # 1. Mac
    if [[ "${OS}" == "Mac" ]]; then

        add_log "E" "Auto log rotate on Mac is not yet supported"
        return 1
    # 2. Linux
    else
        # 1. check logrotate cmd
        add_log "I" "Check if logrotate command exists"
        flag=1
        if which logrotate > /dev/null 2>&1; then
            add_log "I" "Command 'which logrotate' found logrotate"
        elif [[ -f /usr/sbin/logrotate ]]; then
            add_log "I" "Command 'which logrotate' did not found logrotate, but found file '/usr/sbin/logrotate'"
        else
            add_log "E" "Either command 'which logrotate' nor file '/usr/sbin/logrotate' is found, exiting"
            return 1
        fi

        # 2. Check sudo privilege
        current_user=$(whoami)
        add_log "I" "Check if current user has sudo command, you may need to enter password for current user"
        if ! sudo ls /root > /dev/null 2>&1; then
            add_log "E" "Failed to execute cmd 'sudo ls /root' with current user '${current_user}', please make sure current user has sudo privilege"
            return 1
        fi

        # 3. Check MO_LOG_PATH conf
        add_log "I" "Check related confs as below:"
        get_conf | grep -E "MO_LOG_AUTO_SPLIT|MO_LOG_MAX_SIZE|MO_LOG_RESERVE_NUM"

        case "${MO_LOG_AUTO_SPLIT}" in
            "daily")
                LOG_SPLIT_STRATEGY="daily"
                ;;
            "size")
                if [ -z "${MO_LOG_MAX_SIZE}" ]; then
                    add_log "E" "Conf 'MO_LOG_AUTO_SPLIT' is set to 'size', but conf 'MO_LOG_MAX_SIZE' is not set, please set it first, e.g. mo_ctl set_conf MO_LOG_MAX_SIZE=1024M"
                    return 1
                else
                    LOG_SPLIT_STRATEGY="size ${MO_LOG_MAX_SIZE}"
                fi
                ;;
            *)
                add_log "E" "Invalid value ${MO_LOG_AUTO_SPLIT} for conf MO_LOG_AUTO_SPLIT, choose from: daily|size"
                return 1
                ;;
        esac

        add_log "D" "LOG_SPLIT_STRATEGY=${LOG_SPLIT_STRATEGY}"

        if ! pos_int_range "${MO_LOG_RESERVE_NUM}" "${MO_LOG_RESERVE_MAX_NUM}"; then
            add_log "E" "${MO_LOG_RESERVE_NUM} is not greater than 0 and less than ${MO_LOG_RESERVE_MAX_NUM}, please set it to an integer between 1 and ${MO_LOG_RESERVE_MAX_NUM}"
            return 1
        fi
    fi
}

function auto_log_rotate_status() {
    rc=0

    if [[ -s ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME} ]]; then
        add_log "D" "Cron file ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME} for ${alr_name} already exists, trying to get content: "
        acl_content=$(cat ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME})
        add_log "D" "${acl_content}"
        add_log "I" "${alr_name} status：enabled"
    else
        add_log "D" "Cron file ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME} for ${alr_name} does not exist"
        add_log "I" "${alr_name} status：disabled"
        rc=1
    fi

    return ${rc}
}

function auto_log_rotate_enable() {
    if ! auto_log_rotate_precheck; then
        return 1
    fi

    if auto_log_rotate_status; then
        add_log "I" "Function auto_log_rotate has already been enabled, exiting"
        return 0
    fi

    add_log "D" "Writing content to ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}"
    add_log "D" "${MO_LOG_PATH}/*.log {" "l"
    add_log "D" "${LOG_SPLIT_STRATEGY}" "l"
    add_log "D" "compress" "l"
    add_log "D" "rotate ${MO_LOG_RESERVE_NUM}" "l"
    add_log "D" "copytruncate" "l"
    add_log "D" "missingok" "l"
    add_log "D" "notifempty" "l"
    add_log "D" "dateext" "l"
    add_log "D" "dateformat -%Y%m%d_%H%M%S" "l"
    add_log "D" "}" "l"

    add_log "I" "Password of current user may be required to execute command in sudo mode"

    add_log "D" "Command: sudo touch ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}"
    sudo touch ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}

    add_log "D" "sudo chmod 777 ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}"
    sudo chmod 777 ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}

    add_log "D" "Command:"
    add_log "D" "sudo cat > ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME} << EOF" "l"
    add_log "D" "${MO_LOG_PATH}/*.log {" "l"
    add_log "D" "${LOG_SPLIT_STRATEGY}" "l"
    add_log "D" "compress" "l"
    add_log "D" "rotate ${MO_LOG_RESERVE_NUM}" "l"
    add_log "D" "copytruncate" "l"
    add_log "D" "missingok" "l"
    add_log "D" "notifempty" "l"
    add_log "D" "dateext" "l"
    add_log "D" "dateformat -%Y%m%d_%H%M%S" "l"
    add_log "D" "}" "l"
    add_log "D" "EOF" "l"

    sudo cat > ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME} << EOF
${MO_LOG_PATH}/*.log {
${LOG_SPLIT_STRATEGY}
compress
rotate ${MO_LOG_RESERVE_NUM}
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
EOF

    add_log "D" "sudo chmod 644 ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}"
    sudo chmod 644 ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}

    if ! auto_log_rotate_status; then
        add_log "Failed to enable auto_log_rotate"
        return 1
    fi

}

function auto_log_rotate_disable() {
    if ! auto_log_rotate_precheck; then
        return 1
    fi

    if ! auto_log_rotate_status; then
        add_log "I" "Function auto_log_rotate has already been disabled, exiting"
        return 0
    fi

    add_log "I" "Disabling ${alr_name} by removing cron file ${LOG_ROTATE_CRON_PATH}/${LOG_ROTATE_CRON_FILE_NAME}"
    if cd ${LOG_ROTATE_CRON_PATH} && sudo rm -f ./${LOG_ROTATE_CRON_FILE_NAME}; then
        add_log "I" "Succeeded"
    else
        add_log "E" "Failed"
        return 1
    fi

    if auto_log_rotate_status; then
        add_log "E" "Failed to disable auto_log_rotate"
        return 1
    fi

}

function auto_log_rotate() {

    option="$1"
    OS=$(what_os)
    CLEAN_LOGS_CRON_USER=$(whoami)

    add_log "D" "Current OS: ${OS}"

    case "${option}" in
        "" | "status")
            auto_log_rotate_status
            ;;
        "enable")
            auto_log_rotate_enable
            ;;
        "disable")
            auto_log_rotate_disable
            ;;
        *)
            add_log "E" "Invalid option for ${alr_name}: ${option}"
            help_auto_log_rotate
            return 1
            ;;
    esac

}
