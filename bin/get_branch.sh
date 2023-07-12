#!/bin/bash
# cid

function get_branch()
{
    option=$1

    add_log "INFO" "Try get mo branch"
    if [[ ! -d ${MO_PATH}/matrixone ]]; then
        add_log "ERROR" "Path ${MO_PATH}/matrixone does not exist, please make sure mo is deployed properly"
        add_log "ERROR" "Get branch failed, exiting"
        return 1
    fi
    current_branch=`cd ${MO_PATH}/matrixone && git branch | grep "\*" | head -1`
    current_branch=`echo "${current_branch:2}"`
    if [[ "${current_branch}" != "" ]]; then
        add_log "INFO" "Get branch succeeded, current branch: ${current_branch}"
    else
        add_log "ERROR" "Get branch failed"
        return 1
    fi
}
