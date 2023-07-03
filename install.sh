#!/bin/bash

function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"
    nowtime=`date '+%F_%T'`
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
        add_log "INFO" "Try to download mo_ctl from URL: ${URL}"
        if wget --timeout=60 --tries=2 ${URL} -O mo_ctl.zip; then
            add_log "INFO" "Successfully downloaded mo_ctl"
            rc="0"
            break;
        fi
    done
    
    if [[ "${rc}" == "1" ]]; then
        add_log "ERROR" "Failed to download after tyring all URLs. Please check if 'wget' is installed or Internet access is ok."
    fi

    return ${rc}

}

function install()
{
    pkg=$1
    
    if [[ ! -f ${pkg} ]]; then
        add_log "ERROR"  "Error! Installation file ${pkg} is not found, please check again."
        return 1
    fi

    add_log "INFO" "Try to install mo_ctl from file ${pkg}" 

    if ! unzip -o mo_ctl.zip && mkdir -p /data/ && mv ./mo_ctl_standalone-main /data/mo_ctl; then
        add_log "ERROR"  "Failed to extract file, please check if 'unzip' is installed or file is complete"
        return 1
    fi

    add_log "INFO" "Successfully extracted mo_ctl file to /data/mo_ctl/" 

    add_log "INFO" "Setting up mo_ctl to /usr/bin/mo_ctl" 

    cd /data/mo_ctl/ && chmod +x ./mo_ctl.sh
    cat /dev/null > /usr/bin/mo_ctl   
    echo "bash +x /data/mo_ctl/mo_ctl.sh \$*" > /usr/bin/mo_ctl
    chmod +x /usr/bin/mo_ctl

    add_log "INFO" "Done. Successfully installed mo_ctl. Enjoy!!!"
    add_log "INFO" "Use 'mo_ctl help' to get more info" 

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