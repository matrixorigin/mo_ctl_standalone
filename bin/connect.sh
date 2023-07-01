#!/bin/bash
# connect

function connect()
{
    add_log "INFO" "Checking connectivity"
    if mysql -u${MO_USER} -P${MO_PORT} -h${MO_HOST} -p${MO_PW} -e "select 1" >/dev/null 2>&1; then
        add_log "INFO" "Ok, connecting for user ... "
        mysql -u${MO_USER} -P${MO_PORT} -h${MO_HOST} -p${MO_PW}
        add_log "INFO" "Connect succeeded and finished. Bye"

    else
        add_log "ERROR" "Connect failed"
        return 1
    fi
}