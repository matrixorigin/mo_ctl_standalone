#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# start

function start() {
    if status; then
        add_log "I" "No need to start mo-service"
        add_log "I" "Start succeeded"
        return 0
    fi

    total_mem=$(get_mem_mb)

    add_log "D" "Check total memory on current machine, command: free -m | awk 'NR==2{print $2}', result(Mi): ${total_mem}"
    docker_mem_limit="${MO_CONTAINER_LIMIT_MEMORY}"
    go_mem_limit=""

    get_conf MO_DEPLOY_MODE
    get_conf DAEMON_METHOD

    if [[ "${MO_DEPLOY_MODE}" == "docker" ]]; then
        start_docker
    else
        mkdir -p ${MO_LOG_PATH}
        RUN_TAG="$(date "+%Y%m%d_%H%M%S")"

        if [[ "${total_mem}" != "" ]]; then
            let go_mem_limit=total_mem*${GO_MEM_LIMIT_RATIO}/100
            add_log "I" "GO memory limit(Mi): ${go_mem_limit}"
        fi

        if [[ "${MO_DEPLOY_MODE}" == "git" ]]; then
            mo_actual_path="${MO_PATH}/matrixone"
        elif [[ "${MO_DEPLOY_MODE}" == "binary" ]]; then
            mo_actual_path="${MO_PATH}"
        else
            add_log "E" "Invalid MO_DEPLOY_MODE, choose from: git | binary | docker"
            exit 1
        fi

        debug_option=""
        if [[ "${MO_DEBUG_PORT}" != "" ]]; then
            debug_option="-debug-http :${MO_DEBUG_PORT}"
        fi

        pprof_option=""
        if [[ "${PPROF_INTERVAL}" != "" ]]; then
            pprof_option="-profile-interval ${PPROF_INTERVAL}s"
        fi

        if [[ "${DAEMON_METHOD}" == "systemd" ]]; then
            start_systemd
        else
            start_process
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

# 启动 docker 容器
function start_docker() {
    dp_info=$(docker ps -a --filter "name=${MO_CONTAINER_NAME}")
    dp_name=$(docker ps -a --filter "name=${MO_CONTAINER_NAME}" --format "table {{.Names}}" | tail -n 1)
    if [[ "${dp_name}" == "${MO_CONTAINER_NAME}" ]]; then
        add_log "I" "Container named ${MO_CONTAINER_NAME} found. Start mo container: docker start ${MO_CONTAINER_NAME}"
        docker start ${MO_CONTAINER_NAME}
    else
        # initial start
        docker_server_ver=$(docker version --format='{{.Server.Version}}')

        # host data path
        mkdir -p ${MO_CONTAINER_DATA_HOST_PATH}

        if [[ "${MO_CONTAINER_EXTRA_MOUNT_OPTION}" != "" ]]; then
            cmd_params="-d -v ${MO_CONTAINER_EXTRA_MOUNT_OPTION} -v ${MO_CONTAINER_DATA_HOST_PATH}:/mo-data:rw -p ${MO_DEBUG_PORT}:${MO_CONTAINER_DEBUG_PORT} -p ${MO_PORT}:${MO_CONTAINER_PORT} --name ${MO_CONTAINER_NAME}"
        else
            cmd_params="-d  -v ${MO_CONTAINER_DATA_HOST_PATH}:/mo-data:rw -p ${MO_DEBUG_PORT}:${MO_CONTAINER_DEBUG_PORT} -p ${MO_PORT}:${MO_CONTAINER_PORT} --name ${MO_CONTAINER_NAME}"
        fi

        docker_init_cmd="docker run"

        # memory limit
        if [[ "${total_mem}" != "" ]]; then
            if [[ "${docker_mem_limit}" == "" ]]; then
                add_log "D" "Conf MO_CONTAINER_LIMIT_MEMORY is empty, will set docker memory limit as ${MO_CONTAINER_MEMORY_RATIO}% of total memory"
                let docker_mem_limit=total_mem*${MO_CONTAINER_MEMORY_RATIO}/100
            else
                add_log "D" "Will set docker memory limit as conf MO_CONTAINER_LIMIT_MEMORY value"
            fi
            let go_mem_limit=docker_mem_limit*${GO_MEM_LIMIT_RATIO}/100
            add_log "D" "Docker memory limit(Mi): ${docker_mem_limit}, GO memory limit(Mi): ${go_mem_limit}"
        fi

        if [[ "${docker_mem_limit}" == "" ]]; then
            add_log "W" "Docker memory limit seems to be empty, thus will not set this limit"
        else
            add_log "D" "Start command will add: --memory=${docker_mem_limit}m"
            cmd_params="${cmd_params} --memory=${docker_mem_limit}m"
        fi

        if [[ "${go_mem_limit}" == "" ]]; then
            add_log "W" "GO memory limit seems to be empty, thus will not set this limit"
        else
            add_log "D" "Start command will add: --env GOMEMLIMIT=${go_mem_limit}MiB"
            cmd_params="${cmd_params} --env GOMEMLIMIT=${go_mem_limit}MiB"
        fi

        # cpu limit
        if [[ "${MO_CONTAINER_LIMIT_CPU}" != "" ]]; then
            total_cpu_cores=$(get_cpu_cores)
            add_log "D" "Conf MO_CONTAINER_LIMIT_CPU is set as ${MO_CONTAINER_LIMIT_CPU}, total cpu cores: ${total_cpu_cores}"
            if pos_int_range ${MO_CONTAINER_LIMIT_CPU} ${total_cpu_cores}; then
                add_log "D" "Start command will add: --cpus=${MO_CONTAINER_LIMIT_CPU}"
                cmd_params="${cmd_params} --cpus=${MO_CONTAINER_LIMIT_CPU}"
            else
                add_log "W" "Conf MO_CONTAINER_LIMIT_CPU is not a valid positive integer or greater than total cpu cores, ignoring this conf"
            fi
        fi

        # auto restart
        auto_restart=$(to_lower "${MO_CONTAINER_AUTO_RESTART}")
        if [[ "${auto_restart}" == "yes" ]]; then
            add_log "D" "Start command will add: --restart=always"
            cmd_params="${cmd_params} --restart=always"
        fi

        # get hostname
        add_log "D" "Get hostname conf MO_CONTAINER_HOSTNAME: ${MO_CONTAINER_HOSTNAME}"
        if [[ "${MO_CONTAINER_HOSTNAME}" == "" ]]; then
            real_hostname=$(hostname)
            add_log "W" "Failed to get hostname, will use default value: MO_CONTAINER_HOSTNAME=${real_hostname}"
            MO_CONTAINER_HOSTNAME="${real_hostname}"
        fi

        cmd_params="${cmd_params} --hostname ${MO_CONTAINER_HOSTNAME}"

        # if docker_server_ver ≥ DOCKER_SERVER_VERSION, don't use privileged
        if ! cmp_version "${docker_server_ver}" "${DOCKER_SERVER_VERSION}"; then
            cmd_params="${cmd_params} --privileged=true"
        fi

        if [[ "${MO_CONTAINER_TIMEZONE}" == "host" ]]; then
            cmd_params="${cmd_params} -v /etc/localtime:/etc/localtime"
        fi

        debug_option=""
        if [[ "${MO_DEBUG_PORT}" != "" ]]; then
            debug_option="-debug-http :${MO_DEBUG_PORT}"
        fi

        pprof_option=""
        if [[ "${PPROF_INTERVAL}" != "" ]]; then
            pprof_option="-profile-interval ${PPROF_INTERVAL}s"
        fi

        # if conf path exists
        if [[ -d ${MO_CONTAINER_CONF_HOST_PATH} ]]; then
            docker_init_cmd="docker run ${cmd_params} -v ${MO_CONTAINER_CONF_HOST_PATH}:/etc/launch:rw --entrypoint /mo-service ${MO_CONTAINER_IMAGE} ${debug_option} ${pprof_option} -launch ${MO_CONTAINER_CONF_CON_FILE}"
        else
            docker_init_cmd="docker run ${cmd_params} --entrypoint /mo-service ${MO_CONTAINER_IMAGE} ${debug_option} ${pprof_option} -launch ${MO_CONTAINER_CONF_CON_FILE}"
        fi

        add_log "I" "Initial start mo container: ${docker_init_cmd}"
        ${docker_init_cmd}
    fi
}

# 启动 systemd 服务
function start_systemd() {
    # Create systemd service file
    SYSTEMD_SERVICE_FILE="/etc/systemd/system/matrixone.service"
    add_log "I" "Creating systemd service file at ${SYSTEMD_SERVICE_FILE}"

    # Prepare environment variables
    ENV_VARS=""
    if [[ "${go_mem_limit}" != "" ]]; then
        ENV_VARS="Environment=GOMEMLIMIT=${go_mem_limit}MiB"
    fi

    # Create service file content
    sudo bash -c "cat > ${SYSTEMD_SERVICE_FILE} << EOF
[Unit]
Description=MatrixOne Database Service
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${mo_actual_path}
${ENV_VARS}
ExecStart=${mo_actual_path}/mo-service ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE}
Restart=always
RestartSec=5
StandardOutput=append:${MO_LOG_PATH}/stdout-${RUN_TAG}.log
StandardError=append:${MO_LOG_PATH}/stderr-${RUN_TAG}.log

[Install]
WantedBy=multi-user.target
EOF"

    # Reload systemd and start service
    add_log "I" "Reloading systemd daemon"
    sudo systemctl daemon-reload
    add_log "I" "Starting matrixone service"
    sudo systemctl start matrixone.service
    sudo systemctl enable matrixone.service
}

