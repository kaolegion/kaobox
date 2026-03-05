#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Session Manager
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Manage active context session
# Storage:
#   - $BRAIN_ROOT/.session
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_SESSION_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_SESSION_LOADED=1

# ----------------------------------------------------------
# Validate runtime environment
# ----------------------------------------------------------
[[ -n "${BRAIN_ROOT:-}" ]] || {
    echo "[context] BRAIN_ROOT not defined" >&2
    return 1
}

readonly SESSION_FILE="$BRAIN_ROOT/.session"

# ==========================================================
# Set active note
# ==========================================================
session_set_active() {

    local file="$1"

    [[ -n "${file:-}" ]] || return 1

    echo "$file" > "$SESSION_FILE"
}

# ==========================================================
# Get active note
# ==========================================================
session_get_active() {

    [[ -f "$SESSION_FILE" ]] || return 0
    cat "$SESSION_FILE"
}
