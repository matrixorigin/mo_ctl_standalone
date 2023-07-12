#!/bin/bash
# stop

function stop()
{
    force=$1
    kill_option=""
    if [[ "${force}" == "force" ]]; then
        kill_option="-9"
    fi
    max_times=10
    if status; then
        for ((i=1;i<=${max_times};i++)); do
            add_log "INFO" "Try stop all mo-services found for a maximum of ${max_times} times, try no: $i"
            for pid in ${p_ids}; do
                add_log "INFO" "Stopping mo-service with pid ${pid} with command: kill ${kill_option} ${pid}"
                if kill ${kill_option} ${pid}; then
                    add_log "INFO" "kill succeeded"
                else
                    add_log "ERROR" "kill fail"
                fi
            done
            add_log "INFO" "Wait for ${STOP_INTERVAL} seconds"
            sleep ${STOP_INTERVAL}
            if ! status; then
                add_log "INFO" "Stop succeeded"
                break;
            else
                if [[ "${i}" == "${max_times}" ]] ; then
                    add_log "ERRPR" "Stop failed after a maximum of ${max_times} times"
                    return 1
                else
                    add_log "ERROR" "Stop failed, will try again now"
                fi
            fi
        done

    else
        add_log "INFO" "No need to stop mo-service"
        add_log "INFO" "Stop succeeded"
    fi
}
