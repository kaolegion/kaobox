#!/usr/bin/env bash

# ==========================================
# KAOBOX BRAIN — REINDEX COMMAND
# Rebuild full notes index safely
# ==========================================

set -euo pipefail

# ------------------------------------------
# Security — Absolute path guard
# ------------------------------------------

check_absolute_path() {
    local path="$1"
    if [[ "$path" != /* ]]; then
        echo "[ERROR] Absolute path required: $path"
        exit 1
    fi
}

# ------------------------------------------
# Environment validation
# ------------------------------------------

check_absolute_path "$NOTES_DIR"
check_absolute_path "$INDEX_SCRIPT"

if [ ! -d "$NOTES_DIR" ]; then
    echo "[ERROR] Notes directory missing: $NOTES_DIR"
    exit 1
fi

if [ ! -x "$INDEX_SCRIPT" ]; then
    echo "[ERROR] Index script not executable: $INDEX_SCRIPT"
    exit 1
fi

# ------------------------------------------
# Reindex process
# ------------------------------------------

cmd_reindex() {
    echo "[Brain] Reindexing all notes..."

    local count=0

    while IFS= read -r -d '' file; do
        check_absolute_path "$file"
        echo "[DEBUG] Indexing: $file"
        "$INDEX_SCRIPT" index "$file"
        count=$((count+1))
    done < <(find "$NOTES_DIR" -type f -name "*.md" -print0)

    echo "[Brain] Reindex complete."
    echo "[Brain] Files processed: $count"
}
