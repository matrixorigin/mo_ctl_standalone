#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# get_cid

function get_cid() {
    option=$1

    if [[ "${MO_DEPLOY_MODE}" != "git" ]]; then
        add_log "E" "Currently mo_ctl does not support get_branch when mo deploy mode is not git"
        return 1
    fi

    if [[ "${option}" != "less" ]]; then
        add_log "I" "Try get mo commit id"
    fi

    if [[ ! -d ${MO_PATH}/matrixone ]]; then
        add_log "E" "Path ${MO_PATH}/matrixone does not exist, please make sure mo is deployed properly"
        add_log "E" "Get commit id failed, exiting"
        return 1
    fi

    # better way to get commit id
    cid_full=$(cd ${MO_PATH}/matrixone && git log -n 1)
    cid_less=$(cd ${MO_PATH}/matrixone && git log -n 1 --format='%H')
    cid_less=$(echo "${cid_less:0:8}")

    #deprecated:
    #cid_full="$(cd ${MO_PATH}/matrixone && git log | head -n 6)"
    #cid_less=`echo ${cid_full} | grep "^commit" | awk '{print $2}'`
    if [[ "${cid_full}" != "" ]]; then
        if [[ "${option}" == "less" ]]; then
            echo "${cid_less}"
        else
            echo "${cid_full}"
        fi

        if [[ "${option}" != "less" ]]; then
            add_log "I" "Get commit id succeeded"
        fi
    else
        add_log "E" "Get commit id failed"
        return 1
    fi
}
