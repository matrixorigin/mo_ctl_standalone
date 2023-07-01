#!/bin/bash
# mysql_to_mo


# engines
engines=(\
    #"ARCHIVE" "BDB" "CSV"\
    #"EXAMPLE" "FEDERATED" "HEAP"\
    "MyISAM" "InnoDB"\
    #"MEMORY" "MERGE" "ISAM" "NDBCLUSTER"\
)

# character sets
char_sets=(\
    #"big5" "dec8" "cp850" "hp8" "koi8r" "latin1" "latin2"\
    #"swe7" "ascii" "ujis" "sjis" "hebrew" "tis620" "euckr" "koi8u"\
    #"gb2312" "greek" "cp1250" "gbk" "latin5" "armscii8" "utf8" "ucs2"\
    #"cp866" "keybcs2" "macce" "macroman" "cp852" "latin7"\
    "utf8mb3" "utf8mb4" "utf8" \
    #"cp1251" "utf16" "utf16le" "cp1256" "cp1257" "utf32" "binary"\
    #"geostd8" "cp932" "eucjpms" "gb18030"\
)


collates=(\
    "utf8mb3_general_ci" "utf8mb3_bin" "utf8mb4_general_ci" "utf8mb4_unicode_ci" "utf8_general_ci" \
)

# row formats
row_formats=(\
    #"DEFAULT" "FIXED" "COMPRESSED" "REDUNDANT"\
    "COMPACT" "DYNAMIC"\
    )

# index types
index_types=("BTREE" "HASH")

##########################
# basics
##########################


function check_files()
{
    if [[ ! -f "${DDL_SRC_FILE}" ]]; then
        add_log "ERROR" "Source file ${DDL_SRC_FILE} does not exist"
        return 1
    fi

    if [[ ! -f "${DDL_TGT_FILE}" ]]; then
        touch "${DDL_TGT_FILE}"
    fi

    add_log "INFO" "Cleaning content of target file ${DDL_TGT_FILE}"
    cat /dev/null > "${DDL_TGT_FILE}"
}


##########################
# get content
##########################


