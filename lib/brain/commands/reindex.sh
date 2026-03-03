#!/usr/bin/env bash

# ==========================================
# KAOBOX BRAIN — REINDEX COMMAND
# Batch rebuild (single transaction)
# ==========================================

set -euo pipefail


#!/usr/bin/env bash
# ------------------------------------------
# Security — Absolute path guard
# ------------------------------------------

_check_absolute_path() {
    local path="$1"
    [[ "$path" == /* ]] || {
        echo "[ERROR] Absolute path required: $path"
        return 1
    }
}

# ------------------------------------------
# Command implementation
# ------------------------------------------

cmd_reindex() {

    [[ -n "${NOTES_DIR:-}" ]] || {
        echo "[ERROR] NOTES_DIR not defined"
        return 1
    }

    _check_absolute_path "$NOTES_DIR" || return 1

    if [[ ! -d "$NOTES_DIR" ]]; then
        echo "[ERROR] Notes directory missing: $NOTES_DIR"
        return 1
    fi

    echo "[Brain] Reindexing all notes..."

    mapfile -d '' files < <(
        find "$NOTES_DIR" -type f -name "*.md" -print0 | sort -z
    )

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "[Brain] No notes found."
        return 0
    fi

    reindex_all "${files[@]}"

    echo "[Brain] Reindex complete."
    echo "[Brain] Files processed: ${#files[@]}"
}
