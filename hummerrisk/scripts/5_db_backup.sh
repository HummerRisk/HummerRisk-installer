#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"
HMR_BASE=$(get_config HMR_BASE)
BACKUP_DIR="/opt/hmr_db_backup"
CURRENT_VERSION=$(get_config HMR_CURRENT_VERSION)

HOST=$(get_config HMR_DB_HOST)
PORT=$(get_config HMR_DB_PORT)
USER=$(get_config HMR_DB_USER)
PASSWORD=$(get_config HMR_DB_PASSWORD)
DATABASE=$(get_config HMR_DB_NAME)
DB_FILE=${BACKUP_DIR}/${DATABASE}-${CURRENT_VERSION}-$(date +%F_%T).sql

function main() {
  if [[ ! -d ${BACKUP_DIR} ]]; then
    mkdir -p ${BACKUP_DIR}
  fi

  echo " 'Backing up'..."

  backup_cmd="mysqldump --host=${HOST} --port=${PORT} --user=${USER} --password=${PASSWORD} ${DATABASE}"
  if ! docker run --rm -i --network=hummer_net hummerrisk/mysql:8.0.32 ${backup_cmd} > "${DB_FILE}"; then
    log_error " 'Backup failed'!"
    rm -f "${DB_FILE}"
    exit 1
  else
    log_success " 'Backup succeeded! The backup file has been saved to': ${DB_FILE}"
  fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main
fi
