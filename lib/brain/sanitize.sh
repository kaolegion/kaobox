#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Input Sanitization
# ----------------------------------------------------------
# - Idempotent
# - Safe for SQL
# - Preserves FTS operators
# ==========================================================

[[ -n "${BRAIN_SANITIZE_LOADED:-}" ]] && return 0
readonly BRAIN_SANITIZE_LOADED=1

sanitize_sql() {
    # Escape single quotes for SQLite
    local input="$1"
    printf "%s" "$input" | sed "s/'/''/g"
}

sanitize_fts() {
    local input="$1"

    # Remove only dangerous SQL control characters
    # Preserve: letters, numbers, space, _, -, *, :, ", parentheses
    printf "%s" "$input" \
        | tr -cd '[:alnum:] _-*:"()'
}
