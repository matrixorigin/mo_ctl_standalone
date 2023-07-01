MO_PATH="/data/mo/20230630-1448/matrixone"

MO_HOST="127.0.0.1"
MO_PORT="6001"
MO_USER="dump"
MO_PW="111"

MO_DEBUG_PORT="9876"
MO_CONF_FILE="${MO_PATH}/etc/launch-tae-CN-tae-DN/launch.toml"
MO_LOG_PATH="${MO_PATH}/logs"


###########################################
# no need to set below conf for most cases 
###########################################

# for precheck
CHECK_LIST=("go" "gcc" "git" "mysql")
GCC_VERSION="8.5.0"
GO_VERSION="1.19"

# for deploy
MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
# in case you're in mainland of China, you can set one of the backup addresses below to replace the default value:
# default: "https://github.com/matrixorigin/matrixone.git"
# "https://ghproxy.com/https://github.com/matrixorigin/matrixone.git"
# "https://ghproxy.com/https://github.com/matrixorigin/matrixone.git"
# "https://hub.njuu.cf/matrixorigin/matrixone.git"
# "https://hub.yzuu.cf/matrixorigin/matrixone.git"
# "https://kgithub.com/matrixorigin/matrixone.git"
# "https://gitclone.com/github.com/matrixorigin/matrixone.git"
#)

MO_DEFAULT_VERSION="0.8.0"
# in case you're in mainland of China, set this go proxy when building mo-service
GOPROXY=https://goproxy.cn,direct

# for stop
# interval between stop and check status after stop, unit: seconds
STOP_INTERVAL=5


# for start
# interval between start and check status after start, unit: seconds
START_INTERVAL=2


# for restart
# interval between stop and start, unit: seconds
RESTART_INTERVAL=2

# for pprof
# duration to collect pprof profile, unit: seconds
PPROF_OUT_PATH="/tmp/pprof-test/"
PPROF_PROFILE_DURATION=30