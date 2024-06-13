#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# basic funtions

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

function get_nanosecond()
{
    os=`what_os`
    if [[ "${os}" == "Mac" ]]; then
        # 1. for Mac
        # format: 1690284688.93481087684631347656
        if which python3 >/dev/null 2>&1; then
            # in nanosecond
            nanosec=`python3 -c "import time; print('%.9f' % time.time())"`
        elif which python >/dev/null 2>&1; then
            # in nanosecond
            nanosec=`python -c "import time; print('%.9f' % time.time())"`
        else
            # in second
            nanosec=`date +%s.0000000000`
        fi
    else
        # 2. for Linux
        # format: 1690284688.93481087684631347656
        # in nanosecond
        nanosec=`date +%s.%N`
    fi
    echo "${nanosec}"
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

    os=`what_os`
    if [[ "${os}" == "Mac" ]]; then
        # 1. for Mac
        # format: 2023-07-25 17:39:24.904 UTC+0800
        timezone="UTC+0800"
        if which python3 >/dev/null 2>&1; then
            # in millisecond 
            timestamp_ms=`python3 -c "import datetime; print(datetime.datetime.now(datetime.timezone(datetime.timedelta(hours = 8))).strftime('%Y-%m-%d %H:%M:%S.%f'))" | cut -b 1-23`
        elif which python >/dev/null 2>&1; then
            # in millisecond 
            timestamp_ms=`python -c "import datetime; print(datetime.datetime.now(datetime.timezone(datetime.timedelta(hours = 8))).strftime('%Y-%m-%d %H:%M:%S.%f'))" | cut -b 1-23`
        else
            # in second
            timestamp_ms=`date '+%Y-%m-%d %H:%M:%S'`
        fi
        nowtime="${timestamp_ms} ${timezone}"
    else
        # 2. for Linux
        # format: 2023-07-13 15:37:40
        # nowtime=`date '+%F %T'`
        # format: 2023-07-25 17:39:24.904 UTC+0800
        nowtime="`date '+%Y-%m-%d %H:%M:%S.%N UTC%z'`"
        timestamp_ms="`echo "${nowtime}" | cut -b 1-23`"
        timezone="`echo "${nowtime}" | cut -b 31-39`"
        nowtime="${timestamp_ms} ${timezone}"
    fi

    level=`to_upper ${level}`
    display_log_level=`to_upper ${TOOL_LOG_LEVEL}`
    if [[ "${display_log_level}" == "" ]]; then
        display_log_level="I"
    fi
    case "${level}" in
        "E")
            level="ERROR"
            ;;
        "W")
            level="WARN"
            case "${display_log_level}" in
                "E")
                    return 0
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
        "I")
            level="INFO" 
            case "${display_log_level}" in
                "E"|"W")
                    return 0
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
        "D")
            level="DEBUG" 
            case "${display_log_level}" in
                "E"|"W"|"I")
                    return 0
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
        *)
            echo "These are valid log levels: E/e/W/w/I/i/D/d."
            echo "   E/e: ERROR, W/w: WARN, I/i: INFO, D/d: DEBUG"
            exit 1
        ;;
    esac 

    case "${add_line}" in
        "n" )
            echo -n "${nowtime}    [${level}]    ${msg}"
            ;;
        "l" )
            echo "${msg}"
            ;;
        *)
        echo "${nowtime}    [${level}]    ${msg}"
        ;;
    esac
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


function pos_int_range()
# function: check if a given string is a valid positive integer and is not larger than the second given number
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

