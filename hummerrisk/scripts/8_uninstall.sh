#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

function remove_hummerrisk() {
  echo -e " Make sure you have a backup of data, this operation is not reversible! \n"
  RUN_BASE=$(get_config RUN_BASE)
#  images=$(get_images)
  images=$(docker images|grep hummerrisk|awk '{print $1":"$2}')
  confirm="n"
  read_from_input confirm " 'Are you clean up hummerrisk files'?" "y/n" "${confirm}"
  if [[ "${confirm}" == "y" ]]; then
    if [[ -f "${CONFIG_FILE}" ]]; then
      cd "${PROJECT_DIR}" || exit 1
      hrctl down
      sleep 2s
      echo
      echo -e " 'Cleaning up' ${RUN_BASE}"
      rm -rf "${RUN_BASE}"
      echo -e " 'Cleaning up' /usr/bin/hrctl"
      rm -f /usr/bin/hrctl
      echo_done
    fi
  fi
  echo
  confirm="n"
  read_from_input confirm " 'Do you need to clean up the Docker image'?" "y/n" "${confirm}"
  if [[ "${confirm}" == "y" ]]; then
    for image in ${images}; do
      docker rmi "${image}"
    done
  fi
  echo_green " 'Cleanup complete'!"
}

function main() {
  echo_yellow "\n>>>  'Uninstall hummerrisk'"
  remove_hummerrisk
}

main
