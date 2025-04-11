#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# connect

function connect() {
    add_log "I" "Checking connectivity"
    if MYSQL_PWD="${MO_PW}" mysql --local-infile -u${MO_USER} -P${MO_PORT} -h${MO_HOST} -e "select 1" > /dev/null 2>&1; then
        add_log "I" "Ok, connecting for user ... "
        MYSQL_PWD="${MO_PW}" mysql --local-infile -u${MO_USER} -P${MO_PORT} -h${MO_HOST}
        add_log "I" "Connect succeeded and finished. Bye"

    else
        add_log "E" "Connect failed"
        return 1
    fi
}
