#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

#DOCKER_CONFIG="/etc/docker/daemon.json"
#docker_copy_failed=0

cd "${BASE_DIR}" || exit 1

function install_docker() {
   if [[ -d docker ]]; then
      echo "... Offline | install docker"
      \cp -rp docker/* /usr/bin/
      \cp -rp docker.service /etc/systemd/system/
      chmod +x /usr/bin/docker*
      chmod 754 /etc/systemd/system/docker.service
      echo "... Start docker"
      systemctl enable docker; systemctl daemon-reload; service docker start
   else
      echo "... Online| install docker"
      unset VERSION
      curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
      echo "... Start docker"
      systemctl enable docker; systemctl daemon-reload; service docker start
   fi
}

function check_docker_install() {
  command -v docker >/dev/null || {
    install_docker
  }
}

function check_docker_compose_install() {
  command -v docker-compose >/dev/null || {
  curl -SL https://download.hummerrisk.com/docker/compose/releases/download/v2.17.2/docker-compose-$(uname -s | tr A-Z a-z)-$(uname -m) -o /usr/local/bin/docker-compose 2>&1
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
  echo_yellow "1.  'Install Docker and Docker-compose'"
  check_docker_install
  check_docker_compose_install
  echo_yellow "\n2.  'Start Docker'"
  check_docker_start
  check_docker_compose
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
