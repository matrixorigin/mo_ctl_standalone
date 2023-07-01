#!/bin/bash
# precheck

function precheck()
{
    rc=0
    list_nok=""

    for item in ${CHECK_LIST[@]}; do
        add_log "INFO" "Precheck on pre-requisite: ${item}"
        
        # 1. check if installed
        if ! which ${item} >/dev/null 2>&1; then
            add_log "ERROR" "Nok. Please check if it is installed or exists in your \$PATH env"
            list_nok="$item ${list_nok}"
            rc=1
            continue
        else
            add_log "INFO" "Ok. ${item} is installed"
        fi

        # 2. check version
        case ${item} in
            "gcc")
                version_current=`gcc --version | head -1 | awk -F'[)] ' '{print $2}' | awk '{print $1}'`
                version_required="${GCC_VERSION}"
    
                ;;
            "go")
                version_current=`go version | head -1 |  awk '{print $3}' | sed "s#go##g"`
                version_required="${GO_VERSION}"
                ;;
            *)
                continue
                ;;
        esac

        add_log "INFO" "Version check on ${item}. Current: ${version_current}, required: ${version_required}" 

        if cmp_version ${version_current} ${version_required}; then
           add_log "INFO" "Ok. ${item} version is greater than or equal to required"
        else
            add_log "WARN" "Nok. Please upgrade ${item} version to minimum required"
            list_nok="$item ${list_nok}"
            rc=1
        fi

    done

    if [[ "${rc}" == "0" ]]; then
        add_log "INFO" "All pre-requisites are ok"

    else
        add_log "INFO" "At least one pre-requisite is not ok, list: ${list_nok}"

    fi

    return ${rc}
}