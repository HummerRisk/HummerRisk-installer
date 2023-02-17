#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

function prepare_config() {
  cd "${PROJECT_DIR}" || exit 1
  echo_yellow "2.  'Check Configuration File'"
  echo " 'Path to Configuration file': ${CONFIG_DIR}"

  echo -e "${CONFIG_FILE}  [\033[32m √ \033[0m]"
  if [[ ! -f "${HR_BASE}/compose/.env" ]]; then
    ln -s "${CONFIG_FILE}" "${HR_BASE}/compose/.env"
  fi
  echo_done
  backup_dir="${HR_BASE}/backup"
  if [[ ! -d "${backup_dir}" ]]; then
    mkdir -p ${backup_dir}
  fi
  now=$(date +'%Y-%m-%d_%H-%M-%S')
  backup_config_file="${backup_dir}/install.conf.${now}"
  echo_yellow "\n3.  'Backup Configuration File'"
  \cp -rp ${PROJECT_DIR}/install.conf ${backup_config_file}
  echo " 'Back up to' ${backup_config_file}"

  echo_done
}

function set_run_base() {
  echo_yellow "1.  'Configure Persistent Directory'"
  echo "HummerRisk will be installed to the $(echo_yellow /opt/hummerrisk) directory"

  \cp -rp hrctl /usr/bin/hrctl
  chmod 755 /usr/bin/hrctl

  if [[ ! -d "${HR_BASE}" ]]; then
    mkdir -p "${HR_BASE}"
    \cp -rP "${PROJECT_DIR}/config_init" "${HR_BASE}/conf"
    \cp -rP "${PROJECT_DIR}/install.conf" "${HR_BASE}/conf"
    chmod 644 -R "${HR_BASE}/conf"
  fi

  if [[ ! -d "${HR_BASE}/data" ]]; then
    mkdir -p "${HR_BASE}"/data/{hummerrisk,mysql}
  fi
  if [[ ! -d "${HR_BASE}/logs" ]]; then
    mkdir -p "${HR_BASE}/logs"
  fi
  \cp -rp "${PROJECT_DIR}/compose" "${HR_BASE}"
  \cp -rp "${PROJECT_DIR}/scripts" "${HR_BASE}"
  echo_done
}

function set_external_mysql() {
  mysql_host=$(get_config DB_HOST)
  read_from_input mysql_host " 'Please enter MySQL server IP'" "" "${mysql_host}"
  if [[ "${mysql_host}" == "127.0.0.1" || "${mysql_host}" == "localhost" ]]; then
    mysql_host=$(hostname -I | cut -d ' ' -f1)
  fi

  mysql_port=$(get_config DB_PORT)
  read_from_input mysql_port " 'Please enter MySQL server port'" "" "${mysql_port}"

  mysql_db=$(get_config DB_NAME)
  read_from_input mysql_db " 'Please enter MySQL database name'" "" "${mysql_db}"

  mysql_user=$(get_config DB_USER)
  read_from_input mysql_user " 'Please enter MySQL username'" "" "${mysql_user}"

  mysql_pass=$(get_config DB_PASSWORD)
  read_from_input mysql_pass " 'Please enter MySQL password'" "" "${mysql_pass}"

  if ! test_mysql_connect "${mysql_host}" "${mysql_port}" "${mysql_user}" "${mysql_pass}" "${mysql_db}"; then
    echo_red " 'Failed to connect to database, please reset'"
    echo
    set_mysql
  fi
  sed -i 's/HR_USE_EXTERNAL_MYSQL=.*/HR_USE_EXTERNAL_MYSQL=1/g' $(pwd)/install.conf

  export HR_DB_HOST="${mysql_host}"
  export HR_DB_PORT="${mysql_port}"
  export HR_DB_USER="${mysql_user}"
  export HR_DB_PASSWORD="${mysql_pass}"
  export HR_DB_NAME="${mysql_db}"
  export HR_USE_EXTERNAL_MYSQL=1
}

