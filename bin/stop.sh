#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# stop

function stop()
{
    force=$1
    kill_option=""
    if [[ "${force}" == "force" ]]; then
        kill_option="-9"
    fi
    max_times=10
    # get PIDS
    if status; then
        for ((i=1;i<=${max_times};i++)); do
            add_log "I" "Try stop all mo-services found for a maximum of ${max_times} times, try no: $i"
            for pid in ${PIDS}; do
                add_log "I" "Stopping mo-service with pid ${pid} with command: kill ${kill_option} ${pid}"
                if kill ${kill_option} ${pid}; then
                    add_log "I" "kill succeeded"
                else
                    add_log "E" "kill fail"
                fi
            done
            add_log "I" "Wait for ${STOP_INTERVAL} seconds"
            sleep ${STOP_INTERVAL}
            if ! status; then
                add_log "I" "Stop succeeded"
                break;
            else
                if [[ "${i}" == "${max_times}" ]] ; then
                    add_log "E" "Stop failed after a maximum of ${max_times} times"
                    return 1
                else
                    add_log "E" "Stop failed, will try again now"
                fi
            fi
        done

    else
        add_log "I" "No need to stop mo-service"
        add_log "I" "Stop succeeded"
    fi
}
