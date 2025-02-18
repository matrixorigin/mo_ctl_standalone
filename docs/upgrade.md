# upgrade
## 1. 作用
将mo从一个版本(commit_id_2)升级到另外一个版本（commit_id_2）

## 2. 用法
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl upgrade help
Usage           : mo_ctl upgrade [version]   # upgrade or downgrade mo from current version to a target commit id or stable version
 [version]      : a branch(e.g. 'main'), a commit id (e.g. '38888f7'), or a release version(e.g. '1.2.0')
                : use 'latest' to upgrade to latest commit on main branch if you don't know the id
Examples        : mo_ctl upgrade 38888f7              # upgrade/downgrade to commit id 38888f7 on main branch
                : mo_ctl upgrade latest               # upgrade/downgrade to latest commit on main branch
                : mo_ctl upgrade 1.2.0                # upgrade/downgrade to stable version 1.2.0
```

## 3. 前提条件
1、mo已停止
2、mo watchdog已禁用

## 4. 示例
先部署一个mo v2.0.1版本的实例，之后将其升级为v2.0.2版本
```bash
github@shpc2-10-222-1-9:/data$ mo_ctl sql "select version(), git_version(); create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3); select * from t1;"
2025-02-18 16:42:27.356 UTC+0800    [INFO]    Input "select version(), git_version(); create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3); select * from t1;" is not a path or a file, try to execute it as a query
2025-02-18 16:42:27.362 UTC+0800    [INFO]    Begin executing query "select version(), git_version(); create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3); select * from t1;"
--------------
select version(), git_version()
--------------

+-------------------------+---------------+
| version()               | git_version() |
+-------------------------+---------------+
| 8.0.30-MatrixOne-v2.0.1 | 25b06b2ca     |
+-------------------------+---------------+
1 row in set (0.00 sec)

--------------
create database test
--------------

Query OK, 1 row affected (0.01 sec)

--------------
create table t1(id int)
--------------

Query OK, 0 rows affected (0.01 sec)

--------------
insert into t1 values (1),(2),(3)
--------------

Query OK, 3 rows affected (0.00 sec)

--------------
select * from t1
--------------

+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.00 sec)

Bye
2025-02-18 16:42:27.407 UTC+0800    [INFO]    End executing query select version(), git_version(); create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3); select * from t1;, succeeded
2025-02-18 16:42:27.416 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select version(), git_version(); create database test; use test; create table t1(id int); insert into t1 values (1),(2),(3); select * from t1;,succeeded,38

github@shpc2-10-222-1-9:/data$ mo_ctl upgrade v2.0.2
2025-02-18 16:43:28.923 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3515961       1 11 16:41 ?        00:00:14 /data/mo/test/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/test/matrixone/etc/launch/launch.toml
2025-02-18 16:43:28.928 UTC+0800    [INFO]    List of pid(s): 
3515961
2025-02-18 16:43:28.934 UTC+0800    [ERROR]    Please make sure no mo-service is running.
2025-02-18 16:43:28.939 UTC+0800    [INFO]    You may use 'mo_ctl stop [force]' to stop mo-service
2025-02-18 16:43:28.961 UTC+0800    [INFO]    watchdog status：disabled

github@shpc2-10-222-1-9:/data$ mo_ctl stop force 
2025-02-18 16:43:48.906 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3515961       1 11 16:41 ?        00:00:16 /data/mo/test/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/test/matrixone/etc/launch/launch.toml
2025-02-18 16:43:48.911 UTC+0800    [INFO]    List of pid(s): 
3515961
2025-02-18 16:43:48.917 UTC+0800    [INFO]    Try stop all mo-services found for a maximum of 10 times, try no: 1
2025-02-18 16:43:48.922 UTC+0800    [INFO]    Stopping mo-service with pid 3515961 with command: kill -9 3515961
2025-02-18 16:43:48.928 UTC+0800    [INFO]    Wait for 5 seconds
2025-02-18 16:43:53.947 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:43:53.953 UTC+0800    [INFO]    Stop succeeded

github@shpc2-10-222-1-9:/data$ mo_ctl watchdog
2025-02-18 16:44:04.017 UTC+0800    [INFO]    watchdog status：disabled

