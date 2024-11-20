# mo_ctl stop
## 1. 作用
停止本地单机mo服务。若已有对应的mo服务在停止状态，则会略过。

## 2. 用法
```bash
mo_ctl stop [force]
```
- `force`：可选项，若添加，则会尝试强制停止。

## 3. 前提条件
无


## 4. 示例
### 1) 源码模式部署（git）
**示例1：** 无mo_service进程运行情况下，停止mo。
```bash
github@test:/data$ mo_ctl stop
2024-05-24 17:57:39.639 UTC+0800    [INFO]    No mo-service is running
2024-05-24 17:57:39.645 UTC+0800    [INFO]    No need to stop mo-service
2024-05-24 17:57:39.650 UTC+0800    [INFO]    Stop succeeded
```

**示例2：** 至少有一个mo-service进程运行的情况下，则会尝试把每一个mo-service进程全部终止掉。
```bash
github@test:/data$ mo_ctl stop
2024-05-24 17:59:07.661 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   2107944       1 85 17:59 ?        00:00:06 /data/mo/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/matrixone/etc/launch/launch.toml
2024-05-24 17:59:07.667 UTC+0800    [INFO]    List of pid(s): 
2107944
2024-05-24 17:59:07.673 UTC+0800    [INFO]    Try stop all mo-services found for a maximum of 10 times, try no: 1
2024-05-24 17:59:07.679 UTC+0800    [INFO]    Stopping mo-service with pid 2107944 with command: kill  2107944
2024-05-24 17:59:07.685 UTC+0800    [INFO]    Wait for 5 seconds
2024-05-24 17:59:12.703 UTC+0800    [INFO]    No mo-service is running
2024-05-24 17:59:12.710 UTC+0800    [INFO]    Stop succeeded
```

### 2) 二进制模式部署（binary）
与源码部署模式（git）示例一致，请参考上文。

### 3) 容器模式部署（docker）
容器模式下，`mo_ctl stop`命令会检查容器名称为配置项`MO_CONTAINER_NAME`对应值的容器，是否存在，以及是否在运行状态，决定是否停止该mo容器。
注：对于其他容器（包括任何其他异名的mo容器），或者任何其他非容器形式运行的mo-service，则不会尝试停止。

**示例1：** 若容器尚不存在，则会直接略过。
```bash
github@test$ mo_ctl stop
2024-05-24 12:09:35.178 UTC+0800    [INFO]    Check if container named mo-20240524_120530 is running
2024-05-24 12:09:35.314 UTC+0800    [INFO]    No container named mo-20240524_120530 is running
2024-05-24 12:09:35.343 UTC+0800    [INFO]    No need to stop mo-service
2024-05-24 12:09:35.374 UTC+0800    [INFO]    Stop succeeded
```

**示例2：** 若容器已存在，且未在运行状态，则会直接略过。
```bash
github@test$ mo_ctl stop
2024-05-24 18:12:14.538 UTC+0800    [INFO]    Check if container named mo-20240524_180210 is running
2024-05-24 18:12:14.717 UTC+0800    [INFO]    No container named mo-20240524_180210 is running
2024-05-24 18:12:14.750 UTC+0800    [INFO]    No need to stop mo-service
2024-05-24 18:12:14.787 UTC+0800    [INFO]    Stop succeeded
```

**实例3：** 若容器已存在，且在运行状态，则会尝试停止该容器。
```bash
github@test$ mo_ctl stop
2024-05-24 18:08:08.417 UTC+0800    [INFO]    Check if container named mo-20240524_180210 is running
2024-05-24 18:08:08.572 UTC+0800    [INFO]    Info of: docker ps --no-trunc --filter name=mo-20240524_180210
CONTAINER ID                                                       IMAGE                     COMMAND                                  CREATED              STATUS              PORTS                                                                                    NAMES
b7eb37e98038c9494df71fd81879a5500e24881102b698f695be75846cc19bd9   matrixone:main_03d182fe   "/mo-service -launch /etc/launch.toml"   About a minute ago   Up About a minute   0.0.0.0:6001->6001/tcp, :::6001->6001/tcp, 0.0.0.0:9876->12345/tcp, :::9876->12345/tcp   mo-20240524_180210
2024-05-24 18:08:08.602 UTC+0800    [INFO]    Try stop all mo-services found for a maximum of 10 times, try no: 1
2024-05-24 18:08:08.637 UTC+0800    [INFO]    Stopping mo container: docker stop mo-20240524_180210
mo-20240524_180210
2024-05-24 18:08:10.364 UTC+0800    [INFO]    Wait for 5 seconds
2024-05-24 18:08:15.398 UTC+0800    [INFO]    Check if container named mo-20240524_180210 is running
2024-05-24 18:08:15.547 UTC+0800    [INFO]    No container named mo-20240524_180210 is running
2024-05-24 18:08:15.581 UTC+0800    [INFO]    Stop succeeded
```
