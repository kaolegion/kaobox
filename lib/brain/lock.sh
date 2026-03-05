#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - Lock System
# ----------------------------------------------------------
# - Deterministic
# - Idempotent
# - Dynamic FD allocation
# - Safe release
# ==========================================================

[[ -n "${BRAIN_LOCK_LOADED:-}" ]] && return 0
readonly BRAIN_LOCK_LOADED=1

: "${LOCK_DIR:=$INDEX_DIR/.lock}"
: "${LOCK_FILE:=$LOCK_DIR/brain.lock}"

readonly LOCK_DIR
readonly LOCK_FILE

# Dynamic FD (assigned at runtime)
BRAIN_LOCK_FD=""

acquire_lock() {

    # Prevent double acquisition in same process
    if [[ -n "${BRAIN_LOCK_FD:-}" ]]; then
        echo "[Brain] Lock already acquired in this process."
        return 1
    fi

    mkdir -p "$LOCK_DIR"

    exec {BRAIN_LOCK_FD}>"$LOCK_FILE"

    if ! flock -n "$BRAIN_LOCK_FD"; then
        exec {BRAIN_LOCK_FD}>&-
        BRAIN_LOCK_FD=""
        echo "[Brain] Another process is running. Aborting."
        return 1
    fi
}

release_lock() {

    if [[ -z "${BRAIN_LOCK_FD:-}" ]]; then
        return 0
    fi

    flock -u "$BRAIN_LOCK_FD" 2>/dev/null || true
    exec {BRAIN_LOCK_FD}>&- 2>/dev/null || true

    BRAIN_LOCK_FD=""
}
