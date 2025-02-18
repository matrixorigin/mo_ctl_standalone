# `pprof`
## 1. 作用
收集MO数据库相关的go profile信息，一般用于debug。

## 2. 用法
目前支持的profile类型有：`cpu`、`heap`、`allocs`、`goroutine`、`trace`、`malloc`，其中`cpu`和`trace`需要指定收集时间（单位：秒），默认为`30`秒。
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof help
Usage          : mo_ctl pprof [item] [duration] # collect pprof information
Options        : 1. [item] (optional, default: profile): Specify kind of profile to collect, available: cpu | heap | allocs | goroutine | trace | malloc
                 2. [duration] (optional, default: 30): Specify duration in seconds to collect the profile, only valid for 'cpu' and 'trace'
Example        : mo_ctl pprof         # collect cpu profile for 30s
                 mo_ctl pprof cpu     # same as above
                 mo_ctl pprof cpu 30  # same as above
                 mo_ctl pprof heap    # collect heap profile
```

## 3. 前提条件
MO已启动，且暴露了debug端口，其端口号可以通过配置项`MO_DEBUG_PORT`获取
```
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl status
2025-01-21 14:50:33.423 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:03:32 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:50:33.428 UTC+0800    [INFO]    List of pid(s): 
3112216
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf MO_DEBUG_PORT
2025-01-21 14:50:40.583 UTC+0800    [INFO]    Get conf succeeded: MO_DEBUG_PORT="12345"
```

此外，请确保收集后保存的目录已提前创建完成，可通过配置项`PPROF_OUT_PATH`查看
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf PPROF_OUT_PATH
2025-01-21 14:54:12.095 UTC+0800    [INFO]    Get conf succeeded: PPROF_OUT_PATH="/data/pprof-20241203"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mkdir -p /data/pprof-20241203
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ ls -ld /data/pprof-20241203
drwxr-xr-x 2 github github 471040 Jan 21 14:52 /data/pprof-20241203
```

## 4. 示例
### 1) 收集`cpu` profile
**示例1**：使用默认参数，收集`30s`
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl status
2025-01-21 14:50:33.423 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:03:32 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:50:33.428 UTC+0800    [INFO]    List of pid(s): 
3112216
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_conf MO_DEBUG_PORT
2025-01-21 14:50:40.583 UTC+0800    [INFO]    Get conf succeeded: MO_DEBUG_PORT="12345"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof
2025-01-21 14:51:26.788 UTC+0800    [INFO]    Option is not set, using default value: cpu
2025-01-21 14:51:26.794 UTC+0800    [INFO]    pprof option is profile
2025-01-21 14:51:26.799 UTC+0800    [INFO]    duration is not set, using conf value: 30
2025-01-21 14:51:26.805 UTC+0800    [INFO]    collect duration is 30 seconds
2025-01-21 14:51:26.823 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:03:38 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:51:26.829 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 14:51:26.834 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/profile-20250121_145126.pprof http://127.0.0.1:12345/debug/pprof/profile?seconds=30
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 30399    0 30399    0     0   1008      0 --:--:--  0:00:30 --:--:--  7739
2025-01-21 14:51:56.996 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/profile-20250121_145126.pprof
```

**示例2**：使用指定参数，收集`15s`
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof cpu 15
2025-01-21 14:52:31.469 UTC+0800    [INFO]    pprof option is profile
2025-01-21 14:52:31.475 UTC+0800    [INFO]    collect duration is 15 seconds
2025-01-21 14:52:31.494 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:03:46 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:52:31.499 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 14:52:31.504 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/profile-20250121_145231.pprof http://127.0.0.1:12345/debug/pprof/profile?seconds=15
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21755    0 21755    0     0   1441      0 --:--:--  0:00:15 --:--:--  5604
2025-01-21 14:52:46.607 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/profile-20250121_145231.pprof
```

### 2) 收集`heap` profile
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof heap
2025-01-21 14:56:12.352 UTC+0800    [INFO]    pprof option is heap
2025-01-21 14:56:12.371 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:04:14 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:56:12.376 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 14:56:12.381 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/heap-20250121_145612.pprof http://127.0.0.1:12345/debug/pprof/heap
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  227k    0  227k    0     0  7730k      0 --:--:-- --:--:-- --:--:-- 7857k
2025-01-21 14:56:12.421 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/heap-20250121_145612.pprof
```

### 3) 收集`allocs` profile
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof allocs
2025-01-21 14:56:42.554 UTC+0800    [INFO]    pprof option is allocs
2025-01-21 14:56:42.572 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:04:17 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:56:42.577 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 14:56:42.583 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/allocs-20250121_145642.pprof http://127.0.0.1:12345/debug/pprof/allocs
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  228k    0  228k    0     0   9.8M      0 --:--:-- --:--:-- --:--:-- 10.1M
2025-01-21 14:56:42.616 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/allocs-20250121_145642.pprof
```

### 5) 收集`goroutine` profile
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof goroutine
2025-01-21 15:00:05.088 UTC+0800    [INFO]    pprof option is goroutine
2025-01-21 15:00:05.107 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:04:42 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 15:00:05.112 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 15:00:05.118 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/goroutine-20250121_150005.pprof http://127.0.0.1:12345/debug/pprof/goroutine
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 11720    0 11720    0     0  3471k      0 --:--:-- --:--:-- --:--:-- 3815k
2025-01-21 15:00:05.131 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/goroutine-20250121_150005.pprof
```


### 5) 收集`trace` profile
收集`30s`
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof trace
2025-01-21 15:00:14.491 UTC+0800    [INFO]    pprof option is trace
2025-01-21 15:00:14.497 UTC+0800    [INFO]    duration is not set, using conf value: 30
2025-01-21 15:00:14.502 UTC+0800    [INFO]    collect duration is 30 seconds
2025-01-21 15:00:14.520 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:04:43 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 15:00:14.526 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 15:00:14.531 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/trace-20250121_150014.pprof http://127.0.0.1:12345/debug/pprof/trace?seconds=30
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 15.1M    0 15.1M    0     0   516k      0 --:--:--  0:00:30 --:--:--  598k
2025-01-21 15:00:44.548 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/trace-20250121_150014.pprof
```

### 6) 收集`malloc` profile
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl pprof malloc
2025-01-21 14:57:10.163 UTC+0800    [INFO]    pprof option is malloc
2025-01-21 14:57:10.182 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3112216       1 12 14:21 ?        00:04:21 /data/cus_reg/mo/20250121_070243/matrixone/mo-service -daemon -debug-http :12345 -launch /data/cus_reg/mo/20250121_070243/matrixone/etc/launch/launch.toml
2025-01-21 14:57:10.188 UTC+0800    [INFO]    List of pid(s): 
3112216
2025-01-21 14:57:10.193 UTC+0800    [INFO]    Try get pprof with command: curl -o /data/pprof-20241203/malloc-20250121_145710.pprof http://127.0.0.1:12345/debug/malloc
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21874    0 21874    0     0   9.8M      0 --:--:-- --:--:-- --:--:-- 10.4M
2025-01-21 14:57:10.206 UTC+0800    [INFO]    Get pprof succeeded. Please check result file: /data/pprof-20241203/malloc-20250121_145710.pprof
```