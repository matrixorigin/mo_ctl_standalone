#!/bin/bash
# start

function start()
{
    if status; then
        add_log "INFO" "No need to start mo-service"
        add_log "INFO" "Start succeeded"
        return 0
    fi

    mkdir -p ${MO_LOG_PATH}
    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
    add_log "INFO" "Starting mo-service: cd ${MO_PATH}/matrixone/ && ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log"
    cd ${MO_PATH}/matrixone/ && ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log
    add_log "INFO" "Wait for ${START_INTERVAL} seconds"
    sleep ${START_INTERVAL}
    if status; then
        add_log "INFO" "Start succeeded"
    else
        add_log "ERROR" "Start failed"
        return 1
    fi
}