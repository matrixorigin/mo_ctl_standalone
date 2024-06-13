#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# deploy

function git_clone()
{
    rc=1
    # 1. git clone

    mo_version=$1
    force=$2

    try_times=10


    if [[ -d "${MO_PATH}/matrixone/" ]] && [[ "`ls ${MO_PATH}/matrixone/ | wc -l |sed 's/[[:space:]]//g'`" != "0" ]]; then
        if [[ "${force}" != "force" ]]; then
            add_log "E" "MO_PATH ${MO_PATH}/matrixone/ already exists and not empty, please add flag \"force\" and try again, or remove it manually, exiting"
            return 1
        else
            add_log "W" "MO_PATH ${MO_PATH}/matrixone/ already exists and not empty, please confirm if you really want to overwrite it(Yes/No): "
            user_confirm=""
            read -t 30 user_confirm
            if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
                add_log "E" "User input not confirmed or timed out, exiting"
                return 1
            fi
        fi
    fi 

    if [[ "${MO_PATH}" != "" ]] ; then
        cd ${MO_PATH} >/dev/null 2>&1 && rm -rf ./matrixone/ >/dev/null 2>&1
    fi



    mkdir -p ${MO_PATH}
    add_log "I" "Deploying mo on path ${MO_PATH}"
    for ((i=1;i<=${try_times};i++));do
        add_log "I" "Try number: $i"
        if [[ "${MO_GIT_URL}" == "" ]]; then
            add_log "E" "MO_GIT_URL is not set, please set it first, exiting"
            return 1
        fi
        add_log "I" "cd ${MO_PATH} && git clone ${MO_GIT_URL}"
        if cd ${MO_PATH} && git clone ${MO_GIT_URL}; then
            add_log "I" "Git clone source codes succeeded, judging if checkout is needed"
            add_log "D" "cmd: cd ${MO_PATH}/matrixone/"
            cd ${MO_PATH}/matrixone/
            if [[ "${mo_version}" == "main" ]]; then
                add_log "I" "mo_version is set to main, skip checkout"
                rc=0
            else
                remote_tags=`git tag`
                remote_branches=`git branch -r | awk -F'origin/' '{print $2}' | grep -v HEAD`
                add_log "I" "Trying to checkout to ${mo_version}"
                add_log "D" "List of remote tags:"
                add_log "D" "${remote_tags}" "l"
                add_log "D" "List of remote branches:"
                add_log "D" "${remote_branches}" "l"
                # set default version, use latest tag
                if [[ ${mo_version} == "" ]]; then
                    add_log "I" "mo_version is empty, trying to find the tag for latest release"
                    mo_version=`for tags in ${remote_tags} ; do echo $tags; done |sort -r | head -1`
                    mo_v_type="tag"
                else
                    mo_v_type="unknown"
                    # 1. is it a tag?
                    for tag in ${remote_tags}; do
                        if [[ "${tag}" == "${mo_version}" ]]; then
                            mo_v_type="tag"
                            add_log "D" "Tag ${tag} mathces mo_version ${mo_version}"
                            break
                        fi
                    done

                    # 2. is it a branch?
                    if [[ "${mo_v_type}" == "unknown" ]]; then
                        add_log "D" "No tag mathces mo_version ${mo_version}, trying to match a branch"
                        for branch in ${remote_branches}; do
                            if [[ "${branch}" == "${mo_version}" ]]; then
                                mo_v_type="branch"
                                add_log "D" "Branch ${branch} mathces mo_version ${mo_version}"
                                break
                            fi
                        done
                    fi

                    # 3. is it a commit id?
                    if [[ "${mo_v_type}" == "unknown" ]]; then
                        mo_v_type="commit"
                        add_log "D" "No branch mathces mo_version ${mo_version}, will take it as a commit id"

                    fi

                fi

                add_log "I" "mo_version: ${mo_version}, type: ${mo_v_type}"
                if ! git checkout ${mo_version}; then
                    add_log "E" "Check out to ${mo_version} failed, please make sure it's a valid ${mo_v_type}, exiting"
                    rc=1
                    break;
                fi
            fi
            # git clone and checkout all ok, breaking the loop
            rc=0
            break;
        fi

    done

    if [[ "${rc}" == "1" ]] ;then
        add_log "E" "All tries on git clone or a checkout have failed. Exiting"
    fi

    return ${rc}


}


