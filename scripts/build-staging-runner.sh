#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/common.sh"

WINE_VERSION="11.0"
WINE_SHA256="c07a6857933c1fc60dff5448d79f39c92481c1e9db5aa628db9d0358446e0701"
WINE_URL="https://dl.winehq.org/wine/source/11.0/wine-11.0.tar.xz"
STAGING_TAG="v11.0"
STAGING_COMMIT="6cc805ea57132eeaf44764e9213823c9b8d0d300"
STAGING_SHA256="226dc2fc10ec4eb64d7dbc7c66fcf262ea52aa0e3362b9d61b715d85897cbeb3"
STAGING_URL="https://gitlab.winehq.org/wine/wine-staging/-/archive/${STAGING_TAG}/wine-staging-${STAGING_TAG}.tar.gz"

FLATPAK_REMOTE="${ALIPAY_FLATPAK_REMOTE:-}"
LOCAL_REMOTE="alipay-wine-staging-local"
LOCAL_REPO="${DATA_DIR}/staging-flatpak-repo"
BUILD_ROOT="${CACHE_DIR}/staging-runner-build/${WINE_VERSION}-${STAGING_COMMIT}"
SOURCE_DIR="${BUILD_ROOT}/source"
STAGING_DIR="${BUILD_ROOT}/wine-staging"
BUILD_DIR="${BUILD_ROOT}/build-wow64"
APP_DIR="${BUILD_ROOT}/appdir"
WINE_ARCHIVE="${CACHE_DIR}/wine-${WINE_VERSION}.tar.xz"
STAGING_ARCHIVE="${CACHE_DIR}/wine-staging-${STAGING_TAG}.tar.gz"
STATUS_FILE="${STATE_DIR}/staging-runner-build.status"
LOCK_FILE="${STATE_DIR}/staging-runner-build.lock"
LOG_FILE="${LOG_DIR}/staging-runner-build.log"
BUILD_JOBS="${BUILD_JOBS:-14}"

rotate_log "${LOG_FILE}" 104857600
exec >> "${LOG_FILE}" 2>&1
exec 9> "${LOCK_FILE}"
if ! flock -n 9; then
    printf '%s Wine Staging runner 已在构建\n' "$(date --iso-8601=seconds)"
    exit 0
fi

build_status() {
    local stage="$1"
    local detail="${2:-}"
    {
        printf 'updated_at=%s\n' "$(date --iso-8601=seconds)"
        printf 'stage=%s\n' "${stage}"
        printf 'detail=%s\n' "${detail}"
    } > "${STATUS_FILE}"
}

on_error() {
    local exit_code="$?"
    build_status failed "exit=${exit_code},line=${BASH_LINENO[0]:-unknown}"
    exit "${exit_code}"
}
trap on_error ERR

mkdir -p "${BUILD_ROOT}" "${LOCAL_REPO}"
build_status install-sdk "org.freedesktop.Sdk//25.08"
if [[ -z "${FLATPAK_REMOTE}" ]]; then
    for remote_candidate in flathub flathub-wecom; do
        if flatpak remotes --user --columns=name | grep -Fxq "${remote_candidate}"; then
            FLATPAK_REMOTE="${remote_candidate}"
            break
        fi
    done
fi
if [[ -z "${FLATPAK_REMOTE}" ]] || \
   ! flatpak remotes --user --columns=name | grep -Fxq "${FLATPAK_REMOTE}"; then
    printf 'Flatpak remote 不存在：%s\n' "${FLATPAK_REMOTE}" >&2
    exit 69
fi
for sdk_ref in \
    org.freedesktop.Sdk//25.08 \
    org.freedesktop.Sdk.Extension.mingw-w64//25.08; do
    if ! flatpak info --user "${sdk_ref}" >/dev/null 2>&1; then
        flatpak install --user --noninteractive -y --no-deps --no-related \
            "${FLATPAK_REMOTE}" "${sdk_ref}"
    fi
done

download_checked() {
    local url="$1"
    local output="$2"
    local expected="$3"

    if [[ -f "${output}" ]] && \
       [[ "$(sha256sum "${output}" | awk '{print $1}')" != "${expected}" ]]; then
        mv "${output}" "${output}.invalid.$(date +%s)"
    fi
    if [[ ! -f "${output}" ]]; then
        curl --fail --location --continue-at - --retry 20 --retry-all-errors \
            --retry-delay 10 --connect-timeout 30 --output "${output}" "${url}"
    fi
    printf '%s  %s\n' "${expected}" "${output}" | sha256sum --check -
}

build_status download-sources "wine=${WINE_VERSION},staging=${STAGING_TAG}"
download_checked "${WINE_URL}" "${WINE_ARCHIVE}" "${WINE_SHA256}"
download_checked "${STAGING_URL}" "${STAGING_ARCHIVE}" "${STAGING_SHA256}"

