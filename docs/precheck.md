# mo_ctl precheck
## 1. 作用
检查部署单机mo前，所在服务器是否符合实施要求。

## 2. 用法
```bash
mo_ctl precheck
```

## 3. 前提条件
在预检查前，请先设置mo的部署模式
### 1) 源码部署模式 (git)
默认即为git模式，若采用此模式，可略过
```bash
mo_ctl set_conf MO_DEPLOY_MODE=git
```

### 2) 二进制部署模式 (binary)
```bash
mo_ctl set_conf MO_DEPLOY_MODE=binary
```

### 3) 容器部署模式 (docker)
```bash
mo_ctl set_conf MO_DEPLOY_MODE=docker
```

## 4. 示例
### 1) 源码部署模式 (git)
**示例1：** 全部检查项通过
```bash
github@test:/data$ mo_ctl precheck
2024-05-17 17:38:10.423 UTC+0800    [INFO]    Precheck on pre-requisite: go
2024-05-17 17:38:10.470 UTC+0800    [INFO]    Ok. go is installed
2024-05-17 17:38:10.521 UTC+0800    [INFO]    Version check on go. Current: 1.22.3, required: 1.20
2024-05-17 17:38:10.570 UTC+0800    [INFO]    Ok. go version is greater than or equal to required
2024-05-17 17:38:10.610 UTC+0800    [INFO]    Precheck on pre-requisite: gcc
2024-05-17 17:38:10.658 UTC+0800    [INFO]    Ok. gcc is installed
2024-05-17 17:38:10.710 UTC+0800    [INFO]    Version check on gcc. Current: 10.2.1, required: 8.5.0
2024-05-17 17:38:10.757 UTC+0800    [INFO]    Ok. gcc version is greater than or equal to required
2024-05-17 17:38:10.794 UTC+0800    [INFO]    Precheck on pre-requisite: git
2024-05-17 17:38:10.837 UTC+0800    [INFO]    Ok. git is installed
2024-05-17 17:38:10.875 UTC+0800    [INFO]    Precheck on pre-requisite: mysql
2024-05-17 17:38:10.921 UTC+0800    [INFO]    Ok. mysql is installed
2024-05-17 17:38:10.958 UTC+0800    [INFO]    Precheck on pre-requisite: docker
2024-05-17 17:38:10.996 UTC+0800    [INFO]    Conf MO_DEPLOY_MODE is set to 'git', ignoring docker
2024-05-17 17:38:11.033 UTC+0800    [INFO]    All pre-requisites are ok
```

**示例2：** 至少有一个检查项不满足条件，可能的原因有：
- 依赖未提前安装；
- 已安装但版本号不符合要求；
- 已安装但未正确配置到`$PATH`变量中导致找不到该命令；
- ...
```bash
github@test:/data$ mo_ctl precheck
2024-05-17 17:38:50.946 UTC+0800    [INFO]    Precheck on pre-requisite: go
2024-05-17 17:38:50.983 UTC+0800    [ERROR]    Nok. Please check if it is installed or exists in your $PATH env
2024-05-17 17:38:51.016 UTC+0800    [INFO]    Precheck on pre-requisite: gcc
2024-05-17 17:38:51.050 UTC+0800    [INFO]    Ok. gcc is installed
2024-05-17 17:38:51.099 UTC+0800    [INFO]    Version check on gcc. Current: 11.4.0, required: 8.5.0
2024-05-17 17:38:51.138 UTC+0800    [INFO]    Ok. gcc version is greater than or equal to required
2024-05-17 17:38:51.169 UTC+0800    [INFO]    Precheck on pre-requisite: git
2024-05-17 17:38:51.204 UTC+0800    [INFO]    Ok. git is installed
2024-05-17 17:38:51.235 UTC+0800    [INFO]    Precheck on pre-requisite: mysql
2024-05-17 17:38:51.270 UTC+0800    [INFO]    Ok. mysql is installed
2024-05-17 17:38:51.303 UTC+0800    [INFO]    Precheck on pre-requisite: docker
2024-05-17 17:38:51.336 UTC+0800    [INFO]    Conf MO_DEPLOY_MODE is set to 'host', ignoring docker
2024-05-17 17:38:51.368 UTC+0800    [ERROR]    At least one pre-requisite is not ok, list: go
```

### 2) 容器部署模式 (docker)



## 附录A-检查清单
序号|检查项|检查条件|部署模式|说明
:---:|:---:|:---:|:---:|:---:
1|go|已提前安装go，且版本号不低于1.21|git|依赖go环境编译mo源码
2|gcc|已提前安装gcc，且版本号不低于8.5.0；或clang 13.0版本|git|依赖gcc底层库
3|git|已提前安装git，版本号无特殊要求，建议最新即可|git|依赖git命令获取源码
4|mysql (client)|已提前安装好mysql client（或兼容mysql client的工具，如mariadb client），版本号无特殊要求，建议8.0.x以上|git、docker、binary|用于作为客户端连接到mo服务端
5|docker|已提前安装好docker并启动，且版本号不低于20|docker|容器部署模式依赖docker环境
