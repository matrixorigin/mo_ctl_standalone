#!/bin/bash
# upgrade

#global vars
current_branch=""
current_cid=""
target_branch=""
target_cid=""
RUN_TAG=""
MO_UPGRADE_PATH=""
action_type=""
declare -A stable_list

function init_global_vars()
{
    target_branch="main"
    current_cid=`get_cid less | sed -n '2p'`
    current_branch=`get_branch | grep "current branch" | head -n 1 | awk -F "current branch: " '{print $2}'`
    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
    MO_UPGRADE_PATH="${MO_PATH}/matrixone-bk-${RUN_TAG}"
    action_type="upgrade"

    stable_list=(
        ["0.8.0"]="3bd05cb14f32dbca4cf57abe03fec4907450c7e7"
        ["0.7.0"]="6d4bd173514990032372310f7b3d9d803781074a"
        ["0.6.0"]="c3262c1b58d030b00534283b9bd22cc83c888a2a"
        ["0.5.1"]="c9491645c681c9e239817a6fa71fb71df25003e2"
        ["0.4.0"]="aefc440bf6d6c2a5e96ba411fb0c98ae0b8bd657"
        ["0.3.0"]="56fcd3ff8e4aa3b5a8b9d08c420fa90f7462c579"
        ["0.2.0"]="c22aa58f948cef7e59acef1ebabb8f8dfd4154cd"
        ["0.1.0"]="19cc0453b573e23ae643bea492bc43c5df4758db"
    )



}



function check_upgrade_pre_requisites()
{
    rc=0
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
    if ls -a ${MO_PATH}/matrixone/ | grep -vE "logs|^.$|^..$|mo-service|mo-dump" | xargs -i cp -r ${MO_PATH}/matrixone/{} ${MO_UPGRADE_PATH}/ >/dev/null 2>&1; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed, exiting"
        return 1
    fi
}


function validate_target_cid()
{

    cd ${MO_UPGRADE_PATH}

    # 0. Output info
    add_log "INFO" "Specified upgrade info:"
    add_log "INFO" "current branch: ${current_branch}, current commit id: ${current_cid}"
    add_log "INFO" "target branch: ${target_branch}, target commit id: ${target_cid}"



    # 1. check if target commit id is a valid stable version
    if [ -v stable_list["${target_cid}"] ] ; then
        add_log "INFO" "Target commit id ${target_cid} is a stable version, whose last commit id is ${stable_list[${target_cid}]}"
        target_branch="${target_cid}"
        target_cid="${stable_list[${target_cid}]}"
    fi

    # 2. currently mo is already on this commit id
    if echo "${current_cid}" | grep "${target_cid}" >/dev/null 2>&1 || echo "${target_cid}" | grep "${current_cid}" >/dev/null 2>&1 ; then
        add_log "INFO" "Current commit id seems to match target, thus no need to perform any upgrade, exiting"
        exit 0
    fi

    # 3 checkout target branch or commit id
    # 3.1. switch to target branch
    # e.g. branch not the same: 0.8.0 -> main, main -> 0.8.0, 0.8.0 -> 0.7.0
    if [[ "${current_branch}" != "${target_branch}" ]]; then
        add_log "INFO" "Current and target branch are not the same, switching to target: git checkout ${target_branch}"
        if ! git checkout ${target_branch}; then
            add_log "ERROR" "Failed, exiting"
            return 1
        fi
    else
    # 3.2. git fetch to update codes on local repository
    # e.g. branch=main, but switch commit id de596817 -> d3661e7d
        # 3.2.1 git fetch
        add_log "INFO" "Git fetching: git fetch"
        if ! git fetch; then
            add_log "ERROR" "Failed, exiting"
            return 1
        fi

        # 3.2.2 get latest commit id if target cid is set to latest
        if [[ "${target_cid}" == "latest" ]]; then
            target_cid=`git log ${target_branch} | head  -n 1 | awk '{print $2}'`
            add_log "INFO" "Latest commit id on remote repository is ${target_cid}"
            if echo "${current_cid}" | grep "${target_cid}" >/dev/null 2>&1; then
                add_log "INFO" "Target commit id ${target_cid} seems to match current commit id ${current_cid}"
                add_log "INFO" "No need to perform any upgrade, exiting"
                exit 0
            fi
        fi

        # 3.2.3 check if target commit id is submitted
        add_log "INFO" "Check if the given commit id ${target_cid} is valid: git merge-base --is-ancestor HEAD ${target_cid}"
        git merge-base --is-ancestor HEAD ${target_cid} >/dev/null 2>&1
        check_cid_result=`echo $?`
        if [[ "${check_cid_result}" == "0" ]]; then
            add_log "INFO" "Succeeded, valid target commit id is newer than current, thus it's an UPGRADE"
            action_type="upgrade"
        elif [[ "${check_cid_result}" == "1" ]]; then
            add_log "INFO" "Succeeded, valid target commit id is older than current, thus it's a DOWNGRADE"
            action_type="downgrade"
        else 
            add_log "ERROR" "Failed, commit id seems to be invalid, exiting"
            return 1
        fi

    fi

    add_log "INFO" "Actual upgrade info:"
    add_log "INFO" "current branch: ${current_branch}, current commit id: ${current_cid}"
    add_log "INFO" "target branch: ${target_branch}, target commit id: ${target_cid}"

}

function update_src_codes()
{    
 
    cd ${MO_UPGRADE_PATH}

    # 1. pull : merge codes from local repository to local workdir
    add_log "INFO" "Git pulling: git pull"
    if git pull; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed, exiting"
        return 1
    fi

    # 2. checkout to target commit id
    if [[ "${target_cid}" == "main" ]]; then
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
    if cd ${MO_UPGRADE_PATH}/ && make build ; then
        add_log "INFO" "Build succeeded"
    else
        add_log "ERROR" "Build failed"
        return 1
    fi


}
function upgrade_build_mo_dump()
{
    add_log "INFO" "Try to build mo-dump: make build modump"
    if cd ${MO_UPGRADE_PATH}/ && make build modump; then
        add_log "INFO" "Build succeeded"
    else
        add_log "ERROR" "Build failed"
        return 1
    fi
}


function upgrade_build_all()
{
    rc=0
    if [[ "${GOPROXY}" != "" ]]; then
        add_log "INFO" "GOPROXY is set, setting go proxy to GOPROXY=${GOPROXY}"
        go env -w GOPROXY=${GOPROXY}
    fi

    if ! upgrade_build_mo_service; then
        rc=1
    fi

    if ! upgrade_build_mo_dump; then
        rc=1
    fi

    return ${rc}

}

function upgrade_rollback()
{
    mv ${MO_UPGRADE_PATH} ${MO_PATH}/matrixone-UPGRADE-FAILED-${RUN_TAG}
}

function upgrade_commit()
{
    # copy mo logs
    if [[ -d "${MO_LOG_PATH}" ]] ; then 
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

    add_log "INFO" "All ${action_type} actions succeeded. Please use 'mo_ctl start' or 'mo_ctl restart' to restart your mo-service"


    return 0
}