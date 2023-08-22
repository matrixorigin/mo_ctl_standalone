#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# status

function status()
{

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
        add_log "I" "Check if container named ${MO_CONTAINER_NAME} is running"
        dp_info=`docker ps --filter "name=${MO_CONTAINER_NAME}"`
        dp_name=`docker ps --filter "name=${MO_CONTAINER_NAME}" --format "table {{.Names}}" | tail -n 1`
        if [[ "${dp_name}" == "${MO_CONTAINER_NAME}" ]]; then
            add_log "I" "Info of: docker ps --filter name=${MO_CONTAINER_NAME}"
            echo "${dp_info}"
        else
            add_log "I" "No container named ${MO_CONTAINER_NAME} is running"
            return 1
        fi
    else
        p_info=`ps -ef |grep mo-service | grep -v grep`
        PIDS=`ps -ef |grep mo-service | grep -v grep | awk '{print $2}'`
        if [[ "${p_info}" != "" ]]; then
            add_log "I" "At least one mo-service is running. Process info: "
            echo "${p_info}"
            add_log "I" "List of pid(s): "
            echo "${PIDS}"
        else
            add_log "I" "No mo-service is running"
            return 1
        fi
    fi
}
