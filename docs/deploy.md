# `deploy`
## 1. 作用
在本地部署一个单机的mo数据库实例。

## 2. 用法
注意： `deploy`只在`MO_DEPLOY_MODE`设置为`git`或`docker`时有效，在后者设置为`binary`时，请先手动下载并解压好二进制文件包。
### 1) 源码模式部署（git）
```bash
mo_ctl deploy help
Usage         : mo_ctl deploy [$mo_version] [force] [nobuild] # 在本地部署一个单机mo实例
              : mo_ctl deploy help        # 打印帮助
```

- `$mo_version`: 可选项，默认为最新的已发布版本号。有以下几种可能的情况：
  - 版本号：主要是已发布（`release`的版本号），例如`1.2.0`、`1.1.3`，对应`github`代码仓库中的`tag`名称。一般用于生产环境。
  - 分支名: 例如`main`、`1.2-dev`，会部署该分支下最新的`commit`代码，对应`github`代码仓库中的`branch`名称。一般用于测试环境。
  - `commit`号：例如`e63a995`，对应`github`代码仓库中的任意一个`commmit`号。一般用于测试环境。
- `force`: 可选项，若指定则会覆盖目录安装。一般用于重复安装使用，常见于测试环境，而生产环境不推荐且需要慎重选择！
- `nobuild`: 可选项，若指定则会跳过。一般用于调试或构建镜像使用，常见于测试环境。

**注意**：使用前，请先确保您已设置部署模式为`git`（默认）。
```bash
mo_ctl set_conf MO_DEPLOY_MODE=git
```
此外，以下参数与部署相关，均有默认值，用户部署前，可选配置。
```bash
mo_ctl set_conf MO_PATH=/data/mo # 安装目录，默认为/data/mo/，会在此目录下拉取git源码到matrixone目录下
mo_ctl set_conf MO_LOG_PATH=/data/mo/matrixone/logs # 日志目录，默认为${MO_PATH}/matrixone/logs
mo_ctl set_conf MO_CONF_SRC_PATH=/my/mo/confs/ # 默认为空，即使用git源码自带的配置文件。如果设置，则会拷贝此目录下的cn.toml、tn.toml、log.toml文件到${MO_PATH}/matrixone/etc/launch/目录并替换默认配置文件
mo_ctl set_conf MO_CONF_FILE="\${MO_PATH}/matrixone/etc/launch/launch.toml" # 设置MO启动时的配置文件路径，可以用相关的变量（例如已设置好的MO_PATH），但需要注意用\$转义
mo_ctl set_conf MO_GIT_URL="https://github.com/matrixorigin/matrixone.git" # 设置代码拉取所在的git仓库url地址，如果国内遇到网络问题，可以通过代理拉取，例如：https://githubfast.com/matrixorigin/matrixone.git 或 https://gh-proxy.com/github.com/matrixorigin/matrixone.git
```

### 2) 二进制模式部署（binary）

注意：使用前，请先确保您已设置部署模式为binary。

```bash
mo_ctl set_conf MO_DEPLOY_MODE=binary
```

二进制无需部署，只需要提前下载并解压mo的release包即可完成部署，地址为：
```bash
https://github.com/matrixorigin/matrixone
```

例如：
```bash
mkdir -p /data/mo/
wget https://github.com/matrixorigin/matrixone/releases/download/v2.0.1-hotfix-20241211/mo-v2.0.1-hotfix-20241211-musl-x86_64.zip -O /data/mo/mo-v2.0.1-hotfix-20241211-musl-x86_64.zip
cd /data/mo/
unzip mo-v2.0.1-hotfix-20241211-musl-x86_64.zip 
# 解压后会有一个mo-v2.0.1-hotfix-20241211-musl-x86_64目录，内容如下：
# github@shpc2-10-222-1-9:/data/mo/mo-v2.0.1-hotfix-20241211-musl-x86_64$ ll
# total 187532
# drwxr-xr-x 4 github github      4096 Dec 16 14:39 etc
# -rwxr-xr-x 1 github github 192018312 Dec 16 14:39 mo-service
# drwxr-xr-x 3 github github      4096 Dec 16 14:39 pkg
```

