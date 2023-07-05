#!/bin/bash
# mysql_to_mo

src_file=""
tgt_file=""


##########################
# basics
##########################


function check_files()
{
    add_log "INFO" "Check if source file ${src_file} and ${tgt_file} exist"
    if [[ ! -f "${src_file}" ]]; then
        add_log "ERROR" "Source file ${src_file} does not exist"
        return 1
    fi

    if [[ ! -f "${tgt_file}" ]]; then
        touch "${tgt_file}"
    fi

    add_log "INFO" "Cleaning content of target file ${tgt_file}"
    cat /dev/null > "${tgt_file}"
}


##########################
# get content
##########################


function get_db()
{

    awk '/[Dd][Rr][Oo][Pp] [Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Uu][Ss][Ee] /,/;/' "${src_file}" >> "${tgt_file}"
}

function get_tbl()
{

    awk '/[Dd][Rr][Oo][Pp] [Tt][Aa][Bb][Ll][Ee]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Tt][Aa][Bb][Ll][Ee]/,/;/' "${src_file}" >> "${tgt_file}"


}

function get_view()
{
    awk '/[Dd][Rr][Oo][Pp] [Vv][Ii][Ee][Ww]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Vv][Ii][Ee][Ww]/,/;/' "${src_file}" >> "${tgt_file}"
}

function get_index()
{
    awk '/[Dd][Rr][Oo][Pp] [Ii][Nn][Dd][Ee][Xx]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Ii][Nn][Dd][Ee][Xx]/,/;/' "${src_file}" >> "${tgt_file}"
}

function get_udf()
{
    awk '/[Dd][Rr][Oo][Pp] [Ff][Uu][Cc][Tt][Ii][Oo][Nn]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Ff][Uu][Cc][Tt][Ii][Oo][Nn]/,/;/' "${src_file}" >> "${tgt_file}"
}


function get_sp()
{
    awk '/[Dd][Rr][Oo][Pp] [Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee]/,/;/' "${src_file}" >> "${tgt_file}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee]/,/;/' "${src_file}" >> "${tgt_file}"
}

function get_data()
{
    awk '/[Ii][Nn][Ss][Ee][Rr][Tt] [Ii][Nn][Tt][Oo]/,/);/' "${src_file}" >> "${tgt_file}"
}


function get_ddl()
{
    rc=0
    add_log "INFO" "Getting drop and create database ... "
    if ! get_db; then
        add_log "ERROR" "Failed"
        rc=1
    fi  
    
    add_log "INFO" "Getting drop and create table ... "
    if ! get_tbl; then
        add_log "ERROR" "Failed"
        rc=1
    fi  

    add_log "INFO" "Getting drop and create view ... "
    if ! get_view; then
        add_log "ERROR" "Failed"
        rc=1
    fi  
#    get_index
#    get_udf
#    get_sp

    return ${rc}
}



##########################
# delete unwanted content
##########################
function del_all_not_supported()
{

    rc=0

    # 1. key = xxx, key xxx, key
    DEL_KEY_1=(\
        "ENGINE" "ROW_FORMAT" \
        "DEFAULT CHARSET" "CHARACTER SET" \
        "COLLATE" "USING" "AUTO_INCREMENT")


    for del_key in "${DEL_KEY_1[@]}"; do
        add_log "INFO" "Delete content: ${del_key}=xxx, ${del_key} = xxx, ${del_key} xxx, and/or ${delkey}"

        if ! sed -i "s/$del_key=[a-zA-Z0-9_]*//gi" ${tgt_file}; then
            add_log "ERROR" "Failed at key=xxx"
            rc = 1
        fi

        if ! sed -i "s/$del_key = [a-zA-Z0-9_]*//gi" ${tgt_file}; then
            add_log "ERROR" "Failed at key = xxx"
            rc=1
        fi
        
        if [[ "${del_key}" == "AUTO_INCREMENT" ]]; then
            if ! sed -i "s/$del_key//gi" ${tgt_file}; then
                add_log "ERROR" "Failed at key xxx"
                rc=1
            fi
        else
            if ! sed -i "s/$del_key [a-zA-Z0-9_]*//gi" ${tgt_file}; then
                add_log "ERROR" "Failed at key"
                rc=1
            fi
        fi
    done

}

function del_set_var()
{
    rc=0
    add_log "INFO" "Delete content: SET xxx"
    if ! sed -i "s/^SET .*//gi" ${tgt_file}; then
        add_log "ERROR" "Failed"
        rc=1
    fi

    return ${rc}
}

function del_unwanted()
{
    rc=0

    if ! del_all_not_supported; then
        rc=1
    fi

    if ! del_set_var; then
        rc=1 
    fi

    return ${rc}
}


##########################
# format content
##########################

function format_file()
{
    rc=0
#    add_log "INFO" "Adding lines... "
#    if ! sed -i 's/;$/;\n/g' "${tgt_file}"; then
#        add_log "ERROR" "Failed"
#        rc=1
#    fi
    
    add_log "INFO" "Converting dos to unix... "
    #if dos2unix "${tgt_file}" >/dev/null 2>&1; then
    if sed -i "s/\r//" "${tgt_file}"; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
#         add_log "WARN" "Failed, please check if dos2unix is installed, the output file format may have potential issues when executing in mo. You can convert output file mannually after installing it: dos2unix ${tgt_file}"
    fi

    return ${rc}
}


##########################
# main
##########################

function mysql_to_mo()
{
    rc=0
    src_file=$1
    tgt_file=$2
    if ! check_files; then
        return 1
    fi

#    add_log "INFO" "1. Getting ddl, please wait...  "
#    if get_ddl; then
#        add_log "INFO"  "Getting ddl succeeded"
#    else
#        add_log "ERROR"  "Getting ddl failed"
#        rc=1
#    fi

    add_log "INFO" "1. Copy source file to target file, this may take a while depending on the size the source file, please wait... "
    if ! cp -pf ${src_file} ${tgt_file}; then
        add_log "ERROR" "Failed"
        return 1
    fi 

    add_log "INFO" "2. Delete unwanted content, please wait... "
    if ! del_unwanted; then
        add_log "ERROR" "Delete unwanted content failed"
        rc=1
    fi

#    add_log "INFO" "3. Getting data, please wait...  "
#    if get_data; then
#        add_log "INFO"  "Getting data succeeded"
#    else
#        add_log "ERROR"  "Getting data failed"
#        rc=1
#    fi

    add_log "INFO" "3. Format file, please wait... "
    if ! format_file; then
        add_log "ERROR" "Format file failed"
        rc=1
    fi
    
    return ${rc}

}