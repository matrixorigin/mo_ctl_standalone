#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# upgrade

#global vars
current_branch=""
current_cid=""
target_branch=""
target_cid=""
RUN_TAG=""
MO_UPGRADE_PATH=""
action_type=""
is_cid_notlatest_notstable_valid=""
#declare -A stable_list



function init_global_vars()
{
    current_cid=`get_cid less | sed -n '2p'`
    current_branch=`get_branch | grep "current branch" | head -n 1 | awk -F "current branch: " '{print $2}'`
    target_branch="${current_branch}"
    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
    MO_UPGRADE_PATH="${MO_PATH}/matrixone-bk-${RUN_TAG}"
    is_cid_notlatest_notstable_valid="1"
    # deprecated: this only works on bash v4 but not bash v3, so might raise issues on MacOS
    # see: https://github.com/matrixorigin/mo_ctl_standalone/issues/42
    #stable_list=(
    #    ["0.8.0"]="3bd05cb14f32dbca4cf57abe03fec4907450c7e7"
    #    ["0.7.0"]="6d4bd173514990032372310f7b3d9d803781074a"
    #    ["0.6.0"]="c3262c1b58d030b00534283b9bd22cc83c888a2a"
    #    ["0.5.1"]="c9491645c681c9e239817a6fa71fb71df25003e2"
    #    ["0.4.0"]="aefc440bf6d6c2a5e96ba411fb0c98ae0b8bd657"
    #    ["0.3.0"]="56fcd3ff8e4aa3b5a8b9d08c420fa90f7462c579"
    #    ["0.2.0"]="c22aa58f948cef7e59acef1ebabb8f8dfd4154cd"
    #    ["0.1.0"]="19cc0453b573e23ae643bea492bc43c5df4758db"
    #)

}



function check_upgrade_pre_requisites()
{
    rc=0
    if [[ "${target_cid}" == "" ]]; then
        add_log "E" "Please specify a commit id to upgrade"
        help_upgrade
        rc=1
        return ${rc}
    fi

    if status; then
        add_log "E" "Please make sure no mo-service is running."
        add_log "I" "You may use 'mo_ctl stop [force]' to stop mo-service"
        rc=1
    fi

    if watchdog; then
        add_log "E" "Please make sure mo-watchdog is disabled before upgrading."
        add_log "I" "You may use 'mo_ctl watchdog disable' to disable mo-watchdog"
        rc=1
    fi
    return ${rc}
}

function copy_mo_path()
{
    add_log "I" "Copying upgrade path from ${MO_PATH}/matrixone/ to ${MO_UPGRADE_PATH}/"
    mkdir -p ${MO_UPGRADE_PATH}/
    if ls -a ${MO_PATH}/matrixone/ | grep -vE "logs|^.$|^..$|mo-data|mo-service|mo-dump" | xargs -I{} cp -r ${MO_PATH}/matrixone/{} ${MO_UPGRADE_PATH}/ >/dev/null 2>&1; then
        add_log "I" "Succeeded"
    else
        add_log "E" "Failed, exiting"
        return 1
    fi
}


