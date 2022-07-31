#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

target=$1

function upgrade_config() {
  confirm="n"
  to_version="${VERSION}"
  if [[ -n "${target}" ]]; then
    to_version="${target}"
  else
    echo to_version=$(get_latest_version)
  fi
  if [[ "${to_version}" && "${to_version}" != "${VERSION}" ]]; then
    sed -i "s@VERSION=.*@VERSION=${to_version}@g" "${SCRIPT_DIR}/const.sh"
    sed -i "s@CURRENT_VERSION=.*@CURRENT_VERSION=${to_version}@g" "${CONFIG_FILE}"
    export VERSION=${to_version}
  fi
  echo

  current_version=$(get_config CURRENT_VERSION)
  if [ -z "${current_version}" ]; then
    set_config CURRENT_VERSION "${VERSION}"
  fi

  if [[ "${SHELL}" == "/bin/bash" ]]; then
    if grep -q "alias hrctl=" ~/.bashrc; then
      sed -i 's@alias hrctl=.*@@g' ~/.bashrc
      unalias hrctl
      . ~/.bashrc
    fi
  fi
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
  echo_yellow "\n2.  'Upgrade hummerrisk config'"
  upgrade_config

  echo_yellow "\n3.  'Upgrade Docker image'"
  bash "${SCRIPT_DIR}/4_load_images.sh"

  echo_yellow "\n4.  'Backup database'"
  backup_db

  echo_yellow "\n5.  'Cleanup Image'"
  clear_images

  echo_yellow "\n6.  'Upgrade successfully. You can now restart the program'"
  echo "cd ${PROJECT_DIR}"
  echo "hrctl start"
  set_current_version

  hrctl start
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
