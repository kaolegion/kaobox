#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain — Session Command (Observability)
# ----------------------------------------------------------
# Shows current active context session (focus)
# - Deterministic output
# - No DB writes
# ==========================================================

[[ -n "${BRAIN_SESSION_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_SESSION_CMD_LOADED=1

cmd_session() {

    [[ -n "${KAOBOX_ROOT:-}" ]] || {
        echo "[ERROR] KAOBOX_ROOT not defined" >&2
        return 1
    }

    # shellcheck source=/dev/null
    source "$KAOBOX_ROOT/lib/brain/context/session.sh"

    echo "SESSION"
    echo "----------------------------------------"

    local active=""
    active="$(session_get_active 2>/dev/null || true)"

    if [[ -n "${active:-}" ]]; then
        echo "Active: $active"
    else
        echo "Active: (none)"
    fi

    return 0
}