function build_mo_service()
{
    # mo-service
    add_log "I" "Try to build mo-service: make build"
    if cd ${MO_PATH}/matrixone/ && make build ; then
        add_log "I" "Build succeeded"
    else
        add_log "E" "Build failed"
        return 1
    fi


}

function build_mo_dump()
{
    add_log "I" "Try to build mo-dump: make cgo && make modump"
    #if cd ${MO_PATH}/matrixone/ && make build modump; then
    if cd ${MO_PATH}/matrixone/ && make cgo && make modump; then
        add_log "I" "Build succeeded"
    else
        add_log "E" "Build failed"
        return 1
    fi
}


function build_all()
{
    force=$1

    if [[ "${GOPROXY}" != "" ]]; then
        add_log "I" "GOPROXY is set, setting go proxy to GOPROXY=${GOPROXY}"
        go env -w GOPROXY=${GOPROXY}
    fi

    if [[ "${force}" == "force" ]]; then
        build_mo_service
        #build_mo_dump
    else
        if [[ -f "${MO_PATH}/matrixone/mo-service" ]]; then
            add_log "I" "mo-service is already built on ${MO_PATH}, no need to build"
        else
            build_mo_service
        fi

        #if [[ -f "${MO_PATH}/matrixone/mo-dump" ]]; then
        #    add_log "I" "mo-dump is already built on ${MO_PATH}, no need to build"
        #else
        #    build_mo_dump
        #fi
    fi
}

function replace_mo_confs()
{
    add_log "I" "Setting mo conf file"
    CONF_FILE_NAME_LIST=("cn.toml" "tn.toml" "log.toml")

    rc=0
    for conf_file_name in ${CONF_FILE_NAME_LIST[*]}; do
        add_log "I" "Conf source path MO_CONF_SRC_PATH: ${MO_CONF_SRC_PATH}, file name: ${conf_file_name}"
        if [[ ! -f "${MO_CONF_SRC_PATH}/${conf_file_name}" ]]; then
            add_log "W" "File does not exist or is not set, skipping"
        else
            add_log "D" "Copy conf file: cp -f ${MO_CONF_SRC_PATH}/${conf_file_name} ${MO_PATH}/matrixone/etc/launch/${conf_file_name}"
            if ! cp ${MO_CONF_SRC_PATH}/${conf_file_name} ${MO_PATH}/matrixone/etc/launch/${conf_file_name}; then
                add_log "E" "Failed to copy conf file"
                rc=1
            fi
        fi
    done

    return ${rc}

}

function deploy_docker()
{
    mo_version=$1

    add_log "I" "MO deploy mode is set to docker, checking docker status: systemctl status docker && systemctl status dockerd"
    os=`what_os`
    if [[ "${os}" == "Linux" ]]; then
        if systemctl status docker >/dev/null 2>&1 || systemctl status dockerd >/dev/null 2>&1 ; then
            add_log "I" "Docker or dockerd seems to be running normally"
        else
            add_log "E" "It seems docker is not running normally, please try restart it via 'systemctl restart docker'"
            return 1
        fi
    else
        if ! docker info >/dev/null 2>&1; then
            add_log "E" "It seems docker is not running normally, please try restart it via 'open -a Docker'"
            return 1
        fi
    fi

    #cid=`get_stable_cid ${mo_version}`

    #if [[ "${mo_version}" == "main" ]]; then
    #    MO_CONTAINER_IMAGE="${MO_REPO}:latest"
    #elif [[ "${mo_version}" != "${cid}" ]]; then
    #    MO_CONTAINER_IMAGE="${MO_REPO}:${mo_version}"
    #else
        #MO_CONTAINER_IMAGE="${MO_REPO}:${MO_IMAGE_PREFIX}-${mo_version}"
    #    MO_CONTAINER_IMAGE="${MO_REPO}:${mo_version}"
    #fi

    #set_conf MO_CONTAINER_IMAGE="${MO_CONTAINER_IMAGE}"

    if [[ "${MO_CONTAINER_IMAGE}" == "" ]]; then
        add_log "E" "conf MO_CONTAINER_IMAGE is empty, please set it first"
    fi
    
    # 2024/4/2: deprecated as we don't pull image manually
    #add_log "I" "Pulling image ${MO_CONTAINER_IMAGE}"
    #if ! docker pull ${MO_CONTAINER_IMAGE}; then
    #    add_log "E" "Failed to pull docker image, please check if ${MO_CONTAINER_IMAGE} is a correct image or it might be a network issue"
    #    return 1
    #fi

    #add_log "I" "Successfully pulled image ${MO_CONTAINER_IMAGE}"
}

