#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

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
}

function post_install() {
  echo_green "\n>>>  'The Installation is Complete'"
  HOST=$(ip addr | grep 'state UP' -A2 | grep inet | grep -Ev '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | head -n 1 | cut -d / -f1)
  if [ ! "$HOST" ]; then
      HOST=$(hostname -I | cut -d ' ' -f1)
  fi
  HTTP_PORT=$(get_config HTTP_PORT)

  echo_yellow "1.  'You can use the following command to start, and then visit'"
  echo "cd ${PROJECT_DIR}"
  echo "hrctl start"

  echo_yellow "\n2.  'Other management commands'"
  echo "hrctl stop"
  echo "hrctl restart"
  echo "hrctl backup"
  echo "hrctl upgrade"
  echo " 'For more commands, you can enter hrctl --help to understand'"

  echo_yellow "\n3.  'Web access'"
  echo "http://${HOST}:${HTTP_PORT}"
  echo " 'Default username'): admin   'Default password'): hummer"

  echo_yellow "\n4.  'More information'"
  echo " 'Offical Website'): https://www.hummerrisk.com/"
  echo " 'Documentation'): https://docs.hummerrisk.com/"
  echo -e "\n\n"
}

function main() {
  echo_logo
  pre_install
  prepare_config
  echo "Test 4_install: 当前目录 $(pwd)"
  set_current_version
  echo_green "\n>>>  'Install and Configure Docker'"
  if ! bash "${BASE_DIR}/2_install_docker.sh"; then
    exit 1
  fi
  echo_green "\n>>>  'Loading Docker Image'"
  if ! bash "${BASE_DIR}/3_load_images.sh"; then
    exit 1
  fi
  echo_green "\n>>>  'Install and Configure hummerrisk'"
  if ! bash "${BASE_DIR}/1_config_hummerrisk.sh"; then
    exit 1
  fi
  hrctl start
  post_install
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
