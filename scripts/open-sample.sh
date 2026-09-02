#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/common.sh"

SERVICE_HOST_PORT="${ALIPAY_DEVTOOLS_SERVICE_HOST_PORT:-6792}"
SERVICE_HOST_TIMEOUT="${ALIPAY_DEVTOOLS_SERVICE_HOST_TIMEOUT:-30}"
SAMPLE_DIR="${WORKSPACE_DIR}/wine-flatpak-smoke"
[[ -f "${SAMPLE_DIR}/mini.project.json" ]] || "${SCRIPT_DIR}/prepare-sample.sh" >/dev/null

sample_windows="Z:$(printf '%s' "${SAMPLE_DIR}" | tr '/' '\\')"
set +e
curl --fail --silent --show-error --max-time "${SERVICE_HOST_TIMEOUT}" \
    --request POST \
    --header 'Content-Type: application/json' \
    --header "project-path: ${sample_windows}" \
    --header 'project-type: alipay-mini' \
    --header 'project-lite-mode: false' \
    --data '{}' \
    "http://127.0.0.1:${SERVICE_HOST_PORT}/service/v1/focus"
curl_exit="$?"
set -e
if (( curl_exit == 28 )); then
    printf '请求已提交；开发者工具尚未在 %s 秒内完成工程初始化。\n' \
        "${SERVICE_HOST_TIMEOUT}" >&2
elif (( curl_exit != 0 )); then
    exit "${curl_exit}"
fi
printf '\n'