github@shpc2-10-222-1-9:/data$ mo_ctl upgrade v2.0.2
2025-02-18 16:44:46.927 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:44:46.949 UTC+0800    [INFO]    watchdog status：disabled
2025-02-18 16:44:47.053 UTC+0800    [INFO]    Target: v2.0.2
2025-02-18 16:44:47.063 UTC+0800    [INFO]    Current info:
2025-02-18 16:44:47.069 UTC+0800    [INFO]    Commit id: 25b06b2c, branch: 2.0-dev, tag: 
2025-02-18 16:44:47.098 UTC+0800    [INFO]    Tag v2.0.2 mathces target v2.0.2
2025-02-18 16:44:47.103 UTC+0800    [INFO]    target_type: tag, actual_target: v2.0.2
2025-02-18 16:44:47.108 UTC+0800    [INFO]    Back up mo path from /data/mo/test/matrixone to /data/mo/test/matrixone-UPGRADE-BK-20250218_164447
2025-02-18 16:44:47.119 UTC+0800    [INFO]    Succeeded
2025-02-18 16:44:47.125 UTC+0800    [INFO]    Deploying new mo on target tag v2.0.2
2025-02-18 16:44:47.138 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="git"
2025-02-18 16:44:47.143 UTC+0800    [INFO]    Precheck on pre-requisite: go
2025-02-18 16:44:47.148 UTC+0800    [INFO]    Ok. go is installed
2025-02-18 16:44:47.159 UTC+0800    [INFO]    Version check on go. Current: 1.23.0, required: 1.20
2025-02-18 16:44:47.165 UTC+0800    [INFO]    Ok. go version is greater than or equal to required
2025-02-18 16:44:47.170 UTC+0800    [INFO]    Precheck on pre-requisite: gcc
2025-02-18 16:44:47.176 UTC+0800    [INFO]    Ok. gcc is installed
2025-02-18 16:44:47.183 UTC+0800    [INFO]    Version check on gcc. Current: 12.2.0, required: 8.5.0
2025-02-18 16:44:47.189 UTC+0800    [INFO]    Ok. gcc version is greater than or equal to required
2025-02-18 16:44:47.194 UTC+0800    [INFO]    Precheck on pre-requisite: git
2025-02-18 16:44:47.200 UTC+0800    [INFO]    Ok. git is installed
2025-02-18 16:44:47.205 UTC+0800    [INFO]    Precheck on pre-requisite: mysql
2025-02-18 16:44:47.211 UTC+0800    [INFO]    Ok. mysql is installed
2025-02-18 16:44:47.216 UTC+0800    [INFO]    Precheck on pre-requisite: docker
2025-02-18 16:44:47.221 UTC+0800    [INFO]    Conf MO_DEPLOY_MODE is set to 'git', ignoring docker
2025-02-18 16:44:47.227 UTC+0800    [INFO]    All pre-requisites are ok
2025-02-18 16:44:47.232 UTC+0800    [INFO]    Precheck passed, deploying mo now
2025-02-18 16:44:47.238 UTC+0800    [INFO]    Deploying mo on path /data/mo/test
2025-02-18 16:44:47.243 UTC+0800    [INFO]    Try number: 1
2025-02-18 16:44:47.249 UTC+0800    [INFO]    cd /data/mo/test && git clone https://github.com/matrixorigin/matrixone.git
Cloning into 'matrixone'...
remote: Enumerating objects: 195965, done.
remote: Counting objects: 100% (493/493), done.
remote: Compressing objects: 100% (276/276), done.
remote: Total 195965 (delta 343), reused 217 (delta 217), pack-reused 195472 (from 4)
Receiving objects: 100% (195965/195965), 123.12 MiB | 1.86 MiB/s, done.
Resolving deltas: 100% (145582/145582), done.
2025-02-18 16:45:57.289 UTC+0800    [INFO]    Git clone source codes succeeded, judging if checkout is needed
2025-02-18 16:45:57.302 UTC+0800    [INFO]    Trying to checkout to v2.0.2
2025-02-18 16:45:57.334 UTC+0800    [INFO]    mo_version: v2.0.2, type: tag
Note: switching to 'v2.0.2'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by switching back to a branch.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -c with the switch command. Example:

  git switch -c <new-branch-name>

