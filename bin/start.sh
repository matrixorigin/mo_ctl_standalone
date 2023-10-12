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

    total_mem=`get_mem_mb`

    add_log "D" "Check total memory on current machine, command: free -m | awk 'NR==2{print $2}', result(Mi): ${total_mem}"
    docker_mem_limit=""
    go_mem_limit=""
    

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then

        dp_info=`docker ps -a --filter "name=${MO_CONTAINER_NAME}"`
        dp_name=`docker ps -a --filter "name=${MO_CONTAINER_NAME}" --format "table {{.Names}}" | tail -n 1`
        if [[ "${dp_name}" == "${MO_CONTAINER_NAME}" ]]; then
            add_log "I" "Container named ${MO_CONTAINER_NAME} found. Start mo container: docker start ${MO_CONTAINER_NAME}"
            docker start ${MO_CONTAINER_NAME}
        else
            # initial start
            docker_server_ver=`docker version --format='{{.Server.Version}}'`
            
            # host data path
            mkdir -p ${MO_CONTAINER_DATA_HOST_PATH}
            
            cmd_params="-d  -v ${MO_CONTAINER_DATA_HOST_PATH}:/mo-data:rw -p ${MO_DEBUG_PORT}:${MO_CONTAINER_DEBUG_PORT} -p ${MO_PORT}:${MO_CONTAINER_PORT} --name ${MO_CONTAINER_NAME}"
            docker_init_cmd="docker run"

            if [[ "${total_mem}" != "" ]]; then
                let docker_mem_limit=total_mem*${MO_CONTAINER_MEMORY_RATIO}/100
                let go_mem_limit=docker_mem_limit*${GO_MEM_LIMIT_RATIO}/100
                add_log "D" "Docker memory limit(Mi): ${docker_mem_limit}, GO memory limit(Mi): ${go_mem_limit}"
            fi

            if [[ "${docker_mem_limit}" == "" ]]; then
                add_log "W" "Docker memory limit seems to be empty, thus will not set this limit"
            else
                add_log "D" "Start command will add: --memory ${docker_mem_limit}m"
                cmd_params="${cmd_params} --memory ${docker_mem_limit}m"
            fi

            if [[ "${go_mem_limit}" == "" ]]; then
                add_log "W" "GO memory limit seems to be empty, thus will not set this limit"
            else
                add_log "D" "Start command will add: --env GOMEMLIMIT=${go_mem_limit}MiB"
                cmd_params="${cmd_params} --env GOMEMLIMIT=${go_mem_limit}MiB"
            fi

            # get hostname
            this_hostname=`hostname`
            if [[ "${this_hostname}" == "" ]]; then 
                add_log "W" "Failed to get hostname, will use default value: MO_CONTAINER_HOSTNAME=${MO_CONTAINER_HOSTNAME}"
                cmd_params="${cmd_params} --hostname ${MO_CONTAINER_HOSTNAME}"
            else
                add_log "D" "Get hostname of host: ${this_hostname}"
                add_log "D" "Setting conf container hostname: MO_CONTAINER_HOSTNAME=${this_hostname}"
                set_conf MO_CONTAINER_HOSTNAME=${this_hostname}
                cmd_params="${cmd_params} --hostname ${this_hostname}"
            fi
            

            # if docker_server_ver ≥ DOCKER_SERVER_VERSION, don't use privileged
            if ! cmp_version "${docker_server_ver}" "${DOCKER_SERVER_VERSION}"; then
                #docker_init_cmd="${docker_init_cmd} --privileged=true"
                cmd_params="${cmd_params} --privileged=true"
            fi

            # if conf path exists
            if [[ -d ${MO_CONTAINER_CONF_HOST_PATH} ]]; then
                docker_init_cmd="docker run ${cmd_params} -v ${MO_CONTAINER_CONF_HOST_PATH}:/etc:rw --entrypoint /mo-service ${MO_IMAGE_FULL} -launch ${MO_CONTAINER_CONF_CON_FILE}"
            else
                docker_init_cmd="docker run ${cmd_params} ${MO_IMAGE_FULL}"              
            fi

            #docker_init_cmd="${docker_init_cmd} --hostname ${MO_CONTAINER_HOSTNAME}  -v ${MO_CONTAINER_DATA_HOST_PATH}:/mo-data:rw -v ${MO_CONTAINER_CONF_HOST_PATH}:/etc:rw --entrypoint /mo-service ${MO_IMAGE_FULL} -launch ${MO_CONTAINER_CONF_CON_FILE}"


            add_log "I" "Initial start mo container: ${docker_init_cmd}"
            ${docker_init_cmd}
        fi
    else
        mkdir -p ${MO_LOG_PATH}
        RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
        
        if [[ "${total_mem}" != "" ]]; then
            let go_mem_limit=total_mem*${GO_MEM_LIMIT_RATIO}/100
            add_log "I" "GO memory limit(Mi): ${go_mem_limit}"
        fi

        if [[ "${go_mem_limit}" == "" ]]; then
            add_log "W" "GO memory limit seems to be empty, thus will not set this limit"
            add_log "I" "Starting mo-service: cd ${MO_PATH}/matrixone/ && ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log"
            cd ${MO_PATH}/matrixone/ && ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log
        else
            add_log "I" "Start command will add GOMEMLIMIT=${go_mem_limit}MiB"
            add_log "I" "Starting mo-service: cd ${MO_PATH}/matrixone/ && GOMEMLIMIT=${go_mem_limit}MiB ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log"
            cd ${MO_PATH}/matrixone/ && GOMEMLIMIT=${go_mem_limit}MiB ${MO_PATH}/matrixone/mo-service -daemon -debug-http :${MO_DEBUG_PORT} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log
        fi
        
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