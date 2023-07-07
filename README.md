# What it is
`mo_ctl` tool is a tool designed to help you easily manage your standalone MatrixOne server, such as deploying, starting, stopping, connect and much more fun admin operations for you to discover!

# How to get it
Depending on whether your machine has access to the Internet or not, you can choose to install `mo_ctl` online or offline. Please remember to run the commands as root or a user with sudo privileges (and add `sudo` to each command). Also `install.sh` will use `unzip` command to extract `mo_ctl`, thus please make sure `unzip` is installed.

```bash
# Option-A. install with the Internet
wget https://raw.githubusercontent.com/matrixorigin/mo_ctl_standalone/main/install.sh && bash +x ./install.sh

# Option-B. install without the Internet
# 1. download them to your local pc first, then upload them to your server machine
wget https://raw.githubusercontent.com/matrixorigin/mo_ctl_standalone/main/install.sh
wget https://github.com/matrixorigin/mo_ctl_standalone/archive/refs/heads/main.zip -O mo_ctl.zip

# 2. install from offline pacakge
bash +x ./install.sh mo_ctl.zip
```

In case you have network issues accessing above address, you can use the backup address below.

```bash
# backup address

# Option-A. install with the Internet
wget https://ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/blob/main/install.sh && bash +x install.sh

# Option-B. install without the Internet
# 1. download them to your pc first, then upload them to your machine
wget https://ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/blob/main/install.sh
wget https://ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/archive/refs/heads/main.zip -O mo_ctl.zip

# 2. install from offline pacakge
bash +x ./install.sh mo_ctl.zip
```

For users who are running this on your Mac environment, assuming you're a non-root user, thus please run `install.sh` as
```
sudo -u $(whoami) bash +x ./install.sh
```

# How to use it

After `mo_ctl` is installed, you can use `mo_ctl help` to print help info on how to use.

# Quick start
1. Take a quick look at the tool guide. 
```bash
mo_ctl help
```

2. Note that some pre-requisites are required by `mo_ctl`, and use `mo_ctl precheck` to check if your machine meets them. Refer to chapter Reference for more info on how to install them.
3. Set some configurations

```bash
mo_ctl get_conf MO_PATH # check default value of mo path to be installed
mo_ctl set_conf MO_PATH="/data/mo/20230701/matrixone" # set your own mo path
mo_ctl set_conf MO_GIT_URL="https://ghproxy.com/https://github.com/matrixorigin/matrixone.git" # in case have network issues, you can set this conf by overwritting default value MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
```

3. Deploy a standalone mo instance of latest stable release version(current: 0.8.0)
```bash
mo_ctl deploy
```

4. Check mo-service status
```bash
mo_ctl status
```

5. Connect to mo-service after a few seconds when mo-service's initialization is finished
```bash
mo_ctl connect
```

6. Now enjoy your journey with MatrixOne via mo_ctl! For more help, please check chapter Reference

# Reference

## Command reference

### help - print help info
Use `mo_ctl help` to get help on how to use `mo_ctl`
```bash
mo_ctl help
Usage             : mo_ctl [option_1] [option_2]

[option_1]        : available: help | precheck | deploy | status | start | stop | restart | connect | get_cid | set_conf | get_conf | pprof | ddl_convert
  0) help         : print help information
  1) precheck     : check pre-requisites for mo_ctl
  2) deploy       : deploy mo onto the path configured
  3) status       : check if there's any mo process running on this machine
  4) start        : start mo-service from the path configured
  5) stop         : stop all mo-service processes found on this machine
  6) restart      : start mo-service from the path configured
  7) connect      : connect to mo via mysql client using connection info configured
  8) get_cid      : print mo commit id from the path configured
  9) pprof        : collect pprof information
  10) set_conf    : set configurations
  11) get_conf    : get configurations
  12) ddl_convert : convert ddl file from to mo format from other types of database
  e.g.            : mo_ctl status

[option_2]        : Use " mo_ctl [option_1] help " to get more info
  e.g.            : mo_ctl deploy help 
```

Use `mo_ctl [option_1] help` to get more help on how to use `mo_ctl [option_1]`

### precheck - check pre-requisites

Use `mo_ctl precheck` before deploying your MatrixOne standalone instance. Currently the required pre-requsites are: `go`/`gcc`/`git`/`mysql(client)`.
```bash
mo_ctl precheck help
Usage         : mo_ctl precheck # check pre-requisites for mo_ctl
   Check list : go gcc git mysql 
```

### deploy - deploy mo

Use `mo_ctl deploy [mo_version] [force]` to deploy a stable version of mo release, or a specific development version.

```bash
mo_ctl deploy help
Usage         : mo_ctl deploy [mo_version] [force] # deploy mo onto the path configured
  [mo_version]: optional, specify an mo version to deploy
  [force]     : optional, if specified will delete all content under MO_PATH and deploy from beginning
  e.g.        : mo_ctl deploy             # default, same as mo_ctl deploy 0.8.0
              : mo_ctl deploy main        # deploy development latest version
              : mo_ctl deploy d29764a     # deploy development version d29764a
              : mo_ctl deploy 0.8.0       # deploy stable verson 0.8.0
              : mo_ctl deploy force       # delete all under MO_PATH and deploy verson 0.8.0
              : mo_ctl deploy 0.8.0 force # delete all under MO_PATH and deploy stable verson 0.8.0 from beginning
```

### start - start mo-service

