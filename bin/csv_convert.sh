#!/bin/bash
################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
# csv_convert

NUM_SRC_FILE=""
LOOP_COUNT=""
TGT_FILE=""
FILE_NAME=""
add_quote="y"

function csv_convert_precheck()
{
    add_log "I" "Reading conf settings: "
    get_conf CSV_CONVERT_MAX_BATCH_SIZE,CSV_CONVERT_SRC_FILE,CSV_CONVERT_BATCH_SIZE,CSV_CONVERT_TGT_DIR,CSV_CONVERT_TYPE,CSV_CONVERT_META_DB,CSV_CONVERT_META_TABLE,CSV_CONVERT_META_COLUMN_LIST,CSV_CONVERT_TN_TYPE,CSV_CONVERT_TMP_DIR

    # 1. check source file
    if [[ ! -f ${CSV_CONVERT_SRC_FILE} ]]; then
        add_log "E" "Conf CSV_CONVERT_SRC_FILE: ${CSV_CONVERT_SRC_FILE} is not a valid file or does not exist"
        return 1
    fi

    # 2. check batchsize
    if ! pos_int_range ${CSV_CONVERT_BATCH_SIZE} ${CSV_CONVERT_MAX_BATCH_SIZE}; then
        add_log "E" "Conf CSV_CONVERT_BATCH_SIZE: ${CSV_CONVERT_BATCH_SIZE} is not a valid integer or is larger than maximum batch size: ${CSV_CONVERT_MAX_BATCH_SIZE}"
        return 1
    fi

    # 3. check target directory
    if [[ ! -d ${CSV_CONVERT_TGT_DIR} ]]; then
        add_log "E" "Conf CSV_CONVERT_TGT_DIR: ${CSV_CONVERT_TGT_DIR} is not a valid directory or does not exist"
        return 1
    fi

    # 4. check convert type
    case "${CSV_CONVERT_TYPE}" in
        "1"|"2"|"3")
            :
            ;;
        *)
            add_log "E" "Conf CSV_CONVERT_TYPE: ${CSV_CONVERT_TYPE} is not in valid range: 1|2|3"
            return 1
        ;;
    esac 

    # 5. check meta data info
    if [ "${CSV_CONVERT_META_DB}" == "" ]; then
        add_log "E" "Conf CSV_CONVERT_META_DB is empty, please set it first"
        return 1
    fi

    if [ "${CSV_CONVERT_META_TABLE}" == "" ]; then
        add_log "E" "Conf CSV_CONVERT_META_TABLE is empty, please set it first"
        return 1
    fi

}

function csv_convert_prep()
{

    CONVERT_TYPE=$1

    # 1. generate target file
    FILE_NAME=`basename ${CSV_CONVERT_SRC_FILE} | awk -F"." '{print $1}'`

    if [[ "${CSV_CONVERT_TN_TYPE}" == "2" ]]; then
        TN_TYPE="tn-single"
    else
        TN_TYPE="tn-multi"
    fi

    TGT_FILE="${CSV_CONVERT_TGT_DIR}/${FILE_NAME}_${CONVERT_TYPE}_${TN_TYPE}_${CSV_CONVERT_BATCH_SIZE}.sql"

    add_log "I" "Generate target file ${TGT_FILE}"
    if ! touch ${TGT_FILE}; then
        # empty target file
        add_log "E" "Failed to generate target file, please check if you have enough permissions under target directory"
        return 1
    fi
    
    if [[ "${CSV_CONVERT_TN_TYPE}" == "2" ]]; then
        echo "begin;" > ${TGT_FILE}
    else
        cat /dev/null > ${TGT_FILE}
    fi

    # 2. count number of lines in source file
    add_log "I" "Counting number of lines in source file: ${CSV_CONVERT_SRC_FILE}"
    NUM_SRC_FILE=`wc -l ${CSV_CONVERT_SRC_FILE} | awk '{print $1}'`
    add_log "I" "Number of lines: ${NUM_SRC_FILE}"

    # 3. calculate number of loops
    LOOP_COUNT=`floor_quotient ${NUM_SRC_FILE} ${CSV_CONVERT_BATCH_SIZE}`

}




