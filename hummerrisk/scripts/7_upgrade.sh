#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

target=$1

function prepare_new_package() {
  hummerrisk_online_file_name="hummerrisk-installer-${to_version}.tar.gz"
  echo "Download install script to hummerrisk-installer-${to_version} (开始下载包到 hummerrisk-installer-${to_version})"
  if [ ! -d "hummerrisk-installer-${to_version}" ]; then
    curl -LOk -m 60 -o "${hummerrisk_online_file_name}" https://github.com/alvin5840/hummerrisk/releases/download/"${to_version}"/"${hummerrisk_online_file_name}" || {
    rm -rf "${hummerrisk_online_file_name}"
    echo -e "[\033[31m ERROR \033[0m] Failed to download hummerrisk-installer-${to_version} (下载 hummerrisk-installer-${to_version} 失败, 请检查网络是否正常或尝试重新执行脚本)"
    exit 1
    }
    tar -zxf "${hummerrisk_online_file_name}" || {
      rm -rf hummerrisk-installer-"${to_version}"
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip hummerrisk-installer-${to_version} (解压 hummerrisk-installer-${to_version} 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    rm -rf "${hummerrisk_online_file_name}"
  fi
}

function upgrade_config() {
  confirm="n"
  # 处理版本
  to_version="${VERSION}"
  if [[ -n "${target}" ]]; then
    to_version="${target}"
  else
    echo to_version=$(get_latest_version)
  fi
  if [[ "${to_version}" && "${to_version}" != "${VERSION}" ]]; then
    prepare_new_package
    cd hummerrisk-installer-"${to_version}"|| exit 1
    sed -i -e "1,4s/VERSION=.*/VERSION=${to_version}/g" scripts/const.sh
    sed -i "s@VERSION=.*@VERSION=${to_version}@g" "${SCRIPT_DIR}/const.sh"
    sed -i "s@HR_CURRENT_VERSION=.*@HR_CURRENT_VERSION=${to_version}@g" "${CONFIG_FILE}"
    export VERSION=${to_version}
    /bin/bash install.sh
  fi
  echo
}

function backup_db() {
  if docker ps | grep hummer_risk >/dev/null; then
      docker stop hummer_risk
      docker rm hummer_risk
      sleep 2s
      echo
  fi
  if [[ "${SKIP_BACKUP_DB}" != "1" ]]; then
    if ! bash "${SCRIPT_DIR}/5_db_backup.sh"; then
      confirm="n"
      read_from_input confirm " 'Failed to backup the database. Continue to upgrade'?" "y/n" "${confirm}"
      if [[ "${confirm}" == "n" ]]; then
        exit 1
      fi
    fi
  else
    echo "SKIP_BACKUP_DB=${SKIP_BACKUP_DB},  'Skip database backup'"
  fi
}

function clear_images() {
  current_version=$(get_config CURRENT_VERSION)
  if [[ "${current_version}" != "${to_version}" ]]; then
    confirm="n"
    docker images | grep hummerrisk/ | grep "${current_version}" | awk '{print $3}' | xargs docker rmi -f
  fi
  echo_done
}

function main() {
  echo_yellow "\n1.  'Upgrade hummerrisk config'"
  upgrade_config

  echo_yellow "\n2.  'Upgrade Docker image'"
  bash "${SCRIPT_DIR}/4_load_images.sh"

  echo_yellow "\n3.  'Backup database'"
  backup_db

  echo_yellow "\n4.  'Cleanup Image'"
  clear_images

  echo_yellow "\n5.  'Upgrade successfully. You can now restart the program'"
  echo "hrctl start"
  hrctl start
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi

}