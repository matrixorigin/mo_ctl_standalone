#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# basic funtions

# function: print log with given log level and message
# usage: add_log [level] [msg] []
# e.g. : add_log "I" "This is a demo log message"
# in: 
#    [level]: log level, suggested: DEBUG | INFO | WARN | ERROR
#    [msg]: log message in one sentence
# output: 
#    "[current_timestamp]    [level]    [msg]"
#    e.g.: "20230630_222408    [INFO]    This is a demo log message"
function add_log()
{
    level=$1
    msg="$2"
    add_line="$3"
    #format: 2023-07-13_15:37:40
    #nowtime=`date '+%F_%T'`
    #format: 2023-07-13_15:37:22.775
    nowtime="`date '+%Y-%m-%d_%H:%M:%S.%N'`"
    nowtime="`echo "${nowtime}" | cut -b 1-23`"
    
    case "${level}" in
        "e"|"E")
            level="ERROR"
            ;;
        "W"|"w")
            level="WARN" 
            ;;
        "I"|"i")
            level="INFO" 
            ;;
        "d"|"D")
            level="DEBUG" 
            ;;
        *)
            echo "These are valid log levels: E/e/W/w/I/i/D/d."
            echo "   E/e: ERROR, W/w: WARN, I/i: INFO, D/d: DEBUG"
            exit 1
        ;;
    esac 

    if [[ "${add_line}" == "n" ]]; then
        echo -n "${nowtime}    [${level}]    ${msg}"
    else
        echo "${nowtime}    [${level}]    ${msg}"
    fi
}

# function: compare the version number of 2 given string
# usage: cmp_version [v1] [v2]
# e.g. : cmp_version 1.20.1 1.19
# in: 
#   [v1]: current version
#   [v2]: required version
# output: 
#   0: if [v1] ≥ [v2]
#   1: otherwise
function cmp_version()
{ 
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; 
}

# deprecated
function cmp_version_old()
{
    version_current=$1
    version_required=$2
    rc=`awk -v  v1=${version_required} -v v2=${version_current} 'BEGIN{print(v2>=v1)?"0":"1"}'`
    return $rc
}

# fuction: return os name of current machine
# usage: what_os
# in: none
# out: os name, available: Mac | Linux | OtherOS
function what_os()
{    
    system=`uname`
    os=""
    case "${system}" in
        "")
            return 1
            ;;
        "Darwin")
            os="Mac"
            ;;
        "Linux")
            os="Linux"
            ;;            
        *)
            os="OtherOS"
            ;;
    esac
    echo "${os}"
}

function pos_int_range()
# function: check if a given string is a valid positive integer and is less than the second given number
# usage: pos_int_range [num1] [num2]
# e.g. : pos_int_range 10 100
# in:
#   [num1]: number to be judged
#   [num2]: maximum number of range
# out:
#   0: if 0 < [num1] ≤ [num2]
#   1: otherwise
{
    num1=$1
    num2=$2
    if [[ ${num1} -gt 0 ]] 2>/dev/null && [[ ${num1} -le ${num2} ]]  2>/dev/null
    then
        return 0
    else
        return 1
    fi
}

# function: convert an input string to upper format
# usage: to_upper [string]
# e.g. : to_upper aBcdEfgHI
# in:
#   [string]: string in alphabet format
# out:
#   [string]: upper format of input string, e.g. aBcdEfgHI -> ABCDEFGHI
function to_upper()
{
    echo $(echo $1 | tr '[a-z]' '[A-Z]') 
}

# function: convert an input string to lower format
# usage: to_lower [string]
# e.g. : to_lower aBcdEfgHI
# in:
#   [string]: string in alphabet format
# out:
#   [string]: lower format of input string, e.g. aBcdEfgHI -> abcdefghi
function to_lower()
{
    echo $(echo $1 | tr '[A-Z]' '[a-z]') 
}

# function: get time cost between start time and end time
# usage: get_timing [start_time] [end_time]
# e.g. : get_timing "1689217282.184130282" "1689217289.414088786"
# in:
#   [start_time]: start time in format 'date +%s.%N', such as: 1689217282.184130282
#   [end_time]: end time in format 'date +%s.%N', such as: 1689217289.414088786
# out:
#   [time_cost]: time cost between start time and end time, unit: ms, such as 7230
function time_cost_ms()
{
    start=$1
    end=$2
  
    start_s=$(echo $start | cut -d '.' -f 1)
    start_ns=$(echo $start | cut -d '.' -f 2)
    end_s=$(echo $end | cut -d '.' -f 1)
    end_ns=$(echo $end | cut -d '.' -f 2)


    cost=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))

    echo "${cost}"
}