#!/bin/bash
# cid

function get_cid()
{
    option=$1

    add_log "INFO" "Try get mo commitid: "
    cid_full="$(cd ${MO_PATH}/matrixone && git log | head -n 6)"
    cid_less=`echo ${cid_full} | grep "^commit" | awk '{print $2}'`
    if [[ "${cid_full}" != "" ]]; then
        if [[ "${option}" == "less" ]]; then
            echo "${cid_less}"
        else
            echo "${cid_full}"
        fi
        add_log "INFO" "Get commit id succeeded"
    else
        add_log "ERROR" "Get commit id failed"
        return 1
    fi
}
