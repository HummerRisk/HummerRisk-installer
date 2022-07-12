#!/bin/bash
#

Version=dev

function install_soft() {
    if command -v dnf > /dev/null; then
      if [ "$1" == "python" ]; then
        dnf -q -y install python2
        ln -s /usr/bin/python2 /usr/bin/python
      else
        dnf -q -y install $1
      fi
    elif command -v yum > /dev/null; then
      yum -q -y install $1
    elif command -v apt > /dev/null; then
      apt-get -qqy install $1
    elif command -v zypper > /dev/null; then
      zypper -q -n install $1
    elif command -v apk > /dev/null; then
      apk add -q $1
    else
      echo -e "[\033[31m ERROR \033[0m] Please install it first (请先安装) $1 "
      exit 1
    fi
}

function prepare_install() {
  for i in curl wget zip python; do
    command -v $i &>/dev/null || install_soft $i
  done
}

function get_installer() {
  echo "download install script to /opt/hummerrisk-installer-${Version} (开始下载安装脚本到 /opt/hummerrisk-installer-${Version})"
  cd /opt || exit
  if [ ! -d "/opt/hummerrisk-installer-${Version}" ]; then
    timeout 60s wget -qO hummerrisk-installer-${Version}.tar.gz https://github.com/HummerRisk/HummerRisk/releases/download/${Version}/hummerrisk-installer-${Version}.tar.gz || {
      rm -rf /opt/hummerrisk-installer-${Version}.tar.gz
      echo -e "[\033[31m ERROR \033[0m] Failed to download hummerrisk-installer-${Version} (下载 hummerrisk-installer-${Version} 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    tar -xf /opt/hummerrisk-installer-${Version}.tar.gz -C /opt || {
      rm -rf /opt/hummerrisk-installer-${Version}
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip hummerrisk-installer-${Version} (解压 hummerrisk-installer-${Version} 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    rm -rf /opt/hummerrisk-installer-${Version}.tar.gz
  fi
}

function config_installer() {
  cd /opt/hummerrisk-installer-${Version} || exit 1
  sed -i "s/VERSION=.*/VERSION=${Version}/g" /opt/hummerrisk-installer-${Version}/static.env
  ./hrctl.sh install
  ./hrctl.sh start
}

function main(){
  prepare_install
  get_installer
  config_installer
}
main
