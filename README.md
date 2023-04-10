# HummerRisk 安装管理包

installer 可以安装、部署、更新 管理 hummerrisk

## 安装部署

```bash
cd installer

# 安装，版本是在 static.env 指定的
hrctl install

# 升级到 static.env 中的版本
hrctl upgrade v0.9.0

# 升级到指定版本
hrctl upgrade v0.9.0
```


## 管理命令

```bash
# 启动
hrctl start

# 停止
hrctl stop

# 重启
hrctl restart

# 升级
hrctl upgrade

# 卸载
hrctl uninstall

# 备份数据库
hrctl backup_db

# 还原数据库
hrctl restore_db /opt/hummerrisk/db_backup/hummerrisk-xx.sql
# 帮助
hrctl --help
```

## 配置文件说明

配置文件将会放在 /opt/hummerrisk/conf 中

```
[root@VM-25-15-centos ~]# tree /opt/hummerrisk/conf/
/opt/hummerrisk/conf/
├── hummerrisk
│   ├── aws-config            # aws配置文件
│   └── hummerrisk.properties # hummerrisk 的配置文件
├── install.conf              #  # 整个项目的配置文件
└── mysql
    ├── hummerrisk.sql        # 初始化 SQL
    └── mysql.cnf             # MySQL 数据库的配置文件

3 directories, 4 files
```

### install.conf 说明

install.conf 文件是环境变量式配置文件，会挂在到各个容器中

install.conf 有说明，可以参考

### 组件端口说明

| 组件名称        | 端口             | 说明 |
|-------------|----------------|--|
| hmr-ui      | 80             |  |
| hmr-flyway  | 9000           |  |
| hmr-gateway | 8080           |  |
| hmr-auth    | 9200           |  |
| hmr-system  | 9300,9301,8001 |  |
| hmr-cloud   | 9400,9401,8002 |  |
| hmr-k8s     | 9500,9501,8003 |  |
| hmr-monitor | 9100           |  |
| hmr-mysql   | 3306           |  |
| hmr-nacos   | 8848,9848      |  |
| hmr-redis   | 6379           |  |
| hmr-job     | 8084           |  |
