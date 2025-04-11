#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# upgrade

#global vars

current_branch=""
current_tag=""
current_cid=""
current_cid_full=""

target_type=""
actual_target=""
target_cid_full=""
target_branch=""

RUN_TAG=""
MO_UPGRADE_PATH=""
#action_type=""
#declare -A stable_list

function upgrade_init_vars() {

    cd ${MO_PATH}/matrixone
    current_cid=$(get_cid less)
    current_cid_full=$(get_cid)
    current_branch=$(get_branch less)
    current_tag=""
    if [[ "${MO_V_TYPE}" == "tag" ]]; then
        current_tag="${current_branch}"
        current_branch=""
    fi

    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
    MO_UPGRADE_PATH="${MO_PATH}/matrixone-UPGRADE-BK-${RUN_TAG}"
}

function upgrade_check_pre_requisites() {
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

# Step_2. Validate target commit id
function upgrade_valid_target() {
    target_cid=$1
    add_log "I" "Target: ${target_cid}"
    if [[ "${MO_DEPLOY_MODE}" != "git" ]]; then
        add_log "E" "Currently upgrade is only supported when mo is deployed in git mode. Please check MO_DEPLOY_MODE again"
        return 1
    fi

    add_log "D" "Try to get current commit id"

    cd ${MO_PATH}/matrixone

    add_log "I" "Current info:"
    add_log "I" "Commit id: ${current_cid}, branch: ${current_branch}, tag: ${current_tag}"

    if [[ "${target_cid}" == "latest" ]]; then
        # 1. is current commit a tag?
        if [[ "${current_tag}" != "" ]]; then
            add_log "E" "MO is currently on a tag but not a branch, thus upgrade to latest is not possible. Please specify a commit id, a branch or a tag"
            return 1
        fi
        add_log "D" "Command: git fetch"

        # 2. current commit id a branch commit id, so is current commit id the newest?
        git fetch
        latest_cid=$(git rev-parse origin/${current_branch} | head -n 1)
        add_log "I" "Latest commit id on current branch ${current_branch} is ${latest_cid}"
        if echo "${latest_cid}" | grep "${current_cid}" > /dev/null 2>&1; then
            #if [[ "${latest_cid}" == "${current_cid}" ]]; then
            add_log "W" "Current commit id is already latest, no need to perform upgrade, exiting"
            return 1
        fi

        # 3. target is latest commid id
        actual_target="${current_branch}"
        target_type="branch"

    else
        # check if target cid is a valid branch, commit id or tag
        remote_tags=$(git tag)
        remote_branches=$(git branch -r | awk -F'origin/' '{print $2}' | grep -v HEAD)

        add_log "D" "List of remote tags:"
        add_log "D" "${remote_tags}" "l"
        add_log "D" "List of remote branches:"
        add_log "D" "${remote_branches}" "l"

        target_type="unknown"
        actual_target="${target_cid}"
        # 1. is it a tag?
        for tag in ${remote_tags}; do
            if [[ "${tag}" == "${target_cid}" ]]; then
                add_log "I" "Tag ${tag} mathces target ${target_cid}"
                target_type="tag"

                if [[ "${target_cid}" == "${current_tag}" ]]; then
                    add_log "W" "Currently on a tag ${current_tag} which is the same as given target ${target_cid}, no need to perform upgrade, exiting"
                    return 2
                fi
                break
            fi
        done

        # 2. is it a branch?
        if [[ "${target_type}" == "unknown" ]]; then
            add_log "D" "No tag mathces target ${target_cid}, trying to match a branch"
            for branch in ${remote_branches}; do
                if [[ "${branch}" == "${target_cid}" ]]; then
                    target_type="branch"
                    add_log "I" "Branch ${branch} mathces target ${target_cid}"
                    git fetch
                    latest_cid=$(git rev-parse origin/${branch} | head -n 1)
                    add_log "I" "Latest commit id on target branch ${branch} is ${latest_cid}"

                    if echo "${latest_cid}" | grep "${current_cid}" > /dev/null 2>&1; then
                        #if [[ "${latest_cid}" == "${current_cid}" ]]; then
                        add_log "W" "Current commit id is already latest, no need to perform upgrade, exiting"
                        return 2
                    fi
                    break
                fi
            done
        fi

        # 3. is it a commit id?
        if [[ "${target_type}" == "unknown" ]]; then
            target_type="commit"
            add_log "D" "No branch mathces target ${target_cid}, will take it as a commit id"
        fi

    fi

    add_log "I" "target_type: ${target_type}, actual_target: ${actual_target}"

    return 0
}

function upgrade_bk_old_mo() {
    add_log "I" "Back up mo path from ${MO_PATH}/matrixone to ${MO_UPGRADE_PATH}"
    add_log "D" "cmd:  mv ${MO_PATH}/matrixone ${MO_UPGRADE_PATH}"
    if mv ${MO_PATH}/matrixone ${MO_UPGRADE_PATH}; then
        #if ls -a ${MO_PATH}/matrixone/ | grep -vE "logs|^.$|^..$|mo-data|mo-service|mo-dump" | xargs -I{} cp -r ${MO_PATH}/matrixone/{} ${MO_UPGRADE_PATH}/ >/dev/null 2>&1; then
        add_log "I" "Succeeded"
    else
        add_log "E" "Failed, exiting"
        return 1
    fi
}

function upgrade_deploy_new_mo() {

    add_log "I" "Deploying new mo on target ${target_type} ${actual_target}"
    if ! deploy ${actual_target}; then
        add_log "E" "Failed, exiting"
        return 1
    fi
}

function upgrade_copy_conf_and_data() {

    add_log "I" "Backup new mo confs and copy confs from old mo to new mo"
    add_log "D" "cmd:  mv ${MO_PATH}/matrixone/etc ${MO_PATH}/matrixone/etc-default && cp -rp ${MO_UPGRADE_PATH}/etc ${MO_PATH}/matrixone/etc"
    mv ${MO_PATH}/matrixone/etc ${MO_PATH}/matrixone/etc-default && cp -rp ${MO_UPGRADE_PATH}/etc ${MO_PATH}/matrixone/etc

    if [[ -d ${MO_UPGRADE_PATH}/mo-data ]]; then
        add_log "I" "Copy mo-data from old mo to new mo"
        add_log "D" "cmd:  mv ${MO_UPGRADE_PATH}/mo-data ${MO_PATH}/matrixone/"
        mv ${MO_UPGRADE_PATH}/mo-data ${MO_PATH}/matrixone/
    else
        add_log "I" "${MO_UPGRADE_PATH}/mo-data does not exist, skipping moving it"
    fi

}

function upgrade_rollback() {
    add_log "E" "Rolling back upgrade action"
    add_log "D" "cmd:  mv ${MO_UPGRADE_PATH} ${MO_PATH}/matrixone"
    #action_type=`to_upper "${action_type}"`
    cd ${MO_PATH} && rm -rf ./matrixone
    mv "${MO_UPGRADE_PATH}" "${MO_PATH}/matrixone"
}

function upgrade_print_report() {
    target_branch=$(get_branch less)
    target_cid_full=$(get_cid)
    add_log "I" "Branch or tag before upgrade: ${current_branch}"
    add_log "I" "Branch or tag after upgrade: ${target_branch}"
    add_log "I" "--------------------------------"
    add_log "I" "Commit id before upgrade:"
    add_log "I" "${current_cid_full}" "l"
    add_log "I" "--------------------------------"
    add_log "I" "Commit id after upgrade:"
    add_log "I" "${target_cid_full}" "l"

}

function upgrade() {
    target_cid=$1

    if [[ "${MO_DEPLOY_MODE}" != "git" ]]; then
        add_log "E" "Currently upgrade is only supported when mo is deployed in git mode. Please check MO_DEPLOY_MODE again"
        return 1
    fi

    # 2. check pre-requisites
    if ! upgrade_check_pre_requisites; then
        return 1
    fi

    # 1. init vars
    if ! upgrade_init_vars; then
        add_log "E" "Upgrade failed, exiting"
        return 1
    fi

    # 2. validate target
    if ! upgrade_valid_target "${target_cid}"; then
        add_log "E" "Upgrade failed, exiting"
        return 1
    fi

    # 3. backup old mo
    if ! upgrade_bk_old_mo; then
        add_log "E" "Upgrade failed, exiting"
        return 1
    fi

    # 4. deploy new mo
    if ! upgrade_deploy_new_mo; then
        upgrade_rollback
        add_log "E" "Upgrade failed, exiting"
        return 1
    fi

    # 5. copy confs
    if ! upgrade_copy_conf_and_data; then
        upgrade_rollback
        add_log "E" "Upgrade failed, exiting"
        return 1
    fi

    # 6. print repot
    if ! upgrade_print_report; then
        add_log "E" "Upgrade failed, exiting"
    fi

    add_log "I" "Upgrade succeeded. Please use 'mo_ctl start' or 'mo_ctl restart' to restart your mo-service"

    return 0
}
