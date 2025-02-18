# `csv_convert`
## 1. 作用
将一个`csv`格式的文件，转换成`insert`或`load data inline`格式的文件

## 2. 用法
```bash
root@test0 # mo_ctl csv_convert help
Usage           : mo_ctl csv_convert                        # convert a csv file to a sql file in format "insert into values" or "load data inline format='csv'"
Note: please set below configurations first before you run this option
      1. CSV_CONVERT_SRC_FILE: source csv file to convert, e.g. mo_ctl set_conf CSV_CONVERT_SRC_FILE="/data/test.csv"
      2. CSV_CONVERT_BATCH_SIZE: batch size of target file, note max batch size is limited to 100000000, e.g. mo_ctl set_conf CSV_CONVERT_BATCH_SIZE=8192
      3. CSV_CONVERT_TGT_DIR: a directory to generate target file, e.g. mo_ctl set_conf CSV_CONVERT_TGT_DIR=/data/target_dir/
      4. CSV_CONVERT_TYPE: [OPTIONAL, default: 3] convert type: 1|2|3, e.g. mo_ctl set_conf CSV_CONVERT_TYPE=3
          1: insert into values
          2: load data inline format='csv', data='1\n2\n' into table db_1.tb_1;
          3: 
              load data  inline format='csv', data=$XXX$
              1,2,3
              11,22,33
              111,222,333
              $XXX$ 
              into table db_1.tb_1;
      5. CSV_CONVERT_META_DB: database name, e.g. mo_ctl set_conf CSV_CONVERT_META_DB=school
      6. CSV_CONVERT_META_TABLE: table name, e.g. mo_ctl set_conf CSV_CONVERT_META_TABLE=student
      7. CSV_CONVERT_META_COLUMN_LIST: [OPTIONAL, default: empty] column list, seperated by ',' , e.g. mo_ctl set_conf CSV_CONVERT_META_COLUMN_LIST=id,name,age
      8. CSV_CONVERT_TN_TYPE: [OPTIONAL, default: 1] transaction type, choose from: 1|2, e.g. mo_ctl set_conf CSV_CONVERT_TN_TYPE=1
          1: multi transactions
          2: single transation(will add 'begin;' at first line and 'end;' at last line)
      9. CSV_CONVERT_TMP_DIR: [OPTIONAL, default: /tmp] a directory to contain temporary files, e.g. mo_ctl set_conf CSV_CONVERT_TMP_DIR=/tmp/
```

## 3. 前提条件
请先提前准备好`csv`源文件，并设置好相关的参数
```bash
mo_ctl set_conf CSV_CONVERT_SRC_FILE="/data/test.csv" # 设置csv源文件
mo_ctl set_conf CSV_CONVERT_BATCH_SIZE=8192 # 设置转换后的BatchSize大小，即每批insert或load data inline的数据行数
mo_ctl set_conf CSV_CONVERT_TGT_DIR=/data/target_dir/ # 设置目标存储目录
mo_ctl set_conf CSV_CONVERT_TYPE=3 # 设置转换后的格式类型，1为insert，2为单行格式的load data inline，3个多行格式的load data inline
mo_ctl set_conf CSV_CONVERT_META_DB="school" # 目标库的名称
mo_ctl set_conf CSV_CONVERT_META_TABLE="student" # 目标表的名称
mo_ctl set_conf CSV_CONVERT_META_COLUMN_LIST="id,name,age" # 目标表的列清单名称
mo_ctl set_conf CSV_CONVERT_TN_TYPE=1 # 事务类型，1为多事务，即隐式事务（每条SQL分别为单独一个事务下执行），2为单事务，即显示事务（所有SQL在同一个事务下执行）
mo_ctl set_conf CSV_CONVERT_TMP_DIR=/tmp/ # 存放转换过程中临时文件的目录
mo_ctl set_conf CSV_CONVERT_INSERT_ADD_QUOTE=no # 设置是否给每列的值前后添加引号
```

## 4 示例
准保好一个csv文件，内容如下：
```bash
github@shpc2-10-222-1-9:~$ cat /data/test.csv
1,A,33
2,B,23
3,C,88
4,D,27
5,E,67
```

