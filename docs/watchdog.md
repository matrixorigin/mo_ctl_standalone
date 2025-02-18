# `watchdog`
## 1. 作用
设置一个看门狗，用户守护本地mo服务进程

## 2. 用法
```bash
github@shpc2-10-222-1-9:~$ mo_ctl watchdog help
Usage           : mo_ctl watchdog [option]    # setup a watchdog crontab task for mo-service to keep it alive
Options         :
 [option]       : (optional, default: status) available: enable | disable | status
Examples        : mo_ctl watchdog enable      # enable watchdog service for mo, by default it will check if mo-servie is alive and pull it up if it's dead every one minute
                  mo_ctl watchdog disable     # disable watchdog
                  mo_ctl watchdog status      # check if watchdog is enabled or disabled
                  mo_ctl watchdog             # same as mo_ctl watchdog status
```

## 3. 前提条件
Linux服务端已启用`crontab`服务，Mac服务端已启动`launchctl`服务

## 4. 示例
### 4.1 查看状态（`status`）
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl watchdog 
2025-02-18 16:00:55.523 UTC+0800    [INFO]    watchdog status：disabled
github@shpc2-10-222-1-9:/data$ mo_ctl watchdog status
2025-02-18 16:00:57.880 UTC+0800    [INFO]    watchdog status：disabled
```

### 4.2 启用（`enable`）
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl watchdog enable
2025-02-18 16:01:07.222 UTC+0800    [INFO]    watchdog status：disabled
2025-02-18 16:01:07.233 UTC+0800    [INFO]    Creating cron file /etc/cron.d/mo_watchdog
2025-02-18 16:01:07.238 UTC+0800    [INFO]    Content: * * * * * github ! /usr/local/bin/mo_ctl status && /usr/local/bin/mo_ctl start
2025-02-18 16:01:07.276 UTC+0800    [INFO]    Succeeded
2025-02-18 16:01:07.311 UTC+0800    [INFO]    watchdog status：enabled
```

### 4.3 禁用（`disable`）
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl watchdog disable
2025-02-18 16:01:15.329 UTC+0800    [INFO]    watchdog status：enabled
2025-02-18 16:01:15.334 UTC+0800    [INFO]    Disabling watchdog by removing cron file /etc/cron.d/mo_watchdog
2025-02-18 16:01:15.343 UTC+0800    [INFO]    Succeeded
2025-02-18 16:01:15.364 UTC+0800    [INFO]    watchdog status：disabled
```