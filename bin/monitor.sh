#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# monitor

monitor_name="monitor"
MONITOR_COMPONENT_LIST=("node_exporter" "prometheus" "grafana")
MONITOR_VERSION_LIST=("${MONITOR_NODE_EXPORTER_VERSION}" "${MONITOR_PROMETHEUS_VERSION}" "${MONITOR_GRAFANA_VERSION}")

# deploy
# components: promethues + node_exporter + grafana
# way: online | offline
# Steps:
# 1. download (online)
# 2. extract
# 3. configure
function monitor_deploy() {
    online="$1"

    #MONITOR_URL_PREFIX_1
    #https://mirror.ghproxy.com/github.com/prometheus/${module_name}/releases/download/${module_version}/${module_name}-${module_version}.${os}-${arch}.tar.gz

    # download and extact
    if [[ "${online}" == "online" ]] || [[ "${online}" == "" ]]; then
        # get os type
        os=$(uname)
        os_lower=$(to_lower "${os}")

        # get arch
        arch=$(arch)
        if [[ "${arch}" == "aarch64" ]]; then
            arch="arm64"
        elif [[ "${arch}" == "x86_64" ]]; then
            arch="amd64"
        fi

        add_log "D" "os: ${os}, arch: ${arch}"

        add_log "D" "Creating monitoring folder: mkdir -p ~/mo_ctl/monitor"
        mkdir -p ~/mo_ctl/monitor

        for ((i = 0; i <= 2; i++)); do
            echo "os: ${os_lower}"
            module_name="${MONITOR_COMPONENT_LIST[${i}]}"
            module_version="${MONITOR_VERSION_LIST[${i}]}"
            target_file="${module_name}-${module_version}.${os_lower}-${arch}.tar.gz"

            if [[ ${i} -lt 2 ]]; then
                url="${MONITOR_URL_PREFIX_1}/prometheus/${module_name}/releases/download/v${module_version}/${module_name}-${module_version}.${os_lower}-${arch}.tar.gz"
            else
                url="${MONITOR_URL_PREFIX_2}/oss/release/${module_name}-${module_version}.${os_lower}-${arch}.tar.gz"
            fi

            add_log "I" "----------------------------------------------------"
            add_log "I" "Component name: ${module_name}"
            add_log "I" "Action: download, command: wget "${url}" -O ~/mo_ctl/monitor/${target_file}"
            # 1. download
            if ! wget "${url}" -O ~/mo_ctl/monitor/${target_file}; then
                add_log "E" "Download failed, please check if your network status is abnormal, exiting"
                return 1
            fi

            # 2. extract
            add_log "I" "Action: extract, command: tar xvf ~/mo_ctl/monitor/${target_file} -C ~/mo_ctl/monitor/"
            if ! tar xvf ~/mo_ctl/monitor/${target_file} -C ~/mo_ctl/monitor/; then
                add_log "E" "Extract failed, please check if file is incomplete or disk space is full"
                return 1
            fi
        done

        add_log "I" "Deploy monitor system succeeded"

    fi

}

# uninstall
function monitor_uninstall() {
    :
}

# status
# check monitor status
# 1. prometheus
# 2. node_exporter
# 3. grafana
function monitor_status() {
    :
}

# start
function monitor_start() {
    :
}

# stop
function monitor_stop() {
    :
}

# usage:
# mo_ctl monitor [option_1] [option_2]
#     option_1: deploy | uninstall | status | start | stop
#     option_2:
#          deploy: online | offline
function monitor() {
    option_1="$1"
    option_2="$2"

    case "${option_1}" in
        "deploy")
            monitor_deploy ${option_2}
            ;;
        "uninstall")
            :
            ;;
        "status")
            :
            ;;
        "start")
            :
            ;;
        "stop")
            :
            ;;
        *)
            add_log "E" "Invalid option for ${monitor_name}: ${option_1}"
            help_watchdog
            return 1
            ;;
    esac

}
