#!/bin/bash
#install.sh

DOWNLOAD_FILE_RENAME="mo_ctl.zip"
TOOL_LOG_LEVEL="I"

function to_upper()
{
    echo $(echo $1 | tr '[a-z]' '[A-Z]') 
}

function to_lower()
{
    echo $(echo $1 | tr '[A-Z]' '[a-z]') 
}

function what_os()
{    
    system=`uname`
    os=""
    case "${system}" in
        "")
            return 1
            ;;
        "Darwin")
            os="Mac"
            ;;
        "Linux")
            os="Linux"
            ;;            
        *)
            os="OtherOS"
            ;;
    esac
    echo "${os}"
}

function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"

    os=`what_os`
    if [[ "${os}" == "Mac" ]]; then
        # 1. for Mac
        # format: 2023-07-25 17:39:24.904 UTC+0800
        timezone="UTC+0800"
        if which python3 >/dev/null 2>&1; then
            # in millisecond 
            timestamp_ms=`python3 -c "import datetime; print(datetime.datetime.now(datetime.timezone(datetime.timedelta(hours = 8))).strftime('%Y-%m-%d %H:%M:%S.%f'))" | cut -b 1-23`
        elif which python >/dev/null 2>&1; then
            # in millisecond 
            timestamp_ms=`python -c "import datetime; print(datetime.datetime.now(datetime.timezone(datetime.timedelta(hours = 8))).strftime('%Y-%m-%d %H:%M:%S.%f'))" | cut -b 1-23`
        else
            # in second
            timestamp_ms=`date '+%Y-%m-%d %H:%M:%S'`
        fi
        nowtime="${timestamp_ms} ${timezone}"
    else
        # 2. for Linux
        # format: 2023-07-13 15:37:40
        # nowtime=`date '+%F %T'`
        # format: 2023-07-25 17:39:24.904 UTC+0800
        nowtime="`date '+%Y-%m-%d %H:%M:%S.%N UTC%z'`"
        timestamp_ms="`echo "${nowtime}" | cut -b 1-23`"
        timezone="`echo "${nowtime}" | cut -b 31-39`"
        nowtime="${timestamp_ms} ${timezone}"
    fi

    level=`to_upper ${level}`
    display_log_level=`to_upper ${TOOL_LOG_LEVEL}`
    if [[ "${display_log_level}" == "" ]]; then
        display_log_level="I"
    fi
    case "${level}" in
        "E")
            level="ERROR"
            ;;
        "W")
            level="WARN"
            case "${display_log_level}" in
                "E")
                    return 0
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
        "I")
            level="INFO" 
            case "${display_log_level}" in
                "E"|"W")
                    return 0
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
        "D")
            level="DEBUG" 
            case "${display_log_level}" in
                "E"|"W"|"I")
                    return 0
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
        *)
            echo "These are valid log levels: E/e/W/w/I/i/D/d."
            echo "   E/e: ERROR, W/w: WARN, I/i: INFO, D/d: DEBUG"
            exit 1
        ;;
    esac 

    case "${add_line}" in
        "n" )
            echo -n "${nowtime}    [${level}]    ${msg}"
            ;;
        "l" )
            echo "${msg}"
            ;;
        *)
        echo "${nowtime}    [${level}]    ${msg}"
        ;;
    esac
}
function usage()
{
    echo "  Usage          : $0 [tool_path]"
    echo "  [tool_path]    : Optional. If specifed, $0 will try to install mo_ctl tool offline from the file path. It's recommended to use this way when your machine has limited access to the Internet."
    echo "                Otherwise, $0 will try to install mo_ctl from the Internet."
    echo "  e.g.           : $0                      # install mo_ctl online"
    echo "                 : $0 /tmp/mo_ctl.zip      # install mo_ctl offline"
    echo "  Pre-requisites : 1) unzip is installed; 2) run as root or a sudo user"
}

function download()
{
    SITES=(\
            # in case you're in mainland of China, you can set one of the backup addresses below to replace the default value:
             "https://mirror.ghproxy.com/https://github.com/matrixorigin" \
           "https://hub.njuu.cf/matrixorigin" \
           "https://hub.yzuu.cf/matrixorigin" \
           "https://kgithub.com/matrixorigin" \
           "https://gitclone.com/github.com" \
           # in case you can access to github directly
           "https://github.com/matrixorigin" \
    )

    rc="1"

    for site in ${SITES[@]}; do
        URL="${site}/mo_ctl_standalone/archive/refs/heads/main.zip"
        add_log "I" "Try to download mo_ctl from URL: ${URL}"
        if wget --timeout=60 --tries=2 ${URL} -O ${DOWNLOAD_FILE_RENAME}; then
            add_log "I" "Successfully downloaded mo_ctl"
            rc="0"
            break;
        fi
    done
    
    if [[ "${rc}" == "1" ]]; then
        add_log "E" "Failed to download after tyring all URLs. Please check if 'wget' is installed or Internet access is ok."
    fi

    return ${rc}

}

