#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

target=$1

function prepare_new_package() {
  version=$1
  hummerrisk_online_file_name="hummerrisk-installer-${version}.tar.gz"
  echo "Download install script to hummerrisk-installer-${version} (开始下载包到 hummerrisk-installer-${version})"
  if [ ! -d "hummerrisk-installer-${version}" ]; then
       git_urls=('download.hummerrisk.com' 'github.com' 'hub.fastgit.org')
       for git_url in "${git_urls[@]}"
       do
          success="true"
          for i in {1..3}
          do
             echo -ne "检测 ${git_url} ... ${i} "
             if ! curl -m 8 -kIs "https://${git_url}" >/dev/null;then
                echo "failed"
                success="false"
                break
             else
                echo "ok"
             fi
          done
          if [ ${success} == "true" ];then
             server_url=${git_url}
             break
          fi
       done

       if [ "x${server_url}" == "x" ];then
           echo -e "\nNo stable download server found, please check the network or use the offline installation package"
           exit 1
       fi
    curl -LOk -m 60 -o "${hummerrisk_online_file_name}" https://${server_url}/hummerrisk/hummerrisk/releases/download/"${version}"/"${hummerrisk_online_file_name}" || {
    rm -rf "${hummerrisk_online_file_name}"
    echo -e "[\033[31m ERROR \033[0m] Failed to download hummerrisk-installer-${version} (下载 hummerrisk-installer-${version} 失败, 请检查网络是否正常或尝试重新执行脚本)"
    exit 1
    }
    tar -zxf "${hummerrisk_online_file_name}" || {
      rm -rf hummerrisk-installer-"${version}"
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip hummerrisk-installer-${version} (解压 hummerrisk-installer-${version} 失败, 请检查网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    rm -rf "${hummerrisk_online_file_name}"
  fi
}

function upgrade_config() {
  # 在线升级
  if [[ ! -f "install.sh" ]];then
    # 处理版本
    echo "Online update !"
    to_version=""
    if [[ -n "${target}" ]]; then
      to_version="${target}"
    else
      to_version=$(get_latest_version)
    fi
    echo "Update version to: $to_version"
    prepare_new_package $to_version
#    if [[ "${to_version}" != "${VERSION}" ]] || [[ "${target}" =~ '-f' ]]; then
    cd hummerrisk-installer-"${to_version}"|| exit 1
    sed -i -e "1,4s/VERSION=.*/VERSION=${to_version}/g" scripts/const.sh
    sed -i "s@VERSION=.*@VERSION=${to_version}@g" "${SCRIPT_DIR}/const.sh"
    sed -i "s@HMR_CURRENT_VERSION=.*@HMR_CURRENT_VERSION=${to_version}@g" "${CONFIG_FILE}"
    /bin/bash install.sh
#    elif [[ "${to_version}" == "${VERSION}" ]]; then
#      echo "The current version is the same as the latest version, exit the upgrade process"
#      exit 0
#    fi
  else
    echo "offline update ！"
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
  current_version=$(get_config HMR_CURRENT_VERSION)
  if [[ "x${current_version}" != "x" ]]; then
    docker images | grep hummerrisk/ | grep -Ev "${current_version}|mysql" | awk '{print $3}' | xargs docker rmi -f &> /dev/null
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