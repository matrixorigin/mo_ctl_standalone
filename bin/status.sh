#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# status

function status()
{
    p_info=`ps -ef |grep mo-service | grep -v grep`
    p_ids=`ps -ef |grep mo-service | grep -v grep | awk '{print $2}'`
    if [[ "${p_info}" != "" ]]; then
        add_log "I" "At least one mo-service is running. Process info: "
        echo "${p_info}"
        add_log "I" "List of pid(s): "
        echo "${p_ids}"
    else
        add_log "I" "No mo-service is running"
        return 1
    fi
}
