#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# pprof

function pprof() {
    option=$1

    duration="$2"
    DEFAULT_OPION="cpu"
    DEFAULT_DURATION=30
    if [[ ! -d "${PPROF_OUT_PATH}" ]]; then
        add_log "E" "Directory PPROF_OUT_PATH=${PPROF_OUT_PATH} does not exist, please check again"
        return 1
    fi

    if [[ "${option}" == "" ]]; then
        add_log "I" "Option is not set, using default value: ${DEFAULT_OPION}"
        option="${DEFAULT_OPION}"

    fi

    if [[ "${option}" == "cpu" ]]; then
        option="profile"
    fi

    MAX_DURATION=3600
    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
    OUT_FILE="${PPROF_OUT_PATH}/${option}-${RUN_TAG}.pprof"
    URL="http://${MO_HOST}:${MO_DEBUG_PORT}/debug/pprof/${option}"
    URL_2="http://${MO_HOST}:${MO_DEBUG_PORT}/debug/${option}"

    add_log "I" "pprof option is ${option}"

    case "${option}" in
        "profile" | "trace")
            if [[ "${duration}" == "" ]]; then
                add_log "I" "duration is not set, using conf value: ${PPROF_PROFILE_DURATION}"
                duration="${PPROF_PROFILE_DURATION}"
                if [[ "${duration}" == "" ]]; then
                    add_log "I" "conf value PPROF_PROFILE_DURATION is not set, using default value ${DEFAULT_DURATION}"
                    duration=${DEFAULT_DURATION}
                fi
            fi

            if ! pos_int_range ${duration} ${MAX_DURATION}; then
                add_log "E" "duration ${PPROF_PROFILE_DURATION} is not a valid positive integer or it's larger than ${MAX_DURATION}"
                return 1
            fi

            URL="${URL}?seconds=${duration}"
            add_log "I" "collect duration is ${duration} seconds"
            ;;
        "allocs" | "heap" | "goroutine")
            :
            ;;
        "malloc")
            URL="${URL_2}"
            ;;
        *)
            add_log "E" "Invalid option ${option} for pprof. Available: cpu | trace | allocs | heap | goroutine | malloc"
            help_pprof
            exit 1
            ;;
    esac

    if ! status; then
        add_log "E" "No mo-service is running mo this machine, thus will not run pprof, exiting"
        return 1
    fi

    add_log "I" "Try get pprof with command: curl -o ${OUT_FILE} ${URL}"
    if curl -o ${OUT_FILE} ${URL}; then
        add_log "I" "Get pprof succeeded. Please check result file: ${OUT_FILE}"
    else
        add_log "E" "Get pprof failed. Check if mo-service is running or debug port is correct or startup command with -debug-http option"
        return 1
    fi
}
