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
OS=""
RUN_TAG=""
TMP_DIR=""

function csv_convert_precheck()
{
    add_log "I" "Reading conf settings: "
    get_conf | grep CSV

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


    # 4. In case of parallel mode, create tmp fifo file and write some contents
    # tmpfifo file
    if [ ! -f ${CSV_CONVERT_TMP_DIR}/tmpfifo ]; then
        add_log "D" "Creating tmp fifo: mkfifo ${CSV_CONVERT_TMP_DIR}/tmpfifo"
        mkfifo ${CSV_CONVERT_TMP_DIR}/tmpfifo
    fi
    exec 9<>${CSV_CONVERT_TMP_DIR}/tmpfifo
    
    cpu_cores=`get_cpu_cores`

    # thread numbers to run in parallel, 3/4 of total cpu cores
    let THREAD_NUM=${cpu_cores}*3/4

    if [[ ${LOOP_COUNT} -le ${THREAD_NUM} ]]; then
        THREAD_NUM=1
    fi

    # write some \n into &9, where one \n represents one thread
    for ((i=0;i<${THREAD_NUM};i++));do
        echo -ne "\n" 1>&9
    done 

    RUN_TAG="$(date "+%Y%m%d_%H%M%S")"
    TMP_DIR="${CSV_CONVERT_TMP_DIR}/${RUN_TAG}"
    mkdir -p ${TMP_DIR}

}


function csv_convert_parallel_merge_and_clean()
{
    add_log "D" "Merging ${LOOP_COUNT} number of tmp files under ${TMP_DIR} to ${TGT_FILE}"
    for((i=0; i < ${LOOP_COUNT}; i++)); do
        # merge all tmp files and remove them
        sql_tmp_file="${TMP_DIR}/${FILE_NAME}_tmp_${i}.sql"
        cat "${sql_tmp_file}" >> "${TGT_FILE}"
        rm -f "${sql_tmp_file}"
    done

    add_log "D" "Cleaning ${CSV_CONVERT_TMP_DIR}/tmpfifo and ${TMP_DIR}"
    rm -f ${CSV_CONVERT_TMP_DIR}/tmpfifo
    rmdir ${TMP_DIR}
}


