#!/bin/bash
# basic funtions

# function: print log with given log level and message
# usage: add_log [level] [msg] []
# e.g. : add_log "INFO" "This is a demo log message"
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
    nowtime=`date '+%F_%T'`
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
    case ${system} in
        Darwin)
            echo "Mac"
            ;;
        Linux)
            echo "Linux"
            ;;            
        *)
            echo "OtherOS"
            ;;
    esac
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