#!/bin/bash
#install.sh

function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"
    #format: 2023-07-13_15:37:40
    #nowtime=`date '+%F_%T'`
    #format: 2023-07-13_15:37:22.775
    nowtime=`date '+%Y-%m-%d_%H:%M:%S.%N'`
    nowtime=`echo "${nowtime}" | cut -b 1-23`
    
    case "${level}" in
        "e"|"E")
            level="ERROR"
            ;;
        "W"|"w")
            level="WARN" 
            ;;
        "I"|"i")
            level="INFO" 
            ;;
        "d"|"D")
            level="DEBUG" 
            ;;
        *)
            echo "These are valid log levels: E/e/W/w/I/i/D/d."
            echo "   E/e: ERROR, W/w: WARN, I/i: INFO, D/d: DEBUG"
            exit 1
        ;;
    esac 

    if [[ "${add_line}" == "n" ]]; then
        echo -n "${nowtime}    [${level}]    ${msg}"
    else
        echo "${nowtime}    [${level}]    ${msg}"
    fi
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
             "https://ghproxy.com/https://github.com/matrixorigin" \
           "https://ghproxy.com/https://github.com/matrixorigin" \
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
        if wget --timeout=60 --tries=2 ${URL} -O mo_ctl.zip; then
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
    os=`uname`
    os_user=`whoami`
    mo_ctl_global_path=/usr/local/bin
    mo_ctl_local_path=~/mo_ctl

    add_log "I" "Current os: ${os}, current user: ${os_user}"

    if [[ "${os_user}" == "" ]]; then
        add_log "E" "Get current os user failed"
        return 1
    fi

    if [[ "${os}" == "Darwin" ]]; then
        os="Mac"
        # mo_ctl_local_path="/Users/${os_user}/mo_ctl"
    elif [[ "${os}" == "Linux" ]]; then
        os="Linux"
        # mo_ctl_local_path="/data/mo_ctl"
        # mkdir -p /data/
    elif [[ "${os}" == "" ]]; then
        add_log "E" "Get current os failed"
        return 1
    else
        add_log "E" "Currently only Linux or Mac is supported"
        return 1
    fi


    if [[ ! -f ${pkg} ]]; then
        add_log "E"  "Error! Installation file ${pkg} is not found, please check again."
        return 1
    fi

    if [[ -d ${mo_ctl_local_path} ]]; then
        add_log "W" "Path ${mo_ctl_local_path} already exists, removing it now" 
        rm -rf ~/mo_ctl/
        #if [[ "${os}" == "Linux" ]]; then
        #    rm -rf /data/mo_ctl/
        #else
        #    rm -rf /Users/${os_user}/mo_ctl/
        #fi
    fi

    add_log "I" "Try to install mo_ctl from file ${pkg}" 
    if unzip -o mo_ctl.zip &&  mv ./mo_ctl_standalone-main/ ${mo_ctl_local_path} &&     chmod +x ${mo_ctl_local_path}/mo_ctl.sh; then
        add_log "I" "Successfully extracted mo_ctl file to ${mo_ctl_local_path}"
    else
        add_log "E"  "Failed to extract file, please check if 'unzip' is installed or file is complete"
        return 1
    fi
    
    add_log "I" "Setting up mo_ctl to ${mo_ctl_global_path}/mo_ctl" 

    if sudo touch ${mo_ctl_global_path}/mo_ctl && sudo chown ${os_user} ${mo_ctl_global_path}/mo_ctl && echo "bash +x ${mo_ctl_local_path}/mo_ctl.sh \"\$*\"" > ${mo_ctl_global_path}/mo_ctl && chmod +x ${mo_ctl_global_path}/mo_ctl; then
        add_log "I" "Succeeded"
    else
        add_log "E" "Failed"
    fi

    if [[ "${os}" == "Mac" ]]; then
        add_log "I" "Setting up default confs for mac: MO_PATH=/Users/${os_user}/mo"
        if ${mo_ctl_local_path}/mo_ctl.sh set_conf MO_PATH=/Users/${os_user}/mo; then
            add_log "I" "Succeeded"
        else
            add_log "E" "Failed"
        fi
    fi

    add_log "I" "Done. Successfully installed mo_ctl to path ${mo_ctl_local_path}/"
    add_log "I" "Use 'mo_ctl help' to get more info. Have Fun!" 

}

function main()
{
    option=$1
    case "${option}" in
        "")
            download && install "mo_ctl.zip"
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