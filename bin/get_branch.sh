#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# get_branch

function get_branch()
{
    option=$1

    if [[ "${MO_DEPLOY_MODE}" != "git" ]]; then
        add_log "E" "Currently mo_ctl does not support get_branch when mo deploy mode is not git"
        return 1
    fi

    if [[ "${option}" != "less" ]]; then
        add_log "I" "Try get mo branch"
    fi
    
    if [[ ! -d ${MO_PATH}/matrixone ]]; then
        add_log "E" "Path ${MO_PATH}/matrixone does not exist, please make sure mo is deployed properly"
        add_log "E" "Get branch failed, exiting"
        return 1
    fi
    current_branch=`cd ${MO_PATH}/matrixone && git branch | grep "\*" | head -1`
    current_branch=`echo "${current_branch:2}"`
    
    cd ${MO_PATH}/matrixone
    if echo "${current_branch}" | grep "HEAD" >/dev/null 2>&1; then
        if [[ "${option}" != "less" ]]; then
            add_log "I" "current_branch is ${current_branch}, contains \"HEAD\" info, thus it's a commit id, trying to find it's real branch"
        fi
        cid_full=`git log | head -n 1 | awk {'print $2'}`
        cid_less=`echo "${cid_full:0:8}"`
        cd ${MO_PATH}/matrixone
        current_branch=`git branch --contains ${cid_less} -a | grep -v HEAD | sed 's/ //g' | awk -F "/" '{print $NF}'`
        add_log "D" "cid_full: ${cid_full}, cid_less: ${cid_less}, current_branch: ${current_branch}"
    fi

    if [[ "${current_branch}" != "" ]]; then
        MO_V_TYPE="branch"
        if [[ "${option}" != "less" ]]; then
            add_log "I" "Get branch succeeded, current branch: ${current_branch}"
        else
            echo "${current_branch}"
        fi      
    else
        if [[ "${option}" != "less" ]]; then
            add_log "I" "No branch contains this commit, try to match a tag"
        fi
        current_tag=`git tag --contains ${cid_less} | grep -v HEAD | sed 's/ //g' | sort | head -1`
        if [[ "${current_tag}" != "" ]]; then
            MO_V_TYPE="tag"
            if [[ "${option}" != "less" ]]; then
                add_log "I" "Get tag succeeded, current tag: ${current_tag}"
            else
                echo "${current_tag}"
            fi
        else
            MO_V_TYPE="unkown"
            add_log "E" "Get tag failed"
            return 1
        fi
    fi
}
