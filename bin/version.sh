#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# get_cid

function version_deprecated() {
    echo "Tool version: ${TOOL_NAME} ${MO_TOOL_VERSION}"
    echo "Server version: ${MO_SERVER_NAME} ${MO_SERVER_VERSION}"
}

function version() {
    add_log "I" "Tool version (mo_ctl):"
    add_log "I" "-------------------------------"
    add_log "I" "${TOOL_NAME} ${MO_TOOL_VERSION}"
    echo ""
    add_log "I" "Server version (MatrixOne): "
    add_log "I" "-------------------------------"
    server_info=$(sql "select version()")
    if [ $? -ne 0 ]; then
        add_log "E" "Failed to get server version"
        return 1
    fi
    server_version=$(echo "${server_info}" | grep 'MatrixOne' | awk -F '[ -]+' '{print $4}')
    add_log "I" "超融合数据库MatrixOne企业版软件 ${server_version}"
}
