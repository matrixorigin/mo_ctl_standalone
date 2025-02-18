# `uninstall`
## 1. 作用
卸载当前服务器上的单机mo

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl uninstall help
Usage           : mo_ctl uninstall        # uninstall mo from path MO_PATH=/data/mo/20230629/matrixone
Note            : You will need to input 'Yes/No' to confirm before uninstalling
```
## 3. 前提条件
（谨慎操作！！！）卸载前，请确认以下条件：
1、MO已停止
```bash
mo_ctl status

github@shpc2-10-222-1-9:~$ mo_ctl status
2025-02-10 11:49:04.496 UTC+0800    [INFO]    No mo-service is running
```

2、mo_ctl watchdog 已禁用
```bash
mo_ctl watchdog

2025-02-10 11:50:00.476 UTC+0800    [DEBUG]    Get status of service cron
2025-02-10 11:50:00.485 UTC+0800    [DEBUG]    Succeeded. Service cron seems to be running.
2025-02-10 11:50:00.491 UTC+0800    [INFO]    watchdog status：disabled
```

## 4 示例
```bash
github@shpc2-10-222-1-9:~$ mo_ctl uninstall
2025-02-10 11:50:21.206 UTC+0800    [WARN]    You're uninstalling MO from path /data/cus_reg/mo/20250210_070243/matrixone, are you sure? (Yes/No)
yes
2025-02-10 11:50:22.527 UTC+0800    [INFO]    Checking pre-requisites before uninstalling MO
2025-02-10 11:50:22.532 UTC+0800    [INFO]    Check if mo-service running
2025-02-10 11:50:22.573 UTC+0800    [INFO]    Check if mo-service watchdog enabled
2025-02-10 11:50:22.597 UTC+0800    [DEBUG]    Get status of service cron
2025-02-10 11:50:22.607 UTC+0800    [DEBUG]    Succeeded. Service cron seems to be running.
2025-02-10 11:50:22.612 UTC+0800    [INFO]    watchdog status：disabled
2025-02-10 11:50:22.618 UTC+0800    [INFO]    Check pre-requisites before uninstalling succeeded
2025-02-10 11:50:22.624 UTC+0800    [INFO]    Uninstall MO succeeded.
```