function get_db()
{
    awk '/[Dd][Rr][Oo][Pp] [Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Dd][Aa][Tt][Aa][Bb][Aa][Ss][Ee]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Uu][Ss][Ee] /,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}

function get_tbl()
{
    awk '/[Dd][Rr][Oo][Pp] [Tt][Aa][Bb][Ll][Ee]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Tt][Aa][Bb][Ll][Ee]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}

function get_view()
{
    awk '/[Dd][Rr][Oo][Pp] [Vv][Ii][Ee][Ww]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Vv][Ii][Ee][Ww]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}

function get_index()
{
    awk '/[Dd][Rr][Oo][Pp] [Ii][Nn][Dd][Ee][Xx]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Ii][Nn][Dd][Ee][Xx]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}

function get_udf()
{
    awk '/[Dd][Rr][Oo][Pp] [Ff][Uu][Cc][Tt][Ii][Oo][Nn]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Ff][Uu][Cc][Tt][Ii][Oo][Nn]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}


function get_sp()
{
    awk '/[Dd][Rr][Oo][Pp] [Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
    awk '/[Cc][Rr][Ee][Aa][Tt][Ee] [Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}

function get_data()
{
    awk '/[Ii][Nn][Ss][Ee][Rr][Tt] [Ii][Nn][Tt][Oo]/,/;/' "${DDL_SRC_FILE}" >> "${DDL_TGT_FILE}"
}


function get_content()
{
    add_log "INFO" "Getting drop and create database ... "
    if get_db; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  
    
    add_log "INFO" "Getting drop and create table ... "
    if get_tbl; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  

    add_log "INFO" "Getting drop and create view ... "
    if get_view; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  
#    get_index
#    get_udf
#    get_sp

    add_log "INFO" "Getting insert into ... "
    if get_data; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  
    

}



##########################
# delete unwanted content
##########################

function del_engine()
{
    for engine in ${engines[@]}; do
        sed -i "s/ENGINE=${engine}//gi" ${DDL_TGT_FILE} 
        sed -i "s/ENGINE = ${engine}//gi" ${DDL_TGT_FILE} 
    done
}

function del_row_format()
{
    for row_format in ${row_formats[@]}; do
        sed -i "s/ROW_FORMAT=${row_format}//gi" ${DDL_TGT_FILE}
        sed -i "s/ROW_FORMAT = ${row_format}//gi" ${DDL_TGT_FILE}
    done
}

function del_charset()
{

    for char_set in ${char_sets[@]}; do
        sed -i "s/DEFAULT CHARSET=${char_set}//gi" ${DDL_TGT_FILE}
        sed -i "s/DEFAULT CHARSET = ${char_set}//gi" ${DDL_TGT_FILE}
        sed -i "s/CHARACTER SET ${char_set}//gi" ${DDL_TGT_FILE}
        sed -i "s/CHARACTER SET = ${char_set}//gi" ${DDL_TGT_FILE}
        sed -i "s/CHARACTER SET=${char_set}//gi" ${DDL_TGT_FILE}
    done   


    for collate in ${collates[@]}; do
        sed -i "s/COLLATE ${collate}//gi" ${DDL_TGT_FILE}
        sed -i "s/COLLATE=${collate}//gi" ${DDL_TGT_FILE}
        sed -i "s/COLLATE = ${collate}//gi" ${DDL_TGT_FILE}
    done

}

function del_index_types()
{

    for index_type in ${index_types[@]}; do
        sed -i "s/USING ${index_type}//gi" ${DDL_TGT_FILE}
    done
}

function del_auto_increment()
{

    # note the orders, first replace 'AUTO_INCREMENT=' with ';', then replace 'AUTO_INCREMENT' with ''
    sed -i "s/AUTO_INCREMENT=\([0-9]*\)//" ${DDL_TGT_FILE}
    sed -i "s/AUTO_INCREMENT = \([0-9]*\)//" ${DDL_TGT_FILE}
    sed -i "s/AUTO_INCREMENT//g" ${DDL_TGT_FILE}
}

function del_unwanted()
{
    add_log "INFO" "Deleting ENGINE=xxx ... "
    if del_engine; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  

    add_log "INFO" "Deleting ROW_FORMAT=xxx ... "
    if del_row_format; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi   

    add_log "INFO" "Deleting DEFAULT CHARSET=xxx, CHARACTER SET xxx, COLLATE xxx ... "
    if del_charset; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  

    add_log "INFO" "Deleting USING xxx ... "
    if del_index_types; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi  
    
    add_log "INFO" "Deleting AUTO_INCREMENT, AUTO_INCREMENT=xxx ... "
    if del_auto_increment; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi   
    
}

##########################
# format content
##########################

function format_content()
{
    add_log "INFO" "Adding lines... "
    if sed -i 's/;$/;\n/g' "${DDL_TGT_FILE}"; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi
    
    add_log "INFO" "Converting dos to unix... "
    if dos2unix "${DDL_TGT_FILE}" >/dev/null 2>&1; then
        add_log "INFO" "Succeeded"
    else
        add_log "ERROR" "Failed"
    fi
}


##########################
# main
##########################

function mysql_to_mo()
{
    add_log "INFO" "Check if source file ${DDL_SRC_FILE} and ${DDL_TGT_FILE} exist"
    if ! check_files; then
        return 1
    fi

    add_log "INFO" "1. Getting content, pls wait...  "
    if get_content; then
        add_log "INFO"  "Getting content succeeded"
    else
        add_log "ERROR"  "Getting content failed"
        return 1
    fi

    add_log "INFO" "2. Deleting unwanted content, pls wait... "
    if del_unwanted; then
        add_log "INFO"  "Deleting unwanted content succeeded"
    else
        add_log "ERROR" "Deleting unwanted content failed"
        return 1
    fi

    add_log "INFO" "3. Formatting content, pls wait... "
    if format_content; then
        add_log "INFO" "Formatting content succeeded"
    else
        add_log "ERROR" "Formatting content failed"
        return 1
    fi

}