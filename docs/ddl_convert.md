# `ddl_convert`
## 1. 作用
将一个mysql格式的文件，转换成mo格式的文件。
注：本功能已无需使用，mo目前能兼容大部分mysql格式的文件

## 2. 用法
```bash
github@shpc2-10-222-1-9:~$ mo_ctl ddl_convert help
Usage         : mo_ctl ddl_convert [option]  [src_file] [tgt_file] # convert a ddl file to mo format from other types of database
Options    :
  [option]    : (required) currently only supports 'mysql_to_mo'
  [src_file]  : (required) source file to be converted, will use env DDL_SRC_FILE from conf file by default
  [tgt_file]  : (required) target file of converted output, will use env DDL_TGT_FILE from conf file by default
Examples      : mo_ctl ddl_convert mysql_to_mo /tmp/mysql.sql /tmp/mo.sql
```

## 3. 前提条件
参考用法

## 4 示例
参考用法