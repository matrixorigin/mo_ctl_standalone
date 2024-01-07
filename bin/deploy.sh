#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# deploy

function git_clone()
{
    # 1. git clone
    rc=0
    mo_version=$1
    force=$2

    try_times=10


    if [[ -d "${MO_PATH}/matrixone/" ]] && [[ "`ls ${MO_PATH}/matrixone/ | wc -l |sed 's/[[:space:]]//g'`" != "0" ]]; then
        if [[ "${force}" != "force" ]]; then
            add_log "I" "MO_PATH ${MO_PATH}/matrixone/ already exists and not empty, will skip git clone and check out"
            return 0
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
        add_log "I" "cd ${MO_PATH} && git clone ${MO_GIT_URL}"
        if [[ "${MO_GIT_URL}" == "" ]]; then
            add_log "E" "MO_GIT_URL is not set, please set it first, exiting"
            return 1
        fi
        if cd ${MO_PATH} && git clone ${MO_GIT_URL};then
            add_log "I" "Git clone succeeded."
            add_log "I" "checking out to version ${mo_version}"
            if cd ${MO_PATH}/matrixone/ && git checkout ${mo_version}; then
                add_log "I" "Check out succeeded."
            else
                add_log "E" "Check out failed, please check mo version, exiting"
                rc="1"                     
            fi
            # git clone ok, breaking the loop
            break;
        fi

        if [[ "${rc}" == "1" ]] ;then
            # checkout failed, breaking the loop
            break;
        fi
    done

    if [[ "${rc}" == "1" ]] ;then
        add_log "E" "All tries on git clone have failed. Exiting"
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
            add_log "E" "File does not exist or is not set"
            rc=1
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

    add_log "I" "Pulling image ${MO_CONTAINER_IMAGE}"
    if ! docker pull ${MO_CONTAINER_IMAGE}; then
        add_log "E" "Failed to pull docker image, please check if ${MO_CONTAINER_IMAGE} is a correct image or it might be a network issue"
        return 1
    fi

    add_log "I" "Successfully pulled image ${MO_CONTAINER_IMAGE}"
}

function deploy()
{
    mo_version=$1
    force=$2

    # set default version
    if [[ ${mo_version} == "" ]]; then 
        mo_version=${MO_DEFAULT_VERSION}
    elif [[ ${mo_version} == "force" ]]; then
        mo_version=${MO_DEFAULT_VERSION}
        force="force"
    fi

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
        deploy_docker ${mo_version}
    else
        # 0. Precheck
        if ! precheck; then
            add_log "I" "Precheck failed, exiting"
            return 1
        else
            add_log "I" "Precheck passed, deploying mo now"
        fi

        # 1. Install
        if ! git_clone ${mo_version} ${force}; then
            return 1
        fi

        # 2. Build
        if [[ "${force}" == "nobuild" ]]; then
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

    fi

}