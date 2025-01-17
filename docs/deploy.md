# deploy
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
```

### 2) 容器模式部署（docker）
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
mo_ctl set_conf MO_CONTAINER_CONF_HOST_PATH=/my/mo/conf # mo容器挂载配置文件在宿主机上的目录，默认为空，即使用容器自带的配置文件。若有修改配置文件需求，可按此设置
mo_ctl set_conf MO_CONTAINER_CONF_CON_FILE
```

## 3. 前提条件
`mo_ctl precheck`已执行，且各项环境检查均已通过。

## 4. 示例
### 1) 源码模式部署（git）
**示例1：** 无mo_service进程运行情况下，启动mo。


### 2) 二进制模式部署（binary）
与源码部署模式（git）示例一致，请参考上文。

### 3) 容器模式部署（docker）