function install()
{
    pkg=$1
    os=`what_os`
    os_user=`whoami`
    mo_ctl_global_path=/usr/local/bin
    mo_ctl_local_path=~/mo_ctl

    add_log "I" "Current os: ${os}, current user: ${os_user}"

    if [[ "${os_user}" == "" ]]; then
        add_log "E" "Get current os user failed"
        return 1
    fi

    if [[ "${os}" != "Mac" ]] && [[ "${os}" != "Linux" ]]; then
        add_log "E" "Currently only Linux or Mac is supported"
        return 1
    fi

    add_log "I" "Try to install mo_ctl from file ${pkg}"

    if [[ ! -f ${pkg} ]]; then
        add_log "E"  "Error! Installation file ${pkg} is not found, please check again."
        return 1
    fi

    #pkg_basename=`basename ${pkg} .zip`
    #pkg_prefix=`echo ".zip"  | awk -F '.' '{print $1}'`
    if ! command -v unzip; then
        add_log "E" "Command 'unzip' is not found, please check it is installed"
        return 1
    fi

    tmp_path="./mo_ctl_tmp"
    add_log "D" "cmd: rm -rf ${tmp_path} && mkdir ${tmp_path}"
    if ! ( rm -rf ${tmp_path} && mkdir ${tmp_path} ) ; then
        add_log "E" "Failed to remove and re-create tmp path ${tmp_path}"
        return 1
    fi

    add_log "D" "cmd: unzip -o ${pkg} -d ${tmp_path}"
    if ! unzip -o ${pkg} -d ${tmp_path}; then
        add_log "E" "Failed to extract file ${pkg} to ${tmp_path}, please make sure file exists, file is complete or current user has enough privilege"
        return 1
    fi

    pkg_name_after_unzip=`ls ${tmp_path}`

    add_log "D" "cmd: unzip -o ${pkg} -d ${tmp_path}"
    if [[ -d ${mo_ctl_local_path} ]]; then
        add_log "W" "Path ${mo_ctl_local_path} already exists, removing it?(yes/no)" 
        user_confirm=""
        read -t 30 user_confirm
        if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
            add_log "E" "User input not confirmed or timed out, exiting"
            return 1
        fi
        add_log "D" "cmd: rm -rf ~/mo_ctl/"
        rm -rf ~/mo_ctl/
    fi

    add_log "D" "cmd: mv ${tmp_path}/${pkg_name_after_unzip} ${mo_ctl_local_path} && chmod +x ${mo_ctl_local_path}/mo_ctl.sh"
    if  mv ${tmp_path}/${pkg_name_after_unzip} ${mo_ctl_local_path} && chmod +x ${mo_ctl_local_path}/mo_ctl.sh; then
        add_log "I" "Successfully extracted mo_ctl file to ${mo_ctl_local_path}"
    else
        add_log "E"  "Failed to extract file, please check if 'unzip' is installed or file is complete"
        return 1
    fi
    
    add_log "I" "Setting up mo_ctl to ${mo_ctl_global_path}/mo_ctl" 
    add_log "D" "cmd: sudo mkdir -p ${mo_ctl_global_path}/ && sudo touch ${mo_ctl_global_path}/mo_ctl && sudo chown ${os_user} ${mo_ctl_global_path}/mo_ctl && echo "bash +x ${mo_ctl_local_path}/mo_ctl.sh \"\$*\"" > ${mo_ctl_global_path}/mo_ctl && chmod +x ${mo_ctl_global_path}/mo_ctl" 
    add_log "I" "If you're running on MacOS, we need your confirmation with password to run sudo commands"

    if sudo mkdir -p ${mo_ctl_global_path}/ && sudo touch ${mo_ctl_global_path}/mo_ctl && sudo chown ${os_user} ${mo_ctl_global_path}/mo_ctl && echo "bash +x ${mo_ctl_local_path}/mo_ctl.sh \"\$*\"" > ${mo_ctl_global_path}/mo_ctl && chmod +x ${mo_ctl_global_path}/mo_ctl; then
        add_log "I" "Succeeded"
    else
        add_log "E" "Failed"
        return 1
    fi

    if [[ "${os}" == "Mac" ]]; then
        add_log "I" "Setting up default confs for mac: MO_PATH=/Users/${os_user}/mo"
        add_log "D" "cmd: ${mo_ctl_local_path}/mo_ctl.sh set_conf MO_PATH=/Users/${os_user}/mo"
        if ${mo_ctl_local_path}/mo_ctl.sh set_conf MO_PATH=/Users/${os_user}/mo; then
            add_log "I" "Succeeded"
        else
            add_log "E" "Failed"
            return 1
        fi
    fi

    add_log "D" "cmd: chmod +x ${mo_ctl_local_path}/bin/*.sh"
    add_log "I" "Adding executable permission to scripts"
    if ! chmod +x ${mo_ctl_local_path}/bin/*.sh; then
        add_log "E" "Failed"
        return 1
    fi

    add_log "I" "Done. Successfully installed mo_ctl to path ${mo_ctl_local_path}/"
    add_log "I" "Use 'mo_ctl help' to get more info. Have Fun!" 

}

function main()
{
    option=$1
    case "${option}" in
        "")
            download && install "${DOWNLOAD_FILE_RENAME}"
            ;;
        "help")
            usage
            ;;
        *)
            install ${option}
            ;;
    esac
}

main $*