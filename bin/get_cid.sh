#!/bin/bash
# cid

function get_cid()
{
    add_log "INFO" "Try get mo commitid: "
    if cd ${MO_PATH}/matrixone && git log | head -6 ; then
        add_log "INFO" "Get commit id succeeded"
    else
        add_log "ERROR" "Get commit id failed"
        return 1
    fi
}
