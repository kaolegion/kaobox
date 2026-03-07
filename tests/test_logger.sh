#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/core/logger.sh"

echo "[TEST] Logger module"

log_info "Info OK"
log_warn "Warn OK"
log_error "Error OK"
log_debug "Debug OK"

echo "[PASS] Logger test complete"
