
# Check 996

帮助你检查项目996状态. 😎

```
Usage: check_996.rb [options]
    -s, --start WORK_START_TIME      start job time e.g. 10:00:00
    -e, --end WORK_END_TIME          end job time  e.g. 18:00:00
    -g, --git-log GIT_LOG_CMD        use git log command, default is `git log --all`
    -f, --filter FILTER              time range filter  e.g. last_[day|week|month|year] last_5_[day|week|month|year]   '2022-01-01 08:10:00,2022-10-01 08:10:00'
    -v, --version                    version
```

# 使用说明

## 依赖项目

* 确保你有  `ruby 2.7+`
* 如果有 `curl` or `wget` 可以帮助远程执行


### 步骤一:

终端，进入你想统计的git仓库

```bash
cd </path/to/your/git_repo>
```

### 步骤二 

终端使用如下命令

* curl support

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Mark24Code/check_996/main/check_996.rb)"
```

* wget support

```bash
ruby -e "$(wget https://raw.githubusercontent.com/Mark24Code/check_996/main/check_996.rb -O -)"
```

## 更多建议：

脚本下载在本地可以直接使用参数，远程执行也可以使用参数，使用 `--` 分隔参数： 

```
 <script>  -- -s 10:30 -e 19:30
```

例如自定义理论上的工作时间:

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Mark24Code/check_996/main/check_996.rb)" -- -s 10:30 -e 19:30
```

## 额外参数说明


#### 过滤器

如果我不想对全量git进行计算，只关心一段时间，可以使用 -f 参数

提供人性化语义化参数 

```bash
-f, --filter FILTER              time range filter  e.g. last_[day|week|month|year] last_5_[day|week|month|year]   '2022-01-01 08:10:00,2022-10-01 08:10:00'
```

例如

```bash
-f last_week
-f last_month
-f last_25_days
-f '2022-01-01 08:10:00,2022-10-01 08:10:00'
```


### 统计方式

默认使用 `git log --all` 会在当前分支进入可触达分支，也可以自己定义, 但是检查必须是 `git log xxxx`

```bash
-g, --git-log GIT_LOG_CMD        use git log command, default is `git log --all`
```