function validate_target_cid()
{

    cd ${MO_UPGRADE_PATH}

    # 0. Output info
    add_log "I" "Specified info:"
    add_log "I" "1. current branch: ${current_branch}, current commit id: ${current_cid}"
    add_log "I" "2. target branch: ${target_branch}, target commit id: ${target_cid}"


    # 1. check if target commit id is a valid stable version
    s_cid=`get_stable_cid "${target_cid}"`
    if [[ "${s_cid}" != "${target_cid}" ]]; then
        add_log "I" "Target commit id ${target_cid} is a stable version, whose last commit id is ${s_cid}"
        target_branch="${target_cid}"
        before_t_cid="${target_cid}"
        target_cid="${s_cid}"
    fi

    # deprecated
    #if [ -v stable_list["${target_cid}"] ] ; then
    #    add_log "I" "Target commit id ${target_cid} is a stable version, whose last commit id is ${stable_list[${target_cid}]}"
    #    target_branch="${target_cid}"
    #    target_cid="${stable_list[${target_cid}]}"
    #fi

    # 2. currently mo is already on this commit id
    if echo "${current_cid}" | grep "${target_cid}" >/dev/null 2>&1 || echo "${target_cid}" | grep "${current_cid}" >/dev/null 2>&1 ; then
        add_log "I" "Current commit id seems to match target, thus no need to perform any upgrade, exiting"
        exit 0
    fi

    # 3 checkout target branch
     if [[ "${current_branch}" != "${target_branch}" ]]; then
        # 3.1. switch to target branch
        # e.g. branch not the same: 0.8.0 -> main, main -> 0.8.0, 0.8.0 -> 0.7.0
        add_log "I" "Current and target branch are not the same, switching to target: git checkout ${target_branch}"
        if [[ "${target_branch}" == "main" ]] || [[ "${target_branch}" > "${current_branch}" ]]; then
            add_log "I" "Target branch is main or newer than current, thus it's an UPGRADE"
            action_type="upgrade"
        else
            add_log "I" "Target branch is older than current, thus it's a DOWNGRADE"
            action_type="downgrade"
        fi
        if ! git checkout ${target_branch}; then
            add_log "E" "Failed, exiting"
            return 1
        fi
    else
        # 3.2. git fetch to update codes on local repository
        # e.g. branch=main, but switch commit id de596817 -> d3661e7d
        add_log "I" "Git fetching: git fetch"
        if ! git fetch; then
            add_log "E" "Failed, exiting"
            return 1
        fi
    fi

    # 4. If target branch is main
    if [[ "${target_branch}" == "main"  ]]; then
        if [[ "${current_branch}" != "main" ]]; then
            add_log "I" "Current branch ${current_branch} is not on main, checking out to main: git checkout main"
            ! git checkout main && return 1
        fi
        if [[ "${target_cid}" == "latest" ]]; then
            # 4.1. get latest commit id if target cid is set to latest
            before_t_cid="${target_cid}"
            target_cid=`git rev-parse origin/${target_branch} | head  -n 1`
                add_log "I" "Target commit id is latest, thus it's an UPGRADE"
                action_type="upgrade"
                add_log "I" "Latest commit id on remote repository is ${target_cid}"
            if echo "${current_cid}" | grep "${target_cid}" >/dev/null 2>&1; then
                add_log "I" "Target commit id ${target_cid} seems to match current commit id ${current_cid}"
                add_log "I" "No need to perform any upgrade, exiting"
                exit 0
            fi

        else
            # 4.2. check if target commit id is submitted, that is, a valid commit id
            add_log "I" "Check if the given commit id ${target_cid} is valid: git merge-base --is-ancestor ${current_cid} ${target_cid}"
            git merge-base --is-ancestor ${current_cid} ${target_cid} >/dev/null 2>&1
            check_cid_result=`echo $?`
            if [[ "${check_cid_result}" == "0" ]]; then
                if [[ "action_type" != "" ]]; then

                    add_log "I" "Succeeded, valid target commit id is newer than current, thus it's an UPGRADE"
                    action_type="upgrade"
                fi
            elif [[ "${check_cid_result}" == "1" ]]; then
                if [[ "action_type" != "" ]]; then
                    add_log "I" "Succeeded, valid target commit id is older than current, thus it's a DOWNGRADE"
                    action_type="downgrade"
                fi
            else 
                
                add_log "E" "Failed, commit id ${target_cid} seems to be invalid, exiting"
                return 1
            fi

            is_cid_notlatest_notstable_valid="0"
        fi
    fi


    # 5. print action info
    add_log "I" "Actual info:"
    add_log "I" "1. current branch: ${current_branch}, current commit id: ${current_cid}"
    add_log "I" "2. target branch: ${target_branch}, target commit id: ${target_cid}"
    add_log "I" "3. action_type: ${action_type}"
}

function update_src_codes()
{    
 
    cd ${MO_UPGRADE_PATH}

    # 1. pull : merge codes from local repository to local workdir
    add_log "I" "Git pulling: git pull"
    if git pull; then
        add_log "I" "Succeeded"
    else
        add_log "E" "Failed, exiting"
        return 1
    fi

    # 2. checkout to target cid
    if [[ "${is_cid_notlatest_notstable_valid}" == "0"  ]]; then
        add_log "I" "Checking out to target commit id ${target_cid}: git checkout ${target_cid}"
        git checkout ${target_cid} >/dev/null 2>&1
    fi

}

