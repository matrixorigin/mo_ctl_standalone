# `connect`
## 1. 作用
通过本地的mysql客户端，根据配置的连接信息，登录到数据库并提供交互操作界面。

## 2. 用法
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl connect help
Usage         : mo_ctl connect # connect to mo via mysql client using connection info configured
Note          : Please set below confs first
                1. MO_HOST (optional, default: 127.0.0.1): ip or domain name of target mo to connect, default: 127.0.0.1
                2. MO_PORT (optional, default: 6001): port of target mo to connect
                3. MO_USER (optional, default: dump): user name of target mo to connect
                4. MO_PW (optional, default: 111): user password of target mo to connect
Examples      : mo_ctl set_conf MO_HOST=127.0.0.1
                mo_ctl set_conf MO_PORT=6001
                mo_ctl set_conf MO_USER=dump
                mo_ctl set_conf MO_PW=111
                mo_ctl connect
```

## 3. 前提条件
请先设置相关的参数，说明如下：
```bash
mo_ctl set_conf MO_HOST=127.0.0.1  # 主机名或IP
mo_ctl set_conf MO_PORT=6001 # 端口号
mo_ctl set_conf MO_HOST=dump  # 用户名
mo_ctl set_conf MO_HOST=111  # 用户密码
```

## 4. 示例
### 4.1 客户端与服务端为同一环境，连接到本地MO
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_HOST=127.0.0.1
2025-01-21 14:22:12.678 UTC+0800    [DEBUG]    conf list: MO_HOST=127.0.0.1
2025-01-21 14:22:12.686 UTC+0800    [INFO]    Try to set conf: MO_HOST="127.0.0.1"
2025-01-21 14:22:12.693 UTC+0800    [DEBUG]    key: MO_HOST, value: 127.0.0.1
2025-01-21 14:22:12.699 UTC+0800    [INFO]    Setting conf MO_HOST="127.0.0.1"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_PORT=6001
2025-01-21 14:22:17.460 UTC+0800    [DEBUG]    conf list: MO_PORT=6001
2025-01-21 14:22:17.468 UTC+0800    [INFO]    Try to set conf: MO_PORT="6001"
2025-01-21 14:22:17.475 UTC+0800    [DEBUG]    key: MO_PORT, value: 6001
2025-01-21 14:22:17.481 UTC+0800    [INFO]    Setting conf MO_PORT="6001"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_USER=dump
2025-01-21 14:22:21.902 UTC+0800    [DEBUG]    conf list: MO_USER=dump
2025-01-21 14:22:21.909 UTC+0800    [INFO]    Try to set conf: MO_USER="dump"
2025-01-21 14:22:21.916 UTC+0800    [DEBUG]    key: MO_USER, value: dump
2025-01-21 14:22:21.922 UTC+0800    [INFO]    Setting conf MO_USER="dump"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_PW=111
2025-01-21 14:22:25.446 UTC+0800    [DEBUG]    conf list: MO_PW=111
2025-01-21 14:22:25.454 UTC+0800    [INFO]    Try to set conf: MO_PW="111"
2025-01-21 14:22:25.460 UTC+0800    [DEBUG]    key: MO_PW, value: 111
2025-01-21 14:22:25.466 UTC+0800    [INFO]    Setting conf MO_PW="111"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl connect
2025-01-21 14:22:29.133 UTC+0800    [INFO]    Checking connectivity
2025-01-21 14:22:29.154 UTC+0800    [INFO]    Ok, connecting for user ... 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 210
Server version: 8.0.30-MatrixOne-v MatrixOne

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+---------------------+
| Database            |
+---------------------+
| mydb1               |
| mydb2               |
| information_schema  |
| mydb3               |
| master_oneiov       |
| mo_catalog          |
| mo_debug            |
| mo_task             |
| mysql               |
| mydb99              |
| system              |
| system_metrics      |
| yourdb              |
+---------------------+
13 rows in set (0.00 sec)
```

