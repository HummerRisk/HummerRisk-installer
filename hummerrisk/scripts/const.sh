#!/usr/bin/env bash

# 当前 HummerRisk 版本
export VERSION=v0.1
export HR_BASE=/opt

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export SCRIPT_DIR="${BASE_DIR}"
PROJECT_DIR=$(dirname "${SCRIPT_DIR}")

export CONFIG_DIR="${HR_BASE}/hummerrisk/conf"
export CONFIG_FILE="$CONFIG_DIR/install.conf"
export OS=$(uname -s)