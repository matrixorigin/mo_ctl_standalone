# `start`
## 1. 作用
启动本地单机mo服务。若已有对应的mo服务在运行状态，则会略过。

## 2. 用法
```bash
mo_ctl start
```

## 3. 前提条件
mo已经成功完成部署。


## 4. 示例
### 1) 源码模式部署（git）
**示例1：** 无mo_service进程运行情况下，启动mo。
```bash
github@test:/data$ mo_ctl start 
2024-05-17 17:09:32.966 UTC+0800    [INFO]    No mo-service is running
2024-05-17 17:09:33.075 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="git"
2024-05-17 17:09:33.123 UTC+0800    [INFO]    GO memory limit(Mi): 9597
2024-05-17 17:09:33.199 UTC+0800    [INFO]    Starting mo-service: cd /data/mo/matrixone/ && GOMEMLIMIT=9597MiB /data/mo/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/matrixone/etc/launch/launch.toml >/data/mo/matrixone/logs/stdout-20240517_170933.log 2>/data/mo/matrixone/logs/stderr-20240517_170933.log
2024-05-17 17:09:33.397 UTC+0800    [INFO]    Wait for 2 seconds
2024-05-17 17:09:35.494 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   1223534       1 99 17:09 ?        00:00:03 /data/mo/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/matrixone/etc/launch/launch.toml
2024-05-17 17:09:35.529 UTC+0800    [INFO]    List of pid(s): 
1223534
2024-05-17 17:09:35.565 UTC+0800    [INFO]    Start succeeded
```

**示例2：** 至少有一个mo-service进程运行的情况下，则会直接忽略启动过程。
```bash
github@test:/data$ mo_ctl start 
2024-05-17 17:11:59.253 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   1223534       1 70 17:09 ?        00:01:42 /data/mo/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/matrixone/etc/launch/launch.toml
2024-05-17 17:11:59.290 UTC+0800    [INFO]    List of pid(s): 
1223534
2024-05-17 17:11:59.329 UTC+0800    [INFO]    No need to start mo-service
2024-05-17 17:11:59.369 UTC+0800    [INFO]    Start succeeded
```

### 2) 二进制模式部署（binary）
与源码部署模式（git）示例一致，请参考上文。

### 3) 容器模式部署（docker）
容器模式下，`mo_ctl start`命令会检查容器名称为配置项`MO_CONTAINER_NAME`对应值的容器，是否存在，以及是否在运行状态，决定是否启动mo。

**示例1：** 若容器尚不存在，则会以`docker run`命令尝试启动mo。
```bash
[root@test ~]# mo_ctl start 
2024-05-17 17:22:35.499 UTC+0800    [INFO]    Check if container named mo-20240517_120545 is running
2024-05-17 17:22:35.619 UTC+0800    [INFO]    No container named mo-20240517_120545 is running
2024-05-17 17:22:35.719 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="docker"
2024-05-17 17:22:36.163 UTC+0800    [INFO]    Try to set conf: MO_CONTAINER_HOSTNAME="test"
2024-05-17 17:22:36.244 UTC+0800    [INFO]    Setting conf MO_CONTAINER_HOSTNAME="test"
2024-05-17 17:22:36.304 UTC+0800    [INFO]    Initial start mo container: docker run -d  -v /data/mo/matrixone/mo-data:/mo-data:rw -p 9876:12345 -p 6001:6001 --name mo-20240517_120545 --memory=15089m --env GOMEMLIMIT=9053MiB --hostname test0 -v /data/cus_reg/mo/matrixone/conf/:/etc:rw --entrypoint /mo-service matrixone:1.2-dev_4a707317 -launch /etc/launch.toml
2e58ed01196d4187cbfc34adec186a41510ec9764ce9c62e544e8712400fb44a
```

**示例2：** 若容器已存在，且未在运行状态，则会以`docker start`命令尝试启动mo。
```bash
[root@test ~]# mo_ctl start 
2024-05-17 17:20:08.023 UTC+0800    [INFO]    Check if container named mo-20240517_120545 is running
2024-05-17 17:20:08.141 UTC+0800    [INFO]    No container named mo-20240517_120545 is running
2024-05-17 17:20:08.232 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="docker"
2024-05-17 17:20:08.357 UTC+0800    [INFO]    Container named mo-20240517_120545 found. Start mo container: docker start mo-20240517_120545
mo-20240517_120545
```

**实例3：** 若容器已存在，且在运行状态，则会跳过启动过程。
```bash
[root@test ~]# mo_ctl start 
2024-05-17 17:25:55.223 UTC+0800    [INFO]    Check if container named mo-20240517_120545 is running
2024-05-17 17:25:55.354 UTC+0800    [INFO]    Info of: docker ps --no-trunc --filter name=mo-20240517_120545
CONTAINER ID                                                       IMAGE                        COMMAND                                  CREATED         STATUS         PORTS                                                                                    NAMES
2e58ed01196d4187cbfc34adec186a41510ec9764ce9c62e544e8712400fb44a   matrixone:1.2-dev_4a707317   "/mo-service -launch /etc/launch.toml"   3 minutes ago   Up 3 minutes   0.0.0.0:6001->6001/tcp, :::6001->6001/tcp, 0.0.0.0:9876->12345/tcp, :::9876->12345/tcp   mo-20240517_120545
2024-05-17 17:25:55.388 UTC+0800    [INFO]    No need to start mo-service
2024-05-17 17:25:55.423 UTC+0800    [INFO]    Start succeeded
```