# possible options
# 1. mo_ctl deploy: deploy default version, i.e. mo_ctl deploy ${latest_stable_version}, where ${latest_stable_version} is decided from git tag result
# 2. mo_ctl deploy force
# 3. mo_ctl deploy nobuild
# 4. mo_ctl deploy force nobuild


# 5. mo_ctl deploy v1.1.3: deploy a stable version(tag)
# 6. mo_ctl deploy v1.1.3 force
# 7. mo_ctl deploy v1.1.3 nobuild
# 8. mo_ctl deploy v1.1.3 force nobuild


# 9. mo_ctl deploy main: deploy main branch latest version
# 10. mo_ctl deploy main force
# 11. mo_ctl deploy main nobuild
# 12. mo_ctl deploy main force nobuild

# 13. mo_ctl deploy xxxxxx: deploy xxxx commit id
# 14. mo_ctl deploy xxxxxx force
# 13. mo_ctl deploy xxxxxx nobuild
# 14. mo_ctl deploy xxxxxx force nobuild

function deploy()
{

    var_1="$1"
    var_2="$2"
    var_3="$3"

    mo_version=""
    force=""
    nobuild=""

    case "${var_1}" in
        "")
            # 1. mo_ctl deploy
            mo_version=""
            force=""
            nobuild=""
            ;;
        "nobuild")
            # 3. mo_ctl deploy nobuild
            mo_version=""
            force=""
            nobuild="nobuild"
            ;;
        "force")
            # 2. mo_ctl deploy force
            # 4. mo_ctl deploy force nobuild
            mo_version=""
            force="force"
            nobuild="${var_3}"
            ;;
        *)
            # 5. mo_ctl deploy v1.1.3: deploy a stable version(tag)
            # 6. mo_ctl deploy v1.1.3 force
            # 7. mo_ctl deploy v1.1.3 nobuild
            # 8. mo_ctl deploy v1.1.3 force nobuild


            # 9. mo_ctl deploy main: deploy main branch latest version
            # 10. mo_ctl deploy main force
            # 11. mo_ctl deploy main nobuild
            # 12. mo_ctl deploy main force nobuild

            # 13. mo_ctl deploy xxxxxx: deploy xxxx commit id
            # 14. mo_ctl deploy xxxxxx force
            # 13. mo_ctl deploy xxxxxx nobuild
            # 14. mo_ctl deploy xxxxxx force nobuild
            mo_version="${var_1}"
            force="${var_2}"
            if [[ "${force}" == "nobuild" ]]; then
                force=""
                nobuild="nobuild"
            else
                nobuild="${var_3}"
            fi
            ;;
    esac

    add_log "D" "mo_version: ${mo_version}, force: ${force}, nobuild: ${nobuild}" 

    get_conf MO_DEPLOY_MODE

    case "${MO_DEPLOY_MODE}" in
        "docker")
            deploy_docker ${mo_version}
            ;;
        "binary")
            add_log "I" "MO_DEPLOY_MODE is set to 'binary', thus skipping deployment. Please download and decompress mo binary file into a folder and set conf MO_PATH and MO_CONF_FILE, exiting"
            return 0
            ;;

        "git")
            # 0. Precheck
            if ! precheck; then
                add_log "I" "Precheck failed, exiting"
                return 1
            else
                add_log "I" "Precheck passed, deploying mo now"
            fi

            # 1. Git clone source codes and checkout to branch/tag/commit
            if ! git_clone "${mo_version}" "${force}"; then
                return 1
            fi

            # 2. Build
            if [[ "${nobuild}" == "nobuild" ]]; then
                add_log "W" "Flag \"nobuild\" is set, will skip building mo-service"
                :
            else
                if ! build_all ${force}; then
                    return 1
                fi
            fi

            # 3. Create logs folder
            add_log "I" "Creating mo logs ${MO_LOG_PATH} path in case it does not exist"
            mkdir -p ${MO_LOG_PATH}
            add_log "I" "Deoloy succeeded"

            # 4. Copy conf file
            replace_mo_confs

            ;;
        *)
            add_log "E" "Invalid MO_DEPLOY_MODE, choose from: git | binary | docker"
            exit 1
            ;;
    esac

}