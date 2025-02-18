# `get_branch`
## 1. 作用
（仅针对`git`部署模式适用）获取当前部署的代码分支，如果使用`tag`部署，则获取`tag`号。此外，一般配合`get_cid`使用，后者用于获取`commit_id`。

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_branch help
Usage         : mo_ctl get_branch [less] # print which git branch mo is currently on
  [less]      : (optional) print less info with branch only, otherwise print more info
Examples      : mo_ctl get_branch
                mo_ctl get_branch less
```
## 3. 前提条件
MO完成部署，且部署模式为`git`
## 4. 示例
打印完整信息，例如此处显示部署的mo所使用的代码为`main`分支
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_branch
2025-01-21 14:36:13.261 UTC+0800    [INFO]    Try get mo branch
2025-01-21 14:36:13.272 UTC+0800    [INFO]    Get branch succeeded, current branch: main
```

打印较少信息，只返回分支名称
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_branch less
main
```