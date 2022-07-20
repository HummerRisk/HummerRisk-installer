#!/usr/bin/env bash
#
export CURRENT_DIR=$(cd "$(dirname "$0")";pwd)

. "${CURRENT_DIR}/scripts/utils.sh"

function prepare_config() {
  cd "${PROJECT_DIR}" || exit 1
  echo "Test:prepare_config ,查看当前目录 $(pwd)，抽空配置文件目录CONFIG_DIR ${CONFIG_DIR} --${PROJECT_DIR}/compose/.env"
  # 设置 hummerrisk 安装目录
  sed -i "1,4s@HR_BASE=.*@HR_BASE=${HR_BASE}@g" hrctl
  \cp -rp hrctl /usr/bin/hrctl
  chmod 755 /usr/bin/hrctl

  echo_yellow "1.  'Check Configuration File'"
  echo " 'Path to Configuration file'): ${CONFIG_DIR}"
  echo "Test install.sh: 当前目录 $(pwd) PROJECT_DIR:${PROJECT_DIR}"
#  if [[ ! -d "${CONFIG_DIR}" ]]; then
#    fi
    mkdir -p "${CONFIG_DIR}"
    cp install.conf "${CONFIG_FILE}"
    \cp -rp ${PROJECT_DIR}/config_init/*  "${CONFIG_DIR}"
    echo "Test：执行copy instll.conf 到 ${CONFIG_FILE}"
    echo -e "${CONFIG_FILE}  [\033[32m √ \033[0m]"
#  if [[ ! -f .env ]]; then
#    ln -s ${CONFIG_FILE} .env
#  fi
  if [[ ! -f "${PROJECT_DIR}/compose/.env" ]]; then
    ln -s "${CONFIG_FILE}" ${PROJECT_DIR}/compose/.env
  fi
  chmod 644 -R ${CONFIG_DIR}
  echo_done

  backup_dir="${HR_BASE}/backup"
  if [[ ! -d "${backup_dir}" ]]; then
    mkdir -p ${backup_dir}
  fi
  now=$(date +'%Y-%m-%d_%H-%M-%S')
  backup_config_file="${backup_dir}/install.conf.${now}"
  echo_yellow "\n2.  'Backup Configuration File'"
  \cp -rp ${CONFIG_FILE} ${backup_config_file}
  echo " 'Back up to') ${backup_config_file}"

  echo_done
}

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
  echo " 'Default username': admin   'Default password'): hummer"

  echo_yellow "\n4.  'More information'"
  echo " 'Offical Website'): https://www.hummerrisk.com/"
  echo " 'Documentation': https://docs.hummerrisk.com/"
  echo -e "\n\n"
}

function main() {
  echo_logo
  pre_install
  prepare_config
  set_current_version
  echo_green "\n>>>  'Install and Configure Docker'"
  if ! bash "${SCRIPT_DIR}/2_install_docker.sh"; then
    exit 1
  fi
  echo_green "\n>>>  'Loading Docker Image'"
  if ! bash "${SCRIPT_DIR}/3_load_images.sh"; then
    exit 1
  fi
  echo_green "\n>>>  'Install and Configure hummerrisk'"
  if ! bash "${SCRIPT_DIR}/4_config_hummerrisk.sh"; then
    exit 1
  fi
  hrctl start
  post_install
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
