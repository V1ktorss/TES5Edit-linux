#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

chmod +x linux/native-port/smoke-test-bsarch.sh
chmod +x linux/native-port/regression-paths-bsarch.sh
chmod +x linux/native-port/stress-large-bsarch.sh
chmod +x linux/native-port/xedit-readiness-audit.sh
chmod +x linux/native-port/check-xedit-readiness.sh
chmod +x linux/native-port/smoke-test-xedit-headless.sh
chmod +x linux/native-port/run-all-checks.sh

ENFORCE_STYLE="${ENFORCE_STYLE:-1}" linux/native-port/run-all-checks.sh
