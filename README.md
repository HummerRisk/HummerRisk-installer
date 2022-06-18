# HummerRisk 安装管理包

installer 可以安装、部署、更新 管理 hummerrisk

## 安装部署

```bash
cd installer

# 安装，版本是在 static.env 指定的
./hrctl.sh install

# 检查更新
./hrctl.sh check_update

# 升级到 static.env 中的版本
./hrctl.sh upgrade

# 升级到指定版本
./hrctl.sh upgrade v0.1.0
```

## 离线安装
```bash
# 生成离线包
$ cd scripts && bash 0_prepare.sh

# 完成以后将这个包压缩，复制到想安装的机器，直接安装即可
$ ./hrctl.sh install
```

## 管理命令

```bash
# 启动
./hrctl.sh start

# 停止
./hrctl.sh stop

# 重启
./hrctl.sh restart

# 升级
./hrctl.sh upgrade

# 卸载
./hrctl.sh uninstall

# 帮助
./hrctl.sh --help
```

## 配置文件说明

配置文件将会放在 /opt/hummerrisk/config 中

```
[root@hummerrisk hummerrisk]# tree .
├── conf
│   ├── mysql                      
│   │   ├── mysql.cnf               # mysql 配置文件
│   │   └── sql
│   │       └── hummerrisk.sql     # mysql 初始化数据库脚本
│   ├── hummerrisk.properties      # hummerrisk 配置文件
│   └── version                     # 版本文件
└── config
    └── config.txt                  # 主配置文件

4 directories, 5 files
```

### config.txt 说明

config.txt 文件是环境变量式配置文件，会挂在到各个容器中

config-example.txt 有说明，可以参考
