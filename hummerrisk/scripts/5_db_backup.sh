#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"
HR_BASE=$(get_config HR_BASE)
BACKUP_DIR="${HR_BASE}/db_backup"
CURRENT_VERSION=$(get_config HR_CURRENT_VERSION)

HOST=$(get_config HR_DB_HOST)
PORT=$(get_config HR_DB_PORT)
USER=$(get_config HR_DB_USER)
PASSWORD=$(get_config HR_DB_PASSWORD)
DATABASE=$(get_config HR_DB_NAME)
DB_FILE=${BACKUP_DIR}/${DATABASE}-${CURRENT_VERSION}-$(date +%F_%T).sql

function main() {
  if [[ ! -d ${BACKUP_DIR} ]]; then
    mkdir -p ${BACKUP_DIR}
  fi

  echo " 'Backing up'..."

  backup_cmd="mysqldump --host=${HOST} --port=${PORT} --user=${USER} --password=${PASSWORD} ${DATABASE}"
  if ! docker run --rm -i --network=hr_hummerrisk-network hummerrisk/mysql:5.7.38 ${backup_cmd} > "${DB_FILE}"; then
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
