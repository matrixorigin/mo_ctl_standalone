#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# sql

query=""

function exec_path()
{
    rc=0
    add_log "I" "Input ${query} is a path, listing .sql files in it: "
    ls -A ${query}/ | grep "\.sql\$"
    declare -A query_report
    for query_file in `ls -A ${query}/ | grep "\.sql\$"`; do
        add_log "I" "Begin executing query file ${query_file}"
        startTime=`date +%s.%N`

        if mysql -h"${MO_HOST}" -P"${MO_PORT}" -u"${MO_USER}" -p"${MO_PW}" -vvv < "${query}/${query_file}"; then
            endTime=`date +%s.%N`
            add_log "I" "End executing query file ${query_file}, succeeded"
            outcome="succeeded"
        else
            endTime=`date +%s.%N`
            add_log "E" "End executing query file ${query_file}, failed"
            outcome="failed"
            rc=1
        fi
        cost=`time_cost_ms ${startTime} ${endTime}`
        query_report["${query_file}"]="${outcome},${cost}"
    done
    add_log "I" "Done executing all query files in path ${query}"
    add_log "I" "Query report:"
    echo "query_file,outcome,time_cost_ms"
    for query_file in ${!query_report[*]}; do
        echo "${query_file},${query_report[${query_file}]}"
    done
    return ${rc}
}

function exec_file()
{
    rc=0
    add_log "I" "Input ${query} is a file"
    add_log "I" "Begin executing query file ${query}"
    startTime=`date +%s.%N`
    if mysql -h"${MO_HOST}" -P"${MO_PORT}" -u"${MO_USER}" -p"${MO_PW}" -vvv < "${query}"; then
        endTime=`date +%s.%N`
        add_log "I" "End executing query file ${query}, succeeded"
        outcome="succeeded"
    else
        endTime=`date +%s.%N`
        add_log "E" "End executing query file ${query}, failed"
        outcome="failed"
        rc=1
    fi
    cost=`time_cost_ms ${startTime} ${endTime}`
    add_log "I" "Query report:"
    echo "query_file,outcome,time_cost_ms"
    echo "${query},${outcome},${cost}"
    return ${rc}
}


function exec_query()
{
    add_log "I" "Input \"${query}\" is not a path or a file, try to execute it as a query"
    add_log "I" "Begin executing query \"${query}\""
    startTime=`date +%s.%N`
    if mysql -h"${MO_HOST}" -P"${MO_PORT}" -u"${MO_USER}" -p"${MO_PW}" -vvv -e "${query}"; then
        endTime=`date +%s.%N`
        add_log "I" "End executing query ${query}, succeeded"
        outcome="succeeded"
    else
        endTime=`date +%s.%N`
        add_log "E" "End executing query ${query}, failed"
        outcome="failed"
        rc=1
    fi
    cost=`time_cost_ms ${startTime} ${endTime}`

    add_log "I" "Query report:"
    echo "query,outcome,time_cost_ms"
    echo "${query},${outcome},${cost}"
    return ${rc}
}

function sql()
{
    query="$*"
    # 1. empty query
    if [[ "${query}" == "" ]]; then
        add_log "E" "Query is empty, please check again"
        help_query
        return 1
    # 2. input is a path
    elif [[ -d "${query}" ]]; then
        exec_path
    # 3. input is a file
    elif [[ -f "${query}" ]]; then
        exec_file
    # 4. input is a query
    else
        exec_query
    fi
}
