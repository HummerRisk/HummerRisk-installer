#!/usr/bin/env bash
#
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=scripts/utils.sh
. "${PROJECT_DIR}/scripts/utils.sh"

action=${1-}
target=${2-}
args=("$@")

function check_config_file() {
  if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "$(gettext 'Configuration file not found'): ${CONFIG_FILE}"
    echo "$(gettext 'Please install it first')"
    return 3
  fi
  if [[ ! -f .env ]]; then
    ln -s "${CONFIG_FILE}" .env
  fi
}

function pre_check() {
  check_config_file || return 3
}

function usage() {
  echo "hummerrisk $(gettext 'Deployment Management Script')"
  echo
  echo "Usage: "
  echo "  hrctl [COMMAND] [ARGS...]"
  echo "  hrctl --help"
  echo
  echo "Installation Commands: "
  echo "  status     $(gettext 'Status    hummerrisk')"
  echo "  upgrade    $(gettext 'Upgrade   hummerrisk')"
  echo "  reconfig   $(gettext 'Reconfig  hummerrisk')"
  echo
  echo "Management Commands: "
  echo "  start      $(gettext 'Start     hummerrisk')"
  echo "  stop       $(gettext 'Stop      hummerrisk')"
  echo "  down       $(gettext 'Down      hummerrisk')"
  echo "  restart    $(gettext 'Restart   hummerrisk')"
  echo "  uninstall  $(gettext 'Uninstall hummerrisk')"
  echo
  echo "More Commands: "
  echo "  version            $(gettext 'View hummerrisk version')"
  echo "  load_image         $(gettext 'Loading docker image')"
  echo "  backup_db          $(gettext 'Backup database')"
  echo "  restore_db [file]  $(gettext 'Data recovery through database backup file')"
  echo
}

function service_to_docker_name() {
  service=$1
  if [[ "${service:0:3}" != "hr" ]]; then
    service=hr_${service}
  fi
  echo "${service}"
}

EXE=""

function start() {
  ${EXE} up -d
}

function stop() {
  if [[ -n "${target}" ]]; then
    ${EXE} stop "${target}" && ${EXE} rm -f "${target}"
    return
  fi
  services=$(get_docker_compose_services ignore_db)
  for i in ${services}; do
    ${EXE} stop "${i}"
  done
  for i in ${services}; do
    ${EXE} rm -f "${i}" >/dev/null
  done
}

function close() {
  if [[ -n "${target}" ]]; then
    ${EXE} stop "${target}"
    return
  fi
  services=$(get_docker_compose_services ignore_db)
  for i in ${services}; do
    ${EXE} stop "${i}"
  done
}

function pull() {
   if [[ -n "${target}" ]]; then
    ${EXE} pull "${target}"
    return
  fi
  ${EXE} pull
}

function restart() {
  stop
  echo -e "\n"
  start
}

function check_update() {
  current_version=$(get_current_version)
  latest_version=$(get_latest_version)
  if [[ "${current_version}" == "${latest_version}" ]]; then
    echo_green "$(gettext 'The current version is up to date'): ${latest_version}"
    echo
    return
  fi
  if [[ -n "${latest_version}" ]] && [[ ${latest_version} =~ v.* ]]; then
    echo -e "\033[32m$(gettext 'The latest version is'): ${latest_version}\033[0m"
  else
    exit 1
  fi
  echo -e "$(gettext 'The current version is'): ${current_version}"
  Install_DIR="$(cd "$(dirname "${PROJECT_DIR}")" >/dev/null 2>&1 && pwd)"
  if [[ ! -d "${Install_DIR}/hummerrisk-installer-${latest_version}" ]]; then
    if [[ ! -f "${Install_DIR}/hummerrisk-installer-${latest_version}.tar.gz" ]]; then
      timeout 60s wget -qO "${Install_DIR}/hummerrisk-installer-${latest_version}.tar.gz" "https://github.com/HummerRisk/HummerRisk/releases/download/${latest_version}/hummerrisk-installer-${latest_version}.tar.gz" || {
        rm -f "${Install_DIR}/hummerrisk-installer-${latest_version}.tar.gz"
        exit 1
      }
    fi
    tar -xf "${Install_DIR}/hummerrisk-installer-${latest_version}.tar.gz" -C "${Install_DIR}" || {
      rm -rf "${Install_DIR}/hummerrisk-installer-${latest_version}" "${Install_DIR}/hummerrisk-installer-${latest_version}.tar.gz"
      exit 1
    }
  fi
  cd "${Install_DIR}/hummerrisk-installer-${latest_version}" || exit 1
  ./hrctl.sh upgrade "${latest_version}"
  ln -sf /usr/bin/hrctl "${PROJECT_DIR}/hrctl.sh"
}

function main() {
  if [[ "${action}" == "help" || "${action}" == "h" || "${action}" == "-h" || "${action}" == "--help" ]]; then
    echo ""
  elif [[ "${action}" == "install" || "${action}" == "reconfig" ]]; then
    echo ""
  else
    pre_check || return 3
    EXE=$(get_docker_compose_cmd_line)
  fi
  case "${action}" in
    install)
      bash "${SCRIPT_DIR}/4_install_hummerrisk.sh"
      ;;
    upgrade)
      bash "${SCRIPT_DIR}/7_upgrade.sh" "$target"
      ;;
    check_update)
      check_update
      ;;
    reconfig)
      ${EXE} down -v
      bash "${SCRIPT_DIR}/1_config_hummerrisk.sh"
      ;;
    start)
      start
      ;;
    restart)
      restart
      ;;
    stop)
      stop
      ;;
    pull)
      pull
      ;;
    close)
      close
      ;;
    status)
      ${EXE} ps
      ;;
    down)
      if [[ -z "${target}" ]]; then
        ${EXE} down -v
      else
        ${EXE} stop "${target}" && ${EXE} rm -f "${target}"
      fi
      ;;
    uninstall)
      bash "${SCRIPT_DIR}/8_uninstall.sh"
      ;;
    backup_db)
      bash "${SCRIPT_DIR}/5_db_backup.sh"
      ;;
    restore_db)
      bash "${SCRIPT_DIR}/6_db_restore.sh" "$target"
      ;;
    load_image)
      bash "${SCRIPT_DIR}/3_load_images.sh"
      ;;
    cmd)
      echo "${EXE}"
      ;;
    tail)
      if [[ -z "${target}" ]]; then
        ${EXE} logs --tail 100 -f
      else
        docker_name=$(service_to_docker_name "${target}")
        docker logs -f "${docker_name}" --tail 100
      fi
      ;;
    exec)
      docker_name=$(service_to_docker_name "${target}")
      docker exec -it "${docker_name}" sh
      ;;
    show_services)
      get_docker_compose_services
      ;;
    raw)
      ${EXE} "${args[@]:1}"
      ;;
    version)
      get_current_version
      ;;
    help)
      usage
      ;;
    --help)
      usage
      ;;
    -h)
      usage
      ;;
    *)
      echo "No such command: ${action}"
      usage
      ;;
    esac
}

main "$@"
