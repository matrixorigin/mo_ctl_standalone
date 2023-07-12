#!/bin/bash
#uninstall.sh

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

function to_lower()
{
    echo $(echo $1 | tr '[A-Z]' '[a-z]') 
}

function usage()
{
    echo "  Usage          : $0" # uninstalling mo_ctl tool, will need to input Yes/No to confirm or not
}


function uninstall()
{
    mo_ctl_global_path=/usr/local/bin
    mo_ctl_local_path=~/mo_ctl

    add_log "WARN" "You're uninstalling mo_ctl tool, are you sure? (Yes/No)"
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "ERROR" "User input not confirmed or timed out, exiting"
        return 1
    fi
    add_log "INFO" "Uninstalling mo_ctl now"
    add_log "INFO" "Removing path ${mo_ctl_local_path}"
    rm -rf ~/mo_ctl
    add_log "INFO" "Done"
    add_log "INFO" "Removing file ${mo_ctl_global_path}/mo_ctl"
    rm -f ${mo_ctl_global_path}/mo_ctl
    add_log "INFO" "Done"
    add_log "INFO" "All done, exiting"
}

function main()
{
    option=$1
    case "${option}" in
        "help")
            usage
            ;;
        *)
            uninstall
            ;;
    esac
}

main $*