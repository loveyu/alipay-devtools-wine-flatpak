#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/common.sh"

SERVICE_HOST_PORT="${ALIPAY_DEVTOOLS_SERVICE_HOST_PORT:-6792}"
DISABLE_GPU="${ALIPAY_DEVTOOLS_DISABLE_GPU:-1}"
SETTINGS_DIR="${WINEPREFIX_HOST}/drive_c/users/$(id -un)/.mini-ide"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
ARGV_FILE="${SETTINGS_DIR}/argv.json"

command -v jq >/dev/null
mkdir -p "${SETTINGS_DIR}"
if ! jq empty "${SETTINGS_FILE}" >/dev/null 2>&1; then
    printf '{}\n' > "${SETTINGS_FILE}"
fi

temporary_file="$(mktemp "${SETTINGS_FILE}.XXXXXX")"
trap 'rm -f -- "${temporary_file}"' EXIT
jq --argjson port "${SERVICE_HOST_PORT}" \
    '. + {"service-host.enabled": true, "service-host.port": $port}' \
    "${SETTINGS_FILE}" > "${temporary_file}"
mv -- "${temporary_file}" "${SETTINGS_FILE}"
trap - EXIT

if ! jq empty "${ARGV_FILE}" >/dev/null 2>&1; then
    printf '{}\n' > "${ARGV_FILE}"
fi
temporary_file="$(mktemp "${ARGV_FILE}.XXXXXX")"
trap 'rm -f -- "${temporary_file}"' EXIT
if [[ "${DISABLE_GPU}" == "1" ]]; then
    jq '. + {"disable-gpu": true, "disable-http2": false}' \
        "${ARGV_FILE}" > "${temporary_file}"
else
    jq 'del(."disable-gpu") | . + {"disable-http2": false}' \
        "${ARGV_FILE}" > "${temporary_file}"
fi
mv -- "${temporary_file}" "${ARGV_FILE}"
trap - EXIT

printf 'service_host_port=%s\n' "${SERVICE_HOST_PORT}" > \
    "${STATE_DIR}/service-host.conf"
printf '%s\n' "${SERVICE_HOST_PORT}"
