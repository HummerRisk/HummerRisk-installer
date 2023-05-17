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
     HMR_BASE=`grep "^HMR_BASE=" /usr/bin/hrctl | cut -d'=' -f2`
     hrctl down
  fi
}

function post_install() {
  if [[ $(docker exec -it hmr-auth sh -c 'curl http://system:9300/license') =~ 'true' ]];then
    echo_green "\n>>>  'Loading XPACK Plugin'"
    local  EXE="$(get_docker_compose_cmd_line) -f  ${HMR_BASE}/compose/docker-compose-xpack.yml"
    ${EXE} up -d
  fi
  echo_green "\n>>>  'The Installation is Complete'"
  HOST=$(ip addr | grep 'state UP' -A3 | grep inet | grep -Ev '(127.0.0.1|inet6|docker)' | awk '{print $2}' | tr -d "addr:" | head -n 1 | cut -d / -f1)
  if [ ! "$HOST" ]; then
      HOST=$(hostname -I | cut -d ' ' -f1)
  fi
  HTTP_PORT=$(get_config HMR_HTTP_PORT)

  rm -rf $(get_config HMR_BASE)/scripts/docker/
  rm -rf $(get_config HMR_BASE)/scripts/images/
  echo_yellow "1.  'You can use the following command to start, and then visit'"
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

function download_cve_data() {
    triy_db=trivy-offline-v2-$(get_config TRIVY_DB_VERSION).db.tar.gz
    triy_db_md5=trivy-offline-v2-$(get_config TRIVY_DB_VERSION).md5
    if [[ ! -f ${triy_db} ]]; then
      curl -LOk -m 600 -o ${triy_db} https://download.hummerrisk.com/offline-package/trivy/trivy-db//${triy_db}
      curl -LOk -m 600 -o ${triy_db_md5} https://download.hummerrisk.com/offline-package/trivy/trivy-db//${triy_db_md5}
    fi
    tar zxf ${triy_db} -C "${HMR_BASE}/data/trivy/"
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
  download_cve_data
  /bin/bash hrctl start
  post_install
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
