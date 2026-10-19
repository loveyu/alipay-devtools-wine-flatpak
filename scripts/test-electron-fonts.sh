#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/common.sh"

PROGRAM="$(<"${STATE_DIR}/program.host-path")"
PROGRAM_DIR="$(dirname -- "${PROGRAM}")"
[[ -f "${PROGRAM}" && "${PROGRAM}" == "${WINEPREFIX_HOST}/"* ]]
TEST_DIR="$(mktemp -d "${CACHE_DIR}/font-smoke.XXXXXX")"
LOG_FILE="${LOG_DIR}/electron-font-smoke.log"
trap 'rm -rf -- "${TEST_DIR}"' EXIT
mkdir -p "${TEST_DIR}/electron/resources/app" "${TEST_DIR}/prefix"
# 仅复制 Electron 外壳，测试不加载业务资源或用户数据。
while IFS= read -r -d '' file; do
    cp -a --reflink=auto "${file}" "${TEST_DIR}/electron/"
done < <(find "${PROGRAM_DIR}" -maxdepth 1 -type f \
    \( -name '*.dll' -o -name '*.pak' -o -name '*.bin' -o -name '*.dat' \) -print0)
cp -a --reflink=auto "${PROGRAM}" "${TEST_DIR}/electron/font-smoke.exe"
cp -a --reflink=auto "${PROGRAM_DIR}/locales" "${TEST_DIR}/electron/"
install -m 0644 "${PROJECT_DIR}/tests/electron-font-smoke.js" \
    "${TEST_DIR}/electron/resources/app/index.js"
printf '%s\n' '{"name":"font-smoke","version":"1.0.0","main":"index.js"}' \
    > "${TEST_DIR}/electron/resources/app/package.json"
load_desktop_environment
rotate_log "${LOG_FILE}"
timeout 60 flatpak run --user --arch=x86_64 --branch="${RUNNER_BRANCH}" \
    --nosocket=wayland --filesystem="${TEST_DIR}" \
    --env="WINEPREFIX=${TEST_DIR}/prefix" --env="WINEARCH=${WINEARCH_VALUE}" \
    --env=WINEDEBUG=-all --command=sh "${RUNNER_APP}" -c '
        wine "$1"
        result=$?
        wineserver --kill
        exit "$result"
    ' sh "${TEST_DIR}/electron/font-smoke.exe" > "${LOG_FILE}" 2>&1
grep -Fxq FONT_ALL_OK < <(tr -d '\r' < "${LOG_FILE}")
printf 'Electron 中西文、emoji 和私用区字符布局测试通过。\n'
