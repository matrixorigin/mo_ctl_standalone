#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# connect

function connect()
{
    add_log "I" "Checking connectivity"
    if mysql -u${MO_USER} -P${MO_PORT} -h${MO_HOST} -p${MO_PW} -e "select 1" >/dev/null 2>&1; then
        add_log "I" "Ok, connecting for user ... "
        mysql -u${MO_USER} -P${MO_PORT} -h${MO_HOST} -p${MO_PW}
        add_log "I" "Connect succeeded and finished. Bye"

    else
        add_log "E" "Connect failed"
        return 1
    fi
}