#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# precheck

function precheck()
{
    rc=0
    list_nok=""

    for item in ${CHECK_LIST[@]}; do
        add_log "I" "Precheck on pre-requisite: ${item}"

        if [[ "${item}" == "docker" ]]; then
            # ignore docker in case deploy mode is not docker
            if [[ "${MO_DEPLOY_MODE}" != "docker" ]]; then
                add_log "I" "Conf MO_DEPLOY_MODE is set to '${MO_DEPLOY_MODE}', ignoring docker"
                continue
            fi
        fi

        # 1. check if installed
        if ! which ${item} >/dev/null 2>&1; then



            add_log "E" "Nok. Please check if it is installed or exists in your \$PATH env"
            list_nok="$item ${list_nok}"
            rc=1
            continue
        else
            add_log "I" "Ok. ${item} is installed"
        fi

        # 2. check version
        case ${item} in
            "gcc")
                os=`what_os`
                if [[ "${os}" == "Mac" ]]; then
                    version_current=`gcc --version | head -n 1 | awk -F"Apple clang version "  '{print $2}' | awk '{print $1}' | sed 's/[[:space:]]//g'`
                    version_required="${CLANG_VERSION}"
                else
                    version_current=`gcc --version | head -n 1 | awk -F'[)] ' '{print $2}' | awk '{print $1}'`
                    version_required="${GCC_VERSION}"
                fi
    
                ;;
            "go")
                version_current=`go version | head -1 |  awk '{print $3}' | sed "s#go##g"`
                version_required="${GO_VERSION}"
                ;;
            *)
                continue
                ;;
        esac

        add_log "I" "Version check on ${item}. Current: ${version_current}, required: ${version_required}" 

        if cmp_version ${version_current} ${version_required}; then
           add_log "I" "Ok. ${item} version is greater than or equal to required"
        else
            add_log "W" "Nok. Please upgrade ${item} version to minimum required"
            list_nok="$item ${list_nok}"
            rc=1
        fi

    done

    if [[ "${rc}" == "0" ]]; then
        add_log "I" "All pre-requisites are ok"

    else
        add_log "E" "At least one pre-requisite is not ok, list: ${list_nok}"

    fi

    return ${rc}
}