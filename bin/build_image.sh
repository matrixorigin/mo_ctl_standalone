#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# get_cid


function build_image()
{
    option=$1

    add_log "I" "Try to build an MO image. Related confs:"
    get_conf MO_PATH
    get_conf MO_BUILD_IMAGE_PATH
    get_conf GOPROXY


    if [[ ! -d ${MO_PATH}/matrixone ]]; then
        add_log "E" "Path ${MO_PATH}/matrixone does not exist, please make sure mo is deployed from source code"
        return 1
    fi

    if ! command -v docker >/dev/null 2>&1; then
        add_log "E" "Command docker is not found, please make sure docker command exists"
        return 1
    fi

    #if [[ "${GOPROXY}" != "" ]]; then
    #    add_log "D" "GOPROXY is set, setting go proxy to GOPROXY=${GOPROXY}"
    #    go env -w GOPROXY=${GOPROXY}
    #fi

    image_name="matrixone"
    commitid_full=`cd ${MO_PATH}/matrixone && git log | head -n 1 | awk {'print $2'}`
    commitid_less=`echo "${commitid_full:0:8}"`

    branch=`cd ${MO_PATH}/matrixone && git branch | grep "\*" | head -1`
    branch=`echo "${branch:2}"`

    add_log "D" "Commit id full: ${commitid_full}, commit id less: ${commitid_less}, branch: ${branch}"

    if [[ "${commitid_less}" == "" ]] || [[ "${branch}" == "" ]]; then
        add_log "E" "Commit id or branch is empty, exiting"
        return 1
    fi

    add_log "I" "Build MO image ${image_name}:${branch}_${commitid_less}"
    if cd ${MO_PATH}/matrixone && docker build -f optools/images/Dockerfile -t ${image_name}:${branch}_${commitid_less} . --build-arg GOPROXY="${GOPROXY}" ; then
        :
    else
        return 1
    fi

    mkdir -p ${MO_BUILD_IMAGE_PATH}
    add_log "I" "Saving ${image_name}:${branch}_${commitid_less} to file ${MO_BUILD_IMAGE_PATH}/${image_name}_${branch}_${commitid_less}.tar"
    if ! docker save ${image_name}:${branch}_${commitid_less} > ${MO_BUILD_IMAGE_PATH}/${image_name}_${branch}_${commitid_less}.tar; then
        return 1
    fi
}
