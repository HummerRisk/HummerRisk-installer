#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

IMAGE_DIR="images"
USE_XPACK="${USE_XPACK-0}"

function prepare_config_xpack() {
  if [[ "${USE_XPACK}" == "1" ]]; then
    sed -i 's@USE_XPACK=.*@USE_XPACK=1@g' "${PROJECT_DIR}"/install.conf
  fi
}

function prepare_docker_bin() {
  DOCKER_MD5="f8c950e9d4edb901c0a8124706f60919"
  md5_matched=$(check_md5 /tmp/docker.tar.gz "${DOCKER_MD5}")
  if [[ ! -f /tmp/docker.tar.gz || "${md5_matched}" != "1" ]]; then
    curl -L https://download.docker.com/linux/static/stable/`uname -m`/docker-20.10.17.tgz -o /tmp/docker.tar.gz
  else
    echo "'Using Docker cache':/tmp/docker.tar.gz"
  fi
  tar -xf /tmp/docker.tar.gz -C ./ || {
    rm -rf docker /tmp/docker.tar.gz
    exit 1
  }
  chown -R root:root docker
  chmod +x docker/*
}

function prepare_compose_bin() {
  if [[ ! -d "$BASE_DIR/docker" ]]; then
    mkdir -p "${BASE_DIR}/docker"
  fi
  curl -L https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o docker/
  chown -R root:root docker
  chmod +x docker/*
  export PATH=$PATH:$(pwd)/docker
}

function prepare_image_files() {
  if ! pgrep -f "docker" >/dev/null; then
    echo "Docker is not running, please install and start ..."
    exit 1
  fi

  images=$(get_images)

  for image in ${images}; do
    echo "[${image}]"
    pull_image "$image"

    filename=$(basename "${image}").tar
    component=$(echo "${filename}" | awk -F: '{ print $1 }')
    md5_filename=$(basename "${image}").md5
    md5_path=${IMAGE_DIR}/${md5_filename}

    image_id=$(docker inspect -f "{{.ID}}" "${image}")
    saved_id=""
    if [[ -f "${md5_path}" ]]; then
      saved_id=$(cat "${md5_path}")
    fi

    mkdir -p "${IMAGE_DIR}"
    # 这里达不到想要的想过，因为在构建前会删掉目录下的所有文件，所以 save_id 不可能存在
    if [[ ${image_id} != "${saved_id}" ]]; then
      rm -f ${IMAGE_DIR}/${component}*
      image_path="${IMAGE_DIR}/${filename}"
      echo " Save image ${image} -> ${image_path}"
      docker save -o "${image_path}" "${image}" && echo "${image_id}" >"${md5_path}"
    else
      echo " The image has been saved, skipping: ${image}"
    fi
    echo
  done
}

function main() {
  prepare_config_xpack

  echo "1. Preparing Docker offline package"
  prepare_docker_bin
  prepare_compose_bin

  echo -e "\n2. Preparing image offline package"
  prepare_image_files
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi