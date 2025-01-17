# build_image
## 1. 作用
针对mo数据库进程的日志文件，按一定的规则进行切分，避免文件过大

## 2. 用法
```bash
Usage           : mo_ctl auto_log_rotate [option]            # 设置数据库日志文件自动切分
Options         : 
  [option]      : enable | disable | status(default)
```


## 3. 前提条件
请先设置相关的参数，说明如下：



***注意***：如果对相关参数进行了重新设置，需要先禁用（`disable`），再启用（`enable`），新的配置才能生效

## 4. 示例
### 4.1 按周期自动切分日志文件
