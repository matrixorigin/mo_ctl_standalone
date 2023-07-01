#!/bin/bash
# restart

function restart()
{
    stop

    add_log "INFO" "Wait for ${RESTART_INTERVAL} seconds"
    sleep ${RESTART_INTERVAL}

    start
}
