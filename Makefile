SHELL := /bin/bash

.PHONY: check helpers download install enable-service open-sample run status \
	build-staging-runner staging-install staging-enable-service staging-open-sample \
	staging-run staging-status staging-stop

check:
	@bash -n scripts/*.sh
	@if find . -path './.git' -prune -o -type f \
		\( -iname '*.exe' -o -iname '*.msi' \) -print -quit | grep -q .; then \
		echo '错误：仓库中不能提交支付宝小程序开发者工具安装包' >&2; exit 1; \
	fi
	@if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git diff --check; fi

helpers:
	@mkdir -p .local/bin
	@cc -O2 -Wall -Wextra -o .local/bin/x11-control tests/x11-control.c -lX11 -ldl

download: check
	@./scripts/download.sh

install: check
	@./scripts/install.sh

enable-service:
	@./scripts/enable-service-host.sh

open-sample:
	@./scripts/open-sample.sh

run: check
	@./scripts/run.sh

status:
	@./scripts/status.sh

build-staging-runner: check
	@./scripts/with-staging-runner.sh ./scripts/build-staging-runner.sh

staging-install: check
	@./scripts/with-staging-runner.sh ./scripts/install.sh

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