Or undo this operation with:

  git switch -

Turn off this advice by setting config variable advice.detachedHead to false

HEAD is now at 83164a179 fix top container reset (#21208) (#21335)
2025-02-18 16:45:57.614 UTC+0800    [INFO]    GOPROXY is set, setting go proxy to GOPROXY=https://mirrors.aliyun.com/goproxy,direct
2025-02-18 16:45:57.625 UTC+0800    [INFO]    Try to build mo-service: make build
[Create build config]
make[1]: Entering directory '/data/mo/test/matrixone/cgo'
cc -std=c99 -g -O3 -Wall -Werror   -c -o mo.o mo.c
cc -std=c99 -g -O3 -Wall -Werror   -c -o arith.o arith.c
cc -std=c99 -g -O3 -Wall -Werror   -c -o compare.o compare.c
cc -std=c99 -g -O3 -Wall -Werror   -c -o logic.o logic.c
ar -rcs libmo.a *.o
make[1]: Leaving directory '/data/mo/test/matrixone/cgo'
[Build binary]
CGO_CFLAGS="-I/data/mo/test/matrixone/cgo " CGO_LDFLAGS="-L/data/mo/test/matrixone/cgo -lm -lmo" go build   -ldflags="-X 'github.com/matrixorigin/matrixone/pkg/version.GoVersion=go version go1.23.0 linux/amd64' -X 'github.com/matrixorigin/matrixone/pkg/version.BranchName=HEAD' -X 'github.com/matrixorigin/matrixone/pkg/version.CommitID=83164a179' -X 'github.com/matrixorigin/matrixone/pkg/version.BuildTime=1739868361' -X 'github.com/matrixorigin/matrixone/pkg/version.Version=v2.0.2'"  -o mo-service ./cmd/mo-service
2025-02-18 16:46:48.320 UTC+0800    [INFO]    Build succeeded
2025-02-18 16:46:48.326 UTC+0800    [INFO]    Creating mo logs /data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs path in case it does not exist
2025-02-18 16:46:48.332 UTC+0800    [INFO]    Deoloy succeeded
2025-02-18 16:46:48.338 UTC+0800    [INFO]    Setting mo conf file
2025-02-18 16:46:48.343 UTC+0800    [INFO]    Conf source path MO_CONF_SRC_PATH: /data/cus_reg/mo_confs/, file name: cn.toml
2025-02-18 16:46:48.355 UTC+0800    [INFO]    Conf source path MO_CONF_SRC_PATH: /data/cus_reg/mo_confs/, file name: tn.toml
2025-02-18 16:46:48.366 UTC+0800    [INFO]    Conf source path MO_CONF_SRC_PATH: /data/cus_reg/mo_confs/, file name: log.toml
2025-02-18 16:46:48.378 UTC+0800    [INFO]    Backup new mo confs and copy confs from old mo to new mo
2025-02-18 16:46:48.392 UTC+0800    [INFO]    Copy mo-data from old mo to new mo
2025-02-18 16:46:48.500 UTC+0800    [INFO]    Branch or tag before upgrade: 2.0-dev
2025-02-18 16:46:48.505 UTC+0800    [INFO]    Branch or tag after upgrade: 2.0-dev
2025-02-18 16:46:48.511 UTC+0800    [INFO]    --------------------------------
2025-02-18 16:46:48.517 UTC+0800    [INFO]    Commit id before upgrade:
2025-02-18 16:44:46.957 UTC+0800    [INFO]    Try get mo commit id
commit 25b06b2ca563296e52d0c85fcc0e50b3525db871
Author: YANGGMM <www.yangzhao123@gmail.com>
Date:   Tue Dec 10 01:51:15 2024 +0800

    fix restore view with lower case table names equals to 0(#2.0-dev) (#20668)
    
    fix restore view with lower case table names equals to 0
    
    Approved by: @daviszhen, @heni02, @aressu1985, @sukki37
2025-02-18 16:44:46.965 UTC+0800    [INFO]    Get commit id succeeded
2025-02-18 16:46:48.527 UTC+0800    [INFO]    --------------------------------
2025-02-18 16:46:48.533 UTC+0800    [INFO]    Commit id after upgrade:
2025-02-18 16:46:48.486 UTC+0800    [INFO]    Try get mo commit id
commit 83164a1790d3bacb37c6e213615c78e157c52e09
Author: ou yuanning <45346669+ouyuanning@users.noreply.github.com>
Date:   Thu Jan 23 23:16:51 2025 +0800

    fix top container reset (#21208) (#21335)
    
    fix top container reset
    
    Approved by: @badboynt1, @sukki37
2025-02-18 16:46:48.494 UTC+0800    [INFO]    Get commit id succeeded
2025-02-18 16:46:48.544 UTC+0800    [INFO]    Upgrade succeeded. Please use 'mo_ctl start' or 'mo_ctl restart' to restart your mo-service
github@shpc2-10-222-1-9:/data$ mo_ctl start 
2025-02-18 16:47:48.366 UTC+0800    [INFO]    No mo-service is running
2025-02-18 16:47:48.382 UTC+0800    [INFO]    Get conf succeeded: MO_DEPLOY_MODE="git"
2025-02-18 16:47:48.388 UTC+0800    [INFO]    GO memory limit(Mi): 9542
2025-02-18 16:47:48.399 UTC+0800    [INFO]    Starting mo-service: cd /data/mo/test/matrixone/ && GOMEMLIMIT=9542MiB /data/mo/test/matrixone/mo-service -daemon -debug-http :9876  -launch /data/mo/test/matrixone/etc/launch/launch.toml >/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/stdout-20250218_164748.log 2>/data/cus_reg_bk/mo/log_ym/log_date/mo-backup/logs/stderr-20250218_164748.log
2025-02-18 16:47:48.434 UTC+0800    [INFO]    Wait for 2 seconds
2025-02-18 16:47:50.454 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3522142       1 11 16:47 ?        00:00:00 /data/mo/test/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/test/matrixone/etc/launch/launch.toml
2025-02-18 16:47:50.460 UTC+0800    [INFO]    List of pid(s): 
3522142
2025-02-18 16:47:50.465 UTC+0800    [INFO]    Start succeeded
github@shpc2-10-222-1-9:/data$ mo_ctl status
2025-02-18 16:47:58.510 UTC+0800    [INFO]    At least one mo-service is running. Process info: 
github   3522142       1 13 16:47 ?        00:00:01 /data/mo/test/matrixone/mo-service -daemon -debug-http :9876 -launch /data/mo/test/matrixone/etc/launch/launch.toml
2025-02-18 16:47:58.516 UTC+0800    [INFO]    List of pid(s): 
3522142
github@shpc2-10-222-1-9:/data$ mo_ctl sql "select version(), git_version(); show databases; select * from test.t1;"
2025-02-18 16:48:17.661 UTC+0800    [INFO]    Input "select version(), git_version(); show databases; select * from test.t1;" is not a path or a file, try to execute it as a query
2025-02-18 16:48:17.666 UTC+0800    [INFO]    Begin executing query "select version(), git_version(); show databases; select * from test.t1;"
--------------
select version(), git_version()
--------------

+-------------------------+---------------+
| version()               | git_version() |
+-------------------------+---------------+
| 8.0.30-MatrixOne-v2.0.2 | 83164a179     |
+-------------------------+---------------+
1 row in set (0.01 sec)

--------------
show databases
--------------

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mo_catalog         |
| mo_debug           |
| mo_task            |
| mysql              |
| system             |
| system_metrics     |
| test               |
+--------------------+
8 rows in set (0.00 sec)

--------------
select * from test.t1
--------------

+------+
| id   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.00 sec)

Bye
2025-02-18 16:48:17.683 UTC+0800    [INFO]    End executing query select version(), git_version(); show databases; select * from test.t1;, succeeded
2025-02-18 16:48:17.693 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select version(), git_version(); show databases; select * from test.t1;,succeeded,10
```