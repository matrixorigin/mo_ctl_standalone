# `auto_log_rotate`
## 1. 作用
针对mo数据库进程的日志文件，按一定的规则进行切分，避免文件过大

## 2. 用法
```bash
Usage           : mo_ctl auto_log_rotate [option]            # 设置数据库日志文件自动切分
Options         : 
  [option]      : enable | disable | status(default)
```


## 3. 前提条件
请先设置相关的参数，说明如下：
```bash
mo_ctl set_conf MO_LOG_AUTO_SPLIT='daily' # 可选，基于按日切分，或按文件大小切分，可选值：'daily' (默认) | 'size'，其中：
  'daily': 按日切分
  'size': 按文件大小切分，文件大小设置参数为 MO_LOG_MAX_SIZE
mo_ctl set_conf MO_LOG_MAX_SIZE="1024M" # 可选，当MO_LOG_AUTO_SPLIT=size时有效，格式为[size][unit], 默认值：1024M，其中：
  1. [size]: 文件大小阈值，
  2. [unit]: 文件大小单位：可选值：留空（bytes,default), k(kilobytes), M(megabytes), G(gigabytes)
mo_ctl set_conf MO_LOG_RESERVE_NUM=10000 # 可选，保留的日志文件个数
```


***注意***：如果对相关参数进行了重新设置，需要先禁用（`disable`），再启用（`enable`），新的配置才能生效

## 4. 示例
### 4.1 按周期自动切分日志文件
1、检查是否启用日志自动切分功能
```bash
 mo_ctl auto_log_rotate 
 # 或者：mo_ctl auto_log_rotate status
```

如果已启用，先禁用
```bash
 mo_ctl auto_log_rotate disable
```



2、设置相关参数，例如：
```bash
mo_ctl set_conf MO_LOG_AUTO_SPLIT=daily # 按天切分日志
mo_ctl set_conf MO_LOG_RESERVE_NUM=1000 # 保留1000个文件
mo_ctl auto_log_rotate
```

3、启用日志自动切分功能
```bash
mo_ctl auto_log_rotate enable
```

示例输出：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl auto_log_rotate
2025-01-08 16:54:38.628 UTC+0800    [DEBUG]    Current OS: Linux
2025-01-08 16:54:38.635 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate already exists, trying to get content: 
2025-01-08 16:54:38.641 UTC+0800    [DEBUG]    /data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
size 10M
compress
rotate 100
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
2025-01-08 16:54:38.647 UTC+0800    [INFO]    auto_log_rotate status：enabled

github@shpc2-10-222-1-9:~$ mo_ctl auto_log_rotate disable
2025-01-08 16:55:02.252 UTC+0800    [DEBUG]    Current OS: Linux
2025-01-08 16:55:02.257 UTC+0800    [INFO]    Check if logrotate command exists
2025-01-08 16:55:02.265 UTC+0800    [INFO]    Command 'which logrotate' did not found logrotate, but found file '/usr/sbin/logrotate'
2025-01-08 16:55:02.271 UTC+0800    [INFO]    Check if current user has sudo command, you may need to enter password for current user
2025-01-08 16:55:02.279 UTC+0800    [INFO]    Check related confs as below:
MO_LOG_AUTO_SPLIT="size"
MO_LOG_MAX_SIZE="10M"
MO_LOG_RESERVE_NUM="100"
2025-01-08 16:55:02.291 UTC+0800    [DEBUG]    LOG_SPLIT_STRATEGY=size 10M
2025-01-08 16:55:02.296 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate already exists, trying to get content: 
2025-01-08 16:55:02.302 UTC+0800    [DEBUG]    /data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
size 10M
compress
rotate 100
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
2025-01-08 16:55:02.307 UTC+0800    [INFO]    auto_log_rotate status：enabled
2025-01-08 16:55:02.313 UTC+0800    [INFO]    Disabling auto_log_rotate by removing cron file /etc/logrotate.d/mo-service
2025-01-08 16:55:02.322 UTC+0800    [INFO]    Succeeded
2025-01-08 16:55:02.327 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate does not exist
2025-01-08 16:55:02.333 UTC+0800    [INFO]    auto_log_rotate status：disabled

