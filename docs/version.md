# `version`
## 1. 作用
获取`mo_ctl`客户端工具和`mo`服务端的版本号

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:~$ mo_ctl version help
Usage        : mo_ctl version # show mo_ctl and matrixone version
```
## 3. 前提条件
`mo`服务端可正常连接

## 4 示例
```bash
github@shpc2-10-222-1-9:~$ mo_ctl version
2025-02-10 11:56:47.668 UTC+0800    [INFO]    Tool version (mo_ctl):
2025-02-10 11:56:47.674 UTC+0800    [INFO]    -------------------------------
2025-02-10 11:56:47.679 UTC+0800    [INFO]    mo_ctl V1.0

2025-02-10 11:56:47.685 UTC+0800    [INFO]    Server version (MatrixOne): 
2025-02-10 11:56:47.690 UTC+0800    [INFO]    -------------------------------
2025-02-10 11:56:47.696 UTC+0800    [INFO]    Input "select version()" is not a path or a file, try to execute it as a query
2025-02-10 11:56:47.701 UTC+0800    [INFO]    Begin executing query "select version()"
--------------
select version()
--------------

+-------------------------+
| version()               |
+-------------------------+
| 8.0.30-MatrixOne-v2.1.0 |
+-------------------------+
1 row in set (0.00 sec)

Bye
2025-02-10 11:56:47.726 UTC+0800    [INFO]    End executing query select version(), succeeded
2025-02-10 11:56:47.735 UTC+0800    [INFO]    Query report:
query,outcome,time_cost_ms
select version(),succeeded,17
```