function set_internal_mysql() {
#  set_config USE_EXTERNAL_MYSQL 0
  password=$(get_config DB_PASSWORD)
  if [[ -z "${password}" ]]; then
    DB_PASSWORD=$(random_str 26)
#    set_config HR_DB_PASSWORD "${DB_PASSWORD}"
#    mysql_pass_base64=$(echo "${DB_PASSWORD}" |base64 )
#    sed -i "s@spring.datasource.password=.*@spring.datasource.password=${DB_PASSWORD}@g" "${HR_BASE}/conf/hummerrisk/hummerrisk.properties"
#  else
#    mysql_pass_base64=$(echo "${password}" |base64 )
#    sed -i "s@spring.datasource.password=.*@spring.datasource.password=${password}@g" "${HR_BASE}/conf/hummerrisk/hummerrisk.properties"
  fi
    export HR_DB_HOST="mysql"
    export HR_DB_PORT="3306"
    export HR_DB_USER="root"
    export HR_DB_PASSWORD="${DB_PASSWORD}"
    export HR_DB_NAME="hummerrisk"
    export HR_USE_EXTERNAL_MYSQL=0
}

function set_mysql() {
  confirm="n"
  if [[ $(cat $(pwd)/install.conf |grep HR_USE_EXTERNAL_MYSQL|awk -F= '{print $2}') -eq 1 ]];then
    for i in `cat $(pwd)/install.conf |grep HR_DB`;do
      export ${i}
      confirm="skip"
    done
  else
    read_from_input confirm " 'Do you want to use external MySQL'?" "y/n" "${confirm}"
  fi
#  use_external_mysql=$(get_config USE_EXTERNAL_MYSQL)
#  confirm="n"
#  if [[ "${use_external_mysql}" == "1" ]]; then
#    confirm="y"
#  fi
  if [[ ${confirm} != "skip" ]];then
    if [[ "${confirm}" == "y" ]]; then
      set_external_mysql
    else
      set_internal_mysql
    fi
  fi
  echo_done
}

function set_service_port() {
  echo_yellow "\n5.  'Configure External Port'"
  http_port=$(get_config HTTP_PORT)
  confirm="n"
  read_from_input confirm " 'Do you need to customize the hummerrisk external port'?" "y/n" "${confirm}"
  if [[ "${confirm}" == "y" ]]; then
    read_from_input http_port " hummerrisk web port:" "" "${http_port}"
    set_config HR_HTTP_PORT "${http_port}"
    export HR_HTTP_PORT=${http_port}
  else
    export HR_HTTP_PORT=80
  fi

  echo_done
}

function init_db() {
  use_external_mysql=$(get_config USE_EXTERNAL_MYSQL)
  if [[ "${use_external_mysql}" == "1" ]]; then
    echo_yellow "\n4.  'Init hummerrisk Database'"
    bash "${BASE_DIR}/6_db_restore.sh" "${HR_BASE}/conf/mysql/hummerrisk.sql" || {
      echo_failed
      exit 1
    }
    echo_done
  fi
}

function main() {
  if [[ ! -f ${CONFIG_FILE} ]]; then
      set_run_base
      prepare_config
      echo_yellow "\n4.  'Configure MySQL'"
      set_mysql
      set_service_port
      init_db
  else
      set_run_base
      check_config
      echo_yellow "\n2.  'Skip Configure MySQL'"
  fi
  if [[ -f ${CONFIG_FILE} ]]; then
#    env|grep -E "HR_|COMPOSE" > "$CONFIG_FILE"
    envsubst < install.conf > "${CONFIG_FILE}"
    cd "$CURRENT_DIR"/config_init/hummerrisk && envsubst < hummerrisk.properties > "$CONFIG_DIR/hummerrisk/hummerrisk.properties"
    cd "$CURRENT_DIR"
  fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
