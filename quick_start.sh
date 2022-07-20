#!/bin/bash
#

set -e
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
export VERSION=$(curl -s https://api.github.com/repos/alvin5840/HummerRisk/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

hummerrisk_online_file_name="hummerrisk-${VERSION}-online.tar.gz"

function get_installer() {
  echo "Download install script to hummerrisk-installer-${VERSION} (开始下载安装脚本到 hummerrisk-installer-${VERSION})"
  if [ ! -d "hummerrisk-installer-${VERSION}" ]; then
    curl -LOk -m 60 -o "${hummerrisk_online_file_name}" https://github.com/alvin5840/hummerrisk/releases/download/"${VERSION}"/"${hummerrisk_online_file_name}" || {
    rm -rf "${hummerrisk_online_file_name}"
    echo -e "[\033[31m ERROR \033[0m] Failed to download hummerrisk-installer-${VERSION} (下载 hummerrisk-installer-${VERSION} 失败, 请检查网络是否正常或尝试重新执行脚本)"
    exit 1
    }
    tar -zxf "${hummerrisk_online_file_name}" || {
      rm -rf hummerrisk-installer-"${VERSION}"
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip hummerrisk-installer-${VERSION} (解压 hummerrisk-installer-${VERSION} 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    rm -rf "${hummerrisk_online_file_name}"
  fi
}

function config_installer() {
  cd hummerrisk-"${VERSION}"-online|| exit 1
  sed -i -e "1,4s/VERSION=.*/VERSION=${VERSION}/g" scripts/const.sh
}

function main(){
  get_installer
  config_installer
  /bin/bash install.sh
}

main