function upgrade_build_mo_service()
{
    # mo-service
    add_log "I" "Try to build mo-service: make build"
    if cd ${MO_UPGRADE_PATH}/ && make build ; then
        add_log "I" "Build succeeded"
    else
        add_log "E" "Build failed"
        return 1
    fi


}
function upgrade_build_mo_dump()
{
    add_log "I" "Try to build mo-dump: make cgo && make modump"
#    if cd ${MO_UPGRADE_PATH}/ && make build modump; then
    if cd ${MO_UPGRADE_PATH}/ && make cgo && make modump; then
        add_log "I" "Build succeeded"
    else
        add_log "E" "Build failed"
        return 1
    fi
}


function upgrade_build_all()
{
    rc=0
    if [[ "${GOPROXY}" != "" ]]; then
        add_log "I" "GOPROXY is set, setting go proxy to GOPROXY=${GOPROXY}"
        go env -w GOPROXY=${GOPROXY}
    fi

    if ! upgrade_build_mo_service; then
        rc=1
    fi

    #if ! upgrade_build_mo_dump; then
    #    rc=1
    #fi

    return ${rc}

}

function upgrade_rollback()
{
    add_log "I" "Rolling back ${action_type} actions by moving below folder"
    add_log "I" "${MO_UPGRADE_PATH} -> ${MO_PATH}/matrixone-${action_type}-FAILED-${RUN_TAG}"
    action_type=`to_upper "${action_type}"`
    mv ${MO_UPGRADE_PATH} ${MO_PATH}/matrixone-${action_type}-FAILED-${RUN_TAG}
}

function upgrade_commit()
{
    add_log "I" "Committing ${action_type} actions by moving below folders"
    action_type=`to_upper "${action_type}"`
    add_log "I" "1. ${MO_PATH}/matrixone/mo-data -> ${MO_UPGRADE_PATH}/"
    add_log "I" "2. ${MO_PATH}/matrixone -> ${MO_PATH}/matrixone-${action_type}-BACKUP-${RUN_TAG}"
    add_log "I" "3. ${MO_UPGRADE_PATH} -> ${MO_PATH}/matrixone"
    # copy mo logs
    if [[ -d "${MO_LOG_PATH}" ]] ; then 
        mv ${MO_LOG_PATH} ${MO_UPGRADE_PATH}/logs
    fi
    
    # move mo-data
    mv ${MO_PATH}/matrixone/mo-data ${MO_UPGRADE_PATH}/

    # move original mo folder to backup
    mv ${MO_PATH}/matrixone ${MO_PATH}/matrixone-${action_type}-BACKUP-${RUN_TAG}
    
    # move upgraded mo folder to current mo path
    mv ${MO_UPGRADE_PATH} ${MO_PATH}/matrixone

}


function upgrade()
{
    target_cid=$1

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
        add_log "E" "Currently mo_ctl does not support upgrade when mo deploy mode is docker"
        return 1
    fi

    # 0. initialize global variables
    init_global_vars


    
    # 1. check if target_cid is not empty and mo-service not running and mo-watchdog disabled
    if ! check_upgrade_pre_requisites; then
        return 1
    fi

    # 2. copy mo path
    if ! copy_mo_path; then
        return 1
    fi
    
    # 3. validate commit id
    if ! validate_target_cid; then
        upgrade_rollback
        return 1
    fi

    # 4. update codes in local workdir from remote repository
    if ! update_src_codes; then
        upgrade_rollback
        return 1
    fi

    # 5. rebuild mo-service and mo-dump
    if ! upgrade_build_all; then
        upgrade_rollback
        return 1
    fi

    # 5. commit all actions
    if ! upgrade_commit; then
        return 1
    fi

    add_log "I" "All ${action_type} actions succeeded. Please use 'mo_ctl start' or 'mo_ctl restart' to restart your mo-service"


    return 0
}