#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

function set_run_base() {
  echo_yellow "1.  'Configure Persistent Directory'"
  run_base="${HR_BASE}/hummerrisk"
  confirm="n"
  read_from_input confirm " 'Do you need custom persistent store, will use the default directory' ${run_base}?" "y/n" "${confirm}"
  if [[ "${confirm}" == "y" ]]; then
    echo
    echo " 'To modify the persistent directory such as logs video, you can select your largest disk and create a directory in it, such as' /opt/hummerrisk"
    echo " 'Note: you can not change it after installation, otherwise the database may be lost'"
    echo
    df -h | grep -Ev "map|devfs|tmpfs|overlay|shm"
    echo
    read_from_input run_base " 'Persistent storage directory'" "" "${run_base}"
    if [[ "${run_base}" == "y" ]]; then
      echo_failed
      echo
      set_run_base
    fi
  fi
  if [[ ! -d "${run_base}" ]]; then
    echo "Test: 创建 ${run_base} 和 复制 ${PROJECT_DIR}/config_init"
    mkdir -p "${run_base}"
    \cp -rR "${PROJECT_DIR}/config_init" "${run_base}/conf"
  fi
  set_config RUN_BASE ${run_base}
  if [[ ! -d "${run_base}/conf" ]]; then
    cp -R "${PROJECT_DIR}/config_init" ${run_base}
  fi
  if [[ ! -d "${run_base}/conf/mysql/sql" ]]; then
    mkdir -p "${run_base}/conf/mysql/sql"
  fi
  if [[ ! -f "${run_base}/conf/mysql/mysql.cnf" ]]; then
    cp "${PROJECT_DIR}/config_init/mysql/mysql.cnf" "${run_base}/conf/mysql"
  fi
  if [[ ! -f "${run_base}/conf/mysql/sql" ]]; then
    cp "${PROJECT_DIR}/config_init/mysql/hummerrisk.sql" "${run_base}/conf/mysql/sql"
  fi
  chmod 644 -R "${run_base}/conf"
  echo "Test: 4config_hummer set_run_base : 查看PROJECT_DIR: ${PROJECT_DIR}"
  if [[ ! -d "${run_base}/data" ]]; then
    mkdir -p "${run_base}"/data/{hummerrisk,mysql}
  fi
  \cp -rp "${PROJECT_DIR}/compose" "${run_base}"
  \cp -rp "${PROJECT_DIR}/scripts" "${run_base}"
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

  set_config DB_HOST "${mysql_host}"
  set_config DB_PORT "${mysql_port}"
  set_config DB_USER "${mysql_user}"
  set_config DB_PASSWORD "${mysql_pass}"
  set_config DB_NAME "${mysql_db}"
  set_config USE_EXTERNAL_MYSQL 1

  run_base=$(get_config RUN_BASE)
  sed -i "s@jdbc:mysql://mysql:3306@jdbc:mysql://${mysql_host}:${mysql_port}@g" "${run_base}/conf/hummerrisk/hummerrisk.properties"
  sed -i "s@spring.datasource.username=.*@spring.datasource.username=${mysql_user}@g" "${run_base}/conf/hummerrisk/hummerrisk.properties"
  sed -i "s@spring.datasource.password=.*@spring.datasource.password=${mysql_pass}@g" "${run_base}/conf/hummerrisk/hummerrisk.properties"
}

function set_internal_mysql() {
  set_config USE_EXTERNAL_MYSQL 0
  password=$(get_config DB_PASSWORD)
  if [[ -z "${password}" ]]; then
    DB_PASSWORD=$(random_str 26)
    set_config DB_PASSWORD "${DB_PASSWORD}"
    run_base=$(get_config RUN_BASE)
    sed -i "s@spring.datasource.password=.*@spring.datasource.password=${DB_PASSWORD}@g" "${run_base}/conf/hummerrisk/hummerrisk.properties"
  else
    sed -i "s@spring.datasource.password=.*@spring.datasource.password=${password}@g" "${run_base}/conf/hummerrisk/hummerrisk.properties"
  fi
}

function set_mysql() {
  echo_yellow "\n2. 'Configure MySQL'"
  use_external_mysql=$(get_config USE_EXTERNAL_MYSQL)
  confirm="n"
  if [[ "${use_external_mysql}" == "1" ]]; then
    confirm="y"
  fi
  read_from_input confirm " 'Do you want to use external MySQL'?" "y/n" "${confirm}"

  if [[ "${confirm}" == "y" ]]; then
    set_external_mysql
  else
    set_internal_mysql
  fi
  echo_done
}

function set_service_port() {
  echo_yellow "\n3.  'Configure External Port'"
  http_port=$(get_config HTTP_PORT)
  confirm="n"
  read_from_input confirm " 'Do you need to customize the hummerrisk external port')?" "y/n" "${confirm}"
  if [[ "${confirm}" == "y" ]]; then
    read_from_input http_port " 'hummerrisk web port'" "" "${http_port}"
    set_config HTTP_PORT "${http_port}"
  fi
  echo_done
}

function init_db() {
  use_external_mysql=$(get_config USE_EXTERNAL_MYSQL)
  if [[ "${use_external_mysql}" == "1" ]]; then
    echo_yellow "\n4.  'Init hummerrisk Database'"
    run_base=$(get_config RUN_BASE)
    docker_network_check
    bash "${BASE_DIR}/6_db_restore.sh" "${run_base}/conf/mysql/sql/hummerrisk.sql" || {
      echo_failed
      exit 1
    }
    echo_done
  fi
}

function main() {
  echo -e "Test 1_config查看变量: BASE_DIR PROJECT_DIR HR_BASE CONFIG_DIR CONFIG_FILE RUN_BASE\n"
  echo -e "Test 1_config: $BASE_DIR $PROJECT_DIR $HR_BASE $CONFIG_DIR $CONFIG_FILE $RUN_BASE\n"

  set_run_base
  set_mysql
  set_service_port
  init_db
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
