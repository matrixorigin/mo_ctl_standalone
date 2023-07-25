#!/bin/bash
#uninstall.sh

function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"

    os=`uname`
    if [[ "${os}" == "Darwin" ]]; then
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


function to_lower()
{
    echo $(echo $1 | tr '[A-Z]' '[a-z]') 
}

function usage()
{
    echo "  Usage          : $0" # uninstalling mo_ctl tool, will need to input Yes/No to confirm or not
}


function tool_uninstall()
{
    mo_ctl_global_path=/usr/local/bin
    mo_ctl_local_path=~/mo_ctl

    add_log "W" "You're uninstalling mo_ctl tool, are you sure? (Yes/No)"
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "E" "User input not confirmed or timed out, exiting"
        return 1
    fi
    add_log "I" "Uninstalling mo_ctl now"
    add_log "I" "Removing path ${mo_ctl_local_path}: rm -rf ~/mo_ctl"
    rm -rf ~/mo_ctl
    add_log "I" "Done"
    add_log "I" "Removing file ${mo_ctl_global_path}/mo_ctl: sudo rm -f ${mo_ctl_global_path}/mo_ctl"
    add_log "I" "If you're running on MacOS, we need your confirmation with password to run sudo commands" 

    sudo rm -f ${mo_ctl_global_path}/mo_ctl
    add_log "I" "Done"
    add_log "I" "All done, exiting"
}

function main()
{
    option=$1
    case "${option}" in
        "help")
            usage
            ;;
        *)
            tool_uninstall
            ;;
    esac
}

main $*