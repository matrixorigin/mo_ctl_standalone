################################################################
# Copyright (C) 2023 Matrix Origin. All Rights Reserved
# Visit us at https://www.matrixorigin.cn/
################################################################
###### configurations ######


###########################################
# set below confs on demand
###########################################

# For deploy
# path to deploy matrixone, recommanded path: /data/mo/${DATE}/
MO_PATH="/data/mo/"
# log path used to store mo-service logs
MO_LOG_PATH="${MO_PATH}/matrixone/logs"

# For connect
# host ip to connect where mo is deployed, by default: 127.0.0.1
MO_HOST="127.0.0.1"
# host port to connect where mo is deployed, by default: 6001
# note: this conf is not meant to be the server side conf, but the client side conf
MO_PORT="6001"
# username to connect to mo, by default: root
MO_USER="root"
# password of the user to connect to mo, please use your own password 
MO_PW="111"
# mo deploy mode: docker | host
MO_DEPLOY_MODE="host"
MO_REPO="matrixorigin/matrixone"
MO_IMAGE_PREFIX="nightly"
MO_IMAGE_FULL=""
MO_CONTAINER_NAME="mo"
MO_CONTAINER_PORT="6001"
MO_CONTAINER_DEBUG_PORT="12345"
MO_CONTAINER_CONF_HOST_PATH="/dev/null"
MO_CONTAINER_CONF_CON_FILE="/etc/quickstart/launch.toml"

###########################################
# no need to set below conf for most cases 
###########################################

# for precheck
CHECK_LIST=("go" "gcc" "git" "mysql" "docker")
GCC_VERSION="8.5.0"
CLANG_VERSION="13.0"
GO_VERSION="1.20"
DOCKER_SERVER_VERSION="20"

# for deploy
# which url to be used for git cloning mo
MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
# in case you have network issues accessing above address, you can set one of the backup addresses below to replace the default value:
# default: "https://github.com/matrixorigin/matrixone.git"
# "https://ghproxy.com/https://github.com/matrixorigin/matrixone.git"
# "https://hub.yzuu.cf/matrixorigin/matrixone.git"
# "https://kgithub.com/matrixorigin/matrixone.git"
# "https://gitclone.com/github.com/matrixorigin/matrixone.git"
#)

# default version of which mo to be deployed
MO_DEFAULT_VERSION="1.0.0-rc1"
# which go proxy to be used when downloading go dependencies
# you can set this go proxy when building mo-service
GOPROXY="https://goproxy.cn,direct"

# for stop
# interval between stop and check status after stop, unit: seconds
STOP_INTERVAL="5"

# for start
# interval between start and check status after start, unit: seconds
START_INTERVAL="2"
# debug port that mo-service uses when it is started, which can be used to collect pprof info
MO_DEBUG_PORT="9876"
# conf file used to start mo-service
MO_CONF_FILE="${MO_PATH}/matrixone/etc/launch/launch.toml"
# GO memory limit ratio, x%. By default, 90% is recommended
GO_MEM_LIMIT_RATIO=90

# for restart
# interval between stop and start, unit: seconds
RESTART_INTERVAL="2"

# for pprof
# output path of pprof results 
PPROF_OUT_PATH="/tmp/pprof-test/"
# duration to collect pprof profile, unit: seconds
PPROF_PROFILE_DURATION="30"
