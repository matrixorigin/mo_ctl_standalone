#!/bin/bash
# upgrade

current_cid=`get_cid less | sed -n '2p'`
current_branch=`cd ${MO_PATH}/matrixone && git branch | head -n 1 | awk '{print $2}'`
target_branch="main"
RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
MO_UPGRADE_PATH="${MO_PATH}/matrixone-bk-${RUN_TAG}"

function check_pre_requisites()
{
    rc=0
    target_cid=$1
    if [[ "${target_cid}" == "" ]]; then
        add_log "ERROR" "Please specify a commit id to upgrade"
        help_upgrade
        rc=1
        return ${rc}
    fi

    if status; then
        add_log "ERROR" "Please make sure no mo-service is running."
        add_log "INFO" "You may use 'mo_ctl stop [force]' to stop mo-service"
        rc=1
    fi

    if watchdog; then
        add_log "ERROR" "Please make sure mo-watchdog is disabled before upgrading."
        add_log "INFO" "You may use 'mo_ctl watchdog disable' to disable mo-watchdog"
        rc=1
    fi
    return ${rc}
}

function copy_mo_path()
{
    add_log "INFO" "Copying upgrade path from ${MO_PATH}/matrixone/ to ${MO_UPGRADE_PATH}/"
    mkdir -p ${MO_UPGRADE_PATH}/
    if ls -a ${MO_PATH}/matrixone/ | grep -vE "logs|^.$|^..$" | xargs -i cp -r ${MO_PATH}/matrixone/{} ${MO_UPGRADE_PATH}/ >/dev/null 2>&1; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed, exiting"
        return 1
    fi
}

function update_src_codes()
{
    target_cid=$1

    cd ${MO_UPGRADE_PATH}

    add_log "INFO" "Current branch: ${current_branch}"

    # 1. switch to target branch
    if [[ "${current_branch}" != "${target_branch}" ]]; then
        add_log "INFO" "Switch from current branch ${current_branch} to ${target_branch}: git checkout ${target_branch}"
        if git checkout ${target_branch}; then
            add_log "INFO" "Succeeded"
        else
            add_log "ERROR" "Failed, exiting"
            return 1
        fi
    fi

    # 2. validate target commit id
    if [[ "${target_cid}" != "latest" ]]; then
        add_log "INFO" "Check if the given commit id ${target_cid} is valid: git merge-base --is-ancestor HEAD ${target_cid} || git merge-base --is-ancestor ${target_cid} HEAD"
        git merge-base --is-ancestor HEAD ${target_cid} >/dev/null 2>&1
        check_cid_result=`echo $?`
        if [[ "${check_cid_result}" == "0" ]] || [[ "${check_cid_result}" == "1" ]]; then
            add_log "INFO" "Succeeded"
        else 
            add_log "ERROR" "Failed, exiting"
            return 1
        fi
    fi

    # 3. pull : fetch and merge to latest codes
    add_log "INFO" "Pull(fetch and merge) latest mo codes: git pull"
    if git pull; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed, exiting"
        return 1
    fi

    # 4. checkout to target commit id
    if [[ "${target_cid}" != "latest" ]]; then
        add_log "INFO" "Check out to target commit id: git checkout ${target_cid}"
        if git checkout ${target_cid}; then
            add_log "INFO" "Succeeded"
        else
            add_log "ERROR" "Failed, exiting"
            return 1
        fi
    fi
}

function upgrade_build_mo_service()
{
    # mo-service
    add_log "INFO" "Try to build mo-service: make build"
    if cd ${MO_UPGRADE_PATH}/matrixone/ && make build ; then
        add_log "INFO" "Build succeeded"
    else
        add_log "ERROR" "Build failed"
        return 1
    fi


}
function upgrade_build_mo_dump()
{
    add_log "INFO" "Try to build mo-dump: make build modump"
    if cd ${MO_UPGRADE_PATH}/matrixone/ && make build modump; then
        add_log "INFO" "Build succeeded"
    else
        add_log "ERROR" "Build failed"
        return 1
    fi
}


function upgrade_build_all()
{
    force=$1

    if [[ "${GOPROXY}" != "" ]]; then
        add_log "INFO" "GOPROXY is set, setting go proxy to GOPROXY=${GOPROXY}"
        go env -w GOPROXY=${GOPROXY}
    fi

    if [[ "${force}" == "force" ]]; then
        build_mo_service
        build_mo_dump
    else
        if [[ -f "${MO_UPGRADE_PATH}/matrixone/mo-service" ]]; then
            add_log "INFO" "mo-service is already built on ${MO_UPGRADE_PATH}, no need to build"
        else
            build_mo_service
        fi

        if [[ -f "${MO_UPGRADE_PATH}/matrixone/mo-dump" ]]; then
            add_log "INFO" "mo-dump is already built on ${MO_UPGRADE_PATH}, no need to build"
        else
            build_mo_dump
        fi
    fi
}

function upgrade_rollback()
{
    mv ${MO_UPGRADE_PATH} ${MO_PATH}/matrixone-UPGRADE-FAILED-${RUN_TAG}
}

function upgrade_commit()
{
    # copy mo logs
    if -d "${MO_LOG_PATH}"; then 
        mv ${MO_LOG_PATH} ${MO_UPGRADE_PATH}/logs
    fi
    
    # move original mo folder to backup
    mv ${MO_PATH}/matrixone ${MO_PATH}/matrixone-UPGRADE-BACKUP-${RUN_TAG}
    
    # move upgraded mo folder to current mo path
    mv ${MO_UPGRADE_PATH} ${MO_PATH}/matrixone

}


function upgrade()
{
    target_cid=$1

    # 1. check if target_cid is not empty and mo-service not running
    if ! check_pre_requisites ${target_cid}; then
        return 1
    fi

    add_log "INFO" "Upgrading branch-commitid from ${current_branch}-${current_cid} to ${target_branch}-${target_cid}"

    if echo "${current_cid}" | grep "${target_cid}" >/dev/null 2>&1; then
        add_log "INFO" "Target commit id ${target_cid} seems to match current commit id ${current_cid}"
        add_log "INFO" "No need to perform any upgrade, exiting"
        return 0
    fi


    # 2. copy mo path
    if ! copy_mo_path; then
        return 1
    fi
    
    # 3. git fetch, check target_cid, and git pull operations on current mo path
    if ! update_src_codes ${target_cid}; then
        upgrade_rollback
        return 1
    fi

    # 4. rebuild mo-service and mo-dump
    if ! upgrade_build_all; then
        upgrade_rollback
        return 1
    fi

    # 5. commit all actions
    if ! upgrade_commit; then
        return 1
    fi
    add_log "INFO" "All upgrade actions succeeded. Please use 'mo_ctl start' or 'mo_ctl restart' to restart your mo-service"

    return 0
}