之后，设置相关的配置
```bash
mo_ctl set_conf MO_PATH=/data/mo/mo-v2.0.1-hotfix-20241211-musl-x86_64
mo_ctl set_conf MO_LOG_PATH=/data/mo/matrixone/logs # 日志目录，默认为${MO_PATH}/matrixone/logs
mo_ctl set_conf MO_CONF_SRC_PATH=/my/mo/confs/ # 默认为空，即使用git源码自带的配置文件。如果设置，则会拷贝此目录下的cn.toml、tn.toml、log.toml文件到${MO_PATH}/etc/launch/目录并替换默认配置文件
mo_ctl set_conf MO_CONF_FILE=/data/mo/mo-v2.0.1-hotfix-20241211-musl-x86_64/etc/launch/launch.toml
```


### 3) 容器模式部署（docker）
```bash
mo_ctl deploy help
Usage         : mo_ctl deploy             # 在本地部署一个单机mo实例
              : mo_ctl deploy help        # 打印帮助
```
- 无其他参数：`docker`部署模式下，请阅读以下注意事项，而执行`deploy`命令时无需添加其他参数。

**注意**：使用前，请先确保您已设置部署模式为`docker`。
```bash
mo_ctl set_conf MO_DEPLOY_MODE=docker
```
此外，以下参数与部署相关，均有默认值，用户部署前，可选配置。
```bash
mo_ctl set_conf MO_CONTAINER_IMAGE="matrixorigin/matrixone:1.2.0" # mo镜像全名，默认为最新已发布版本的镜像全名，格式为${image_repo_address}/${image_name}:${image_tag}
mo_ctl set_conf MO_CONTAINER_NAME=mo # mo容器名称，默认为mo
mo_ctl set_conf MO_CONTAINER_PORT=6001 # mo容器内数据库进程使用的端口，默认为6001
mo_ctl set_conf MO_CONTAINER_DEBUG_PORT=12345 # mo容器内数据库debug使用的端口，默认为12345
mo_ctl set_conf MO_CONTAINER_CONF_HOST_PATH="" # mo容器使用的配置文件所在宿主机的目录，默认为空，可以设置，但需要准备好对应文件，例如设置为/data/mo/conf/，则需要在里面准备好tn.toml、cn.toml、log.toml、launch.toml文件
mo_ctl set_conf MO_CONTAINER_CONF_CON_FILE="/etc/quickstart/launch.toml" # mo容器内使用的配置文件路径，默认是/etc/quickstart/launch.toml
mo_ctl set_conf MO_CONTAINER_DATA_HOST_PATH="/data/mo/data/" # mo容器使用的数据目录对应的宿主机目录，默认为空，但建议设置为一个用户指定的目录，例如/data/mo/data/
mo_ctl set_conf MO_CONTAINER_HOSTNAME="" # 设置mo容器使用的主机名，可以与宿主机的主机名一致，例如myhost
mo_ctl set_conf MO_CONTAINER_LIMIT_MEMORY="" # 设置mo容器使用的内存大小限制的数值，单位为mb，例如10240，代表限制容器只能使用10240mb大小的内存
mo_ctl set_conf MO_CONTAINER_MEMORY_RATIO=90 # 设置mo容器使用的内存大小限制所占宿主机总内存大小的比例。但注意，如果设置了MO_CONTAINER_LIMIT_MEMORY，则该配置项无效，会被前者覆盖
mo_ctl set_conf MO_CONTAINER_AUTO_RESTART=yes # 设置mo容器遇到异常后是否启动重启
mo_ctl set_conf MO_CONTAINER_LIMIT_CPU="" # 设置mo容器使用的CPU核数大小限制的数值，例如8，代表限制容器只能使用8核大小的cpu
mo_ctl set_conf MO_CONTAINER_CONF_HOST_PATH=/my/mo/conf # mo容器挂载配置文件在宿主机上的目录，默认为空，即使用容器自带的配置文件。若有修改配置文件需求，可按此设置
```

## 3. 前提条件
`mo_ctl precheck`已执行，且各项环境检查均已通过。

## 4. 示例
### 1) 源码模式部署（git）
**示例1：** 无mo_service进程运行情况下，启动mo。


