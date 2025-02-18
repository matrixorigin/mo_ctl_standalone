# `get_cid`
## 1. 作用
（仅针对`git`部署模式适用）获取当前部署的`commit_id`号。此外，一般配合`get_branch`使用，后者用于获取分支（`branch`）或标签（`tag`)。

## 2. 用法
使用帮助：
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_cid help
Usage         : mo_ctl get_cid [less] # print mo git commit id from the path configured
  [less]      : (optional) print less info with cid only, otherwise print more info
Examples      : mo_ctl get_cid
                mo_ctl get_cid less
```

## 3. 前提条件
MO完成部署，且部署模式为`git`

## 4. 示例
打印完整信息，例如此处显示部署的mo所使用的代码`commit_id`为`ef13f21e68fa06530c549b7808e99aaaa1ac7807`
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_cid
2025-01-21 14:39:27.448 UTC+0800    [INFO]    Try get mo commit id
commit ef13f21e68fa06530c549b7808e99aaaa1ac7807
Author: GreatRiver <14086886+LeftHandCold@users.noreply.github.com>
Date:   Mon Jan 20 18:54:13 2025 +0800

    Fix pitrtid is not unique and panic (#21293)
    
    Fix pitrtid is not unique and panic
    
    Approved by: @XuPeng-SH
2025-01-21 14:39:27.458 UTC+0800    [INFO]    Get commit id succeeded
```

打印较少信息，只返回8位`commit_id`信息
```bash
github@shpc2-10-222-1-9:/data/logs/mo_ctl/auto_clean_logs$ mo_ctl get_cid less
ef13f21e
```