function csv_convert_1()
{
    add_log "I" "Convert csv file to \"insert into values\" sql file"

    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"

    if [ ! -f ${CSV_CONVERT_TMP_DIR}/tmpfifo ]; then
        add_log "D" "Creating tmp fifo: mkfifo ${CSV_CONVERT_TMP_DIR}/tmpfifo"
        mkfifo ${CSV_CONVERT_TMP_DIR}/tmpfifo
    fi
    exec 9<>${CSV_CONVERT_TMP_DIR}/tmpfifo
    
    cpu_cores=`get_cpu_cores`

    # thread numbers to run in parallel, 3/4 of total cpu cores
    let THREAD_NUM=${cpu_cores}*3/4

    # write some \n into &9, where one \n represents one thread
    for ((i=0;i<${THREAD_NUM};i++));do
        echo -ne "\n" 1>&9
    done 



    # e.g. 1201 / 10=120.10
    # p_int=121
    p_int=`echo "${ddl_lines}" | awk -F"." '{print $1}'`
    p_decimal=`echo "${ddl_lines}" | awk -F"." '{print $2}'`
    #echo  "$p_int"
    #echo  "$p_decimal"

    if [ "${p_decimal}" != "00" ]; then
        p_int=`echo "${p_int}+1" | bc`
    fi
    #echo  "$p_int"
    #echo  "$p_decimal"
    start_line=0

    for((i=0; i < ${LOOP_COUNT}; i++));do
        # control the number of threads
        read -u 9
        # run in multi-thread mode
        {
            TMP_DIR="${CSV_CONVERT_TMP_DIR}/${RUN_TAG}"
            mkdir -p ${CSV_FILE_TMP_DIR}
            sql_tmp_file="${TMP_DIR}/${FILE_NAME}_tmp_${i}.sql"
            start_line=`expr 1 + ${CSV_CONVERT_BATCH_SIZE} * ${i}`
            end_line=`expr ${start_line} + ${CSV_CONVERT_BATCH_SIZE} - 1`


            #echo "start_line: $start_line, end_line: $end_line"
            
            # seperate the csv file into ${p_int} ddl files of ${CSV_CONVERT_BATCH_SIZE} lines
            sed -n "${start_line}, ${end_line}p" "${CSV_CONVERT_SRC_FILE}" > ${sql_tmp_file}
            

            if [ "${add_quote}" == "y" ]; then

                os=`what_os`
                if [[ "${os}" == "Linux" ]]; then

                    # replace , with ","
                    # this line will work on MacOS: sed -i '' 's/,/","/g' ${sql_tmp_file}
                    sed -i 's/,/","/g' ${sql_tmp_file}
                
                    # replace \n with "),("
                    sed -i ':a;N;$!ba;s/\n/\"),(\"/g' "${sql_tmp_file}"
                  
                    # add "); to the end
                    echo "\");" >> "${sql_tmp_file}"

                    # add insert ddl to the head
                    sed -i "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} (${CSV_CONVERT_META_COLUMN_LIST}) values (\"" "${sql_tmp_file}"
                else

                    # replace , with ","
                    # this line will work on MacOS: sed -i '' 's/,/","/g' ${sql_tmp_file}
                    sed -i '' 's/,/","/g' ${sql_tmp_file}
                
                    # replace \n with "),("
                    sed -i '' ':a;N;$!ba;s/\n/\"),(\"/g' "${sql_tmp_file}"
                  
                    # add "); to the end
                    echo "\");" >> "${sql_tmp_file}"

                    # add insert ddl to the head
                    sed -i '' "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} (${CSV_CONVERT_META_COLUMN_LIST}) values (\"" "${sql_tmp_file}"
                fi

            else

                # replace \n with ),(
                sed -i ':a;N;$!ba;s/\n/),(/g' "${sql_tmp_file}"
                
                # add "); to the end
                echo ");" >> "${sql_tmp_file}"
               
                # add insert ddl to the head
                sed -i "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} (${CSV_CONVERT_META_COLUMN_LIST}) values (" "${sql_tmp_file}"
      
            fi

            # no \n
            sed -i ':a;N;$!ba;s/\n//g' "${sql_tmp_file}"
            
            # repalce NaN with 'NaN' : nan -> "nan"
            sed -i 's|(nan|(\"nan\"|g' "${sql_tmp_file}"
            sed -i 's|,nan,|\",nan,\"|g' "${sql_tmp_file}"
            sed -i 's|nan)|\"nan\")|g' "${sql_tmp_file}"

            # write a \n into tmpfifo
            echo -ne "\n" 1>&9

        } &
    done
    # wait until all threads are done
    wait

    for((i=0; i < ${LOOP_COUNT}; i++));do
        # merge all tmp files and remove them
        sql_tmp_file="${TMP_DIR}/${FILE_NAME}_tmp_${i}.sql"
        cat "${sql_tmp_file}" >> "${TGT_FILE}"
        rm -f "${sql_tmp_file}"
    done

    rm -f ${TEST_DIR}/tmpfifo

    add_log "I" "Finished"

}