### 4.1 客户端与服务端为不同环境，连接到远端MO
```bash
github@test0:/data$ ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 79176sec preferred_lft 79176sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:65:cf:9d brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 10.222.4.0/16 brd 10.222.255.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe65:cf9d/64 scope link 
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:9d:60:ad:df brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
github@test0:/data$ mo_ctl set_conf MO_HOST=10.222.1.9
2025-01-21 14:26:50.946 UTC+0800    [DEBUG]    conf list: MO_HOST=10.222.1.9
2025-01-21 14:26:51.459 UTC+0800    [INFO]    Try to set conf: MO_HOST="10.222.1.9"
2025-01-21 14:26:51.879 UTC+0800    [DEBUG]    key: MO_HOST, value: 10.222.1.9
2025-01-21 14:26:52.064 UTC+0800    [INFO]    Setting conf MO_HOST="10.222.1.9"
github@test0:/data$ mo_ctl set_conf MO_PORT=6001
2025-01-21 14:26:57.511 UTC+0800    [DEBUG]    conf list: MO_PORT=6001
2025-01-21 14:26:58.231 UTC+0800    [INFO]    Try to set conf: MO_PORT="6001"
2025-01-21 14:26:58.305 UTC+0800    [DEBUG]    key: MO_PORT, value: 6001
2025-01-21 14:26:58.391 UTC+0800    [INFO]    Setting conf MO_PORT="6001"
github@test0:/data$ mo_ctl set_conf MO_USER=dump
2025-01-21 14:27:02.605 UTC+0800    [DEBUG]    conf list: MO_USER=dump
2025-01-21 14:27:02.987 UTC+0800    [INFO]    Try to set conf: MO_USER="dump"
2025-01-21 14:27:03.241 UTC+0800    [DEBUG]    key: MO_USER, value: dump
2025-01-21 14:27:03.324 UTC+0800    [INFO]    Setting conf MO_USER="dump"
github@test0:/data$ mo_ctl set_conf MO_PW=111
2025-01-21 14:27:07.024 UTC+0800    [DEBUG]    conf list: MO_PW=111
2025-01-21 14:27:07.110 UTC+0800    [INFO]    Try to set conf: MO_PW="111"
2025-01-21 14:27:07.154 UTC+0800    [DEBUG]    key: MO_PW, value: 111
2025-01-21 14:27:07.225 UTC+0800    [INFO]    Setting conf MO_PW="111"
github@test0:/data$ mo_ctl connect
2025-01-21 14:27:09.562 UTC+0800    [INFO]    Checking connectivity
2025-01-21 14:27:09.727 UTC+0800    [INFO]    Ok, connecting for user ... 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 221
Server version: 8.0.30-MatrixOne-v MatrixOne

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+---------------------+
| Database            |
+---------------------+
| mydb1               |
| mydb2               |
| information_schema  |
| mydb3               |
| master_oneiov       |
| mo_catalog          |
| mo_debug            |
| mo_task             |
| mysql               |
| mydb99              |
| system              |
| system_metrics      |
| yourdb              |
+---------------------+
13 rows in set (0.00 sec)
```

### 4.3 客户端与服务端为不同环境，连接到MO Cloud实例
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_HOST="freetier-01.cn-hangzhou.cluster.matrixonecloud.cn"
2025-01-21 14:29:15.378 UTC+0800    [DEBUG]    conf list: MO_HOST=freetier-01.cn-hangzhou.cluster.matrixonecloud.cn
2025-01-21 14:29:15.386 UTC+0800    [INFO]    Try to set conf: MO_HOST="freetier-01.cn-hangzhou.cluster.matrixonecloud.cn"
2025-01-21 14:29:15.393 UTC+0800    [DEBUG]    key: MO_HOST, value: freetier-01.cn-hangzhou.cluster.matrixonecloud.cn
2025-01-21 14:29:15.399 UTC+0800    [INFO]    Setting conf MO_HOST="freetier-01.cn-hangzhou.cluster.matrixonecloud.cn"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_PORT=6001
2025-01-21 14:29:17.524 UTC+0800    [DEBUG]    conf list: MO_PORT=6001
2025-01-21 14:29:17.532 UTC+0800    [INFO]    Try to set conf: MO_PORT="6001"
2025-01-21 14:29:17.538 UTC+0800    [DEBUG]    key: MO_PORT, value: 6001
2025-01-21 14:29:17.544 UTC+0800    [INFO]    Setting conf MO_PORT="6001"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_USER="188ebcb8_0747_4475_8c27_879xxxxxxxx:admin:accountadmin"
2025-01-21 14:29:19.381 UTC+0800    [DEBUG]    conf list: MO_USER=188ebcb8_0747_4475_8c27_879xxxxxxxx:admin:accountadmin
2025-01-21 14:29:19.390 UTC+0800    [INFO]    Try to set conf: MO_USER="188ebcb8_0747_4475_8c27_879xxxxxxxx:admin:accountadmin"
2025-01-21 14:29:19.396 UTC+0800    [DEBUG]    key: MO_USER, value: 188ebcb8_0747_4475_8c27_879xxxxxxxx:admin:accountadmin
2025-01-21 14:29:19.402 UTC+0800    [INFO]    Setting conf MO_USER="188ebcb8_0747_4475_8c27_879xxxxxxxx:admin:accountadmin"
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl set_conf MO_PW="xxxxxxxx"
2025-01-21 14:29:21.150 UTC+0800    [DEBUG]    conf list: MO_PW=xxxxxxxx
2025-01-21 14:29:21.158 UTC+0800    [INFO]    Try to set conf: MO_PW="xxxxxxxx"
2025-01-21 14:29:21.164 UTC+0800    [DEBUG]    key: MO_PW, value: xxxxxxxx
2025-01-21 14:29:21.170 UTC+0800    [INFO]    Setting conf MO_PW="xxxxxxxx"

github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl connect
2025-01-21 14:29:23.839 UTC+0800    [INFO]    Checking connectivity
2025-01-21 14:29:24.027 UTC+0800    [INFO]    Ok, connecting for user ... 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2150913306
Server version: 8.0.30-MatrixOne-v2.0.1 MatrixOne

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+---------------------+
| Database            |
+---------------------+
| mydb1               |
| mydb2               |
| information_schema  |
| mydb3               |
| master_oneiov       |
| mo_catalog          |
| mo_debug            |
| mo_task             |
| mysql               |
| mydb99              |
| system              |
| system_metrics      |
| yourdb              |
+---------------------+
13 rows in set (0.00 sec)
```