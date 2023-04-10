#!/usr/bin/env bash
#
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "${BASE_DIR}/utils.sh"

HOST=$(get_config HMR_DB_HOST)
PORT=$(get_config HMR_DB_PORT)
USER=$(get_config HMR_DB_USER)
PASSWORD=$(get_config HMR_DB_PASSWORD)
DATABASE=$(get_config HMR_DB_NAME)

DB_FILE="$1"

function main() {
  echo " 'Start restoring database': $DB_FILE"

  restore_cmd="mysql --host=${HOST} --port=${PORT} --user=${USER} --password=${PASSWORD} ${DATABASE}"
  if [[ ! -f "${DB_FILE}" ]]; then
    echo " 'file does not exist': ${DB_FILE}"
    exit 2
  fi
  echo $restore_cmd "Test"

  if ! docker run --rm -i --network=hummer_net hummerrisk/mysql:5.7.38 ${restore_cmd} <"${DB_FILE}"; then
    log_error " 'Database recovery failed. Please check whether the database file is complete or try to recover manually'!"
    exit 1
  else
    log_success " 'Database recovered successfully'!"
  fi
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  if [[ -z "$1" ]]; then
    log_error " 'Format error'！Usage 'hrctl restore_db DB_Backup_file '"
    exit 1
  fi
  if [[ ! -f $1 ]]; then
    echo " 'The backup file does not exist': $1"
    exit 2
  fi
  main
fi
