# `set_conf`
## 1. 作用
设置`mo_ctl`工具的配置项和设置值。

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl set_conf help
Usage         : mo_ctl set_conf [setting] # set configurations
Options       :
  [setting]   : (required) choose one of below
                1. conf setting in 'key=value' format, only single conf is supported
                2. 'reset', reset all currently confs back to default values (!!!DANGEROUS!!!)
Examples      : mo_ctl set_conf MO_PATH=/data/mo/20230629
                mo_ctl set_conf BACKUP_CRON_SCHEDULE="30 23 * * *"             # in case your conf value contains a special character like '*', use double " to quote it
                mo_ctl set_conf MO_LOG_PATH="\${MO_PATH}/matrixone/logs"      # in case your conf value contains a special character like '$', use double " and \ to quote it
                mo_ctl set_conf reset                                            # reset all confs to default, note this could be DANGEROUS as all of your current settings will be lost and reset to default values. Use it very carefully!!!
```
## 3. 前提条件
无

## 4. 示例
设置某个配置项
```bash
github@shpc2-10-222-1-9:~$ mo_ctl set_conf MO_PATH=/data/mo/20230629
2025-01-21 16:46:33.816 UTC+0800    [DEBUG]    conf list: MO_PATH=/data/mo/20230629
2025-01-21 16:46:33.824 UTC+0800    [INFO]    Try to set conf: MO_PATH="/data/mo/20230629"
2025-01-21 16:46:33.830 UTC+0800    [DEBUG]    key: MO_PATH, value: /data/mo/20230629
2025-01-21 16:46:33.836 UTC+0800    [INFO]    Setting conf MO_PATH="/data/mo/20230629"
```

基于某个配置项的值，设置另外一个配置项，例如根据`MO_PATH`的值设置`MO_CONF_FILE`的值，注意`\$`中`$`前面需要反引号`\`
```bash
github@shpc2-10-222-1-9:~$ mo_ctl set_conf MO_CONF_FILE="\${MO_PATH}/matrixone/etc/launch/launch.toml"
2025-01-21 16:48:36.866 UTC+0800    [DEBUG]    conf list: MO_CONF_FILE=${MO_PATH}/matrixone/etc/launch/launch.toml
2025-01-21 16:48:36.874 UTC+0800    [INFO]    Try to set conf: MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
2025-01-21 16:48:36.881 UTC+0800    [DEBUG]    key: MO_CONF_FILE, value: ${MO_PATH}/matrixone/etc/launch/launch.toml
2025-01-21 16:48:36.887 UTC+0800    [INFO]    Setting conf MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
```

（谨慎使用！！！）还原所有配置项为默认的配置
```bash
github@shpc2-10-222-1-9:~$ mo_ctl set_conf reset
2025-01-21 16:50:25.451 UTC+0800    [DEBUG]    conf list: reset
2025-01-21 16:50:25.456 UTC+0800    [INFO]    You're about to set all confs, which will be replaced by default settings. This could be dangerous since all of your current settings will be lost!!! Are you sure? (Yes/No)
yes
2025-01-21 16:50:27.030 UTC+0800    [INFO]    Reset all confs succeeded
```