SHELL := /bin/bash

.PHONY: check helpers download install install-user-integration enable-service open-sample run status \
	build-deepin-runner migrate-to-deepin stop test-portal test-fonts \
	build-staging-runner staging-install staging-enable-service staging-open-sample \
	staging-run staging-status staging-stop staging-test-portal

check:
	@bash -n scripts/*.sh
	@tests/alipay-host-open.sh
	@tests/desktop-launch.sh
	@tests/install-user-integration.sh
	@tests/stop.sh
	@tests/deepin-runner.sh
	@if find . -path './.git' -prune -o -type f \
		\( -iname '*.exe' -o -iname '*.msi' \) -print -quit | grep -q .; then \
		echo '错误：仓库中不能提交支付宝小程序开发者工具安装包' >&2; exit 1; \
	fi
	@if grep -R -E -- '--filesystem=/data([/:;]|$$)' flatpak >/dev/null; then \
		echo '错误：/data 必须使用本机用户级 override，不能写入 Flatpak 清单' >&2; exit 1; \
	fi
	@if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git diff --check; fi
	@if git ls-files | grep -Eiq '\.(dll|ttf|ttc|otf|flatpak|bundle)$$'; then \
		echo '错误：仓库中不能提交 DLL、字体或生成的 Flatpak 制品' >&2; exit 1; \
	fi

helpers:
	@mkdir -p .local/bin
	@cc -O2 -Wall -Wextra -o .local/bin/x11-control tests/x11-control.c -lX11 -ldl

download: check
	@./scripts/download.sh

install: check
	@./scripts/install.sh
	@./scripts/install-user-integration.sh

install-user-integration: check
	@./scripts/install-user-integration.sh

enable-service:
	@./scripts/enable-service-host.sh

open-sample:
	@./scripts/open-sample.sh

run: check
	@./scripts/run.sh

status:
	@./scripts/status.sh

build-deepin-runner: check
	@ALIPAY_DEVTOOLS_RUNNER_VARIANT=deepin ./scripts/build-deepin-runner.sh

migrate-to-deepin: check
	@ALIPAY_DEVTOOLS_RUNNER_VARIANT=deepin ./scripts/migrate-to-deepin.sh
	@./scripts/install-user-integration.sh

stop:
	@./scripts/stop.sh

test-portal: check
	@./scripts/test-portal-runner.sh

test-fonts: check
	@./scripts/test-electron-fonts.sh

build-staging-runner: check
	@./scripts/with-staging-runner.sh ./scripts/build-staging-runner.sh

staging-install: check
	@./scripts/with-staging-runner.sh ./scripts/install.sh
	@./scripts/install-user-integration.sh

staging-enable-service:
	@./scripts/with-staging-runner.sh ./scripts/enable-service-host.sh

staging-open-sample:
	@./scripts/with-staging-runner.sh ./scripts/open-sample.sh

staging-run: check
	@./scripts/with-staging-runner.sh ./scripts/run.sh

staging-status:
	@./scripts/with-staging-runner.sh ./scripts/status.sh

staging-stop:
	@./scripts/with-staging-runner.sh ./scripts/stop.sh

staging-test-portal: check
	@./scripts/with-staging-runner.sh ./scripts/test-portal-runner.sh
