#!/bin/bash
# restart

function restart()
{
    force=$1
    stop ${force}

    add_log "INFO" "Wait for ${RESTART_INTERVAL} seconds"
    sleep ${RESTART_INTERVAL}

    start
}