### 2) 二进制模式部署（binary）
与源码部署模式（git）示例一致，请参考上文。

### 3) 容器模式部署（docker）
无需部署，直接启动即可，以下为容器模式的启动示例：
```bash
2025-01-21 06:19:25.786 UTC+0800    [INFO]    Check if container named mo-20250121_060453 is running
2025-01-21 06:19:25.904 UTC+0800    [INFO]    No container named mo-20250121_060453 is running
2025-01-21 06:19:25.945 UTC+0800    [DEBUG]    Check total memory on current machine, command: free -m | awk 'NR==2{print }', result(Mi): 15884
2025-01-21 06:19:25.987 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="docker"
2025-01-21 06:19:26.176 UTC+0800    [DEBUG]    Conf MO_CONTAINER_LIMIT_MEMORY is empty, will set docker memory limit as 95% of total memory
2025-01-21 06:19:26.198 UTC+0800    [DEBUG]    Docker memory limit(Mi): 15089, GO memory limit(Mi): 9053
2025-01-21 06:19:26.218 UTC+0800    [DEBUG]    Start command will add: --memory=15089m
2025-01-21 06:19:26.245 UTC+0800    [DEBUG]    Start command will add: --env GOMEMLIMIT=9053MiB
2025-01-21 06:19:26.280 UTC+0800    [DEBUG]    Conf MO_CONTAINER_LIMIT_CPU is set as 4, total cpu cores: 8
2025-01-21 06:19:26.303 UTC+0800    [DEBUG]    Start command will add: --cpus=4
2025-01-21 06:19:26.333 UTC+0800    [DEBUG]    Start command will add: --restart=always
2025-01-21 06:19:26.364 UTC+0800    [DEBUG]    Get hostname of host: HOST-10-222-4-2
2025-01-21 06:19:26.389 UTC+0800    [DEBUG]    Setting conf container hostname: MO_CONTAINER_HOSTNAME=HOST-10-222-4-2
2025-01-21 06:19:26.415 UTC+0800    [DEBUG]    conf list: MO_CONTAINER_HOSTNAME=HOST-10-222-4-2
2025-01-21 06:19:26.451 UTC+0800    [INFO]    Try to set conf: MO_CONTAINER_HOSTNAME="HOST-10-222-4-2"
2025-01-21 06:19:26.478 UTC+0800    [DEBUG]    key: MO_CONTAINER_HOSTNAME, value: HOST-10-222-4-2
2025-01-21 06:19:26.501 UTC+0800    [INFO]    Setting conf MO_CONTAINER_HOSTNAME="HOST-10-222-4-2"
2025-01-21 06:19:26.554 UTC+0800    [INFO]    Initial start mo container: docker run -d  -v /data/cus_reg/mo/20250121_060453/matrixone/mo-data:/mo-data:rw -p 9876:12345 -p 6001:6001 --name mo-20250121_060453 --memory=15089m --env GOMEMLIMIT=9053MiB --cpus=4 --restart=always --hostname HOST-10-222-4-2 -v /data/cus_reg/mo/20250121_060453/matrixone/conf/:/etc:rw --entrypoint /mo-service matrixone:2.0-dev_15c83060 -debug-http :12345  -launch /etc/launch.toml
6ea22a30fbb2da05912f5e7a4bc84e37446e623e67c2ad216b0a0e2d9dd93094
+ mo_ctl status
2025-01-21 06:19:27.714 UTC+0800    [INFO]    Check if container named mo-20250121_060453 is running
2025-01-21 06:19:27.986 UTC+0800    [INFO]    Info of: docker ps --no-trunc --filter name=mo-20250121_060453
CONTAINER ID                                                       IMAGE                        COMMAND                                                     CREATED        STATUS                  PORTS                                                                                    NAMES
6ea22a30fbb2da05912f5e7a4bc84e37446e623e67c2ad216b0a0e2d9dd93094   matrixone:2.0-dev_15c83060   "/mo-service -debug-http :12345 -launch /etc/launch.toml"   1 second ago   Up Less than a second   0.0.0.0:6001->6001/tcp, :::6001->6001/tcp, 0.0.0.0:9876->12345/tcp, :::9876->12345/tcp   mo-20250121_060453
```