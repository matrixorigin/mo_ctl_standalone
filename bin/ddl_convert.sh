#!/bin/bash
# ddl_convert


function ddl_convert ()
{
    option=$1
    src_file=$2
    tgt_file=$3
    case ${option} in
        mysql_to_mo)
            if [[ "${src_file}" == "" ]]; then
                add_log "INFO" "DDL_SRC_FILE is not set manually, try to get it from conf file"
                if ! get_conf DDL_SRC_FILE; then
                    return 1
                else
                    src_file=${DDL_SRC_FILE}
                fi
            fi

            if [[ "${tgt_file}" == "" ]]; then
                add_log "INFO" "DDL_TGT_FILE is not set manually, try to get it from conf file"
                if ! get_conf DDL_TGT_FILE; then
                    return 1
                else
                    tgt_file=${DDL_TGT_FILE}
                fi
            fi

            src_file=`readlink -f ${src_file}`
            tgt_file=`readlink -f ${tgt_file}`
           
            os=`what_os`
            if [[ "${os}" == "Mac" ]] ; then
                mysql_to_mo_mac ${src_file} ${tgt_file}
            else
                mysql_to_mo ${src_file} ${tgt_file}
            fi 
            
            ;;
        *)
            add_log "ERROR" "Invaid option: ${option}"
            help_ddl_convert
            return 1
            ;;
    esac
}