# convert csv file to batch insert format
# 1) source file:
# 1,Aron,99.8
# 2,Betty,77.6
# 3,Cindy,100.0
# 2) target file"
# insert into school.student (id,name,grade) values ("1","Aron","99.5");
# insert into school.student (id,name,grade) values ("2","Betty","88.8");
# insert into school.student (id,name,grade) values ("3","Cindy","100.0");
function csv_convert_insert_parallel()
{


    add_log "I" "Convert csv file to \"insert into db.table(col1,col2,...,coln) values (val1,val2,...,valn)\" sql file"

    for((i=0; i < ${LOOP_COUNT}; i++));do

        add_log "D" "Loop number: ${i}"

        # control threads
        read -u 9
        # run in multi-thread mode
        {
            sql_tmp_file="${TMP_DIR}/${FILE_NAME}_tmp_${i}.sql"
            let start_line=1+${CSV_CONVERT_BATCH_SIZE}*${i}
            let end_line=${start_line}+${CSV_CONVERT_BATCH_SIZE}-1

            # seperate the csv file into ${LOOP_COUNT} tmp files of ${CSV_CONVERT_BATCH_SIZE} lines
            sed -n "${start_line}, ${end_line}p" "${CSV_CONVERT_SRC_FILE}" > ${sql_tmp_file}
            

            if [ "${CSV_CONVERT_INSERT_ADD_QUOTE}" == "yes" ]; then

                if [[ "${OS}" == "Linux" ]]; then

                    # replace , with ","
                    # this line will work on MacOS: sed -i '' 's/,/","/g' ${sql_tmp_file}
                    sed -i 's/,/","/g' ${sql_tmp_file}
                
                    # replace \n with "),("
                    sed -i ':a;N;$!ba;s/\n/\"),(\"/g' "${sql_tmp_file}"
                  
                    # add "); to the end
                    echo "\");" >> "${sql_tmp_file}"

                    # add insert ddl to the head
                    if [[ "${CSV_CONVERT_META_COLUMN_LIST}" != "" ]]; then 
                        sed -i "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} (${CSV_CONVERT_META_COLUMN_LIST}) values (\"" "${sql_tmp_file}"
                    else
                        sed -i "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} values (\"" "${sql_tmp_file}"
                    fi
                else

                    # replace , with ","
                    # this line will work on MacOS: sed -i '' 's/,/","/g' ${sql_tmp_file}
                    sed -i '' 's/,/","/g' ${sql_tmp_file}
                
                    # replace \n with "),("
                    sed -i '' ':a;N;$!ba;s/\n/\"),(\"/g' "${sql_tmp_file}"
                  
                    # add "); to the end
                    echo "\");" >> "${sql_tmp_file}"

                    # add insert ddl to the head
                    if [[ "${CSV_CONVERT_META_COLUMN_LIST}" != "" ]]; then 
                        sed -i "" "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} (${CSV_CONVERT_META_COLUMN_LIST}) values (\"" "${sql_tmp_file}"
                    else
                        sed -i "" "1i\insert into ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE} values (\"" "${sql_tmp_file}"
                    fi

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

    csv_convert_parallel_merge_and_clean

    add_log "I" "Finished"

}




# convert to batch load
# line_mode=single: 
#     load data inline format='csv', data='1\n2\n' into table db_1.tb_1;
# line_mode=multi:
#     load data  inline format='csv', data=$XXX$
#     1,2,3
#     11,22,33
#     111,222,333
#     $XXX$ 
#     into table db_1.tb_1;
function csv_convert_load_serial()
{
    # multi or single
    line_mode="$1"

    add_log "I" "Convert csv file to \"load data inline format='csv' (multiple lines) \" sql file"

    for ((i=0;i<${LOOP_COUNT};i++)); do
        add_log "D" "Loop number: ${i}"
        let start_line=1+${CSV_CONVERT_BATCH_SIZE}*${i}
        let end_line=${start_line}+${CSV_CONVERT_BATCH_SIZE}-1


        if [[ "${line_mode}" == "single" ]]; then
            echo -n "load data inline format='csv', data='" >> ${TGT_FILE}
            # get batch size lines and replace char \n with string \\n
            sed -n "${start_line},${end_line}p" ${CSV_CONVERT_SRC_FILE} | ':a;N;$!ba;s/\n/\\n/g' >> ${TGT_FILE}
            if [[ "${CSV_CONVERT_META_COLUMN_LIST}" == "" ]]; then
                echo "' into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE};" >> ${TGT_FILE}
            else
                echo "' into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE}(${CSV_CONVERT_META_COLUMN_LIST});" >> ${TGT_FILE}
            fi
        else
            echo "load data inline format='csv', data=\$XXX\$" >> ${TGT_FILE}
            sed -n "${start_line},${end_line}p" ${CSV_CONVERT_SRC_FILE} >> ${TGT_FILE}
            echo "\$XXX\$" >> ${TGT_FILE}
            if [[ "${CSV_CONVERT_META_COLUMN_LIST}" == "" ]]; then
                echo "into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE};" >> ${TGT_FILE}
            else
                echo "into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE}(${CSV_CONVERT_META_COLUMN_LIST});" >> ${TGT_FILE}
            fi
        fi

    done
    add_log "I" "Finished"

}

function csv_convert_load_parallel()
{

    # multi or single
    line_mode="$1"

    add_log "I" "Convert csv file to \"load data inline format='csv' (multiple lines) \" sql file"

    for((i=0; i < ${LOOP_COUNT}; i++));do

        add_log "D" "Loop number: ${i}"

        # control threads
        read -u 9
        # run in multi-thread mode
        {
            sql_tmp_file="${TMP_DIR}/${FILE_NAME}_tmp_${i}.sql"
            let start_line=1+${CSV_CONVERT_BATCH_SIZE}*${i}
            let end_line=${start_line}+${CSV_CONVERT_BATCH_SIZE}-1

            # seperate the csv file into ${LOOP_COUNT} tmp files of ${CSV_CONVERT_BATCH_SIZE} lines
            sed -n "${start_line}, ${end_line}p" "${CSV_CONVERT_SRC_FILE}" > ${sql_tmp_file}
            
            # sed to replace/add the content of tmp files
            # format:
            # 1) single line
            # load data inline format='csv', data='1\n2\n' into table db_1.tb_1;
            if [[ "${line_mode}" == "single" ]]; then
                # replace char \n with string \\n

                if [[ "${OS}" == "Linux" ]]; then
                    # replace , with ","
                    # this line will work on MacOS: sed -i '' 's/,/","/g' ${sql_tmp_file}

                    sed -i ':a;N;$!ba;s/\n/\\n/g' ${sql_tmp_file}
                    # add to the beginning
                    sed -i "s#^#load data inline format='csv', data='#g" ${sql_tmp_file}
                    # add to the end
                    if [[ "${CSV_CONVERT_META_COLUMN_LIST}" == "" ]]; then
                        sed -i "s#\$# into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE};#g" ${sql_tmp_file}
                    else
                        sed -i "s#\$# into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE}(${CSV_CONVERT_META_COLUMN_LIST});#g" ${sql_tmp_file}
                    fi
                else
                    sed -i "" ':a;N;$!ba;s/\n/\\n/g' ${sql_tmp_file}
                    # add to the beginning
                    sed -i "" "s#^#load data inline format='csv', data='#g" ${sql_tmp_file}
                    # add to the end
                    if [[ "${CSV_CONVERT_META_COLUMN_LIST}" == "" ]]; then
                        sed -i "" "s#\$# into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE};#g" ${sql_tmp_file}
                    else
                        sed -i "" "s#\$# into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE}(${CSV_CONVERT_META_COLUMN_LIST});#g" ${sql_tmp_file}
                    fi
                fi
            # 2) multi lines
            # load data inline format='csv', data=$XXX$
            # 1,2,3
            # 11,22,33
            # 111,222,333
            # $XXX$ 
            # into table db_1.tb_1;
            else
                if [[ "${OS}" == "Linux" ]]; then
                    sed -i "1iload data inline format='csv', data=\$XXX\$" ${sql_tmp_file}
                else
                    sed -i "" "1iload data inline format='csv', data=\$XXX\$" ${sql_tmp_file}
                fi
                echo "\$XXX\$" >> ${sql_tmp_file}
                if [[ "${CSV_CONVERT_META_COLUMN_LIST}" == "" ]]; then
                    echo "into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE};" >> ${sql_tmp_file}
                else
                    echo "into table ${CSV_CONVERT_META_DB}.${CSV_CONVERT_META_TABLE}(${CSV_CONVERT_META_COLUMN_LIST});" >> ${sql_tmp_file}
                fi

            fi

            # write a \n into tmpfifo
            echo -ne "\n" 1>&9

        } &
    done
    # wait until all threads are done
    wait

    csv_convert_parallel_merge_and_clean

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

    # run in parallel or serial
    run_mode="parallel"
    
    OS=`what_os`

    # what type is it
    case "${CSV_CONVERT_TYPE}" in
        "1")
            convert_type="insert"
            ! csv_convert_prep ${convert_type} && return 1
            ! csv_convert_insert_${run_mode} && return 1
            ;;
        "2")
            line_mode="single"
            convert_type="load-singleline"
            ! csv_convert_prep ${convert_type} && return 1
            ! csv_convert_load_${run_mode} "${line_mode}" && return 1
            ;;
        "3")
            line_mode="multi"
            convert_type="load-multilines"
            ! csv_convert_prep ${convert_type} && return 1
            ! csv_convert_load_${run_mode} "${line_mode}" && return 1
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
