# `build_image`
## 1. 作用
基于mo源码，构建docker镜像

## 2. 用法
```bash
Usage           : mo_ctl build_image             # build an MO image from source code
Note            : Please set below configurations first before you run the [enable] option
                  1. MO_PATH (optional, default: /data/mo): path to MO source codes. 
                  2. GOPROXY (optional, default: https://proxy.golang.com.cn,direct): GO proxy setting. 
                  3. MO_BUILD_IMAGE_PATH (optional, default: /tmp): path to save target MO image
Examples        : Build an MO image based on main branch latest commit id
                  mo_ctl set_conf MO_DEPLOY_MODE=git
                  mo_ctl set_conf MO_PATH=/data/mo/src
                  mo_ctl set_conf GOPROXY=https://proxy.golang.com.cn,direct
                  mo_ctl set_conf MO_BUILD_IMAGE_PATH=/data/mo/images
                  mo_ctl build_image
```


## 3. 前提条件
1、请确保docker已安装完成，并正常启动。以ubuntu的系统为例：
```
sudo apt install docker
sudo systemctl start docker
sudo systemctl status docker
```
参考：https://docs.docker.com/engine/install/

2、基于源码的方式，拉取mo的源码目录，并且选择不构建二进制文件
```bash
mkdir -p /data/mo/src_code/ # 确认存放mo源码的目录存在，并为空
mo_ctl set_conf MO_DEPLOY_MODE=git # 设置部署模式为git，即git拉取源码部署
mo_ctl set_conf MO_PATH=/data/mo/src_code/ # 设置存放mo源码的目录
# 可选，如果遇到github无法访问，可以选择代理地址，例如
# 默认：mo_ctl set_conf MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
# 代理：mo_ctl set_conf MO_GIT_URL="https://gh-proxy.com/github.com/matrixorigin/matrixone.git"
# 代理：mo_ctl set_conf MO_GIT_URL="https://githubfast.com/matrixorigin/matrixone.git"
mo_ctl deploy v2.0.1 nobuild # 以2.0.1版本为例，选择不构建二进制文件，即只拉取代码即可
```

3、之后，设置构建镜像的相关参数：
```bash
mkdir -p /data/mo/image # 确保镜像存放的路径存在
mo_ctl set_conf MO_BUILD_IMAGE_PATH=/data/mo/images # 设置镜像存放的路径
mo_ctl set_conf GOPROXY=https://proxy.golang.com.cn,direct # 设置构建镜像时的go代理地址，参考：https://developer.aliyun.com/article/879662
```


***注意***：如果对相关参数进行了重新设置，需要先禁用（`disable`），再启用（`enable`），新的配置才能生效

## 4. 示例
参数设置完成后，直接一键构建镜像
```bash
mo_ctl build_image
```

注意：如果当前执行的用户不在docker组内，可能会失败，请先加入docker组，或者使用sudo权限构建，如：
```
mo_ctl build_image
```

示例输出：
```bash

```