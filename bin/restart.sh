#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# restart

function restart() {
    force=$1
    stop ${force}

    add_log "I" "Wait for ${RESTART_INTERVAL} seconds"
    sleep ${RESTART_INTERVAL}

    start
}
