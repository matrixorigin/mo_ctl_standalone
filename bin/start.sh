#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# start

function start()
{
    if status; then
        add_log "I" "No need to start mo-service"
        add_log "I" "Start succeeded"
        return 0
    fi

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then

        dp_info=`docker ps -a --filter "name=${MO_CONTAINER_NAME}"`
        dp_name=`docker ps -a --filter "name=${MO_CONTAINER_NAME}" --format "table {{.Names}}" | tail -n 1`
        if [[ "${dp_name}" == "${MO_CONTAINER_NAME}" ]]; then
            add_log "I" "Container named ${MO_CONTAINER_NAME} found. Start mo container: docker start ${MO_CONTAINER_NAME}"
            docker start ${MO_CONTAINER_NAME}
        else
            # initial start
            docker_server_ver=`docker version --format='{{.Server.Version}}'`

            docker_init_cmd="docker run -d -p ${MO_DEBUG_PORT}:${MO_CONTAINER_DEBUG_PORT} -p ${MO_PORT}:${MO_CONTAINER_PORT} --name ${MO_CONTAINER_NAME}"

            # if docker_server_ver ≥ DOCKER_SERVER_VERSION, don't use privileged
            if ! cmp_version "${docker_server_ver}" "${DOCKER_SERVER_VERSION}"; then
                docker_init_cmd="${docker_init_cmd} --privileged=true"
            fi

            # if conf path exists
            if [[ -d ${MO_CONTAINER_CONF_HOST_PATH} ]]; then
                docker_init_cmd="${docker_init_cmd} -v ${MO_CONTAINER_CONF_HOST_PATH}:/etc:rw --entrypoint /mo-service ${MO_IMAGE_FULL} -launch ${MO_CONTAINER_CONF_CON_FILE}"
            else
                docker_init_cmd="${docker_init_cmd} ${MO_IMAGE_FULL}"
            fi

            add_log "I" "Initial start mo container: ${docker_init_cmd}"
            ${docker_init_cmd}
        fi
    else
        mkdir -p ${MO_LOG_PATH}
        RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
        add_log "I" "Starting mo-service: cd ${MO_PATH}/matrixone/ && ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log"
        cd ${MO_PATH}/matrixone/ && ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log
        add_log "I" "Wait for ${START_INTERVAL} seconds"
        sleep ${START_INTERVAL}
        if status; then
            add_log "I" "Start succeeded"
        else
            add_log "E" "Start failed"
            return 1
        fi
    fi
}