#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/common.sh"
load_desktop_environment

printf '== state ==\n'
sed -n '1,20p' "${STATE_DIR}/app.status" 2>/dev/null || true
printf 'program=%s\n' "$(cat "${STATE_DIR}/program.host-path" 2>/dev/null || true)"
printf 'runner=%s\nprefix=%s\n' "${RUNNER_REF}" "${WINEPREFIX_HOST}"
printf 'variant=%s\n' "${RUNNER_VARIANT}"
scale_factor="$(detect_system_scale_factor)"
printf '\n== scale ==\n'
printf 'system_scale=%s\n' "${scale_factor}"
printf 'wine_dpi=%s\n' "$(scale_factor_to_wine_dpi "${scale_factor}")"
printf '\n== flatpak ==\n'
flatpak ps --columns=instance,application,pid,runtime | \
    awk -v app="${RUNNER_APP}" 'NR == 1 || $2 == app'
printf '\n== windows ==\n'
xwininfo -root -tree 2>/dev/null | \
    grep -i -E '小程序开发者工具|MiniProgramStudio|Mini Program Studio' || true
printf '\n== install log ==\n'
tail -n 80 "${LOG_DIR}/install.log" 2>/dev/null || true
printf '\n== app log ==\n'
tail -n 120 "${LOG_DIR}/app.log" 2>/dev/null || true
