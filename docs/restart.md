# `restart`
## 1. 作用
重启本地单机mo服务，即第一步先尝试停止，第二步再尝试启动。若第一步已有对应的mo服务在停止状态，则会略过停止。

## 2. 用法
```bash
mo_ctl restart [force]
```
- `force`：可选项，若添加，则会在第一步尝试强制停止。

## 3. 前提条件
无

## 4. 示例
### 1) `git`或`binary`部署模式
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl restart 
2025-01-21 15:03:24.581 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:05:07 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 15:03:24.586 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 15:03:24.591 UTC+0800    [INFO]    Try stop all mo-services found for a maximum of 10 times, try no: 1
2025-01-21 15:03:24.596 UTC+0800    [INFO]    Stopping mo-service with pid 3112216 with command: kill  3112216
2025-01-21 15:03:24.602 UTC+0800    [INFO]    Wait for 5 seconds
2025-01-21 15:03:29.621 UTC+0800    [INFO]    No mo-service is running
2025-01-21 15:03:29.626 UTC+0800    [INFO]    Stop succeeded
2025-01-21 15:03:29.632 UTC+0800    [INFO]    Wait for 2 seconds
2025-01-21 15:03:31.651 UTC+0800    [INFO]    No mo-service is running
2025-01-21 15:03:31.658 UTC+0800    [DEBUG]    Check total memory on current machine, command: free -m | awk 'NR==2{print }', result(Mi): 31808
2025-01-21 15:03:31.666 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="git"
2025-01-21 15:03:31.673 UTC+0800    [INFO]    GO memory limit(Mi): 9542
2025-01-21 15:03:31.678 UTC+0800    [DEBUG]    Start command will add GOMEMLIMIT=9542MiB
2025-01-21 15:03:31.684 UTC+0800    [INFO]    Starting mo-service: cd /data/cus_reg/mo/20250121_070243/matrixone/ && GOMEMLIMIT=9542MiB /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345  -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml >/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/stdout-20250121_150331.log 2>/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/stderr-20250121_150331.log
2025-01-21 15:03:31.736 UTC+0800    [INFO]    Wait for 2 seconds
2025-01-21 15:03:33.756 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3116231       1 25 15:03 ?        00:00:00 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 15:03:33.762 UTC+0800    [INFO]    List of pid(s): 
3116231
2025-01-21 15:03:33.767 UTC+0800    [INFO]    Start succeeded
```

### 2) `docker`部署模式
```bash
[github@HOST-10-222-4-2 ~]$ mo_ctl restart 
2025-01-21 15:03:54.839 UTC+0800    [INFO]    Check if container named mo-20250121_123938 is running
2025-01-21 15:03:55.300 UTC+0800    [INFO]    Info of: docker ps --no-trunc --filter name=mo-20250121_123938
CONTAINER ID                                                       IMAGE                     COMMAND                                                     CREATED       STATUS       PORTS                                                                                    NAMES
8dbac89e3024f5a1fd8234123a71275f3be0704a930f6a0d98f444b2bf5b3b0f   matrixone:main_daf9e93b   "/mo-service -debug-http :12345 -launch /etc/launch.toml"   2 hours ago   Up 2 hours   0.0.0.0:6001->6001/tcp, :::6001->6001/tcp, 0.0.0.0:9876->12345/tcp, :::9876->12345/tcp   mo-20250121_123938
2025-01-21 15:03:55.335 UTC+0800    [INFO]    Try stop all mo-services found for a maximum of 10 times, try no: 1
2025-01-21 15:03:55.363 UTC+0800    [INFO]    Stopping mo container: docker stop mo-20250121_123938
mo-20250121_123938
2025-01-21 15:04:07.462 UTC+0800    [INFO]    Wait for 5 seconds
2025-01-21 15:04:12.502 UTC+0800    [INFO]    Check if container named mo-20250121_123938 is running
2025-01-21 15:04:12.693 UTC+0800    [INFO]    No container named mo-20250121_123938 is running
2025-01-21 15:04:12.719 UTC+0800    [INFO]    Stop succeeded
2025-01-21 15:04:12.742 UTC+0800    [INFO]    Wait for 2 seconds
2025-01-21 15:04:14.782 UTC+0800    [INFO]    Check if container named mo-20250121_123938 is running
2025-01-21 15:04:14.917 UTC+0800    [INFO]    No container named mo-20250121_123938 is running
2025-01-21 15:04:14.964 UTC+0800    [DEBUG]    Check total memory on current machine, command: free -m | awk 'NR==2{print }', result(Mi): 15884
2025-01-21 15:04:15.007 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="docker"
2025-01-21 15:04:15.178 UTC+0800    [INFO]    Container named mo-20250121_123938 found. Start mo container: docker start mo-20250121_123938
mo-20250121_123938
```