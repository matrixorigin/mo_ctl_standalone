# mo_ctl status
## 1. 作用
检查本地单机mo服务的运行状态。

## 2. 用法
```bash
mo_ctl status
```

## 3. 前提条件
无。

## 4. 示例
### 1) 源码模式部署（git）
**示例1：** 无mo_service进程运行。
```bash
github@test:/data$ mo_ctl status
2024-05-17 14:57:29.158 UTC+0800    [INFO]    No mo-service is running
```

**示例2：** 至少有一个mo-service进程运行。
```bash
github@test:/data$ mo_ctl status
2024-05-17 14:58:51.662 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   1188018       1 99 14:57 ?        00:01:22 /data/mo/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/matrixone/etc/launch/launch.toml
2024-05-17 14:58:51.699 UTC+0800    [INFO]    List of pid(s): 
1188018
```

### 2) 二进制模式部署（binary）
与源码部署模式（git）示例一致，请参考上文。

### 3) 容器模式部署（docker）
容器模式下，`mo_ctl status`命令会检查容器名称为配置项`MO_CONTAINER_NAME`对应值的容器，是否在运行状态，并输出`docker ps --no-trunc --filter`命令的相关信息。

**示例1：** 对应容器不在正常运行状态。
```bash
github@test:/data$ mo_ctl status
2024-05-17 15:13:51.843 UTC+0800    [INFO]    Check if container named mo-20240517_120545 is running
2024-05-17 15:13:51.965 UTC+0800    [INFO]    No container named mo-20240517_120545 is running
```

**示例2：** 对应容器在正常运行状态。
```bash
[github@test]$ mo_ctl status
2024-05-17 15:01:07.205 UTC+0800    [INFO]    Check if container named mo-20240517_120545 is running
2024-05-17 15:01:07.361 UTC+0800    [INFO]    Info of: docker ps --no-trunc --filter name=mo-20240517_120545
CONTAINER ID                                                       IMAGE                        COMMAND                                  CREATED       STATUS       PORTS                                                                                    NAMES
a1978fa4732a462fe00a40d3f87c3c4c7fff76452d0e45290608c089311f3b55   matrixone:1.2-dev_4a707317   "/mo-service -launch /etc/launch.toml"   3 hours ago   Up 2 hours   0.0.0.0:6001->6001/tcp, :::6001->6001/tcp, 0.0.0.0:9876->12345/tcp, :::9876->12345/tcp   mo-20240517_120545
```