设置好相关的参数：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_SRC_FILE="/data/test.csv" # 设置csv源文件
2025-02-10 11:42:00.866 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_SRC_FILE=/data/test.csv
2025-02-10 11:42:00.873 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_SRC_FILE="/data/test.csv"
2025-02-10 11:42:00.880 UTC+0800    [DEBUG]    key: CSV_CONVERT_SRC_FILE, value: /data/test.csv
2025-02-10 11:42:00.886 UTC+0800    [INFO]    Setting conf CSV_CONVERT_SRC_FILE="/data/test.csv"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_BATCH_SIZE=2 # 设置转换后的BatchSize大小，即每批insert或load data inline的数据行数
2025-02-10 11:42:06.191 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_BATCH_SIZE=2
2025-02-10 11:42:06.199 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_BATCH_SIZE="2"
2025-02-10 11:42:06.205 UTC+0800    [DEBUG]    key: CSV_CONVERT_BATCH_SIZE, value: 2
2025-02-10 11:42:06.211 UTC+0800    [INFO]    Setting conf CSV_CONVERT_BATCH_SIZE="2"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_TGT_DIR=/data/target_dir/ # 设置目标存储目录
2025-02-10 11:42:17.406 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_TGT_DIR=/data/target_dir/
2025-02-10 11:42:17.414 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_TGT_DIR="/data/target_dir/"
2025-02-10 11:42:17.420 UTC+0800    [DEBUG]    key: CSV_CONVERT_TGT_DIR, value: /data/target_dir/
2025-02-10 11:42:17.426 UTC+0800    [INFO]    Setting conf CSV_CONVERT_TGT_DIR="/data/target_dir/"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_TYPE=1 # 设置转换后的格式类型，1为insert，2为单行格式的load data inline，3个多行格式的load data inline
2025-02-10 11:42:20.194 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_TYPE=1
2025-02-10 11:42:20.202 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_TYPE="1"
2025-02-10 11:42:20.208 UTC+0800    [DEBUG]    key: CSV_CONVERT_TYPE, value: 1
2025-02-10 11:42:20.216 UTC+0800    [INFO]    Setting conf CSV_CONVERT_TYPE="1"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_META_DB="school" # 目标库的名称
2025-02-10 11:42:22.763 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_META_DB=school
2025-02-10 11:42:22.771 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_META_DB="school"
2025-02-10 11:42:22.777 UTC+0800    [DEBUG]    key: CSV_CONVERT_META_DB, value: school
2025-02-10 11:42:22.783 UTC+0800    [INFO]    Setting conf CSV_CONVERT_META_DB="school"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_META_TABLE="student" # 目标表的名称
2025-02-10 11:42:25.001 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_META_TABLE=student
2025-02-10 11:42:25.009 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_META_TABLE="student"
2025-02-10 11:42:25.016 UTC+0800    [DEBUG]    key: CSV_CONVERT_META_TABLE, value: student
2025-02-10 11:42:25.021 UTC+0800    [INFO]    Setting conf CSV_CONVERT_META_TABLE="student"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_META_COLUMN_LIST="id,name,age" # 目标表的列清单名称
2025-02-10 11:42:32.748 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_META_COLUMN_LIST=id,name,age
2025-02-10 11:42:32.756 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_META_COLUMN_LIST="id,name,age"
2025-02-10 11:42:32.762 UTC+0800    [DEBUG]    key: CSV_CONVERT_META_COLUMN_LIST, value: id,name,age
2025-02-10 11:42:32.768 UTC+0800    [INFO]    Setting conf CSV_CONVERT_META_COLUMN_LIST="id,name,age"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_TN_TYPE=1 # 事务类型，1为多事务，即隐式事务（每条SQL分别为单独一个事务下执行），2为单事务，即显示事务（所有SQL在同一个事务下执行）
2025-02-10 11:42:37.931 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_TN_TYPE=1
2025-02-10 11:42:37.938 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_TN_TYPE="1"
2025-02-10 11:42:37.945 UTC+0800    [DEBUG]    key: CSV_CONVERT_TN_TYPE, value: 1
2025-02-10 11:42:37.953 UTC+0800    [INFO]    Setting conf CSV_CONVERT_TN_TYPE="1"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_TMP_DIR=/tmp/ # 存放转换过程中临时文件的目录
2025-02-10 11:42:41.107 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_TMP_DIR=/tmp/
2025-02-10 11:42:41.115 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_TMP_DIR="/tmp/"
2025-02-10 11:42:41.122 UTC+0800    [DEBUG]    key: CSV_CONVERT_TMP_DIR, value: /tmp/
2025-02-10 11:42:41.127 UTC+0800    [INFO]    Setting conf CSV_CONVERT_TMP_DIR="/tmp/"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf CSV_CONVERT_INSERT_ADD_QUOTE=yes # 设置是否给每列的值前后添加引号
2025-02-10 11:45:57.902 UTC+0800    [DEBUG]    conf list: CSV_CONVERT_INSERT_ADD_QUOTE=yes
2025-02-10 11:45:57.910 UTC+0800    [INFO]    Try to set conf: CSV_CONVERT_INSERT_ADD_QUOTE="yes"
2025-02-10 11:45:57.916 UTC+0800    [DEBUG]    key: CSV_CONVERT_INSERT_ADD_QUOTE, value: yes
2025-02-10 11:45:57.924 UTC+0800    [INFO]    Setting conf CSV_CONVERT_INSERT_ADD_QUOTE="yes"
```

执行格式转换：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl csv_convert
2025-02-10 11:46:10.894 UTC+0800    [INFO]    Checking pre-requisites...
2025-02-10 11:46:10.899 UTC+0800    [INFO]    Reading conf settings: 
CSV_CONVERT_MAX_BATCH_SIZE=100000000
CSV_CONVERT_SRC_FILE="/data/test.csv"
CSV_CONVERT_BATCH_SIZE="2"
CSV_CONVERT_TGT_DIR="/data/target_dir/"
CSV_CONVERT_TYPE="1"
CSV_CONVERT_META_DB="school"
CSV_CONVERT_META_TABLE="student"
CSV_CONVERT_META_COLUMN_LIST="id,name,age"
CSV_CONVERT_TN_TYPE="1"
CSV_CONVERT_TMP_DIR="/tmp/"
CSV_CONVERT_INSERT_ADD_QUOTE="yes"
2025-02-10 11:46:10.912 UTC+0800    [INFO]    Please make sure above configurations are correct, continue? (Yes/No)
yes
2025-02-10 11:46:12.377 UTC+0800    [INFO]    Conversion begins, this may take a while depending on the size of source file and processing ability of your machine. Please wait...
2025-02-10 11:46:12.385 UTC+0800    [INFO]    Generate target file /data/target_dir//test_insert_tn-multi_2.sql
2025-02-10 11:46:12.391 UTC+0800    [INFO]    Counting number of lines in source file: /data/test.csv
2025-02-10 11:46:12.397 UTC+0800    [INFO]    Number of lines: 5
2025-02-10 11:46:12.405 UTC+0800    [DEBUG]    Creating tmp fifo: mkfifo /tmp//tmpfifo
2025-02-10 11:46:12.414 UTC+0800    [INFO]    Convert csv file to "insert into db.table(col1,col2,...,coln) values (val1,val2,...,valn)" sql file
2025-02-10 11:46:12.420 UTC+0800    [DEBUG]    Loop number: 0
2025-02-10 11:46:12.425 UTC+0800    [DEBUG]    Loop number: 1
2025-02-10 11:46:12.432 UTC+0800    [DEBUG]    Loop number: 2
2025-02-10 11:46:12.444 UTC+0800    [DEBUG]    Merging 3 number of tmp files under /tmp//20250210_114612 to /data/target_dir//test_insert_tn-multi_2.sql
2025-02-10 11:46:12.452 UTC+0800    [DEBUG]    Cleaning /tmp//tmpfifo and /tmp//20250210_114612
2025-02-10 11:46:12.458 UTC+0800    [INFO]    Finished
2025-02-10 11:46:12.463 UTC+0800    [INFO]    Conversion ends, please check file: /data/target_dir//test_insert_tn-multi_2.sql
```

查看格式转换后的文件：
```bash
github@shpc2-10-222-1-9:~$ cat /data/target_dir//test_insert_tn-multi_2.sql
insert into school.student (id,name,age) values ("1","A","33"),("2","B","23");
insert into school.student (id,name,age) values ("3","C","88"),("4","D","27");
insert into school.student (id,name,age) values ("5","E","67");
```
