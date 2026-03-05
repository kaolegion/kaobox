#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Preflight Checks
# ----------------------------------------------------------
# - Idempotent
# - Non-destructive
# - Validates DB integrity
# ==========================================================

[[ -n "${BRAIN_PREFLIGHT_LOADED:-}" ]] && return 0
readonly BRAIN_PREFLIGHT_LOADED=1

preflight_check() {

    # 1️⃣ Environment sanity
    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[FATAL] BRAIN_DB not defined"
        return 1
    }

    [[ -n "${INDEX_DIR:-}" ]] || {
        echo "[FATAL] INDEX_DIR not defined"
        return 1
    }

    # 2️⃣ Directory existence
    [[ -d "$INDEX_DIR" ]] || {
        echo "[FATAL] Index directory not found: $INDEX_DIR"
        return 1
    }

    # 3️⃣ Database existence
    [[ -f "$BRAIN_DB" ]] || {
        echo "[FATAL] Brain database not found at $BRAIN_DB"
        return 1
    }

    # 4️⃣ SQLite integrity check
    if ! sqlite3 "$BRAIN_DB" "PRAGMA integrity_check;" | grep -q "ok"; then
        echo "[FATAL] Brain database integrity check failed"
        return 1
    fi

    return 0
}