github@shpc2-10-222-1-9:~$ mo_ctl set_conf MO_LOG_AUTO_SPLIT=daily
2025-01-08 16:55:42.456 UTC+0800    [DEBUG]    conf list: MO_LOG_AUTO_SPLIT=daily
2025-01-08 16:55:42.464 UTC+0800    [INFO]    Try to set conf: MO_LOG_AUTO_SPLIT="daily"
2025-01-08 16:55:42.470 UTC+0800    [DEBUG]    key: MO_LOG_AUTO_SPLIT, value: daily
2025-01-08 16:55:42.476 UTC+0800    [INFO]    Setting conf MO_LOG_AUTO_SPLIT="daily"
github@shpc2-10-222-1-9:~$ mo_ctl set_conf MO_LOG_RESERVE_NUM=1000 # 保留1000个文件
2025-01-08 16:55:55.653 UTC+0800    [DEBUG]    conf list: MO_LOG_RESERVE_NUM=1000
2025-01-08 16:55:55.661 UTC+0800    [INFO]    Try to set conf: MO_LOG_RESERVE_NUM="1000"
2025-01-08 16:55:55.667 UTC+0800    [DEBUG]    key: MO_LOG_RESERVE_NUM, value: 1000
2025-01-08 16:55:55.673 UTC+0800    [INFO]    Setting conf MO_LOG_RESERVE_NUM="1000"
github@shpc2-10-222-1-9:~$ mo_ctl auto_log_rotate enable
2025-01-08 16:56:00.845 UTC+0800    [DEBUG]    Current OS: Linux
2025-01-08 16:56:00.850 UTC+0800    [INFO]    Check if logrotate command exists
2025-01-08 16:56:00.856 UTC+0800    [INFO]    Command 'which logrotate' did not found logrotate, but found file '/usr/sbin/logrotate'
2025-01-08 16:56:00.862 UTC+0800    [INFO]    Check if current user has sudo command, you may need to enter password for current user
2025-01-08 16:56:00.871 UTC+0800    [INFO]    Check related confs as below:
MO_LOG_AUTO_SPLIT="daily"
MO_LOG_MAX_SIZE="10M"
MO_LOG_RESERVE_NUM="1000"
2025-01-08 16:56:00.882 UTC+0800    [DEBUG]    LOG_SPLIT_STRATEGY=daily
2025-01-08 16:56:00.888 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate does not exist
2025-01-08 16:56:00.893 UTC+0800    [INFO]    auto_log_rotate status：disabled
2025-01-08 16:56:00.898 UTC+0800    [DEBUG]    Writing content to /etc/logrotate.d/mo-service
/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
daily
compress
rotate 1000
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
2025-01-08 16:56:00.956 UTC+0800    [INFO]    Password of current user may be required to execute command in sudo mode
2025-01-08 16:56:00.961 UTC+0800    [DEBUG]    Command: sudo touch /etc/logrotate.d/mo-service
2025-01-08 16:56:00.972 UTC+0800    [DEBUG]    sudo chmod 777 /etc/logrotate.d/mo-service
2025-01-08 16:56:00.981 UTC+0800    [DEBUG]    Command:
sudo cat > /etc/logrotate.d/mo-service << EOF
/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
daily
compress
rotate 1000
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
EOF
2025-01-08 16:56:01.054 UTC+0800    [DEBUG]    sudo chmod 644 /etc/logrotate.d/mo-service
2025-01-08 16:56:01.063 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate already exists, trying to get content: 
2025-01-08 16:56:01.069 UTC+0800    [DEBUG]    /data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
daily
compress
rotate 1000
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
2025-01-08 16:56:01.074 UTC+0800    [INFO]    auto_log_rotate status：enabled

```

### 4.2 按文件大小自动切分日志文件
其余步骤与4.1相同，主要是第2步设置参数稍有不同，例如按100M作为自动切分的文件大小阈值，保留1000个文件：
```bash
mo_ctl set_conf MO_LOG_MAX_SIZE=100M # 文件大小阈值为100M
mo_ctl set_conf MO_LOG_RESERVE_NUM=1000 #保留1000个文件
```

示例输出：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl auto_log_rotate enable
2025-01-08 16:59:14.517 UTC+0800    [DEBUG]    Current OS: Linux
2025-01-08 16:59:14.522 UTC+0800    [INFO]    Check if logrotate command exists
2025-01-08 16:59:14.528 UTC+0800    [INFO]    Command 'which logrotate' did not found logrotate, but found file '/usr/sbin/logrotate'
2025-01-08 16:59:14.534 UTC+0800    [INFO]    Check if current user has sudo command, you may need to enter password for current user
2025-01-08 16:59:14.543 UTC+0800    [INFO]    Check related confs as below:
MO_LOG_AUTO_SPLIT="size"
MO_LOG_MAX_SIZE="10M"
MO_LOG_RESERVE_NUM="1000"
2025-01-08 16:59:14.554 UTC+0800    [DEBUG]    LOG_SPLIT_STRATEGY=size 10M
2025-01-08 16:59:14.559 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate does not exist
2025-01-08 16:59:14.565 UTC+0800    [INFO]    auto_log_rotate status：disabled
2025-01-08 16:59:14.570 UTC+0800    [DEBUG]    Writing content to /etc/logrotate.d/mo-service
/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
size 10M
compress
rotate 1000
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
2025-01-08 16:59:14.628 UTC+0800    [INFO]    Password of current user may be required to execute command in sudo mode
2025-01-08 16:59:14.633 UTC+0800    [DEBUG]    Command: sudo touch /etc/logrotate.d/mo-service
2025-01-08 16:59:14.642 UTC+0800    [DEBUG]    sudo chmod 777 /etc/logrotate.d/mo-service
2025-01-08 16:59:14.650 UTC+0800    [DEBUG]    Command:
sudo cat > /etc/logrotate.d/mo-service << EOF
/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
size 10M
compress
rotate 1000
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
EOF
2025-01-08 16:59:14.723 UTC+0800    [DEBUG]    sudo chmod 644 /etc/logrotate.d/mo-service
2025-01-08 16:59:14.731 UTC+0800    [DEBUG]    Cron file /etc/logrotate.d/mo-service for auto_log_rotate already exists, trying to get content: 
2025-01-08 16:59:14.737 UTC+0800    [DEBUG]    /data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/*.log {
size 10M
compress
rotate 1000
copytruncate
missingok
notifempty
dateext
dateformat -%Y%m%d_%H%M%S
}
2025-01-08 16:59:14.742 UTC+0800    [INFO]    auto_log_rotate status：enabled
```