function csv_convert_2()
{

    add_log "I" "Convert csv file to \"load data inline format='csv' (single line) \" sql file"

    add_log "I" "Finished"

}


function csv_convert_3()
{
    add_log "I" "Convert csv file to \"load data inline format='csv' (multiple lines) \" sql file"

    for ((i=0;i<${LOOP_COUNT};i++)); do
        add_log "D" "Loop number: ${i}"
        let start_line=1+${CSV_CONVERT_BATCH_SIZE}*${i}
        let end_line=${start_line}+${CSV_CONVERT_BATCH_SIZE}-1

        echo "load data inline format='csv', data=\$XXX\$" >> ${TGT_FILE}
        sed -n "${start_line},${end_line}p" ${CSV_CONVERT_SRC_FILE} >> ${TGT_FILE}
        echo "\$XXX\$" >> ${TGT_FILE}
        if [[ "${CSV_CONVERT_META_COLUMN_LIST}" == "" ]]; then
            echo "into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE};" >> ${TGT_FILE}
        else
            echo "into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE}(${CSV_CONVERT_META_COLUMN_LIST});" >> ${TGT_FILE}
        fi

    done
    add_log "I" "Finished"

}



function csv_convert()
{
    add_log "I" "Checking pre-requisites..."
    if ! csv_convert_precheck; then
        add_log "E" "At lease one pre-requisite does not meet, please check configurations again."
        return 1
    fi

    add_log "I" "Please make sure above configurations are correct, continue? (Yes/No)"
    read -t 30 user_confirm
    if [[ "$(to_lower ${user_confirm})" != "yes" ]]; then
        add_log "E" "User input not confirmed or timed out, exiting"
        return 1
    fi

    add_log "I" "Conversion begins, this may take a while depending on the size of source file and processing ability of your machine. Please wait..."


    # what type is it
    case "${CSV_CONVERT_TYPE}" in
        "1")
            convert_type="insert"
            ! csv_convert_prep ${convert_type} && return 1
            ! csv_convert_1 && return 1
            ;;
        "2")
            convert_type="load-singleline"
            ! csv_convert_prep ${convert_type} && return 1
            ! csv_convert_2 && return 1
            ;;
        "3")
            convert_type="load-multilines"
            ! csv_convert_prep ${convert_type} && return 1
            ! csv_convert_3 && return 1
            ;;
        *)
            return 1
        ;;
    esac


    # what transcation type is it
    if [[ "${CSV_CONVERT_TN_TYPE}" == "2" ]]; then
        echo "commit;" >> ${TGT_FILE}
    fi


    add_log "I" "Conversion ends, please check file: ${TGT_FILE}"


}