# 启动 nohup 或 daemon 进程
function start_process() {
    if [[ "${go_mem_limit}" == "" ]]; then
        add_log "W" "GO memory limit seems to be empty, thus will not set this limit"
        if [[ "${DAEMON_METHOD}" == "nohup" ]]; then
            add_log "I" "Starting mo-service: cd ${mo_actual_path}/ && nohup ${mo_actual_path}/mo-service ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log &"
            cd ${mo_actual_path}/ && nohup ${mo_actual_path}/mo-service ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} > ${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2> ${MO_LOG_PATH}/stderr-${RUN_TAG}.log &
        else
            add_log "I" "Starting mo-service: cd ${mo_actual_path}/ && ${mo_actual_path}/mo-service -daemon ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log"
            cd ${mo_actual_path}/ && ${mo_actual_path}/mo-service -daemon ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} > ${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2> ${MO_LOG_PATH}/stderr-${RUN_TAG}.log
        fi
    else
        add_log "D" "Start command will add GOMEMLIMIT=${go_mem_limit}MiB"
        if [[ "${DAEMON_METHOD}" == "nohup" ]]; then
            add_log "I" "Starting mo-service: cd ${mo_actual_path}/ && GOMEMLIMIT=${go_mem_limit}MiB nohup ${mo_actual_path}/mo-service  ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log &"
            cd ${mo_actual_path}/ && GOMEMLIMIT=${go_mem_limit}MiB nohup ${mo_actual_path}/mo-service ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} > ${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2> ${MO_LOG_PATH}/stderr-${RUN_TAG}.log &
        else
            add_log "I" "Starting mo-service: cd ${mo_actual_path}/ && GOMEMLIMIT=${go_mem_limit}MiB ${mo_actual_path}/mo-service -daemon ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} >${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2>${MO_LOG_PATH}/stderr-${RUN_TAG}.log"
            cd ${mo_actual_path}/ && GOMEMLIMIT=${go_mem_limit}MiB ${mo_actual_path}/mo-service -daemon ${debug_option} ${pprof_option} -launch ${MO_CONF_FILE} > ${MO_LOG_PATH}/stdout-${RUN_TAG}.log 2> ${MO_LOG_PATH}/stderr-${RUN_TAG}.log
        fi
    fi
}
