#!/bin/bash
#

set -e
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
export VERSION=$(curl -s https://api.github.com/repos/HummerRisk/HummerRisk/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

hummerrisk_online_file_name="hummerrisk-${VERSION}-online.tar.gz"

function get_installer() {
  echo "Download install script to /opt/hummerrisk-installer-${VERSION} (开始下载安装脚本到 /opt/hummerrisk-installer-${VERSION})"
  cd /opt || exit
  if [ ! -d "/opt/hummerrisk-installer-${VERSION}" ]; then
    timeout 60s curl -LOk -m 60 -o "${hummerrisk_online_file_name}" https://github.com/hummerrisk/hummerrisk/releases/download/"${VERSION}"/"${hummerrisk_online_file_name}" || {
    rm -rf /opt/"${hummerrisk_online_file_name}"
    echo -e "[\033[31m ERROR \033[0m] Failed to download hummerrisk-installer-${VERSION} (下载 hummerrisk-installer-${VERSION} 失败, 请检查网络是否正常或尝试重新执行脚本)"
    exit 1
    }
    tar -xf /opt/"${hummerrisk_online_file_name}" -C /opt || {
      rm -rf /opt/hummerrisk-installer-"${VERSION}"
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip hummerrisk-installer-${VERSION} (解压 hummerrisk-installer-${VERSION} 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    rm -rf /opt/"${hummerrisk_online_file_name}"
  fi
}

function config_installer() {
  cd /opt/hummerrisk-installer-"${VERSION}" || exit 1
  sed -i -e "1,3s/VERSION=.*/VERSION=${VERSION}/g" /opt/hummerrisk-installer-"${VERSION}"/scripts/const.sh
}

function main(){
  get_installer
  config_installer
  ./hrctl install
}

main