build_status apply-staging "${STAGING_COMMIT}"
if [[ ! -f "${SOURCE_DIR}/.alipay-staging-patched" ]]; then
    prepare_dir="${BUILD_ROOT}/source.prepare.$$"
    staging_prepare="${BUILD_ROOT}/staging.prepare.$$"
    mkdir -p "${prepare_dir}" "${staging_prepare}"
    tar --extract --xz --file="${WINE_ARCHIVE}" --strip-components=1 --directory="${prepare_dir}"
    tar --extract --gzip --file="${STAGING_ARCHIVE}" --strip-components=1 --directory="${staging_prepare}"
    # Wine Staging needs autoreconf while applying patches.  Keep that build
    # dependency inside the Freedesktop SDK instead of installing it on the host.
    flatpak run --user \
        --command=sh \
        --filesystem="${BUILD_ROOT}" \
        org.freedesktop.Sdk//25.08 \
        -c 'python3 "$1/staging/patchinstall.py" DESTDIR="$2" --all' \
        sh "${staging_prepare}" "${prepare_dir}"
    printf '%s\n' "${STAGING_COMMIT}" > "${prepare_dir}/.alipay-staging-patched"
    mv "${prepare_dir}" "${SOURCE_DIR}"
    mv "${staging_prepare}" "${STAGING_DIR}"
fi

build_status initialize-appdir "${STAGING_RUNNER_APP}"
mkdir -p "${BUILD_DIR}"
if [[ ! -f "${APP_DIR}/metadata" ]]; then
    flatpak build-init \
        --arch=x86_64 \
        --sdk-extension=org.freedesktop.Sdk.Extension.mingw-w64 \
        "${APP_DIR}" "${STAGING_RUNNER_APP}" \
        org.freedesktop.Sdk org.freedesktop.Platform 25.08
fi

build_status build-new-wow64 "jobs=${BUILD_JOBS}"
flatpak build \
    --allow=devel \
    --bind-mount="/run/build=${BUILD_ROOT}" \
    --env="BUILD_JOBS=${BUILD_JOBS}" \
    "${APP_DIR}" bash -lc '
        set -Eeuo pipefail
        export PATH="/usr/lib/sdk/mingw-w64/bin:${PATH}"
        cd /run/build/build-wow64
        if [[ ! -f Makefile ]]; then
            /run/build/source/configure \
                --prefix=/app \
                --libdir=/app/lib \
                --enable-archs=i386,x86_64 \
                --disable-winemenubuilder \
                --disable-tests
        fi
        make -j"${BUILD_JOBS}"
        make install \
            LDCONFIG=/bin/true \
            UPDATE_DESKTOP_DATABASE=/bin/true \
            INSTALL_PROGRAM_FLAGS=-s
    '

build_status finish-flatpak "${STAGING_RUNNER_APP}"
if [[ ! -f "${BUILD_ROOT}/.finished" ]]; then
    mkdir -p \
        "${APP_DIR}/files/share/wine/gecko" \
        "${APP_DIR}/files/share/wine/mono"
    flatpak build-finish \
        --command=wine \
        --share=ipc \
        --share=network \
        --allow=multiarch \
        --socket=x11 \
        --socket=pulseaudio \
        --device=dri \
        --filesystem=xdg-download/AlipayDevTools:create \
        --env=WINEPREFIX=/var/data/wine-alipay-devtools \
        --extension=org.winehq.Wine.gecko=directory=share/wine/gecko \
        --extension=org.winehq.Wine.gecko=version=stable-25.08 \
        --extension=org.winehq.Wine.mono=directory=share/wine/mono \
        --extension=org.winehq.Wine.mono=version=stable-25.08 \
        "${APP_DIR}"
    printf '%s\n' "${STAGING_COMMIT}" > "${BUILD_ROOT}/.finished"
fi

build_status export-flatpak "${LOCAL_REPO}"
flatpak build-export --disable-fsync \
    --subject="Wine ${WINE_VERSION} Staging ${STAGING_TAG} new WoW64 for Alipay DevTools" \
    "${LOCAL_REPO}" "${APP_DIR}" "${STAGING_RUNNER_BRANCH}"

local_url="file://${LOCAL_REPO}"
if flatpak remotes --user --columns=name | grep -Fxq "${LOCAL_REMOTE}"; then
    flatpak remote-modify --user --url="${local_url}" "${LOCAL_REMOTE}"
else
    flatpak remote-add --user --if-not-exists --no-gpg-verify \
        "${LOCAL_REMOTE}" "${local_url}"
fi

build_status install-flatpak "${STAGING_RUNNER_APP}//${STAGING_RUNNER_BRANCH}"
flatpak install --user --noninteractive -y --reinstall --no-deps --no-related \
    "${LOCAL_REMOTE}" "${STAGING_RUNNER_APP}//${STAGING_RUNNER_BRANCH}"

build_status complete "${STAGING_RUNNER_APP}//${STAGING_RUNNER_BRANCH}"
printf '%s Wine Staging runner 构建完成\n' "$(date --iso-8601=seconds)"
