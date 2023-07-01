#!/bin/bash
# status

function status()
{
    p_info=`ps -ef |grep mo-service | grep -v grep`
    p_ids=`ps -ef |grep mo-service | grep -v grep | awk '{print $2}'`
    if [[ "${p_info}" != "" ]]; then
        add_log "INFO" "At least one mo-service is running. Process info: "
        add_log "INFO" "${p_info}"
        add_log "INFO" "Pids: "
        add_log "INFO" "${p_ids}"
    else
        add_log "INFO" "No mo-service is running"
        return 1
    fi
}