# function: return the round up value of quotient of the 2 given positive integer number
# tmp = num1 / num2
# return : floor(tmp)
# e.g. 6/4=1.5, return 2; 6/3=2, return 2
function floor_quotient()
{
    n1=$1
    n2=$2
    if [[ ${n1} -gt 0 ]] 2>/dev/null && [[ ${n2} -gt 0 ]] 2>/dev/null; then
        quotient=`expr ${n1} / ${n2}`
        remainder=`expr ${n1} % ${n2}`
        if [[ ${remainder} -ne 0 ]]; then
            quotient=`expr ${quotient} + 1`
        fi

        echo "${quotient}"
    else
        add_log "E" "Either input number ${n1} or ${n2} is not a valid positive number"
        return 1
    fi
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
    # note:
    # date +'%s * 1000 + 10#%-N / 1000000' with gnu date (such as liunx)
    # date +'%s * 1000 + %-N / 1000000' with not gnu date (such as mac)

    start=$1
    end=$2
  
    start_s=$(echo $start | cut -d '.' -f 1)
    start_ns=$(echo $start | cut -d '.' -f 2)
    end_s=$(echo $end | cut -d '.' -f 1)
    end_ns=$(echo $end | cut -d '.' -f 2)

    # deprecated: it depends on bc
    # cost=`expr $time_micro/1000 | bc`
    os=`what_os`
    #if [[ "${os}" == "Mac" ]]; then
    #    cost=$(( ( $end_s - $start_s ) * 1000 + ( $end_ns / 1000000 - $start_ns / 1000000 ) ))
    #else
        cost=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))
    #fi

    echo "${cost}"
}

# function: get latest commit id of a given release version
function get_stable_cid()
{
    cid="$1"
    case "${cid}" in
        "1.0.0-rc1")
            echo "6c08c6a45191d63f9f89e5bfef5ff37194713b5f"
            ;;
        "0.8.0")
            echo "daf86797160585d24c158e4ee220964264616505"
            ;;
        "0.7.0")
            echo "6d4bd173514990032372310f7b3d9d803781074a"
            ;;
        "0.6.0")
            echo "c3262c1b58d030b00534283b9bd22cc83c888a2a"
            ;;
        "0.5.1")
            echo "c9491645c681c9e239817a6fa71fb71df25003e2"
            ;;
        "0.4.0")
            echo "aefc440bf6d6c2a5e96ba411fb0c98ae0b8bd657"
            ;;
        "0.3.0")
            echo "56fcd3ff8e4aa3b5a8b9d08c420fa90f7462c579"
            ;;
        "0.2.0")
            echo "c22aa58f948cef7e59acef1ebabb8f8dfd4154cd"
            ;;
        "0.1.0")
            echo "19cc0453b573e23ae643bea492bc43c5df4758db"
            ;;                                                                    
        *)
            echo "${cid}"
            ;;
    esac
    
}

# function: get cpu cores of current machine
function get_cpu_cores()
{
    os=`what_os`
    cpu_cores=""
    if [[ "${os}" == "Mac" ]]; then
        cpu_cores=`sysctl -n machdep.cpu.core_count`
    else
        cpu_cores=`cat /proc/cpuinfo | grep "processor" | wc -l`
    fi
    echo "${cpu_cores}"
}

# function: get memory size in megabytes of current machine 
function get_mem_mb()
{
    os=`what_os`
    total_mem=""

    if [[ "${os}" == "Mac" ]]; then
        total_mem_bytes=`sysctl hw.memsize | awk -F ":" '{print $2}' | sed 's/ //g'`
        total_mem=`expr $total_mem_bytes / 1024 / 1024`
    else
        total_mem=`free -m | awk 'NR==2{print $2}'`
    fi

    echo "${total_mem}"
}

# function: check if cron is enabled
function check_cron_service()
{
    if [[ "${OS}" == "Mac" ]]; then
        # 1. Mac
        add_log "D" "Get status of service cron"
        add_log "I" "On MacOS, we need you confirmation with password to continue this operation: sudo launchctl list | grep cron"
        if sudo launchctl list | grep -i cron; then
            add_log "D" "Succeeded. Service cron seems to be running."
        else
            add_log "E" "Failed. Please check again 'sudo launchctl list | grep -i cron' to make sure it's running. Refer to 'https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html' for more info"
            return 1
        fi
    else
        # 2. Linux
        add_log "D" "Get status of service cron"
        if systemctl status cron >/dev/null 2>&1 || service cron status >/dev/null 2>&1 || systemctl status crond >/dev/null 2>&1 || service crond status >/dev/null 2>&1; then
            add_log "D" "Succeeded. Service cron seems to be running."
        else
            add_log "E" "Failed. Please check again via 'systemctl status crond' or 'systemctl status cron' to make sure it's running. Or try to restart it via 'systemctl restart cron'."
            return 1
        fi
    fi
}