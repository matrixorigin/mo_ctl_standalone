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
    #commitid_full=`get_cid less | head -n 2 | tail -n 1`
    #commitid_less=`echo "${commitid_full:0:8}"`
    commitid_less=`get_cid less`


    #branch=`get_branch | grep "current branch" | awk -F "current branch: " '{print $2}'`
    branch=`get_branch less`


    add_log "D" "Commit id: ${commitid_less}, branch: ${branch}"

    if [[ "${commitid_less}" == "" ]] || [[ "${branch}" == "" ]]; then
        add_log "E" "Commit id or branch is empty, exiting"
        return 1
    fi

    add_log "I" "Build MO image ${image_name}:${branch}_${commitid_less}"

    cd ${MO_PATH}/matrixone && 
    
    if [[ "${MO_CONTAINER_DEPIMAGE_REPLACE_REPO}" == "yes" ]]; then
        add_log "D" "Repace repo for some images"
        
        add_log "D" "s#FROM golang:1.22.3-bookworm as builder#FROM ccr.ccs.tencentyun.com/mo-infra/golang:1.22.3-bookworm as builder#g' optools/images/Dockerfile"
        sed -i 's#FROM golang:1.22.3-bookworm as builder#FROM ccr.ccs.tencentyun.com/mo-infra/golang:1.22.3-bookworm as builder#g' optools/images/Dockerfile

        add_log "D" "s#FROM ubuntu:22.04#FROM ccr.ccs.tencentyun.com/mo-infra/ubuntu:22.04#g' optools/images/Dockerfile"
        sed -i 's#FROM ubuntu:22.04#FROM ccr.ccs.tencentyun.com/mo-infra/ubuntu:22.04#g' optools/images/Dockerfile
    fi

    if docker build -f optools/images/Dockerfile -t ${image_name}:${branch}_${commitid_less} . --build-arg GOPROXY="${GOPROXY}" ; then
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
