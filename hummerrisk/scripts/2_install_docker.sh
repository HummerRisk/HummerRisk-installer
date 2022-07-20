#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

#DOCKER_CONFIG="/etc/docker/daemon.json"
#docker_copy_failed=0

cd "${BASE_DIR}" || exit 1

function copy_docker() {
  \cp -f ./docker/* /usr/bin/
  \cp -f ./docker.service /etc/systemd/system/
}

function install_docker() {
   if [[ -d docker ]]; then
      log "... Offline | install docker"
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      chmod +x /usr/bin/docker*
      chmod 754 /etc/systemd/system/docker.service
      log "... Start docker"
      systemctl enable docker; systemctl daemon-reload; service docker start
   else
      log "... Online| install docker"
      curl -fsSL https://get.docker.com -o get-docker.sh 2>&1
      sudo sh get-docker.sh 2>&1 | tee -a ${CURRENT_DIR}/install.log
      log "... Start docker"
      systemctl enable docker; systemctl daemon-reload; service docker start
   fi
}


function check_docker_install() {
  command -v docker >/dev/null || {
    if command -v dnf >/dev/null; then
      if [[ -f "/etc/redhat-release" ]]; then
        if ! command -v docker >/dev/null; then
          yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null
          yum install -q -y yum-utils
          yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo
          yum install -q -y docker-ce docker-ce-cli containerd.io
          systemctl enable docker >/dev/null
          return
        fi
      fi
    fi
    install_docker
  }
}

function check_compose_install() {
  command -v docker-compose >/dev/null || {
  curl -L https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose 2>&1 | tee -a ${CURRENT_DIR}/install.log
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  }
  echo_done
}

function start_docker() {
  if command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker
  fi
  if ! docker ps >/dev/null 2>&1; then
    echo_failed
    exit 1
  fi
}

function check_docker_start() {
  prepare_set_redhat_firewalld
  if ! docker ps >/dev/null 2>&1; then
    start_docker
  fi
}

function check_docker_compose() {
  if ! docker-compose -v >/dev/null 2>&1; then
    echo_failed
    exit 1
  fi
  echo_done
}

function main() {
  if [[ "${OS}" == 'Darwin' ]]; then
    echo " 'Skip docker installation on MacOS'"
    return
  fi
  echo_yellow "1.  'Install Docker'"
  check_docker_install
  check_compose_install
  echo_yellow "\n2.  'Start Docker'"
  check_docker_start
  check_docker_compose
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