Use `mo_ctl start` to startup mo-service, which is built under conf `MO_PATH`.

```bash
mo_ctl start help
Usage         : mo_ctl start # start mo-service from the path configured
```

### stop - stop mo-service

Use `mo_ctl stop [force]` to stop any mo-service found on current machine.

```bash
 mo_ctl stop help
Usage         : mo_ctl stop [force] # stop all mo-service processes found on this machine
 [force]      : optional, if specified, will try to kill mo-services with -9 option, so be very carefully
  e.g.        : mo_ctl stop         # default, stop all mo-service processes found on this machine
              : mo_ctl stop force   # stop all mo-services with kill -9 command
```

### restart - restart mo-service

Use `mo_ctl restart [force]` to stop any mo-service found on current machine, and start mo-service which is built under conf `MO_PATH`.

```bash
mo_ctl restart help
Usage         : mo_ctl restart [force] # a combination operation of stop and start
 [force]      : optional, if specified, will try to kill mo-services with -9 option, so be very carefully
  e.g.        : mo_ctl restart         # default, stop all mo-service processes found on this machine and start mo-serivce under path of conf MO_PATH
              : mo_ctl restart force   # stop all mo-services with kill -9 command and start mo-serivce under path of conf MO_PATH
```

### connect - connect to mo-service via mysql-client

Use `mo_ctl connect` to connect to mo via mysql client using connection info configured.

```bash
mo_ctl connect help
Usage         : mo_ctl connect # connect to mo via mysql client using connection info configured
```

### get_cid - print mo commit id

Use `mo_ctl get_cid`  print mo commit id from the path from conf  `MO_PATH`.

```bash
mo_ctl get_cid help
Usage         : mo_ctl get_cid # print mo commit id from the path configured
```

### pprof - collect pprof information

Use `mo_ctl pprof [item] [duration]` to collect pprof information, which is usefully when debugging issues.

```bash
mo_ctl pprof help
Usage         : mo_ctl pprof [item] [duration] # collect pprof information
  [item]      : optional, specify what pprof to collect, available: profile | heap | allocs
  1) profile  : default, collect profile pprof for 30 seconds
  2) heap     : collect heap pprof at current moment
  3) allocs   : collect allocs pprof at current moment
  [duration]  : optional, only valid when [item]=profile, specifiy duration to collect profile
  e.g.        : mo_ctl pprof
              : mo_ctl pprof profile    # collect duration will use conf value PPROF_PROFILE_DURATION from conf file or 30 if it's not set
              : mo_ctl pprof profile 30
              : mo_ctl pprof heap
```

### set_conf - set configurations

Use `mo_ctl set_conf [conf_list]` to set one or more configuration items.

```bash
mo_ctl set_conf help
Usage         : mo_ctl setconf [conf_list] # set configurations
 [conf_list]  : configuration list in key=value format, seperated by comma
  e.g.        : mo_ctl setconf MO_PATH=/data/mo/20230629/matrixone,MO_PW=M@trix0riginR0cks,MO_PORT=6101  # set multiple configurations
              : mo_ctl setconf MO_PATH=/data/mo/20230629/matrixone                                       # set single configuration
```

### get_conf - get configurations

Use `mo_ctl get_conf [conf_list]` to get one or more configuration items.

```bash
mo_ctl get_conf help
Usage         : mo_ctl getconf [conf_list] # get configurations
 [conf_list]  : optional, configuration list in key, seperated by comma.
              : use 'all' or leave it as blank to print all configurations
  e.g.        : mo_ctl getconf MO_PATH,MO_PW,MO_PORT  # get multiple configurations
              : mo_ctl getconf MO_PATH                # get single configuration
              : mo_ctl getconf all                    # get all configurations
              : mo_ctl getconf                        # get all configurations
```

### ddl_convert - a ddl format converter

Use `mo_ctl ddl_convert [options] [src_file] [tgt_file]` to convert a ddl file to mo format from other types of database. Currently, only `mysql_to_mo` is supported.

```bash
mo_ctl ddl_convert help
Usage           : mo_ctl ddl_convert [options] [src_file] [tgt_file] # convert a ddl file to mo format from other types of database
 [options]      : available: mysql_to_mo
 [src_file]     : source file to be converted, will use env DDL_SRC_FILE from conf file by default
 [tgt_file]     : target file of converted output, will use env DDL_TGT_FILE from conf file by default
  e.g.          : mo_ctl ddl_convert mysql_to_mo /tmp/mysql.sql /tmp/mo.sql
```

note： some types of column definition might not have yet been supported in mo, please refer to
https://docs.matrixorigin.cn/0.8.0/MatrixOne/Overview/feature/mysql-compatibility/#_1 for more info.

## Installing pre-requisites

### gcc

`gcc` is required for building and running MatrixOne. Version `8.5` or higher is recommended. Please refer to https://gcc.gnu.org/install/ on how to install it.

### go

`go` is required for building and running MatrixOne. Version `1.20` or higher is recommended. Please refer to https://go.dev/doc/install on how to install it.

### git

`git` is used to perform actions when deploying, getting commit id, etc on MatrixOne. Latest version is recommended. Please refer to https://github.com/git-guides/install-git on how to install it.

### mysql(client)

`mysql` command is used as a client tool for connecting MatrixOne server. Version `8.0.30` or higher is recommended. Please refer to https://dev.mysql.com/downloads/ on how to install it.

