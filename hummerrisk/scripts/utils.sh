#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck source=./const.sh
. "${SCRIPT_DIR}/const.sh"

function is_confirm() {
  read -r confirmed
  if [[ "${confirmed}" == "y" || "${confirmed}" == "Y" || ${confirmed} == "" ]]; then
    return 0
  else
    return 1
  fi
}

function echo_logo() {
  cat << "EOF"

██╗  ██╗██╗   ██╗███╗   ███╗███╗   ███╗███████╗██████╗ ██████╗ ██╗███████╗██╗  ██╗
██║  ██║██║   ██║████╗ ████║████╗ ████║██╔════╝██╔══██╗██╔══██╗██║██╔════╝██║ ██╔╝
███████║██║   ██║██╔████╔██║██╔████╔██║█████╗  ██████╔╝██████╔╝██║███████╗█████╔╝
██╔══██║██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══╝  ██╔══██╗██╔══██╗██║╚════██║██╔═██╗
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║██║███████║██║  ██╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝

EOF

  echo -e "\t\t\t\t\t\t\t\t   Version: \033[33m $VERSION \033[0m \n"
}

function echo_red() {
  echo -e "\033[1;31m$1\033[0m"
}

function echo_green() {
  echo -e "\033[1;32m$1\033[0m"
}

function echo_yellow() {
  echo -e "\033[1;33m$1\033[0m"
}

function has_config() {
  key=$1
  if grep "^${key}=" "${CONFIG_FILE}" &>/dev/null; then
    echo "1"
  else
    echo "0"
  fi
}

function get_config() {
  key=$1
  default=${2-''}
  value=$(grep "^${key}=" "${CONFIG_FILE}" | awk -F= '{ print $2 }')
  if [[ -z "$value" ]];then
    value="$default"
  fi
  echo "${value}"
}

function get_env_value() {
  key=$1
  default=${2-''}
  value=$(env | grep "$key=" | awk -F= '{ print $2 }')
  echo "${value}"
}

function get_config_or_env() {
  key=$1
  value=''
  default=${2-''}
  if [[ -f "${CONFIG_FILE}" ]];then
    value=$(get_config "$key")
  fi

  if [[ -z "$value" ]];then
    value=$(get_env_value "$key")
  fi

  if [[ -z "$value" ]];then
    value="$default"
  fi
  echo "${value}"
}

function set_config() {
  key=$1
  value=$2

  has=$(has_config "${key}")
  if [[ ${has} == "0" ]]; then
    echo "${key}=${value}" >>"${CONFIG_FILE}"
    return
  fi

  origin_value=$(get_config "${key}")
  if [[ "${value}" == "${origin_value}" ]]; then
    return
  fi

  if [[ "${OS}" == 'Darwin' ]]; then
    sed -i '' "s,^${key}=.*$,${key}=${value},g" "${CONFIG_FILE}"
  else
    sed -i "s,^${key}=.*$,${key}=${value},g" "${CONFIG_FILE}"
  fi
}

function test_mysql_connect() {
  host=$1
  port=$2
  user=$3
  password=$4
  db=$5
  command="CREATE TABLE IF NOT EXISTS test(id INT); DROP TABLE test;"
  docker run -it --rm hummerrisk/mysql:5.7.38 mysql -h"${host}" -P"${port}" -u"${user}" -p"${password}" "${db}" -e "${command}" 2>/dev/null
}

function test_redis_connect() {
  host=$1
  port=$2
  password=$3
  command="SET msg 'ok';GET msg;DEL msg"
  docker run -it --rm hummerrisk/redis:6.2.10-alpine redis-cli -h "${host}" -a"${user}" -p"${password}" "${command}" 2>/dev/null
}

function get_images() {
  USE_XPACK=$(get_config_or_env '0')
  scope="public"
  if [[ "$USE_XPACK" == "1" ]];then
    scope="all"
  fi
#  EXE=$(get_docker_compose_cmd_line)
#  images=$(${EXE} config|grep image:|awk '{print $2}')
  images=(
    "hummerrisk/mysql:8.0.32"
    "hummerrisk/redis:6.2.10-alpine"
    "hummerrisk/xxl-job-admin:2.3.1"
    "hummerrisk/hmr-flyway:${VERSION}"
    "hummerrisk/hmr-monitor:${VERSION}"
    "hummerrisk/hmr-system:${VERSION}"
    "hummerrisk/hmr-k8s:${VERSION}"
    "hummerrisk/hmr-gateway:${VERSION}"
    "hummerrisk/hmr-auth:${VERSION}"
    "hummerrisk/hmr-cloud:${VERSION}"
    "hummerrisk/hmr-ui:${VERSION}"
  )
  for image in "${images[@]}"; do
    echo "${image}"
  done
  if [[ "${scope}" == "all" ]]; then
    echo
  fi
}

function read_from_input() {
  var=$1
  msg=$2
  choices=$3
  default=$4
  if [[ -n "${choices}" ]]; then
    msg="${msg} (${choices}) "
  fi
  if [[ -z "${default}" ]]; then
    msg="${msg} ( 'no default')"
  else
    msg="${msg} ( 'default' ${default})"
  fi
  echo -n "${msg}: "
  read -r input
  if [[ -z "${input}" && -n "${default}" ]]; then
    export "${var}"="${default}"
  else
    export "${var}"="${input}"
  fi
}

function get_file_md5() {
  file_path=$1
  if [[ -f "${file_path}" ]]; then
    if [[ "${OS}" == "Darwin" ]]; then
      md5 "${file_path}" | awk -F= '{ print $2 }'
    else
      md5sum "${file_path}" | awk '{ print $1 }'
    fi
  fi
}

