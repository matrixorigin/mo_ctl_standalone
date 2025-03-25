# What it is

`mo_ctl` tool is a tool designed to help you easily manage your standalone MatrixOne server, such as deploying, starting, stopping, connect and much more fun admin operations for you to discover!

# How to get it

Depending on whether your machine has access to the Internet or not, you can choose to install `mo_ctl` online or offline. Please remember to run the commands as root or a user with sudo privileges (and add `sudo` to each command). Also `install.sh` will use `unzip` command to extract `mo_ctl`, thus please make sure `unzip` is installed.

```bash
# Option-A. install locally with the Internet
wget https://raw.githubusercontent.com/matrixorigin/mo_ctl_standalone/main/deploy/local/install.sh && bash +x ./install.sh
# download from gitee.com
# wget https://gitee.com/matrixorigin/mo_ctl_standalone/blob/main/deploy/local/install.sh && bash +x ./install.sh

# Option-B. install locally without the Internet
# 1. download them to your local pc first, then upload them to your server machine
wget https://raw.githubusercontent.com/matrixorigin/mo_ctl_standalone/main/install.sh
wget https://github.com/matrixorigin/mo_ctl_standalone/archive/refs/heads/main.zip -O mo_ctl.zip

# Option-C. install and use it in K8S.
# 1. build docker image:
sudo docker build -t mo_ctl_standalone --build-arg GITHUB_TOKEN=${GITHUB_TOKEN} . -f optools/image/Dockerfile

# 2. install from offline pacakge
bash +x ./install.sh mo_ctl.zip
```

In case you have network issues accessing above address, you can use the backup address below.

```bash
# backup address

# Option-A. install with the Internet
wget https://mirror.ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/blob/main/deploy/local/install.sh && bash +x install.sh

# Option-B. install without the Internet
# 1. download them to your pc first, then upload them to your machine
wget https://mirror.ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/blob/main/deploy/local/install.sh
wget https://mirror.ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/archive/refs/heads/main.zip -O mo_ctl.zip

# 2. install from offline pacakge
bash +x ./install.sh mo_ctl.zip
```

You can uninstall mo_ctl using below command.

```bash
wget https://raw.githubusercontent.com/matrixorigin/mo_ctl_standalone/main/deploy/local/uninstall.sh && bash +x ./uninstall.sh

# backup address
wget https://mirror.ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/blob/main/deploy/local/uninstall.sh && bash +x uninstall.sh

# on Ubuntu, MacOS or any other Linux with a non-root user with sudo privilges
wget https://mirror.ghproxy.com/https://github.com/matrixorigin/mo_ctl_standalone/blob/main/deploy/local/uninstall.sh && sudo bash +x uninstall.sh
```

# How to use it

After `mo_ctl` is installed, you can use `mo_ctl help` to print help info on how to use.
Or, if you depoy it in K8S, apply a YAML file to start a job, take the full-backup job for example:

```
# use the backup cronjob
sudo crictl pull --creds ${username}:${password} mo-ctl:latest
kubectl create ns mo-job
kubectl get secret s3key -n mo-db -o yaml | sed 's/namespace: mo-db/namespace: mo-job/' | kubectl apply -f -
kubectl apply -f deploy/k8s/backup-pvc.yaml
# before run the next command, you should change the envs to set the confs of this tool, which starts with "_CTL_".
kubectl apply -f deploy/k8s/backup-full-cronjob.yaml
```

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
mo_ctl set_conf MO_GIT_URL="https://mirror.ghproxy.com/https://github.com/matrixorigin/matrixone.git" # in case have network issues, you can set this conf by overwritting default value MO_GIT_URL="https://github.com/matrixorigin/matrixone.git"
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

```bash
github@shpc2-10-222-1-9:/data$ mo_ctl help
Usage               : mo_ctl [option_1] [option_2]

Options             :
  [option_1]        : available: auto_backup | auto_clean_logs | auto_log_rotate | backup | clean_backup | clean_logs | connect | csv_convert | ddl_convert | deploy | get_branch | get_cid | get_conf | help | monitor | pprof | precheck | restart | set_conf | sql | start | status | stop | uninstall | upgrade | version | watchdog
    auto_backup     : setup a crontab task to backup your databases automatically
    auto_clean_logs : set up a crontab task to clean system log table data automatically
    auto_log_rotate : set up a crontab task to split and compress mo-service log file automatically
    backup          : create a backup of your databases manually
    build_image     : build an MO image from source code
    clean_backup    : clean old backups older than conf 31 days manually
    clean_logs      : clean system log table data manually
    connect         : connect to mo via mysql client using connection info configured
    csv_convert     : convert a csv file to a sql file in format "insert into values" or "load data inline format='csv'"
    ddl_convert     : convert a ddl file to mo format from other types of database
    deploy          : deploy mo onto the path configured
    get_branch      : upgrade or downgrade mo from current version to a target commit id or stable version
    get_cid         : print mo git commit id from the path configured
    get_conf        : get configurations
    help            : print help information
    monitor         : monitor system related operations
    pprof           : collect pprof information
    precheck        : check pre-requisites for mo_ctl
    restart         : a combination operation of stop and start
    set_conf        : set configurations
    sql             : execute sql from string, or a file or a path containg multiple files
    start           : start mo-service from the path configured
    status          : check if there's any mo process running on this machine
    stop            : stop all mo-service processes found on this machine
    uninstall       : uninstall mo from path MO_PATH=/data/mo/test/matrixone
    upgrade         : upgrade or downgrade mo from current version to a target commit id or stable version
    version         : show mo_ctl and matrixone version
    watchdog        : setup a watchdog crontab task for mo-service to keep it alive

  [option_2]        : Option for [option_1]. Use 'mo_ctl [option_1] help' to get more info

Examples            : mo_ctl status
                      mo_ctl status help
```
