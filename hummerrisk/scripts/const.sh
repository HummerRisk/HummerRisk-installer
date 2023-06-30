#!/usr/bin/env bash

# 当前 HummerRisk 版本
export VERSION=v1.2.0
export HMR_BASE=/opt/hummerrisk

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export SCRIPT_DIR="${BASE_DIR}"
PROJECT_DIR=$(dirname "${SCRIPT_DIR}")

export CONFIG_DIR="${HMR_BASE}/conf"
#export HUMMERRISK_CONF="${CONFIG_DIR}/hummerrisk/hummerrisk.properties"
export CONFIG_FILE="$CONFIG_DIR/install.conf"
export OS=$(uname -s)
