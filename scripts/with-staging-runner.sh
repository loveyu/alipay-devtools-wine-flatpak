#!/usr/bin/env bash

set -Eeuo pipefail

if (( $# == 0 )); then
    printf '用法：%s COMMAND [ARG ...]\n' "$0" >&2
    exit 64
fi

XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"

export ALIPAY_DEVTOOLS_RUNNER_VARIANT=staging
export ALIPAY_DEVTOOLS_DATA_DIR="${ALIPAY_DEVTOOLS_STAGING_DATA_DIR:-${XDG_DATA_HOME}/alipay-devtools-wine-flatpak-staging}"
export ALIPAY_DEVTOOLS_STATE_DIR="${ALIPAY_DEVTOOLS_STAGING_STATE_DIR:-${XDG_STATE_HOME}/alipay-devtools-wine-flatpak-staging}"
export ALIPAY_DEVTOOLS_CACHE_DIR="${ALIPAY_DEVTOOLS_STAGING_CACHE_DIR:-${XDG_CACHE_HOME}/alipay-devtools-wine-flatpak-staging}"

exec "$@"