function check_md5() {
  file=$1
  md5_should=$2

  md5=$(get_file_md5 "${file}")
  if [[ "${md5}" == "${md5_should}" ]]; then
    echo "1"
  else
    echo "0"
  fi
}


function echo_failed() {
  echo_red "[FAILED] $1"
}

function log_success() {
  echo_green "[SUCCESS] $1"
}

function log_warn() {
  echo_yellow "[WARN] $1"
}

function log_error() {
  echo_red "[ERROR] $1"
}

function echo_done() {
  sleep 0.5
  echo "'complete'"
}

# shellcheck disable=SC2120
function get_docker_compose_cmd_line() {
  ignore_db="$1"
  cmd="docker-compose -f ${HMR_BASE}/compose/docker-compose-app.yml"
  services=$(get_docker_compose_services "$ignore_db")
  if [[ "${services}" =~ mysql ]]; then
    cmd="${cmd} -f  ${HMR_BASE}/compose/docker-compose-mysql.yml -f  ${HMR_BASE}/compose/docker-compose-service.yml"
  fi
  echo "${cmd}"
}

function get_docker_compose_services() {
  ignore_db="$1"
  services="trivy-server"
  use_external_mysql=$(get_config HMR_USE_EXTERNAL_MYSQL)
  if [[ "${use_external_mysql}" != "1" && "${ignore_db}" != "ignore_db" ]]; then
    services+=" mysql"
  fi
  echo "${services}"
}

function random_str() {
  len=$1
  if [[ -z ${len} ]]; then
    len=16
  fi
  uuid=None
  if command -v dmidecode &>/dev/null; then
    uuid=$(dmidecode -t 1 | grep UUID | awk '{print $2}' | base64 | head -c ${len})
  fi
  if [[ "${#uuid}" == "${len}" ]]; then
    echo "${uuid}"
  else
    head -c100 < /dev/urandom | base64 | tr -dc A-Za-z0-9 | head -c ${len}; echo
  fi
}



function prepare_set_redhat_firewalld() {
  if command -v firewall-cmd > /dev/null; then
    if firewall-cmd --state >/dev/null 2>&1; then
      if command -v dnf > /dev/null; then
        if ! firewall-cmd --list-all | grep 'masquerade: yes' >/dev/null; then
          firewall-cmd --permanent --add-masquerade >/dev/null
          flag=1
        fi
      fi
      if [[ "$flag" ]]; then
        firewall-cmd --reload >/dev/null
        unset flag
      fi
    fi
  fi
}

function get_latest_version() {
  curl -s 'https://api.github.com/repos/HummerRisk/HummerRisk/releases/latest' |
    grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' |
    sed 's/\"//g;s/,//g;s/ //g'
}

function image_has_prefix() {
  if [[ $1 =~ registry.* ]]; then
    echo "1"
  else
    echo "0"
  fi
}

function set_current_version() {
  current_version=$(get_config CURRENT_VERSION)
  if [ "${current_version}" != "${VERSION}" ]; then
    set_config HMR_CURRENT_VERSION "${VERSION}"
  fi
}

function get_current_version() {
  current_version=$(get_config CURRENT_VERSION)
  if [ -z "${current_version}" ]; then
    current_version="${VERSION}"
  fi
  echo "${current_version}"
}

function pull_image() {
  image=$1
  DOCKER_IMAGE_PREFIX=$(get_config_or_env 'HMR_DOCKER_IMAGE_PREFIX')
  IMAGE_PULL_POLICY=${IMAGE_PULL_POLICY-"Always"}
  if [[ "x${DOCKER_IMAGE_PREFIX}" == "x" ]];then
    DOCKER_IMAGE_PREFIX="registry.cn-beijing.aliyuncs.com"
  fi
  if docker image inspect -f '{{ .Id }}' "$image" &> /dev/null; then
    exits=0
  else
    exits=1
  fi

  if [[ "$exits" == "0" && "$IMAGE_PULL_POLICY" != "Always" ]];then
    echo "Image exist, pass"
    return
  fi
  if [[ -n "${DOCKER_IMAGE_PREFIX}" && $(image_has_prefix "${image}") == "0" ]]; then
    docker pull "${DOCKER_IMAGE_PREFIX}/${image}"
    docker tag "${DOCKER_IMAGE_PREFIX}/${image}" "${image}"
    docker rmi -f "${DOCKER_IMAGE_PREFIX}/${image}"
  else
    docker pull "${image}"
  fi
  echo ""
}

function pull_images() {
  images_to=$(get_images)

  for image in ${images_to}; do
    echo "[${image}]"
    pull_image "$image"
  done
}

function prop {
   [ -f "$1" ] | grep -P "^\s*[^#]?${2}=.*$" $1 | cut -d'=' -f2
}

function check_config() {
  if [[ -f ${CONFIG_FILE} ]]; then
     export HMR_USE_EXTERNAL_MYSQL=$(get_config HMR_USE_EXTERNAL_MYSQL)
     export HMR_DB_HOST=$(get_config HMR_DB_HOST)
     export HMR_DB_USER=$(get_config HMR_DB_USER)
     export HMR_DB_PASSWORD=$(get_config HMR_DB_PASSWORD)
     export HMR_DB_NAME=$(get_config HMR_DB_NAME)
     export HMR_DB_PORT=$(get_config HMR_DB_PORT)
     export HMR_HTTP_PORT=$(get_config HMR_HTTP_PORT)
     export HMR_DOCKER_SUBNET=$(get_config HMR_DOCKER_SUBNET)
     export HMR_DOCKER_GATEWAY=$(get_config HMR_DOCKER_GATEWAY)
     export TRIVY_SERVER_PORT=$(get_config TRIVY_SERVER_PORT)
  fi
}