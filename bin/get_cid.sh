#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# get_cid

function get_cid()
{
    option=$1

    add_log "I" "Try get mo commit id"
    if [[ ! -d ${MO_PATH}/matrixone ]]; then
        add_log "E" "Path ${MO_PATH}/matrixone does not exist, please make sure mo is deployed properly"
        add_log "E" "Get commit id failed, exiting"
        return 1
    fi
    cid_full="$(cd ${MO_PATH}/matrixone && git log | head -n 6)"
    cid_less=`echo ${cid_full} | grep "^commit" | awk '{print $2}'`
    if [[ "${cid_full}" != "" ]]; then
        if [[ "${option}" == "less" ]]; then
            echo "${cid_less}"
        else
            echo "${cid_full}"
        fi
        add_log "I" "Get commit id succeeded"
    else
        add_log "E" "Get commit id failed"
        return 1
    fi
}
