#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# ddl_convert


function ddl_convert ()
{
    option=$1
    src_file=$2
    tgt_file=$3
    case ${option} in
        mysql_to_mo)
            if [[ "${src_file}" == "" ]]; then
                add_log "I" "DDL_SRC_FILE is not set manually, try to get it from conf file"
                if ! get_conf DDL_SRC_FILE; then
                    return 1
                else
                    src_file=${DDL_SRC_FILE}
                fi
            fi

            if [[ "${tgt_file}" == "" ]]; then
                add_log "I" "DDL_TGT_FILE is not set manually, try to get it from conf file"
                if ! get_conf DDL_TGT_FILE; then
                    return 1
                else
                    tgt_file=${DDL_TGT_FILE}
                fi
            fi

            src_file=`readlink -f ${src_file}`
            tgt_file=`readlink -f ${tgt_file}`
           
            mysql_to_mo ${src_file} ${tgt_file}
            
            ;;
        *)
            add_log "E" "Invaid option: ${option}"
            help_ddl_convert
            return 1
            ;;
    esac
}
