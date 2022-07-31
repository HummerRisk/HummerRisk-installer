#!/usr/bin/env bash
#
. "./scripts/utils.sh"

export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

function pre_install() {
  if ! command -v systemctl &>/dev/null; then
    command -v docker >/dev/null || {
      log_error " 'The current Linux system does not support systemd management. Please deploy docker by yourself before running this script again'"
      exit 1
    }
    command -v docker-compose >/dev/null || {
      log_error " 'The current Linux system does not support systemd management. Please deploy docker-compose by yourself before running this script again'"
      exit 1
    }
  fi
  if [ -f /usr/bin/hrctl ]; then
     # 获取已安装的 hummerrisk 的运行目录
     HR_BASE=`grep "^HR_BASE=" /usr/bin/hrctl | cut -d'=' -f2`
     hrctl down
  fi
}

function post_install() {
  echo_green "\n>>>  'The Installation is Complete'"
  HOST=$(ip addr | grep 'state UP' -A2 | grep inet | grep -Ev '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | head -n 1 | cut -d / -f1)
  if [ ! "$HOST" ]; then
      HOST=$(hostname -I | cut -d ' ' -f1)
  fi
  HTTP_PORT=$(get_config HTTP_PORT)

  echo_yellow "1.  'You can use the following command to start, and then visit'"
#  echo "cd ${PROJECT_DIR}"
  echo "hrctl start"

  echo_yellow "\n2.  'Other management commands'"
  echo "hrctl stop"
  echo "hrctl restart"
  echo "hrctl backup"
  echo "hrctl upgrade"
  echo " 'For more commands, you can enter hrctl --help to understand'"

  echo_yellow "\n3.  'Web access'"
  echo "http://${HOST}:${HTTP_PORT}"
  echo " 'Default username': admin   'Default password': hummer"

  echo_yellow "\n4.  'More information'"
  echo " 'Offical Website': https://www.hummerrisk.com/"
  echo " 'Documentation': https://docs.hummerrisk.com/"
  echo -e "\n\n"
}

function main() {
  echo_logo
  pre_install
  echo_green "\n>>>  'Install and Configure Docker'"
  if ! bash "${SCRIPT_DIR}/2_install_docker.sh"; then
    exit 1
  fi
  echo_green "\n>>>  'Install and Configure hummerrisk'"
  if ! bash "${SCRIPT_DIR}/3_config_hummerrisk.sh"; then
    exit 1
  fi
  echo_green "\n>>>  'Loading Docker Image'"
  if ! bash "${SCRIPT_DIR}/4_load_images.sh"; then
    exit 1
  fi
  set_current_version
  post_install
  /bin/bash hrctl start
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
